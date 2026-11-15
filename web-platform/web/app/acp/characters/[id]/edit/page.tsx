import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getCharacterById } from '@/lib/dal'
import { ADMIN_LVL, squadsForFaction } from '@/lib/constants'
import { vehicleName } from '@/lib/vehicles'
import CharacterEditForm from './CharacterEditForm'
import DeleteVehicleButton from './DeleteVehicleButton'

export const dynamic = 'force-dynamic'

export default async function CharacterEditPage({ params }: PageProps<'/acp/characters/[id]/edit'>) {
  await requireStaff(ADMIN_LVL.MANAGER)
  const id = Number((await params).id)
  const c = await getCharacterById(id)
  if (!c) notFound()

  const factionRows = await prisma.faction.findMany({ select: { faction_id: true, faction_type: true, faction_abbrev: true } })
  const squadsByFaction: Record<number, Record<number, string>> = {}
  for (const f of factionRows) squadsByFaction[f.faction_id] = squadsForFaction(f.faction_type, f.faction_abbrev)

  const vehicles = await prisma.vehicle.findMany({
    where: { vehicle_owner: id, vehicle_type: 3 },
    orderBy: { vehicle_sqlid: 'desc' },
  })

  return (
    <>
      <div className="acp-hub-head">
        <div className="acp-hub-id">
          <div className="acp-hub-name">Edit {c.player_name.replace(/_/g, ' ')}</div>
          <div className="acp-hub-meta">Character #{c.player_id}</div>
        </div>
        <div className="acp-hub-actions"><Link href={`/acp/characters/${id}`} className="acp-btn">← Back to Character</Link></div>
      </div>

      <section className="acp-panel" style={{ marginBottom: 14 }}>
        <div className="acp-panel-head"><span>Character Fields</span></div>
        <div style={{ padding: 16 }}>
          <CharacterEditForm v={{
            player_id: c.player_id, player_name: c.player_name,
            player_cash: c.player_cash, player_bankcash: c.player_bankcash, player_savings: c.player_savings,
            player_level: c.player_level, player_hours: c.player_hours,
            player_factionid: c.player_factionid, player_factionrank: c.player_factionrank, player_factiontier: c.player_factiontier,
            player_factionsquad: c.player_factionsquad, player_factionsquad2: c.player_factionsquad2, player_factionsquad3: c.player_factionsquad3,
            player_factionbadge: c.player_factionbadge,
            player_driverslicense: c.player_driverslicense, player_gunlicense: c.player_gunlicense, player_ccwlicense: c.player_ccwlicense,
            player_outstanding_fines: c.player_outstanding_fines, player_ajail_time: c.player_ajail_time,
          }} squadsByFaction={squadsByFaction} />
        </div>
      </section>

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Owned Vehicles — {vehicles.length}</span></div>
        {vehicles.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-car" />This character owns no vehicles.</div>
        ) : (
          <table className="acp-table">
            <thead><tr><th style={{ width: 56 }}>ID</th><th>Vehicle</th><th>Plate</th><th>Health</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {vehicles.map(v => (
                <tr key={v.vehicle_sqlid}>
                  <td className="acp-td-muted">{v.vehicle_sqlid}</td>
                  <td>{vehicleName(v.vehicle_modelid)} <span className="acp-td-muted">#{v.vehicle_modelid}</span></td>
                  <td className="acp-mono acp-td-muted">{v.vehicle_license || '—'}</td>
                  <td className="acp-td-muted">{Math.round(v.vehicle_health)}</td>
                  <td>{v.vehicle_impounded === 1 ? <span className="acp-badge is-red">Impounded</span> : <span className="acp-badge is-green">Active</span>}</td>
                  <td style={{ textAlign: 'right' }}><DeleteVehicleButton charId={id} sqlId={v.vehicle_sqlid} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </>
  )
}
