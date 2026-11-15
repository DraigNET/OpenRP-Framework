'use client'

import { useActionState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { loginAction } from './actions'

const ERROR_MESSAGES: Record<string, string> = {
  UsePassword2FA: 'Use your username and password to complete your account security checks.',
  CredentialsSignin: 'Invalid username or password.',
  NotInGuild: 'You must join the OpenRP Framework Discord server before using Discord login.',
  NoLinkedAccount: 'This Discord account is not linked to a OpenRP Framework UCP account.',
  RateLimited: 'Too many failed login attempts. Please wait before trying again.',
  DiscordError: 'Discord authentication failed. Please try again.',
  default: 'An error occurred. Please try again.',
}

export default function LoginForm({ urlError, callbackUrl, discordEnabled = false }: { urlError?: string; callbackUrl: string; discordEnabled?: boolean }) {
  const router = useRouter()
  const [state, action, pending] = useActionState(loginAction, undefined)

  useEffect(() => {
    if (state?.success && state.redirectTo) {
      router.refresh()
      router.push(state.redirectTo)
    }
  }, [state, router])

  const errorMsg = state?.error ?? (urlError ? (ERROR_MESSAGES[urlError] ?? ERROR_MESSAGES.default) : null)

  return (
    <div className="ucp-login-body">
      <div className="ucp-login-wrapper">
        <div className="ucp-login-card">
          <h1>OpenRP Framework UCP</h1>
          <h2>Sign In</h2>

          {errorMsg && (
            <div className="ucp-alert ucp-alert-error">{errorMsg}</div>
          )}

          <form action={action} className="ucp-login-form">
            <input type="hidden" name="callbackUrl" value={callbackUrl} />
            <label>
              Username
              <input type="text" name="username" required autoComplete="username" />
            </label>
            <label>
              Password
              <input type="password" name="password" required autoComplete="current-password" />
            </label>

            <label>
              Email code (if 2FA is enabled)
              <input type="text" name="code" inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]{6}" maxLength={6} />
            </label>
            <p className="ucp-muted" style={{ fontSize: 12 }}>Leave the code blank on your first attempt to request an email.</p>
            <div className="ucp-remember-row">
              <label className="ucp-remember">
                <input type="checkbox" name="remember_me" value="1" />
                <span className="ucp-remember-box" />
                <span>Stay logged in</span>
              </label>
            </div>

            <div className="ucp-login-actions">
              <button type="submit" disabled={pending} className="ucp-btn ucp-btn-primary">
                {pending ? 'Logging in…' : 'Login'}
              </button>
              <Link href="/ucp/register" className="ucp-btn ucp-btn-outline ucp-btn-right" style={{ border: '1px solid var(--border)', color: 'var(--accent-soft)' }}>
                Create an Account
              </Link>
            </div>
          </form>

          {discordEnabled && <>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, margin: '18px 0 12px' }}>
            <hr style={{ flex: 1, border: 'none', borderTop: '1px solid var(--border)' }} />
            <span style={{ color: 'var(--text-3)', fontSize: 12, whiteSpace: 'nowrap' }}>or</span>
            <hr style={{ flex: 1, border: 'none', borderTop: '1px solid var(--border)' }} />
          </div>

          <a href="/api/discord-login" className="ucp-btn ucp-btn-auth-link"
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, background: '#5865F2', borderColor: '#5865F2', color: '#fff', textDecoration: 'none', marginBottom: 18 }}>
            <i className="fa-brands fa-discord" /> Login with Discord
          </a>
          </>}

          <div className="ucp-login-footer">
            <Link href="/ucp/forgot" className="ucp-link" style={{ color: 'var(--accent-soft)', textDecoration: 'none' }}>
              Forgot your password?
            </Link>
          </div>

          <p className="ucp-login-footer" style={{ textAlign: 'right' }}>
            <a href="/" style={{ color: 'var(--text-2)', textDecoration: 'none', fontSize: 13 }}>
              Back to main site
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}
