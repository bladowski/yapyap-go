import { useEffect, useState } from 'react';
import type { WalletInfo } from '../types';
import { fetchDriverWallets } from '../services/api';

export default function Wallets() {
  const [wallets, setWallets] = useState<WalletInfo[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDriverWallets()
      .then(setWallets)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-8 w-8 border-2 border-yapyap-green border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-6">Driver Wallets</h2>

      <div className="bg-white rounded-xl shadow overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-left px-4 py-3 font-semibold text-gray-600">
                Driver
              </th>
              <th className="text-left px-4 py-3 font-semibold text-gray-600">
                Vehicle
              </th>
              <th className="text-right px-4 py-3 font-semibold text-gray-600">
                Balance (TZS)
              </th>
              <th className="text-center px-4 py-3 font-semibold text-gray-600">
                Status
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {wallets.map((w) => (
              <tr key={w.driverId} className="hover:bg-gray-50 transition-colors">
                <td className="px-4 py-3 font-medium">{w.driverName}</td>
                <td className="px-4 py-3 text-gray-500">{w.category}</td>
                <td
                  className={`px-4 py-3 text-right font-mono font-semibold ${
                    w.balanceTzs >= 0 ? 'text-green-600' : 'text-red-600'
                  }`}
                >
                  {w.balanceTzs.toLocaleString()} TZS
                </td>
                <td className="px-4 py-3 text-center">
                  <span
                    className={`inline-block px-2 py-0.5 rounded-full text-xs font-medium ${
                      w.balanceTzs >= 0
                        ? 'bg-green-100 text-green-700'
                        : 'bg-red-100 text-red-700'
                    }`}
                  >
                    {w.balanceTzs >= 0 ? 'Owed by platform' : 'Owes platform'}
                  </span>
                </td>
              </tr>
            ))}
            {wallets.length === 0 && (
              <tr>
                <td colSpan={4} className="px-4 py-8 text-center text-gray-400">
                  No driver data available. Ensure drivers are online and the backend is running.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Summary card */}
      {wallets.length > 0 && (
        <div className="mt-6 grid grid-cols-3 gap-4">
          <div className="bg-white rounded-xl shadow p-4">
            <p className="text-sm text-gray-500">Total Drivers</p>
            <p className="text-2xl font-bold">{wallets.length}</p>
          </div>
          <div className="bg-white rounded-xl shadow p-4">
            <p className="text-sm text-gray-500">Platform Owed</p>
            <p className="text-2xl font-bold text-green-600">
              {wallets
                .filter((w) => w.balanceTzs >= 0)
                .reduce((s, w) => s + w.balanceTzs, 0)
                .toLocaleString()}{' '}
              TZS
            </p>
          </div>
          <div className="bg-white rounded-xl shadow p-4">
            <p className="text-sm text-gray-500">Driver Debt</p>
            <p className="text-2xl font-bold text-red-600">
              {wallets
                .filter((w) => w.balanceTzs < 0)
                .reduce((s, w) => s + Math.abs(w.balanceTzs), 0)
                .toLocaleString()}{' '}
              TZS
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
