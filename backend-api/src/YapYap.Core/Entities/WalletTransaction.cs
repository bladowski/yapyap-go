using YapYap.Core.Enums;

namespace YapYap.Core.Entities;

public class WalletTransaction
{
    public Guid Id { get; set; }
    public Guid WalletId { get; set; }
    public Guid? TripId { get; set; }
    public WalletTransactionType Type { get; set; }

    /// <summary>Positive = credit, negative = debit.</summary>
    public decimal AmountTzs { get; set; }

    /// <summary>Wallet balance after this transaction.</summary>
    public decimal BalanceAfterTzs { get; set; }

    public string? Description { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public Wallet Wallet { get; set; } = null!;
    public Trip? Trip { get; set; }
}
