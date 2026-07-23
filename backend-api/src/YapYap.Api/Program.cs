using Microsoft.EntityFrameworkCore;
using YapYap.Api.Hubs;
using YapYap.Api.Services;
using YapYap.Core.Interfaces;
using YapYap.Infrastructure.Data;
using YapYap.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
    });
builder.Services.AddOpenApi();
builder.Services.AddSignalR();

builder.Services.AddDbContext<YapYapDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions => npgsqlOptions.UseNetTopologySuite()));

builder.Services.AddSingleton<ConnectionTracker>();
builder.Services.AddScoped<IMapService, MockMapService>();
builder.Services.AddScoped<ITripEventDispatcher, SignalRTripEventDispatcher>();
builder.Services.AddScoped<TripService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    await DbInitializer.InitializeAsync(app.Services);
}

app.UseAuthorization();
app.MapControllers();
app.MapHub<DriverLocationHub>("/hubs/location");
app.MapHub<TripHub>("/hubs/trip");

app.Run();
