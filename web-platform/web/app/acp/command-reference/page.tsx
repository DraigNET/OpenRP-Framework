import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { ADMIN_TIERS } from '@/lib/data/admin-commands'
import CommandReference from './CommandReference'

export default async function CommandReferencePage() {
  const user = await requireStaff(ADMIN_LVL.JUNIOR)
  return <CommandReference tiers={ADMIN_TIERS} staffLevel={user.staffLevel} />
}
