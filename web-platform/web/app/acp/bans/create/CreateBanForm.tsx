'use client'

import { useActionState } from 'react'
import { createBanAction, type CreateBanState } from '../actions'

const INITIAL: CreateBanState = { error: '' }

export default function CreateBanForm() {
  const [state, action, pending] = useActionState(createBanAction, INITIAL)

  return (
    <form action={action} className="acp-form">
      {state.error && <div className="acp-form-error">{state.error}</div>}

      <div className="acp-field">
        <label htmlFor="account_name">Account Name</label>
        <input id="account_name" name="account_name" className="acp-input" placeholder="Exact account username" required />
      </div>

      <div className="acp-field">
        <label htmlFor="hours">Duration (hours)</label>
        <input id="hours" name="hours" type="number" min={0} max={720} defaultValue={0} className="acp-input" />
        <span className="acp-field-hint">0 = permanent. Max 720 hours (30 days).</span>
      </div>

      <div className="acp-field">
        <label htmlFor="reason">Reason</label>
        <input id="reason" name="reason" className="acp-input" maxLength={64} placeholder="Reason (max 64 chars)" required />
      </div>

      <div>
        <button type="submit" className="acp-btn acp-btn-danger" disabled={pending}>
          {pending ? 'Banning…' : 'Ban Account'}
        </button>
      </div>
    </form>
  )
}
