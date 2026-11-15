'use client'

import { useTransition } from 'react'
import { unbanAction } from './actions'

export default function UnbanButton({ banId, name }: { banId: number; name: string }) {
  const [pending, start] = useTransition()
  return (
    <button
      type="button"
      className="acp-btn acp-btn-danger acp-btn-sm"
      disabled={pending}
      onClick={() => { if (confirm(`Unban ${name}? This lets the account log in immediately.`)) start(() => unbanAction(banId)) }}
    >
      {pending ? '…' : 'Unban'}
    </button>
  )
}
