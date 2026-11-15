'use server'

import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction, sqlDateTime } from '@/lib/admin-log'
import { PENALTY_FLAGS, type PenaltyFlagKey, type PenaltyState, type OjailState } from './flags'

export async function updatePenaltiesAction(_prev: PenaltyState, formData: FormData): Promise<PenaltyState> {
  const user = await requireStaff(ADMIN_LVL.GENERAL)
  const accountId = Number(formData.get('account_id'))
  if (!Number.isInteger(accountId) || accountId <= 0) return { ok: false, error: 'Invalid account.' }

  const account = await prisma.account.findUnique({ where: { account_id: accountId } })
  if (!account) return { ok: false, error: 'Account not found.' }

  const data: Record<PenaltyFlagKey, number> = {} as Record<PenaltyFlagKey, number>
  const changed: string[] = []
  for (const { key, label } of PENALTY_FLAGS) {
    const next = formData.get(key) === 'on' ? 1 : 0
    data[key] = next
    if ((account[key] ?? 0) !== next) changed.push(`${label} ${next ? 'on' : 'off'}`)
  }

  await prisma.account.update({ where: { account_id: accountId }, data })

  if (changed.length > 0) {
    await logAdminAction(user, 'penalise', 'account', accountId, `Updated penalties for ${account.account_name}: ${changed.join(', ')}`)
  }

  revalidatePath(`/acp/players/${accountId}/penalties`)
  return { ok: true, error: '' }
}

/** Offline admin-jail a character on an offline account (mirrors offline_ajail.php). */
export async function offlineJailAction(_prev: OjailState, formData: FormData): Promise<OjailState> {
  const user = await requireStaff(ADMIN_LVL.JUNIOR)
  const accountId = Number(formData.get('account_id'))
  const characterId = Number(formData.get('character_id'))
  const minutes = Math.trunc(Number(formData.get('time')) || 0)
  const reason = String(formData.get('reason') ?? '').trim()

  if (!accountId || !characterId) return { ok: false, error: 'Invalid account or character.', message: '' }
  if (minutes < 10) return { ok: false, error: 'Jail time must be at least 10 minutes.', message: '' }
  if (!reason) return { ok: false, error: 'A reason is required.', message: '' }
  if (reason.length > 64) return { ok: false, error: 'Reason cannot exceed 64 characters.', message: '' }

  const [account, character] = await Promise.all([
    prisma.account.findUnique({ where: { account_id: accountId }, select: { account_online: true } }),
    prisma.character.findFirst({ where: { player_id: characterId, account_id: accountId }, select: { player_name: true } }),
  ])
  if (!account || !character) return { ok: false, error: 'Character not found on this account.', message: '' }
  if (account.account_online === 1) return { ok: false, error: 'This player is online. Use /ajail in-game instead.', message: '' }

  const seconds = minutes * 60
  await prisma.$executeRaw`
    UPDATE characters SET player_oajail_reason = ${reason}, player_oajail_admin = ${user.name}, player_ajail_time = ${seconds}
    WHERE player_id = ${characterId} AND account_id = ${accountId}`
  await prisma.adminRecord.create({
    data: { account_id: accountId, character_id: characterId, record_type: 1, record_reason: reason, record_time: seconds, record_admin: user.id, record_date: sqlDateTime() },
  })
  await logAdminAction(user, 'offline_ajail', 'account', accountId, `Offline admin-jailed ${character.player_name} for ${minutes} min`, reason)
  revalidatePath(`/acp/players/${accountId}/penalties`)
  return { ok: true, error: '', message: `${character.player_name.replace(/_/g, ' ')} offline-jailed for ${minutes} minutes.` }
}
