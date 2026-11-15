'use client'

import { useActionState } from 'react'
import { updatePenaltiesAction } from './actions'
import { PENALTY_FLAGS, type PenaltyState } from './flags'

const INITIAL: PenaltyState = { ok: false, error: '' }

export default function PenaltyFlagsForm({ accountId, values }: { accountId: number; values: Record<string, number> }) {
  const [state, action, pending] = useActionState(updatePenaltiesAction, INITIAL)

  return (
    <form action={action} className="acp-form" style={{ maxWidth: 'none' }}>
      <input type="hidden" name="account_id" value={accountId} />
      {state.error && <div className="acp-form-error">{state.error}</div>}
      {state.ok && <div className="acp-form-ok">Penalties saved.</div>}

      <div className="acp-flag-grid">
        {PENALTY_FLAGS.map(f => (
          <label key={f.key} className="acp-flag">
            <input type="checkbox" name={f.key} defaultChecked={values[f.key] === 1} />
            <span>{f.label}</span>
          </label>
        ))}
      </div>

      <div>
        <button type="submit" className="acp-btn acp-btn-primary" disabled={pending}>
          {pending ? 'Saving…' : 'Save Penalties'}
        </button>
      </div>
    </form>
  )
}
