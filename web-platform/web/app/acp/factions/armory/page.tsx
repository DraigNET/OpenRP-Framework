import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL, squadsForFaction, squadOptions } from '@/lib/constants'
import { armoryWeaponName, ARMORY_WEAPON_OPTIONS } from '@/lib/armory-weapons'
import { ArmoryToolbar, DeleteWeaponButton } from './ArmoryButtons'
import { saveType, saveWeapon } from './actions'

export const dynamic = 'force-dynamic'

const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''

export default async function ArmoryTypesPage({ searchParams }: PageProps<'/acp/factions/armory'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const sp = await searchParams

  const factions = await prisma.faction.findMany({ select: { faction_id: true, faction_name: true, faction_type: true, faction_abbrev: true }, orderBy: [{ faction_name: 'asc' }] })
  if (factions.length === 0) return <div className="acp-empty"><i className="fa-solid fa-shield-halved" />No factions.</div>

  const types = await prisma.factionArmoryType.findMany({ orderBy: [{ type_name: 'asc' }, { armory_type_id: 'asc' }] })

  let selectedFaction = Number(firstParam(sp.faction_id)) || 0
  if (!factions.some(f => f.faction_id === selectedFaction)) selectedFaction = factions[0].faction_id

  // type_id=0 explicitly means "create new"; anything else resolves to a real type.
  const creating = firstParam(sp.type_id) === '0'
  let selectedTypeId = Number(firstParam(sp.type_id)) || 0
  let selectedType = creating ? null : (types.find(t => t.armory_type_id === selectedTypeId && t.faction_id === selectedFaction) ?? null)
  if (!creating && !selectedType) { selectedType = types.find(t => t.faction_id === selectedFaction) ?? null; selectedTypeId = selectedType?.armory_type_id ?? 0 }
  else if (selectedType) selectedTypeId = selectedType.armory_type_id

  const editWeaponId = Number(firstParam(sp.edit_weapon)) || 0
  const editingWeapon = editWeaponId > 0 ? await prisma.factionArmoryWeapon.findUnique({ where: { armory_weapon_id: editWeaponId } }) : null

  // Type weapons + faction-wide legacy (null type), legacy listed last.
  const weapons = selectedType
    ? await prisma.factionArmoryWeapon.findMany({
        where: { OR: [{ armory_type_id: selectedType.armory_type_id }, { armory_type_id: null, faction_id: selectedFaction }] },
      })
    : []
  weapons.sort((a, b) =>
    (a.armory_type_id === null ? 1 : 0) - (b.armory_type_id === null ? 1 : 0) || a.sort_order - b.sort_order || a.armory_weapon_id - b.armory_weapon_id)

  const selectedFactionRow = factions.find(f => f.faction_id === selectedFaction)
  const squadMap = squadsForFaction(selectedFactionRow?.faction_type ?? -1, selectedFactionRow?.faction_abbrev)
  const factionTypeUrl = `/acp/factions/armory?faction_id=${selectedFaction}&type_id=${selectedTypeId}`
  const enabledCount = weapons.filter(w => w.weapon_enabled === 1).length

  return (
    <>
      <ArmoryToolbar factions={factions} types={types} selectedFaction={selectedFaction} selectedType={creating ? 0 : selectedTypeId} />

      {/* Type editor — compact horizontal form */}
      <section className="acp-panel">
        <div className="acp-panel-head">
          <span>{selectedType ? `Edit Type #${selectedType.armory_type_id} — ${selectedType.type_name}` : 'Create New Type'}</span>
          <Link href="/acp/factions/lockers" className="acp-panel-link"><i className="fa-solid fa-box" /> Lockers</Link>
        </div>
        {/* key remounts the form when the faction/type changes, so the uncontrolled faction select can't keep a stale value */}
        <form key={`${selectedFaction}-${selectedType?.armory_type_id ?? 0}`} action={saveType} className="acp-form-row">
          <input type="hidden" name="armory_type_id" value={selectedType?.armory_type_id ?? 0} />
          <div className="acp-field" style={{ minWidth: 220 }}>
            <label>Type Name</label>
            <input name="type_name" maxLength={32} required defaultValue={selectedType?.type_name ?? ''} className="acp-input" placeholder="Standard" />
          </div>
          <div className="acp-field" style={{ minWidth: 240 }}>
            <label>Faction</label>
            <select name="faction_id" defaultValue={selectedFaction} className="acp-input">
              {factions.map(f => <option key={f.faction_id} value={f.faction_id}>{f.faction_name} (#{f.faction_id})</option>)}
            </select>
          </div>
          <label className="acp-flag" style={{ width: 'auto' }}><input type="checkbox" name="type_enabled" defaultChecked={!selectedType || selectedType.type_enabled === 1} /> <span>Enabled</span></label>
          <div className="acp-actions">
            <button type="submit" className="acp-btn acp-btn-primary">{selectedType ? 'Save Type' : 'Create Type'}</button>
            {selectedType && <Link href={`/acp/factions/armory?faction_id=${selectedFaction}&type_id=0`} className="acp-btn">New Type</Link>}
          </div>
        </form>
      </section>

      {selectedType && (
        <section className="acp-panel" style={{ marginTop: 14 }}>
          <div className="acp-panel-head">
            <span>Weapons — {selectedType.type_name}</span>
            <span className="acp-panel-link">{weapons.length} total · {enabledCount} enabled</span>
          </div>

          {/* Add / edit weapon — inline above the table. The key remounts the form when a different row is picked so the fields fill in with that row. */}
          <form key={`${selectedType.armory_type_id}-${editingWeapon?.armory_weapon_id ?? 0}`} action={saveWeapon} className="acp-form-row acp-form-divider">
            <input type="hidden" name="armory_type_id" value={selectedType.armory_type_id} />
            <input type="hidden" name="armory_weapon_id" value={editingWeapon?.armory_weapon_id ?? 0} />
            <div className="acp-field" style={{ minWidth: 200 }}>
              <label>{editingWeapon ? `Editing row #${editingWeapon.armory_weapon_id}` : 'Weapon'}</label>
              <input name="weapon_id" type="number" list="armoryWeapons" required defaultValue={editingWeapon?.weapon_id ?? 28} className="acp-input" />
              <datalist id="armoryWeapons">{ARMORY_WEAPON_OPTIONS.map(o => <option key={o.id} value={o.id}>{o.name}</option>)}</datalist>
            </div>
            <div className="acp-field" style={{ width: 96 }}><label>Ammo</label><input name="weapon_ammo" type="number" min={1} required defaultValue={editingWeapon?.weapon_ammo ?? 1} className="acp-input" /></div>
            <div className="acp-field" style={{ width: 88 }}><label>Tier</label><input name="tier_limit" type="number" min={0} max={10} required defaultValue={editingWeapon?.tier_limit ?? 0} className="acp-input" /></div>
            <div className="acp-field" style={{ width: 150 }}><label>Squad</label><select name="squad_id" defaultValue={editingWeapon?.squad_id ?? 0} className="acp-input">
              <option value={0}>None</option>
              {squadOptions(squadMap, editingWeapon?.squad_id ?? 0).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
            </select></div>
            <div className="acp-field" style={{ width: 88 }}><label>Sort</label><input name="sort_order" type="number" min={0} required defaultValue={editingWeapon?.sort_order ?? 0} className="acp-input" /></div>
            <label className="acp-flag" style={{ width: 'auto' }}><input type="checkbox" name="off_duty_allowed" defaultChecked={editingWeapon?.off_duty_allowed === 1} /> <span>Off-duty</span></label>
            <label className="acp-flag" style={{ width: 'auto' }}><input type="checkbox" name="weapon_enabled" defaultChecked={!editingWeapon || editingWeapon.weapon_enabled === 1} /> <span>Enabled</span></label>
            <div className="acp-actions">
              <button type="submit" className="acp-btn acp-btn-primary">{editingWeapon ? 'Save Weapon' : 'Add Weapon'}</button>
              {editingWeapon && <Link href={factionTypeUrl} className="acp-btn">Cancel</Link>}
            </div>
          </form>

          {weapons.length === 0 ? (
            <div className="acp-empty"><i className="fa-solid fa-gun" />No weapons assigned to this type yet.</div>
          ) : (
            <table className="acp-table">
              <thead><tr><th>ID</th><th>Scope</th><th>Weapon</th><th>Ammo</th><th>Tier</th><th>Squad</th><th>Off Duty</th><th>Status</th><th>Sort</th><th style={{ textAlign: 'right' }}>Actions</th></tr></thead>
              <tbody>
                {weapons.map(w => {
                  const legacy = w.armory_type_id === null
                  return (
                    <tr key={w.armory_weapon_id}>
                      <td className="acp-td-muted">{w.armory_weapon_id}</td>
                      <td>{legacy ? <span className="acp-badge is-amber">Faction-wide legacy</span> : <span className="acp-td-muted">{selectedType!.type_name}</span>}</td>
                      <td><b>{armoryWeaponName(w.weapon_id)}</b> <span className="acp-td-muted">#{w.weapon_id}</span></td>
                      <td className="acp-td-muted">{w.weapon_ammo}</td>
                      <td className="acp-td-muted">{w.tier_limit === 0 ? 'None' : w.tier_limit}</td>
                      <td className="acp-td-muted">{w.squad_id === 0 ? 'None' : (squadMap[w.squad_id] ?? w.squad_id)}</td>
                      <td>{w.off_duty_allowed === 1 ? <span className="acp-badge is-green">Yes</span> : <span className="acp-td-muted">No</span>}</td>
                      <td>{w.weapon_enabled === 1 ? <span className="acp-badge is-green">Enabled</span> : <span className="acp-badge is-off">Disabled</span>}</td>
                      <td className="acp-td-muted">{w.sort_order}</td>
                      <td style={{ textAlign: 'right' }}>
                        <div style={{ display: 'inline-flex', gap: 6, alignItems: 'center' }}>
                          <Link href={`/acp/factions/armory?faction_id=${selectedFaction}&type_id=${selectedTypeId}&edit_weapon=${w.armory_weapon_id}`} className="acp-btn acp-btn-sm">{legacy ? 'Edit / Assign' : 'Edit'}</Link>
                          <DeleteWeaponButton rowId={w.armory_weapon_id} />
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </section>
      )}
    </>
  )
}
