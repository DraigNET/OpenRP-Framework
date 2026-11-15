import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDate } from '@/lib/format'
import { AddVpnForm, RemoveVpnButton } from './VpnWhitelistClient'

export const dynamic = 'force-dynamic'

export default async function VpnWhitelistPage() {
  await requireStaff(ADMIN_LVL.GENERAL)

  const rows = await prisma.vpnWhitelist.findMany({ orderBy: { whitelist_id: 'desc' } })

  // The table stores only account IDs. Resolve names here so a player who renames
  // still shows up correctly — the entry follows the account, not the old name.
  const ids = [
    ...new Set([
      ...rows.map(r => r.account_id),
      ...rows.map(r => r.created_by).filter((v): v is number => typeof v === 'number'),
    ]),
  ]
  const accounts = ids.length
    ? await prisma.account.findMany({
        where: { account_id: { in: ids } },
        select: { account_id: true, account_name: true },
      })
    : []
  const nameMap = new Map(accounts.map(a => [a.account_id, a.account_name]))

  return (
    <section className="acp-panel">
      <div className="acp-panel-head">
        <span>VPN Whitelist — {rows.length}</span>
      </div>

      <div style={{ padding: 12, borderBottom: '1px solid var(--acp-line)' }}>
        <AddVpnForm />
      </div>

      {rows.length === 0 ? (
        <div className="acp-empty">
          <i className="fa-solid fa-shield-halved" />
          No accounts are exempt from the VPN check.
        </div>
      ) : (
        <table className="acp-table">
          <thead>
            <tr>
              <th>Account</th>
              <th>Reason</th>
              <th>Added by</th>
              <th>Added</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {rows.map(r => {
              const name = nameMap.get(r.account_id) ?? `#${r.account_id}`
              return (
                <tr key={r.whitelist_id}>
                  <td>
                    <Link href={`/acp/players/${r.account_id}`} className="acp-link">{name}</Link>
                  </td>
                  <td className="acp-td-detail" title={r.reason ?? ''}>{r.reason || '—'}</td>
                  <td className="acp-td-muted">
                    {r.created_by ? (nameMap.get(r.created_by) ?? `#${r.created_by}`) : '—'}
                  </td>
                  <td className="acp-td-muted">
                    {r.created_at ? formatUnixDate(r.created_at) : '—'}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <RemoveVpnButton id={r.whitelist_id} label={name} />
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}
    </section>
  )
}
