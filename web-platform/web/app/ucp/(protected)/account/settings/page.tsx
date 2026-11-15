'use client'

import { useActionState } from 'react'
import { changePasswordAction, changeEmailAction, toggle2FAAction } from './actions'

function Alert({ state }: { state?: { success?: string; error?: string } }) {
  if (!state?.success && !state?.error) return null
  return (
    <div className={`ucp-alert ${state.success ? 'ucp-alert-success' : 'ucp-alert-error'}`}>
      {state.success ?? state.error}
    </div>
  )
}

export default function SettingsPage() {
  const [pwState, pwAction, pwPending] = useActionState(changePasswordAction, undefined)
  const [emailState, emailAction, emailPending] = useActionState(changeEmailAction, undefined)
  const [tfaState, tfaAction, tfaPending] = useActionState(toggle2FAAction, undefined)

  return (
    <>
      <h2 style={{ margin: '0 0 20px', color: 'var(--text-1)' }}>Account Settings</h2>

      <div className="ucp-card">
        <h3 style={{ margin: '0 0 16px', fontSize: 16, color: 'var(--text-1)' }}>Change Password</h3>
        <Alert state={pwState} />
        <form action={pwAction} className="ucp-form">
          <label>Current Password<input name="current_password" type="password" /></label>
          <label>New Password<input name="new_password" type="password" placeholder="Min. 8 characters" /></label>
          <label>Confirm New Password<input name="confirm_password" type="password" /></label>
          <button type="submit" disabled={pwPending} className="ucp-btn ucp-btn-primary">
            {pwPending ? 'Updating…' : 'Update Password'}
          </button>
        </form>
      </div>

      <div className="ucp-card">
        <h3 style={{ margin: '0 0 16px', fontSize: 16, color: 'var(--text-1)' }}>Change Email</h3>
        <Alert state={emailState} />
        <form action={emailAction} className="ucp-form">
          <label>New Email Address<input name="email" type="email" /></label>
          <label>Current Password (to confirm)<input name="password" type="password" /></label>
          <label>Current email code (if 2FA is enabled)<input name="code" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} /></label>
          <button type="submit" disabled={emailPending} className="ucp-btn ucp-btn-primary">
            {emailPending ? 'Updating…' : 'Update Email'}
          </button>
        </form>
      </div>

      <div className="ucp-card">
        <h3 style={{ margin: '0 0 8px', fontSize: 16, color: 'var(--text-1)' }}>Web Two-Factor Authentication</h3>
        <p className="ucp-muted" style={{ marginBottom: 14 }}>When enabled, a 6-digit code will be emailed to you at each website login.</p>
        <Alert state={tfaState} />
        <form action={tfaAction} className="ucp-form">
          <label>Current password<input name="current_password" type="password" required autoComplete="current-password" /></label>
          <label>Email code (leave blank to request one)<input name="code" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} /></label>
          <button type="submit" disabled={tfaPending} className="ucp-btn ucp-btn-outline">
            {tfaPending ? 'Updating…' : 'Toggle 2FA'}
          </button>
        </form>
      </div>
    </>
  )
}
