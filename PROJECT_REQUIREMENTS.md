# Project Requirements — YapYap (Zanzibar Ride-Hailing)

## 1. Product Vision

A ride-hailing platform purpose-built for the Zanzibar market. Unlike generic global platforms, YapYap is tailored to local transport realities — motorcycle taxis, tuk-tuks, and standard cars — with a driver network and client base already in place.

## 2. Core Domain

**Ride-hailing with three vehicle tiers**, each serving distinct use cases across Zanzibar's urban centres (Stone Town, Mbweni, Mwanakwerekwe) and tourist corridors (Nungwi, Paje, Jambiani, Kendwa).

| Category   | Swahili Term | Typical Use                               |
| ---------- | ------------ | ----------------------------------------- |
| Boda Boda  | Pikipiki     | Short solo trips, narrow streets, traffic |
| Tuk Tuk    | Bajaji       | 2–3 passengers, moderate distance         |
| Car        | Gari         | Airport transfers, groups, comfort        |

## 3. Actors

### 3.1 Passenger (Mteja)
- Register via phone number (SMS OTP) — email optional.
- Request a ride: pick-up, drop-off, vehicle category.
- Real-time driver tracking on a map.
- Fare estimate before booking.
- In-app chat or call with driver.
- Rate driver post-trip.
- Ride history and receipts.
- Cash and mobile-money payment (M-Pesa, Airtel Money, Tigo Pesa).

### 3.2 Driver (Dereva)
- Register with phone number, vehicle details, licence upload.
- Online / offline toggle.
- Accept, decline, or ignore incoming ride requests.
- Turn-by-turn navigation to pick-up then drop-off.
- Trip earnings dashboard.
- Cash and mobile-money reconciliation.

### 3.3 Admin (Msimamizi)
- Dashboard: active rides, online drivers, trip volume.
- Driver onboarding & document verification.
- Passenger account management.
- Manual ride creation / editing.
- Fare and surge pricing configuration.
- Dispute and refund handling.
- Service area geofence management.

### 3.4 System
- Automated driver-passenger matching (nearest available).
- Fare calculation (base + distance + time + surge).
- Real-time location broadcast via WebSocket.
- Push notifications (FCM / APNs).
- Scheduled jobs: stale-ride cleanup, earnings settlement.

## 4. Functional Requirements

### 4.1 Ride Lifecycle
1. Passenger requests ride (pick-up, drop-off, category).
2. System calculates fare estimate, shows to passenger.
3. Passenger confirms → system broadcasts to nearby drivers.
4. Driver accepts → passenger notified with driver + vehicle details.
5. Driver navigates to pick-up → passenger tracks on map.
6. Driver arrives → passenger notified.
7. Trip starts → real-time route tracking.
8. Trip ends → fare finalised, payment collected, rating prompt.

### 4.2 Payment Flows
- **Cash**: driver collects at end of trip.
- **Mobile Money**: fare auto-deducted post-trip via M-Pesa / Airtel Money / Tigo Pesa integration.
- Driver wallet: track cash collected vs. digital earnings, commission owed to platform.

### 4.3 Notifications
- Ride accepted, driver arrived, trip started, trip ended.
- Payment receipt.
- Promotional and re-engagement push.

### 4.4 Geofencing
- Admin defines service-area polygon(s).
- Drivers outside the zone cannot go online.
- Passengers outside the zone see "no service" messaging.

## 5. Non-Functional Requirements

| Area          | Requirement                                        |
| ------------- | -------------------------------------------------- |
| Availability  | 99.5 % uptime (Zanzibar power/internet realities)  |
| Latency       | Location updates < 2 s; ride matching < 5 s        |
| Offline-tolerance | App queues actions when connectivity drops; retries on reconnect |
| Data          | TLS in transit; PII encrypted at rest              |
| Scale (v1)    | 500 concurrent riders, 200 drivers, 50 admins      |
| Localisation  | Swahili + English UI                               |

## 6. External Integrations

| Integration           | Purpose                            |
| --------------------- | ---------------------------------- |
| SMS gateway           | OTP, driver alerts                 |
| M-Pesa / Airtel Money | Digital payments                   |
| Google Maps / OSRM    | Geocoding, routing, ETA            |
| FCM / APNs            | Push notifications                 |
| Cloud object storage  | Licence photos, profile avatars    |
