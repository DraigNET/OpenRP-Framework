import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { loadRuntimeEntities } from '@/lib/runtime-config'
export const dynamic='force-dynamic'
export async function GET(request:Request) {
  await requireStaff(ADMIN_LVL.MANAGER)
  try { return Response.json(await loadRuntimeEntities(new URL(request.url).searchParams.get('type')??''),{headers:{'Cache-Control':'no-store'}}) }
  catch { return Response.json({error:'Entity list unavailable.'},{status:400}) }
}
