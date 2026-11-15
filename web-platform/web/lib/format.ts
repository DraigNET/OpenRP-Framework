export function formatCash(amount: number): string {
  return '$' + amount.toLocaleString('en-US')
}

export function formatHeight(cm: number): string {
  const totalInches = Math.round(cm / 2.54)
  const feet = Math.floor(totalInches / 12)
  const inches = totalInches % 12
  return `${feet}'${inches}" (${cm}cm)`
}

export function formatHours(hours: number): string {
  if (hours < 24) return `${hours}h`
  const days = Math.floor(hours / 24)
  const remaining = hours % 24
  return remaining > 0 ? `${days}d ${remaining}h` : `${days}d`
}

export function formatUnixDate(unix: number): string {
  if (!unix) return 'Never'
  return new Date(unix * 1000).toLocaleDateString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}

export function formatUnixDateTime(unix: number): string {
  if (!unix) return 'Never'
  return new Date(unix * 1000).toLocaleDateString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

export function formatDateTime(date: Date | null | undefined): string {
  if (!date) return 'Never'
  return date.toLocaleDateString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

export function clamp(val: number, min = 0, max = 100): number {
  return Math.min(max, Math.max(min, val))
}

export function statPercent(val: number, max = 100): number {
  return clamp((val / max) * 100)
}

/**
 * Converts a SA-MP faction colour (stored as 0xRRGGBBAA, signed 32-bit in DB)
 * into a CSS rgb() string, dropping the alpha byte. Mirrors the game/old-site logic.
 */
export function factionHexToRgb(hex: number | null | undefined, fallback = '#3b82f6'): string {
  if (!hex || Number.isNaN(hex)) return fallback
  const n = hex >>> 0 // signed → unsigned 32-bit
  const r = (n >> 24) & 0xff
  const g = (n >> 16) & 0xff
  const b = (n >> 8) & 0xff
  return `rgb(${r}, ${g}, ${b})`
}
