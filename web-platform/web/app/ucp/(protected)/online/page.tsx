import { queryPlayersDetailed, type SampPlayer } from '@/lib/sampquery'
import { env } from '@/lib/env'
import { prisma } from '@/lib/prisma'
import { isLeaFaction } from '@/lib/constants'
import { getServerStats } from '@/lib/ucp-extra'
import AutoRefresh from '@/components/shared/AutoRefresh'
import PlayersTable, { type PlayerRow } from './PlayersTable'

export const dynamic = 'force-dynamic'

export default async function OnlinePlayersPage() {
  let serverOnline = false
  let players: SampPlayer[] = []

  try {
    players = await queryPlayersDetailed(env.sampQueryHost, env.rconPort, 2000)
    serverOnline = true
  } catch {
    serverOnline = false
  }

  if (!serverOnline) {
    return (
      <div className="ucp-alert ucp-alert-error">
        <i className="fa-solid fa-triangle-exclamation" /> The game server is currently offline (query failed).
      </div>
    )
  }

  // Match online nicknames to characters so each player can show their faction.
  const [chars, factions, stats] = await Promise.all([
    players.length
      ? prisma.character.findMany({
          where: { player_name: { in: players.map(p => p.nickname) } },
          select: { player_name: true, player_factionid: true },
        })
      : [],
    prisma.faction.findMany({ select: { faction_id: true, faction_name: true, faction_type: true } }),
    getServerStats(),
  ])
  const factionById = new Map(factions.map(f => [f.faction_id, f]))
  const charByName = new Map(chars.map(c => [c.player_name, c]))

  const rows: PlayerRow[] = players.map(p => {
    const f = factionById.get(charByName.get(p.nickname)?.player_factionid ?? 0)
    return {
      id: p.playerid,
      name: p.nickname,
      faction: f?.faction_name ?? null,
      isLaw: f ? isLeaFaction(f.faction_type) : false,
      score: p.score,
      ping: p.ping,
    }
  })

  const pings = rows.map(r => r.ping).filter((n): n is number => n !== null)
  const avgPing = pings.length ? Math.round(pings.reduce((a, b) => a + b, 0) / pings.length) : null
  const lawCount = rows.filter(r => r.isLaw).length

  return (
    <div className="ucp-stack">
      <AutoRefresh intervalMs={10000} />
      <div className="ucp-stats">
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-users" /></div>
          <small>Online now</small>
          <b>{rows.length}{stats.maxPlayers !== null && <span className="ucp-muted" style={{ fontSize: 16 }}> / {stats.maxPlayers}</span>}</b>
        </div>
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-shield-halved" /></div>
          <small>Law enforcement &amp; EMS</small>
          <b>{lawCount}</b>
        </div>
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-gauge-high" /></div>
          <small>Average ping</small>
          <b>{avgPing !== null ? `${avgPing} ms` : '—'}</b>
        </div>
        <div className="ucp-card ucp-stat">
          <div className="ucp-stat-ic"><i className="fa-solid fa-chart-line" /></div>
          <small>Peak today</small>
          <b>{stats.peakToday ?? '—'}</b>
        </div>
      </div>

      {rows.length === 0 ? (
        <div className="ucp-card ucp-muted">No players are currently online.</div>
      ) : (
        <PlayersTable rows={rows} />
      )}
    </div>
  )
}
