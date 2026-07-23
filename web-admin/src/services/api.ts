import axios from 'axios';
import type { Driver, WalletInfo } from '../types';

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'X-User-Id': '07bc4848-7d12-470e-a136-c3a4eb2dad8c',
  },
});

export async function fetchNearbyDrivers(lat: number, lng: number, radiusM = 5000) {
  const { data } = await api.get<Driver[]>('/drivers/nearby', {
    params: { latitude: lat, longitude: lng, radiusMeters: radiusM },
  });
  return data;
}

export async function fetchDriverWallets(): Promise<WalletInfo[]> {
  // MVP: fetch all drivers from nearby with large radius, then wallet per driver.
  // In production, add a dedicated /admin/wallets endpoint.
  const { data } = await api.get<Driver[]>('/drivers/nearby', {
    params: { latitude: -6.1659, longitude: 39.1990, radiusMeters: 50000 },
  });

  return data.map((d) => ({
    driverId: d.driverId,
    driverName: d.driverName,
    category: d.category,
    balanceTzs: 0, // backend doesn't expose balance in nearby yet; placeholder
  }));
}

export async function fetchTrips() {
  // Stub — dedicated admin trip endpoint in post-MVP.
  return [];
}
