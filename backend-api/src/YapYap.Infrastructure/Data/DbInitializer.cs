using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using NetTopologySuite.Geometries;
using YapYap.Core.Entities;
using YapYap.Core.Enums;

namespace YapYap.Infrastructure.Data;

public static class DbInitializer
{
    private static readonly GeometryFactory GeometryFactory =
        NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(4326);

    public static async Task InitializeAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<YapYapDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<YapYapDbContext>>();

        logger.LogInformation("Applying pending migrations...");
        await db.Database.MigrateAsync();

        if (await db.Users.AnyAsync())
        {
            logger.LogInformation("Database already seeded — skipping.");
            return;
        }

        logger.LogInformation("Seeding test data...");

        // Stone Town, Zanzibar coordinates (~WGS84 4326)
        var stoneTownPoint = GeometryFactory.CreatePoint(new Coordinate(39.1932, -6.1630));

        // --- Admin ---
        var admin = new User
        {
            Id = Guid.NewGuid(),
            PhoneNumber = "+255777000001",
            FullName = "Admin Mkuu",
            Role = UserRole.Admin,
            LanguagePreference = "sw"
        };
        db.Users.Add(admin);

        // --- Passenger ---
        var passenger = new User
        {
            Id = Guid.NewGuid(),
            PhoneNumber = "+255777000002",
            FullName = "Fatma Juma",
            Role = UserRole.Passenger,
            LanguagePreference = "sw"
        };
        db.Users.Add(passenger);

        // --- Driver 1 — Boda Boda ---
        var driver1User = new User
        {
            Id = Guid.NewGuid(),
            PhoneNumber = "+255777000003",
            FullName = "Juma Ali",
            Role = UserRole.Driver,
            LanguagePreference = "sw"
        };
        db.Users.Add(driver1User);

        var driver1Profile = new DriverProfile
        {
            Id = Guid.NewGuid(),
            UserId = driver1User.Id,
            IsOnline = true,
            IsBusy = false,
            CurrentLocation = GeometryFactory.CreatePoint(new Coordinate(39.1950, -6.1620)),
            LastLocationUpdate = DateTime.UtcNow,
            Rating = 4.80m
        };
        db.DriverProfiles.Add(driver1Profile);

        var vehicle1 = new Vehicle
        {
            Id = Guid.NewGuid(),
            DriverId = driver1Profile.Id,
            Category = VehicleCategory.BodaBoda,
            LicensePlate = "T123 ABC",
            MakeModel = "Bajaj Boxer 150",
            Color = "Black"
        };
        db.Vehicles.Add(vehicle1);

        // --- Driver 2 — Tuk Tuk ---
        var driver2User = new User
        {
            Id = Guid.NewGuid(),
            PhoneNumber = "+255777000004",
            FullName = "Hamisi Bakari",
            Role = UserRole.Driver,
            LanguagePreference = "sw"
        };
        db.Users.Add(driver2User);

        var driver2Profile = new DriverProfile
        {
            Id = Guid.NewGuid(),
            UserId = driver2User.Id,
            IsOnline = true,
            IsBusy = false,
            CurrentLocation = GeometryFactory.CreatePoint(new Coordinate(39.1900, -6.1640)),
            LastLocationUpdate = DateTime.UtcNow,
            Rating = 4.50m
        };
        db.DriverProfiles.Add(driver2Profile);

        var vehicle2 = new Vehicle
        {
            Id = Guid.NewGuid(),
            DriverId = driver2Profile.Id,
            Category = VehicleCategory.TukTuk,
            LicensePlate = "T456 DEF",
            MakeModel = "Bajaj RE 250",
            Color = "Yellow"
        };
        db.Vehicles.Add(vehicle2);

        await db.SaveChangesAsync();
        logger.LogInformation("Seed data inserted: 1 admin, 1 passenger, 2 drivers with vehicles.");
    }
}
