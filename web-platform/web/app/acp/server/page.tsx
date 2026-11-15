import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import ServerConsole from './ServerConsole'

export const dynamic = 'force-dynamic'

export default async function ServerControlPage() {
  const user = await requireStaff(ADMIN_LVL.LEAD)
  return <ServerConsole staffLevel={user.staffLevel} />
}
