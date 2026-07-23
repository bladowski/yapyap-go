namespace YapYap.Core.Enums;

public enum WalletTransactionType
{
    /// <summary>Driver paid commission on a cash trip (debit).</summary>
    CommissionDeduction = 0,

    /// <summary>Driver received fare share from a Stripe trip (credit).</summary>
    StripeFareCredit = 1,

    /// <summary>Manual adjustment by admin.</summary>
    Adjustment = 2,

    /// <summary>Driver payout / withdrawal.</summary>
    Payout = 3
}
