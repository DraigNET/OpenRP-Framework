import { env } from '@/lib/env'
import { AccessToken } from 'livekit-server-sdk'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { verifyVoiceToken, bearer } from '@/lib/voice-auth'
import { voiceJson, voicePreflight } from '@/lib/voice-cors'
import { departmentFor, FACTION_COLORS, initials } from '@/lib/voice-departments'

export const dynamic = 'force-dynamic'

const LIVEKIT_URL = process.env.LIVEKIT_URL ?? 'wss://livekit.streetsofvice.com'
const API_KEY = process.env.LIVEKIT_API_KEY ?? ''
const API_SECRET = process.env.LIVEKIT_API_SECRET ?? ''
// Optional dev key — pre-auth testing bypass. Unset in production to disable.
const DEV_KEY = process.env.VOICE_DEV_KEY ?? ''

export function OPTIONS(req: Request) {
  return voicePreflight(req)
}

export async function POST(req: Request) {
  if (!env.voiceEnabled) return voiceJson(req, { error: 'Voice integration is disabled.' }, 404)
  if (!API_KEY || !API_SECRET) return voiceJson(req, { error: 'Voice not configured' }, 503)

  const body = await req.json().catch(() => ({}))
  const room = typeof body.room === 'string' ? body.room : ''
  if (!room) return voiceJson(req, { error: 'room is required' }, 400)

  // ── Dev bypass: mint from client metadata, no auth (only when DEV_KEY is set). ──
  const devKey = req.headers.get('x-voice-dev-key')
  if (DEV_KEY && devKey === DEV_KEY) {
    const at = new AccessToken(API_KEY, API_SECRET, {
      identity: `dev-${body.characterId ?? 'user'}`,
      name: String(body.characterName ?? 'Dev User'),
      ttl: '2h',
      metadata: JSON.stringify({
        rank: String(body.rank ?? ''),
        faction: String(body.faction ?? ''),
        color: String(body.color ?? '#3b82f6'),
        ini: String(body.ini ?? ''),
      }),
    })
    at.addGrant({ roomJoin: true, room, canPublish: true, canSubscribe: true })
    return voiceJson(req, { url: LIVEKIT_URL, token: await at.toJwt() })
  }

  // ── Authenticated: account id from the Bearer voice-session, else cookie session. ──
  let accountId: number | null = null
  const tok = bearer(req)
  if (tok) {
    accountId = await verifyVoiceToken(tok, 'voice-session')
  } else {
    const session = await auth()
    accountId = session?.user.id ?? null
  }
  if (!accountId) return voiceJson(req, { error: 'Unauthorized' }, 401)

  const characterId = Number(body.characterId)
  if (!characterId) return voiceJson(req, { error: 'characterId is required' }, 400)

  const character = await prisma.character.findUnique({
    where: { player_id: characterId },
    select: { account_id: true, player_name: true, player_factionid: true, player_factionrank: true },
  })
  if (!character || character.account_id !== accountId) {
    return voiceJson(req, { error: 'Character not found' }, 404)
  }

  const faction = character.player_factionid
    ? await prisma.faction.findUnique({
        where: { faction_id: character.player_factionid },
        select: { faction_abbrev: true },
      })
    : null
  const abbrev = faction?.faction_abbrev || ''
  const dept = departmentFor(abbrev)
  if (!dept) return voiceJson(req, { error: 'This character does not have Dispatch access' }, 403)

  // Mutual-aid rooms are shared across all Dispatch agencies; any eligible
  // character may join. Other rooms must belong to the character's department.
  const isMutualAid = room === 'ma-1' || room === 'ma-2'
  if (!isMutualAid && !dept.prefixes.some(p => room.startsWith(p))) {
    return voiceJson(req, { error: 'Channel not permitted for this character' }, 403)
  }

  const color = FACTION_COLORS[abbrev.toUpperCase()] ?? '#3b82f6'
  const at = new AccessToken(API_KEY, API_SECRET, {
    identity: character.player_name,
    name: character.player_name.replace(/_/g, ' '),
    ttl: '2h',
    metadata: JSON.stringify({
      rank: character.player_factionrank || '',
      faction: abbrev.toUpperCase(),
      color,
      ini: initials(character.player_name),
    }),
  })
  at.addGrant({ roomJoin: true, room, canPublish: true, canSubscribe: true })

  return voiceJson(req, { url: LIVEKIT_URL, token: await at.toJwt() })
}
