using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using YapYap.Infrastructure.Data;
using YapYap.Infrastructure.Services;

namespace YapYap.Api.Hubs;

public class DriverLocationHub : Hub
{
    private readonly YapYapDbContext _db;
    private readonly ConnectionTracker _connections;
    private readonly ILogger<DriverLocationHub> _logger;

    private static readonly GeometryFactory Gf =
        NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);

    public DriverLocationHub(YapYapDbContext db, ConnectionTracker connections, ILogger<DriverLocationHub> logger)
    {
        _db = db;
        _connections = connections;
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        await base.OnConnectedAsync();
        _logger.LogInformation("Driver location client connected: {ConnectionId}", Context.ConnectionId);
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = _connections.GetUserId(Context.ConnectionId);
        if (userId is not null)
        {
            var driver = await _db.DriverProfiles.FirstOrDefaultAsync(d => d.UserId == userId.Value);
            if (driver is not null)
            {
                driver.IsOnline = false;
                await _db.SaveChangesAsync();
            }
        }
        _connections.Remove(Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Called by a driver to register their SignalR connection with their user account,
    /// go online, and optionally set initial location.
    /// </summary>
    public async Task RegisterDriverAsync(Guid userId, double latitude, double longitude)
    {
        var driver = await _db.DriverProfiles.FirstOrDefaultAsync(d => d.UserId == userId);
        if (driver is null)
        {
            _logger.LogWarning("RegisterDriverAsync: no driver profile for userId {UserId}", userId);
            return;
        }

        _connections.Add(userId, Context.ConnectionId);

        driver.IsOnline = true;
        driver.CurrentLocation = Gf.CreatePoint(new Coordinate(longitude, latitude));
        driver.LastLocationUpdate = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        _logger.LogInformation("Driver {DriverId} registered and online", driver.Id);
    }

    /// <summary>
    /// Streams a driver location update. Broadcasts to any passenger tracking this driver's active trip.
    /// </summary>
    public async Task SendLocationUpdateAsync(Guid userId, double latitude, double longitude)
    {
        var driver = await _db.DriverProfiles
            .Include(d => d.User)
            .FirstOrDefaultAsync(d => d.UserId == userId);

        if (driver is null) return;

        driver.CurrentLocation = Gf.CreatePoint(new Coordinate(longitude, latitude));
        driver.LastLocationUpdate = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        // Find the active trip where this driver is assigned and in progress
        var activeTrip = await _db.Trips
            .Where(t => t.DriverId == driver.Id &&
                        (t.Status == Core.Enums.TripStatus.DriverAssigned ||
                         t.Status == Core.Enums.TripStatus.DriverArrived ||
                         t.Status == Core.Enums.TripStatus.InProgress))
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync();

        if (activeTrip is not null)
        {
            var passengerConn = _connections.GetConnectionId(activeTrip.PassengerId);
            if (passengerConn is not null)
            {
                await Clients.Client(passengerConn).SendAsync("DriverLocationUpdated", new
                {
                    DriverId = driver.Id,
                    DriverName = driver.User.FullName,
                    Latitude = latitude,
                    Longitude = longitude,
                    Timestamp = DateTime.UtcNow
                });
            }
        }
    }
}
