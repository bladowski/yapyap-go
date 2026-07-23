using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using NetTopologySuite.Geometries;
using YapYap.Core.DTOs;
using YapYap.Core.Entities;
using YapYap.Core.Enums;
using YapYap.Core.Interfaces;
using YapYap.Infrastructure.Data;

namespace YapYap.Infrastructure.Services;

public class TripService
{
    private readonly YapYapDbContext _db;
    private readonly IMapService _mapService;
    private readonly ITripEventDispatcher _dispatcher;
    private readonly IPaymentGatewayService _paymentGateway;
    private readonly ILogger<TripService> _logger;

    private const decimal PlatformCommissionRate = 0.15m;
    private const decimal DriverShareRate = 1m - PlatformCommissionRate; // 0.85

    private static readonly Dictionary<VehicleCategory, (decimal BaseFare, decimal PerKm, decimal PerMinute)> FareMatrix = new()
    {
        [VehicleCategory.BodaBoda] = (BaseFare: 1000m, PerKm: 300m, PerMinute: 50m),
        [VehicleCategory.TukTuk]   = (BaseFare: 2000m, PerKm: 500m, PerMinute: 80m),
        [VehicleCategory.Car]      = (BaseFare: 3500m, PerKm: 800m, PerMinute: 120m),
    };

    private static readonly GeometryFactory Gf =
        NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);

    public TripService(
        YapYapDbContext db,
        IMapService mapService,
        ITripEventDispatcher dispatcher,
        IPaymentGatewayService paymentGateway,
        ILogger<TripService> logger)
    {
        _db = db;
        _mapService = mapService;
        _dispatcher = dispatcher;
        _paymentGateway = paymentGateway;
        _logger = logger;
    }

    public async Task<FareEstimateResponse> EstimateTripPriceAsync(
        double pickupLat, double pickupLng,
        double dropoffLat, double dropoffLng,
        VehicleCategory category)
    {
        var origin = Gf.CreatePoint(new Coordinate(pickupLng, pickupLat));
        var dest = Gf.CreatePoint(new Coordinate(dropoffLng, dropoffLat));
        var route = await _mapService.CalculateRouteAsync(origin, dest);

        var (baseFare, perKm, perMinute) = FareMatrix[category];
        var distanceKm = (decimal)(route.DistanceMeters / 1000.0);
        var durationMin = (decimal)(route.DurationSeconds / 60.0);
        var price = baseFare + (perKm * distanceKm) + (perMinute * durationMin);

        return new FareEstimateResponse(
            Category: category,
            EstimatedPriceTzs: Math.Round(price, 0),
            DistanceMeters: route.DistanceMeters,
            DurationSeconds: route.DurationSeconds
        );
    }

    public async Task<TripResponse> RequestTripAsync(TripRequestDto request, Guid passengerId)
    {
        var pickup = Gf.CreatePoint(new Coordinate(request.PickupLongitude, request.PickupLatitude));
        var dropoff = Gf.CreatePoint(new Coordinate(request.DropoffLongitude, request.DropoffLatitude));

        var fare = await EstimateTripPriceAsync(
            request.PickupLatitude, request.PickupLongitude,
            request.DropoffLatitude, request.DropoffLongitude,
            request.CategoryRequested);

        var trip = new Trip
        {
            Id = Guid.NewGuid(),
            PassengerId = passengerId,
            CategoryRequested = request.CategoryRequested,
            Status = TripStatus.Requested,
            PickupLocation = pickup,
            DropoffLocation = dropoff,
            PickupAddress = request.PickupAddress,
            DropoffAddress = request.DropoffAddress,
            EstimatedPrice = fare.EstimatedPriceTzs,
            PaymentMethod = request.PaymentMethod,
            CreatedAt = DateTime.UtcNow
        };

        _db.Trips.Add(trip);
        await _db.SaveChangesAsync();

        _logger.LogInformation("Trip {TripId} requested by passenger {PassengerId}", trip.Id, passengerId);

        return MapToResponse(trip);
    }

    /// <summary>
    /// Accept a trip. driverUserId is the authenticated user's ID (from auth token/header),
    /// NOT an arbitrary driver profile ID from the request body.
    /// </summary>
    public async Task<TripResponse> AcceptTripAsync(Guid tripId, Guid driverUserId)
    {
        var trip = await _db.Trips
            .Include(t => t.Passenger)
            .FirstOrDefaultAsync(t => t.Id == tripId);

        if (trip is null)
            throw new InvalidOperationException("Trip not found.");

        if (trip.Status != TripStatus.Requested)
            throw new InvalidOperationException($"Trip cannot be accepted. Current status: {trip.Status}.");

        // Derive driver profile from authenticated user ID, not from request body.
        var driver = await _db.DriverProfiles
            .Include(d => d.User)
            .Include(d => d.Vehicle)
            .FirstOrDefaultAsync(d => d.UserId == driverUserId);

        if (driver is null)
            throw new InvalidOperationException("Driver profile not found for this user.");

        if (driver.IsBusy)
            throw new InvalidOperationException("Driver is already on a trip.");

        trip.DriverId = driver.Id;
        trip.Status = TripStatus.DriverAssigned;
        driver.IsBusy = true;

        await _db.SaveChangesAsync();

        _logger.LogInformation("Trip {TripId} accepted by driver {DriverId} (userId {UserId})",
            tripId, driver.Id, driverUserId);

        var response = MapToResponse(trip);

        await _dispatcher.SendToUserAsync(trip.PassengerId, "TripAccepted", response);

        return response;
    }

    public async Task<TripResponse> UpdateTripStatusAsync(Guid tripId, TripStatus newStatus, Guid triggeredByUserId)
    {
        var trip = await _db.Trips
            .Include(t => t.Passenger)
            .Include(t => t.Driver!).ThenInclude(d => d.User)
            .Include(t => t.Driver!).ThenInclude(d => d.Vehicle)
            .FirstOrDefaultAsync(t => t.Id == tripId);

        if (trip is null)
            throw new InvalidOperationException("Trip not found.");

        // Verify the triggering user is a trip participant.
        var isPassenger = trip.PassengerId == triggeredByUserId;
        var isDriver = trip.Driver?.UserId == triggeredByUserId;

        if (!isPassenger && !isDriver)
            throw new UnauthorizedAccessException(
                "Only the trip's passenger or assigned driver can update trip status.");

        // Enforce role-specific transition rules.
        var allowed = (trip.Status, newStatus, isDriver, isPassenger) switch
        {
            // Driver-only transitions
            (TripStatus.DriverAssigned, TripStatus.DriverArrived, true, _) => true,
            (TripStatus.DriverArrived, TripStatus.InProgress, true, _) => true,
            (TripStatus.InProgress, TripStatus.Completed, true, _) => true,

            // Either party can cancel (before trip starts)
            (TripStatus.Requested, TripStatus.Cancelled, _, true) => true,
            (TripStatus.DriverAssigned, TripStatus.Cancelled, _, _) => true,
            (TripStatus.DriverArrived, TripStatus.Cancelled, _, _) => true,

            _ => false
        };

        if (!allowed)
            throw new InvalidOperationException(
                $"Invalid state transition: {trip.Status} → {newStatus} by {(isDriver ? "driver" : "passenger")}.");

        var previousStatus = trip.Status;
        trip.Status = newStatus;

        if (newStatus == TripStatus.Completed)
        {
            trip.CompletedAt = DateTime.UtcNow;
            trip.FinalPrice = trip.EstimatedPrice;

            if (trip.Driver is not null)
                trip.Driver.IsBusy = false;

            await ProcessTripPaymentAsync(trip);
        }

        if (newStatus == TripStatus.Cancelled && trip.Driver is not null)
            trip.Driver.IsBusy = false;

        _db.TripEvents.Add(new TripEvent
        {
            Id = Guid.NewGuid(),
            TripId = trip.Id,
            FromStatus = previousStatus,
            ToStatus = newStatus,
            TriggeredByUserId = triggeredByUserId,
            Timestamp = DateTime.UtcNow
        });

        await _db.SaveChangesAsync();

        _logger.LogInformation("Trip {TripId}: {From} → {To}", tripId, previousStatus, newStatus);

        var response = MapToResponse(trip);

        await _dispatcher.SendToUserAsync(trip.PassengerId, "TripUpdated", response);

        if (trip.Driver?.UserId is { } driverUserId)
            await _dispatcher.SendToUserAsync(driverUserId, "TripUpdated", response);

        return response;
    }

    public async Task<TripResponse> GetTripForUserAsync(Guid tripId, Guid userId)
    {
        var trip = await _db.Trips
            .Include(t => t.Passenger)
            .Include(t => t.Driver!).ThenInclude(d => d.User)
            .Include(t => t.Driver!).ThenInclude(d => d.Vehicle)
            .FirstOrDefaultAsync(t => t.Id == tripId);

        if (trip is null)
            throw new InvalidOperationException("Trip not found.");

        if (trip.PassengerId != userId && trip.Driver?.UserId != userId)
            throw new UnauthorizedAccessException(
                "Only the trip's passenger or assigned driver can view trip details.");

        return MapToResponse(trip);
    }

    private async Task ProcessTripPaymentAsync(Trip trip)
    {
        var finalPrice = trip.FinalPrice ?? trip.EstimatedPrice ?? 0m;
        if (finalPrice <= 0 || trip.DriverId is null) return;

        var wallet = await GetOrCreateWalletAsync(trip.DriverId.Value);

        switch (trip.PaymentMethod)
        {
            case PaymentMethod.Cash:
                // Passenger pays driver directly. Platform deducts commission from driver.
                var commission = Math.Round(finalPrice * PlatformCommissionRate, 0);
                wallet.BalanceTzs -= commission;
                wallet.UpdatedAt = DateTime.UtcNow;

                _db.WalletTransactions.Add(new WalletTransaction
                {
                    Id = Guid.NewGuid(),
                    WalletId = wallet.Id,
                    TripId = trip.Id,
                    Type = WalletTransactionType.CommissionDeduction,
                    AmountTzs = -commission,
                    BalanceAfterTzs = wallet.BalanceTzs,
                    Description = $"Commission on cash trip {trip.Id}",
                    Timestamp = DateTime.UtcNow
                });

                _logger.LogInformation(
                    "Cash trip {TripId}: deducted {Commission} TZS commission from driver {DriverId}",
                    trip.Id, commission, trip.DriverId);
                break;

            case PaymentMethod.Stripe:
                // Passenger pays platform via Stripe. Platform credits driver's share.
                var driverShare = Math.Round(finalPrice * DriverShareRate, 0);
                wallet.BalanceTzs += driverShare;
                wallet.UpdatedAt = DateTime.UtcNow;

                _db.WalletTransactions.Add(new WalletTransaction
                {
                    Id = Guid.NewGuid(),
                    WalletId = wallet.Id,
                    TripId = trip.Id,
                    Type = WalletTransactionType.StripeFareCredit,
                    AmountTzs = driverShare,
                    BalanceAfterTzs = wallet.BalanceTzs,
                    Description = $"Stripe fare credit for trip {trip.Id}",
                    Timestamp = DateTime.UtcNow
                });

                _logger.LogInformation(
                    "Stripe trip {TripId}: credited {Share} TZS to driver {DriverId}",
                    trip.Id, driverShare, trip.DriverId);
                break;

            default:
                _logger.LogWarning("Trip {TripId} completed with unsupported payment method {Method}",
                    trip.Id, trip.PaymentMethod);
                break;
        }
    }

    private async Task<Wallet> GetOrCreateWalletAsync(Guid driverId)
    {
        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.DriverId == driverId);

        if (wallet is not null) return wallet;

        wallet = new Wallet
        {
            Id = Guid.NewGuid(),
            DriverId = driverId,
            BalanceTzs = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _db.Wallets.Add(wallet);

        _logger.LogInformation("Created wallet for driver {DriverId}", driverId);
        return wallet;
    }

    private static TripResponse MapToResponse(Trip trip)
    {
        var vehicle = trip.Driver?.Vehicle;
        var vehicleDesc = vehicle is not null
            ? $"{vehicle.MakeModel} ({vehicle.LicensePlate}) - {vehicle.Color}"
            : null;

        return new TripResponse(
            TripId: trip.Id,
            Status: trip.Status,
            DriverId: trip.DriverId,
            DriverName: trip.Driver?.User.FullName,
            VehicleDescription: vehicleDesc,
            EstimatedPriceTzs: trip.EstimatedPrice,
            CreatedAt: trip.CreatedAt
        );
    }
}
