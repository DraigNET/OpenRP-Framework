import { NextResponse } from 'next/server'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { prisma } from '@/lib/prisma'
import { publicRuntimeState } from '@/lib/runtime-config-status'
export async function GET() {
  await requireStaff(ADMIN_LVL.MANAGER)
  const [state]=await prisma.$queryRaw<{revision:number;applied_revision:number;last_heartbeat:number;last_error:string;schema_version:number}[]>`SELECT revision,applied_revision,last_heartbeat,last_error,schema_version FROM runtime_config_state WHERE id=1`
  const value=publicRuntimeState(state)
  return NextResponse.json(value,{headers:{'Cache-Control':'no-store'}})
}
