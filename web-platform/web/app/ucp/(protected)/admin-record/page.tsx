import { prisma } from '@/lib/prisma'
import { requireUser } from '@/lib/dal'
import type { ReactNode } from 'react'

export default async function AdminRecordPage() {
  const user = await requireUser()

  const records = await prisma.adminRecord.findMany({
    where: { account_id: user.id },
    orderBy: { record_id: 'desc' },
  })

  const adminIds = [...new Set(records.map(r => r.record_admin).filter(Boolean))]
  const admins = adminIds.length > 0
    ? await prisma.account.findMany({ where: { account_id: { in: adminIds } }, select: { account_id: true, account_name: true } })
    : []
  const adminMap = Object.fromEntries(admins.map(a => [a.account_id, a.account_name]))

  const charIds = [...new Set(records.map(r => r.character_id).filter(Boolean))]
  const chars = charIds.length > 0
    ? await prisma.character.findMany({ where: { player_id: { in: charIds } }, select: { player_id: true, player_name: true } })
    : []
  const charMap = Object.fromEntries(chars.map(c => [c.player_id, c.player_name.replace('_', ' ')]))

  const kicks = records.filter(r => r.record_type === 0)
  const ajails = records.filter(r => r.record_type === 1)
  const bans = records.filter(r => r.record_type === 2)

  // Plain render helper (not a component) — builds a records table inline.
  const renderTable = (rows: typeof records, extraCol = false): ReactNode => (
    <table className="ucp-table admin-record-table">
      <thead>
        <tr>
          <th>Character</th>
          <th>Reason</th>
          {extraCol && <th>Time</th>}
          <th>Admin</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        {rows.map(r => (
          <tr key={r.record_id}>
            <td>{charMap[r.character_id] ?? 'Unknown'}</td>
            <td>{r.record_reason || '—'}</td>
            {extraCol && <td>{r.record_time > 0 ? `${r.record_time} min` : '—'}</td>}
            <td>{adminMap[r.record_admin] ?? 'Unknown'}</td>
            <td>{r.record_date || '—'}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )

  return (
    <>
      <div className="ucp-card admin-record-card admin-record-section">
        <h2>Admin Records</h2>
        <p className="ucp-muted">All disciplinary actions taken against your account.</p>
      </div>

      <div className="ucp-card admin-record-card admin-record-section">
        <h3>Kicks</h3>
        {kicks.length === 0
          ? <p className="ucp-muted">No kick records found.</p>
          : renderTable(kicks)}
      </div>

      <div className="ucp-card admin-record-card admin-record-section">
        <h3>Admin Jails</h3>
        {ajails.length === 0
          ? <p className="ucp-muted">No admin jail records found.</p>
          : renderTable(ajails, true)}
      </div>

      <div className="ucp-card admin-record-card admin-record-section">
        <h3>Bans</h3>
        {bans.length === 0
          ? <p className="ucp-muted">No bans on record.</p>
          : renderTable(bans)}
      </div>
    </>
  )
}
