'use server'

import { headers } from 'next/headers'
import { prisma } from '@/lib/prisma'
import { sendPasswordResetEmail } from '@/lib/email'
import { clientIpFromHeaders } from '@/lib/login-attempts'
import { env } from '@/lib/env'
import { SignJWT } from 'jose'

const RESET_EXPIRY = 60 * 60  // 1 hour

export type ForgotState = { error?: string; success?: boolean } | undefined

export async function forgotAction(_prev: ForgotState, formData: FormData): Promise<ForgotState> {
  const hdrs = await headers()
  const ip = clientIpFromHeaders(hdrs)
  const email = (formData.get('email') as string ?? '').trim()

  if (!email) return { error: 'Please enter your email address.' }

  const account = await prisma.account.findFirst({
    where: { account_email: email },
    select: { account_id: true, account_email: true },
  })

  // Always return success so account enumeration isn't possible
  if (!account) return { success: true }

  const now = Math.floor(Date.now() / 1000)
  await prisma.account.update({
    where: { account_id: account.account_id },
    data: { password_reset_at: now },
  })

  // Sign a JWT containing account ID + the reset timestamp for single-use validation
  const token = await new SignJWT({ scope: 'password-reset', reset_at: now })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(String(account.account_id))
    .setIssuedAt()
    .setExpirationTime(`${RESET_EXPIRY}s`)
    .sign(new TextEncoder().encode(env.authSecret))

  sendPasswordResetEmail(account.account_email, token, env.siteUrl).catch((e) => {
    console.error('[email] failed to send password reset:', e)
  })

  return { success: true }
}
