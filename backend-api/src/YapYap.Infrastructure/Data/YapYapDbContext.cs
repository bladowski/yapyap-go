using Microsoft.EntityFrameworkCore;
using YapYap.Core.Entities;
using YapYap.Core.Enums;

namespace YapYap.Infrastructure.Data;

public class YapYapDbContext : DbContext
{
    public YapYapDbContext(DbContextOptions<YapYapDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Vehicle> Vehicles => Set<Vehicle>();
    public DbSet<DriverProfile> DriverProfiles => Set<DriverProfile>();
    public DbSet<Trip> Trips => Set<Trip>();
    public DbSet<TripEvent> TripEvents => Set<TripEvent>();
    public DbSet<Payment> Payments => Set<Payment>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.HasPostgresExtension("postgis");

        ConfigureUser(builder);
        ConfigureVehicle(builder);
        ConfigureDriverProfile(builder);
        ConfigureTrip(builder);
        ConfigureTripEvent(builder);
        ConfigurePayment(builder);
    }

    private static void ConfigureUser(ModelBuilder builder)
    {
        var entity = builder.Entity<User>();

        entity.ToTable("users");

        entity.HasKey(u => u.Id);
        entity.HasIndex(u => u.PhoneNumber).IsUnique();
        entity.HasIndex(u => u.Role);

        entity.Property(u => u.PhoneNumber).HasMaxLength(20).IsRequired();
        entity.Property(u => u.FullName).HasMaxLength(200).IsRequired();
        entity.Property(u => u.LanguagePreference).HasMaxLength(5).HasDefaultValue("sw");
        entity.Property(u => u.CreatedAt).HasDefaultValueSql("now() AT TIME ZONE 'utc'");
        entity.Property(u => u.IsActive).HasDefaultValue(true);

        entity.Property(u => u.Role)
            .HasConversion<string>()
            .HasMaxLength(20);
    }

    private static void ConfigureVehicle(ModelBuilder builder)
    {
        var entity = builder.Entity<Vehicle>();

        entity.ToTable("vehicles");

        entity.HasKey(v => v.Id);
        entity.HasIndex(v => v.DriverId).IsUnique();

        entity.Property(v => v.LicensePlate).HasMaxLength(20).IsRequired();
        entity.Property(v => v.MakeModel).HasMaxLength(100).IsRequired();
        entity.Property(v => v.Color).HasMaxLength(30).IsRequired();

        entity.Property(v => v.Category)
            .HasConversion<string>()
            .HasMaxLength(20);

        entity.HasOne(v => v.Driver)
            .WithOne(d => d.Vehicle!)
            .HasForeignKey<Vehicle>(v => v.DriverId)
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureDriverProfile(ModelBuilder builder)
    {
        var entity = builder.Entity<DriverProfile>();

        entity.ToTable("driver_profiles");

        entity.HasKey(d => d.Id);
        entity.HasIndex(d => d.UserId).IsUnique();

        entity.Property(d => d.Rating)
            .HasPrecision(3, 2)
            .HasDefaultValue(5.00m);

        entity.HasIndex(d => d.CurrentLocation)
            .HasMethod("GIST");

        entity.HasOne(d => d.User)
            .WithOne()
            .HasForeignKey<DriverProfile>(d => d.UserId)
            .OnDelete(DeleteBehavior.Restrict);
    }

    private static void ConfigureTrip(ModelBuilder builder)
    {
        var entity = builder.Entity<Trip>();

        entity.ToTable("trips");

        entity.HasKey(t => t.Id);
        entity.HasIndex(t => t.PassengerId);
        entity.HasIndex(t => t.DriverId);
        entity.HasIndex(t => t.Status);
        entity.HasIndex(t => t.CreatedAt);

        entity.HasIndex(t => t.PickupLocation).HasMethod("GIST");
        entity.HasIndex(t => t.DropoffLocation).HasMethod("GIST");

        entity.Property(t => t.PickupAddress).HasMaxLength(500);
        entity.Property(t => t.DropoffAddress).HasMaxLength(500);
        entity.Property(t => t.EstimatedPrice).HasPrecision(10, 2);
        entity.Property(t => t.FinalPrice).HasPrecision(10, 2);
        entity.Property(t => t.CreatedAt).HasDefaultValueSql("now() AT TIME ZONE 'utc'");

        entity.Property(t => t.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        entity.Property(t => t.CategoryRequested)
            .HasConversion<string>()
            .HasMaxLength(20);

        entity.Property(t => t.PaymentMethod)
            .HasConversion<string>()
            .HasMaxLength(20);

        entity.HasOne(t => t.Passenger)
            .WithMany()
            .HasForeignKey(t => t.PassengerId)
            .OnDelete(DeleteBehavior.Restrict);

        entity.HasOne(t => t.Driver)
            .WithMany()
            .HasForeignKey(t => t.DriverId)
            .OnDelete(DeleteBehavior.SetNull);
    }

    private static void ConfigureTripEvent(ModelBuilder builder)
    {
        var entity = builder.Entity<TripEvent>();

        entity.ToTable("trip_events");

        entity.HasKey(te => te.Id);
        entity.HasIndex(te => te.TripId);
        entity.HasIndex(te => te.Timestamp);

        entity.Property(te => te.FromStatus)
            .HasConversion<string>()
            .HasMaxLength(20);

        entity.Property(te => te.ToStatus)
            .HasConversion<string>()
            .HasMaxLength(20);

        entity.HasOne(te => te.Trip)
            .WithMany(t => t.Events)
            .HasForeignKey(te => te.TripId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    private static void ConfigurePayment(ModelBuilder builder)
    {
        var entity = builder.Entity<Payment>();

        entity.ToTable("payments");

        entity.HasKey(p => p.Id);
        entity.HasIndex(p => p.TripId).IsUnique();
        entity.HasIndex(p => p.TransactionRef).IsUnique().HasFilter(null);

        entity.Property(p => p.Amount).HasPrecision(10, 2);
        entity.Property(p => p.Currency).HasMaxLength(3).HasDefaultValue("TZS");
        entity.Property(p => p.Provider).HasMaxLength(50).IsRequired();
        entity.Property(p => p.TransactionRef).HasMaxLength(100);
        entity.Property(p => p.Timestamp).HasDefaultValueSql("now() AT TIME ZONE 'utc'");

        entity.Property(p => p.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        entity.HasOne(p => p.Trip)
            .WithOne(t => t.Payment)
            .HasForeignKey<Payment>(p => p.TripId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
