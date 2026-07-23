import { MapPin, Wallet } from 'lucide-react';

type Page = 'map' | 'wallets';

interface SidebarProps {
  currentPage: Page;
  onNavigate: (page: Page) => void;
}

export default function Sidebar({ currentPage, onNavigate }: SidebarProps) {
  const links: { id: Page; label: string; icon: typeof MapPin }[] = [
    { id: 'map', label: 'Live Map', icon: MapPin },
    { id: 'wallets', label: 'Wallets', icon: Wallet },
  ];

  return (
    <aside className="w-56 bg-gray-900 text-white flex flex-col shrink-0">
      <div className="px-5 py-5 border-b border-gray-700">
        <h1 className="text-lg font-bold tracking-tight">
          <span className="text-yapyap-green">YapYap</span> Admin
        </h1>
      </div>
      <nav className="flex-1 px-3 py-4 space-y-1">
        {links.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            onClick={() => onNavigate(id)}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
              currentPage === id
                ? 'bg-yapyap-green text-white'
                : 'text-gray-300 hover:bg-gray-800 hover:text-white'
            }`}
          >
            <Icon size={18} />
            {label}
          </button>
        ))}
      </nav>
      <div className="px-5 py-3 border-t border-gray-700 text-xs text-gray-500">
        YapYap MVP v0.1
      </div>
    </aside>
  );
}
