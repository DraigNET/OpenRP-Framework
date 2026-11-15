import { prisma } from '@/lib/prisma'
import { notFound } from 'next/navigation'
import { requireFactionCharacter } from '@/lib/dal'
import { FACTION_TIER } from '@/lib/data/attributes'
import { FACTION_TIER_ID, isGangFaction } from '@/lib/constants'

export default async function FactionGunLogsPage({ params, searchParams }: PageProps<'/ucp/faction/[id]/gun-logs'>) {
  const { id } = await params
  const sp = await searchParams

  const char = await requireFactionCharacter(Number(id))
  // Gun logs are owner/command-only, and gangs only.
  if (char.player_factiontier > FACTION_TIER_ID.COMMAND) notFound()

  const faction = await prisma.faction.findUnique({ where: { faction_id: char.player_factionid } })
  if (!faction || !isGangFaction(faction.faction_type)) notFound()

  const now = new Date()
  const year = sp?.year ? Number(sp.year) : now.getFullYear()
  const month = sp?.month ? Number(sp.month) : now.getMonth() + 1
  const start = new Date(year, month - 1, 1)
  const end = new Date(year, month, 1)

  const [logs, availableRaw] = await Promise.all([
    prisma.emmetPurchaseLog.findMany({
      where: { faction_id: char.player_factionid, purchased_at: { gte: start, lt: end } },
      orderBy: { purchased_at: 'desc' },
      take: 200,
    }),
    prisma.emmetPurchaseLog.findMany({
      where: { faction_id: char.player_factionid },
      select: { purchased_at: true },
      orderBy: { purchased_at: 'desc' },
    }),
  ])

  const availableYears = [...new Set(availableRaw.map(r => r.purchased_at.getFullYear()))]
  const purchaseCount = logs.length
  const uniqueBuyers = new Set(logs.map(l => l.buyer_character_id)).size
  const totalAmmo = logs.reduce((s, l) => s + l.weapon_ammo, 0)
  const totalSpend = logs.reduce((s, l) => s + l.purchase_price, 0)
  const factionShort = faction.faction_abbrev || faction.faction_name

  return (
    <>
      <div className="ucp-card">
        <h3>Gun Logs</h3>
        <p className="ucp-muted" style={{ marginTop: 6 }}>Review faction weapon purchases made through Emmet dealers.</p>
      </div>

      <div className="ucp-card" style={{ marginTop: 18 }}>
        <form method="get" style={{ display: 'flex', flexDirection: 'row', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <span className="ucp-muted" style={{ fontSize: 13 }}>Year</span>
            <select name="year" className="char-text-input" style={{ minWidth: 120 }} defaultValue={year}>
              {(availableYears.length ? availableYears : [now.getFullYear()]).map(y => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <span className="ucp-muted" style={{ fontSize: 13 }}>Month</span>
            <select name="month" className="char-text-input" style={{ minWidth: 160 }} defaultValue={month}>
              {Array.from({ length: 12 }, (_, i) => i + 1).map(m => (
                <option key={m} value={m}>{new Date(2000, m - 1).toLocaleString('default', { month: 'long' })}</option>
              ))}
            </select>
          </div>
          <button type="submit" className="ucp-btn ucp-btn-primary" style={{ marginTop: 22 }}>Load</button>
        </form>
      </div>

      <div className="ucp-card" style={{ marginTop: 18 }}>
        <div style={{ display: 'flex', gap: 18, flexWrap: 'wrap' }}>
          {[['Faction', factionShort], ['Purchases', purchaseCount.toLocaleString()], ['Unique Buyers', uniqueBuyers.toLocaleString()], ['Total Ammo', totalAmmo.toLocaleString()], ['Total Spend', `$${totalSpend.toLocaleString()}`]].map(([label, value]) => (
            <div key={label} style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
              <span className="ucp-muted">{label}:</span>
              <strong>{value}</strong>
            </div>
          ))}
        </div>
      </div>

      <div className="ucp-card" style={{ marginTop: 18 }}>
        <table className="ucp-table">
          <thead>
            <tr><th>Purchased</th><th>Buyer</th><th>Tier</th><th>Dealer</th><th>Weapon</th><th>Ammo</th><th>Price</th></tr>
          </thead>
          <tbody>
            {logs.length === 0
              ? <tr><td colSpan={7} className="ucp-muted">No gun purchases recorded for this faction in the selected month.</td></tr>
              : logs.map(log => (
                <tr key={log.id}>
                  <td style={{ whiteSpace: 'nowrap' }}>{log.purchased_at.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}</td>
                  <td>{log.buyer_character_name.replace('_', ' ')}<div className="ucp-muted" style={{ fontSize: 12 }}>{log.buyer_account_name}</div></td>
                  <td>{FACTION_TIER[log.buyer_faction_tier] ?? `Tier ${log.buyer_faction_tier}`}</td>
                  <td>{log.emmet_name}<div className="ucp-muted" style={{ fontSize: 12 }}>#{log.emmet_sqlid}</div></td>
                  <td>{log.weapon_name}<div className="ucp-muted" style={{ fontSize: 12 }}>ID {log.weapon_id}</div></td>
                  <td>{log.weapon_ammo.toLocaleString()}</td>
                  <td>${log.purchase_price.toLocaleString()}</td>
                </tr>
              ))}
          </tbody>
        </table>
      </div>
    </>
  )
}
