import { prisma } from '@/lib/prisma'
import { factionHexToRgb } from '@/lib/format'
import TurfMap, { type TurfZone } from './TurfMap'

export const dynamic = 'force-dynamic'

export default async function GangZonesPage() {
  const zones = await prisma.gangZone.findMany({ where: { gz_faction: { not: -1 } } })

  const factionIds = [...new Set(zones.map(z => z.gz_faction))]
  const factions = factionIds.length > 0
    ? await prisma.faction.findMany({
        where: { faction_id: { in: factionIds } },
        select: { faction_id: true, faction_name: true, faction_hex: true },
      })
    : []
  const factionMap = Object.fromEntries(factions.map(f => [f.faction_id, f]))

  const SCALE = 6144 / 6000
  const rendered: TurfZone[] = zones.map(z => {
    const f = factionMap[z.gz_faction]
    return {
      x: (z.gz_min_x + 3000) * SCALE,
      y: (3000 - z.gz_max_y) * SCALE,
      w: (z.gz_max_x - z.gz_min_x) * SCALE,
      h: (z.gz_max_y - z.gz_min_y) * SCALE,
      fill: factionHexToRgb(f?.faction_hex ?? 0, 'rgb(120,120,120)'),
      faction: f?.faction_name ?? 'Unknown',
      contested: z.gz_contested === 1,
    }
  })

  return (
    <>
      <div className="ucp-card">
        <h2>Gang Territories</h2>
        <p className="ucp-muted">Controlled and contested gang zones across San Andreas.</p>
      </div>
      {rendered.length === 0 && (
        <div className="ucp-card ucp-empty-state" role="status">
          <i className="fa-solid fa-map-location-dot" aria-hidden="true" />
          <h3>No gang zones yet</h3>
          <p className="ucp-muted">The framework starts with an empty map. Zones will appear here once they are created on your server.</p>
        </div>
      )}
      <div className="ucp-card" style={{ marginTop: 20 }}>
        <TurfMap zones={rendered} />
      </div>
    </>
  )
}
