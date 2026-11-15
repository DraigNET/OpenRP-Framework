import { prisma } from '@/lib/prisma'
import { requireFactionCharacter } from '@/lib/dal'
import { squadsForFaction } from '@/lib/constants'
import { RosterClient } from './MemberEditModal'
import type { RosterMember } from './MemberEditModal'

export const dynamic = 'force-dynamic'

export default async function FactionRosterPage({ params }: PageProps<'/ucp/faction/[id]/roster'>) {
  const { id } = await params
  const char = await requireFactionCharacter(Number(id))

  const members = await prisma.character.findMany({
    where: { player_factionid: char.player_factionid },
    orderBy: [{ player_factiontier: 'asc' }, { player_name: 'asc' }],
    select: {
      player_id: true, player_name: true, player_factionrank: true,
      player_factiontier: true, player_factionbadge: true,
      player_factionsquad: true, player_factionsquad2: true, player_factionsquad3: true,
      player_online: true, player_logindate: true,
    },
  })

  const faction = await prisma.faction.findUnique({ where: { faction_id: char.player_factionid } })
  const fType = faction?.faction_type ?? -1
  const isGang = fType === 1
  const squadMap = squadsForFaction(fType, faction?.faction_abbrev)

  return (
    <RosterClient
      charPlayerId={char.player_id}
      myTier={char.player_factiontier}
      isGang={isGang}
      squadMap={squadMap}
      members={members as RosterMember[]}
    />
  )
}
