import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { requireFactionCharacter } from '@/lib/dal'
import { VEHICLE_OWNER_TYPE } from '@/lib/constants'

export default async function FactionOverviewPage({ params }: PageProps<'/ucp/faction/[id]'>) {
  const { id } = await params
  const char = await requireFactionCharacter(Number(id))

  const [faction, memberCount, onlineCount, vehicleCount] = await Promise.all([
    prisma.faction.findUnique({ where: { faction_id: char.player_factionid } }),
    prisma.character.count({ where: { player_factionid: char.player_factionid } }),
    prisma.character.count({ where: { player_factionid: char.player_factionid, player_online: 1 } }),
    prisma.vehicle.count({ where: { vehicle_type: VEHICLE_OWNER_TYPE.FACTION, vehicle_owner: char.player_factionid } }),
  ])
  if (!faction) notFound()

  const stats = [
    { label: 'Members', value: String(memberCount) },
    { label: 'Online', value: String(onlineCount) },
    { label: 'Vehicles', value: String(vehicleCount) },
    { label: 'Bank', value: `$${faction.faction_bank.toLocaleString()}` },
  ]

  return (
    <div className="ucp-card">
      <h3>{faction.faction_name}</h3>
      <div style={{ marginTop: 12, display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(200px,1fr))', gap: 16 }}>
        {stats.map(({ label, value }) => (
          <div key={label}>
            <strong>{label}:</strong><br />{value}
          </div>
        ))}
      </div>
    </div>
  )
}
