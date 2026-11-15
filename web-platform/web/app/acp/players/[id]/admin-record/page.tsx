import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getAccountById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'

export const dynamic = 'force-dynamic'

const TYPE: Record<number, { label: string; cls: string }> = {
  0: { label: 'Kick', cls: 'is-amber' },
  1: { label: 'Admin Jail', cls: 'is-amber' },
  2: { label: 'Ban', cls: 'is-red' },
}

interface RecRow {
  record_id: number
  record_type: number
  record_reason: string
  record_time: number
  record_date: string
  admin_name: string
}

export default async function PlayerAdminRecord({ params }: PageProps<'/acp/players/[id]/admin-record'>) {
  await requireStaff(ADMIN_LVL.JUNIOR)
  const id = Number((await params).id)
  if (!(await getAccountById(id))) notFound()

  const rows = await prisma.$queryRaw<RecRow[]>`
    SELECT r.record_id, r.record_type, r.record_reason, r.record_time, r.record_date,
           COALESCE(a.account_name, CONCAT('#', r.record_admin)) AS admin_name
    FROM admin_record r LEFT JOIN accounts a ON a.account_id = r.record_admin
    WHERE r.account_id = ${id} ORDER BY r.record_id DESC LIMIT 200`

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Admin Record — {rows.length}</span></div>
      {rows.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-gavel" />No punishments on record.</div>
      ) : (
        <table className="acp-table">
          <thead>
            <tr><th>Type</th><th>Reason</th><th>Duration</th><th>Admin</th><th>Date</th></tr>
          </thead>
          <tbody>
            {rows.map(r => {
              const t = TYPE[r.record_type] ?? { label: `#${r.record_type}`, cls: 'is-off' }
              const mins = Number(r.record_time)
              return (
                <tr key={r.record_id}>
                  <td><span className={`acp-badge ${t.cls}`}>{t.label}</span></td>
                  <td className="acp-td-detail" title={r.record_reason}>{r.record_reason || '—'}</td>
                  <td className="acp-td-muted">{mins > 0 ? `${Math.round(mins / 60)} min` : '—'}</td>
                  <td className="acp-td-muted">{r.admin_name}</td>
                  <td className="acp-td-muted">{r.record_date || '—'}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
    </section>
  )
}
