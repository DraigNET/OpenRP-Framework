'use server'

import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'

export interface VpnWlState { error: string; ok: boolean }

const nowUnix = () => Math.floor(Date.now() / 1000)

export async function addVpnWhitelist(_prev: VpnWlState, formData: FormData): Promise<VpnWlState> {
  const user = await requireStaff(ADMIN_LVL.GENERAL)
  const raw = String(formData.get('account') ?? '').trim()
  const reason = String(formData.get('reason') ?? '').trim() || null

  if (!raw) return { error: 'Account name or ID is required.', ok: false }

  // Resolve whatever was typed to an account_id. We store only the ID, never the name,
  // so a later rename can't orphan the entry.
  const account = /^\d+$/.test(raw)
    ? await prisma.account.findUnique({ where: { account_id: Number(raw) } })
    : await prisma.account.findUnique({ where: { account_name: raw } })

  if (!account) return { error: `Account "${raw}" not found.`, ok: false }

  if (await prisma.vpnWhitelist.findUnique({ where: { account_id: account.account_id } })) {
    return { error: `${account.account_name} is already VPN-whitelisted.`, ok: false }
  }

  await prisma.vpnWhitelist.create({
    data: { account_id: account.account_id, reason, created_by: user.id, created_at: nowUnix() },
  })

  await logAdminAction(
    user, 'vpn_whitelist_add', 'account', account.account_id,
    `VPN-whitelisted ${account.account_name}`, reason,
  )

  revalidatePath('/acp/vpn-whitelist')
  return { error: '', ok: true }
}

export async function removeVpnWhitelist(id: number): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.GENERAL)

  const row = await prisma.vpnWhitelist.findUnique({ where: { whitelist_id: id } })
  if (!row) return

  await prisma.vpnWhitelist.delete({ where: { whitelist_id: id } })

  await logAdminAction(
    user, 'vpn_whitelist_remove', 'account', row.account_id,
    `Removed VPN whitelist for account #${row.account_id}`,
  )

  revalidatePath('/acp/vpn-whitelist')
}
