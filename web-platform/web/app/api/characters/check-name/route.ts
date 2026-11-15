import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@/auth'
import { prisma } from '@/lib/prisma'

export async function GET(req: NextRequest) {
  const session = await auth()
  if (!session) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const name = req.nextUrl.searchParams.get('name') ?? ''
  if (!name) return NextResponse.json({ available: false, error: 'No name provided' })

  const existing = await prisma.character.findFirst({
    where: { player_name: { equals: name } },
    select: { player_id: true },
  })

  return NextResponse.json({ available: !existing })
}
