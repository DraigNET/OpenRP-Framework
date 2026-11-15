'use client'

import { useTransition } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { deleteWeapon } from './actions'

interface FactionOpt { faction_id: number; faction_name: string }
interface TypeOpt { armory_type_id: number; faction_id: number; type_name: string }

/** Compact top toolbar: pick a faction and a type (both auto-open), or start a new type. */
export function ArmoryToolbar({ factions, types, selectedFaction, selectedType }: {
  factions: FactionOpt[]; types: TypeOpt[]; selectedFaction: number; selectedType: number
}) {
  const router = useRouter()
  const factionTypes = types.filter(t => t.faction_id === selectedFaction)
  return (
    <div className="acp-toolbar">
      <label className="acp-inline-label">Faction
        <select className="acp-input" value={selectedFaction}
          onChange={e => router.push(`/acp/factions/armory?faction_id=${e.target.value}`)}>
          {factions.map(f => <option key={f.faction_id} value={f.faction_id}>{f.faction_name} (#{f.faction_id})</option>)}
        </select>
      </label>
      <label className="acp-inline-label">Type
        <select className="acp-input" value={selectedType}
          onChange={e => router.push(`/acp/factions/armory?faction_id=${selectedFaction}&type_id=${e.target.value}`)}>
          {factionTypes.length === 0 && <option value={0}>No types yet</option>}
          {selectedType === 0 && factionTypes.length > 0 && <option value={0}>— Select a type —</option>}
          {factionTypes.map(t => <option key={t.armory_type_id} value={t.armory_type_id}>{t.type_name} (#{t.armory_type_id})</option>)}
        </select>
      </label>
      <span className="acp-toolbar-spacer" />
      <Link href={`/acp/factions/armory?faction_id=${selectedFaction}&type_id=0`} className="acp-btn acp-btn-primary"><i className="fa-solid fa-plus" /> New Type</Link>
    </div>
  )
}

export function DeleteWeaponButton({ rowId }: { rowId: number }) {
  const [pending, start] = useTransition()
  return (
    <button type="button" className="acp-btn acp-btn-sm" disabled={pending}
      onClick={() => { if (confirm('Delete this weapon row?')) start(() => deleteWeapon(rowId)) }}>
      {pending ? '…' : 'Delete'}
    </button>
  )
}
