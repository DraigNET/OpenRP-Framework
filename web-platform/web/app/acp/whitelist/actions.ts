'use server'

import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'

export interface WlState { error: string; ok: boolean }

const nowUnix = () => Math.floor(Date.now() / 1000)
const expiry = (days: number) => (days <= 0 ? 0 : nowUnix() + days * 86400)

export async function addIpWhitelist(_prev: WlState, formData: FormData): Promise<WlState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const ip = String(formData.get('ip') ?? '').trim()
  const reason = String(formData.get('reason') ?? '').trim() || null
  const days = Math.max(0, Number(formData.get('days')) || 0)

  if (!ip) return { error: 'IP address is required.', ok: false }
  if (!/^[0-9a-fA-F.:]{3,45}$/.test(ip)) return { error: 'That doesn’t look like a valid IP address.', ok: false }
  if (await prisma.multiaccountIpWhitelist.findUnique({ where: { ip_address: ip } })) {
    return { error: 'That IP is already whitelisted.', ok: false }
  }

  await prisma.multiaccountIpWhitelist.create({
    data: { ip_address: ip, reason, created_by: user.id, created_at: nowUnix(), expires_at: expiry(days) },
  })
  await logAdminAction(user, 'whitelist_add', 'ip', ip, `Whitelisted IP ${ip}`, reason)
  revalidatePath('/acp/whitelist')
  return { error: '', ok: true }
}

export async function addAccountWhitelist(_prev: WlState, formData: FormData): Promise<WlState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const raw = String(formData.get('account') ?? '').trim()
  const reason = String(formData.get('reason') ?? '').trim() || null
  const days = Math.max(0, Number(formData.get('days')) || 0)

  if (!raw) return { error: 'Account name or ID is required.', ok: false }
  const account = /^\d+$/.test(raw)
    ? await prisma.account.findUnique({ where: { account_id: Number(raw) } })
    : await prisma.account.findUnique({ where: { account_name: raw } })
  if (!account) return { error: `Account "${raw}" not found.`, ok: false }
  if (await prisma.multiaccountAccountWhitelist.findUnique({ where: { account_id: account.account_id } })) {
    return { error: 'That account is already whitelisted.', ok: false }
  }

  await prisma.multiaccountAccountWhitelist.create({
    data: { account_id: account.account_id, reason, created_by: user.id, created_at: nowUnix(), expires_at: expiry(days) },
  })
  await logAdminAction(user, 'whitelist_add', 'account', account.account_id, `Whitelisted account ${account.account_name}`, reason)
  revalidatePath('/acp/whitelist')
  return { error: '', ok: true }
}

export async function removeWhitelist(kind: 'ip' | 'account', id: number): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  if (kind === 'ip') {
    const row = await prisma.multiaccountIpWhitelist.findUnique({ where: { whitelist_id: id } })
    if (!row) return
    await prisma.multiaccountIpWhitelist.delete({ where: { whitelist_id: id } })
    await logAdminAction(user, 'whitelist_remove', 'ip', row.ip_address, `Removed IP whitelist ${row.ip_address}`)
  } else {
    const row = await prisma.multiaccountAccountWhitelist.findUnique({ where: { whitelist_id: id } })
    if (!row) return
    await prisma.multiaccountAccountWhitelist.delete({ where: { whitelist_id: id } })
    await logAdminAction(user, 'whitelist_remove', 'account', row.account_id, `Removed account whitelist #${row.account_id}`)
  }
  revalidatePath('/acp/whitelist')
}
