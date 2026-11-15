'use server'

import { prisma } from '@/lib/prisma'
import { hashPassword } from '@/lib/password'
import { env } from '@/lib/env'
import { jwtVerify } from 'jose'

export type ResetState = { error?: string; success?: boolean } | undefined

export async function resetAction(_prev: ResetState, formData: FormData): Promise<ResetState> {
  const token   = (formData.get('token')    as string ?? '')
  const password = (formData.get('password') as string ?? '')
  const confirm  = (formData.get('confirm')  as string ?? '')

  if (!token)                return { error: 'Invalid reset link.' }
  if (password.length < 8)   return { error: 'Password must be at least 8 characters.' }
  if (password !== confirm)  return { error: 'Passwords do not match.' }

  let accountId: number
  let resetAt: number

  try {
    const { payload } = await jwtVerify(
      token,
      new TextEncoder().encode(env.authSecret),
      { algorithms: ['HS256'] },
    )
    if (payload.scope !== 'password-reset') return { error: 'Invalid reset link.' }
    accountId = Number(payload.sub)
    resetAt = Number(payload.reset_at)
  } catch {
    return { error: 'This reset link has expired or is invalid. Please request a new one.' }
  }

  const account = await prisma.account.findUnique({
    where: { account_id: accountId },
    select: { password_reset_at: true },
  })

  // Single-use: ensure the reset_at in the token matches what's in the DB
  if (!account || account.password_reset_at !== resetAt) {
    return { error: 'This reset link has already been used. Please request a new one.' }
  }

  const changed = await prisma.account.updateMany({
    where: { account_id: accountId, password_reset_at: resetAt },
    data: {
      account_password:    await hashPassword(password),
      password_reset_at:   null,
      password_reset_version: { increment: 1 },
      twofa_code_hash: null, twofa_expires: null, twofa_attempts: 0,
      remember_token_hash: null,
      remember_token_expires: null,
    },
  })

  if (changed.count !== 1) return { error: 'This reset link has already been used.' }
  return { success: true }
}
