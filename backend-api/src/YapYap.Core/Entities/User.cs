using YapYap.Core.Enums;

namespace YapYap.Core.Entities;

public class User
{
    public Guid Id { get; set; }
    public string PhoneNumber { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public UserRole Role { get; set; }
    public string LanguagePreference { get; set; } = "sw";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
}
