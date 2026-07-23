using Microsoft.EntityFrameworkCore;
using YapYap.Api.Hubs;
using YapYap.Infrastructure.Data;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.Services.AddSignalR();

builder.Services.AddDbContext<YapYapDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions => npgsqlOptions.UseNetTopologySuite()));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseAuthorization();
app.MapControllers();
app.MapHub<YapYap.Api.Hubs.LocationHub>("/hubs/location");
app.MapHub<YapYap.Api.Hubs.TripHub>("/hubs/trip");

app.Run();
