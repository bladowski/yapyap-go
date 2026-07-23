import * as signalR from '@microsoft/signalr';

type LocationCallback = (driver: {
  driverId: string;
  driverName: string;
  latitude: number;
  longitude: number;
  timestamp: string;
}) => void;

class SignalRService {
  private connection: signalR.HubConnection | null = null;
  private locationCallbacks: LocationCallback[] = [];

  async connect() {
    this.connection = new signalR.HubConnectionBuilder()
      .withUrl('/hubs/location')
      .withAutomaticReconnect()
      .build();

    this.connection.on('DriverLocationUpdated', (data: string) => {
      try {
        const parsed = typeof data === 'string' ? JSON.parse(data) : data;
        for (const cb of this.locationCallbacks) {
          cb(parsed);
        }
      } catch {
        console.warn('Failed to parse driver location:', data);
      }
    });

    await this.connection.start();
    console.log('SignalR connected to /hubs/location');
  }

  onDriverLocation(cb: LocationCallback) {
    this.locationCallbacks.push(cb);
    return () => {
      this.locationCallbacks = this.locationCallbacks.filter((c) => c !== cb);
    };
  }

  async disconnect() {
    await this.connection?.stop();
  }
}

export const signalRService = new SignalRService();
