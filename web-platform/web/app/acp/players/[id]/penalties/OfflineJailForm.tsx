'use client'

import { useActionState } from 'react'
import { offlineJailAction } from './actions'
import type { OjailState } from './flags'

const INIT: OjailState = { ok: false, error: '', message: '' }

export default function OfflineJailForm({ accountId, characters }: { accountId: number; characters: Array<{ id: number; name: string }> }) {
  const [state, action, pending] = useActionState(offlineJailAction, INIT)
  return (
    <form action={action} className="acp-form" style={{ maxWidth: 480 }}>
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
        <div className="acp-field"><label>Time (minutes, min 10)</label><input name="time" type="number" min={10} className="acp-input" placeholder="e.g. 60" required /></div>
        <div className="acp-field"><label>Reason (max 64)</label><input name="reason" maxLength={64} className="acp-input" placeholder="Reason" required /></div>
      </div>
      <div><button type="submit" className="acp-btn acp-btn-danger" disabled={pending}>{pending ? 'Jailing…' : 'Offline Admin Jail'}</button></div>
    </form>
  )
}
