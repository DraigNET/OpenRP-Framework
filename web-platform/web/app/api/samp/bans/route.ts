import { NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'
import { ADMIN_LVL } from '@/lib/constants'

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''

async function requireManager() {
  const session = await auth()
  if (!session) return null
  const account = await prisma.account.findUnique({
    where: { account_id: session.user.id },
    select: { account_stafflevel: true },
  })
  if (!account || account.account_stafflevel < ADMIN_LVL.MANAGER) return null
  return account
}

export async function DELETE(req: Request) {
  const account = await requireManager()
  if (!account) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const url = new URL(req.url)
  const address = url.searchParams.get('address')
  if (!address) return NextResponse.json({ error: 'missing address' }, { status: 400 })

  try {
    const res = await fetch(`${AGENT_URL}/bans?address=${encodeURIComponent(address)}`, {
      method: 'DELETE',
      headers: { 'X-Agent-Key': AGENT_KEY },
      signal: AbortSignal.timeout(5000),
    })
    const data = await res.json()
    return NextResponse.json(data, { status: res.ok ? 200 : 500 })
  } catch {
    return NextResponse.json({ ok: false, error: 'agent_unreachable' }, { status: 502 })
  }
}
