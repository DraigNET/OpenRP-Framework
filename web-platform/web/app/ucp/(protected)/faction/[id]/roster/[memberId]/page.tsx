import { redirect, notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireUser } from '@/lib/dal'
import { isGangFaction, FACTION_TIER_ID, } from '@/lib/constants'
import { FACTION_TIER } from '@/lib/data/attributes'
import { EditMemberForm } from './EditMemberForm'

export const dynamic = 'force-dynamic'

export default async function EditMemberPage({
  params,
}: {
  params: Promise<{ id: string; memberId: string }>
}) {
  const { id, memberId } = await params
  const user = await requireUser()

  const myChar = await prisma.character.findFirst({
    where: { player_id: Number(id), account_id: user.id },
  })
  if (!myChar || myChar.player_factionid <= 0) redirect('/ucp/faction')
  if (myChar.player_factiontier > FACTION_TIER_ID.COMMAND) redirect(`/ucp/faction/${id}/roster`)

  const member = await prisma.character.findUnique({ where: { player_id: Number(memberId) } })
  if (!member || member.player_factionid !== myChar.player_factionid) notFound()

  const isOwner = myChar.player_factiontier === FACTION_TIER_ID.OWNER
  if (isOwner && member.player_id === myChar.player_id) redirect(`/ucp/faction/${id}/roster`)
  if (!isOwner && member.player_factiontier < FACTION_TIER_ID.MEMBER) redirect(`/ucp/faction/${id}/roster`)
  if (member.player_online === 1) redirect(`/ucp/faction/${id}/roster`)

  const faction = await prisma.faction.findUnique({ where: { faction_id: myChar.player_factionid } })
  if (!faction) redirect('/ucp/faction')

  const isGang = isGangFaction(faction.faction_type)
  const memberName = member.player_name.replace(/_/g, ' ')

  const tierOptions = (
    isOwner
      ? Object.entries(FACTION_TIER)
      : Object.entries(FACTION_TIER).filter(([k]) => Number(k) >= FACTION_TIER_ID.MEMBER)
  ) as [string, string][]

  return (
    <EditMemberForm
      charPlayerId={Number(id)}
      member={{
        player_id: member.player_id,
        player_factionrank: member.player_factionrank,
        player_factiontier: member.player_factiontier,
        player_factionbadge: member.player_factionbadge,
        player_factionsquad: member.player_factionsquad,
        player_factionsquad2: member.player_factionsquad2,
        player_factionsquad3: member.player_factionsquad3,
      }}
      memberName={memberName}
      isGang={isGang}
      squadMap={await loadFactionSquads(faction.faction_id)}
      tierOptions={tierOptions}
    />
  )
}

import { loadFactionSquads } from '@/lib/runtime-squads'
