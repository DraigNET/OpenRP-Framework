import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import CreateBanForm from './CreateBanForm'

export const dynamic = 'force-dynamic'

export default async function CreateBanPage() {
  await requireStaff(ADMIN_LVL.JUNIOR)
  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Create Offline Ban</span></div>
      <div style={{ padding: 16 }}>
        <CreateBanForm />
      </div>
    </section>
  )
}
