import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getCharacterById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { zoneName } from '@/lib/zones'

export const dynamic = 'force-dynamic'

const LOG_TYPE: Record<number, string> = {
  1: 'Chat', 2: 'Action', 3: 'Script', 4: 'Game', 5: 'Damage', 6: 'OOC', 7: 'PM', 8: 'Phone',
  9: 'Pager', 10: 'Admin', 11: 'Radio', 12: 'CMD', 13: 'Drugs', 14: 'Anti-Cheat', 15: 'Graffiti',
  16: 'Job', 17: 'Staff Chat', 18: 'Name Change', 19: 'Money Flow', 20: 'Faction Bank',
}
const fmt = (v: Date | string | null) => (v instanceof Date ? v.toLocaleString('en-GB') : (v ?? '—'))

export default async function Investigate({ params }: PageProps<'/acp/characters/[id]/investigate'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const id = Number((await params).id)
  const c = await getCharacterById(id)
  if (!c) notFound()

  const ipRows = await prisma.$queryRaw<Array<{ logged_ip: string }>>`
    SELECT logged_ip FROM player_logs WHERE log_char_id = ${id}
    GROUP BY logged_ip ORDER BY MAX(log_time) DESC LIMIT 50`
  const ips = ipRows.map(r => r.logged_ip).filter(Boolean)

  const [alts, commands, recent] = await Promise.all([
    ips.length
      ? prisma.$queryRawUnsafe<Array<{ player_id: number; player_name: string; match_count: bigint }>>(
          `SELECT c.player_id, c.player_name, COUNT(*) AS match_count
           FROM player_logs l JOIN characters c ON c.player_id = l.log_char_id
           WHERE l.logged_ip IN (${ips.map(() => '?').join(',')}) AND l.log_char_id > 0 AND c.player_id != ?
           GROUP BY c.player_id ORDER BY match_count DESC LIMIT 50`, ...ips, id)
      : Promise.resolve([]),
    prisma.$queryRaw<Array<{ log_entry: string; uses: bigint }>>`
      SELECT log_entry, COUNT(*) AS uses FROM player_logs
      WHERE log_char_id = ${id} AND log_entry LIKE '/%' GROUP BY log_entry ORDER BY uses DESC LIMIT 10`,
    prisma.$queryRaw<Array<{ log_time: Date; log_type: number; logged_zone: number; log_entry: string }>>`
      SELECT log_time, log_type, logged_zone, log_entry FROM player_logs
      WHERE log_char_id = ${id} ORDER BY log_time DESC LIMIT 100`,
  ])

  return (
    <>
      <div className="acp-hub-head">
        <div className="acp-hub-id">
          <div className="acp-hub-name">Investigate {c.player_name.replace(/_/g, ' ')}</div>
          <div className="acp-hub-meta">Character #{c.player_id}</div>
        </div>
        <div className="acp-hub-actions"><Link href={`/acp/characters/${id}`} className="acp-btn">← Back to Character</Link></div>
      </div>

      <div className="acp-grid-2">
        <section className="acp-panel">
          <div className="acp-panel-head"><span>IP History — {ips.length}</span></div>
          {ips.length === 0 ? <div className="acp-empty"><i className="fa-solid fa-network-wired" />No IPs recorded.</div> : (
            <table className="acp-table"><tbody>{ips.map((ip, idx) => <tr key={idx}><td className="acp-mono">{ip}</td></tr>)}</tbody></table>
          )}
        </section>

        <section className="acp-panel">
          <div className="acp-panel-head"><span>Possible Alt Characters — {alts.length}</span></div>
          {alts.length === 0 ? <div className="acp-empty"><i className="fa-solid fa-user-secret" />No IP-linked characters.</div> : (
            <table className="acp-table">
              <thead><tr><th>Character</th><th>Shared Log Hits</th></tr></thead>
              <tbody>{alts.map(a => (
                <tr key={a.player_id}>
                  <td className="acp-td-name"><Link href={`/acp/characters/${a.player_id}`} className="acp-link">{a.player_name.replace(/_/g, ' ')}</Link></td>
                  <td className="acp-td-muted">{Number(a.match_count).toLocaleString('en-GB')}</td>
                </tr>
              ))}</tbody>
            </table>
          )}
        </section>
      </div>

      <section className="acp-panel" style={{ margin: '14px 0' }}>
        <div className="acp-panel-head"><span>Command Usage (top 10)</span></div>
        {commands.length === 0 ? <div className="acp-empty"><i className="fa-solid fa-terminal" />No commands logged.</div> : (
          <table className="acp-table">
            <thead><tr><th>Command</th><th>Uses</th></tr></thead>
            <tbody>{commands.map((cmd, idx) => (
              <tr key={idx}><td className="acp-mono">{cmd.log_entry}</td><td className="acp-td-muted">{Number(cmd.uses).toLocaleString('en-GB')}</td></tr>
            ))}</tbody>
          </table>
        )}
      </section>

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Recent Activity — latest {recent.length}</span></div>
        {recent.length === 0 ? <div className="acp-empty"><i className="fa-solid fa-clock-rotate-left" />No activity.</div> : (
          <table className="acp-table">
            <thead><tr><th>Time</th><th>Type</th><th>Zone</th><th>Entry</th></tr></thead>
            <tbody>{recent.map((r, idx) => (
              <tr key={idx}>
                <td className="acp-td-muted">{fmt(r.log_time)}</td>
                <td><span className="acp-badge">{LOG_TYPE[r.log_type] ?? `#${r.log_type}`}</span></td>
                <td className="acp-td-muted">{zoneName(r.logged_zone)}</td>
                <td className="acp-td-detail" title={r.log_entry}>{r.log_entry}</td>
              </tr>
            ))}</tbody>
          </table>
        )}
      </section>
    </>
  )
}
