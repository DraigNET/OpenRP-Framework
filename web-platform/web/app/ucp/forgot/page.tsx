'use client'

import { useActionState } from 'react'
import Link from 'next/link'
import { forgotAction } from './actions'

export default function ForgotPage() {
  const [state, action, pending] = useActionState(forgotAction, undefined)

  if (state?.success) {
    return (
      <div className="ucp-login-body">
        <div className="ucp-login-wrapper">
          <div className="ucp-login-card" style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>✉️</div>
            <h1>OpenRP Framework UCP</h1>
            <h2>Check Your Email</h2>
            <p style={{ color: 'var(--text-2)', marginBottom: 24 }}>
              If an account exists for that email address, we&apos;ve sent a password reset link.
              Please check your inbox and spam folder.
            </p>
            <Link href="/ucp/login" className="ucp-btn ucp-btn-outline"
              style={{ display: 'inline-flex', justifyContent: 'center', color: 'var(--accent-soft)' }}>
              Back to Login
            </Link>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="ucp-login-body">
      <div className="ucp-login-wrapper">
        <div className="ucp-login-card">
          <h1>OpenRP Framework UCP</h1>
          <h2>Reset Password</h2>
          <p style={{ color: 'var(--text-2)', fontSize: 14, marginBottom: 20 }}>
            Enter your email address and we&apos;ll send you a link to reset your password.
          </p>

          {state?.error && (
            <div className="ucp-alert ucp-alert-error">{state.error}</div>
          )}

          <form action={action} className="ucp-login-form">
            <label>
              Email Address
              <input type="email" name="email" required autoComplete="email" />
            </label>
            <div className="ucp-login-actions" style={{ marginTop: 20 }}>
              <button type="submit" disabled={pending} className="ucp-btn ucp-btn-primary">
                {pending ? 'Sending…' : 'Send Reset Link'}
              </button>
            </div>
          </form>

          <p className="ucp-login-footer" style={{ textAlign: 'center', marginTop: 16 }}>
            <Link href="/ucp/login" style={{ color: 'var(--accent-soft)', textDecoration: 'none' }}>
              Back to Login
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
