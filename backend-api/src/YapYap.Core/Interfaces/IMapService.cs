using NetTopologySuite.Geometries;
using YapYap.Core.Models;

namespace YapYap.Core.Interfaces;

public interface IMapService
{
    Task<RouteResult> CalculateRouteAsync(Point origin, Point destination);
}
