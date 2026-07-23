# Tech Stack — YapYap MVP

## 1. Overview

MVP is a single-region, single-instance deployment optimised for rapid iteration with the Zanzibar driver/client network. Everything runs through one monolithic backend; the three client surfaces (passenger, driver, admin) are separate codebases.

## 2. Stack Matrix

| Layer              | Choice                               | Rationale (MVP)                                          |
| ------------------ | ------------------------------------ | -------------------------------------------------------- |
| **Mobile Apps**    | Flutter 3.x (Dart)                   | Single codebase → Android + iOS; rich map/ location plugins; two completely separate Flutter projects for clean permission & UI scopes |
| **Admin Panel**    | React 19 + Vite + TypeScript         | Lightweight SPA; fast dev loop; no SSR needed for an internal dashboard |
| **Backend**        | .NET 10 — ASP.NET Core Web API        | Single monolithic API serving all three clients; strong typing, mature ORM, first-class SignalR |
| **Database**       | PostgreSQL 16 + PostGIS 3            | Geospatial queries (nearest driver, geofence containment) via PostGIS; relational integrity for trips/payments |
| **ORM**            | Entity Framework Core 10 + `Npgsql.EntityFrameworkCore.PostgreSQL.NetTopologySuite` | Spatial type mapping (Point, Polygon) directly in C#; migrations as code |
| **Real-Time**      | ASP.NET Core SignalR (in-memory)      | WebSocket fan-out to passenger/driver; in-memory hub group management — no Redis backplane needed at single-instance scale |
| **Caching / State**| In-memory (ConcurrentDictionary)      | Ephemeral driver locations, online presence, pending ride broadcasts — all live in the API process; lost on restart, acceptable for MVP |
| **Message Queue**  | None (MVP)                           | Synchronous in-process dispatch for ride matching, notifications; no background workers yet |
| **Payments**       | Deferred (MVP v2)                    | Cash-only recorded in-app; mobile-money integration added post-MVP |
| **Notifications**  | Firebase Cloud Messaging (FCM) + APNs | Push to passenger & driver apps; sent directly from backend via Firebase Admin SDK |
| **Maps / Routing** | Google Maps or OpenStreetMap (OSRM)  | Geocoding, reverse-geocoding, ETA; final decision deferred to Flutter app spike |
| **Object Storage**  | AWS S3 or Cloudflare R2             | Driver licence uploads, profile photos                          |
| **CI/CD**          | GitHub Actions                        | Lint → build → test → containerise per service                  |

## 3. Monorepo Structure

```
yapyap-go/
├── mobile-passenger/    # Flutter — Passenger App
├── mobile-driver/       # Flutter — Driver App
├── web-admin/           # React + Vite — Admin Panel
├── backend-api/         # .NET 10 ASP.NET Core Web API
├── docker-compose.yml   # PostgreSQL + PostGIS (dev)
└── docs/                # Requirements, architecture, ADRs
```

## 4. Backend Project Layout (backend-api/)

```
backend-api/
├── YapYap.sln
├── src/
│   └── YapYap.Api/           # ASP.NET Core host, Program.cs, controllers/hubs
│   └── YapYap.Core/          # Domain entities, enums, interfaces
│   └── YapYap.Infrastructure/# EF Core DbContext, migrations, repositories
├── tests/
│   └── YapYap.Api.Tests/     # Integration / controller tests
```

## 5. Key Backend Dependencies (NuGet)

| Package                                                    | Purpose                        |
| ---------------------------------------------------------- | ------------------------------ |
| `Microsoft.AspNetCore.SignalR`                            | Real-time hubs (included)      |
| `Npgsql.EntityFrameworkCore.PostgreSQL`                   | EF Core PostgreSQL provider    |
| `Npgsql.EntityFrameworkCore.PostgreSQL.NetTopologySuite` | Spatial type support (PostGIS) |
| `NetTopologySuite`                                         | Geo types: Point, Polygon      |
| `FirebaseAdmin`                                            | FCM push notifications         |
| `Swashbuckle.AspNetCore`                                   | Swagger / OpenAPI in dev       |

## 6. Database Connection (dev)

Connection string pattern (via `docker-compose`):

```
Host=localhost;Port=5432;Database=yapyap;Username=yapyap;Password=yapyap_dev
```

PostGIS extension enabled on first migration or startup.

## 7. Dev Environment Quick-Start

```bash
# 1. Start PostgreSQL
docker compose up -d

# 2. Run backend
cd backend-api
dotnet run --project src/YapYap.Api

# 3. Swagger UI at https://localhost:5001/swagger
```

## 8. What's Deferred to v2

- Redis / distributed SignalR backplane
- Message queue (RabbitMQ / SQS)
- Mobile-money payment integration
- Kubernetes / multi-instance deployment
- APM / distributed tracing
- CDN for static assets
