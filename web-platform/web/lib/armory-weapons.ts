/** SA-MP weapon ids → names for the faction armory (mirrors acpFactionArmoryWeaponNames). */
export const ARMORY_WEAPONS: Record<number, string> = {
  [-25201]: 'Special Vest Attachment',
  0: 'Fist', 1: 'Brass Knuckles', 2: 'Golf Club', 3: 'Nightstick', 4: 'Knife', 5: 'Baseball Bat',
  6: 'Shovel', 7: 'Pool Cue', 8: 'Katana', 9: 'Chainsaw', 10: 'Cane', 11: 'Spray Can',
  12: 'Colt', 13: 'Silenced Colt', 14: 'Desert Eagle', 15: 'Uzi', 16: 'TEC-9', 17: 'MP5',
  18: 'AK-47', 19: 'M4A1', 20: 'Shotgun', 21: 'Combat Shotgun', 22: 'Sawnoff Shotgun',
  23: 'Rifle', 24: 'Sniper Rifle', 25: 'Camera', 26: 'Tazer', 27: 'Fire Extinguisher',
  28: 'Police Glock', 29: 'Licensed Colt', 30: 'Licensed Desert Eagle', 31: 'Tear Gas',
}

export const armoryWeaponName = (id: number): string => ARMORY_WEAPONS[id] ?? `Weapon #${id}`
/** Selectable weapon options (ordered), for the add-weapon dropdown. */
export const ARMORY_WEAPON_OPTIONS = Object.entries(ARMORY_WEAPONS)
  .map(([id, name]) => ({ id: Number(id), name }))
  .sort((a, b) => a.id - b.id)
