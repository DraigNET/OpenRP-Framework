import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { prisma } from '@/lib/prisma'
import MaintenanceForm from './MaintenanceForm'

export const dynamic = 'force-dynamic'

const STATUS_CLASS: Record<string, string> = {
  pending: 'is-amber',
  done:    'is-green',
  error:   'is-red',
}

const fmt = (d: Date | null) => d ? d.toLocaleString('en-GB') : '—'

export default async function CommandsPage() {
  await requireStaff(ADMIN_LVL.LEAD)

  const history = await prisma.webCommand.findMany({
    orderBy: { id: 'desc' },
    take: 30,
    include: { account: { select: { account_name: true } } },
  })

  return (
    <>
      <MaintenanceForm />

      <div className="acp-panel">
        <div className="acp-panel-head"><span>Command History — last 30</span></div>
        {history.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-terminal" />No commands issued yet.</div>
        ) : (
          <table className="acp-table">
            <thead>
              <tr><th>ID</th><th>Command</th><th>Params</th><th>Status</th><th>Result</th><th>Issued By</th><th>Issued At</th><th>Processed At</th></tr>
            </thead>
            <tbody>
              {history.map(c => (
                <tr key={c.id}>
                  <td className="acp-td-muted">#{c.id}</td>
                  <td><code>{c.command}</code></td>
                  <td className="acp-td-muted">{c.params || '—'}</td>
                  <td><span className={`acp-badge ${STATUS_CLASS[c.status] ?? ''}`}>{c.status}</span></td>
                  <td className="acp-td-detail" title={c.result ?? ''}>{c.result ?? '—'}</td>
                  <td className="acp-td-muted">{c.account.account_name}</td>
                  <td className="acp-td-muted">{fmt(c.issued_at)}</td>
                  <td className="acp-td-muted">{fmt(c.processed_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  )
}
