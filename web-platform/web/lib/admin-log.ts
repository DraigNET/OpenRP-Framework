import 'server-only'
import { headers } from 'next/headers'
import { prisma } from './prisma'
import type { SessionUser } from './dal'

/**
 * Writes an entry to admin_action_logs — the ACP audit trail. Every mutation
 * (ban, unban, penalise, transfer, etc.) must call this so staff actions are
 * accountable, mirroring the old site's log_admin_action(). Failure to log must
 * never break the action itself, so errors are swallowed (and console'd).
 *
 * admin_action_logs is not a Prisma model (raw INSERT); created_at is unix secs.
 */
export async function logAdminAction(
  user: SessionUser,
  actionType: string,
  targetType: string,
  targetId: string | number,
  description: string,
  reason: string | null = null,
): Promise<void> {
  try {
    const h = await headers()
    const ip = (h.get('x-forwarded-for')?.split(',')[0] ?? h.get('x-real-ip') ?? '').trim()
    const ua = h.get('user-agent') ?? ''
    const now = Math.floor(Date.now() / 1000)
    await prisma.$executeRaw`
      INSERT INTO admin_action_logs
        (account_id, account_name, staff_level, action_type, target_type, target_id,
         description, reason, ip_address, user_agent, created_at)
      VALUES
        (${user.id}, ${user.name}, ${user.staffLevel}, ${actionType}, ${targetType}, ${String(targetId)},
         ${description}, ${reason}, ${ip}, ${ua}, ${now})`
  } catch (e) {
    console.error('logAdminAction failed:', e)
  }
}

/** Server-local "Y-m-d H:i:s" string, matching the gamemode's admin_record format. */
export function sqlDateTime(d = new Date()): string {
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
}
