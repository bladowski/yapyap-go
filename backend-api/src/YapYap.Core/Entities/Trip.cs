using NetTopologySuite.Geometries;
using YapYap.Core.Enums;

namespace YapYap.Core.Entities;

public class Trip
{
    public Guid Id { get; set; }
    public Guid PassengerId { get; set; }
    public Guid? DriverId { get; set; }
    public VehicleCategory CategoryRequested { get; set; }
    public TripStatus Status { get; set; }
    public Point PickupLocation { get; set; } = null!;
    public Point DropoffLocation { get; set; } = null!;
    public string? PickupAddress { get; set; }
    public string? DropoffAddress { get; set; }
    public decimal? EstimatedPrice { get; set; }
    public decimal? FinalPrice { get; set; }
    public PaymentMethod PaymentMethod { get; set; }
    public string? StripePaymentIntentId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }

    public User Passenger { get; set; } = null!;
    public DriverProfile? Driver { get; set; }
    public ICollection<TripEvent> Events { get; set; } = new List<TripEvent>();
    public Payment? Payment { get; set; }
}
