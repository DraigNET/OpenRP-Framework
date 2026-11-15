'use server'

import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireUser } from '@/lib/dal'
import { isGangFaction, FACTION_TIER_ID } from '@/lib/constants'

async function resolveContext(charPlayerId: number, memberId: number) {
  const user = await requireUser()

  const myChar = await prisma.character.findFirst({
    where: { player_id: charPlayerId, account_id: user.id },
  })
  if (!myChar || myChar.player_factionid <= 0) return null

  if (myChar.player_factiontier > FACTION_TIER_ID.COMMAND) return null

  const member = await prisma.character.findUnique({ where: { player_id: memberId } })
  if (!member || member.player_factionid !== myChar.player_factionid) return null

  const faction = await prisma.faction.findUnique({ where: { faction_id: myChar.player_factionid } })
  if (!faction) return null

  // Command can only edit Member/Recruit tier; Owner can edit anyone except themselves
  const isOwner = myChar.player_factiontier === FACTION_TIER_ID.OWNER
  if (isOwner && member.player_id === myChar.player_id) return null
  if (!isOwner && member.player_factiontier < FACTION_TIER_ID.MEMBER) return null

  return { myChar, member, faction, isOwner }
}

export type EditMemberState = { error: string; ok: boolean }

const int = (fd: FormData, k: string) => Math.trunc(Number(fd.get(k)) || 0)

export async function editMember(_prev: EditMemberState, formData: FormData): Promise<EditMemberState> {
  const charPlayerId = Number(formData.get('char_player_id'))
  const memberId = Number(formData.get('member_id'))

  const ctx = await resolveContext(charPlayerId, memberId)
  if (!ctx) return { error: 'Unauthorised.', ok: false }

  if (ctx.member.player_online === 1) return { error: 'Cannot edit a member who is currently online.', ok: false }

  const rank = String(formData.get('player_factionrank') ?? '').slice(0, 64)
  const tier = int(formData, 'player_factiontier')

  // Command can only set tier 3 or 4; Owner can set 1–4 (but not on themselves)
  const allowedTiers = ctx.isOwner ? [1, 2, 3, 4] : [3, 4]
  if (!allowedTiers.includes(tier)) return { error: 'Invalid tier.', ok: false }

  const isGang = isGangFaction(ctx.faction.faction_type)

  const data: Record<string, string | number> = {
    player_factionrank: rank,
    player_factiontier: tier,
  }

  if (!isGang) {
    data.player_factionbadge = int(formData, 'player_factionbadge')
    data.player_factionsquad = int(formData, 'player_factionsquad')
    data.player_factionsquad2 = int(formData, 'player_factionsquad2')
    data.player_factionsquad3 = int(formData, 'player_factionsquad3')
  }

  await prisma.character.update({ where: { player_id: memberId }, data })

  revalidatePath(`/ucp/faction/${charPlayerId}/roster`)
  revalidatePath(`/ucp/faction/${charPlayerId}/roster/${memberId}`)
  return { error: '', ok: true }
}

export async function kickMember(charPlayerId: number, memberId: number): Promise<void> {
  const ctx = await resolveContext(charPlayerId, memberId)
  if (!ctx) return

  if (ctx.member.player_online === 1) return

  await prisma.character.update({
    where: { player_id: memberId },
    data: {
      player_factionid: 0,
      player_factiontier: FACTION_TIER_ID.MEMBER,
      player_factionrank: '',
      player_factionsquad: 0,
      player_factionsquad2: 0,
      player_factionsquad3: 0,
      player_factionbadge: 0,
    },
  })

  revalidatePath(`/ucp/faction/${charPlayerId}/roster`)
  redirect(`/ucp/faction/${charPlayerId}/roster`)
}
