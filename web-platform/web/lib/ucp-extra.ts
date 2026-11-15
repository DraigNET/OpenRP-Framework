/**
 * Figures the v5 UCP design shows that aren't a plain column on a model.
 *
 * Everything here is derived from tables that already exist in the game database
 * (sessions, player_logs, characters.player_on_duty) plus the samp-agent.
 * Each function returns null (UI shows "—") if its source can't be read, so a missing
 * table or an offline agent never breaks a page.
 */
import { Prisma } from '@prisma/client'
import { prisma } from '@/lib/prisma'
import { LEA_FACTION_TYPES } from '@/lib/constants'

const DAY = 86400
const LOG_TYPE_MONEY_FLOW = 19 // gamemode.pwn: LOG_TYPE_MONEY_FLOW

// ── Level progression ──────────────────────────────────────────────────────────

/** paycheck.pwn: level = hours / 8 + 1, so a level is exactly 8 played hours. */
export const HOURS_PER_LEVEL = 8

export function levelProgress(hours: number) {
  const into = hours % HOURS_PER_LEVEL
  return { into, needed: HOURS_PER_LEVEL, pct: Math.round((into / HOURS_PER_LEVEL) * 100) }
}

// ── Server-wide figures ────────────────────────────────────────────────────────

export interface ServerStats {
  maxPlayers: number | null
  /** Highest simultaneous characters logged in since 00:00 UTC, from the sessions table. */
  peakToday: number | null
  /** Seconds since the gamemode process started, from the samp-agent. */
  uptimeSeconds: number | null
  /** Law-enforcement / EMS characters online AND on duty (characters.player_on_duty). */
  lawOnDuty: number | null
}

let uptimeCache: { at: number; value: number | null } | null = null

async function agentUptime(): Promise<number | null> {
  if (uptimeCache && Date.now() - uptimeCache.at < 30_000) return uptimeCache.value
  let value: number | null = null
  try {
    const res = await fetch(`${process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'}/status`, {
      headers: { 'X-Agent-Key': process.env.SAMP_AGENT_KEY ?? '' },
      signal: AbortSignal.timeout(1500),
      cache: 'no-store',
    })
    const data = await res.json()
    value = typeof data.uptime === 'number' ? data.uptime : null
  } catch { /* agent offline */ }
  uptimeCache = { at: Date.now(), value }
  return value
}

async function peakToday(now: number): Promise<number | null> {
  const dayStart = now - (now % DAY)
  try {
    const rows = await prisma.$queryRaw<{ s: number; m: number; l: number }[]>`
      SELECT e_session_unix_store AS s, e_session_time AS m, e_session_unix_last AS l
      FROM sessions WHERE e_session_unix_store >= ${dayStart - DAY}`
    // Sweep line over session start/end points, clipped to today.
    const points: [number, number][] = []
    for (const r of rows) {
      const start = Number(r.s)
      const end = Number(r.l) > 0 ? Number(r.l) : start + Math.max(Number(r.m), 1) * 60
      if (end < dayStart) continue
      points.push([Math.max(start, dayStart), 1], [Math.min(end, now), -1])
    }
    points.sort((a, b) => a[0] - b[0] || a[1] - b[1])
    let cur = 0, peak = 0
    for (const [, d] of points) { cur += d; peak = Math.max(peak, cur) }
    return peak
  } catch { return null }
}

async function lawOnDuty(): Promise<number | null> {
  try {
    const rows = await prisma.$queryRaw<{ c: bigint | number }[]>`
      SELECT COUNT(*) AS c FROM characters ch
      JOIN factions f ON f.faction_id = ch.player_factionid
      WHERE ch.player_online = 1 AND ch.player_on_duty > 0
        AND f.faction_type IN (${Prisma.join([...LEA_FACTION_TYPES])})`
    return Number(rows[0]?.c ?? 0)
  } catch { return null }
}

export async function getServerStats(): Promise<ServerStats> {
  const now = Math.floor(Date.now() / 1000)
  const [uptimeSeconds, peak, law] = await Promise.all([agentUptime(), peakToday(now), lawOnDuty()])
  return {
    maxPlayers: Number(process.env.SAMP_MAX_PLAYERS ?? 150), // server.cfg: maxplayers 150
    peakToday: peak,
    uptimeSeconds,
    lawOnDuty: law,
  }
}

// ── Per-account figures ────────────────────────────────────────────────────────

export interface AccountExtras {
  /** Hours played in the last 7 days (sum of sessions.e_session_time, minutes). */
  hoursThisWeek: number | null
  /**
   * Change in cash + bank + savings across all characters, measured against the oldest
   * daily snapshot inside the last 7 days (character_daily_stats). null until a snapshot
   * at least a day old exists.
   */
  netWorth: { delta: number; days: number } | null
  /** Net cash in minus cash out over the last 7 days (player_logs type 19). Fallback for netWorth. */
  cashFlowThisWeek: number | null
}

// player_logs.log_entry formats written by the gamemode (anticheat/modules/money.pwn, money/paycheck.pwn)
const CASH_RE = /^(Give|Take) Cash: (.*) - Amount: \$(-?\d+)$/
const BANK_CREDIT_RE = /^Bank Credit: (.*) - Amount: \$(\d+)$/
const BANK_DEBIT_RE = /^Bank Debit - Amount: \$(\d+)$/
// Cash that merely moves between wallet and bank isn't income or spending.
const INTERNAL_TRANSFER = new Set(['Bank deposit', 'ATM withdraw'])

export async function getAccountExtras(accountId: number, charIds: number[]): Promise<AccountExtras> {
  const now = Math.floor(Date.now() / 1000)

  let hoursThisWeek: number | null = null
  try {
    const rows = await prisma.$queryRaw<{ m: bigint | number | null }[]>`
      SELECT SUM(e_session_time) AS m FROM sessions
      WHERE e_session_acc = ${accountId} AND e_session_unix_store >= ${now - 7 * DAY}`
    hoursThisWeek = Math.round((Number(rows[0]?.m ?? 0) / 60) * 10) / 10
  } catch { /* sessions unreadable */ }

  let netWorth: AccountExtras['netWorth'] = null
  let cashFlowThisWeek: number | null = null
  if (charIds.length) {
    try {
      const rows = await prisma.$queryRaw<{ now_total: bigint | number | null; then_total: bigint | number | null; n: bigint | number; days: bigint | number | null }[]>`
        SELECT SUM(c.player_cash + c.player_bankcash + c.player_savings) AS now_total,
               SUM(s.cash + s.bank + s.savings) AS then_total,
               COUNT(*) AS n,
               MAX(DATEDIFF(CURDATE(), o.day)) AS days
        FROM characters c
        JOIN (SELECT character_id, MIN(day) AS day FROM character_daily_stats
              WHERE character_id IN (${Prisma.join(charIds)}) AND day >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
              GROUP BY character_id) o ON o.character_id = c.player_id
        JOIN character_daily_stats s ON s.character_id = o.character_id AND s.day = o.day`
      const r = rows[0]
      if (r && Number(r.n) > 0 && Number(r.days ?? 0) >= 1) {
        netWorth = { delta: Number(r.now_total ?? 0) - Number(r.then_total ?? 0), days: Number(r.days) }
      }
    } catch { /* snapshots unreadable */ }

    try {
      const rows = await prisma.$queryRaw<{ log_entry: string }[]>`
        SELECT log_entry FROM player_logs
        WHERE log_type = ${LOG_TYPE_MONEY_FLOW} AND log_char_id IN (${Prisma.join(charIds)})
          AND log_time >= FROM_UNIXTIME(${now - 7 * DAY}) LIMIT 5000`
      cashFlowThisWeek = rows.reduce((sum, r) => {
        const m = CASH_RE.exec(r.log_entry)
        if (!m || INTERNAL_TRANSFER.has(m[2])) return sum
        return sum + (m[1] === 'Give' ? 1 : -1) * Number(m[3])
      }, 0)
    } catch { /* logs unreadable */ }
  }

  return { hoursThisWeek, netWorth, cashFlowThisWeek }
}

// ── Activity feed ──────────────────────────────────────────────────────────────

export interface ActivityItem {
  icon: string
  title: string
  detail?: string
  /** Unix seconds. */
  at: number
}

const NOTIFICATION_ICON: Record<string, string> = {
  faction: 'fa-shield-halved',
  career: 'fa-briefcase',
  level: 'fa-arrow-up-right-dots',
  admin: 'fa-gavel',
}

const usd = (n: number) => `$${Math.abs(n).toLocaleString('en-US')}`

/** Turns one player_logs money-flow line into a feed item, or null for lines we don't show. */
function moneyItem(entry: string, at: number): ActivityItem | null {
  const cash = CASH_RE.exec(entry)
  if (cash) {
    const [, dir, reason, raw] = cash
    const amount = Number(raw)
    if (amount === 0) return null
    if (reason === 'Bank deposit') return { icon: 'fa-building-columns', title: `Deposited ${usd(amount)} to your bank`, at }
    if (reason === 'ATM withdraw') return { icon: 'fa-money-bill-transfer', title: `Withdrew ${usd(amount)} from an ATM`, at }
    return { icon: dir === 'Give' ? 'fa-arrow-down' : 'fa-arrow-up', title: reason, detail: `${dir === 'Give' ? '+' : '−'}${usd(amount)} cash`, at }
  }
  const credit = BANK_CREDIT_RE.exec(entry)
  if (credit && Number(credit[2]) > 0) {
    return { icon: 'fa-building-columns', title: `${credit[1]} paid into your bank`, detail: `+${usd(Number(credit[2]))}`, at }
  }
  const debit = BANK_DEBIT_RE.exec(entry)
  if (debit && Number(debit[1]) > 0) {
    return { icon: 'fa-building-columns', title: 'Bank payment', detail: `−${usd(Number(debit[1]))}`, at }
  }
  return null
}

/**
 * Everything an account has recently done, newest first: character logins, cash and bank
 * movements (player_logs), and the notifications raised by the game and website
 * (promotions and level-ups).
 */
export async function getRecentActivity(accountId: number, charIds: number[], limit = 6): Promise<ActivityItem[]> {
  const items: ActivityItem[] = []

  const [logins, chars] = await Promise.all([
    prisma.characterLoginHistory.findMany({ where: { account_id: accountId }, orderBy: { login_time: 'desc' }, take: limit }),
    prisma.character.findMany({ where: { account_id: accountId }, select: { player_id: true, player_name: true } }),
  ])
  const names = new Map(chars.map(c => [c.player_id, c.player_name.replace(/_/g, ' ')]))
  for (const l of logins) {
    items.push({ icon: 'fa-right-to-bracket', title: `Logged in as ${names.get(l.character_id) ?? 'a character'}`, at: l.login_time })
  }

  if (charIds.length) {
    try {
      const rows = await prisma.$queryRaw<{ log_entry: string; t: Date }[]>`
        SELECT log_entry, log_time AS t FROM player_logs
        WHERE log_type = ${LOG_TYPE_MONEY_FLOW} AND log_char_id IN (${Prisma.join(charIds)})
        ORDER BY log_id DESC LIMIT ${limit * 4}`
      for (const r of rows) {
        const item = moneyItem(r.log_entry, Math.floor(new Date(r.t).getTime() / 1000))
        if (item) items.push(item)
      }
    } catch { /* logs unreadable */ }
  }

  try {
    const notes = await prisma.notification.findMany({
      where: { account_id: accountId },
      orderBy: { created_at: 'desc' },
      take: limit,
    })
    for (const n of notes) {
      items.push({ icon: NOTIFICATION_ICON[n.type] ?? 'fa-circle-info', title: n.title, detail: n.body || undefined, at: n.created_at })
    }
  } catch { /* notifications table not created yet */ }

  return items.sort((a, b) => b.at - a.at).slice(0, limit)
}

// ── Time helper shared by the UI ───────────────────────────────────────────────

export function timeAgo(unixSeconds: number, now = Math.floor(Date.now() / 1000)): string {
  if (!unixSeconds || unixSeconds <= 0) return 'Never'
  const d = Math.max(0, now - unixSeconds)
  if (d < 60) return 'just now'
  if (d < 3600) return `${Math.floor(d / 60)} min ago`
  if (d < 86400) return `${Math.floor(d / 3600)} h ago`
  if (d < 86400 * 30) return `${Math.floor(d / 86400)} d ago`
  return `${Math.floor(d / (86400 * 30))} mo ago`
}
