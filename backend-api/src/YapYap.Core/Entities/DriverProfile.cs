using NetTopologySuite.Geometries;

namespace YapYap.Core.Entities;

public class DriverProfile
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? VehicleId { get; set; }
    public bool IsOnline { get; set; }
    public bool IsBusy { get; set; }
    public Point? CurrentLocation { get; set; }
    public DateTime? LastLocationUpdate { get; set; }
    public decimal Rating { get; set; }

    public User User { get; set; } = null!;
    public Vehicle? Vehicle { get; set; }
}
