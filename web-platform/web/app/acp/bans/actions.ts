'use server'

import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction, sqlDateTime } from '@/lib/admin-log'

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''

async function agentAddBan(address: string, name: string, reason: string) {
  await fetch(`${AGENT_URL}/bans`, {
    method: 'POST',
    headers: { 'X-Agent-Key': AGENT_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ address, name, reason }),
    signal: AbortSignal.timeout(5000),
  }).catch(() => {})
}

async function agentRemoveBan(address: string) {
  await fetch(`${AGENT_URL}/bans?address=${encodeURIComponent(address)}`, {
    method: 'DELETE',
    headers: { 'X-Agent-Key': AGENT_KEY },
    signal: AbortSignal.timeout(5000),
  }).catch(() => {})
}

export async function unbanAction(banId: number): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.JUNIOR)
  const ban = await prisma.ban.findUnique({ where: { ban_id: banId } })
  if (!ban) return

  await prisma.ban.delete({ where: { ban_id: banId } })
  if (ban.account_ip) await agentRemoveBan(ban.account_ip)
  await logAdminAction(user, 'unban', 'account', ban.account_id, `Unbanned account ${ban.account_name}`)
  revalidatePath('/acp/bans')
}

export interface CreateBanState { error: string }

/** Offline-bans an account by name (bans row + admin_record type 2 + audit). */
export async function createBanAction(_prev: CreateBanState, formData: FormData): Promise<CreateBanState> {
  const user = await requireStaff(ADMIN_LVL.JUNIOR)

  const accountName = String(formData.get('account_name') ?? '').trim()
  const hours = Math.max(0, Math.min(720, Number(formData.get('hours')) || 0))
  const reason = String(formData.get('reason') ?? '').trim()

  if (!accountName || !reason) return { error: 'Account name and reason are required.' }
  if (reason.length > 64) return { error: 'Reason cannot exceed 64 characters.' }

  const account = await prisma.account.findUnique({ where: { account_name: accountName } })
  if (!account) return { error: `Account "${accountName}" not found.` }

  const existing = await prisma.ban.findFirst({
    where: { account_id: account.account_id, OR: [{ unban_time: 0 }, { unban_time: { gt: Math.floor(Date.now() / 1000) } }] },
  })
  if (existing) return { error: 'That account is already banned.' }

  const now = Math.floor(Date.now() / 1000)
  const unbanTime = hours === 0 ? 0 : now + hours * 3600

  await prisma.ban.create({
    data: {
      account_id: account.account_id,
      account_name: account.account_name,
      account_ip: account.account_lastip,
      ban_admin: user.name,
      ban_reason: reason,
      ban_time: now,
      unban_time: unbanTime,
    },
  })

  // admin_record type 2 = ban (Pawn parity)
  await prisma.adminRecord.create({
    data: {
      account_id: account.account_id,
      character_id: 0,
      record_type: 2,
      record_reason: reason,
      record_time: hours,
      record_admin: user.id,
      record_date: sqlDateTime(),
    },
  })

  if (account.account_lastip) await agentAddBan(account.account_lastip, account.account_name, reason)
  await logAdminAction(user, 'create', 'ban', account.account_id, `Offline banned ${account.account_name}`, reason)

  revalidatePath('/acp/bans')
  redirect('/acp/bans')
}
