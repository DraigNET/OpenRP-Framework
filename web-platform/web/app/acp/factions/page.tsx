import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatCash } from '@/lib/format'

export const dynamic = 'force-dynamic'

export default async function FactionsList() {
  await requireStaff(ADMIN_LVL.GENERAL)

  const [factions, counts] = await Promise.all([
    prisma.faction.findMany({ orderBy: { faction_id: 'asc' } }),
    prisma.character.groupBy({
      by: ['player_factionid'],
      where: { player_factionid: { gt: 0 } },
      _count: { player_id: true },
    }),
  ])
  const countMap = new Map(counts.map(c => [c.player_factionid, c._count.player_id]))

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Factions — {factions.length}</span></div>
      {factions.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-shield-halved" />No factions found.</div>
      ) : (
        <table className="acp-table">
          <thead>
            <tr><th style={{ width: 56 }}>ID</th><th>Name</th><th>Tag</th><th>Members</th><th>Bank</th></tr>
          </thead>
          <tbody>
            {factions.map(f => (
              <tr key={f.faction_id}>
                <td className="acp-td-muted">{f.faction_id}</td>
                <td>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ width: 9, height: 9, borderRadius: 2, background: `#${(f.faction_hex >>> 8).toString(16).padStart(6, '0')}`, display: 'inline-block' }} />
                    <Link href={`/acp/factions/${f.faction_id}`} className="acp-link">{f.faction_name}</Link>
                  </span>
                </td>
                <td className="acp-td-muted">{f.faction_abbrev || '—'}</td>
                <td>{countMap.get(f.faction_id) ?? 0}</td>
                <td className="acp-td-muted">{formatCash(f.faction_bank)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
