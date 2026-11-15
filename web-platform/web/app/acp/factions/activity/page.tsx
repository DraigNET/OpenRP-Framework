import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'

export const dynamic = 'force-dynamic'

const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''
const pad = (n: number) => String(n).padStart(2, '0')
const ymd = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
const monthName = (m: number) => new Date(2000, m - 1, 1).toLocaleString('en-GB', { month: 'long' })

function activityDuration(minutes: number): string {
  const d = Math.floor(minutes / 1440), h = Math.floor((minutes % 1440) / 60), m = minutes % 60
  return `${d}d ${h}h ${m}m`
}
const factionColor = (hex: number) => `#${(hex >>> 8).toString(16).padStart(6, '0')}`

/** Monday of the given ISO week (matches MySQL WEEK(date, 1)). */
function isoWeekStart(year: number, week: number): Date {
  const jan4 = new Date(year, 0, 4)
  const dow = (jan4.getDay() + 6) % 7
  const week1Mon = new Date(jan4); week1Mon.setDate(jan4.getDate() - dow)
  const monday = new Date(week1Mon); monday.setDate(week1Mon.getDate() + (week - 1) * 7)
  return monday
}

export default async function GlobalFactionActivity({ searchParams }: PageProps<'/acp/factions/activity'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const sp = await searchParams
  const modeRaw = firstParam(sp.mode)
  const mode = (['all', 'week', 'month'] as const).includes(modeRaw as never) ? modeRaw : 'all'

  const [factions, counts, weeksRaw, monthsRaw] = await Promise.all([
    prisma.faction.findMany({
      where: { faction_show_activity: 1 },
      select: { faction_id: true, faction_name: true, faction_abbrev: true, faction_hex: true, faction_active_minutes: true },
    }),
    prisma.character.groupBy({ by: ['player_factionid'], where: { player_factionid: { gt: 0 } }, _count: { player_id: true } }),
    prisma.$queryRaw<Array<{ y: number; w: number }>>`
      SELECT DISTINCT YEAR(a.activity_date) AS y, WEEK(a.activity_date, 1) AS w
      FROM faction_activity a JOIN factions f ON f.faction_id = a.faction_id
      WHERE f.faction_show_activity = 1 ORDER BY y DESC, w DESC`,
    prisma.$queryRaw<Array<{ y: number; m: number }>>`
      SELECT DISTINCT YEAR(a.activity_date) AS y, MONTH(a.activity_date) AS m
      FROM faction_activity a JOIN factions f ON f.faction_id = a.faction_id
      WHERE f.faction_show_activity = 1 ORDER BY y DESC, m DESC`,
  ])
  const countMap = new Map(counts.map(c => [c.player_factionid, c._count.player_id]))
  const weeks = weeksRaw.map(r => ({ y: Number(r.y), w: Number(r.w) }))
  const months = monthsRaw.map(r => ({ y: Number(r.y), m: Number(r.m) }))

  // Resolve selected period (default to latest available)
  let year = Number(firstParam(sp.year)) || 0
  let week = Number(firstParam(sp.week)) || 0
  let month = Number(firstParam(sp.month)) || 0
  if (mode === 'week' && !week && weeks[0]) { year = year || weeks[0].y; week = weeks[0].w }
  if (mode === 'month' && !month && months[0]) { year = year || months[0].y; month = months[0].m }

  // Period minutes
  let minutesMap = new Map<number, number>()
  if (mode === 'all') {
    minutesMap = new Map(factions.map(f => [f.faction_id, f.faction_active_minutes]))
  } else {
    let start: string, end: string
    if (mode === 'week') {
      const mon = isoWeekStart(year, week)
      const sun = new Date(mon); sun.setDate(mon.getDate() + 6)
      start = ymd(mon); end = ymd(sun)
    } else {
      start = `${year}-${pad(month)}-01`
      end = ymd(new Date(year, month, 0))
    }
    const sums = await prisma.$queryRawUnsafe<Array<{ faction_id: number; minutes: bigint }>>(
      `SELECT faction_id, SUM(minutes) AS minutes FROM faction_activity WHERE activity_date BETWEEN ? AND ? GROUP BY faction_id`,
      start, end)
    minutesMap = new Map(sums.map(s => [s.faction_id, Number(s.minutes)]))
  }

  const rows = factions
    .map(f => ({ ...f, minutes: minutesMap.get(f.faction_id) ?? 0, members: countMap.get(f.faction_id) ?? 0 }))
    .sort((a, b) => b.minutes - a.minutes)
  const maxMinutes = Math.max(1, ...rows.map(r => r.minutes))

  const years = [...new Set((mode === 'month' ? months : weeks).map(x => x.y))]
  const tab = (m: string, label: string) =>
    <Link href={`/acp/factions/activity?mode=${m}`} className={`acp-btn${mode === m ? ' acp-btn-primary' : ''}`}>{label}</Link>

  return (
    <>
      <div className="acp-toolbar">{tab('all', 'All Time')}{tab('week', 'Weekly')}{tab('month', 'Monthly')}</div>

      {mode === 'week' && (
        <form method="GET" action="/acp/factions/activity" className="acp-toolbar">
          <input type="hidden" name="mode" value="week" />
          <select name="year" defaultValue={year} className="acp-input" style={{ maxWidth: 120 }}>
            {years.map(y => <option key={y} value={y}>{y}</option>)}
          </select>
          <select name="week" defaultValue={week} className="acp-input" style={{ maxWidth: 150 }}>
            {weeks.filter(x => x.y === year).map(x => <option key={x.w} value={x.w}>Week {x.w}</option>)}
          </select>
          <button type="submit" className="acp-btn acp-btn-primary">Load</button>
        </form>
      )}
      {mode === 'month' && (
        <form method="GET" action="/acp/factions/activity" className="acp-toolbar">
          <input type="hidden" name="mode" value="month" />
          <select name="year" defaultValue={year} className="acp-input" style={{ maxWidth: 120 }}>
            {years.map(y => <option key={y} value={y}>{y}</option>)}
          </select>
          <select name="month" defaultValue={month} className="acp-input" style={{ maxWidth: 160 }}>
            {months.filter(x => x.y === year).map(x => <option key={x.m} value={x.m}>{monthName(x.m)}</option>)}
          </select>
          <button type="submit" className="acp-btn acp-btn-primary">Load</button>
        </form>
      )}

      <section className="acp-panel" style={{ marginBottom: 14 }}>
        <div className="acp-panel-head"><span>Activity Hours</span></div>
        <div className="acp-bars">
          {rows.map(r => (
            <div key={r.faction_id} className="acp-bar-col" title={`${r.faction_name}: ${activityDuration(r.minutes)}`}>
              <span className="acp-bar-val">{Math.round(r.minutes / 60)}</span>
              <div className="acp-bar" style={{ height: `${Math.max(2, (r.minutes / maxMinutes) * 100)}%`, background: factionColor(r.faction_hex) }} />
              <span className="acp-bar-lbl">{r.faction_abbrev || r.faction_name.slice(0, 4)}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="acp-panel">
        <div className="acp-panel-head">
          <span>{mode === 'all' ? 'All-Time' : mode === 'week' ? `Week ${week}, ${year}` : `${monthName(month)} ${year}`} — {rows.length} factions</span>
        </div>
        {rows.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-chart-column" />No activity data for this period.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th>Faction</th><th>Abbrev</th><th>Members</th><th>Activity</th><th>Minutes</th><th></th></tr></thead>
            <tbody>
              {rows.map(r => (
                <tr key={r.faction_id}>
                  <td>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ width: 9, height: 9, borderRadius: 2, background: factionColor(r.faction_hex), display: 'inline-block' }} />
                      <Link href={`/acp/factions/${r.faction_id}/activity`} className="acp-link">{r.faction_name}</Link>
                    </span>
                  </td>
                  <td className="acp-td-muted">{r.faction_abbrev || '—'}</td>
                  <td>{r.members}</td>
                  <td>{activityDuration(r.minutes)}</td>
                  <td className="acp-td-muted">{r.minutes.toLocaleString('en-GB')}</td>
                  <td style={{ textAlign: 'right' }}>
                    <Link href={`/acp/factions/${r.faction_id}/activity`} className="acp-btn acp-btn-sm">View Members</Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </>
  )
}
