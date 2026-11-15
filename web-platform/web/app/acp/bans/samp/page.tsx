import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import BansJsonClient from './BansJsonClient'

export const dynamic = 'force-dynamic'

interface BanEntry {
  address: string
  name: string
  time: string
  reason: string
}

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''

async function fetchBans(): Promise<BanEntry[]> {
  try {
    const res = await fetch(`${AGENT_URL}/bans`, {
      headers: { 'X-Agent-Key': AGENT_KEY },
      cache: 'no-store',
      signal: AbortSignal.timeout(5000),
    })
    if (!res.ok) return []
    return await res.json()
  } catch {
    return []
  }
}

export default async function BansJsonPage() {
  await requireStaff(ADMIN_LVL.MANAGER)
  const bans = await fetchBans()
  return <BansJsonClient bans={bans} />
}
