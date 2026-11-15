'use server'

import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL, MAX_CHARACTERS_PER_ACCOUNT } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'

export interface SettingsState { error: string; ok: boolean }
export interface ManageState { error: string; ok: boolean; message: string }

const int = (fd: FormData, k: string) => Math.trunc(Number(fd.get(k)) || 0)
const chk = (fd: FormData, k: string) => (fd.get(k) ? 1 : 0)

export async function updateAccountSettings(_prev: SettingsState, formData: FormData): Promise<SettingsState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const accountId = Number(formData.get('account_id'))
  const account = await prisma.account.findUnique({ where: { account_id: accountId } })
  if (!account) return { error: 'Account not found.', ok: false }

  const email = String(formData.get('account_email') ?? '').trim()
  const discordName = String(formData.get('account_discordname') ?? '').trim()
  const discordIdRaw = String(formData.get('discord_id') ?? '').trim()
  const discordId = discordIdRaw ? BigInt(discordIdRaw) : null

  await prisma.account.update({
    where: { account_id: accountId },
    data: {
      account_email: email,
      account_email_verified: chk(formData, 'account_email_verified'),
      account_stafflevel: int(formData, 'account_stafflevel'),
      account_premiumlevel: int(formData, 'account_premiumlevel'),
      account_factionteam: int(formData, 'account_factionteam'),
      account_quiz_passed: chk(formData, 'account_quiz_passed'),
      twofa_enabled: chk(formData, 'twofa_enabled'),
      discord_verified: chk(formData, 'discord_verified'),
      account_discordname: discordName || 'Undefined',
      discord_id: discordId,
    },
  })
  // account_supporter isn't on the Prisma model — update it directly.
  await prisma.$executeRaw`UPDATE accounts SET account_supporter = ${int(formData, 'account_supporter')} WHERE account_id = ${accountId}`

  await logAdminAction(user, 'account_settings', 'account', accountId, `Edited account settings for ${account.account_name}`)
  revalidatePath(`/acp/players/${accountId}/settings`)
  return { error: '', ok: true }
}

/** Transfer a character to another account (offline only, target under the cap). */
export async function transferCharacter(_prev: ManageState, formData: FormData): Promise<ManageState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const sourceId = Number(formData.get('account_id'))
  const characterId = Number(formData.get('character_id'))
  const target = String(formData.get('target_account') ?? '').trim()
  const reason = String(formData.get('reason') ?? '').trim()
  if (!characterId || !target) return { error: 'Choose a character and target account.', ok: false, message: '' }

  const targetAccount = /^\d+$/.test(target)
    ? await prisma.account.findUnique({ where: { account_id: Number(target) } })
    : await prisma.account.findUnique({ where: { account_name: target } })
  const character = await prisma.character.findFirst({ where: { player_id: characterId, account_id: sourceId } })

  if (!targetAccount) return { error: 'Target account not found.', ok: false, message: '' }
  if (!character) return { error: 'Character not found on this account.', ok: false, message: '' }
  if (targetAccount.account_id === sourceId) return { error: 'The character is already on that account.', ok: false, message: '' }
  if (character.player_online === 1) return { error: 'That character is online — transfer after they disconnect.', ok: false, message: '' }
  const targetCount = await prisma.character.count({ where: { account_id: targetAccount.account_id } })
  if (targetCount >= MAX_CHARACTERS_PER_ACCOUNT) return { error: `Target account already has ${MAX_CHARACTERS_PER_ACCOUNT} characters.`, ok: false, message: '' }

  await prisma.character.update({ where: { player_id: characterId }, data: { account_id: targetAccount.account_id } })
  await logAdminAction(user, 'transfer', 'character', characterId,
    `Transferred ${character.player_name} to ${targetAccount.account_name}`, reason || null)
  revalidatePath(`/acp/players/${sourceId}/settings`)
  return { error: '', ok: true, message: `${character.player_name.replace(/_/g, ' ')} transferred to ${targetAccount.account_name}.` }
}

/** Ban the linked Discord account from the guild via the bot. */
export async function discordBanAction(accountId: number): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const account = await prisma.account.findUnique({ where: { account_id: accountId }, select: { account_name: true, discord_id: true } })
  if (!account?.discord_id) return
  const guild = process.env.DISCORD_GUILD_ID
  const token = process.env.DISCORD_BOT_TOKEN
  if (!guild || !token) return
  try {
    const res = await fetch(`https://discord.com/api/guilds/${guild}/bans/${account.discord_id}`, {
      method: 'PUT',
      headers: { Authorization: `Bot ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ delete_message_seconds: 0 }),
    })
    if (res.ok) await logAdminAction(user, 'discord_ban', 'account', accountId, `Discord-banned ${account.account_name} (${account.discord_id})`)
  } catch { /* network failure must not throw */ }
  revalidatePath(`/acp/players/${accountId}/settings`)
}

/** Permanently delete an account and all its characters + related rows. */
export async function deleteAccount(_prev: ManageState, formData: FormData): Promise<ManageState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const accountId = Number(formData.get('account_id'))
  const confirmName = String(formData.get('confirm_account_name') ?? '').trim()
  const reason = String(formData.get('reason') ?? '').trim()

  const account = await prisma.account.findUnique({ where: { account_id: accountId } })
  if (!account) return { error: 'Account not found.', ok: false, message: '' }
  if (accountId === user.id) return { error: 'You cannot delete your own account.', ok: false, message: '' }
  if (account.account_online === 1) return { error: 'Account is online — delete after they disconnect.', ok: false, message: '' }
  if (confirmName !== account.account_name) return { error: 'Type the exact account username to confirm.', ok: false, message: '' }

  const chars = await prisma.character.findMany({ where: { account_id: accountId }, select: { player_id: true } })
  const charIds = chars.map(c => c.player_id)

  await prisma.$transaction([
    prisma.accountIpHistory.deleteMany({ where: { account_id: accountId } }),
    prisma.rulesQuizAttempt.deleteMany({ where: { account_id: accountId } }),
    prisma.ban.deleteMany({ where: { account_id: accountId } }),
    prisma.adminRecord.deleteMany({ where: { account_id: accountId } }),
    ...(charIds.length ? [
      prisma.adminRecord.deleteMany({ where: { character_id: { in: charIds } } }),
      prisma.playerWeapon.deleteMany({ where: { character_id: { in: charIds } } }),
      prisma.vehicle.deleteMany({ where: { vehicle_type: 3, vehicle_owner: { in: charIds } } }),
    ] : []),
    prisma.character.deleteMany({ where: { account_id: accountId } }),
    prisma.account.delete({ where: { account_id: accountId } }),
  ])

  await logAdminAction(user, 'delete', 'account', accountId, `Deleted account ${account.account_name} and ${charIds.length} character(s)`, reason || null)
  redirect('/acp/players')
}
