import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getAccountById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDate } from '@/lib/format'

export const dynamic = 'force-dynamic'

interface IpRow {
  ip_address: string
  first_seen: number | bigint
  last_seen: number | bigint
  access_count: number | bigint
  shared: bigint
}

export default async function PlayerConnections({ params }: PageProps<'/acp/players/[id]/connections'>) {
  await requireStaff(ADMIN_LVL.JUNIOR)
  const id = Number((await params).id)
  if (!(await getAccountById(id))) notFound()

  const rows = await prisma.$queryRaw<IpRow[]>`
    SELECT h.ip_address, h.first_seen, h.last_seen, h.access_count,
           (SELECT COUNT(DISTINCT o.account_id) FROM account_ip_history o
            WHERE o.ip_address = h.ip_address AND o.account_id <> ${id}) AS shared
    FROM account_ip_history h WHERE h.account_id = ${id}
    ORDER BY h.last_seen DESC LIMIT 100`

  return (
    <section className="acp-panel">
      <div className="acp-panel-head">
        <span>IP History — {rows.length}</span>
        <Link href="/acp/shared-ips" className="acp-panel-link">Shared IPs tool →</Link>
      </div>
      {rows.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-network-wired" />No recorded IP history.</div>
      ) : (
        <table className="acp-table">
          <thead><tr><th>IP Address</th><th>First Seen</th><th>Last Seen</th><th>Visits</th><th>Shared With</th></tr></thead>
          <tbody>
            {rows.map((r, i) => {
              const shared = Number(r.shared)
              return (
                <tr key={i}>
                  <td className="acp-mono">{r.ip_address}</td>
                  <td className="acp-td-muted">{formatUnixDate(Number(r.first_seen))}</td>
                  <td className="acp-td-muted">{formatUnixDate(Number(r.last_seen))}</td>
                  <td className="acp-td-muted">{Number(r.access_count)}</td>
                  <td>{shared > 0
                    ? <span className="acp-badge is-amber">{shared} other account{shared === 1 ? '' : 's'}</span>
                    : <span className="acp-td-muted">—</span>}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
    </section>
  )
}
