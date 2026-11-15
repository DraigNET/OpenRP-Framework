import { env } from '@/lib/env'
import { prisma } from '@/lib/prisma'
import { verifyVoiceToken, bearer } from '@/lib/voice-auth'
import { voiceJson, voicePreflight } from '@/lib/voice-cors'
import { departmentFor } from '@/lib/voice-departments'

export const dynamic = 'force-dynamic'

export function OPTIONS(req: Request) {
  return voicePreflight(req)
}

/** Lists the authenticated account's characters, flagging Dispatch eligibility. */
export async function GET(req: Request) {
  if (!env.voiceEnabled) return voiceJson(req, { error: 'Voice integration is disabled.' }, 404)
  const token = bearer(req)
  if (!token) return voiceJson(req, { error: 'Unauthorized' }, 401)

  const accountId = await verifyVoiceToken(token, 'voice-session')
  if (!accountId) return voiceJson(req, { error: 'Unauthorized' }, 401)

  const characters = await prisma.character.findMany({
    where: { account_id: accountId },
    select: { player_id: true, player_name: true, player_factionid: true, player_factionrank: true },
    orderBy: { player_name: 'asc' },
  })

  const factionIds = [...new Set(characters.map(c => c.player_factionid).filter(Boolean))]
  const factions = factionIds.length
    ? await prisma.faction.findMany({
        where: { faction_id: { in: factionIds } },
        select: { faction_id: true, faction_abbrev: true },
      })
    : []
  const abbrevById = new Map(factions.map(f => [f.faction_id, f.faction_abbrev || '']))

  const result = characters.map(c => {
    const abbrev = abbrevById.get(c.player_factionid) ?? ''
    const dept = departmentFor(abbrev)
    return {
      id: c.player_id,
      name: c.player_name.replace(/_/g, ' '),
      faction: dept ? abbrev.toUpperCase() : null,
      factionId: c.player_factionid,
      rank: c.player_factionrank || '',
      hasAccess: dept !== null,
    }
  })

  return voiceJson(req, result)
}
