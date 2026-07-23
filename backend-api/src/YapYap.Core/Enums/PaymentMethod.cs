namespace YapYap.Core.Enums;

public enum PaymentMethod
{
    Cash = 0,
    Stripe = 1,
    // Post-MVP mobile money integrations:
    MPesa = 2,
    TigoPesa = 3,
    AirtelMoney = 4
}
