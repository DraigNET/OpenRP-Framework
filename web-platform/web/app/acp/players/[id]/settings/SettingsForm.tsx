'use client'

import { useActionState } from 'react'
import { updateAccountSettings, type SettingsState } from './actions'
import { staffLevelTitle } from '@/lib/constants'

const INIT: SettingsState = { error: '', ok: false }

interface Values {
  account_id: number
  account_email: string
  account_email_verified: number
  account_stafflevel: number
  account_supporter: number
  account_premiumlevel: number
  account_factionteam: number
  account_quiz_passed: number
  twofa_enabled: number
  discord_verified: number
  account_discordname: string
  discord_id: string | null
}

export default function SettingsForm({ v }: { v: Values }) {
  const [state, action, pending] = useActionState(updateAccountSettings, INIT)
  return (
    <form action={action} className="acp-form" style={{ maxWidth: 560 }}>
      <input type="hidden" name="account_id" value={v.account_id} />
      {state.error && <div className="acp-form-error">{state.error}</div>}
      {state.ok && <div className="acp-form-ok">Account settings saved.</div>}

      <div className="acp-field">
        <label>Email</label>
        <input name="account_email" defaultValue={v.account_email} className="acp-input" type="email" />
      </div>

      <div className="acp-fs-row">
        <div className="acp-field">
          <label>Staff Level</label>
          <select name="account_stafflevel" defaultValue={v.account_stafflevel} className="acp-input">
            {[0, 1, 2, 3, 4, 5, 6, 7, 8].map(l => <option key={l} value={l}>{l} — {staffLevelTitle(l)}</option>)}
          </select>
        </div>
        <div className="acp-field">
          <label>Supporter Rank</label>
          <select name="account_supporter" defaultValue={v.account_supporter} className="acp-input">
            <option value={0}>None</option><option value={1}>Trial</option><option value={2}>Helper</option><option value={3}>Senior Helper</option>
          </select>
        </div>
      </div>

      <div className="acp-fs-row">
        <div className="acp-field"><label>Premium Level</label><input name="account_premiumlevel" type="number" defaultValue={v.account_premiumlevel} className="acp-input" /></div>
        <div className="acp-field"><label>Faction Team</label><input name="account_factionteam" type="number" defaultValue={v.account_factionteam} className="acp-input" /></div>
      </div>

      <div className="acp-fs-row">
        <div className="acp-field">
          <label>Discord Name</label>
          <input name="account_discordname" defaultValue={v.account_discordname === 'Undefined' ? '' : v.account_discordname} className="acp-input" placeholder="Not linked" />
        </div>
        <div className="acp-field">
          <label>Discord ID</label>
          <input name="discord_id" defaultValue={v.discord_id ?? ''} className="acp-input" placeholder="Not linked" />
        </div>
      </div>

      <div className="acp-flag-grid">
        <label className="acp-flag"><input type="checkbox" name="account_email_verified" defaultChecked={v.account_email_verified === 1} /> <span>Email Verified</span></label>
        <label className="acp-flag"><input type="checkbox" name="discord_verified" defaultChecked={v.discord_verified === 1} /> <span>Discord Verified</span></label>
        <label className="acp-flag"><input type="checkbox" name="account_quiz_passed" defaultChecked={v.account_quiz_passed === 1} /> <span>Quiz Passed</span></label>
        <label className="acp-flag"><input type="checkbox" name="twofa_enabled" defaultChecked={v.twofa_enabled === 1} /> <span>Email 2FA</span></label>
      </div>

      <div><button type="submit" className="acp-btn acp-btn-primary" disabled={pending}>{pending ? 'Saving…' : 'Save Account Settings'}</button></div>
    </form>
  )
}
