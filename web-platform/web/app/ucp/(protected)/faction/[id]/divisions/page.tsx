import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { requireFactionCharacter } from '@/lib/dal'
import { DIVISION_FACTION_TYPES } from '@/lib/constants'

export default async function FactionDivisionsPage({ params }: PageProps<'/ucp/faction/[id]/divisions'>) {
  const { id } = await params
  const char = await requireFactionCharacter(Number(id))

  const faction = await prisma.faction.findUnique({ where: { faction_id: char.player_factionid } })
  if (!faction || !DIVISION_FACTION_TYPES.includes(faction.faction_type)) notFound()

  const [divisions, members] = await Promise.all([
    prisma.factionDivision.findMany({
      where: { faction_id: char.player_factionid },
      orderBy: { division_order: 'asc' },
    }),
    prisma.character.findMany({
      where: { player_factionid: char.player_factionid },
      select: {
        player_id: true, player_name: true, player_factionrank: true,
        player_factiontier: true, player_division: true,
      },
    }),
  ])

  // Group members by division
  const membersByDiv = new Map<number, typeof members>()
  for (const m of members) {
    const div = m.player_division ?? 0
    if (!membersByDiv.has(div)) membersByDiv.set(div, [])
    membersByDiv.get(div)!.push(m)
  }

  // Map character IDs to names (for division leaders)
  const charMap = Object.fromEntries(members.map(m => [m.player_id, m.player_name.replace('_', ' ')]))

  const isOwner = char.player_factiontier === 1
  const isCommand = char.player_factiontier <= 2
  const unassigned = membersByDiv.get(0) ?? []

  return (
    <>
      <div className="ucp-card">
        <h3>Divisions</h3>
        <p className="ucp-muted" style={{ marginTop: 6 }}>
          {divisions.length} division{divisions.length !== 1 ? 's' : ''} · {members.length} total members
        </p>
      </div>

      {divisions.length === 0 ? (
        <div className="ucp-card" style={{ marginTop: 18 }}>
          <p className="ucp-muted">No divisions have been created yet.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(300px,1fr))', gap: 18, marginTop: 18 }}>
          {divisions.map(div => {
            const divMembers = membersByDiv.get(div.division_id) ?? []
            const leader = div.division_leader > 0 ? charMap[div.division_leader] : null
            return (
              <div key={div.division_id} className="ucp-card">
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <h4 style={{ margin: 0, fontSize: 15, color: 'var(--text-1)' }}>{div.division_name}</h4>
                  <span className="ucp-muted" style={{ fontSize: 12 }}>{divMembers.length} member{divMembers.length !== 1 ? 's' : ''}</span>
                </div>
                {leader && (
                  <p style={{ margin: '6px 0 10px', fontSize: 13, color: 'var(--accent-soft)' }}>
                    <i className="fa-solid fa-star" style={{ marginRight: 5 }} />{leader}
                  </p>
                )}
                {divMembers.length > 0 ? (
                  <ul style={{ margin: 0, padding: 0, listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 4 }}>
                    {divMembers.map(m => (
                      <li key={m.player_id} style={{ fontSize: 13, color: 'var(--text-2)', display: 'flex', alignItems: 'center', gap: 6 }}>
                        {m.player_id === div.division_leader && (
                          <i className="fa-solid fa-star" style={{ fontSize: 10, color: 'var(--accent-soft)' }} />
                        )}
                        {m.player_name.replace('_', ' ')}
                        {m.player_factionrank && (
                          <span style={{ color: 'var(--text-3)', fontSize: 12 }}>— {m.player_factionrank}</span>
                        )}
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="ucp-muted" style={{ fontSize: 13, margin: 0 }}>No members assigned</p>
                )}
              </div>
            )
          })}
        </div>
      )}

      {unassigned.length > 0 && (
        <div className="ucp-card" style={{ marginTop: 18 }}>
          <h4 style={{ margin: '0 0 10px', fontSize: 14, color: 'var(--text-2)' }}>Unassigned ({unassigned.length})</h4>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {unassigned.map(m => (
              <span key={m.player_id} style={{ fontSize: 13, color: 'var(--text-2)', background: 'var(--bg-input)', padding: '4px 10px', borderRadius: 6, border: '1px solid var(--border-sub)' }}>
                {m.player_name.replace('_', ' ')}
              </span>
            ))}
          </div>
        </div>
      )}
    </>
  )
}
