'use server'

import { headers } from 'next/headers'
import { prisma } from '@/lib/prisma'
import { hashPassword } from '@/lib/password'
import { verifyRecaptcha } from '@/lib/recaptcha'
import { sendVerificationEmail } from '@/lib/email'
import { clientIpFromHeaders } from '@/lib/login-attempts'
import { env } from '@/lib/env'
import { randomBytes } from 'crypto'

const USERNAME_RE = /^[A-Za-z0-9_]{3,24}$/
const REG_WINDOW = 3600   // 1 hour
const REG_MAX    = 5      // max attempts per window

export type RegisterState = { error?: string; success?: boolean } | undefined

export async function registerAction(_prev: RegisterState, formData: FormData): Promise<RegisterState> {
  const hdrs = await headers()
  const ip = clientIpFromHeaders(hdrs)

  const username  = (formData.get('username')  as string ?? '').trim()
  const email     = (formData.get('email')     as string ?? '').trim()
  const password  = (formData.get('password')  as string ?? '')
  const confirm   = (formData.get('confirm')   as string ?? '')
  const captcha   = (formData.get('g-recaptcha-response') as string ?? '')

  if (!username || !email || !password || !confirm)
    return { error: 'All fields are required.' }

  if (!USERNAME_RE.test(username))
    return { error: 'Username must be 3–24 characters and contain only letters, numbers, and underscores.' }

  if (email.length > 256 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
    return { error: 'Please enter a valid email address.' }

  if (password.length < 8)
    return { error: 'Password must be at least 8 characters.' }

  if (password !== confirm)
    return { error: 'Passwords do not match.' }

  // reCAPTCHA
  if (process.env.RECAPTCHA_SITE_KEY) {
    const ok = await verifyRecaptcha(captcha, ip)
    if (!ok) return { error: 'reCAPTCHA verification failed. Please try again.' }
  }

  // IP ban check
  const now = Math.floor(Date.now() / 1000)
  const banned = await prisma.ban.findFirst({
    where: { account_ip: ip, OR: [{ unban_time: 0 }, { unban_time: { gt: now } }] },
    select: { ban_id: true },
  })
  if (banned) return { error: 'Registration is not available from your IP address.' }

  // Rate limit: 5 attempts / hour / IP
  const since = now - REG_WINDOW
  const attempts = await prisma.ucpRegistrationAttempt.count({
    where: { ip_address: ip, created_at: { gt: since } },
  })
  if (attempts >= REG_MAX) {
    await logAttempt(username, email, ip, false, 'rate_limited')
    return { error: 'Too many registration attempts. Please wait before trying again.' }
  }

  // Multi-account check: IP already has an account
  const ipHasAccount = await prisma.accountIpHistory.findFirst({
    where: { ip_address: ip },
    select: { account_id: true },
  })
  if (ipHasAccount) {
    // Check whitelist
    const whitelisted = await prisma.multiaccountIpWhitelist.findUnique({ where: { ip_address: ip } })
    if (!whitelisted) {
      await logAttempt(username, email, ip, false, 'multi_account')
      return { error: 'An account already exists from your IP address.' }
    }
  }

  // Username taken (case-insensitive)
  const usernameTaken = await prisma.account.findFirst({
    where: { account_name: username },
    select: { account_id: true },
  })
  if (usernameTaken) {
    await logAttempt(username, email, ip, false, 'username_taken')
    return { error: 'That username is already taken.' }
  }

  // Email taken (MySQL string comparisons are case-insensitive by default)
  const emailTaken = await prisma.account.findFirst({
    where: { account_email: email },
    select: { account_id: true },
  })
  if (emailTaken) {
    await logAttempt(username, email, ip, false, 'email_taken')
    return { error: 'That email address is already in use.' }
  }

  const verifyCode = randomBytes(16).toString('hex') // 32-char hex
  const hashed = await hashPassword(password)

  const account = await prisma.account.create({
    data: {
      account_name:             username,
      account_password:         hashed,
      account_email:            email,
      account_email_verifycode: verifyCode,
      account_email_verify_sent_at: now,
      account_email_verified:   0,
      account_lastip:           ip,
      account_register_date:    now,
      password_reset_version:   1,
      account_quiz_passed:      0,
    },
  })

  // Log IP history
  await prisma.accountIpHistory.upsert({
    where: { account_id_ip_address: { account_id: account.account_id, ip_address: ip } },
    create: { account_id: account.account_id, ip_address: ip, first_seen: now, last_seen: now, access_count: 1 },
    update: { last_seen: now, access_count: { increment: 1 } },
  })

  await logAttempt(username, email, ip, true, '')

  // Send verification email (non-blocking)
  sendVerificationEmail(email, account.account_id, verifyCode, env.siteUrl).catch((e) => {
    console.error('[email] failed to send verification:', e)
  })

  return { success: true }
}

async function logAttempt(name: string, email: string, ip: string, success: boolean, reason: string) {
  await prisma.ucpRegistrationAttempt.create({
    data: {
      account_name: name.slice(0, 191),
      email: email.slice(0, 191),
      ip_address: ip,
      success: success ? 1 : 0,
      reason,
      created_at: Math.floor(Date.now() / 1000),
    },
  }).catch(() => {})
}

