import 'server-only'
import { prisma } from './prisma'

// Read faction-owned, enabled IDs from the same tables as the game cache.
// React request memoisation keeps pages with many factions to one query.
import { cache } from 'react'
export const loadSquadMaps=cache(async():Promise<Record<number,Record<number,string>>>=>{
  const rows=await prisma.$queryRaw<Array<{squad_id:number;faction_id:number;squad_name:string}>>    `SELECT squad_id,faction_id,squad_name FROM runtime_faction_squads WHERE enabled=1 ORDER BY squad_id`
  const maps:Record<number,Record<number,string>>={}
  for(const row of rows) (maps[row.faction_id]??={})[row.squad_id]=row.squad_name
  return maps
})
export async function loadFactionSquads(factionId:number):Promise<Record<number,string>> {
  return (await loadSquadMaps())[factionId]??{}
}
