import { useState } from 'react';
import Sidebar from './Sidebar';
import LiveMap from '../pages/LiveMap';
import Wallets from '../pages/Wallets';

type Page = 'map' | 'wallets';

export default function Layout() {
  const [page, setPage] = useState<Page>('map');

  return (
    <div className="flex h-screen w-screen overflow-hidden">
      <Sidebar currentPage={page} onNavigate={setPage} />
      <main className="flex-1 overflow-auto">
        {page === 'map' && <LiveMap />}
        {page === 'wallets' && <Wallets />}
      </main>
    </div>
  );
}
