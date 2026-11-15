import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getFactionById, serverNow } from '@/lib/dal'
import { ADMIN_LVL, factionTierName, factionSquadNames, factionSquadList } from '@/lib/constants'

export const dynamic = 'force-dynamic'

function lastActive(unix: number, now: number): { text: string; cls: string } {
  if (!unix) return { text: 'Never', cls: 'acp-td-muted' }
  const s = Math.max(0, now - unix)
  const days = Math.floor(s / 86400)
  const text = s < 3600 ? `${Math.floor(s / 60)}m ago` : s < 86400 ? `${Math.floor(s / 3600)}h ago` : `${days}d ago`
  const cls = days <= 3 ? 'is-recent' : days <= 14 ? 'is-mid' : 'is-stale'
  return { text, cls }
}

export default async function FactionRoster({ params }: PageProps<'/acp/factions/[id]/roster'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const id = Number((await params).id)
  const faction = await getFactionById(id)
  if (!faction) notFound()
  const now = Math.floor(serverNow() / 1000)

  const members = await prisma.character.findMany({
    where: { player_factionid: id },
    orderBy: [{ player_factiontier: 'asc' }, { player_name: 'asc' }],
    select: {
      player_id: true, player_name: true, player_factionrank: true, player_factiontier: true,
      player_factionsquad: true, player_factionsquad2: true, player_factionsquad3: true,
      player_factionbadge: true, player_logindate: true, player_online: true,
    },
  })

  const onlineCount = members.filter(m => m.player_online === 1).length
  const squadList = factionSquadList(faction.faction_type, faction.faction_abbrev)

  return (
    <section className="acp-panel">
      <div className="acp-panel-head" style={{ flexWrap: 'wrap', gap: 10 }}>
        <span>Roster</span>
        <span style={{ fontSize: 12, color: 'var(--acp-text-2)', fontWeight: 400, textTransform: 'none', letterSpacing: 0 }}>
          Members <b style={{ color: 'var(--acp-text)' }}>{members.length}</b> · Online <b style={{ color: onlineCount > 0 ? 'var(--acp-green)' : 'var(--acp-text)' }}>{onlineCount}</b>
          {squadList.length > 0 && <> · Squads <b style={{ color: 'var(--acp-text)' }}>{squadList.join(', ')}</b></>}
        </span>
      </div>
      {members.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-users" />No members.</div>
      ) : (
        <table className="acp-table">
          <thead>
            <tr><th>Rank</th><th>Name</th><th>Tier</th><th>Squads</th><th>Badge</th><th>Last Active</th><th>Status</th><th></th></tr>
          </thead>
          <tbody>
            {members.map(m => {
              const squads = factionSquadNames(faction.faction_type, faction.faction_abbrev, m.player_factionsquad, m.player_factionsquad2, m.player_factionsquad3)
              const la = lastActive(m.player_logindate, now)
              return (
                <tr key={m.player_id}>
                  <td>{m.player_factionrank || '—'}</td>
                  <td className="acp-td-name"><Link href={`/acp/characters/${m.player_id}`} className="acp-link">{m.player_name.replace(/_/g, ' ')}</Link></td>
                  <td className="acp-td-muted">{factionTierName(m.player_factiontier)}</td>
                  <td className="acp-td-muted">{squads.length ? squads.join(', ') : 'None'}</td>
                  <td className="acp-mono acp-td-muted">{String(m.player_factionbadge).padStart(5, '0')}</td>
                  <td><span className={`acp-last ${la.cls}`}>{la.text}</span></td>
                  <td>{m.player_online === 1 ? <span className="acp-badge is-green">Online</span> : <span className="acp-badge is-off">Offline</span>}</td>
                  <td style={{ textAlign: 'right' }}><Link href={`/acp/characters/${m.player_id}`} className="acp-btn acp-btn-sm">View Character</Link></td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
    </section>
  )
}
