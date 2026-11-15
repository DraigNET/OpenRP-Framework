import { env } from '@/lib/env'
import { prisma } from '@/lib/prisma'
import { requireUser } from '@/lib/dal'
import { formatUnixDate, formatDateTime } from '@/lib/format'
import { COLOR } from '@/lib/colors'
import Link from 'next/link'
import { unlinkDiscordAction, resendVerificationAction } from './actions'

const DISCORD_MESSAGES: Record<string, { ok: boolean; text: string }> = {
  linked:         { ok: true,  text: 'Discord account linked and UCP Verified role assigned.' },
  not_in_server:  { ok: false, text: 'You must join the OpenRP Framework Discord server before linking.' },
  already_linked: { ok: false, text: 'That Discord account is already linked to another UCP account.' },
  error:          { ok: false, text: 'Discord link failed. Please try again.' },
  state_error:    { ok: false, text: 'Security check failed. Please try again.' },
  token_error:    { ok: false, text: 'Could not exchange Discord token. Please try again.' },
  user_error:     { ok: false, text: 'Could not fetch Discord profile. Please try again.' },
}

export default async function AccountPage({ searchParams }: { searchParams: Promise<Record<string, string>> }) {
  const params = await searchParams
  const discordMsg = env.discordEnabled && params.discord ? DISCORD_MESSAGES[params.discord] : null
  const user = await requireUser()
  const account = await prisma.account.findUnique({ where: { account_id: user.id } })
  if (!account) return null

  const regDate = formatUnixDate(account.account_register_date)
  const lastLogin = formatDateTime(account.account_lastlogin)

  return (
    <>
      {discordMsg && (
        <div className={`ucp-alert ${discordMsg.ok ? 'ucp-alert-success' : 'ucp-alert-error'}`} style={{ marginBottom: 16 }}>
          {discordMsg.text}
        </div>
      )}

      {params.verification && <p className="ucp-muted" role="status">{params.verification === 'sent' ? 'Verification email sent. Check your inbox.' : params.verification === 'cooldown' ? 'Wait one minute before requesting another email.' : 'Mail delivery is not configured or unavailable. Contact the server owner.'}</p>}
      {!account.account_email_verified && <form action={resendVerificationAction}><button className="ucp-btn ucp-btn-outline" type="submit">Send verification email</button></form>}
      {/* Account Overview */}
      <div className="ucp-card">
        <h2>Account Overview</h2>

        {[
          { label: 'Username', value: account.account_name },
          { label: 'Email', value: account.account_email || 'Not set' },
          { label: 'Email Verified', value: account.account_email_verified
            ? <span style={{ color: COLOR.success, fontWeight: 600 }}>Yes</span>
            : <span style={{ color: COLOR.danger, fontWeight: 600 }}>No</span> },
          { label: 'Registered', value: regDate },
          { label: 'Last Login', value: lastLogin },
          { label: 'Premium Level', value: account.account_premiumlevel },
        ].map(({ label, value }) => (
          <div key={label} className="ucp-detail-row">
            <span>{label}</span>
            <span>{value}</span>
          </div>
        ))}

        <div className="ucp-detail-row">
          <span>Rules Quiz</span>
          <span style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
            {account.account_quiz_passed ? (
              <>
                <span style={{ color: COLOR.success, fontWeight: 600 }}><i className="fa-solid fa-check" /> Passed</span>
                <Link href="/ucp/quiz" className="ucp-btn ucp-btn-outline">View Results</Link>
              </>
            ) : (
              <>
                <span style={{ color: COLOR.warning, fontWeight: 600 }}><i className="fa-solid fa-triangle-exclamation" /> Not passed</span>
                <Link href="/ucp/quiz" className="ucp-btn ucp-btn-primary">Take Rules Quiz</Link>
              </>
            )}
          </span>
        </div>
      </div>

      {/* Connected Accounts */}
      {env.discordEnabled && <div className="ucp-card">
        <h2>Connected Accounts</h2>

        <div className="ucp-detail-row">
          <span>Discord</span>
          <span style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
            {account.discord_verified ? (
              <>
                <span style={{ color: COLOR.success, fontWeight: 600 }}>
                  <i className="fa-brands fa-discord" /> {account.account_discordname || 'Linked'}
                </span>
                <form action={unlinkDiscordAction} style={{ display: 'inline' }}>
                  <button type="submit" className="ucp-btn ucp-btn-outline"
                    style={{ color: COLOR.danger, borderColor: COLOR.danger }}>
                    Unlink
                  </button>
                </form>
              </>
            ) : (
              <a href="/api/discord-link" className="ucp-btn ucp-btn-primary"
                style={{ background: '#5865F2', borderColor: '#5865F2', textDecoration: 'none' }}>
                <i className="fa-brands fa-discord" /> Link Discord
              </a>
            )}
          </span>
        </div>

        <p className="ucp-muted" style={{ marginTop: 14, fontSize: 13 }}>
          Linking your Discord account allows secure identity verification and grants the{' '}
          <strong>UCP Verified</strong>{' '}
          role in the OpenRP Framework Discord server.
        </p>
      </div>}

      {/* Security Status */}
      <div className="ucp-card">
        <h2>Security Status</h2>

        <div className="ucp-detail-row">
          <span>Email 2FA</span>
          <span>
            {account.twofa_enabled ? (
              <span style={{ color: COLOR.success, fontWeight: 600 }}><i className="fa-solid fa-shield-check" /> Enabled</span>
            ) : (
              <span style={{ color: COLOR.danger, fontWeight: 600 }}><i className="fa-solid fa-shield-xmark" /> Disabled</span>
            )}
          </span>
        </div>

        <p className="ucp-muted" style={{ marginTop: 14, fontSize: 13 }}>
          Security settings can be changed from the{' '}
          <Link href="/ucp/account/settings" style={{ color: 'var(--accent-soft)' }}>Settings</Link>{' '}
          page.
        </p>
      </div>
    </>
  )
}
