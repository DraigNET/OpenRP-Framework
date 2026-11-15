'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { saveLocker } from './actions'
import { squadOptions } from '@/lib/constants'

interface FactionOpt { faction_id: number; faction_name: string }
interface TypeOpt { armory_type_id: number; faction_id: number; type_name: string; type_enabled: number }
interface EditLocker { armory_id: number; faction_id: number; armory_type_id: number; armory_name: string; armory_desc: string; armory_enabled: number; armory_squad: number }

export function LockerForm({ factions, types, editing, selectedFaction, squadsByFaction }: {
  factions: FactionOpt[]; types: TypeOpt[]; editing: EditLocker | null; selectedFaction: number; squadsByFaction: Record<number, Record<number, string>>
}) {
  const [faction, setFaction] = useState(editing?.faction_id ?? selectedFaction)
  const factionTypes = types.filter(t => t.faction_id === faction)
  const squadChoices = squadOptions(squadsByFaction[faction] ?? {}, editing && editing.faction_id === faction ? editing.armory_squad : 0)

  return (
    <form action={saveLocker} className="acp-form-row">
      <input type="hidden" name="armory_id" value={editing?.armory_id ?? 0} />
      <div className="acp-field" style={{ minWidth: 220 }}>
        <label>Faction</label>
        <select name="faction_id" value={faction} onChange={e => setFaction(Number(e.target.value))} className="acp-input">
          {factions.map(f => <option key={f.faction_id} value={f.faction_id}>{f.faction_name} (#{f.faction_id})</option>)}
        </select>
      </div>
      <div className="acp-field" style={{ minWidth: 200 }}>
        <label>Armory Type</label>
        <select key={faction} name="armory_type_id" defaultValue={editing?.armory_type_id} className="acp-input" required>
          {factionTypes.length === 0 && <option value="">No types — create one first</option>}
          {factionTypes.map(t => <option key={t.armory_type_id} value={t.armory_type_id}>{t.type_name}{t.type_enabled === 1 ? '' : ' (disabled)'}</option>)}
        </select>
      </div>
      <div className="acp-field" style={{ minWidth: 180 }}><label>Name</label><input name="armory_name" maxLength={64} required defaultValue={editing?.armory_name ?? ''} className="acp-input" placeholder="Main Armory" /></div>
      <div className="acp-field" style={{ flex: 1, minWidth: 220 }}><label>Description <span style={{ fontWeight: 400, color: 'var(--acp-text-3)' }}>(optional)</span></label><input name="armory_desc" maxLength={128} defaultValue={editing?.armory_desc ?? ''} className="acp-input" /></div>
      <div className="acp-field" style={{ minWidth: 180 }}>
        <label>Squad <span style={{ fontWeight: 400, color: 'var(--acp-text-3)' }}>(who can use it)</span></label>
        <select key={faction} name="armory_squad" defaultValue={editing && editing.faction_id === faction ? editing.armory_squad : 0} className="acp-input" title="Only members of this squad can use the locker. Anyone means a general locker, which full-time Fire/EMT cannot use.">
          <option value={0}>Anyone (general locker)</option>
          {squadChoices.map(([k, v]) => <option key={k} value={k}>{v}</option>)}
        </select>
      </div>
      <label className="acp-flag" style={{ width: 'auto' }}><input type="checkbox" name="armory_enabled" defaultChecked={!editing || editing.armory_enabled === 1} /> <span>Enabled</span></label>
      <div className="acp-actions">
        <button type="submit" className="acp-btn acp-btn-primary">{editing ? 'Save Locker' : 'Create Locker'}</button>
        {editing && <Link href={`/acp/factions/lockers?faction_id=${faction}`} className="acp-btn">Cancel</Link>}
      </div>
    </form>
  )
}

export function HelpGuide() {
  const [open, setOpen] = useState(false)

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false) }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [open])

  return (
    <>
      <button type="button" className="acp-btn" onClick={() => setOpen(true)}><i className="fa-solid fa-circle-question" /> Help Guide</button>
      {open && (
        <div className="acp-modal-backdrop" role="presentation" onClick={e => { if (e.target === e.currentTarget) setOpen(false) }}>
          <div className="acp-panel acp-modal" role="dialog" aria-modal="true" aria-label="Armory Locker Guide">
            <div className="acp-panel-head">
              <span><i className="fa-solid fa-box" style={{ marginRight: 8, color: 'var(--acp-accent)' }} />Armory Locker Guide</span>
              <button type="button" className="acp-modal-close" onClick={() => setOpen(false)} aria-label="Close"><i className="fa-solid fa-xmark" /></button>
            </div>
            <div className="acp-modal-body">
              <div className="acp-help-grid">
                <section>
                  <h4><i className="fa-solid fa-list-ol" />Workflow</h4>
                  <ol>
                    <li>Create or confirm the faction&apos;s <strong>armory type</strong> on the Armory Types page.</li>
                    <li>Create the <strong>locker</strong> here with its faction, type, name, description and enabled state.</li>
                    <li>In-game, stand at the desired spot and use <code>/armoryplace [armory id]</code>.</li>
                    <li>Run <code>/reloadarmories</code> in-game after any ACP edit so the server reloads locker, type and weapon data.</li>
                  </ol>
                </section>

                <section>
                  <h4><i className="fa-solid fa-pen-to-square" />Locker Fields</h4>
                  <ul>
                    <li><strong>Faction</strong> — the faction that owns and can use this locker.</li>
                    <li><strong>Armory Type</strong> — the loadout used by this locker. Must belong to the selected faction.</li>
                    <li><strong>Name</strong> — the visible locker label shown in-game.</li>
                    <li><strong>Description</strong> — optional text under the name, often command hints.</li>
                    <li><strong>Squad</strong> — only members of this squad can use the locker. Choose <em>Anyone</em> for a general locker, which full-time Fire/EMT cannot use.</li>
                    <li><strong>Enabled</strong> — disabled lockers stay configured but spawn no pickup or label.</li>
                  </ul>
                </section>

                <section>
                  <h4><i className="fa-solid fa-gun" />Armory Types</h4>
                  <p>Types are <strong>per-faction, not global</strong> — LSPD Standard and LSSD Standard are separate rows. Special units like SWAT are created as armory types under their parent faction.</p>
                  <p>Weapon availability is edited from the Armory Types page; a locker only chooses which type loadout it uses.</p>
                </section>

                <section>
                  <h4><i className="fa-solid fa-location-dot" />Placement</h4>
                  <p>New lockers start at <code>0, 0, -1000</code>, which marks them <strong>Unplaced</strong> and keeps them under the map until placed in-game.</p>
                  <p>Placing a locker only changes its position, interior and virtual world — all other edits stay in the ACP.</p>
                </section>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
