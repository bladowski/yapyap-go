namespace YapYap.Core.Entities;

/// <summary>
/// A driver's financial ledger. Tracks what the driver owes the platform
/// (negative balance = debt from cash trips) or what the platform owes the driver
/// (positive balance = earnings from Stripe trips).
/// </summary>
public class Wallet
{
    public Guid Id { get; set; }
    public Guid DriverId { get; set; }

    /// <summary>
    /// Current balance in TZS. Positive = platform owes driver (Stripe trips).
    /// Negative = driver owes platform (cash trip commissions).
    /// </summary>
    public decimal BalanceTzs { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public DriverProfile Driver { get; set; } = null!;
    public ICollection<WalletTransaction> Transactions { get; set; } = new List<WalletTransaction>();
}
