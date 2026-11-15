import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff, serverNow } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'

export const dynamic = 'force-dynamic'

interface GroupRow {
  account_sig: string
  accounts: string // "id:name|id:name"
  ip_count: bigint
  ips: string // "1.2.3.4, 1.2.3.5"
}

export default async function SharedIpsPage() {
  await requireStaff(ADMIN_LVL.GENERAL)
  const now = Math.floor(serverNow() / 1000)

  // Group accounts that share any IP by the *exact set* of accounts, so a
  // dynamic IP hopping across many addresses collapses to one row instead of
  // repeating the same accounts dozens of times. Whitelisted IPs and accounts
  // are excluded outright (active whitelist = no expiry, 0, or future expiry).
  const rows = await prisma.$queryRaw<GroupRow[]>`
    SELECT per_ip.account_sig,
           MAX(per_ip.accounts) AS accounts,
           COUNT(*) AS ip_count,
           GROUP_CONCAT(per_ip.ip_address ORDER BY per_ip.ip_address SEPARATOR ', ') AS ips
    FROM (
      SELECT h.ip_address,
             GROUP_CONCAT(DISTINCT a.account_id ORDER BY a.account_id) AS account_sig,
             GROUP_CONCAT(DISTINCT CONCAT(a.account_id, ':', a.account_name) ORDER BY a.account_id SEPARATOR '|') AS accounts
      FROM account_ip_history h
      JOIN accounts a ON a.account_id = h.account_id
      WHERE h.ip_address IS NOT NULL AND TRIM(h.ip_address) <> ''
        AND h.ip_address NOT IN (
          SELECT ip_address FROM multiaccount_ip_whitelist
          WHERE ip_address IS NOT NULL AND TRIM(ip_address) <> ''
            AND (expires_at IS NULL OR expires_at = 0 OR expires_at > ${now})
        )
        AND a.account_id NOT IN (
          SELECT account_id FROM multiaccount_account_whitelist
          WHERE expires_at IS NULL OR expires_at = 0 OR expires_at > ${now}
        )
      GROUP BY h.ip_address
      HAVING COUNT(DISTINCT a.account_id) > 1
    ) per_ip
    GROUP BY per_ip.account_sig
    ORDER BY ip_count DESC, per_ip.account_sig
    LIMIT 100`

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Shared IPs — {rows.length} linked group{rows.length === 1 ? '' : 's'}</span></div>
      {rows.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-network-wired" />No non-whitelisted accounts share an IP.</div>
      ) : (
        <table className="acp-table">
          <thead><tr><th>Addresses</th><th>IPs</th><th>Linked Accounts</th></tr></thead>
          <tbody>
            {rows.map(r => {
              const accounts = (r.accounts || '').split('|').filter(Boolean).map(s => {
                const idx = s.indexOf(':')
                return { id: s.slice(0, idx), name: s.slice(idx + 1) }
              })
              const count = Number(r.ip_count)
              return (
                <tr key={r.account_sig}>
                  <td className="acp-mono"><div className="acp-ips-list" title={r.ips}>{r.ips}</div></td>
                  <td><span className="acp-badge is-amber">{count} IP{count === 1 ? '' : 's'}</span></td>
                  <td>
                    {accounts.map((a, j) => (
                      <span key={a.id}>
                        <Link href={`/acp/players/${a.id}`} className="acp-link">{a.name}</Link>
                        {j < accounts.length - 1 ? ', ' : ''}
                      </span>
                    ))}
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
