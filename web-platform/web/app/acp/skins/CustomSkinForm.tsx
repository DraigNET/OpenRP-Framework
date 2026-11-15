'use client'

import { useActionState } from 'react'
import { uploadCustomSkin, type SkinUploadState } from './actions'

const INIT: SkinUploadState = { error: '', ok: false, message: '' }

export default function CustomSkinForm() {
  const [state, action, pending] = useActionState(uploadCustomSkin, INIT)
  return (
    <form action={action} className="acp-form" style={{ maxWidth: 'none' }}>
      {state.error && <div className="acp-form-error">{state.error}</div>}
      {state.ok && <div className="acp-form-ok">{state.message}</div>}

      <div className="acp-fs-row">
        <div className="acp-field">
          <label>Character Name</label>
          <input name="character_name" className="acp-input" placeholder="Firstname_Lastname" required />
        </div>
        <div className="acp-field">
          <label>Base Skin ID</label>
          <input name="base_skin_id" type="number" min={0} max={311} className="acp-input" placeholder="0–311 (not 74)" required />
        </div>
      </div>

      <div className="acp-fs-row">
        <div className="acp-field">
          <label>DFF File</label>
          <input name="dff_file" type="file" accept=".dff" required className="acp-input" />
        </div>
        <div className="acp-field">
          <label>TXD File</label>
          <input name="txd_file" type="file" accept=".txd" required className="acp-input" />
        </div>
      </div>

      <div>
        <button type="submit" className="acp-btn acp-btn-primary" disabled={pending}>
          <i className="fa-solid fa-upload" /> {pending ? 'Uploading…' : 'Upload Skin'}
        </button>
      </div>
    </form>
  )
}
