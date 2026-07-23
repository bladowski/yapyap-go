using Microsoft.AspNetCore.SignalR;
using YapYap.Infrastructure.Services;

namespace YapYap.Api.Hubs;

// SECURITY: The userId parameter in RegisterAsync is an MVP placeholder.
// Post-MVP, replace with [Authorize] + Context.UserIdentifier from JWT bearer auth.

/// <summary>
/// Hub for trip state change events. Passengers and drivers connect here
/// to receive real-time trip updates (accepted, arrived, started, completed, cancelled).
/// </summary>
public class TripHub : Hub
{
    private readonly ConnectionTracker _connections;
    private readonly ILogger<TripHub> _logger;

    public TripHub(ConnectionTracker connections, ILogger<TripHub> logger)
    {
        _connections = connections;
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        await base.OnConnectedAsync();
        _logger.LogDebug("TripHub client connected: {ConnectionId}", Context.ConnectionId);
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _connections.Remove(Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Associates a connection with a user so they receive trip notifications.
    /// Both passengers and drivers call this after connecting.
    /// </summary>
    public Task RegisterAsync(Guid userId)
    {
        _connections.Add(userId, Context.ConnectionId);
        _logger.LogInformation("TripHub registered user {UserId} on connection {ConnId}", userId, Context.ConnectionId);
        return Task.CompletedTask;
    }
}
