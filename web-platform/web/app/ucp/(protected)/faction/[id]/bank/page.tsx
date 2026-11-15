import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { requireFactionCharacter } from '@/lib/dal'
import { COLOR } from '@/lib/colors'

export default async function FactionBankPage({ params }: PageProps<'/ucp/faction/[id]/bank'>) {
  const { id } = await params
  const char = await requireFactionCharacter(Number(id))

  const [faction, logs] = await Promise.all([
    prisma.faction.findUnique({ where: { faction_id: char.player_factionid } }),
    prisma.factionLog.findMany({
      where: { faction_id: char.player_factionid },
      orderBy: { log_id: 'desc' },
      take: 50,
    }),
  ])
  if (!faction) notFound()

  return (
    <div className="ucp-card">
      <h3>Faction Bank</h3>

      <p style={{ fontSize: 18, fontWeight: 600 }}>
        Balance: ${faction.faction_bank.toLocaleString()}
      </p>

      <div style={{ marginTop: 20 }}>
        <h4 style={{ marginBottom: 10 }}>Recent Transactions</h4>

        {logs.length === 0 ? (
          <div className="ucp-muted">No transactions found.</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {logs.map(log => (
              <div key={log.log_id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--bg-input)', padding: 12, borderRadius: 10 }}>
                <div>
                  <div style={{ fontWeight: 600 }}>{log.reason || '—'}</div>
                  <div style={{ color: 'var(--text-2)', fontSize: 12 }}>
                    {log.log_time.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontWeight: 600, fontSize: 15, color: log.action === 1 ? COLOR.success : COLOR.danger }}>
                    {log.action === 1 ? '+' : '-'}${log.amount.toLocaleString()}
                  </div>
                  <div style={{ color: 'var(--text-2)', fontSize: 12 }}>
                    Balance: ${log.balance_after.toLocaleString()}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
