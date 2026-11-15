import { NextRequest, NextResponse } from 'next/server'
import { activeBanWhere } from '@/lib/auth-policy'
import { encode } from 'next-auth/jwt'
import { prisma } from '@/lib/prisma'
import { env } from '@/lib/env'
import { exchangeDiscordCode, fetchDiscordUser, isInGuild } from '@/lib/discord-oauth'
import { isRateLimited, logLoginAttempt, clientIpFromHeaders } from '@/lib/login-attempts'

const isProd = process.env.NODE_ENV === 'production'
const SESSION_MAX_AGE = 30 * 24 * 60 * 60 // 30 days
const COOKIE_NAME = isProd ? '__Secure-authjs.session-token' : 'authjs.session-token'

function redirect(path: string) {
  return NextResponse.redirect(`${env.siteUrl}${path}`)
}

export async function GET(req: NextRequest) {
  if (!env.discordEnabled) return NextResponse.json({ error: 'Discord integration is disabled.' }, { status: 404 })
  const { searchParams } = new URL(req.url)
  const code = searchParams.get('code')
  const state = searchParams.get('state')
  const storedState = req.cookies.get('discord_login_state')?.value

  // Clear state cookie immediately
  const clearState = (res: NextResponse) => {
    res.cookies.delete('discord_login_state')
    return res
  }

  if (!code) return clearState(redirect('/ucp/login?error=DiscordError'))
  if (!state || !storedState || state !== storedState)
    return clearState(redirect('/ucp/login?error=DiscordError'))

  const redirectUri = `${env.siteUrl}/api/discord-login/callback`

  const accessToken = await exchangeDiscordCode(code, redirectUri)
  if (!accessToken) return clearState(redirect('/ucp/login?error=DiscordError'))

  const discordUser = await fetchDiscordUser(accessToken)
  if (!discordUser) return clearState(redirect('/ucp/login?error=DiscordError'))

  const inGuild = await isInGuild(discordUser.id)
  if (!inGuild) return clearState(redirect('/ucp/login?error=NotInGuild'))

  const account = await prisma.account.findFirst({
    where: { discord_id: BigInt(discordUser.id), discord_verified: 1 },
  })
  if (!account) return clearState(redirect('/ucp/login?error=NoLinkedAccount'))

  const ip = clientIpFromHeaders(req.headers)

  if (await isRateLimited(ip)) return clearState(redirect('/ucp/login?error=RateLimited'))

  const now = Math.floor(Date.now() / 1000)
  const banned = await prisma.ban.findFirst({
    where: activeBanWhere(account.account_id, now),
  })
  if (banned) {
    await logLoginAttempt(account.account_name, ip, false, account.account_id)
    return clearState(redirect('/ucp/banned'))
  }

  // OAuth must not bypass the account's email second factor or mandatory password reset.
  if (account.twofa_enabled || account.password_reset_version === 0) return clearState(redirect('/ucp/login?error=UsePassword2FA'))
  await logLoginAttempt(account.account_name, ip, true, account.account_id)

  // Build the same JWT payload our jwt() callback would produce
  const token = await encode({
    token: {
      name: account.account_name,
      email: account.account_email,
      sub: String(account.account_id),
      id: String(account.account_id),
      staffLevel: account.account_stafflevel,
      passwordResetRequired: account.password_reset_version === 0,
      twoFaEnabled: account.twofa_enabled === 1,
      passwordVersion: account.password_reset_version,
      twoFactorVerified: false,
    },
    secret: env.authSecret,
    maxAge: SESSION_MAX_AGE,
    salt: COOKIE_NAME,
  })

  const res = redirect('/ucp')
  clearState(res)
  res.cookies.set(COOKIE_NAME, token, {
    httpOnly: true,
    secure: isProd,
    sameSite: 'lax',
    maxAge: SESSION_MAX_AGE,
    path: '/',
  })
  return res
}
