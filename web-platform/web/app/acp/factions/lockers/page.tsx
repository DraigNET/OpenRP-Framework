import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL, } from '@/lib/constants'
import FactionSelect from '../FactionSelect'
import { LockerForm, HelpGuide } from './LockerClient'

export const dynamic = 'force-dynamic'

const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''

export default async function LockersPage({ searchParams }: PageProps<'/acp/factions/lockers'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const sp = await searchParams

  const factions = await prisma.faction.findMany({ select: { faction_id: true, faction_name: true, faction_abbrev: true, faction_type: true }, orderBy: [{ faction_name: 'asc' }] })
  if (factions.length === 0) return <div className="acp-empty"><i className="fa-solid fa-box" />No factions.</div>

  const types = await prisma.factionArmoryType.findMany({ select: { armory_type_id: true, faction_id: true, type_name: true, type_enabled: true }, orderBy: [{ type_name: 'asc' }] })

  const squadsByFaction: Record<number, Record<number, string>> = {}
  for (const f of factions) squadsByFaction[f.faction_id] = await loadFactionSquads(f.faction_id)

  const editId = Number(firstParam(sp.edit)) || 0
  const editing = editId > 0 ? await prisma.factionArmory.findUnique({ where: { armory_id: editId } }) : null

  let selectedFaction = editing?.faction_id ?? (Number(firstParam(sp.faction_id)) || 0)
  if (!factions.some(f => f.faction_id === selectedFaction)) selectedFaction = factions[0].faction_id

  const lockers = await prisma.factionArmory.findMany({ where: { faction_id: selectedFaction }, orderBy: [{ armory_name: 'asc' }, { armory_id: 'asc' }] })
  const typeName = new Map(types.map(t => [t.armory_type_id, { name: t.type_name, enabled: t.type_enabled }]))
  const facName = new Map(factions.map(f => [f.faction_id, f.faction_abbrev || f.faction_name]))

  return (
    <>
      <div className="acp-toolbar">
        <span style={{ fontSize: 12.5, color: 'var(--acp-text-2)', flex: 1 }}>Place a locker in-game with <span className="acp-mono">/armoryplace [id]</span>, then <span className="acp-mono">/reloadarmories</span>. Weapon loadouts come from the assigned armory type.</span>
        <HelpGuide />
        <Link href={`/acp/factions/armory?faction_id=${selectedFaction}`} className="acp-btn"><i className="fa-solid fa-gun" /> Armory Types</Link>
      </div>

      <section className="acp-panel">
        <div className="acp-panel-head"><span>{editing ? `Edit Locker #${editing.armory_id}` : 'Create Locker'}</span></div>
        <LockerForm key={`${editing?.armory_id ?? 0}-${selectedFaction}`} factions={factions} types={types} editing={editing} selectedFaction={selectedFaction} squadsByFaction={squadsByFaction} />
      </section>

      <section className="acp-panel" style={{ marginTop: 14 }}>
        <div className="acp-panel-head">
          <span>Lockers — {lockers.length}</span>
          <label style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12.5, color: 'var(--acp-text-2)', textTransform: 'none', letterSpacing: 0 }}>
            Faction <FactionSelect factions={factions} selected={selectedFaction} basePath="/acp/factions/lockers" />
          </label>
        </div>
        {lockers.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-box" />No lockers for this faction.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th style={{ width: 56 }}>ID</th><th>Faction</th><th>Type</th><th>Squad</th><th>Name</th><th>Status</th><th>Position</th><th>Int/VW</th><th></th></tr></thead>
            <tbody>
              {lockers.map(l => {
                const t = typeName.get(l.armory_type_id)
                const unplaced = l.armory_z <= -999
                return (
                  <tr key={l.armory_id}>
                    <td className="acp-td-muted">{l.armory_id}</td>
                    <td className="acp-td-muted">{facName.get(l.faction_id) ?? `#${l.faction_id}`}</td>
                    <td>{t?.name ?? `#${l.armory_type_id}`}{t && t.enabled === 0 && <span className="acp-td-muted"> (disabled)</span>}</td>
                    <td className="acp-td-muted">{l.armory_squad ? (squadsByFaction[l.faction_id]?.[l.armory_squad] ?? l.armory_squad) : '—'}</td>
                    <td><b>{l.armory_name}</b>{l.armory_desc && <span className="acp-sub">{l.armory_desc}</span>}</td>
                    <td>{l.armory_enabled === 1 ? <span className="acp-badge is-green">Enabled</span> : <span className="acp-badge is-off">Disabled</span>}</td>
                    <td className="acp-mono acp-td-muted">{unplaced ? <span className="acp-badge is-amber">Unplaced</span> : `${l.armory_x.toFixed(1)}, ${l.armory_y.toFixed(1)}, ${l.armory_z.toFixed(1)}`}</td>
                    <td className="acp-td-muted">{l.armory_int} / {l.armory_vw}</td>
                    <td style={{ textAlign: 'right' }}><Link href={`/acp/factions/lockers?faction_id=${l.faction_id}&edit=${l.armory_id}`} className="acp-btn acp-btn-sm">Edit</Link></td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </section>
    </>
  )
}

import { loadFactionSquads } from '@/lib/runtime-squads'
