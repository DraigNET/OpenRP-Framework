/**
 * Shared status/semantic colours used across UCP and ACP.
 *
 * These are the literal hex values that were previously copy-pasted inline in
 * dozens of components (e.g. green for "good", red for "bad"). Centralising them
 * means one place to adjust, and self-documenting names at call sites.
 *
 * Note: app *chrome* (backgrounds, borders, accents) is still driven by each
 * app's CSS variables/theme — these are only the semantic status accents that
 * are intentionally consistent everywhere.
 */
export const COLOR = {
  success: '#86efac', // positive / paid / online / valid
  successStrong: '#22c55e',
  danger: '#fca5a5', // negative / overdue / offline / banned
  dangerStrong: '#ef4444',
  warning: '#fde68a', // caution / pending
  warningStrong: '#f59e0b',
  info: '#93c5fd', // neutral highlight (bank, links)
  infoStrong: '#3b82f6',
  muted: '#9ca3af',
  mutedDim: '#6b7280',
} as const

/** Maps a boolean "is this good?" to the standard success/danger pair. */
export function statusColor(ok: boolean, strong = false): string {
  if (strong) return ok ? COLOR.successStrong : COLOR.dangerStrong
  return ok ? COLOR.success : COLOR.danger
}
