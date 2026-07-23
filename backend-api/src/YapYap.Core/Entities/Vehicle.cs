using YapYap.Core.Enums;

namespace YapYap.Core.Entities;

public class Vehicle
{
    public Guid Id { get; set; }
    public Guid DriverId { get; set; }
    public VehicleCategory Category { get; set; }
    public string LicensePlate { get; set; } = null!;
    public string MakeModel { get; set; } = null!;
    public string Color { get; set; } = null!;

    public DriverProfile Driver { get; set; } = null!;
}
