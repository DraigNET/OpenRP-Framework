import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getFactionById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatCash } from '@/lib/format'

export const dynamic = 'force-dynamic'

export default async function FactionOverview({ params }: PageProps<'/acp/factions/[id]'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const id = Number((await params).id)
  const faction = await getFactionById(id)
  if (!faction) notFound()

  const members = await prisma.character.count({ where: { player_factionid: id } })
  const color = `#${(faction.faction_hex >>> 8).toString(16).padStart(6, '0')}`

  return (
    <div className="acp-grid-2">
      <section className="acp-panel">
        <div className="acp-panel-head"><span>Details</span></div>
        <div className="acp-kv">
          <div className="acp-kv-row"><span>Faction ID</span><b>{faction.faction_id}</b></div>
          <div className="acp-kv-row"><span>Name</span><b>{faction.faction_name}</b></div>
          <div className="acp-kv-row"><span>Tag</span><b>{faction.faction_abbrev || '—'}</b></div>
          <div className="acp-kv-row"><span>Colour</span><b><span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}><span style={{ width: 12, height: 12, borderRadius: 3, background: color, display: 'inline-block' }} /> <span className="acp-mono">{color}</span></span></b></div>
        </div>
      </section>

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Resources</span></div>
        <div className="acp-kv">
          <div className="acp-kv-row"><span>Bank Balance</span><b>{formatCash(faction.faction_bank)}</b></div>
          <div className="acp-kv-row"><span>Members</span><b>{members}</b></div>
          <div className="acp-kv-row"><span>Activity Tracking</span><b>{faction.faction_show_activity === 1 ? 'On' : 'Off'}</b></div>
        </div>
      </section>
    </div>
  )
}
