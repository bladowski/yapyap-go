using System.Collections.Concurrent;

namespace YapYap.Infrastructure.Services;

public class ConnectionTracker
{
    private readonly ConcurrentDictionary<Guid, string> _userToConnection = new();
    private readonly ConcurrentDictionary<string, Guid> _connectionToUser = new();

    public void Add(Guid userId, string connectionId)
    {
        _userToConnection[userId] = connectionId;
        _connectionToUser[connectionId] = userId;
    }

    public void Remove(string connectionId)
    {
        if (_connectionToUser.TryRemove(connectionId, out var userId))
            _userToConnection.TryRemove(userId, out _);
    }

    public string? GetConnectionId(Guid userId)
    {
        _userToConnection.TryGetValue(userId, out var connId);
        return connId;
    }

    public Guid? GetUserId(string connectionId)
    {
        _connectionToUser.TryGetValue(connectionId, out var userId);
        return userId;
    }
}
