'use client'

import { useTransition } from 'react'
import { kickMember } from './actions'

export function KickButton({ charPlayerId, memberId, memberName }: {
  charPlayerId: number; memberId: number; memberName: string
}) {
  const [pending, start] = useTransition()
  return (
    <button
      type="button"
      className="ucp-btn ucp-btn-danger"
      disabled={pending}
      onClick={() => {
        if (confirm(`Kick ${memberName} from the faction? This cannot be undone.`)) {
          start(() => kickMember(charPlayerId, memberId))
        }
      }}
    >
      {pending ? 'Kicking…' : 'Kick from Faction'}
    </button>
  )
}
