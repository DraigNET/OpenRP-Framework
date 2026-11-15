import 'server-only'
import { prisma } from '@/lib/prisma'

export const MAX_FAILED_ATTEMPTS = 10
export const ATTEMPT_WINDOW_SECONDS = 3600 // 1 hour

/** Extracts the client IP from a request's forwarding headers. */
export function clientIpFromHeaders(headers: Headers): string {
  const fwd = headers.get('x-forwarded-for')
  if (fwd) return fwd.split(',')[0].trim()
  return headers.get('x-real-ip') ?? '0.0.0.0'
}

/**
 * Returns true if this IP has hit the failed-login limit within the window.
 * Mirrors the old PHP login.php throttle (10 failures / hour / IP).
 */
export async function isRateLimited(ip: string): Promise<boolean> {
  const since = Math.floor(Date.now() / 1000) - ATTEMPT_WINDOW_SECONDS
  const fails = await prisma.ucpLoginAttempt.count({
    where: { ip_address: ip, success: 0, created_at: { gt: since } },
  })
  return fails >= MAX_FAILED_ATTEMPTS
}

/** Records a login attempt (success or failure) for auditing + throttling. */
export async function logLoginAttempt(
  username: string,
  ip: string,
  success: boolean,
  accountId?: number
): Promise<void> {
  await prisma.ucpLoginAttempt.create({
    data: {
      account_id: accountId ?? null,
      account_name: username.slice(0, 191),
      ip_address: ip,
      success: success ? 1 : 0,
      created_at: Math.floor(Date.now() / 1000),
    },
  }).catch(() => {
    // Never let attempt logging block a login flow
  })
}
