import { prisma } from '@/lib/prisma'
import { requireFactionCharacter } from '@/lib/dal'
import { vehicleName } from '@/lib/data/vehicles'
import { VEHICLE_OWNER_TYPE } from '@/lib/constants'

export default async function FactionVehiclesPage({ params }: PageProps<'/ucp/faction/[id]/vehicles'>) {
  const { id } = await params
  const char = await requireFactionCharacter(Number(id))

  const vehicles = await prisma.vehicle.findMany({
    where: { vehicle_type: VEHICLE_OWNER_TYPE.FACTION, vehicle_owner: char.player_factionid },
    orderBy: { vehicle_modelid: 'asc' },
  })

  return (
    <div className="ucp-card">
      <h3>Faction Vehicles</h3>

      {vehicles.length === 0 ? (
        <p className="ucp-muted" style={{ marginTop: 10 }}>No vehicles assigned.</p>
      ) : (
        <table className="ucp-table" style={{ marginTop: 10 }}>
          <thead>
            <tr>
              <th>Model</th>
              <th>Name</th>
              <th>Plate</th>
              <th>Mileage</th>
              <th>Impounded</th>
            </tr>
          </thead>
          <tbody>
            {vehicles.map(v => (
              <tr key={v.vehicle_sqlid}>
                <td>{v.vehicle_modelid}</td>
                <td>{vehicleName(v.vehicle_modelid)}</td>
                <td>{v.vehicle_license || '—'}</td>
                <td>{v.vehicle_mileage.toLocaleString()} km</td>
                <td>
                  {v.vehicle_impounded === 1
                    ? <span style={{ color: '#fca5a5' }}>Yes</span>
                    : <span style={{ color: '#86efac' }}>No</span>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}
