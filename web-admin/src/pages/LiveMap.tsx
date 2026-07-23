import { useEffect, useRef, useState, useCallback } from 'react';
import Map, { Marker, Source, Layer, type MapRef } from 'react-map-gl';
import type { Driver } from '../types';
import { fetchNearbyDrivers } from '../services/api';
import { signalRService } from '../services/signalr';

const MAPBOX_TOKEN = 'YOUR_MAPBOX_TOKEN_HERE';

const ZANZIBAR_CENTER = { latitude: -6.1659, longitude: 39.1990 };

export default function LiveMap() {
  const mapRef = useRef<MapRef>(null);
  const [drivers, setDrivers] = useState<Map<string, Driver>>(new Map());
  const [signalRConnected, setSignalRConnected] = useState(false);

  // Fetch initial driver positions.
  useEffect(() => {
    fetchNearbyDrivers(ZANZIBAR_CENTER.latitude, ZANZIBAR_CENTER.longitude)
      .then((list) => {
        setDrivers(new Map(list.map((d) => [d.driverId, d])));
      })
      .catch(console.error);

    // Poll every 15s as fallback.
    const interval = setInterval(() => {
      fetchNearbyDrivers(ZANZIBAR_CENTER.latitude, ZANZIBAR_CENTER.longitude)
        .then((list) => {
          setDrivers((prev) => {
            const next = new Map(prev);
            for (const d of list) next.set(d.driverId, d);
            return next;
          });
        })
        .catch(() => {});
    }, 15000);

    return () => clearInterval(interval);
  }, []);

  // Connect SignalR for real-time driver location updates.
  useEffect(() => {
    signalRService.connect().then(() => setSignalRConnected(true));

    const unsub = signalRService.onDriverLocation((update) => {
      setDrivers((prev) => {
        const next = new Map(prev);
        const existing = next.get(update.driverId);
        if (existing) {
          next.set(update.driverId, {
            ...existing,
            latitude: update.latitude,
            longitude: update.longitude,
          });
        }
        return next;
      });
    });

    return () => {
      unsub();
      signalRService.disconnect();
    };
  }, []);

  const driverArray = Array.from(drivers.values());

  return (
    <div className="relative h-full w-full">
      <Map
        ref={mapRef}
        mapboxAccessToken={MAPBOX_TOKEN}
        initialViewState={{
          latitude: ZANZIBAR_CENTER.latitude,
          longitude: ZANZIBAR_CENTER.longitude,
          zoom: 12,
        }}
        mapStyle="mapbox://styles/mapbox/streets-v12"
      >
        {driverArray.map((d) => (
          <Marker
            key={d.driverId}
            latitude={d.latitude}
            longitude={d.longitude}
          >
            <div
              className="relative flex items-center justify-center w-8 h-8 rounded-full bg-yapyap-green text-white text-xs font-bold shadow-lg border-2 border-white cursor-pointer"
              title={`${d.driverName} — ${d.category}`}
            >
              {d.category === 'BodaBoda' ? '🏍' : d.category === 'TukTuk' ? '🛺' : '🚗'}
            </div>
          </Marker>
        ))}
      </Map>

      {/* Status bar */}
      <div className="absolute top-4 left-4 right-4 flex items-center justify-between">
        <div className="flex items-center gap-2 bg-white/90 backdrop-blur rounded-lg px-3 py-2 shadow text-sm">
          <span
            className={`w-2 h-2 rounded-full ${
              signalRConnected ? 'bg-green-500' : 'bg-red-500'
            }`}
          />
          <span className="text-gray-700">
            {signalRConnected ? 'Live' : 'Polling'}
          </span>
        </div>
        <div className="bg-white/90 backdrop-blur rounded-lg px-3 py-2 shadow text-sm text-gray-700">
          {driverArray.length} driver{driverArray.length !== 1 ? 's' : ''} online
        </div>
      </div>
    </div>
  );
}
