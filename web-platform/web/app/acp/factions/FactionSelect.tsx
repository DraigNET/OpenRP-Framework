'use client'

import { useRouter } from 'next/navigation'

/** Generic faction dropdown that navigates to `${basePath}?faction_id=`. */
export default function FactionSelect({ factions, selected, basePath }: {
  factions: Array<{ faction_id: number; faction_name: string }>
  selected: number
  basePath: string
}) {
  const router = useRouter()
  return (
    <select className="acp-input" style={{ maxWidth: 320 }} value={selected}
      onChange={e => router.push(`${basePath}?faction_id=${e.target.value}`)}>
      {factions.map(f => <option key={f.faction_id} value={f.faction_id}>{f.faction_name} (#{f.faction_id})</option>)}
    </select>
  )
}
