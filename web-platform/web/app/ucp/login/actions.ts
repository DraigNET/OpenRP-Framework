'use server'

import { safeCallbackUrl } from '@/lib/auth-policy'
import { signIn } from '@/auth'
import { AuthError } from 'next-auth'

type LoginState = { error?: string; success?: boolean; redirectTo?: string; requiresCode?: boolean } | undefined

export async function loginAction(_prev: LoginState, formData: FormData): Promise<LoginState> {
  const username = formData.get('username') as string
  const password = formData.get('password') as string
  const callbackUrl = safeCallbackUrl(formData.get('callbackUrl'))
  const code = String(formData.get('code') ?? '')

  try {
    await signIn('credentials', { username, password, code, redirect: false })
  } catch (e) {
    if (e instanceof AuthError) {
      const code = (e as AuthError & { code?: string }).code
      if (code === 'PasswordResetRequired') return { error: 'Your password must be reset before signing in. Use Forgot your password, or contact the server owner.' }
      if (code === 'TwoFactorUnavailable') return { error: 'Your account requires email verification, but mail delivery is unavailable. Contact the server owner.', requiresCode: true }
      if (code === 'TwoFactorRequired') return { error: 'Enter the code sent to your email. Codes expire after 5 minutes; resends are limited to once a minute.', requiresCode: true }
      if (code === 'TwoFactorInvalid') return { error: 'Invalid, expired or already used code.', requiresCode: true }
      if (code === 'RateLimited') {
        return { error: 'Too many failed login attempts. Please wait before trying again.' }
      }
      return { error: 'Invalid username or password.' }
    }
    return { error: 'Something went wrong. Please try again.' }
  }

  // Return success so the client can call router.refresh() to flush the router
  // cache before navigating — prevents stale layout data from a previous account
  // flashing briefly after switching accounts.
  return { success: true, redirectTo: callbackUrl }
}
