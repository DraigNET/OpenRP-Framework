'use client'

import { useActionState, useTransition } from 'react'
import { transferCharacter, discordBanAction, deleteAccount, type ManageState } from './actions'

const INIT: ManageState = { error: '', ok: false, message: '' }

export function TransferForm({ accountId, characters }: { accountId: number; characters: Array<{ id: number; name: string }> }) {
  const [state, action, pending] = useActionState(transferCharacter, INIT)
  if (characters.length === 0) return <p className="acp-field-hint">This account has no characters to transfer.</p>
  return (
    <form action={action} className="acp-form" style={{ maxWidth: 520 }}>
      <input type="hidden" name="account_id" value={accountId} />
      {state.error && <div className="acp-form-error">{state.error}</div>}
      {state.ok && <div className="acp-form-ok">{state.message}</div>}
      <div className="acp-field">
        <label>Character</label>
        <select name="character_id" className="acp-input" required>
          {characters.map(c => <option key={c.id} value={c.id}>{c.name.replace(/_/g, ' ')}</option>)}
        </select>
      </div>
      <div className="acp-fs-row">
        <div className="acp-field"><label>Target Account (name or ID)</label><input name="target_account" className="acp-input" required /></div>
        <div className="acp-field"><label>Reason</label><input name="reason" className="acp-input" maxLength={255} /></div>
      </div>
      <div><button type="submit" className="acp-btn acp-btn-primary" disabled={pending}>{pending ? 'Transferring…' : 'Transfer Character'}</button></div>
    </form>
  )
}

export function DiscordBanButton({ accountId }: { accountId: number }) {
  const [pending, start] = useTransition()
  return (
    <button type="button" className="acp-btn acp-btn-danger" disabled={pending}
      onClick={() => { if (confirm('Ban this user from the Discord guild?')) start(() => discordBanAction(accountId)) }}>
      {pending ? 'Banning…' : 'Ban from Discord'}
    </button>
  )
}

export function DeleteAccountForm({ accountId, accountName }: { accountId: number; accountName: string }) {
  const [state, action, pending] = useActionState(deleteAccount, INIT)
  return (
    <form action={action} className="acp-form" style={{ maxWidth: 520 }}>
      <input type="hidden" name="account_id" value={accountId} />
      {state.error && <div className="acp-form-error">{state.error}</div>}
      <div className="acp-alert acp-alert-danger">This permanently deletes the account and <strong>all</strong> its characters and data.</div>
      <div className="acp-fs-row">
        <div className="acp-field"><label>Confirm Username</label><input name="confirm_account_name" className="acp-input" placeholder={accountName} required /></div>
        <div className="acp-field"><label>Reason</label><input name="reason" className="acp-input" maxLength={255} /></div>
      </div>
      <div><button type="submit" className="acp-btn acp-btn-danger" disabled={pending}
        onClick={e => { if (!confirm('Permanently delete this account and all characters?')) e.preventDefault() }}>
        {pending ? 'Deleting…' : 'Delete Account'}</button></div>
    </form>
  )
}
