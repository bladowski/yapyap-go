using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;
using YapYap.Core.DTOs;
using YapYap.Infrastructure.Data;

namespace YapYap.Api.Controllers;

[ApiController]
[Route("api/v1/drivers")]
public class DriversController : ControllerBase
{
    private readonly YapYapDbContext _db;

    private static readonly GeometryFactory Gf =
        NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);

    public DriversController(YapYapDbContext db)
    {
        _db = db;
    }

    /// <summary>
    /// Find nearby available drivers using PostGIS ST_DWithin.
    /// </summary>
    [HttpGet("nearby")]
    public async Task<ActionResult<List<NearbyDriverDto>>> GetNearbyDrivers(
        [FromQuery] double latitude,
        [FromQuery] double longitude,
        [FromQuery] double radiusMeters = 3000)
    {
        var searchPoint = Gf.CreatePoint(new Coordinate(longitude, latitude));
        var radiusDegrees = radiusMeters / 111_320.0;

        var drivers = await _db.DriverProfiles
            .Include(d => d.User)
            .Include(d => d.Vehicle)
            .Where(d => d.IsOnline && !d.IsBusy && d.CurrentLocation != null)
            .Where(d => d.CurrentLocation!.Distance(searchPoint) <= radiusDegrees)
            .OrderBy(d => d.CurrentLocation!.Distance(searchPoint))
            .Take(20)
            .Select(d => new NearbyDriverDto(
                DriverId: d.Id,
                DriverName: d.User.FullName,
                Category: d.Vehicle!.Category,
                LicensePlate: d.Vehicle.LicensePlate,
                MakeModel: d.Vehicle.MakeModel,
                Color: d.Vehicle.Color,
                DistanceMeters: Math.Round(d.CurrentLocation!.Distance(searchPoint) * 111_320, 0),
                Latitude: d.CurrentLocation!.Y,
                Longitude: d.CurrentLocation!.X
            ))
            .ToListAsync();

        return Ok(drivers);
    }

    /// <summary>
    /// Toggle online status. The X-User-Id header is verified against the driver's UserId
    /// to prevent impersonation.
    /// </summary>
    [HttpPost("{driverId:guid}/online")]
    public async Task<ActionResult> SetOnline(
        Guid driverId,
        [FromHeader(Name = "X-User-Id")] Guid userId,
        [FromQuery] bool online = true)
    {
        var driver = await _db.DriverProfiles.FindAsync(driverId);
        if (driver is null) return NotFound();

        if (driver.UserId != userId)
            return Forbid();

        driver.IsOnline = online;
        await _db.SaveChangesAsync();
        return Ok(new { driver.Id, driver.IsOnline });
    }
}
