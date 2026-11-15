import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { env } from '@/lib/env'
import {
  exchangeDiscordCode, fetchDiscordUser, isInGuild, assignUcpRole,
} from '@/lib/discord-oauth'

function redirect(path: string) {
  return NextResponse.redirect(`${env.siteUrl}${path}`)
}

export async function GET(req: NextRequest) {
  if (!env.discordEnabled) return NextResponse.json({ error: 'Discord integration is disabled.' }, { status: 404 })
  const session = await auth()
  if (!session) return redirect('/ucp/login')

  const { searchParams } = new URL(req.url)
  const code = searchParams.get('code')
  const state = searchParams.get('state')
  const storedState = req.cookies.get('discord_link_state')?.value

  const clearState = (res: NextResponse) => {
    res.cookies.delete('discord_link_state')
    return res
  }

  if (!code) return clearState(redirect('/ucp/account?discord=error'))
  if (!state || !storedState || state !== storedState)
    return clearState(redirect('/ucp/account?discord=state_error'))

  const redirectUri = `${env.siteUrl}/api/discord-link/callback`

  const accessToken = await exchangeDiscordCode(code, redirectUri)
  if (!accessToken) return clearState(redirect('/ucp/account?discord=token_error'))

  const discordUser = await fetchDiscordUser(accessToken)
  if (!discordUser) return clearState(redirect('/ucp/account?discord=user_error'))

  const inGuild = await isInGuild(discordUser.id)
  if (!inGuild) return clearState(redirect('/ucp/account?discord=not_in_server'))

  // Prevent the same Discord account being linked to two UCP accounts
  const existing = await prisma.account.findFirst({
    where: { discord_id: BigInt(discordUser.id) },
    select: { account_id: true },
  })
  if (existing && existing.account_id !== session.user.id)
    return clearState(redirect('/ucp/account?discord=already_linked'))

  await prisma.account.update({
    where: { account_id: session.user.id },
    data: {
      discord_id: BigInt(discordUser.id),
      account_discordname: discordUser.displayName,
      discord_verified: 1,
      discord_linked_at: Math.floor(Date.now() / 1000),
    },
  })

  assignUcpRole(discordUser.id)

  return clearState(redirect('/ucp/account?discord=linked'))
}
