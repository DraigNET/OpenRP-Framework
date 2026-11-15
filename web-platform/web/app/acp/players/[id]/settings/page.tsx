import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getAccountById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import SettingsForm from './SettingsForm'
import { TransferForm, DiscordBanButton, DeleteAccountForm } from './ManageClient'

export const dynamic = 'force-dynamic'

export default async function PlayerSettings({ params }: PageProps<'/acp/players/[id]/settings'>) {
  await requireStaff(ADMIN_LVL.MANAGER)
  const id = Number((await params).id)
  const account = await getAccountById(id)
  if (!account) notFound()

  const [supRows, characters] = await Promise.all([
    prisma.$queryRaw<Array<{ s: number }>>`SELECT account_supporter AS s FROM accounts WHERE account_id = ${id}`,
    prisma.character.findMany({ where: { account_id: id }, select: { player_id: true, player_name: true }, orderBy: { player_name: 'asc' } }),
  ])
  const supporter = Number(supRows[0]?.s ?? 0)
  const charOpts = characters.map(c => ({ id: c.player_id, name: c.player_name }))

  return (
    <>
      <section className="acp-panel" style={{ marginBottom: 14 }}>
        <div className="acp-panel-head"><span>Account Settings</span></div>
        <div style={{ padding: 16 }}>
          <SettingsForm v={{
            account_id: id,
            account_email: account.account_email,
            account_email_verified: account.account_email_verified,
            account_stafflevel: account.account_stafflevel,
            account_supporter: supporter,
            account_premiumlevel: account.account_premiumlevel,
            account_factionteam: account.account_factionteam,
            account_quiz_passed: account.account_quiz_passed,
            twofa_enabled: account.twofa_enabled,
            discord_verified: account.discord_verified,
            account_discordname: account.account_discordname,
            discord_id: account.discord_id != null ? String(account.discord_id) : null,
          }} />
        </div>
      </section>

      <section className="acp-panel" style={{ marginBottom: 14 }}>
        <div className="acp-panel-head"><span>Transfer Character</span></div>
        <div style={{ padding: 16 }}><TransferForm accountId={id} characters={charOpts} /></div>
      </section>

      {account.discord_id != null && (
        <section className="acp-panel" style={{ marginBottom: 14 }}>
          <div className="acp-panel-head"><span>Discord</span></div>
          <div style={{ padding: 16 }}>
            <DiscordBanButton accountId={id} />
          </div>
        </section>
      )}

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Delete Account</span></div>
        <div style={{ padding: 16 }}><DeleteAccountForm accountId={id} accountName={account.account_name} /></div>
      </section>
    </>
  )
}
