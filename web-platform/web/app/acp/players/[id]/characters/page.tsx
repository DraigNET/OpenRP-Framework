import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff, getAccountById } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { formatUnixDateTime, formatCash, formatHours } from '@/lib/format'

export const dynamic = 'force-dynamic'

export default async function PlayerCharacters({ params }: PageProps<'/acp/players/[id]/characters'>) {
  await requireStaff(ADMIN_LVL.JUNIOR)
  const id = Number((await params).id)
  if (!(await getAccountById(id))) notFound()

  const chars = await prisma.character.findMany({ where: { account_id: id }, orderBy: { player_name: 'asc' } })
  const facIds = [...new Set(chars.map(c => c.player_factionid).filter(x => x > 0))]
  const facs = facIds.length
    ? await prisma.faction.findMany({ where: { faction_id: { in: facIds } }, select: { faction_id: true, faction_name: true } })
    : []
  const facMap = new Map(facs.map(f => [f.faction_id, f.faction_name]))

  return (
    <section className="acp-panel">
      <div className="acp-panel-head"><span>Characters — {chars.length}</span></div>
      {chars.length === 0 ? (
        <div className="acp-empty"><i className="fa-solid fa-user" />This account has no characters.</div>
      ) : (
        <table className="acp-table">
          <thead>
            <tr><th style={{ width: 56 }}>ID</th><th>Name</th><th>Level</th><th>Hours</th><th>Bank</th><th>Faction</th><th>Status</th><th>Last Played</th></tr>
          </thead>
          <tbody>
            {chars.map(c => (
              <tr key={c.player_id}>
                <td className="acp-td-muted">{c.player_id}</td>
                <td><Link href={`/acp/characters/${c.player_id}`} className="acp-link">{c.player_name.replace(/_/g, ' ')}</Link></td>
                <td>{c.player_level}</td>
                <td className="acp-td-muted">{formatHours(c.player_hours)}</td>
                <td className="acp-td-muted">{formatCash(c.player_bankcash)}</td>
                <td>{c.player_factionid > 0 ? (facMap.get(c.player_factionid) ?? `#${c.player_factionid}`) : <span className="acp-td-muted">—</span>}</td>
                <td>{c.player_online === 1 ? <span className="acp-badge is-green">Online</span> : <span className="acp-badge is-off">Offline</span>}</td>
                <td className="acp-td-muted">{formatUnixDateTime(c.player_logindate)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
