using Microsoft.AspNetCore.Mvc;
using YapYap.Core.DTOs;
using YapYap.Infrastructure.Services;

namespace YapYap.Api.Controllers;

// SECURITY: The X-User-Id header pattern is an MVP placeholder.
// Post-MVP, replace with JWT bearer auth: [Authorize] + User.FindFirstValue(ClaimTypes.NameIdentifier).
// See hubs and DriversController for the same pattern.

[ApiController]
[Route("api/v1/trips")]
public class TripsController : ControllerBase
{
    private readonly TripService _tripService;

    public TripsController(TripService tripService)
    {
        _tripService = tripService;
    }

    /// <summary>Get a fare estimate before booking.</summary>
    [HttpPost("estimate")]
    public async Task<ActionResult<FareEstimateResponse>> Estimate([FromBody] TripRequestDto request)
    {
        var fare = await _tripService.EstimateTripPriceAsync(
            request.PickupLatitude, request.PickupLongitude,
            request.DropoffLatitude, request.DropoffLongitude,
            request.CategoryRequested);
        return Ok(fare);
    }

    /// <summary>Passenger requests a ride.</summary>
    [HttpPost]
    public async Task<ActionResult<TripResponse>> RequestTrip(
        [FromBody] TripRequestDto request,
        [FromHeader(Name = "X-User-Id")] Guid passengerId)
    {
        var trip = await _tripService.RequestTripAsync(request, passengerId);
        return CreatedAtAction(nameof(GetTrip), new { tripId = trip.TripId }, trip);
    }

    /// <summary>Get trip details by ID. Caller must be a participant.</summary>
    [HttpGet("{tripId:guid}")]
    public async Task<ActionResult> GetTrip(
        Guid tripId,
        [FromHeader(Name = "X-User-Id")] Guid userId)
    {
        var trip = await _tripService.GetTripForUserAsync(tripId, userId);
        return Ok(trip);
    }

    /// <summary>
    /// Driver accepts a trip. The driver's identity is derived from the X-User-Id header,
    /// not from a spoofable request body field.
    /// </summary>
    [HttpPost("{tripId:guid}/accept")]
    public async Task<ActionResult<TripResponse>> AcceptTrip(
        Guid tripId,
        [FromHeader(Name = "X-User-Id")] Guid driverUserId)
    {
        var trip = await _tripService.AcceptTripAsync(tripId, driverUserId);
        return Ok(trip);
    }

    /// <summary>Update trip status. Caller must be a participant; role-based transitions enforced.</summary>
    [HttpPost("{tripId:guid}/status")]
    public async Task<ActionResult<TripResponse>> UpdateStatus(
        Guid tripId,
        [FromBody] UpdateTripStatusRequest request,
        [FromHeader(Name = "X-User-Id")] Guid userId)
    {
        var trip = await _tripService.UpdateTripStatusAsync(tripId, request.NewStatus, userId);
        return Ok(trip);
    }
}
