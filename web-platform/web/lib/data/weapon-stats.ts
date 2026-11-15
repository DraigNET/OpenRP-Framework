export const AMMO_BONUSES: Record<string, number> = {
  'None': 0.0,
  '9x19mm Parabellum': 2.5,
  '.45 ACP': 3.75,
  '.44 Magnum': 7.0,
  '.30-06 Springfield': 5.0,
  '.308 Winchester': 5.0,
  '.223 Rem': 7.5,
  '12 Gauge': 7.5,
  '7.62x39mm': 3.0,
  '5.56x45mm': 4.0,
  '.357 SIG': 12.5,
  '5.7x28mm': 7.0,
}

export interface WeaponStat {
  name: string
  type: string
  ammo: string
  clip: number
  minDmg: number
  maxDmg: number
  minRange: number
  maxRange: number
}

export const WEAPON_STATS: WeaponStat[] = [
  { name: 'Colt 45', type: 'Pistol', ammo: '9x19mm Parabellum', clip: 17, minDmg: 11, maxDmg: 11, minRange: 10, maxRange: 30 },
  { name: 'Colt 45 Silenced', type: 'Pistol', ammo: '9x19mm Parabellum', clip: 17, minDmg: 6, maxDmg: 10, minRange: 10, maxRange: 25 },
  { name: 'Desert Eagle', type: 'Pistol', ammo: '7.62x39mm', clip: 7, minDmg: 20, maxDmg: 25, minRange: 12, maxRange: 40 },
  { name: 'Police Glock', type: 'Pistol', ammo: '.45 ACP', clip: 7, minDmg: 20, maxDmg: 25, minRange: 12, maxRange: 40 },
  { name: 'Uzi', type: 'SMG', ammo: '9x19mm Parabellum', clip: 50, minDmg: 8, maxDmg: 8, minRange: 10, maxRange: 35 },
  { name: 'TEC-9', type: 'SMG', ammo: '9x19mm Parabellum', clip: 50, minDmg: 8, maxDmg: 8, minRange: 10, maxRange: 25 },
  { name: 'MP5', type: 'SMG', ammo: '9x19mm Parabellum', clip: 30, minDmg: 8, maxDmg: 8, minRange: 9, maxRange: 38 },
  { name: 'AK-47', type: 'Assault Rifle', ammo: '7.62x39mm', clip: 30, minDmg: 11, maxDmg: 11, minRange: 11, maxRange: 39 },
  { name: 'AR-15', type: 'Assault Rifle', ammo: '5.56x45mm', clip: 50, minDmg: 11, maxDmg: 12, minRange: 13, maxRange: 46 },
  { name: 'Shotgun', type: 'Shotgun', ammo: '12 Gauge', clip: 1, minDmg: 10, maxDmg: 40, minRange: 11, maxRange: 35 },
  { name: 'Combat Shotgun', type: 'Shotgun', ammo: '12 Gauge', clip: 7, minDmg: 10, maxDmg: 25, minRange: 14, maxRange: 40 },
  { name: 'Sawn Off Shotgun', type: 'Shotgun', ammo: '12 Gauge', clip: 2, minDmg: 10, maxDmg: 40, minRange: 5, maxRange: 24 },
  { name: 'Bolt Action Rifle', type: 'Rifle', ammo: '.30-06 Springfield', clip: 1, minDmg: 33, maxDmg: 33, minRange: 30, maxRange: 100 },
  { name: 'Sniper Rifle', type: 'Rifle', ammo: '.308 Winchester', clip: 1, minDmg: 53, maxDmg: 53, minRange: 30, maxRange: 100 },
]

export interface DamageSpread {
  closeMin: number; closeMax: number
  midMin: number; midMax: number
  farMin: number; farMax: number
}

export function calcDamage(min: number, max: number, ammoBonus: number): DamageSpread {
  return {
    closeMin: Math.round(min + ammoBonus),
    closeMax: Math.round(max + ammoBonus),
    midMin: Math.round(min * 0.75 + ammoBonus),
    midMax: Math.round(max * 0.75 + ammoBonus),
    farMin: Math.round(min * 0.5 + ammoBonus),
    farMax: Math.round(max * 0.5 + ammoBonus),
  }
}

export function ammoClass(ammo: string): string {
  switch (ammo) {
    case '9x19mm Parabellum': return 'ammo-9mm'
    case '.45 ACP': return 'ammo-45'
    case '7.62x39mm': return 'ammo-762'
    case '5.56x45mm': return 'ammo-556'
    case '12 Gauge': return 'ammo-shotgun'
    case '.308 Winchester':
    case '.30-06 Springfield': return 'ammo-sniper'
    default: return ''
  }
}

export function dmgClass(value: number): string {
  if (value >= 60) return 'dmg-high'
  if (value >= 30) return 'dmg-mid'
  return 'dmg-low'
}
