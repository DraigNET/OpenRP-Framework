import { prisma } from '@/lib/prisma'
import { requireFactionCharacter } from '@/lib/dal'
import { FACTION_TIER_ID } from '@/lib/constants'

export default async function FactionActivityPage({ params, searchParams }: PageProps<'/ucp/faction/[id]/activity'>) {
  const { id } = await params
  const sp = await searchParams

  const char = await requireFactionCharacter(Number(id))
  // Activity is owner/command-only. Say so instead of showing a confusing 404.
  if (char.player_factiontier > FACTION_TIER_ID.COMMAND) {
    return (
      <div className="ucp-card">
        <div className="ucp-card-head"><h3><i className="fa-solid fa-lock" />Member activity</h3></div>
        <p className="ucp-muted">Member activity is only available to faction owners and command staff.</p>
      </div>
    )
  }

  const now = new Date()
  const year = sp?.year ? Number(sp.year) : now.getFullYear()
  const month = sp?.month ? Number(sp.month) : now.getMonth() + 1
  const start = Math.floor(new Date(year, month - 1, 1).getTime() / 1000)
  const end = Math.floor(new Date(year, month, 1).getTime() / 1000)

  const members = await prisma.character.findMany({
    where: { player_factionid: char.player_factionid },
    orderBy: [{ player_factiontier: 'asc' }, { player_name: 'asc' }],
    select: {
      player_id: true, player_name: true, player_factionrank: true,
      player_factiontier: true, player_online: true, player_logindate: true, player_hours: true,
    },
  })

  // Get login history for this faction in the selected month
  const loginHistory = await prisma.characterLoginHistory.findMany({
    where: {
      faction_id: char.player_factionid,
      login_time: { gte: start, lt: end },
    },
    select: { character_id: true, login_time: true },
  }).catch(() => [] as { character_id: number; login_time: number }[])

  // Build per-member stats
  const loginMap = new Map<number, { count: number; lastInMonth: number }>()
  for (const log of loginHistory) {
    const existing = loginMap.get(log.character_id)
    if (!existing) {
      loginMap.set(log.character_id, { count: 1, lastInMonth: log.login_time })
    } else {
      existing.count++
      if (log.login_time > existing.lastInMonth) existing.lastInMonth = log.login_time
    }
  }

  const activeCount = members.filter(m => (loginMap.get(m.player_id)?.count ?? 0) > 0).length
  const totalLogins = loginHistory.length

  const monthLabel = new Date(year, month - 1).toLocaleString('default', { month: 'long', year: 'numeric' })

  return (
    <>
      <div className="ucp-card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 12 }}>
          <div>
            <h3 style={{ margin: 0 }}>Member Activity</h3>
            <p className="ucp-muted" style={{ marginTop: 4 }}>{monthLabel}</p>
          </div>
          <form method="get" style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'flex-end' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <span className="ucp-muted" style={{ fontSize: 12 }}>Year</span>
              <select name="year" className="char-text-input" style={{ minWidth: 90 }} defaultValue={year}>
                {[now.getFullYear() - 1, now.getFullYear()].map(y => (
                  <option key={y} value={y}>{y}</option>
                ))}
              </select>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
              <span className="ucp-muted" style={{ fontSize: 12 }}>Month</span>
              <select name="month" className="char-text-input" style={{ minWidth: 120 }} defaultValue={month}>
                {Array.from({ length: 12 }, (_, i) => i + 1).map(m => (
                  <option key={m} value={m}>{new Date(2000, m - 1).toLocaleString('default', { month: 'long' })}</option>
                ))}
              </select>
            </div>
            <button type="submit" className="ucp-btn ucp-btn-primary">Filter</button>
          </form>
        </div>

        <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap', marginTop: 16 }}>
          {[
            ['Members', members.length],
            ['Active This Month', activeCount],
            ['Total Logins', totalLogins],
          ].map(([label, value]) => (
            <div key={label}>
              <div className="ucp-muted" style={{ fontSize: 12 }}>{label}</div>
              <div style={{ fontSize: 20, fontWeight: 700 }}>{value}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="ucp-card" style={{ marginTop: 18 }}>
        <div style={{ overflowX: 'auto' }}>
          <table className="ucp-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Rank</th>
                <th>Status</th>
                <th>Activity (Month)</th>
                <th>Logins (Month)</th>
                <th>Last Login (Month)</th>
                <th>Last Login (Overall)</th>
              </tr>
            </thead>
            <tbody>
              {members.map(m => {
                const stats = loginMap.get(m.player_id)
                const isOnline = m.player_online === 1
                const hasActivity = (stats?.count ?? 0) > 0
                const lastInMonth = stats?.lastInMonth
                  ? new Date(stats.lastInMonth * 1000).toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })
                  : '—'
                const lastOverall = m.player_logindate > 0
                  ? new Date(m.player_logindate * 1000).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
                  : 'Never'

                return (
                  <tr key={m.player_id}>
                    <td>{m.player_name.replace('_', ' ')}</td>
                    <td>{m.player_factionrank || '—'}</td>
                    <td>
                      {isOnline
                        ? <span style={{ color: '#86efac' }}>Online</span>
                        : <span style={{ color: 'var(--text-2)' }}>Offline</span>}
                    </td>
                    <td>
                      <span style={{ color: hasActivity ? '#86efac' : '#fca5a5', fontWeight: 600 }}>
                        {hasActivity ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td>{stats?.count ?? 0}</td>
                    <td>{lastInMonth}</td>
                    <td>{lastOverall}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>
    </>
  )
}
