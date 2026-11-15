import { NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'

export const dynamic = 'force-dynamic'

const LIST_LIMIT = 15

export async function GET() {
  const session = await auth()
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  const accountId = session.user.id

  const [items, unread] = await Promise.all([
    prisma.notification.findMany({
      where: { account_id: accountId },
      orderBy: { created_at: 'desc' },
      take: LIST_LIMIT,
      select: { id: true, type: true, title: true, body: true, link: true, created_at: true, read_at: true },
    }),
    prisma.notification.count({ where: { account_id: accountId, read_at: null } }),
  ])

  return NextResponse.json({ unread, items })
}

/** Body: { action: 'read', id: number } or { action: 'readAll' }. */
export async function POST(req: Request) {
  const session = await auth()
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })
  const accountId = session.user.id

  const body = await req.json().catch(() => null)
  const now = Math.floor(Date.now() / 1000)

  if (body?.action === 'readAll') {
    await prisma.notification.updateMany({ where: { account_id: accountId, read_at: null }, data: { read_at: now } })
    return NextResponse.json({ ok: true })
  }

  if (body?.action === 'read' && Number.isInteger(body.id)) {
    // Scoped to the signed-in account so one player can't mark another's notifications.
    await prisma.notification.updateMany({ where: { id: body.id, account_id: accountId, read_at: null }, data: { read_at: now } })
    return NextResponse.json({ ok: true })
  }

  return NextResponse.json({ error: 'bad request' }, { status: 400 })
}
