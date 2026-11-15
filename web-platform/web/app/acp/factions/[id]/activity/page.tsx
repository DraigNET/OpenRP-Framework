import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getFactionById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDateTime } from '@/lib/format'

export const dynamic = 'force-dynamic'

const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''
const monthName = (m: number) => new Date(2000, m - 1, 1).toLocaleString('en-GB', { month: 'long' })

export default async function FactionActivity({ params, searchParams }: PageProps<'/acp/factions/[id]/activity'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const id = Number((await params).id)
  const faction = await getFactionById(id)
  if (!faction) notFound()
  const sp = await searchParams

  // Months that have login history for this faction.
  const monthsRaw = await prisma.$queryRaw<Array<{ y: number; m: number }>>`
    SELECT DISTINCT YEAR(FROM_UNIXTIME(login_time)) AS y, MONTH(FROM_UNIXTIME(login_time)) AS m
    FROM character_login_history WHERE faction_id = ${id} ORDER BY y DESC, m DESC`
  const months = monthsRaw.map(r => ({ y: Number(r.y), m: Number(r.m) }))

  const now = new Date()
  let year = Number(firstParam(sp.year)) || 0
  let month = Number(firstParam(sp.month)) || 0
  if (year <= 0 || month <= 0 || month > 12) {
    if (months[0]) { year = months[0].y; month = months[0].m }
    else { year = now.getFullYear(); month = now.getMonth() + 1 }
  }
  const startTs = Math.floor(new Date(year, month - 1, 1, 0, 0, 0).getTime() / 1000)
  const endTs = Math.floor(new Date(year, month, 0, 23, 59, 59).getTime() / 1000)

  const [membersRaw, loginRows] = await Promise.all([
    prisma.character.findMany({
      where: { player_factionid: id },
      select: { player_id: true, player_name: true, player_factionrank: true, player_logindate: true, player_online: true },
    }),
    prisma.$queryRaw<Array<{ character_id: number; login_count: bigint; last_login: bigint }>>`
      SELECT character_id, COUNT(*) AS login_count, MAX(login_time) AS last_login
      FROM character_login_history WHERE faction_id = ${id} AND login_time BETWEEN ${startTs} AND ${endTs}
      GROUP BY character_id`,
  ])
  const loginMap = new Map(loginRows.map(r => [r.character_id, { count: Number(r.login_count), last: Number(r.last_login) }]))

  const members = membersRaw.map(m => {
    const l = loginMap.get(m.player_id)
    return { ...m, monthLogins: l?.count ?? 0, monthLast: l?.last ?? 0, active: (l?.count ?? 0) > 0 }
  }).sort((a, b) => (a.active === b.active ? a.player_name.localeCompare(b.player_name) : a.active ? -1 : 1))

  const activeCount = members.filter(m => m.active).length
  const totalLogins = members.reduce((s, m) => s + m.monthLogins, 0)
  const years = [...new Set(months.map(x => x.y))]

  return (
    <>
      <form method="GET" action={`/acp/factions/${id}/activity`} className="acp-toolbar">
        <select name="year" defaultValue={year} className="acp-input" style={{ maxWidth: 120 }}>
          {(years.length ? years : [year]).map(y => <option key={y} value={y}>{y}</option>)}
        </select>
        <select name="month" defaultValue={month} className="acp-input" style={{ maxWidth: 160 }}>
          {(months.filter(x => x.y === year).map(x => x.m) || []).length
            ? months.filter(x => x.y === year).map(x => <option key={x.m} value={x.m}>{monthName(x.m)}</option>)
            : <option value={month}>{monthName(month)}</option>}
        </select>
        <button type="submit" className="acp-btn acp-btn-primary">Load</button>
      </form>

      <div className="acp-statusbar" style={{ marginBottom: 14 }}>
        <div className="acp-status"><span className="acp-status-val">{monthName(month)} {year}</span><span className="acp-status-lbl">Period</span></div>
        <div className="acp-status"><span className="acp-status-val">{activeCount} / {members.length}</span><span className="acp-status-lbl">Active In Month</span></div>
        <div className="acp-status"><span className="acp-status-val">{totalLogins.toLocaleString('en-GB')}</span><span className="acp-status-lbl">Recorded Logins</span></div>
        <div className="acp-status"><span className="acp-status-val">{activityTotal(faction.faction_active_minutes)}</span><span className="acp-status-lbl">All-Time Activity</span></div>
      </div>

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Member Login Activity</span></div>
        {members.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-users" />This faction has no members.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th>Member</th><th>Rank</th><th>Status</th><th>Active In Month</th><th>Logins</th><th>Latest Login In Month</th><th>Current Last Login</th></tr></thead>
            <tbody>
              {members.map(m => (
                <tr key={m.player_id}>
                  <td className="acp-td-name"><Link href={`/acp/characters/${m.player_id}`} className="acp-link">{m.player_name.replace(/_/g, ' ')}</Link></td>
                  <td className="acp-td-muted">{m.player_factionrank || 'None'}</td>
                  <td>{m.player_online === 1 ? <span className="acp-badge is-green">Online</span> : <span className="acp-badge is-off">Offline</span>}</td>
                  <td>{m.active ? <span className="acp-badge is-green">Yes</span> : <span className="acp-badge is-red">No</span>}</td>
                  <td>{m.monthLogins}</td>
                  <td className="acp-td-muted">{m.monthLast ? formatUnixDateTime(m.monthLast) : '—'}</td>
                  <td className="acp-td-muted">{m.player_logindate ? formatUnixDateTime(m.player_logindate) : 'Never'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </>
  )
}

function activityTotal(minutes: number): string {
  const d = Math.floor(minutes / 1440), h = Math.floor((minutes % 1440) / 60)
  return `${d}d ${h}h`
}
