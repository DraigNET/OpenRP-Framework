'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'

export default function FactionTabs({ id }: { id: number }) {
  const pathname = usePathname()
  const base = `/acp/factions/${id}`
  const tabs = [
    { href: base, label: 'Overview' },
    { href: `${base}/roster`, label: 'Roster' },
    { href: `${base}/vehicles`, label: 'Vehicles' },
    { href: `${base}/activity`, label: 'Activity' },
    { href: `${base}/bank`, label: 'Bank' },
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
