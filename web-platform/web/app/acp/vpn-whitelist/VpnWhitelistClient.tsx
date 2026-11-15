'use client'

import { useActionState, useTransition } from 'react'
import { addVpnWhitelist, removeVpnWhitelist, type VpnWlState } from './actions'

const INITIAL: VpnWlState = { error: '', ok: false }

export function AddVpnForm() {
  const [state, action, pending] = useActionState(addVpnWhitelist, INITIAL)
  return (
    <form action={action} className="acp-wl-form">
      <input name="account" className="acp-input" placeholder="Account name or ID" required />
      <input name="reason" className="acp-input" placeholder="Reason (optional)" />
      <button className="acp-btn acp-btn-primary" disabled={pending}>{pending ? '…' : 'Add'}</button>
      {state.error && <span className="acp-wl-err">{state.error}</span>}
    </form>
  )
}

export function RemoveVpnButton({ id, label }: { id: number; label: string }) {
  const [pending, start] = useTransition()
  return (
    <button
      type="button"
      className="acp-btn acp-btn-danger acp-btn-sm"
      disabled={pending}
      onClick={() => { if (confirm(`Remove ${label} from the VPN whitelist?`)) start(() => removeVpnWhitelist(id)) }}
    >
      {pending ? '…' : 'Remove'}
    </button>
  )
}
