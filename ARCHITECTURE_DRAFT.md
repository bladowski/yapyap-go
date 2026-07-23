# Architecture Draft — YapYap

## 1. High-Level System Diagram

```
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Passenger App   │  │   Driver App     │  │   Admin Panel    │
│  (Flutter)       │  │  (Flutter)       │  │  (React + Vite)  │
└────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                     │                     │
         │     REST + SignalR WebSocket              │
         ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────┐
│            ASP.NET Core Web API (Monolith)              │
│                                                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │  Ride/Auth   │ │  SignalR     │ │  Payment     │    │
│  │  Controllers │ │  Hubs        │ │  Service     │    │
│  │              │ │              │ │              │    │
│  │ - Accounts   │ │ - Location   │ │ - Billing    │    │
│  │ - Trips      │ │   streaming  │ │ - Cash       │    │
│  │ - Matching   │ │ - Driver     │ │   recording  │    │
│  │ - Pricing    │ │   dispatch   │ │              │    │
│  └──────────────┘ └──────────────┘ └──────────────┘    │
│                                                         │
│  In-Memory State: driver locations, presence, dispatch   │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌──────────────────┐  ┌──────────────────┐             │
│  │ PostgreSQL 16    │  │  Object Store    │             │
│  │ + PostGIS 3      │  │  (S3 / R2)       │             │
│  │ (primary)        │  │                  │             │
│  └──────────────────┘  └──────────────────┘             │
└─────────────────────────────────────────────────────────┘
```

## 2. Component Breakdown

### 2.1 Client Applications

| App            | Platform       | Key Responsibilities                           |
| -------------- | -------------- | ---------------------------------------------- |
| Passenger App  | Android, iOS   | Map UX, ride request, tracking, payment, chat  |
| Driver App     | Android, iOS   | Online toggle, accept/reject, navigation, earnings |
| Admin Panel    | Web (SPA)      | Dashboards, driver verification, fare config, disputes |

Shared mobile concerns across both apps:
- Background location service (foreground service on Android, location updates on iOS).
- Network resilience queue (store-and-forward when offline).
- Push notification handler with deep-link routing.

### 2.2 ASP.NET Core Monolith (API + Real-Time)

The API Gateway, business logic, and real-time services run in a single ASP.NET Core process (MVP constraint):

- **Auth**: JWT bearer authentication; phone + OTP registration; role-based authorisation (Passenger, Driver, Admin).
- **REST Controllers**: accounts, trips, payments, admin CRUD — versioned under `/api/v1/`.
- **SignalR Hubs**: two hubs — `TripHub` (ride negotiation) and `LocationHub` (GPS streaming). In-memory group management; no Redis backplane at MVP scale.
- **Middlewares**: rate limiting, request logging, global exception handling.
- **Swagger / OpenAPI**: auto-generated during development.

### 2.3 Ride & Auth Service

The transactional core:
- **Accounts**: phone-based registration, OTP verification, profile CRUD, driver document upload.
- **Trips**: ride lifecycle state machine (requested → accepted → arrived → started → completed → cancelled).
- **Matching**: find nearest available drivers filtered by vehicle category; broadcast with timeout escalation (expand radius, notify next ring).
- **Pricing**: base fare × category + distance rate + time rate + surge multiplier. Surge calculated from zone-level supply/demand ratio.

State machine for a trip:

```
Requested ──► Accepted ──► Driver Arrived ──► Started ──► Completed
    │              │              │                │
    └──────────────┴──────────────┴────────────────┘
                        │
                        ▼
                   Cancelled
```

### 2.4 Real-Time Service

Handles all persistent-connection traffic via SignalR:
- **Location broadcast**: drivers push GPS coordinates every 3–5 seconds via `LocationHub`; service fans out to passengers tracking that driver's trip.
- **Ride dispatch**: new ride requests pushed to eligible drivers via `TripHub`; first-accept wins.
- **Presence**: driver online/offline state tracked via in-memory `ConcurrentDictionary` and SignalR connection lifecycle events (`OnConnectedAsync` / `OnDisconnectedAsync`); stale connections evicted automatically.
- **MVP note**: all state lives in-process — lost on restart, acceptable for single-instance v1.

### 2.5 Payment Service

- **Trip finalisation**: receives completed-trip event, calculates final fare (actual distance/time may differ from estimate).
- **Payment collection**: routes to cash marker or M-Pesa/Airtel Money API.
- **Driver wallet**: tracks what drivers owe the platform (commission on cash trips) and what the platform owes drivers (digital fares minus commission).
- **Settlement**: batch process that reconciles wallets and triggers payouts.

### 2.6 Admin Panel Backend

- Aggregated queries for dashboard metrics (rides/day, revenue, active drivers).
- CRUD for configuration tables (vehicle categories, fare parameters, surge rules, geofence polygons).
- Driver verification workflow: document submission → admin review → approve/reject with reason.
- Dispute management: passenger/driver can flag a trip; admin reviews trip log, adjusts fare or issues refund.

## 3. Data Flow: Ride Request (Happy Path)

```
Passenger App          API Gateway        Ride Service       Real-Time Svc        Driver App
     │                      │                   │                   │                   │
     │ 1. POST /rides       │                   │                   │                   │
     │─────────────────────►│                   │                   │                   │
     │                      │ 2. Create trip    │                   │                   │
     │                      │──────────────────►│                   │                   │
     │                      │                   │ 3. Find drivers   │                   │
     │                      │                   │──────────────────►│                   │
     │                      │                   │                   │ 4. Push request   │
     │                      │                   │                   │──────────────────►│
     │                      │                   │                   │                   │
     │                      │                   │                   │ 5. Driver accepts │
     │                      │                   │                   │◄──────────────────│
     │                      │                   │ 6. Trip accepted  │                   │
     │                      │                   │◄──────────────────│                   │
     │ 7. Driver + ETA      │                   │                   │                   │
     │◄─────────────────────│                   │                   │                   │
     │                      │                   │                   │                   │
     │ 8. Track location    │                   │                   │                   │
     │◄════════════════════════════════════════════════════════════════════════════════►│
     │   (WebSocket stream) │                   │                   │                   │
```

## 4. Database Schema — Core Entities

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   users      │     │   drivers    │     │   vehicles   │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ id (PK)      │     │ id (PK)      │     │ id (PK)      │
│ phone        │     │ user_id (FK) │     │ driver_id FK │
│ name         │     │ licence_no   │     │ category     │
│ role         │     │ status       │     │ plate_no     │
│ avatar_url   │     │ avg_rating   │     │ colour       │
│ created_at   │     │ is_online    │     │ make/model   │
└──────────────┘     │ lat, lng     │     │ verified     │
                     │ updated_at   │     └──────────────┘
                     └──────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    trips     │     │ trip_events  │     │  payments    │
├──────────────┤     ├──────────────┤     ├──────────────┤
│ id (PK)      │     │ id (PK)      │     │ id (PK)      │
│ passenger_id │     │ trip_id (FK) │     │ trip_id (FK) │
│ driver_id    │     │ event_type   │     │ amount       │
│ vehicle_cat  │     │ lat, lng     │     │ currency     │
│ status       │     │ metadata     │     │ method       │
│ pick_lat/lng │     │ created_at   │     │ status       │
│ drop_lat/lng │     └──────────────┘     │ created_at   │
│ fare_est     │                          └──────────────┘
│ fare_actual  │
│ surge_mult   │     ┌──────────────┐
│ created_at   │     │   ratings    │
│ updated_at   │     ├──────────────┤
└──────────────┘     │ id (PK)      │
                     │ trip_id (FK) │
┌──────────────┐     │ from_user_id │
│ driver_loc   │     │ to_user_id   │
├──────────────┤     │ score        │
│ driver_id PK │     │ comment      │
│ lat, lng     │     │ created_at   │
│ accuracy     │     └──────────────┘
│ heading      │
│ updated_at   │
└──────────────┘

┌──────────────┐
│ geofence     │
├──────────────┤
│ id (PK)      │
│ name         │
│ polygon      │ (PostGIS GEOMETRY or JSON array)
│ is_active    │
│ created_at   │
└──────────────┘
```

## 5. Infrastructure Notes

- **Hosting**: single cloud region closest to East Africa (e.g., AWS `af-south-1` Cape Town or GCP `africa-south1` Johannesburg) to minimise latency.
- **Compute (MVP)**: single VM or container instance running the ASP.NET Core monolith; scale vertically until demand warrants horizontal scaling.
- **Compute (post-MVP)**: containerised services orchestrated via Kubernetes or a managed container platform once multi-instance is needed.
- **CI/CD**: GitHub Actions for lint, test, build, deploy per service.
- **Monitoring**: structured logging to console / cloud sink; metrics for ride volume, matching latency, payment success rate, SignalR connection churn.
- **Backup**: daily automated PostgreSQL backups to object storage.

## 6. Technology Decisions (Resolved)

| # | Decision              | MVP Choice                              |
|---|-----------------------|-----------------------------------------|
| 1 | Mobile framework      | Flutter (two separate projects)         |
| 2 | Backend language      | C# / .NET 10 — ASP.NET Core Web API     |
| 3 | Database              | PostgreSQL 16 + PostGIS 3               |
| 4 | Real-time transport   | ASP.NET Core SignalR (in-memory)        |
| 5 | Message queue         | None — synchronous in-process for MVP   |
| 6 | API protocol          | REST + SignalR WebSocket                |
| 7 | Admin panel           | React 19 + Vite + TypeScript            |
