using NetTopologySuite.Geometries;
using YapYap.Core.Interfaces;
using YapYap.Core.Models;

namespace YapYap.Infrastructure.Services;

public class MockMapService : IMapService
{
    public Task<RouteResult> CalculateRouteAsync(Point origin, Point destination)
    {
        var distance = origin.Distance(destination);
        var distanceMeters = distance * 111_320; // rough degrees→meters at equator
        var durationSeconds = distanceMeters / 7.5; // ~27 km/h avg urban speed

        return Task.FromResult(new RouteResult(
            DistanceMeters: Math.Round(distanceMeters, 0),
            DurationSeconds: Math.Round(durationSeconds, 0),
            EncodedPolyline: "mock_polyline_base64"
        ));
    }
}
