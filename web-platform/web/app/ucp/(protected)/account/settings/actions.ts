'use server'

import { randomBytes } from 'node:crypto'

import { sendVerificationEmail } from '@/lib/email'
import { env } from '@/lib/env'
import { checkEmailCode } from '@/lib/two-factor'
import { prisma } from '@/lib/prisma'
import { requireUser } from '@/lib/dal'
import { verifyPassword, hashPassword } from '@/lib/password'
import { passwordChangeSchema, emailChangeSchema, firstError } from '@/lib/schemas'

export type SettingsState = { success?: string; error?: string } | undefined

export async function changePasswordAction(_prev: SettingsState, formData: FormData): Promise<SettingsState> {
  const user = await requireUser()

  const parsed = passwordChangeSchema.safeParse({
    current_password: formData.get('current_password') ?? '',
    new_password: formData.get('new_password') ?? '',
    confirm_password: formData.get('confirm_password') ?? '',
  })
  if (!parsed.success) return { error: firstError(parsed.error) }

  const account = await prisma.account.findUnique({ where: { account_id: user.id } })
  if (!account) return { error: 'Account not found.' }

  if (!(await verifyPassword(parsed.data.current_password, account.account_password))) {
    return { error: 'Current password is incorrect.' }
  }

  await prisma.account.update({
    where: { account_id: user.id },
    data: {
      account_password: await hashPassword(parsed.data.new_password),
      password_reset_version: { increment: 1 },
      twofa_code_hash: null, twofa_expires: null, twofa_attempts: 0,
      remember_token_hash: null,
      remember_token_expires: null,
    },
  })
  return { success: 'Password updated successfully.' }
}

export async function changeEmailAction(_prev: SettingsState, formData: FormData): Promise<SettingsState> {
  const user = await requireUser()

  const parsed = emailChangeSchema.safeParse({
    email: formData.get('email') ?? '',
    password: formData.get('password') ?? '',
  })
  if (!parsed.success) return { error: firstError(parsed.error) }

  const account = await prisma.account.findUnique({ where: { account_id: user.id } })
  if (!account) return { error: 'Account not found.' }

  if (!(await verifyPassword(parsed.data.password, account.account_password))) {
    return { error: 'Password is incorrect.' }
  }

  if (account.twofa_enabled) {
    try {
      const result = await checkEmailCode(account.account_id, account.account_email, String(formData.get('code') ?? ''))
      if (result !== 'ok') return { error: result === 'required' ? 'Enter the code sent to your current email, then submit again.' : 'Invalid or expired email code.' }
    } catch { return { error: 'Could not send a verification code. Contact the server owner.' } }
  }
  const verifyCode = randomBytes(16).toString('hex')
  await prisma.account.update({
    where: { account_id: user.id },
    data: { account_email: parsed.data.email, account_email_verified: 0, account_email_verifycode: verifyCode, account_email_verify_sent_at: Math.floor(Date.now() / 1000), twofa_code_hash: null, twofa_expires: null, password_reset_version: { increment: 1 } },
  })
  await sendVerificationEmail(parsed.data.email, account.account_id, verifyCode, env.siteUrl).catch(() => {})
  return { success: 'Email updated. Verify the new address and sign in again.' }
}

export async function toggle2FAAction(_prev: SettingsState, _formData: FormData): Promise<SettingsState> {
  const user = await requireUser()

  const account = await prisma.account.findUnique({ where: { account_id: user.id } })
  if (!account) return { error: 'Account not found.' }

  if (!(await verifyPassword(String(_formData.get('current_password') ?? ''), account.account_password))) return { error: 'Current password is incorrect.' }
  if (!account.account_email_verified) return { error: 'Verify your email address before changing email 2FA.' }
  try {
    const result = await checkEmailCode(account.account_id, account.account_email, String(_formData.get('code') ?? ''))
    if (result !== 'ok') return { error: result === 'required' ? 'Enter the code emailed to you, then submit again with your password.' : 'Invalid, expired or already used code.' }
  } catch { return { error: 'Email delivery is not configured or unavailable. Contact the server owner.' } }
  const newState = account.twofa_enabled ? 0 : 1
  await prisma.account.update({ where: { account_id: user.id }, data: { twofa_enabled: newState, password_reset_version: { increment: 1 } } })
  return { success: `Two-factor authentication ${newState ? 'enabled' : 'disabled'}.` }
}
