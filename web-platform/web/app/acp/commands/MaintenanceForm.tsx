'use client'

import { useActionState } from 'react'
import { scheduleMaintenance } from './actions'

export default function MaintenanceForm() {
  const [state, action, pending] = useActionState(scheduleMaintenance, undefined)

  return (
    <div className="acp-panel" style={{ marginBottom: 14 }}>
      <div className="acp-panel-head"><span>Schedule Maintenance</span></div>
      <form action={action} style={{ padding: 14, display: 'flex', flexDirection: 'column', gap: 12, maxWidth: 420 }}>
        <p style={{ margin: 0, fontSize: 13, color: 'var(--acp-text-2)' }}>
          Broadcasts a server-wide warning and starts a countdown. The server will shut down when the timer reaches zero.
        </p>

        <div className="acp-field">
          <label className="acp-field" style={{ fontSize: 12, fontWeight: 600, color: 'var(--acp-text-2)' }}>
            Countdown (seconds) — min 30, max 21600
          </label>
          <input
            name="seconds"
            type="number"
            min={30}
            max={21600}
            defaultValue={300}
            className="acp-input"
            style={{ width: 140 }}
            required
          />
        </div>

        {state?.error && <div className="acp-badge is-red" style={{ alignSelf: 'flex-start' }}>{state.error}</div>}
        {state?.ok    && <div className="acp-badge is-green" style={{ alignSelf: 'flex-start' }}>Queued — server will pick it up within 2 seconds.</div>}

        <div>
          <button type="submit" disabled={pending} className="acp-btn acp-btn-danger">
            <i className="fa-solid fa-triangle-exclamation" /> {pending ? 'Queuing…' : 'Schedule Maintenance'}
          </button>
        </div>
      </form>
    </div>
  )
}
