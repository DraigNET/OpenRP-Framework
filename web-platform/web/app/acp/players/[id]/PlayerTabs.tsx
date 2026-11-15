'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'

export default function PlayerTabs({ id, canManage }: { id: number; canManage: boolean }) {
  const pathname = usePathname()
  const base = `/acp/players/${id}`
  const tabs = [
    { href: base, label: 'Overview' },
    { href: `${base}/characters`, label: 'Characters' },
    { href: `${base}/admin-record`, label: 'Admin Record' },
    { href: `${base}/penalties`, label: 'Penalties' },
    { href: `${base}/connections`, label: 'Connections' },
    { href: `${base}/logs`, label: 'Logs' },
    ...(canManage ? [{ href: `${base}/settings`, label: 'Settings' }] : []),
  ]
  return (
    <nav className="acp-hubtabs">
      {tabs.map(t => (
        <Link key={t.href} href={t.href} className={`acp-hubtab${pathname === t.href ? ' is-active' : ''}`}>
          {t.label}
        </Link>
      ))}
    </nav>
  )
}
