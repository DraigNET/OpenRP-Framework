'use client'

import { useActionState, useState } from 'react'
import { squadOptions } from '@/lib/constants'
import { updateCharacter, type CharEditState } from './actions'

const INIT: CharEditState = { error: '', ok: false }

export interface CharValues {
  player_id: number
  player_name: string
  player_cash: number; player_bankcash: number; player_savings: number
  player_level: number; player_hours: number
  player_factionid: number; player_factionrank: string; player_factiontier: number
  player_factionsquad: number; player_factionsquad2: number; player_factionsquad3: number
  player_factionbadge: number
  player_driverslicense: number; player_gunlicense: number; player_ccwlicense: number
  player_outstanding_fines: number; player_ajail_time: number
}

const Num = ({ name, label, v }: { name: string; label: string; v: number }) => (
  <div className="acp-field"><label>{label}</label><input name={name} type="number" defaultValue={v} className="acp-input" /></div>
)

export default function CharacterEditForm({ v, squadsByFaction }: { v: CharValues; squadsByFaction: Record<number, Record<number, string>> }) {
  const [state, action, pending] = useActionState(updateCharacter, INIT)
  const [factionId, setFactionId] = useState(v.player_factionid)
  const squadMap = squadsByFaction[factionId] ?? {}
  const squadSelect = (name: string, label: string, cur: number) => (
    <div className="acp-field"><label>{label}</label>
      {Object.keys(squadMap).length > 0 || cur ? (
        <select key={factionId} name={name} defaultValue={cur} className="acp-input">
          <option value={0}>None</option>
          {squadOptions(squadMap, cur).map(([k, n]) => <option key={k} value={k}>{n}</option>)}
        </select>
      ) : <input name={name} type="number" defaultValue={cur} className="acp-input" />}
    </div>
  )
  return (
    <form action={action} className="acp-form" style={{ maxWidth: 720 }}>
      <input type="hidden" name="player_id" value={v.player_id} />
      {state.error && <div className="acp-form-error">{state.error}</div>}
      {state.ok && <div className="acp-form-ok">Character saved.</div>}

      <div className="acp-field"><label>Name</label><input name="player_name" defaultValue={v.player_name} className="acp-input" /></div>

      <div className="acp-fs-row"><Num name="player_cash" label="Cash" v={v.player_cash} /><Num name="player_bankcash" label="Bank" v={v.player_bankcash} /></div>
      <div className="acp-fs-row"><Num name="player_savings" label="Savings" v={v.player_savings} /><Num name="player_outstanding_fines" label="Outstanding Fines" v={v.player_outstanding_fines} /></div>
      <div className="acp-fs-row"><Num name="player_level" label="Level" v={v.player_level} /><Num name="player_hours" label="Hours" v={v.player_hours} /></div>

      <div className="acp-fs-row"><div className="acp-field"><label>Faction ID</label><input name="player_factionid" type="number" value={factionId} onChange={e => setFactionId(Number(e.target.value) || 0)} className="acp-input" /></div>
        <div className="acp-field"><label>Faction Rank</label><input name="player_factionrank" defaultValue={v.player_factionrank} className="acp-input" /></div></div>
      <div className="acp-fs-row"><Num name="player_factiontier" label="Faction Tier" v={v.player_factiontier} /><Num name="player_factionbadge" label="Badge" v={v.player_factionbadge} /></div>
      <div className="acp-fs-row">{squadSelect('player_factionsquad', 'Squad 1', v.player_factionsquad)}{squadSelect('player_factionsquad2', 'Squad 2', v.player_factionsquad2)}{squadSelect('player_factionsquad3', 'Squad 3', v.player_factionsquad3)}</div>
      <div className="acp-fs-row"><Num name="player_ajail_time" label="Admin Jail (sec)" v={v.player_ajail_time} /></div>

      <div className="acp-flag-grid">
        <label className="acp-flag"><input type="checkbox" name="player_driverslicense" defaultChecked={v.player_driverslicense === 1} /> <span>Driver License</span></label>
        <label className="acp-flag"><input type="checkbox" name="player_gunlicense" defaultChecked={v.player_gunlicense === 1} /> <span>Gun License</span></label>
        <label className="acp-flag"><input type="checkbox" name="player_ccwlicense" defaultChecked={v.player_ccwlicense === 1} /> <span>CCW License</span></label>
      </div>

      <div><button type="submit" className="acp-btn acp-btn-primary" disabled={pending}>{pending ? 'Saving…' : 'Save Character'}</button></div>
    </form>
  )
}
