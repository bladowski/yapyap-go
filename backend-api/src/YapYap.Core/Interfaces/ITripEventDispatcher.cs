namespace YapYap.Core.Interfaces;

public interface ITripEventDispatcher
{
    Task SendToUserAsync(Guid userId, string method, object? arg);
}
