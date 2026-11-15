'use client'

import { useState, useTransition } from 'react'
import { deleteCustomSkin } from './actions'

export default function DeleteSkinButton({ skinId, label }: { skinId: number; label: string }) {
  const [pending, start] = useTransition()
  const [error, setError] = useState('')
  return (
    <>
      <button
        type="button"
        className="acp-btn acp-btn-danger acp-btn-sm"
        disabled={pending}
        onClick={() => {
          if (!confirm(`Delete ${label}? This removes the DFF/TXD files from the server.`)) return
          start(async () => setError((await deleteCustomSkin(skinId)).error))
        }}
      >
        {pending ? '…' : 'Delete'}
      </button>
      {error && <div className="acp-form-error" style={{ marginTop: 6 }}>{error}</div>}
    </>
  )
}
