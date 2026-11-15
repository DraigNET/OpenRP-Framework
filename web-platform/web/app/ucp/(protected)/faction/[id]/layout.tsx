import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { notFound, redirect } from 'next/navigation'
import { FACTION_TYPE } from '@/lib/data/attributes'
import { factionHexToRgb } from '@/lib/format'
import Link from 'next/link'
import type { ReactNode } from 'react'
import FactionTabs from './FactionTabs'
import { isGangFaction, FACTION_TIER_ID } from '@/lib/constants'

export default async function FactionLayout({ children, params }: { children: ReactNode; params: Promise<{ id: string }> }) {
  const { id } = await params
  const session = await auth()
  if (!session) redirect('/ucp/login')

  const char = await prisma.character.findFirst({
    where: { player_id: Number(id), account_id: session.user.id, player_factionid: { gt: 0 } },
  })
  if (!char) notFound()

  const faction = await prisma.faction.findUnique({ where: { faction_id: char.player_factionid } })
  if (!faction) notFound()

  const fType = faction.faction_type
  const isOwner = char.player_factiontier === FACTION_TIER_ID.OWNER
  const isGang = isGangFaction(fType)

  const tabs = [
    { href: `/ucp/faction/${id}`, label: 'Overview' },
    { href: `/ucp/faction/${id}/roster`, label: 'Roster' },
    { href: `/ucp/faction/${id}/vehicles`, label: 'Vehicles' },
    { href: `/ucp/faction/${id}/bank`, label: 'Bank' },
    // The activity page is owner/command-only, so don't offer the tab to anyone else.
    ...(char.player_factiontier <= FACTION_TIER_ID.COMMAND ? [{ href: `/ucp/faction/${id}/activity`, label: 'Activity' }] : []),
    ...(isOwner && isGang ? [{ href: `/ucp/faction/${id}/gun-logs`, label: 'Gun Logs' }] : []),
    { href: `/ucp/faction/${id}/settings`, label: 'Settings' },
  ]

  return (
    <>
      <div className="ucp-card ucp-card-compact">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: factionHexToRgb(faction.faction_hex, 'var(--accent)') }} />
            <div style={{ fontSize: 15, fontWeight: 600 }}>
              {char.player_name.replace('_', ' ')}{' '}
              <span style={{ color: 'var(--text-2)' }}>— {faction.faction_abbrev || faction.faction_name}</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {isGang && (
              <Link href={`/ucp/conflict?char=${id}`} className="ucp-btn ucp-btn-primary">Conflict Logger</Link>
            )}
            <Link href="/ucp/faction" className="ucp-btn ucp-btn-outline">Change Character</Link>
          </div>
        </div>
      </div>

      <FactionTabs tabs={tabs} charId={id} />

      {children}
    </>
  )
}
