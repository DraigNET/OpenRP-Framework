/**
 * Faction custom-skin rules — shared by the ACP and optional gamemode model loader.
 * Pure (no DB / no server-only) so both the page and its forms can import it.
 */
export const FSKIN_MIN_ID = 20000
export const FSKIN_MAX_ID = 24999
export const FSKIN_MAX_ENABLED = 500
export const FSKIN_PATH_LIMIT = 63

/** Reserved IDs for your own additions; the blank framework reserves no faction skin IDs. */
export const FSKIN_RESERVED: Record<number, string> = {}

export function fskinTierName(tier: number): string {
  switch (tier) {
    case 1: return 'Owner'
    case 2: return 'Command'
    case 3: return 'Member'
    case 4: return 'Restricted'
    default: return `Tier ${tier}`
  }
}

export function fskinValidateFilename(filename: string, ext: 'dff' | 'txd'): boolean {
  return new RegExp(`^[A-Za-z0-9_-]+\\.${ext}$`, 'i').test(filename)
}

export function fskinNormalizeSubfolder(sub: string): string {
  const s = sub.replace(/\\/g, '/').trim()
  if (s === '') return ''
  if (!/^[A-Za-z0-9_-]+$/.test(s)) throw new Error('Subfolder may only contain letters, numbers, underscores, and hyphens.')
  return s
}

export function fskinRelativePath(factionId: number, filename: string, subfolder = ''): string {
  const parts = ['skins_faction', String(factionId)]
  if (subfolder !== '') parts.push(subfolder)
  parts.push(filename)
  const path = parts.join('/')
  if (path.length > FSKIN_PATH_LIMIT) throw new Error('Final model path is too long. Keep it to 63 characters or less.')
  return path
}

export const fskinReservedReason = (id: number): string | null => FSKIN_RESERVED[id] ?? null
export const fskinInRange = (id: number) => id >= FSKIN_MIN_ID && id <= FSKIN_MAX_ID
