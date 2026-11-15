'use client'

import { usePathname } from 'next/navigation'

const TITLES: Record<string, string> = {
  '/ucp': 'Dashboard',
  '/ucp/characters': 'Characters',
  '/ucp/characters/create': 'Create Character',
  '/ucp/account': 'Account',
  '/ucp/account/settings': 'Settings',
  '/ucp/admin-record': 'Admin Records',
  '/ucp/faction': 'Faction Panel',
  '/ucp/online': 'Online Players',
  '/ucp/quiz': 'Rules Quiz',
  '/ucp/tools': 'Tools & Utilities',
  '/ucp/tools/screenshots': 'Screenshot Overlay',
  '/ucp/tools/gang-zones': 'Gang Territories',
  '/ucp/tools/vehicles': 'Vehicle Catalogue',
  '/ucp/tools/weapons': 'Weapon Statistics',
}

export default function PageTitle() {
  const pathname = usePathname()

  // Dynamic routes
  let title = TITLES[pathname]
  if (!title) {
    if (pathname.startsWith('/ucp/characters/') && pathname.split('/').length === 4) title = 'Character Profile'
    else if (pathname.startsWith('/ucp/faction/')) title = 'Faction Panel'
    else title = 'UCP'
  }

  return <h1 className="ucp-title">{title}</h1>
}
