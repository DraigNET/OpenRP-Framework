'use client'

import { useActionState } from 'react'
import Link from 'next/link'
import { resetAction } from './actions'
import { use } from 'react'

export default function ResetPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = use(params)
  const [state, action, pending] = useActionState(resetAction, undefined)

  if (state?.success) {
    return (
      <div className="ucp-login-body">
        <div className="ucp-login-wrapper">
          <div className="ucp-login-card" style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 48, marginBottom: 16 }}>✅</div>
            <h1>OpenRP Framework UCP</h1>
            <h2>Password Updated</h2>
            <p style={{ color: 'var(--text-2)', marginBottom: 24 }}>
              Your password has been changed successfully.
            </p>
            <Link href="/ucp/login" className="ucp-btn ucp-btn-primary"
              style={{ display: 'inline-flex', justifyContent: 'center' }}>
              Log In
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
          <h2>Choose a New Password</h2>

          {state?.error && (
            <div className="ucp-alert ucp-alert-error">{state.error}</div>
          )}

          <form action={action} className="ucp-login-form">
            <input type="hidden" name="token" value={decodeURIComponent(token)} />
            <label>
              New Password
              <input type="password" name="password" required minLength={8} autoComplete="new-password" />
            </label>
            <label>
              Confirm Password
              <input type="password" name="confirm" required minLength={8} autoComplete="new-password" />
            </label>
            <div className="ucp-login-actions" style={{ marginTop: 20 }}>
              <button type="submit" disabled={pending} className="ucp-btn ucp-btn-primary">
                {pending ? 'Updating…' : 'Update Password'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
