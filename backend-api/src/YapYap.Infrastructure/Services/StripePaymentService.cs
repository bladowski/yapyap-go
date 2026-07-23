using Microsoft.Extensions.Logging;
using YapYap.Core.Interfaces;

namespace YapYap.Infrastructure.Services;

/// <summary>
/// MVP Stripe integration. Returns mocked payment intents.
/// Post-MVP: inject StripeClient with real API keys and replace mock logic
/// with actual Stripe PaymentIntent API calls.
/// </summary>
public class StripePaymentService : IPaymentGatewayService
{
    private readonly ILogger<StripePaymentService> _logger;

    public StripePaymentService(ILogger<StripePaymentService> logger)
    {
        _logger = logger;
    }

    public Task<PaymentIntentResult> CreatePaymentIntentAsync(Guid tripId, decimal amountTzs, string currency = "tzs")
    {
        var paymentIntentId = $"pi_mock_{Guid.NewGuid():N}"[..27];
        var clientSecret = $"{paymentIntentId}_secret_mock";

        _logger.LogInformation(
            "Mock Stripe: Created PaymentIntent {Id} for trip {TripId}, amount {Amount} {Currency}",
            paymentIntentId, tripId, amountTzs, currency);

        return Task.FromResult(new PaymentIntentResult(
            PaymentIntentId: paymentIntentId,
            ClientSecret: clientSecret,
            Amount: amountTzs,
            Currency: currency
        ));
    }

    public Task<PaymentConfirmation> ConfirmPaymentAsync(string paymentIntentId)
    {
        _logger.LogInformation(
            "Mock Stripe: Confirmed PaymentIntent {Id}", paymentIntentId);

        return Task.FromResult(new PaymentConfirmation(
            PaymentIntentId: paymentIntentId,
            Succeeded: true
        ));
    }
}
