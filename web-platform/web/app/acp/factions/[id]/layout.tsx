import type { ReactNode } from 'react'
import { notFound } from 'next/navigation'
import { requireStaff, getFactionById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import FactionTabs from './FactionTabs'

export const dynamic = 'force-dynamic'

export default async function FactionHubLayout({
  children,
  params,
}: {
  children: ReactNode
  params: Promise<{ id: string }>
}) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const id = Number((await params).id)
  const faction = await getFactionById(id)
  if (!faction) notFound()

  const color = `#${(faction.faction_hex >>> 8).toString(16).padStart(6, '0')}`

  return (
    <>
      <div className="acp-hub-head">
        <div className="acp-hub-avatar" style={{ background: color }}>{faction.faction_abbrev?.charAt(0).toUpperCase() || faction.faction_name.charAt(0).toUpperCase()}</div>
        <div className="acp-hub-id">
          <div className="acp-hub-name">
            {faction.faction_name}
            {faction.faction_abbrev && <span className="acp-badge">{faction.faction_abbrev}</span>}
          </div>
          <div className="acp-hub-meta">Faction #{faction.faction_id}</div>
        </div>
      </div>

      <FactionTabs id={id} />
      {children}
    </>
  )
}
