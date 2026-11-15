import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getFactionById } from '@/lib/dal'
import { ADMIN_LVL, VEHICLE_OWNER_TYPE } from '@/lib/constants'
import { vehicleName } from '@/lib/vehicles'

export const dynamic = 'force-dynamic'

export default async function FactionVehicles({ params }: PageProps<'/acp/factions/[id]/vehicles'>) {
  await requireStaff(ADMIN_LVL.GENERAL)
  const id = Number((await params).id)
  if (!(await getFactionById(id))) notFound()

  const vehicles = await prisma.vehicle.findMany({
    where: { vehicle_type: VEHICLE_OWNER_TYPE.FACTION, vehicle_owner: id },
    orderBy: { vehicle_sqlid: 'asc' },
  })

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Vehicles — {vehicles.length}</span></div>
      {vehicles.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-car" />No faction vehicles.</div>
      ) : (
        <table className="acp-table">
          <thead>
            <tr><th style={{ width: 56 }}>ID</th><th>Model</th><th>Plate</th><th>Health</th><th>Mileage</th><th>Status</th></tr>
          </thead>
          <tbody>
            {vehicles.map(v => (
              <tr key={v.vehicle_sqlid}>
                <td className="acp-td-muted">{v.vehicle_sqlid}</td>
                <td>{vehicleName(v.vehicle_modelid)} <span className="acp-td-muted">#{v.vehicle_modelid}</span></td>
                <td className="acp-mono acp-td-muted">{v.vehicle_license || '—'}</td>
                <td className="acp-td-muted">{Math.round(v.vehicle_health)}</td>
                <td className="acp-td-muted">{v.vehicle_mileage.toLocaleString('en-GB')}</td>
                <td>{v.vehicle_impounded === 1 ? <span className="acp-badge is-red">Impounded</span> : <span className="acp-badge is-green">Active</span>}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
