namespace YapYap.Core.Interfaces;

public interface IPaymentGatewayService
{
    /// <summary>
    /// Creates a payment intent for a trip. Returns a client secret the
    /// mobile/web app uses to confirm the payment on-device (e.g., via Stripe SDK).
    /// </summary>
    Task<PaymentIntentResult> CreatePaymentIntentAsync(Guid tripId, decimal amountTzs, string currency = "tzs");

    /// <summary>
    /// Confirms a previously created payment intent.
    /// </summary>
    Task<PaymentConfirmation> ConfirmPaymentAsync(string paymentIntentId);
}

public record PaymentIntentResult(
    string PaymentIntentId,
    string ClientSecret,
    decimal Amount,
    string Currency
);

public record PaymentConfirmation(
    string PaymentIntentId,
    bool Succeeded,
    string? FailureReason = null
);
