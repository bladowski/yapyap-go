using System.Text.Json;
using YapYap.Core.Enums;

namespace YapYap.Core.Entities;

public class TripEvent
{
    public Guid Id { get; set; }
    public Guid TripId { get; set; }
    public TripStatus FromStatus { get; set; }
    public TripStatus ToStatus { get; set; }
    public Guid? TriggeredByUserId { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public JsonDocument? Metadata { get; set; }

    public Trip Trip { get; set; } = null!;
}
