import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff, serverNow } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDate } from '@/lib/format'
import { AddIpForm, AddAccountForm, RemoveButton } from './WhitelistClient'

export const dynamic = 'force-dynamic'

function expiryLabel(expires: number | null, now: number) {
  if (!expires || expires === 0) return <span className="acp-badge is-green">Permanent</span>
  if (expires > now) return <span className="acp-td-muted">Until {formatUnixDate(expires)}</span>
  return <span className="acp-badge is-off">Expired</span>
}

export default async function WhitelistPage() {
  await requireStaff(ADMIN_LVL.MANAGER)
  const now = Math.floor(serverNow() / 1000)

  const [ips, accts] = await Promise.all([
    prisma.multiaccountIpWhitelist.findMany({ orderBy: { whitelist_id: 'desc' } }),
    prisma.multiaccountAccountWhitelist.findMany({ orderBy: { whitelist_id: 'desc' } }),
  ])

  const acctIds = accts.map(a => a.account_id)
  const acctNames = acctIds.length
    ? await prisma.account.findMany({ where: { account_id: { in: acctIds } }, select: { account_id: true, account_name: true } })
    : []
  const nameMap = new Map(acctNames.map(a => [a.account_id, a.account_name]))

  return (
    <div className="acp-grid-2">
      <section className="acp-panel">
        <div className="acp-panel-head"><span>Whitelisted IPs — {ips.length}</span></div>
        <div style={{ padding: 12, borderBottom: '1px solid var(--acp-line)' }}><AddIpForm /></div>
        {ips.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-shield" />No IPs whitelisted.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th>IP Address</th><th>Reason</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {ips.map(ip => (
                <tr key={ip.whitelist_id}>
                  <td className="acp-mono">{ip.ip_address}</td>
                  <td className="acp-td-detail" title={ip.reason ?? ''}>{ip.reason || '—'}</td>
                  <td>{expiryLabel(ip.expires_at, now)}</td>
                  <td style={{ textAlign: 'right' }}><RemoveButton kind="ip" id={ip.whitelist_id} label={ip.ip_address} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Whitelisted Accounts — {accts.length}</span></div>
        <div style={{ padding: 12, borderBottom: '1px solid var(--acp-line)' }}><AddAccountForm /></div>
        {accts.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-user-shield" />No accounts whitelisted.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th>Account</th><th>Reason</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {accts.map(a => (
                <tr key={a.whitelist_id}>
                  <td><Link href={`/acp/players/${a.account_id}`} className="acp-link">{nameMap.get(a.account_id) ?? `#${a.account_id}`}</Link></td>
                  <td className="acp-td-detail" title={a.reason ?? ''}>{a.reason || '—'}</td>
                  <td>{expiryLabel(a.expires_at, now)}</td>
                  <td style={{ textAlign: 'right' }}><RemoveButton kind="account" id={a.whitelist_id} label={nameMap.get(a.account_id) ?? `#${a.account_id}`} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  )
}
