import 'server-only'
import { createHmac, randomInt } from 'node:crypto'
import { prisma } from '@/lib/prisma'
import { env } from '@/lib/env'
import { sendLoginCode } from '@/lib/email'

const TTL = 300
const MAX_ATTEMPTS = 5

/** Bind the digest to its account; a database leak must not allow offline guessing without AUTH_SECRET. */
export function codeDigest(accountId: number, code: string): string {
  return createHmac('sha256', env.authSecret).update(accountId + ':' + code).digest('hex')
}

/** Send or consume an expiring email challenge. No session is created by this helper.
 * Conditional updates make codes single-use, limit attempts across IPs and avoid concurrent resends.
 */
export async function checkEmailCode(accountId: number, email: string, supplied: string): Promise<'ok' | 'required' | 'invalid'> {
  const now = Math.floor(Date.now() / 1000)
  if (!supplied) {
    if (!process.env.SMTP_HOST) throw new Error('Email delivery is not configured.')
    const code = String(randomInt(100000, 1000000))
    const digest = codeDigest(accountId, code)
    const issued = await prisma.account.updateMany({
      where: { account_id: accountId, OR: [{ twofa_last_sent: null }, { twofa_last_sent: { lte: now - 60 } }] },
      data: { twofa_code_hash: digest, twofa_expires: now + TTL, twofa_last_sent: now, twofa_attempts: 0 },
    })
    if (issued.count) {
      try { await sendLoginCode(email, code) }
      catch (error) {
        await prisma.account.updateMany({ where: { account_id: accountId, twofa_code_hash: digest }, data: { twofa_code_hash: null, twofa_expires: null, twofa_last_sent: null } })
        throw error
      }
    }
    return 'required'
  }
  if (!/^\d{6}$/.test(supplied)) return 'invalid'
  const claimed = await prisma.account.updateMany({
    where: { account_id: accountId, twofa_code_hash: codeDigest(accountId, supplied), twofa_expires: { gt: now }, twofa_attempts: { lt: MAX_ATTEMPTS } },
    data: { twofa_code_hash: null, twofa_expires: null, twofa_attempts: 0 },
  })
  if (claimed.count === 1) return 'ok'
  await prisma.account.updateMany({ where: { account_id: accountId, twofa_expires: { gt: now }, twofa_attempts: { lt: MAX_ATTEMPTS } }, data: { twofa_attempts: { increment: 1 } } })
  return 'invalid'
}
