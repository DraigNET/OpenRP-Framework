'use client'

import { usePathname } from 'next/navigation'
import Link from 'next/link'

/** Human labels for known path segments; anything else is title-cased. */
const SEGMENT_LABELS: Record<string, string> = {
  players: 'Players',
  bans: 'Bans',
  samp: 'samp.ban Editor',
  'shared-ips': 'Shared IPs',
  whitelist: 'Multi-Account Whitelist',
  factions: 'Factions',
  conflicts: 'Conflicts',
  'faction-skins': 'Faction Skins',
  server: 'Server Control',
  console: 'Console Log',
  donators: 'Donators',
  skins: 'Custom Skins',
  logs: 'Logs',
  sms: 'SMS Logs',
  reports: 'Report Logs',
  'staff-activity': 'Staff Activity',
  'admin-actions': 'Admin Action Logs',
}

function labelFor(segment: string): string {
  if (SEGMENT_LABELS[segment]) return SEGMENT_LABELS[segment]
  // Numeric id segments (player/faction detail pages) — show as #id for now.
  if (/^\d+$/.test(segment)) return `#${segment}`
  return segment.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
}

export default function AcpBreadcrumbs() {
  const pathname = usePathname()
  // Drop the leading "acp" segment — that's the home crumb.
  const segments = pathname.split('/').filter(Boolean).slice(1)

  if (segments.length === 0) {
    return (
      <nav className="acp-breadcrumbs" aria-label="Breadcrumb">
        <span className="acp-crumb is-current">Dashboard</span>
      </nav>
    )
  }

  return (
    <nav className="acp-breadcrumbs" aria-label="Breadcrumb">
      <Link href="/acp" className="acp-crumb">ACP</Link>
      {segments.map((seg, i) => {
        const href = '/acp/' + segments.slice(0, i + 1).join('/')
        const isLast = i === segments.length - 1
        return (
          <span key={href} className="acp-crumb-wrap">
            <i className="fa-solid fa-chevron-right acp-crumb-sep" />
            {isLast
              ? <span className="acp-crumb is-current">{labelFor(seg)}</span>
              : <Link href={href} className="acp-crumb">{labelFor(seg)}</Link>}
          </span>
        )
      })}
    </nav>
  )
}
