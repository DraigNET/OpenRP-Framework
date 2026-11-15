import { prisma } from '@/lib/prisma'
import { activeBanWhere } from '@/lib/auth-policy'
import 'server-only'
import { SignJWT, jwtVerify } from 'jose'
import { env } from './env'

// Stateless auth for ORP Dispatch. Two short signed tokens, both keyed on the
// UCP account id:
//   - auth-code:     issued by /ucp/voice/authorize, lives ~2 min, single hop to
//                    the desktop app via the orp-dispatch:// deep link.
//   - voice-session: issued by /api/voice/session in exchange for a valid code,
//                    lives 30 days, sent as a Bearer token by the app.

const secret = () => new TextEncoder().encode(env.authSecret)

type Scope = 'voice-auth' | 'voice-session'

async function mint(accountId: number, scope: Scope, ttl: string): Promise<string> {
  const account = await prisma.account.findUnique({ where: { account_id: accountId }, select: { password_reset_version: true } })
  if (!account || account.password_reset_version === 0) throw new Error('Account unavailable')
  return new SignJWT({ scope, passwordVersion: account.password_reset_version })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(String(accountId))
    .setIssuedAt()
    .setExpirationTime(ttl)
    .sign(secret())
}

export const mintAuthCode = (accountId: number) => mint(accountId, 'voice-auth', '2m')
export const mintVoiceSession = (accountId: number) => mint(accountId, 'voice-session', '30d')

/** Verifies a token of the given scope; returns the account id or null. */
export async function verifyVoiceToken(token: string, scope: Scope): Promise<number | null> {
  try {
    const { payload } = await jwtVerify(token, secret(), { algorithms: ['HS256'] })
    if (payload.scope !== scope) return null
    const id = Number(payload.sub)
    if (!Number.isSafeInteger(id) || id <= 0) return null
    const account = await prisma.account.findUnique({ where: { account_id: id }, select: { password_reset_version: true } })
    if (!account || account.password_reset_version === 0 || payload.passwordVersion !== account.password_reset_version) return null
    if (await prisma.ban.findFirst({ where: activeBanWhere(id) })) return null
    return id
  } catch {
    return null
  }
}

/** Extracts a Bearer token from the Authorization header, or null. */
export function bearer(req: Request): string | null {
  const h = req.headers.get('authorization') ?? ''
  return h.startsWith('Bearer ') ? h.slice(7) : null
}
