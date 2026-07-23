export interface Driver {
  driverId: string;
  driverName: string;
  category: string;
  licensePlate: string;
  makeModel: string;
  color: string;
  distanceMeters: number;
  latitude: number;
  longitude: number;
}

export interface DriverProfile {
  id: string;
  userId: string;
  name: string;
  isOnline: boolean;
  balanceTzs: number;
  vehicle?: string;
}

export interface WalletInfo {
  driverId: string;
  driverName: string;
  category: string;
  balanceTzs: number;
}

export interface TripSummary {
  tripId: string;
  status: string;
  passengerName: string;
  driverName: string;
  category: string;
  estimatedPriceTzs: number;
  createdAt: string;
}
