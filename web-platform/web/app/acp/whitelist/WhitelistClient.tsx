'use client'

import { useActionState, useTransition } from 'react'
import { addIpWhitelist, addAccountWhitelist, removeWhitelist, type WlState } from './actions'

const INITIAL: WlState = { error: '', ok: false }

export function AddIpForm() {
  const [state, action, pending] = useActionState(addIpWhitelist, INITIAL)
  return (
    <form action={action} className="acp-wl-form">
      <input name="ip" className="acp-input" placeholder="IP address" required />
      <input name="reason" className="acp-input" placeholder="Reason (optional)" />
      <input name="days" type="number" min={0} defaultValue={0} className="acp-input acp-wl-days" title="Days (0 = permanent)" />
      <button className="acp-btn acp-btn-primary" disabled={pending}>{pending ? '…' : 'Add'}</button>
      {state.error && <span className="acp-wl-err">{state.error}</span>}
    </form>
  )
}

export function AddAccountForm() {
  const [state, action, pending] = useActionState(addAccountWhitelist, INITIAL)
  return (
    <form action={action} className="acp-wl-form">
      <input name="account" className="acp-input" placeholder="Account name or ID" required />
      <input name="reason" className="acp-input" placeholder="Reason (optional)" />
      <input name="days" type="number" min={0} defaultValue={0} className="acp-input acp-wl-days" title="Days (0 = permanent)" />
      <button className="acp-btn acp-btn-primary" disabled={pending}>{pending ? '…' : 'Add'}</button>
      {state.error && <span className="acp-wl-err">{state.error}</span>}
    </form>
  )
}

export function RemoveButton({ kind, id, label }: { kind: 'ip' | 'account'; id: number; label: string }) {
  const [pending, start] = useTransition()
  return (
    <button
      type="button"
      className="acp-btn acp-btn-danger acp-btn-sm"
      disabled={pending}
      onClick={() => { if (confirm(`Remove ${label} from the whitelist?`)) start(() => removeWhitelist(kind, id)) }}
    >
      {pending ? '…' : 'Remove'}
    </button>
  )
}
