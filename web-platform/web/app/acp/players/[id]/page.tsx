import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getAccountById, serverNow } from '@/lib/dal'
import { ADMIN_LVL, staffLevelTitle } from '@/lib/constants'
import { formatUnixDate, formatUnixDateTime, formatDateTime } from '@/lib/format'

export const dynamic = 'force-dynamic'

export default async function PlayerOverview({ params }: PageProps<'/acp/players/[id]'>) {
  await requireStaff(ADMIN_LVL.JUNIOR)
  const id = Number((await params).id)
  const account = await getAccountById(id)
  if (!account) notFound()

  const now = Math.floor(serverNow() / 1000)
  const ban = await prisma.ban.findFirst({
    where: { account_id: id, OR: [{ unban_time: 0 }, { unban_time: { gt: now } }] },
    orderBy: { ban_time: 'desc' },
  })

  const yes = <span className="acp-badge is-green">Yes</span>
  const no = <span className="acp-badge is-off">No</span>

  return (
    <>
      {ban && (
        <div className="acp-alert acp-alert-danger">
          <strong>Account is banned.</strong> {ban.ban_reason || 'No reason'} — by {ban.ban_admin || 'Unknown'}.{' '}
          {ban.unban_time === 0 ? 'Permanent.' : `Until ${formatUnixDateTime(ban.unban_time)}.`}
        </div>
      )}

      <div className="acp-grid-2">
        <section className="acp-panel">
          <div className="acp-panel-head"><span>Account</span></div>
          <div className="acp-kv">
            <div className="acp-kv-row"><span>Account ID</span><b>{account.account_id}</b></div>
            <div className="acp-kv-row"><span>Username</span><b>{account.account_name}</b></div>
            <div className="acp-kv-row"><span>Email</span><b>{account.account_email || 'Not set'}</b></div>
            <div className="acp-kv-row"><span>Email Verified</span><b>{account.account_email_verified === 1 ? yes : no}</b></div>
            <div className="acp-kv-row"><span>Staff Rank</span><b>{staffLevelTitle(account.account_stafflevel)}</b></div>
            <div className="acp-kv-row"><span>Premium Level</span><b>{account.account_premiumlevel}</b></div>
            <div className="acp-kv-row"><span>Registered</span><b>{formatUnixDate(account.account_register_date)}</b></div>
          </div>
        </section>

        <section className="acp-panel">
          <div className="acp-panel-head"><span>Connection &amp; Security</span></div>
          <div className="acp-kv">
            <div className="acp-kv-row"><span>Status</span><b>{account.account_online === 1
              ? <span className="acp-badge is-green">Online</span>
              : <span className="acp-badge is-off">Offline</span>}</b></div>
            <div className="acp-kv-row"><span>Last Login</span><b>{formatDateTime(account.account_lastlogin)}</b></div>
            <div className="acp-kv-row"><span>Last IP</span><b className="acp-mono">{account.account_lastip || 'Unknown'}</b></div>
            <div className="acp-kv-row"><span>Discord</span><b>{account.account_discordname && account.account_discordname !== 'Undefined' ? account.account_discordname : 'Not linked'}</b></div>
            <div className="acp-kv-row"><span>Discord ID</span><b className="acp-mono">{account.discord_id ? String(account.discord_id) : '—'}</b></div>
            <div className="acp-kv-row"><span>Email 2FA</span><b>{account.twofa_enabled === 1 ? yes : no}</b></div>
            <div className="acp-kv-row"><span>Rules Quiz</span><b>{account.account_quiz_passed === 1 ? yes : no}</b></div>
          </div>
        </section>
      </div>
    </>
  )
}
