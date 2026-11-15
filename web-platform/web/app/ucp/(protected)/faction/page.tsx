import { prisma } from '@/lib/prisma'
import { requireUser } from '@/lib/dal'
import { FACTION_TIER } from '@/lib/data/attributes'
import Link from 'next/link'

export default async function FactionSelectorPage() {
  const user = await requireUser()

  const chars = await prisma.character.findMany({
    where: { account_id: user.id, player_factionid: { gt: 0 } },
    orderBy: { player_name: 'asc' },
  })

  const factionIds = [...new Set(chars.map(c => c.player_factionid))]
  const factions = factionIds.length > 0
    ? await prisma.faction.findMany({ where: { faction_id: { in: factionIds } } })
    : []
  const factionMap = Object.fromEntries(factions.map(f => [f.faction_id, f]))

  return (
    <div className="ucp-card">
      <h3>Your Faction Characters</h3>

      {chars.length === 0 ? (
        <div className="ucp-muted" style={{ marginTop: 10 }}>
          You do not have any characters in a faction.
        </div>
      ) : (
        <table className="ucp-table" style={{ marginTop: 10 }}>
          <thead>
            <tr>
              <th>Name</th>
              <th>Faction</th>
              <th>Tier</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {chars.map(c => {
              const faction = factionMap[c.player_factionid]
              const short = faction?.faction_abbrev || faction?.faction_name || ''
              return (
                <tr key={c.player_id}>
                  <td>{c.player_name.replace('_', ' ')}</td>
                  <td>
                    {short}{' '}
                    {short !== faction?.faction_name && (
                      <span style={{ color: 'var(--text-2)' }}>({faction?.faction_name})</span>
                    )}
                  </td>
                  <td>{FACTION_TIER[c.player_factiontier] ?? `Tier ${c.player_factiontier}`}</td>
                  <td style={{ textAlign: 'right' }}>
                    <Link href={`/ucp/faction/${c.player_id}`} className="ucp-btn ucp-btn-primary">
                      Manage
                    </Link>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
    </div>
  )
}
