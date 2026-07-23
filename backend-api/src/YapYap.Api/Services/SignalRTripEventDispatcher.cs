using Microsoft.AspNetCore.SignalR;
using YapYap.Api.Hubs;
using YapYap.Core.Interfaces;
using YapYap.Infrastructure.Services;

namespace YapYap.Api.Services;

public class SignalRTripEventDispatcher : ITripEventDispatcher
{
    private readonly IHubContext<TripHub> _hub;
    private readonly ConnectionTracker _connections;

    public SignalRTripEventDispatcher(IHubContext<TripHub> hub, ConnectionTracker connections)
    {
        _hub = hub;
        _connections = connections;
    }

    public async Task SendToUserAsync(Guid userId, string method, object? arg)
    {
        var connectionId = _connections.GetConnectionId(userId);
        if (connectionId is not null)
            await _hub.Clients.Client(connectionId).SendAsync(method, arg);
    }
}
