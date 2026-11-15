import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { ADMIN_LVL } from '@/lib/constants'

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''

export async function POST(req: NextRequest) {
  const session = await auth()
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const account = await prisma.account.findUnique({
    where: { account_id: session.user.id },
    select: { account_stafflevel: true },
  })
  if (!account || account.account_stafflevel < ADMIN_LVL.DEVELOPER) {
    return NextResponse.json({ error: 'forbidden' }, { status: 403 })
  }

  let command: string
  try {
    const body = await req.json()
    if (typeof body?.command !== 'string' || !body.command.trim()) {
      return NextResponse.json({ error: 'missing_command' }, { status: 400 })
    }
    command = body.command
  } catch {
    return NextResponse.json({ error: 'bad_json' }, { status: 400 })
  }

  try {
    const res = await fetch(`${AGENT_URL}/cmd`, {
      method: 'POST',
      headers: { 'X-Agent-Key': AGENT_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ command }),
      signal: AbortSignal.timeout(5000),
    })
    const data = await res.json()
    return NextResponse.json(data, { status: res.ok ? 200 : 500 })
  } catch {
    return NextResponse.json({ ok: false, error: 'agent_unreachable' }, { status: 502 })
  }
}
