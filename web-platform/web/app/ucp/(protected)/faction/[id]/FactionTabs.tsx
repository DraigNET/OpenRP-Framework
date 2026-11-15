'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'

interface Tab { href: string; label: string }

export default function FactionTabs({ tabs, charId }: { tabs: Tab[]; charId: string }) {
  const pathname = usePathname()

  return (
    <div className="ucp-card ucp-card-compact">
      <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
        {tabs.map(t => {
          const isActive = pathname === t.href
          return (
            <Link key={t.href} href={t.href} className={`ucp-btn ${isActive ? 'ucp-btn-primary' : 'ucp-btn-outline'}`}>
              {t.label}
            </Link>
          )
        })}
      </div>
    </div>
  )
}
