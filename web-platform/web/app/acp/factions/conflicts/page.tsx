import { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import {
  conflictTypeLabel, conflictOutcomeLabel, conflictRoleLabel,
  conflictCooldownActive, conflictCooldownEnd, conflictDuration, conflictDate, nowUnix,
} from '@/lib/conflict'
import ConflictTable, { type ConflictRow } from './ConflictTable'

export const dynamic = 'force-dynamic'

const firstParam = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? ''
const fmtName = (n?: string | null) => (n ? n.replace(/_/g, ' ') : 'Unknown')

interface LogRaw {
  conflict_id: number | bigint
  faction_id: number | bigint
  enemy_faction_id: number | bigint | null
  conflict_type: string
  conflict_location: string
  conflict_description: string
  attacker_deaths: number | bigint
  defender_deaths: number | bigint
  conflict_outcome: string | null
  conflict_timestamp: number | bigint
  created_at: number | bigint
  faction_name: string | null
  enemy_faction_name: string | null
  logged_player_name: string | null
}

interface CooldownRaw {
  faction_id: number | bigint
  enemy_faction_id: number | bigint | null
  conflict_type: string
  conflict_timestamp: number | bigint
  faction_name: string | null
  enemy_faction_name: string | null
}

export default async function ConflictsPage({ searchParams }: PageProps<'/acp/factions/conflicts'>) {
  await requireStaff(ADMIN_LVL.SENIOR)
  const sp = await searchParams

  const selectedFactionParam = Math.max(0, Number(firstParam(sp.faction)) || 0)
  let selectedLogView = firstParam(sp.view)
  if (selectedLogView !== 'made' && selectedLogView !== 'involving') selectedLogView = 'made'

  // Gangs (turf factions). faction_type = 1.
  const gangs = await prisma.faction.findMany({
    where: { faction_type: 1 },
    select: { faction_id: true, faction_name: true, faction_abbrev: true },
    orderBy: [{ faction_name: 'asc' }],
  })
  const selectedFaction = gangs.find(g => g.faction_id === selectedFactionParam) ?? null
  const selectedFactionId = selectedFaction ? selectedFactionParam : 0

  const now = nowUnix()

  // Total + every conflict (for the per-faction cooldown map).
  const [{ total }] = await prisma.$queryRaw<{ total: bigint }[]>`SELECT COUNT(*) AS total FROM faction_conflicts`
  const cooldownRows = await prisma.$queryRaw<CooldownRaw[]>`
    SELECT fc.faction_id, fc.enemy_faction_id, fc.conflict_type, fc.conflict_timestamp,
           own.faction_name AS faction_name, enemy.faction_name AS enemy_faction_name
    FROM faction_conflicts fc
    LEFT JOIN factions own ON own.faction_id = fc.faction_id
    LEFT JOIN factions enemy ON enemy.faction_id = fc.enemy_faction_id
    ORDER BY fc.conflict_timestamp DESC, fc.created_at DESC`

  // Latest conflict touching each faction (as logger or enemy).
  const latest = new Map<number, { logFactionId: number; type: string; ts: number; factionName: string | null; enemyName: string | null }>()
  for (const r of cooldownRows) {
    const fid = Number(r.faction_id)
    const eid = r.enemy_faction_id == null ? 0 : Number(r.enemy_faction_id)
    const entry = { logFactionId: fid, type: r.conflict_type, ts: Number(r.conflict_timestamp), factionName: r.faction_name, enemyName: r.enemy_faction_name }
    if (fid > 0 && !latest.has(fid)) latest.set(fid, entry)
    if (eid > 0 && !latest.has(eid)) latest.set(eid, entry)
  }
  let activeCooldowns = 0
  for (const [perspectiveId, v] of latest) {
    if (conflictCooldownEnd(v.logFactionId, v.type, v.ts, perspectiveId) > now) activeCooldowns++
  }

  // Filtered log list.
  let where = Prisma.empty
  if (selectedFactionId > 0) {
    where = selectedLogView === 'involving'
      ? Prisma.sql`WHERE fc.faction_id = ${selectedFactionId} OR fc.enemy_faction_id = ${selectedFactionId}`
      : Prisma.sql`WHERE fc.faction_id = ${selectedFactionId}`
  }
  const logs = await prisma.$queryRaw<LogRaw[]>`
    SELECT fc.conflict_id, fc.faction_id, fc.enemy_faction_id, fc.conflict_type, fc.conflict_location,
           fc.conflict_description, fc.attacker_deaths, fc.defender_deaths, fc.conflict_outcome,
           fc.conflict_timestamp, fc.created_at,
           own.faction_name AS faction_name, enemy.faction_name AS enemy_faction_name,
           logger.player_name AS logged_player_name
    FROM faction_conflicts fc
    LEFT JOIN factions own ON own.faction_id = fc.faction_id
    LEFT JOIN factions enemy ON enemy.faction_id = fc.enemy_faction_id
    LEFT JOIN characters logger ON logger.player_id = fc.logged_player_id
    ${where}
    ORDER BY fc.conflict_timestamp DESC, fc.created_at DESC
    LIMIT 200`

  const rows: ConflictRow[] = logs.map(l => {
    const logFactionId = Number(l.faction_id)
    const ts = Number(l.conflict_timestamp)
    const statusFactionId = selectedFactionId > 0 ? selectedFactionId : logFactionId
    return {
      id: Number(l.conflict_id),
      status: conflictCooldownActive(logFactionId, l.conflict_type, ts, statusFactionId, now) ? 'active' : 'expired',
      faction: l.faction_name ?? 'Unknown',
      type: conflictTypeLabel(l.conflict_type),
      enemy: l.enemy_faction_name ?? 'Unknown',
      attackerDeaths: Number(l.attacker_deaths),
      defenderDeaths: Number(l.defender_deaths),
      outcome: conflictOutcomeLabel(l.conflict_outcome),
      location: l.conflict_location || '',
      loggedBy: fmtName(l.logged_player_name),
      time: conflictDate(ts),
      loggedAt: conflictDate(Number(l.created_at)),
      description: l.conflict_description || '',
    }
  })

  const shortName = selectedFaction ? (selectedFaction.faction_abbrev || selectedFaction.faction_name) : ''
  const pageTitle = selectedFaction
    ? `${shortName}${selectedLogView === 'involving' ? ' Involved Conflict Logs' : ' Conflict Logs'}`
    : 'All Conflict Logs'

  // Selected faction cooldown banner.
  const sel = selectedFactionId > 0 ? latest.get(selectedFactionId) : undefined
  let banner: { onCooldown: boolean; line: string; right: string } | null = null
  if (selectedFactionId > 0) {
    if (sel) {
      const role = conflictRoleLabel(sel.logFactionId, sel.type, selectedFactionId)
      const opposing = sel.logFactionId === selectedFactionId ? (sel.enemyName ?? 'Unknown') : (sel.factionName ?? 'Unknown')
      const end = conflictCooldownEnd(sel.logFactionId, sel.type, sel.ts, selectedFactionId)
      const remaining = Math.max(0, end - now)
      banner = {
        onCooldown: remaining > 0,
        line: `Last conflict: ${conflictTypeLabel(sel.type)} (${role}) vs ${opposing}, ${conflictDuration(now - sel.ts)} ago.`,
        right: remaining > 0 ? `${conflictDuration(remaining)} left` : 'FREE',
      }
    } else {
      banner = { onCooldown: false, line: 'No conflicts have been logged for this gang.', right: 'FREE' }
    }
  }

  return (
    <>
      <section className="acp-panel" style={{ marginBottom: 14 }}>
        <div style={{ padding: 16, display: 'flex', justifyContent: 'space-between', gap: 16, flexWrap: 'wrap', alignItems: 'flex-start' }}>
          <div>
            <h2 style={{ margin: 0, fontSize: 16 }}>{pageTitle}</h2>
            <p style={{ margin: '6px 0 0', color: 'var(--acp-text-2)', fontSize: 12.5, maxWidth: 640 }}>
              Review gang conflict logger entries and current cooldown status for RoE tracking.
            </p>
          </div>
          <form method="get" className="acp-form-row" style={{ padding: 0, gap: 10 }}>
            <div className="acp-field" style={{ minWidth: 240 }}>
              <label>Faction</label>
              <select name="faction" defaultValue={selectedFactionId} className="acp-input">
                <option value={0}>All gang factions</option>
                {gangs.map(g => <option key={g.faction_id} value={g.faction_id}>{g.faction_name}</option>)}
              </select>
            </div>
            <div className="acp-field" style={{ minWidth: 200 }}>
              <label>Log view</label>
              <select name="view" defaultValue={selectedLogView} className="acp-input">
                <option value="made">Logs made by faction</option>
                <option value="involving">Logs involving faction</option>
              </select>
            </div>
            <div className="acp-actions"><button type="submit" className="acp-btn acp-btn-primary">Load</button></div>
          </form>
        </div>
      </section>

      <div className="acp-statusbar">
        <div className="acp-status"><span className="acp-status-val">{total.toLocaleString()}</span><span className="acp-status-lbl">Total Logs</span></div>
        <div className="acp-status"><span className={`acp-status-val ${activeCooldowns > 0 ? 'is-red' : 'is-green'}`}>{activeCooldowns.toLocaleString()}</span><span className="acp-status-lbl">Active Cooldowns</span></div>
        <div className="acp-status">
          <span className="acp-status-val">{selectedFaction ? shortName : 'All Gangs'}</span>
          <span className="acp-status-lbl">{selectedFaction ? (selectedLogView === 'involving' ? 'Involving faction' : 'Made by faction') : 'Viewing'}</span>
        </div>
      </div>

      {banner && (
        <div className={`acp-alert ${banner.onCooldown ? 'acp-alert-danger' : 'acp-alert-ok'}`} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
          <div>
            <strong style={{ fontSize: 14 }}>{banner.onCooldown ? 'Faction On Cooldown' : 'No Active Cooldown'}</strong>
            <div style={{ marginTop: 3, opacity: 0.9 }}>{banner.line}</div>
          </div>
          <div style={{ fontSize: 18, fontWeight: 700, whiteSpace: 'nowrap' }}>{banner.right}</div>
        </div>
      )}

      <section className="acp-panel">
        <div className="acp-panel-head"><span>Conflict Logs — latest {rows.length}</span></div>
        <ConflictTable rows={rows} />
      </section>
    </>
  )
}
