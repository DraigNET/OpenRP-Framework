'use client'

import { useTransition } from 'react'
import { deleteOwnedVehicle } from './actions'

export default function DeleteVehicleButton({ charId, sqlId }: { charId: number; sqlId: number }) {
  const [pending, start] = useTransition()
  return (
    <button type="button" className="acp-btn acp-btn-danger acp-btn-sm" disabled={pending}
      onClick={() => { if (confirm('Delete this vehicle permanently?')) start(() => deleteOwnedVehicle(charId, sqlId)) }}>
      {pending ? '…' : 'Delete'}
    </button>
  )
}
