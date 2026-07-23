using YapYap.Core.Enums;

namespace YapYap.Core.DTOs;

public record FareEstimateResponse(
    VehicleCategory Category,
    decimal EstimatedPriceTzs,
    double DistanceMeters,
    double DurationSeconds,
    string Currency = "TZS"
);

public record TripRequestDto(
    double PickupLatitude,
    double PickupLongitude,
    double DropoffLatitude,
    double DropoffLongitude,
    string? PickupAddress,
    string? DropoffAddress,
    VehicleCategory CategoryRequested,
    PaymentMethod PaymentMethod
);

public record TripResponse(
    Guid TripId,
    TripStatus Status,
    Guid? DriverId,
    string? DriverName,
    string? VehicleDescription,
    decimal? EstimatedPriceTzs,
    DateTime CreatedAt
);

public record DriverLocationDto(
    Guid DriverId,
    double Latitude,
    double Longitude,
    DateTime Timestamp
);

public record NearbyDriverDto(
    Guid DriverId,
    string DriverName,
    VehicleCategory Category,
    string LicensePlate,
    string MakeModel,
    string Color,
    double DistanceMeters,
    double Latitude,
    double Longitude
);

public record AcceptTripDto(Guid DriverId);

public class AcceptTripRequest
{
    public Guid DriverId { get; init; }
}

public class UpdateTripStatusRequest
{
    public TripStatus NewStatus { get; init; }
}
