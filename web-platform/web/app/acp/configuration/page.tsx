import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { loadRuntimeConfiguration,loadRuntimeHistory } from '@/lib/runtime-config'
import ConfigurationEditor from './ConfigurationEditor'
export const dynamic='force-dynamic'
export default async function ConfigurationPage() {
  await requireStaff(ADMIN_LVL.MANAGER)
  try {
    const [configuration,history]=await Promise.all([loadRuntimeConfiguration(),loadRuntimeHistory()])
    return <ConfigurationEditor initial={configuration} history={history}/>
  } catch(error) {
    console.error('Runtime configuration read failed:',(error as Error).message)
    return <section className="acp-panel"><div className="acp-panel-head">Runtime configuration unavailable</div><div style={{padding:24,lineHeight:1.8}}>Apply <code>database/migrations/001-runtime-configuration.sql</code> , <code>002-runtime-defaults.sql</code> and <code>003-runtime-entity-journal.sql</code> to your framework database, then reload this page. If the migration is already installed, check database connectivity and the web service logs.</div></section>
  }
}
