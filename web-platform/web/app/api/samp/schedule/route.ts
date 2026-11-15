import { NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { ADMIN_LVL } from '@/lib/constants'
import { getScheduledFireAt, setSchedule, cancelSchedule } from '@/lib/samp-schedule'

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''

async function requireLead() {
  const session = await auth()
  if (!session) return null
  const account = await prisma.account.findUnique({
    where: { account_id: session.user.id },
    select: { account_stafflevel: true },
  })
  if (!account || account.account_stafflevel < ADMIN_LVL.LEAD) return null
  return account
}

export async function GET() {
  const account = await requireLead()
  if (!account) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  return NextResponse.json({ fireAt: getScheduledFireAt() })
}

export async function POST(req: Request) {
  const account = await requireLead()
  if (!account) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const body = await req.json().catch(() => ({}))
  const seconds = Number(body.seconds)
  if (!seconds || seconds < 1) {
    return NextResponse.json({ error: 'invalid seconds' }, { status: 400 })
  }

  setSchedule(seconds, async () => {
    try {
      await fetch(`${AGENT_URL}/start`, {
        method: 'POST',
        headers: { 'X-Agent-Key': AGENT_KEY },
        signal: AbortSignal.timeout(8000),
      })
    } catch { /* agent unreachable — nothing to do */ }
  })

  return NextResponse.json({ fireAt: getScheduledFireAt() })
}

export async function DELETE() {
  const account = await requireLead()
  if (!account) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  cancelSchedule()
  return NextResponse.json({ ok: true })
}
