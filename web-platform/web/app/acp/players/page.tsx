import Link from 'next/link'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL, staffLevelTitle } from '@/lib/constants'
import { formatUnixDate } from '@/lib/format'
import type { Prisma } from '@prisma/client'

export const dynamic = 'force-dynamic'

const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''

export default async function PlayersSearch({ searchParams }: PageProps<'/acp/players'>) {
  await requireStaff(ADMIN_LVL.JUNIOR)
  const sp = await searchParams
  const id = firstParam(sp.id).trim()
  const name = firstParam(sp.name).trim()
  const email = firstParam(sp.email).trim()
  const charName = firstParam(sp.char).trim()
  const discord = firstParam(sp.discord).trim()

  // Each filled field narrows the results (AND). Account ID is an exact match.
  const filters: Prisma.AccountWhereInput[] = []
  if (id && /^\d+$/.test(id)) filters.push({ account_id: Number(id) })
  if (name) filters.push({ account_name: { contains: name } })
  if (email) filters.push({ account_email: { contains: email } })
  if (charName) filters.push({ characters: { some: { player_name: { contains: charName } } } })
  if (discord) filters.push(/^\d+$/.test(discord) ? { discord_id: BigInt(discord) } : { account_discordname: { contains: discord } })

  const searched = filters.length > 0
  const results = searched
    ? await prisma.account.findMany({
        where: { AND: filters },
        select: {
          account_id: true, account_name: true, account_stafflevel: true,
          account_online: true, account_register_date: true,
          characters: { select: { player_id: true, player_name: true }, orderBy: { player_id: 'asc' } },
        },
        orderBy: { account_id: 'desc' },
        take: 50,
      })
    : []

  return (
    <>
      <form method="GET" action="/acp/players" className="acp-panel" style={{ marginBottom: 14, padding: 14 }}>
        <div className="acp-logfilter">
          <div className="acp-field"><label>Account ID</label><input name="id" defaultValue={id} className="acp-input" placeholder="Exact ID" inputMode="numeric" /></div>
          <div className="acp-field"><label>Username</label><input name="name" defaultValue={name} className="acp-input" placeholder="Partial or full" /></div>
          <div className="acp-field"><label>Email</label><input name="email" defaultValue={email} className="acp-input" placeholder="Partial or full" /></div>
          <div className="acp-field"><label>Character Name</label><input name="char" defaultValue={charName} className="acp-input" placeholder="Firstname_Lastname" /></div>
          <div className="acp-field"><label>Discord (name or ID)</label><input name="discord" defaultValue={discord} className="acp-input" placeholder="Discord name or ID" /></div>
        </div>
        <div style={{ marginTop: 12 }}>
          <button type="submit" className="acp-btn acp-btn-primary">Search</button>
          <Link href="/acp/players" className="acp-btn" style={{ marginLeft: 8 }}>Reset</Link>
        </div>
      </form>

      <section className="acp-panel">
        <div className="acp-panel-head">
          <span>{searched ? `Results — ${results.length}${results.length === 50 ? '+' : ''}` : 'Player Search'}</span>
        </div>

        {!searched ? (
          <div className="acp-empty">
            <i className="fa-solid fa-user-magnifying-glass" />
            Fill in one or more fields above to search. Multiple fields narrow the results.
          </div>
        ) : results.length === 0 ? (
          <div className="acp-empty"><i className="fa-solid fa-circle-question" />No accounts matched those filters.</div>
        ) : (
          <table className="acp-table">
            <thead>
              <tr><th style={{ width: 60 }}>ID</th><th>Account</th><th>Rank</th><th>Status</th><th>Registered</th></tr>
            </thead>
            <tbody>
              {results.map(a => (
                <tr key={a.account_id}>
                  <td className="acp-td-muted">{a.account_id}</td>
                  <td>
                    <Link href={`/acp/players/${a.account_id}`} className="acp-link">{a.account_name}</Link>
                    {a.characters.length > 0 && (
                      <span className="acp-sub">{a.characters.map(c => c.player_name.replace(/_/g, ' ')).join(', ')}</span>
                    )}
                  </td>
                  <td>{a.account_stafflevel > 0
                    ? <span className="acp-badge is-amber">{staffLevelTitle(a.account_stafflevel)}</span>
                    : <span className="acp-td-muted">Player</span>}</td>
                  <td>{a.account_online === 1
                    ? <span className="acp-badge is-green">Online</span>
                    : <span className="acp-badge is-off">Offline</span>}</td>
                  <td className="acp-td-muted">{formatUnixDate(a.account_register_date)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </>
  )
}
