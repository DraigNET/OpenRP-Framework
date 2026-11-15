import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { ADMIN_LVL } from '@/lib/constants'

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''

export async function GET(req: NextRequest) {
  const session = await auth()
  if (!session) return new NextResponse('Unauthorized', { status: 401 })

  const account = await prisma.account.findUnique({
    where: { account_id: session.user.id },
    select: { account_stafflevel: true },
  })
  if (!account || account.account_stafflevel < ADMIN_LVL.DEVELOPER) {
    return new NextResponse('Forbidden', { status: 403 })
  }

  let agentRes: Response
  try {
    agentRes = await fetch(`${AGENT_URL}/stream`, {
      headers: { 'X-Agent-Key': AGENT_KEY },
      // Use the browser's abort signal so we cancel the upstream when they disconnect
      signal: req.signal,
    })
  } catch {
    return new NextResponse('Agent unavailable', { status: 502 })
  }

  if (!agentRes.ok || !agentRes.body) {
    return new NextResponse('Agent unavailable', { status: 502 })
  }

  return new NextResponse(agentRes.body, {
    headers: {
      'Content-Type':      'text/event-stream',
      'Cache-Control':     'no-cache, no-transform',
      'X-Accel-Buffering': 'no',
    },
  })
}
