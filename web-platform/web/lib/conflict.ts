// Gang conflict logger helpers — ported from the old ucp/includes/conflict.php.
// Cooldowns drive RoE (Rules of Engagement) tracking for turf gangs.

export const FACTION_ATTACKER_COOLDOWN = 28800 // 8h
export const FACTION_DEFENDER_COOLDOWN = 3600 // 1h
export const FACTION_BRAWL_COOLDOWN = 1800 // 30m

export const CONFLICT_OUTCOMES: Record<string, string> = {
  attacker_win: 'Attacker Win',
  defender_win: 'Defender Win',
  stalemate: 'Stalemate',
  mutual_withdrawal: 'Mutual Withdrawal',
  invalid: 'Invalid/Voided',
}

export type ConflictType = 'attack' | 'defense' | 'brawl' | string

/** Current unix time in seconds. */
export function nowUnix(): number {
  return Math.floor(Date.now() / 1000)
}

export function conflictTypeLabel(type: ConflictType): string {
  switch (type) {
    case 'attack': return 'Attack'
    case 'defense': return 'Defense'
    case 'brawl': return 'Brawl'
    default: return 'Unknown'
  }
}

export function conflictOutcomeLabel(outcome?: string | null): string {
  if (!outcome) return 'Not recorded'
  return CONFLICT_OUTCOMES[outcome] ?? 'Unknown'
}

/** Which side the given faction was on for this conflict. */
export function conflictRole(logFactionId: number, type: ConflictType, factionId: number): 'attacker' | 'defender' {
  const isLoggedFaction = logFactionId === factionId
  if ((isLoggedFaction && type === 'defense') || (!isLoggedFaction && type === 'attack')) return 'defender'
  return 'attacker'
}

export function conflictRoleLabel(logFactionId: number, type: ConflictType, factionId: number): string {
  return conflictRole(logFactionId, type, factionId) === 'defender' ? 'Defender' : 'Attacker'
}

export function conflictCooldownSeconds(logFactionId: number, type: ConflictType, factionId: number): number {
  if (type === 'brawl') return FACTION_BRAWL_COOLDOWN
  return conflictRole(logFactionId, type, factionId) === 'defender' ? FACTION_DEFENDER_COOLDOWN : FACTION_ATTACKER_COOLDOWN
}

export function conflictCooldownEnd(logFactionId: number, type: ConflictType, timestamp: number, factionId: number): number {
  return timestamp + conflictCooldownSeconds(logFactionId, type, factionId)
}

export function conflictCooldownActive(logFactionId: number, type: ConflictType, timestamp: number, factionId: number, now = Math.floor(Date.now() / 1000)): boolean {
  return conflictCooldownEnd(logFactionId, type, timestamp, factionId) > now
}

/** Human duration, e.g. "8 hours", "1 hours, 30 minutes", "12 minutes". */
export function conflictDuration(seconds: number): string {
  if (seconds <= 0) return '0 minutes'
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  if (hours > 0 && minutes > 0) return `${hours} hours, ${minutes} minutes`
  if (hours > 0) return `${hours} hours`
  return `${Math.max(1, minutes)} minutes`
}

/** dd/mm/yyyy HH:mm (24h) — matches the old site. */
export function conflictDate(unix: number): string {
  if (!unix) return 'Unknown'
  return new Date(unix * 1000).toLocaleString('en-GB', {
    day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false,
  }).replace(',', '')
}
