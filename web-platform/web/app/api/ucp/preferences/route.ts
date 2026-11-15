import { NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'

export const dynamic = 'force-dynamic'

/** Body: { hue: number } — the UCP accent colour, 0-360. */
export async function POST(req: Request) {
  const session = await auth()
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const body = await req.json().catch(() => null)
  const hue = body?.hue
  if (!Number.isInteger(hue) || hue < 0 || hue > 360) {
    return NextResponse.json({ error: 'hue must be an integer from 0 to 360' }, { status: 400 })
  }

  const now = Math.floor(Date.now() / 1000)
  await prisma.accountPreference.upsert({
    where: { account_id: session.user.id },
    create: { account_id: session.user.id, ui_hue: hue, updated_at: now },
    update: { ui_hue: hue, updated_at: now },
  })

  return NextResponse.json({ ok: true })
}
