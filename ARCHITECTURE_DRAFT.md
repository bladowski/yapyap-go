# Architecture Draft — YapYap

## 1. High-Level System Diagram

```
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Passenger App   │  │   Driver App     │  │   Admin Panel    │
│  (Android / iOS) │  │  (Android / iOS) │  │     (Web)        │
└────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                     │                     │
         │        REST / GraphQL / WebSocket          │
         ▼                     ▼                     ▼
┌─────────────────────────────────────────────────────────┐
│                    API Gateway                          │
│    Auth, rate-limiting, request routing, TLS term       │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Ride/Auth   │ │  Real-Time   │ │  Payment     │
│  Service     │ │  Service     │ │  Service     │
│              │ │              │ │              │
│ - Accounts   │ │ - Location   │ │ - Billing    │
│ - Trips      │ │   streaming  │ │ - M-Pesa     │
│ - Matching   │ │ - Driver     │ │ - Payouts    │
│ - Pricing    │ │   dispatch   │ │ - Commission │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │PostgreSQL│  │  Redis   │  │  Object  │  │  Message │ │
│  │(primary) │  │ (cache,  │  │  Store   │  │  Queue   │ │
│  │          │  │  pub/sub)│  │  (S3)    │  │          │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │
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

### 2.2 API Gateway

Single entry point that:
- Terminates TLS.
- Authenticates requests (JWT validation).
- Rate-limits per client type.
- Routes to internal services.
- Handles WebSocket upgrade for real-time connections.

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

Handles all persistent-connection traffic:
- **Location broadcast**: drivers push GPS coordinates every 3–5 seconds; service fans out to relevant passengers.
- **Ride dispatch**: new ride requests pushed to eligible drivers via WebSocket; first-accept wins.
- **Presence**: driver online/offline state tracked with heartbeat; stale connections evicted.
- Uses **Redis Pub/Sub** to fan out across horizontally-scaled service instances.
- Falls back to polling (HTTP long-polling or short-poll) when WebSocket is unavailable (poor network conditions).

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
- **Compute**: containerised services orchestrated via Kubernetes or a simpler PaaS (managed containers / App Engine) for v1.
- **CI/CD**: GitHub Actions for lint, test, build, deploy per service.
- **Monitoring**: structured logging to a central sink; metrics for ride volume, matching latency, payment success rate, WebSocket connection churn.
- **Backup**: daily automated PostgreSQL backups to object storage.

## 6. Open Decisions (for tech-stack prompt)

Platform needs to settle:
1. Mobile framework (native, React Native, Flutter).
2. Backend language & framework.
3. Database specifics (vanilla PostgreSQL vs. PostGIS extension for geo-queries).
4. Real-time transport (raw WebSockets vs. managed service like Ably/Pusher).
5. Message queue choice.
6. API protocol (REST vs. GraphQL vs. hybrid).
