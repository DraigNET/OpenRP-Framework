import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff, serverNow } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDateTime } from '@/lib/format'
import UnbanButton from './UnbanButton'
import Pagination from '../Pagination'

export const dynamic = 'force-dynamic'

const PER_PAGE = 25
const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''

function banStatus(unbanTime: number, now: number) {
  if (unbanTime === 0) return <span className="acp-badge is-red">Permanent</span>
  if (unbanTime > now) {
    const r = unbanTime - now
    const h = Math.floor(r / 3600)
    const m = Math.floor((r % 3600) / 60)
    return <span className="acp-badge is-amber">{h}h {m}m left</span>
  }
  return <span className="acp-badge is-off">Expired</span>
}

export default async function BansPage({ searchParams }: PageProps<'/acp/bans'>) {
  await requireStaff(ADMIN_LVL.JUNIOR)

  const page = Math.max(1, Number(firstParam((await searchParams).page)) || 1)
  const now = Math.floor(serverNow() / 1000)

  const [bans, total] = await Promise.all([
    prisma.ban.findMany({ orderBy: { ban_time: 'desc' }, skip: (page - 1) * PER_PAGE, take: PER_PAGE }),
    prisma.ban.count(),
  ])
  const totalPages = Math.max(1, Math.ceil(total / PER_PAGE))

  return (
    <>
      <div className="acp-toolbar">
        <span className="acp-toolbar-spacer" />
        <Link href="/acp/bans/create" className="acp-btn acp-btn-primary">
          <i className="fa-solid fa-plus" /> Create Ban
        </Link>
      </div>

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Bans — {total.toLocaleString('en-GB')}</span></div>

        {bans.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-ban" />No bans on record.</div>
        ) : (
          <>
            <table className="acp-table">
              <thead>
                <tr>
                  <th style={{ width: 56 }}>ID</th>
                  <th>Account</th>
                  <th>IP</th>
                  <th>Admin</th>
                  <th>Reason</th>
                  <th>Banned</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {bans.map(b => (
                  <tr key={b.ban_id}>
                    <td className="acp-td-muted">{b.ban_id}</td>
                    <td>
                      {b.account_id
                        ? <Link href={`/acp/players/${b.account_id}`} className="acp-link">{b.account_name || `#${b.account_id}`}</Link>
                        : (b.account_name || '—')}
                    </td>
                    <td className="acp-mono acp-td-muted">{b.account_ip || '—'}</td>
                    <td className="acp-td-muted">{b.ban_admin || '—'}</td>
                    <td className="acp-td-detail" title={b.ban_reason}>{b.ban_reason || '—'}</td>
                    <td className="acp-td-muted">{formatUnixDateTime(b.ban_time)}</td>
                    <td>{banStatus(b.unban_time, now)}</td>
                    <td style={{ textAlign: 'right' }}><UnbanButton banId={b.ban_id} name={b.account_name || `#${b.account_id}`} /></td>
                  </tr>
                ))}
              </tbody>
            </table>

            <Pagination page={page} totalPages={totalPages} hrefFor={p => `/acp/bans?page=${p}`} />
          </>
        )}
      </section>
    </>
  )
}
