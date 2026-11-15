import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff, serverNow } from '@/lib/dal'
import { ADMIN_LVL, staffLevelTitle } from '@/lib/constants'

export const dynamic = 'force-dynamic'

const REC_KICK = 0
const REC_AJAIL = 1
const REC_BAN = 2

interface TopAdminRow {
  account_id: number
  name: string
  account_stafflevel: number | null
  total?: number
  punishments?: number
  reports?: number
  actions?: number
}

interface ActionRow {
  account_id: number
  account_name: string
  action_type: string
  description: string
  created_at: number
}

const asCount = (rows: Array<{ c: bigint | number }>): number => (rows.length ? Number(rows[0].c) : 0)

/** Compact relative time from a unix-seconds timestamp. */
function ago(unix: number, now: number): string {
  const s = Math.max(0, now - unix)
  if (s < 60) return `${s}s`
  if (s < 3600) return `${Math.floor(s / 60)}m`
  if (s < 86400) return `${Math.floor(s / 3600)}h`
  return `${Math.floor(s / 86400)}d`
}

/** "offline_ajail" → "Offline Ajail". */
const humanise = (s: string) => s.replace(/[_-]+/g, ' ').replace(/\b\w/g, c => c.toUpperCase())

export default async function AcpDashboard() {
  const user = await requireStaff(ADMIN_LVL.JUNIOR)

  const nowUnix = Math.floor(serverNow() / 1000)
  const weekAgo = nowUnix - 7 * 86400

  const [
    totalStaff, staffOnline, totalAccounts, activeBans, weekNewBans,
    weekReportsRows, weekActionsRows, weekRefundsRows, punRows,
    recentActions, topAdminRows, topReporterRows, topPunisherRows,
  ] = await Promise.all([
    prisma.account.count({ where: { account_stafflevel: { gt: 0 } } }),
    prisma.account.count({ where: { account_stafflevel: { gt: 0 }, account_online: 1 } }),
    prisma.account.count(),
    prisma.ban.count({ where: { OR: [{ unban_time: 0 }, { unban_time: { gt: nowUnix } }] } }),
    prisma.ban.count({ where: { ban_time: { gte: weekAgo } } }),

    prisma.$queryRaw<Array<{ c: bigint }>>`SELECT COUNT(*) AS c FROM admin_report_logs WHERE accepted_unix >= ${weekAgo}`,
    prisma.$queryRaw<Array<{ c: bigint }>>`SELECT COUNT(*) AS c FROM admin_action_logs WHERE created_at >= ${weekAgo}`,
    prisma.$queryRaw<Array<{ c: bigint }>>`SELECT COUNT(*) AS c FROM refunds WHERE refund_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)`,

    prisma.$queryRaw<Array<{ record_type: number; cnt: bigint }>>`
      SELECT record_type, COUNT(*) AS cnt FROM admin_record
      WHERE (CASE WHEN record_date REGEXP '^[0-9]{4}-'
               THEN STR_TO_DATE(record_date, '%Y-%m-%d %H:%i:%s')
               ELSE STR_TO_DATE(record_date, '%d/%m/%Y, %H:%i') END) >= DATE_SUB(NOW(), INTERVAL 7 DAY)
      GROUP BY record_type`,

    prisma.$queryRaw<ActionRow[]>`
      SELECT account_id, account_name, action_type, description, created_at
      FROM admin_action_logs ORDER BY created_at DESC LIMIT 12`,

    prisma.$queryRaw<TopAdminRow[]>`
      SELECT combined.account_id, COALESCE(a.account_name, 'Unknown') AS name, a.account_stafflevel,
             SUM(combined.cnt) AS total,
             SUM(CASE WHEN combined.source = 'punishments' THEN combined.cnt ELSE 0 END) AS punishments,
             SUM(CASE WHEN combined.source = 'reports' THEN combined.cnt ELSE 0 END) AS reports,
             SUM(CASE WHEN combined.source = 'actions' THEN combined.cnt ELSE 0 END) AS actions
      FROM (
        SELECT record_admin AS account_id, COUNT(*) AS cnt, 'punishments' AS source FROM admin_record
        WHERE record_admin > 0 AND (CASE WHEN record_date REGEXP '^[0-9]{4}-'
            THEN STR_TO_DATE(record_date, '%Y-%m-%d %H:%i:%s')
            ELSE STR_TO_DATE(record_date, '%d/%m/%Y, %H:%i') END) >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY record_admin
        UNION ALL
        SELECT admin_account_id, COUNT(*), 'reports' FROM admin_report_logs WHERE accepted_unix >= ${weekAgo} GROUP BY admin_account_id
        UNION ALL
        SELECT account_id, COUNT(*), 'actions' FROM admin_action_logs WHERE created_at >= ${weekAgo} GROUP BY account_id
      ) AS combined
      LEFT JOIN accounts a ON a.account_id = combined.account_id
      GROUP BY combined.account_id ORDER BY total DESC LIMIT 1`,

    prisma.$queryRaw<TopAdminRow[]>`
      SELECT l.admin_account_id AS account_id, COALESCE(a.account_name, l.admin_account_name) AS name,
             a.account_stafflevel, COUNT(*) AS reports
      FROM admin_report_logs l LEFT JOIN accounts a ON a.account_id = l.admin_account_id
      WHERE l.accepted_unix >= ${weekAgo} GROUP BY l.admin_account_id ORDER BY reports DESC LIMIT 1`,

    prisma.$queryRaw<TopAdminRow[]>`
      SELECT r.record_admin AS account_id, COALESCE(a.account_name, 'Unknown') AS name,
             a.account_stafflevel, COUNT(*) AS punishments
      FROM admin_record r LEFT JOIN accounts a ON a.account_id = r.record_admin
      WHERE r.record_admin > 0 AND (CASE WHEN r.record_date REGEXP '^[0-9]{4}-'
          THEN STR_TO_DATE(r.record_date, '%Y-%m-%d %H:%i:%s')
          ELSE STR_TO_DATE(r.record_date, '%d/%m/%Y, %H:%i') END) >= DATE_SUB(NOW(), INTERVAL 7 DAY)
      GROUP BY r.record_admin ORDER BY punishments DESC LIMIT 1`,
  ])

  const weekReports = asCount(weekReportsRows)
  const weekActions = asCount(weekActionsRows)
  const weekRefunds = asCount(weekRefundsRows)

  let weekKicks = 0, weekAjails = 0, weekBanPun = 0
  for (const p of punRows) {
    if (p.record_type === REC_KICK) weekKicks = Number(p.cnt)
    else if (p.record_type === REC_AJAIL) weekAjails = Number(p.cnt)
    else if (p.record_type === REC_BAN) weekBanPun = Number(p.cnt)
  }
  const weekTotalPun = weekKicks + weekAjails + weekBanPun

  const topAdmin = topAdminRows[0] ?? null
  const topReporter = topReporterRows[0] ?? null
  const topPunisher = topPunisherRows[0] ?? null

  const n = (v: number) => v.toLocaleString('en-GB')

  return (
    <>
      {/* Status strip */}
      <div className="acp-statusbar">
        <div className="acp-status">
          <span className="acp-status-val">{n(totalStaff)}</span>
          <span className="acp-status-lbl">Staff Members</span>
        </div>
        <div className="acp-status">
          <span className={`acp-status-val ${staffOnline > 0 ? 'is-green' : ''}`}>
            <span className={`acp-dot ${staffOnline > 0 ? 'is-green' : 'is-dim'}`} />{n(staffOnline)}
          </span>
          <span className="acp-status-lbl">Staff Online</span>
        </div>
        <div className="acp-status">
          <span className="acp-status-val">{n(totalAccounts)}</span>
          <span className="acp-status-lbl">Registered Accounts</span>
        </div>
        <div className="acp-status">
          <span className={`acp-status-val ${activeBans > 0 ? 'is-red' : ''}`}>{n(activeBans)}</span>
          <span className="acp-status-lbl">Active Bans</span>
        </div>
        <div className="acp-status acp-status-greet">
          <span className="acp-status-val">{user.name}</span>
          <span className="acp-status-lbl">{staffLevelTitle(user.staffLevel)}</span>
        </div>
      </div>

      <div className="acp-dash-grid">
        {/* Recent admin actions */}
        <section className="acp-panel">
          <div className="acp-panel-head">
            <span>Recent Admin Actions</span>
            <Link href="/acp/logs/admin-actions" className="acp-panel-link">View all →</Link>
          </div>
          <table className="acp-table">
            <thead>
              <tr><th style={{ width: 56 }}>When</th><th>Admin</th><th>Action</th><th>Detail</th></tr>
            </thead>
            <tbody>
              {recentActions.length === 0 ? (
                <tr><td colSpan={4} className="acp-table-empty">No admin actions recorded.</td></tr>
              ) : recentActions.map((a, i) => (
                <tr key={i}>
                  <td className="acp-td-muted">{ago(Number(a.created_at), nowUnix)}</td>
                  <td>
                    <Link href={`/acp/players/${a.account_id}`} className="acp-link">{a.account_name || 'Unknown'}</Link>
                  </td>
                  <td><span className="acp-badge">{humanise(a.action_type)}</span></td>
                  <td className="acp-td-detail" title={a.description}>{a.description}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>

        <div className="acp-dash-side">
          {/* Last 7 days */}
          <section className="acp-panel">
            <div className="acp-panel-head"><span>Last 7 Days</span></div>
            <div className="acp-kv">
              <div className="acp-kv-row"><span>Punishments</span><b>{n(weekTotalPun)}</b></div>
              <div className="acp-kv-break">
                <span><span className="acp-dot" style={{ background: '#f59e0b' }} /> Kicks <b>{n(weekKicks)}</b></span>
                <span><span className="acp-dot" style={{ background: '#f97316' }} /> A-Jails <b>{n(weekAjails)}</b></span>
                <span><span className="acp-dot" style={{ background: '#dc2626' }} /> Bans <b>{n(weekBanPun)}</b></span>
              </div>
              <div className="acp-kv-row"><span>Reports Accepted</span><b>{n(weekReports)}</b></div>
              <div className="acp-kv-row"><span>Admin Actions</span><b>{n(weekActions)}</b></div>
              <div className="acp-kv-row"><span>New Bans Issued</span><b>{n(weekNewBans)}</b></div>
              <div className="acp-kv-row"><span>Refunds Issued</span><b>{n(weekRefunds)}</b></div>
            </div>
          </section>

          {/* Top staff */}
          <section className="acp-panel">
            <div className="acp-panel-head"><span>Top Staff — This Week</span></div>
            <div className="acp-ranks">
              <RankRow row={topAdmin} label="Most active" pills={topAdmin ? [
                { label: `${n(Number(topAdmin.punishments ?? 0))} punishments`, cls: 'is-red' },
                { label: `${n(Number(topAdmin.actions ?? 0))} actions`, cls: 'is-blue' },
                { label: `${n(Number(topAdmin.reports ?? 0))} reports`, cls: 'is-green' },
              ] : []} />
              <RankRow row={topReporter} label="Most reports" pills={topReporter ? [{ label: `${n(Number(topReporter.reports ?? 0))} reports`, cls: 'is-green' }] : []} />
              <RankRow row={topPunisher} label="Most punishments" pills={topPunisher ? [{ label: `${n(Number(topPunisher.punishments ?? 0))} punishments`, cls: 'is-red' }] : []} />
            </div>
          </section>
        </div>
      </div>
    </>
  )
}

function RankRow({ row, label, pills }: {
  row: TopAdminRow | null; label: string; pills: Array<{ label: string; cls: string }>
}) {
  if (!row) {
    return (
      <div className="acp-rank is-empty">
        <span className="acp-rank-av">?</span>
        <div className="acp-rank-body"><span className="acp-rank-name">Nobody</span><span className="acp-rank-lbl">{label}</span></div>
      </div>
    )
  }
  return (
    <Link href={`/acp/players/${row.account_id}`} className="acp-rank">
      <span className="acp-rank-av">{(row.name || '?').charAt(0).toUpperCase()}</span>
      <div className="acp-rank-body">
        <span className="acp-rank-name">{row.name}</span>
        <span className="acp-rank-lbl">{label} · {staffLevelTitle(row.account_stafflevel ?? 0)}</span>
        <div className="acp-rank-pills">{pills.map((p, i) => <span key={i} className={`acp-badge ${p.cls}`}>{p.label}</span>)}</div>
      </div>
    </Link>
  )
}
