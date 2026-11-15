import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getFactionById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatDateTime } from '@/lib/format'

export const dynamic = 'force-dynamic'

export default async function FactionBank({ params }: PageProps<'/acp/factions/[id]/bank'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const id = Number((await params).id)
  const faction = await getFactionById(id)
  if (!faction) notFound()

  const logs = await prisma.factionLog.findMany({
    where: { faction_id: id },
    orderBy: { log_id: 'desc' },
    take: 100,
  })

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Bank — balance ${faction.faction_bank.toLocaleString('en-GB')} · last {logs.length} transactions</span></div>
      {logs.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-receipt" />No transactions recorded.</div>
      ) : (
        <table className="acp-table">
          <thead><tr><th>Date</th><th>Reason</th><th>Amount</th><th>Balance After</th></tr></thead>
          <tbody>
            {logs.map(l => (
              <tr key={l.log_id}>
                <td className="acp-td-muted">{formatDateTime(l.log_time)}</td>
                <td className="acp-td-detail" title={l.reason}>{l.reason || '—'}</td>
                <td style={{ color: l.action === 1 ? 'var(--acp-green)' : 'var(--acp-red)', fontWeight: 600 }}>
                  {l.action === 1 ? '+' : '-'}${l.amount.toLocaleString('en-GB')}
                </td>
                <td className="acp-td-muted">${l.balance_after.toLocaleString('en-GB')}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
