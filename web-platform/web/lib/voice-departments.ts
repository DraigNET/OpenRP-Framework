// Optional voice departments mirror the two starter factions.

export interface VoiceDepartment {
  key: 'sapd' | 'fdsa'
  prefixes: string[]
}

export function departmentFor(abbrev: string): VoiceDepartment | null {
  const a = abbrev.toUpperCase()
  if (a === 'SAPD') return { key: 'sapd', prefixes: ['sapd-'] }
  if (a === 'FDSA') return { key: 'fdsa', prefixes: ['fdsa-'] }
  return null
}

export const FACTION_COLORS: Record<string, string> = {
  SAPD: '#3b82f6', FDSA: '#ef4444',
}

export function initials(name: string): string {
  const parts = name.replace(/_/g, ' ').trim().split(/\s+/)
  return ((parts[0]?.[0] ?? '') + (parts[1]?.[0] ?? '')).toUpperCase()
}
