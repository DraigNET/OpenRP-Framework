'use client'

import { useActionState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import Script from 'next/script'
import { registerAction } from './actions'

export default function RegisterForm({ recaptchaSiteKey }: { recaptchaSiteKey: string | null }) {
  const router = useRouter()
  const [state, action, pending] = useActionState(registerAction, undefined)

  useEffect(() => {
    if (state?.success) {
      router.push('/ucp/register/success')
    }
  }, [state, router])

  return (
    <div className="ucp-login-body">
      <div className="ucp-login-wrapper">
        <div className="ucp-login-card">
          <h1>OpenRP Framework UCP</h1>
          <h2>Create Account</h2>

          {state?.error && (
            <div className="ucp-alert ucp-alert-error">{state.error}</div>
          )}

          <form action={action} className="ucp-login-form">
            <label>
              Username
              <input type="text" name="username" required minLength={3} maxLength={24}
                pattern="[A-Za-z0-9_]+" title="Letters, numbers and underscores only"
                autoComplete="username" />
            </label>
            <label>
              Email Address
              <input type="email" name="email" required maxLength={256} autoComplete="email" />
            </label>
            <label>
              Password
              <input type="password" name="password" required minLength={8} autoComplete="new-password" />
            </label>
            <label>
              Confirm Password
              <input type="password" name="confirm" required minLength={8} autoComplete="new-password" />
            </label>

            {recaptchaSiteKey && (
              <div className="g-recaptcha" data-sitekey={recaptchaSiteKey} style={{ marginTop: 8 }} />
            )}

            <div className="ucp-login-actions" style={{ marginTop: 20 }}>
              <button type="submit" disabled={pending} className="ucp-btn ucp-btn-primary">
                {pending ? 'Creating account…' : 'Create Account'}
              </button>
            </div>
          </form>

          <p className="ucp-login-footer" style={{ textAlign: 'center', marginTop: 16 }}>
            Already have an account?{' '}
            <Link href="/ucp/login" style={{ color: 'var(--accent-soft)', textDecoration: 'none' }}>
              Sign in
            </Link>
          </p>
        </div>
      </div>

      {recaptchaSiteKey && (
        <Script src="https://www.google.com/recaptcha/api.js" strategy="afterInteractive" />
      )}
    </div>
  )
}
