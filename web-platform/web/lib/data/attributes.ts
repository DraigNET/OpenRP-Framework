import { FACTION_TYPE_LABEL } from '@/lib/constants'

export const GENDER: Record<number, string> = { 0: 'Unknown', 1: 'Male', 2: 'Female' }

export const RACE: Record<number, string> = { 1: 'White', 2: 'Black', 3: 'Latino', 4: 'Asian' }

export const HAIR: Record<number, string> = {
  1: 'None', 2: 'Black', 3: 'Brown', 4: 'Blonde', 5: 'White', 6: 'Grey', 7: 'Red',
}

export const EYES: Record<number, string> = {
  1: 'Amber', 2: 'Blue', 3: 'Brown', 4: 'Grey', 5: 'Green', 6: 'Hazel',
}

export const BODY: Record<number, string> = {
  1: 'Skinny', 2: 'Slim', 3: 'Normal', 4: 'Plump', 5: 'Obese', 6: 'Muscular',
}

export const FIGHT_STYLE: Record<number, string> = {
  0: 'None', 1: 'Normal', 2: 'Grab & Kick', 3: 'Boxing', 4: 'Kung Fu',
}

export const FACTION_TIER: Record<number, string> = {
  1: 'Owner', 2: 'Command', 3: 'Member', 4: 'Restricted',
}

export const FACTION_TIER_COLOR: Record<number, string> = {
  1: 'text-yellow-400', 2: 'text-blue-400', 3: 'text-green-400', 4: 'text-gray-400',
}

export const FACTION_TIER_BADGE: Record<number, string> = {
  1: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  2: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  3: 'bg-green-500/20 text-green-400 border-green-500/30',
  4: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
}

export const FACTION_TYPE: Record<number, string> = FACTION_TYPE_LABEL

export const RECORD_TYPE: Record<number, string> = { 0: 'Kick', 1: 'Admin Jail', 2: 'Ban' }

export const RECORD_TYPE_BADGE: Record<number, string> = {
  0: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  1: 'bg-orange-500/20 text-orange-400 border-orange-500/30',
  2: 'bg-red-500/20 text-red-400 border-red-500/30',
}

export const DEFAULT_SKIN: Record<number, number> = { 1: 217, 2: 93 }
