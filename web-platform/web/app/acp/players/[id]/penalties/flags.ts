/** Account-level penalty flags (columns on accounts). Shared by the penalise
 *  server action and its form — kept out of the 'use server' file because those
 *  may only export async functions. */
export const PENALTY_FLAGS = [
  { key: 'account_gunban', label: 'Gun Ban' },
  { key: 'account_bikeban', label: 'Bike Ban' },
  { key: 'account_facban', label: 'Faction Ban' },
  { key: 'account_vehban', label: 'Vehicle Ban' },
  { key: 'account_sprintban', label: 'Sprint Ban' },
] as const

export type PenaltyFlagKey = (typeof PENALTY_FLAGS)[number]['key']
export interface PenaltyState { ok: boolean; error: string }
export interface OjailState { ok: boolean; error: string; message: string }
