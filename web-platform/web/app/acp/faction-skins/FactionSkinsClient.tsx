'use client'

import { useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { uploadModel, toggleModel, deleteUsable, updateBaseSkin, type UploadState } from './actions'
import { FSKIN_MIN_ID, FSKIN_MAX_ID } from '@/lib/faction-skins'

interface FactionOpt { faction_id: number; faction_name: string }

export function FactionFilter({ factions, selected, tab }: { factions: FactionOpt[]; selected: number; tab?: string }) {
  const router = useRouter()
  return (
    <select
      className="acp-input"
      style={{ maxWidth: 320 }}
      value={selected}
      onChange={e => router.push(`/acp/faction-skins?faction_id=${e.target.value}${tab ? `&tab=${tab}` : ''}`)}
    >
      {factions.map(f => (
        <option key={f.faction_id} value={f.faction_id}>{f.faction_name} (#{f.faction_id})</option>
      ))}
    </select>
  )
}

const UPLOAD_INIT: UploadState = { error: '', ok: false, message: '' }

interface Row {
  dff: File
  txd?: File
  base: string
  skinId: string
  status: 'idle' | 'uploading' | 'ok' | 'error'
  msg: string
}

interface Batch { rows: Row[]; txds: File[] }

const stem = (f: File) => f.name.replace(/\.(dff|txd)$/i, '').toLowerCase()

// Pair each unpaired DFF with an unused TXD of the same name.
function autoPair(b: Batch): Batch {
  const used = new Set(b.rows.map(r => r.txd?.name))
  const rows = b.rows.map(r => {
    if (r.txd) return r
    const match = b.txds.find(t => !used.has(t.name) && stem(t) === stem(r.dff))
    if (!match) return r
    used.add(match.name)
    return { ...r, txd: match }
  })
  return { ...b, rows }
}

export function UploadForm({ factionId, nextId }: { factionId: number; nextId: number | null }) {
  const [batch, setBatch] = useState<Batch>({ rows: [], txds: [] })
  const [defaultBase, setDefaultBase] = useState('')
  const [subfolder, setSubfolder] = useState('')
  const [enabled, setEnabled] = useState(true)
  const [busy, setBusy] = useState(false)
  const [picker, setPicker] = useState(0) // bump to reset the file input

  const { rows, txds } = batch

  function addFiles(list: FileList | null) {
    if (!list) return
    const files = Array.from(list)
    setBatch(prev => {
      const next: Batch = { rows: [...prev.rows], txds: [...prev.txds] }
      for (const f of files) {
        const ext = f.name.split('.').pop()?.toLowerCase()
        if (ext === 'dff' && !next.rows.some(r => r.dff.name === f.name)) {
          next.rows.push({ dff: f, base: defaultBase, skinId: '', status: 'idle', msg: '' })
        } else if (ext === 'txd' && !next.txds.some(t => t.name === f.name)) {
          next.txds.push(f)
        }
      }
      return autoPair(next)
    })
    setPicker(n => n + 1)
  }

  const patch = (name: string, p: Partial<Row>) =>
    setBatch(prev => ({ ...prev, rows: prev.rows.map(r => (r.dff.name === name ? { ...r, ...p } : r)) }))

  const setTxd = (name: string, txdName: string) =>
    patch(name, { txd: txds.find(t => t.name === txdName), status: 'idle', msg: '' })

  const usedTxd = new Set(rows.map(r => r.txd?.name))
  const unusedTxds = txds.filter(t => !usedTxd.has(t.name))
  const baseOk = (r: Row) => /^\d+$/.test(r.base) && Number(r.base) >= 1 && Number(r.base) <= 311
  const ready = rows.filter(r => r.status !== 'ok' && r.txd && baseOk(r))

  async function uploadAll() {
    setBusy(true)
    for (const r of ready) {
      patch(r.dff.name, { status: 'uploading', msg: '' })
      const fd = new FormData()
      fd.set('faction_id', String(factionId))
      fd.set('base_skin_id', r.base)
      fd.set('skin_id', r.skinId)
      fd.set('subfolder', subfolder)
      if (enabled) fd.set('enabled', '1')
      fd.set('dff_file', r.dff)
      fd.set('txd_file', r.txd!)
      try {
        const res = await uploadModel(UPLOAD_INIT, fd)
        patch(r.dff.name, res.ok ? { status: 'ok', msg: res.message } : { status: 'error', msg: res.error })
      } catch (e) {
        patch(r.dff.name, { status: 'error', msg: (e as Error).message })
      }
    }
    setBusy(false)
  }

  const okCount = rows.filter(r => r.status === 'ok').length

  return (
    <div className="acp-form" style={{ maxWidth: 'none' }}>
      <div className="acp-fs-row">
        <div className="acp-field">
          <label>Default Base Skin ID</label>
          <input
            type="number" min={1} max={311} className="acp-input" placeholder="1-311"
            value={defaultBase}
            onChange={e => {
              const v = e.target.value
              setDefaultBase(v)
              setBatch(prev => ({
                ...prev,
                rows: prev.rows.map(r => (r.status === 'ok' || r.base !== defaultBase ? r : { ...r, base: v })),
              }))
            }}
          />
          <span className="acp-field-hint">Applied to every row you have not edited. Override per row below.</span>
        </div>
        <div className="acp-field">
          <label>Optional Subfolder</label>
          <input
            pattern="[A-Za-z0-9_-]*" className="acp-input" placeholder="e.g. seb"
            value={subfolder} onChange={e => setSubfolder(e.target.value)}
          />
          <span className="acp-field-hint">{nextId !== null ? `Blank custom IDs are auto-assigned, starting at ${nextId}.` : 'No custom IDs available'}</span>
        </div>
      </div>

      <div className="acp-field">
        <label>DFF / TXD Files</label>
        <input
          key={picker} type="file" multiple accept=".dff,.txd" className="acp-input"
          onChange={e => addFiles(e.target.files)} disabled={busy}
        />
        <span className="acp-field-hint">Select all your .dff and .txd files at once. Files with matching names are paired automatically; for any others, choose the TXD from the dropdown on that row.</span>
      </div>

      {rows.length > 0 && (
        <table className="acp-table">
          <thead>
            <tr><th>DFF</th><th>TXD</th><th>Base</th><th>Custom ID</th><th>Status</th><th /></tr>
          </thead>
          <tbody>
            {rows.map(r => {
              const locked = busy || r.status === 'ok'
              return (
                <tr key={r.dff.name}>
                  <td className="acp-mono">{r.dff.name}</td>
                  <td>
                    <select
                      className="acp-input" style={{ minWidth: 160 }}
                      value={r.txd?.name ?? ''} disabled={locked}
                      onChange={e => setTxd(r.dff.name, e.target.value)}
                    >
                      <option value="">— choose TXD —</option>
                      {r.txd && <option value={r.txd.name}>{r.txd.name}</option>}
                      {unusedTxds.map(t => <option key={t.name} value={t.name}>{t.name}</option>)}
                    </select>
                  </td>
                  <td>
                    <input
                      type="number" min={1} max={311} className="acp-input" style={{ width: 72 }}
                      value={r.base} disabled={locked}
                      onChange={e => patch(r.dff.name, { base: e.target.value })}
                    />
                  </td>
                  <td>
                    <input
                      type="number" className="acp-input" style={{ width: 90 }} placeholder="auto"
                      value={r.skinId} disabled={locked}
                      onChange={e => patch(r.dff.name, { skinId: e.target.value })}
                    />
                  </td>
                  <td style={{ fontSize: 12 }}>
                    {r.status === 'uploading' && 'Uploading…'}
                    {r.status === 'ok' && <span className="acp-badge is-green">{r.msg.split('.')[0]}</span>}
                    {r.status === 'error' && <span style={{ color: 'var(--acp-red)' }}>{r.msg}</span>}
                    {r.status === 'idle' && (
                      !r.txd ? <span className="acp-badge is-amber">Needs a TXD</span>
                        : !baseOk(r) ? <span className="acp-badge is-amber">Needs base skin (1-311)</span>
                        : 'Ready'
                    )}
                  </td>
                  <td>
                    {r.status !== 'uploading' && (
                      <button
                        type="button" className="acp-btn acp-btn-sm" disabled={busy}
                        onClick={() => setBatch(prev => ({ ...prev, rows: prev.rows.filter(x => x.dff.name !== r.dff.name) }))}
                      >✕</button>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      )}

      {unusedTxds.length > 0 && (
        <div className="acp-field-hint">
          Unassigned TXDs: <span className="acp-mono">{unusedTxds.map(t => t.name).join(', ')}</span>
          {rows.length === 0 && ' (add the matching DFFs)'}
        </div>
      )}

      <label className="acp-flag" style={{ maxWidth: 280 }}>
        <input type="checkbox" checked={enabled} onChange={e => setEnabled(e.target.checked)} />
        <span>Enabled for next server restart</span>
      </label>

      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <button type="button" className="acp-btn acp-btn-primary" disabled={busy || ready.length === 0} onClick={uploadAll}>
          <i className="fa-solid fa-upload" /> {busy ? 'Uploading…' : `Upload ${ready.length} Model${ready.length === 1 ? '' : 's'}`}
        </button>
        {okCount > 0 && !busy && (
          <span className="acp-form-ok" style={{ margin: 0 }}>{okCount} uploaded. Restart the server before they load.</span>
        )}
      </div>
    </div>
  )
}

export function ToggleModelButton({ modelId, enabled }: { modelId: number; enabled: boolean }) {
  const [pending, start] = useTransition()
  return (
    <button
      type="button"
      className={`acp-btn acp-btn-sm ${enabled ? 'acp-btn-danger' : ''}`}
      disabled={pending}
      onClick={() => start(() => toggleModel(modelId, !enabled))}
    >
      {pending ? '…' : enabled ? 'Disable' : 'Enable'}
    </button>
  )
}

export function BaseSkinEditor({ modelId, baseId }: { modelId: number; baseId: number }) {
  const [pending, start] = useTransition()
  const [value, setValue] = useState(String(baseId))
  const [error, setError] = useState('')
  const dirty = value !== String(baseId)

  function save() {
    setError('')
    start(async () => {
      const res = await updateBaseSkin(modelId, Number(value))
      if (res.error) setError(res.error)
    })
  }

  return (
    <form
      className="acp-inline-form"
      onSubmit={e => { e.preventDefault(); if (dirty) save() }}
      title={error || undefined}
    >
      <input
        type="text" inputMode="numeric" pattern="[0-9]*" maxLength={3} required
        value={value}
        onChange={e => setValue(e.target.value.replace(/\D/g, ''))}
        className="acp-input"
        style={{ width: 64, ...(error ? { borderColor: 'var(--acp-danger, #e5484d)' } : {}) }}
      />
      {dirty && (
        <button type="submit" className="acp-btn acp-btn-sm" disabled={pending}>{pending ? '…' : 'Save'}</button>
      )}
    </form>
  )
}

export function DeleteUsableButton({ rowId }: { rowId: number }) {
  const [pending, start] = useTransition()
  return (
    <button
      type="button"
      className="acp-btn acp-btn-danger acp-btn-sm"
      disabled={pending}
      onClick={() => { if (confirm('Remove this skin from faction availability?')) start(() => deleteUsable(rowId)) }}
    >
      {pending ? '…' : 'Remove'}
    </button>
  )
}
