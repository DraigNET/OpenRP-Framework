export interface NavItem {
  href: string
  icon: string
  label: string
  /** 'exact' highlights only on the same path, 'prefix' on any sub-path. */
  match: 'exact' | 'prefix'
  staffOnly?: number
}

export const PLAYER_NAV: NavItem[] = [
  { href: '/ucp', icon: 'fa-gauge-high', label: 'Dashboard', match: 'exact' },
  { href: '/ucp/online', icon: 'fa-circle-dot', label: 'Online Players', match: 'exact' },
  { href: '/ucp/characters', icon: 'fa-person', label: 'Characters', match: 'prefix' },
  { href: '/ucp/faction', icon: 'fa-shield-halved', label: 'Faction', match: 'prefix' },
  { href: '/ucp/account', icon: 'fa-user', label: 'Account', match: 'exact' },
  { href: '/ucp/quiz', icon: 'fa-book-open', label: 'Rules Quiz', match: 'exact' },
  { href: '/ucp/admin-record', icon: 'fa-gavel', label: 'Admin Records', match: 'prefix' },
  { href: '/ucp/account/settings', icon: 'fa-gear', label: 'Settings', match: 'prefix' },
]

export const TOOLS_NAV: NavItem[] = [
  { href: '/ucp/tools', icon: 'fa-toolbox', label: 'Tools Home', match: 'exact' },
  { href: '/ucp/tools/vehicles', icon: 'fa-car', label: 'Vehicles', match: 'prefix' },
  { href: '/ucp/tools/furniture', icon: 'fa-couch', label: 'Furniture', match: 'prefix' },
  { href: '/ucp/tools/gang-zones', icon: 'fa-map-location-dot', label: 'Gang Zones', match: 'prefix' },
]

export const ADMIN_NAV: NavItem = { href: '/acp', icon: 'fa-shield', label: 'Admin Control Panel', match: 'prefix', staffOnly: 2 }
