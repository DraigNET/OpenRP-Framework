export const WEAPON_NAMES: Record<number, string> = {
  1: 'Brass Knuckle', 2: 'Golf Club', 3: 'Nite Stick', 4: 'Knife',
  5: 'Bat', 6: 'Shovel', 7: 'Poolstick', 8: 'Katana', 9: 'Chainsaw',
  10: 'Cane', 11: 'Spray Can', 12: 'Colt 45', 13: 'Colt 45 Silenced',
  14: 'Desert Eagle', 15: 'Uzi', 16: 'TEC-9', 17: 'MP5',
  18: 'AK-47', 19: 'AR-15', 20: 'Shotgun', 21: 'Combat Shotgun',
  22: 'Sawn Off Shotgun', 23: 'Bolt Action Rifle', 24: 'Sniper Rifle',
  25: 'Camera', 26: 'Tazer', 27: 'Fire Extinguisher', 28: 'Police Glock',
  29: 'Licensed Colt .45', 30: 'Licensed Desert Eagle',
}

export function weaponName(id: number): string {
  return WEAPON_NAMES[id] ?? `Weapon #${id}`
}
