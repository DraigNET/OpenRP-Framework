import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'

export const dynamic = 'force-dynamic'

const FLAGS: Array<[keyof Row, string]> = [
  ['account_gunban', 'Gun Ban'],
  ['account_facban', 'Faction Ban'],
  ['account_sprintban', 'Sprint Ban'],
  ['account_bikeban', 'Bike Ban'],
  ['account_vehban', 'Vehicle Ban'],
]

interface Row {
  account_id: number
  account_name: string
  account_online: number
  account_gunban: number
  account_facban: number
  account_sprintban: number
  account_bikeban: number
  account_vehban: number
}

export default async function ActivePenaltiesPage() {
  await requireStaff(ADMIN_LVL.GENERAL)

  const accounts = await prisma.account.findMany({
    where: {
      OR: [
        { account_gunban: 1 }, { account_facban: 1 }, { account_sprintban: 1 },
        { account_bikeban: 1 }, { account_vehban: 1 },
      ],
    },
    select: {
      account_id: true, account_name: true, account_online: true,
      account_gunban: true, account_facban: true, account_sprintban: true,
      account_bikeban: true, account_vehban: true,
    },
    orderBy: [{ account_name: 'asc' }],
  })

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Active Penalties — {accounts.length} accounts</span></div>
      {accounts.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-circle-check" />No accounts have active penalties.</div>
      ) : (
        <table className="acp-table">
          <thead><tr><th style={{ width: 56 }}>ID</th><th>Account</th><th>Status</th><th>Active Penalties</th></tr></thead>
          <tbody>
            {accounts.map(a => {
              const active = FLAGS.filter(([k]) => (a[k] as number) === 1).map(([, label]) => label)
              return (
                <tr key={a.account_id}>
                  <td className="acp-td-muted">{a.account_id}</td>
                  <td><Link href={`/acp/players/${a.account_id}/penalties`} className="acp-link">{a.account_name}</Link></td>
                  <td>{a.account_online === 1 ? <span className="acp-badge is-green">Online</span> : <span className="acp-badge is-off">Offline</span>}</td>
                  <td>{active.map(l => <span key={l} className="acp-badge is-amber" style={{ marginRight: 4 }}>{l}</span>)}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
    </section>
  )
}
