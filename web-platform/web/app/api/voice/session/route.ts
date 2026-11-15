import { env } from '@/lib/env'
import { verifyVoiceToken, mintVoiceSession } from '@/lib/voice-auth'
import { voiceJson, voicePreflight } from '@/lib/voice-cors'

export const dynamic = 'force-dynamic'

export function OPTIONS(req: Request) {
  return voicePreflight(req)
}

/** Exchanges a short-lived auth code (from the deep link) for a 30-day voice session. */
export async function POST(req: Request) {
  if (!env.voiceEnabled) return voiceJson(req, { error: 'Voice integration is disabled.' }, 404)
  const body = await req.json().catch(() => ({}))
  const code = typeof body.code === 'string' ? body.code : ''
  if (!code) return voiceJson(req, { error: 'code required' }, 400)

  const accountId = await verifyVoiceToken(code, 'voice-auth')
  if (!accountId) return voiceJson(req, { error: 'invalid or expired code' }, 401)

  const token = await mintVoiceSession(accountId)
  return voiceJson(req, { token })
}
