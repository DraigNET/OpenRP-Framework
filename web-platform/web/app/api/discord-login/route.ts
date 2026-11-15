import { NextResponse } from 'next/server'
import { auth } from '@/auth'
import { randomBytes } from 'crypto'
import { env } from '@/lib/env'

export async function GET() {
  if (!env.discordEnabled) return NextResponse.json({ error: 'Discord integration is disabled.' }, { status: 404 })
  const session = await auth()
  if (session) return NextResponse.redirect(`${env.siteUrl}/ucp`)

  const state = randomBytes(16).toString('hex')
  const redirectUri = `${env.siteUrl}/api/discord-login/callback`

  const params = new URLSearchParams({
    client_id: env.discordClientId,
    redirect_uri: redirectUri,
    response_type: 'code',
    scope: 'identify',
    state,
  })

  const response = NextResponse.redirect(
    `https://discord.com/api/oauth2/authorize?${params}`,
  )
  response.cookies.set('discord_login_state', state, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    maxAge: 300,
    path: '/',
  })
  return response
}
