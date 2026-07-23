using YapYap.Core.Enums;

namespace YapYap.Core.Entities;

public class Payment
{
    public Guid Id { get; set; }
    public Guid TripId { get; set; }
    public string Provider { get; set; } = null!;
    public PaymentStatus Status { get; set; }
    public string? TransactionRef { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "TZS";
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public Trip Trip { get; set; } = null!;
}
