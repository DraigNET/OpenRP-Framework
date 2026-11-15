import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDate } from '@/lib/format'

export const dynamic = 'force-dynamic'

export default async function DonatorsPage() {
  await requireStaff(ADMIN_LVL.GENERAL)

  const donators = await prisma.account.findMany({
    where: { account_premiumlevel: { gt: 0 } },
    orderBy: [{ account_premiumlevel: 'desc' }, { account_id: 'asc' }],
    select: {
      account_id: true, account_name: true, account_premiumlevel: true,
      account_online: true, account_register_date: true,
    },
  })

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Donators — {donators.length}</span></div>
      {donators.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-gem" />No donators on record.</div>
      ) : (
        <table className="acp-table">
          <thead><tr><th style={{ width: 56 }}>ID</th><th>Account</th><th>Premium Level</th><th>Status</th><th>Registered</th></tr></thead>
          <tbody>
            {donators.map(d => (
              <tr key={d.account_id}>
                <td className="acp-td-muted">{d.account_id}</td>
                <td><Link href={`/acp/players/${d.account_id}`} className="acp-link">{d.account_name}</Link></td>
                <td><span className="acp-badge is-amber">Level {d.account_premiumlevel}</span></td>
                <td>{d.account_online === 1 ? <span className="acp-badge is-green">Online</span> : <span className="acp-badge is-off">Offline</span>}</td>
                <td className="acp-td-muted">{formatUnixDate(d.account_register_date)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
