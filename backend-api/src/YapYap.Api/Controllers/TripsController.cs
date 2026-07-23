using Microsoft.AspNetCore.Mvc;
using YapYap.Core.DTOs;
using YapYap.Infrastructure.Services;

namespace YapYap.Api.Controllers;

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

    /// <summary>Get trip details by ID.</summary>
    [HttpGet("{tripId:guid}")]
    public async Task<ActionResult> GetTrip(Guid tripId)
    {
        // Simple endpoint — full trip history will be added post-MVP.
        return Ok(new { TripId = tripId, Message = "Use SignalR for real-time trip updates." });
    }

    /// <summary>Driver accepts a trip. Pass driverId in request body.</summary>
    [HttpPost("{tripId:guid}/accept")]
    public async Task<ActionResult<TripResponse>> AcceptTrip(
        Guid tripId,
        [FromBody] AcceptTripRequest request)
    {
        var trip = await _tripService.AcceptTripAsync(tripId, request.DriverId);
        return Ok(trip);
    }

    /// <summary>Update trip status (DriverArrived, InProgress, Completed, Cancelled).</summary>
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
