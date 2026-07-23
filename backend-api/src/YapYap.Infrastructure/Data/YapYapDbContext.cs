using Microsoft.EntityFrameworkCore;

namespace YapYap.Infrastructure.Data;

public class YapYapDbContext : DbContext
{
    public YapYapDbContext(DbContextOptions<YapYapDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
    }
}
