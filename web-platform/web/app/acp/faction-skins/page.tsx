import Link from 'next/link'
import { env } from '@/lib/env'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { FSKIN_MIN_ID, FSKIN_MAX_ID, FSKIN_RESERVED, fskinTierName, fskinInRange } from '@/lib/faction-skins'
import { squadsForFaction, squadOptions } from '@/lib/constants'
import { FactionFilter, UploadForm, BaseSkinEditor, ToggleModelButton, DeleteUsableButton } from './FactionSkinsClient'
import { addUsable, updateAllUsable, setLockerTypeForUntyped } from './actions'
import { ToastForm } from './ToastForm'

export const dynamic = 'force-dynamic'

const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''

export default async function FactionSkinsPage({ searchParams }: PageProps<'/acp/faction-skins'>) {
  await requireStaff(ADMIN_LVL.MANAGER)

  const factions = await prisma.faction.findMany({
    select: { faction_id: true, faction_name: true, faction_type: true, faction_abbrev: true },
    orderBy: [{ faction_name: 'asc' }, { faction_id: 'asc' }],
  })
  if (factions.length === 0) {
    return <div className="acp-empty"><i className="fa-solid fa-users-gear" />No factions in the database.</div>
  }

  const sp = await searchParams
  const wanted = Number(firstParam(sp.faction_id))
  const tab: 'models' | 'usable' = firstParam(sp.tab) === 'models' && env.customSkinsEnabled ? 'models' : 'usable'
  const selected = factions.find(f => f.faction_id === wanted) ?? factions[0]
  const selectedId = selected.faction_id
  const squadMap = squadsForFaction(selected.faction_type, selected.faction_abbrev)

  // Next available custom ID
  const rangeRows = await prisma.factionCustomModel.findMany({
    where: { faction_model_skinid: { gte: FSKIN_MIN_ID, lte: FSKIN_MAX_ID } },
    select: { faction_model_skinid: true },
  })
  const usedIds = new Set(rangeRows.map(r => r.faction_model_skinid))
  for (const id of Object.keys(FSKIN_RESERVED)) usedIds.add(Number(id))
  let nextId: number | null = null
  for (let id = FSKIN_MIN_ID; id <= FSKIN_MAX_ID; id++) { if (!usedIds.has(id)) { nextId = id; break } }

  const [models, usable] = await Promise.all([
    prisma.factionCustomModel.findMany({ where: { faction_model_factionid: selectedId }, orderBy: { faction_model_skinid: 'asc' } }),
    prisma.factionSkin.findMany({
      where: { faction_skin_factionid: selectedId },
      orderBy: [{ faction_skin_skinid: 'asc' }, { faction_skin_tier: 'asc' }, { faction_skin_squad: 'asc' }],
    }),
  ])

  // usable-count per model (this faction)
  const usableBySkin = new Map<number, number>()
  for (const u of usable) usableBySkin.set(u.faction_skin_skinid, (usableBySkin.get(u.faction_skin_skinid) ?? 0) + 1)

  // model status for the usable table (this faction + any faction)
  const thisModelEnabled = new Map(models.map(m => [m.faction_model_skinid, m.faction_model_enabled === 1]))
  const usableSkinIds = [...new Set(usable.map(u => u.faction_skin_skinid))]
  const anyModels = usableSkinIds.length
    ? await prisma.factionCustomModel.findMany({ where: { faction_model_skinid: { in: usableSkinIds } } })
    : []
  const anyModelBySkin = new Map(anyModels.map(m => [m.faction_model_skinid, m]))
  const otherFactionIds = [...new Set(anyModels.map(m => m.faction_model_factionid))]
  const facNames = new Map(factions.filter(f => otherFactionIds.includes(f.faction_id)).map(f => [f.faction_id, f.faction_name]))

  return (
    <>
      <div className="acp-toolbar">
        <span className="acp-toolbar-spacer" />
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12.5, color: 'var(--acp-text-2)' }}>
          Faction <FactionFilter factions={factions} selected={selectedId} tab={tab} />
        </label>
      </div>

      <div className="acp-fs-grid">
        <section className="acp-panel">
          <div className="acp-panel-head"><span>Upload Server Model</span></div>
          <div style={{ padding: 14 }}>
            {env.customSkinsEnabled ? <UploadForm factionId={selectedId} nextId={nextId} /> : <p className="acp-empty">Custom model uploads are disabled. Stock uniforms can be managed below. Enable both custom-skin feature flags only when you want to add model files.</p>}
          </div>
        </section>

        <section className="acp-panel">
          <div className="acp-panel-head"><span>Deployment Notes</span></div>
          <div className="acp-kv">
            <div className="acp-kv-row"><span>SA-MP path</span><b className="acp-mono">skins_faction/{selectedId}/</b></div>
            <div className="acp-kv-row"><span>Enabled cap</span><b>{FSKIN_MIN_ID}–{FSKIN_MAX_ID}</b></div>
          </div>
          <div style={{ padding: '10px 14px', fontSize: 11.5, color: 'var(--acp-text-3)', lineHeight: 1.7 }}>
            • Uploads require a server restart before loading.<br />
            • Availability changes require <span className="acp-mono">/reloadfskins</span>.<br />
            • Reserved hardcoded IDs are skipped by the picker.
          </div>
        </section>
      </div>

      <div className="acp-tabbar" role="tablist" style={{ marginTop: 14, border: '1px solid var(--acp-line)', borderRadius: '10px 10px 0 0' }}>
        {env.customSkinsEnabled && <Link href={`/acp/faction-skins?faction_id=${selectedId}&tab=models`} className={`acp-tab${tab === 'models' ? ' is-active' : ''}`} role="tab" aria-selected={tab === 'models'}>Server Models ({models.length})</Link>}
        <Link href={`/acp/faction-skins?faction_id=${selectedId}&tab=usable`} className={`acp-tab${tab === 'usable' ? ' is-active' : ''}`} role="tab" aria-selected={tab === 'usable'}>Usable By Faction ({usable.length})</Link>
      </div>

      {tab === 'models' && (
      <section className="acp-panel" style={{ borderTopLeftRadius: 0, borderTopRightRadius: 0, borderTop: 0 }}>
        <div className="acp-panel-head"><span>Server Models — {models.length} · {selected.faction_name}</span></div>
        {models.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-shirt" />No custom models registered for this faction.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th>Custom ID</th><th>Base</th><th>DFF</th><th>TXD</th><th>Enabled</th><th>Usable</th><th>
                Actions
                <div style={{ display: 'flex', gap: 6, marginTop: 4, fontSize: 10.5, fontWeight: 500, color: 'var(--acp-text-3)' }}>
                  <span style={{ width: 50 }}>Tier</span><span style={{ width: 130 }}>Squad</span><span style={{ width: 60 }}>Locker</span>
                </div>
              </th></tr></thead>
            <tbody>
              {models.map(m => {
                const inRange = fskinInRange(m.faction_model_skinid)
                const en = m.faction_model_enabled === 1
                const uc = usableBySkin.get(m.faction_model_skinid) ?? 0
                return (
                  <tr key={m.faction_model_id}>
                    <td>{m.faction_model_skinid}</td>
                    <td><BaseSkinEditor key={m.faction_model_baseid} modelId={m.faction_model_id} baseId={m.faction_model_baseid} /></td>
                    <td className="acp-mono acp-td-muted">{m.faction_model_dff}</td>
                    <td className="acp-mono acp-td-muted">{m.faction_model_txd}</td>
                    <td>{!inRange
                      ? <span className="acp-badge is-amber" title={`Loader only accepts ${FSKIN_MIN_ID}-${FSKIN_MAX_ID}`}>Out of range</span>
                      : en ? <span className="acp-badge is-green">Yes</span> : <span className="acp-badge is-off">No</span>}</td>
                    <td>{uc > 0 ? <span className="acp-badge is-blue">{uc} row{uc === 1 ? '' : 's'}</span> : <span className="acp-td-muted">No</span>}</td>
                    <td>
                      <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                        <form action={addUsable} className="acp-inline-form">
                          <input type="hidden" name="faction_id" value={selectedId} />
                          <input type="hidden" name="skin_id" value={m.faction_model_skinid} />
                          <input name="tier" type="number" min={0} max={4} defaultValue={3} className="acp-input" style={{ width: 50 }} title="Tier" />
                          <select name="squad" defaultValue={0} className="acp-input" style={{ width: 130 }} title="Squad">
                            <option value={0}>No squad</option>
                            {squadOptions(squadMap).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                          </select>
                          <input name="locker_type" type="number" min={0} defaultValue={0} className="acp-input" style={{ width: 60 }} title="Locker type id (0 = every locker)" />
                          <button type="submit" className="acp-btn acp-btn-sm">Add Usable</button>
                        </form>
                        <ToggleModelButton modelId={m.faction_model_id} enabled={en} />
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
      {tab === 'usable' && (
      <section className="acp-panel" style={{ borderTopLeftRadius: 0, borderTopRightRadius: 0, borderTop: 0 }}>
        <div className="acp-panel-head" style={{ flexWrap: 'wrap', gap: 10 }}>
          <span>Usable By Faction — {usable.length} · {selected.faction_name}</span>
          <ToastForm id="usable-all" action={updateAllUsable} style={{ marginLeft: 'auto' }}>
            <input type="hidden" name="faction_id" value={selectedId} />
            <button type="submit" className="acp-btn acp-btn-primary acp-btn-sm">Save all changes</button>
          </ToastForm>
          <ToastForm action={setLockerTypeForUntyped} className="acp-inline-form" style={{ textTransform: 'none', letterSpacing: 0, fontWeight: 400 }}>
            <input type="hidden" name="faction_id" value={selectedId} />
            <span style={{ fontSize: 12, color: 'var(--acp-text-2)' }}>Rows set to &ldquo;Every locker&rdquo; &rarr; locker type</span>
            <input name="locker_type" type="number" min={1} required className="acp-input" style={{ width: 60 }} title="Locker type id" />
            <button type="submit" className="acp-btn acp-btn-sm">Apply to all</button>
          </ToastForm>
        </div>
        {usable.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-list-check" />No usable skins assigned to this faction.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th>Row</th><th>Skin ID</th><th>Model file</th><th>Tier</th><th>Squad</th><th>Locker type</th><th>Model</th><th>Actions</th></tr></thead>
            <tbody>
              {usable.map(s => {
                const sid = s.faction_skin_skinid
                let model: React.ReactNode
                if (thisModelEnabled.has(sid)) {
                  model = thisModelEnabled.get(sid)
                    ? <span className="acp-badge is-green">DB model</span>
                    : <span className="acp-badge is-off">Disabled model</span>
                } else if (sid <= 311) {
                  model = <span className="acp-td-muted">Standard GTA skin</span>
                } else if (anyModelBySkin.has(sid)) {
                  const am = anyModelBySkin.get(sid)!
                  model = <span className="acp-badge is-amber">Registered under {facNames.get(am.faction_model_factionid) ?? `#${am.faction_model_factionid}`}</span>
                } else {
                  model = <span className="acp-badge is-amber">Unmatched custom ID</span>
                }
                return (
                  <tr key={s.faction_skin_id}>
                    <td className="acp-td-muted">{s.faction_skin_id}</td>
                    <td>{sid}</td>
                    <td className="acp-mono">{anyModelBySkin.has(sid)
                      ? <span title={anyModelBySkin.get(sid)!.faction_model_dff}>{anyModelBySkin.get(sid)!.faction_model_dff.replace(/^skins_faction\/\d+\//, '')}</span>
                      : <span className="acp-td-muted">{sid <= 311 ? 'Standard GTA skin' : '—'}</span>}</td>
                    <td><input form="usable-all" name={`tier_${s.faction_skin_id}`} type="number" min={0} max={4} defaultValue={s.faction_skin_tier} className="acp-input" style={{ width: 56 }} title={fskinTierName(s.faction_skin_tier)} /></td>
                    <td>
                      <select form="usable-all" name={`squad_${s.faction_skin_id}`} defaultValue={s.faction_skin_squad} className="acp-input" style={{ width: 150 }} title="Squad that can use this uniform">
                        <option value={0}>No squad</option>
                        {squadOptions(squadMap, s.faction_skin_squad).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                      </select>
                    </td>
                    <td><input form="usable-all" name={`locker_${s.faction_skin_id}`} type="number" min={0} defaultValue={s.faction_skin_armory_type} className="acp-input" style={{ width: 70 }} title="Locker type id (0 = every locker)" /></td>
                    <td>{model}</td>
                    <td><DeleteUsableButton rowId={s.faction_skin_id} /></td>
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
