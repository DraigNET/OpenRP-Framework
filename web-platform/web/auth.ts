import { activeBanWhere } from '@/lib/auth-policy'
import { checkEmailCode } from '@/lib/two-factor'
import NextAuth, { CredentialsSignin } from 'next-auth'
import Credentials from 'next-auth/providers/credentials'
import { prisma } from '@/lib/prisma'
import { verifyPassword } from '@/lib/password'
import { isRateLimited, logLoginAttempt, clientIpFromHeaders } from '@/lib/login-attempts'

class PasswordResetRequired extends CredentialsSignin { code = 'PasswordResetRequired' }
class TwoFactorUnavailable extends CredentialsSignin { code = 'TwoFactorUnavailable' }
class TwoFactorRequired extends CredentialsSignin { code = 'TwoFactorRequired' }
class TwoFactorInvalid extends CredentialsSignin { code = 'TwoFactorInvalid' }
class RateLimitError extends CredentialsSignin {
  code = 'RateLimited'
}

declare module 'next-auth' {
  interface Session {
    user: {
      id: number
      name?: string | null
      email?: string | null
      image?: string | null
      staffLevel: number
      passwordResetRequired: boolean
      twoFaEnabled: boolean
      passwordVersion: number
      twoFactorVerified: boolean
    }
  }
  interface User {
    id: string
    staffLevel: number
    passwordResetRequired: boolean
    twoFaEnabled: boolean
    passwordVersion: number
    twoFactorVerified: boolean
  }
}

export const { handlers, signIn, signOut, auth } = NextAuth({
  trustHost: true,

  // Auth.js logs failed logins (CredentialsSignin) and CSRF mismatches at error
  // level with a stack trace, which is just noise. Print a clean one-liner for the
  // expected cases and keep full logging for genuine errors.
  logger: {
    error(err: Error) {
      if (err instanceof CredentialsSignin) {
        console.log('[auth] login failed: invalid username or password')
        return
      }
      if (err.name === 'MissingCSRF') {
        console.log('[auth] request rejected: missing/expired CSRF token (stale tab)')
        return
      }
      console.error(`[auth] ${err.name}: ${err.message}`)
    },
  },

  providers: [
    Credentials({
      credentials: {
        username: { label: 'Username', type: 'text' },
        password: { label: 'Password', type: 'password' },
        code: { label: 'Email code', type: 'text' },
      },
      async authorize(credentials, request) {
        const username = (credentials?.username as string) ?? ''
        const password = (credentials?.password as string) ?? ''
        if (!username || !password) return null

        const ip = clientIpFromHeaders(request.headers)

        if (await isRateLimited(ip)) throw new RateLimitError()

        const account = await prisma.account.findFirst({
          where: { account_name: username },
        })

        if (!account) {
          await logLoginAttempt(username, ip, false)
          return null
        }

        const valid = await verifyPassword(password, account.account_password)
        if (!valid) {
          await logLoginAttempt(username, ip, false, account.account_id)
          return null
        }

        const now = Math.floor(Date.now() / 1000)
        const banned = await prisma.ban.findFirst({
          where: activeBanWhere(account.account_id, now),
        })
        if (banned) {
          await logLoginAttempt(username, ip, false, account.account_id)
          return null
        }

        if (account.password_reset_version === 0) throw new PasswordResetRequired()
        if (account.twofa_enabled === 1) {
          let result: 'ok' | 'required' | 'invalid'
          try { result = await checkEmailCode(account.account_id, account.account_email, String(credentials?.code ?? '')) }
          catch { throw new TwoFactorUnavailable() }
          if (result === 'required') throw new TwoFactorRequired()
          if (result !== 'ok') { await logLoginAttempt(username, ip, false, account.account_id); throw new TwoFactorInvalid() }
        }
        await logLoginAttempt(username, ip, true, account.account_id)

        return {
          id: String(account.account_id),
          name: account.account_name,
          email: account.account_email,
          staffLevel: account.account_stafflevel,
          passwordResetRequired: account.password_reset_version === 0,
          twoFaEnabled: account.twofa_enabled === 1,
          passwordVersion: account.password_reset_version,
          twoFactorVerified: account.twofa_enabled === 1,
        }
      },
    }),
  ],

  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
        token.staffLevel = user.staffLevel
        token.passwordResetRequired = user.passwordResetRequired
        token.twoFaEnabled = user.twoFaEnabled
        token.passwordVersion = user.passwordVersion
        token.twoFactorVerified = user.twoFactorVerified
      }
      const account = await prisma.account.findUnique({ where: { account_id: Number(token.id) }, select: { password_reset_version: true, twofa_enabled: true } })
      if (!account || account.password_reset_version === 0 || token.passwordVersion !== account.password_reset_version || (account.twofa_enabled === 1 && !token.twoFactorVerified)) return null
      if (await prisma.ban.findFirst({ where: activeBanWhere(Number(token.id)) })) return null
      return token
    },

    async session({ session, token }) {
      return {
        ...session,
        user: {
          ...session.user,
          id: Number(token.id),
          staffLevel: token.staffLevel as number,
          passwordResetRequired: token.passwordResetRequired as boolean,
          twoFaEnabled: token.twoFaEnabled as boolean,
          passwordVersion: token.passwordVersion as number,
          twoFactorVerified: token.twoFactorVerified as boolean,
        },
      }
    },
  },

  pages: {
    signIn: '/ucp/login',
    error: '/ucp/login',
  },

  session: { strategy: 'jwt' },
})
