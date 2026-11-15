'use server'

import { randomBytes } from 'node:crypto'
import { redirect } from 'next/navigation'
import { sendVerificationEmail } from '@/lib/email'
import { env } from '@/lib/env'
import { prisma } from '@/lib/prisma'
import { requireUser } from '@/lib/dal'
import { revalidatePath } from 'next/cache'

export async function unlinkDiscordAction(): Promise<void> {
  if (!env.discordEnabled) return
  const user = await requireUser()

  const account = await prisma.account.findUnique({
    where: { account_id: user.id },
    select: { discord_id: true },
  })

  if (!account?.discord_id) return

  // Remove UCP Verified role from Discord (non-blocking)
  const { removeUcpRole } = await import('@/lib/discord-oauth')
  removeUcpRole(String(account.discord_id))

  await prisma.account.update({
    where: { account_id: user.id },
    data: {
      discord_id: null,
      account_discordname: '',
      discord_verified: 0,
      discord_linked_at: null,
    },
  })

  revalidatePath('/ucp/account')
}

/** First-admin and player email verification, with a persistent resend cooldown. */
export async function resendVerificationAction(): Promise<void> {
  const user = await requireUser()
  const account = await prisma.account.findUnique({ where: { account_id: user.id } })
  if (!account || account.account_email_verified) return
  if (!process.env.SMTP_HOST) redirect('/ucp/account?verification=unavailable')
  const now = Math.floor(Date.now() / 1000), code = randomBytes(16).toString('hex')
  const issued = await prisma.account.updateMany({ where: { account_id: user.id, account_email_verified: 0, OR: [{ account_email_verify_sent_at: null }, { account_email_verify_sent_at: { lte: now - 60 } }] }, data: { account_email_verifycode: code, account_email_verify_sent_at: now } })
  if (!issued.count) redirect('/ucp/account?verification=cooldown')
  try { await sendVerificationEmail(account.account_email, account.account_id, code, env.siteUrl) }
  catch { redirect('/ucp/account?verification=unavailable') }
  redirect('/ucp/account?verification=sent')
}
