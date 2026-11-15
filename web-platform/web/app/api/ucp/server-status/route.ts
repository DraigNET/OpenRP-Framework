import { NextResponse } from 'next/server'
import { auth } from '@/auth'
import { env } from '@/lib/env'
import { queryPlayersDetailed } from '@/lib/sampquery'

export const dynamic = 'force-dynamic'

// Every open UCP tab polls this, so share one query between them.
const TTL_MS = 15_000
let cached: { at: number; body: { online: boolean; players: number } } | null = null

export async function GET() {
  const session = await auth()
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  if (cached && Date.now() - cached.at < TTL_MS) return NextResponse.json(cached.body)

  let body: { online: boolean; players: number }
  try {
    const players = await queryPlayersDetailed(env.sampQueryHost, env.rconPort, 2000)
    body = { online: true, players: players.length }
  } catch {
    body = { online: false, players: 0 }
  }
  cached = { at: Date.now(), body }
  return NextResponse.json(body)
}
