import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getAccountById, serverNow, isStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDateTime } from '@/lib/format'
import PenaltyFlagsForm from './PenaltyFlagsForm'
import OfflineJailForm from './OfflineJailForm'
import { PENALTY_FLAGS } from './flags'

export const dynamic = 'force-dynamic'

export default async function PlayerPenalties({ params }: PageProps<'/acp/players/[id]/penalties'>) {
  await requireStaff(ADMIN_LVL.JUNIOR)
  const id = Number((await params).id)
  const account = await getAccountById(id)
  if (!account) notFound()

  const now = Math.floor(serverNow() / 1000)
  const [ban, jailed, canManage] = await Promise.all([
    prisma.ban.findFirst({
      where: { account_id: id, OR: [{ unban_time: 0 }, { unban_time: { gt: now } }] },
      orderBy: { ban_time: 'desc' },
    }),
    prisma.character.findMany({
      where: { account_id: id, player_ajail_time: { gt: 0 } },
      select: { player_id: true, player_name: true, player_ajail_time: true },
    }),
    isStaff(ADMIN_LVL.GENERAL),
  ])
  const allChars = await prisma.character.findMany({ where: { account_id: id }, select: { player_id: true, player_name: true }, orderBy: { player_name: 'asc' } })

  const none = !ban && jailed.length === 0
  const flagValues = Object.fromEntries(PENALTY_FLAGS.map(f => [f.key, account[f.key] ?? 0]))

  return (
    <>
      <section className="acp-panel" style={{ marginBottom: 14 }}>
        <div className="acp-panel-head"><span>Active Penalties</span></div>
        {none ? (
          <div className="acp-empty"><i className="fa-solid fa-circle-check" />No active bans or jails.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th>Type</th><th>Subject</th><th>Detail</th><th>Status</th></tr></thead>
            <tbody>
              {ban && (
                <tr>
                  <td><span className="acp-badge is-red">Ban</span></td>
                  <td>Account</td>
                  <td className="acp-td-detail" title={ban.ban_reason}>{ban.ban_reason || '—'} <span className="acp-td-muted">· by {ban.ban_admin || 'Unknown'}</span></td>
                  <td className="acp-td-muted">{ban.unban_time === 0 ? 'Permanent' : `Until ${formatUnixDateTime(ban.unban_time)}`}</td>
                </tr>
              )}
              {jailed.map(c => (
                <tr key={c.player_id}>
                  <td><span className="acp-badge is-amber">Admin Jail</span></td>
                  <td>{c.player_name.replace(/_/g, ' ')}</td>
                  <td className="acp-td-muted">Character currently jailed</td>
                  <td className="acp-td-muted">{Math.round(c.player_ajail_time / 60)} min remaining</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {canManage && (
        <section className="acp-panel" style={{ marginBottom: 14 }}>
          <div className="acp-panel-head"><span>Penalty Flags</span></div>
          <div style={{ padding: 16 }}>
            <PenaltyFlagsForm accountId={id} values={flagValues} />
          </div>
        </section>
      )}

      {account.account_online !== 1 && allChars.length > 0 && (
        <section className="acp-panel">
          <div className="acp-panel-head"><span>Offline Admin Jail</span></div>
          <div style={{ padding: 16 }}>
            <OfflineJailForm accountId={id} characters={allChars.map(c => ({ id: c.player_id, name: c.player_name }))} />
          </div>
        </section>
      )}
    </>
  )
}
