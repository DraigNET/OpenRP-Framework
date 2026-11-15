'use server'

import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'

const i = (fd: FormData, k: string) => Math.trunc(Number(fd.get(k)) || 0)
const chk = (fd: FormData, k: string) => (fd.get(k) ? 1 : 0)

/** Create or edit an armory type. Editing keeps its lockers/weapons in sync if the faction changes. */
export async function saveType(formData: FormData): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.GENERAL)
  const typeId = i(formData, 'armory_type_id')
  const factionId = i(formData, 'faction_id')
  const name = String(formData.get('type_name') ?? '').trim().slice(0, 32)
  const enabled = chk(formData, 'type_enabled')
  if (!factionId || !name) redirect(`/acp/factions/armory?faction_id=${factionId}`)

  let target = typeId
  if (typeId > 0) {
    await prisma.factionArmoryType.update({ where: { armory_type_id: typeId }, data: { faction_id: factionId, type_name: name, type_enabled: enabled } })
    await prisma.factionArmory.updateMany({ where: { armory_type_id: typeId }, data: { faction_id: factionId } })
    await prisma.factionArmoryWeapon.updateMany({ where: { armory_type_id: typeId }, data: { faction_id: factionId } })
  } else {
    const created = await prisma.factionArmoryType.create({ data: { faction_id: factionId, type_name: name, type_enabled: enabled } })
    target = created.armory_type_id
  }
  await logAdminAction(user, 'armory_type_save', 'faction', factionId, `${typeId > 0 ? 'Updated' : 'Created'} armory type "${name}"`)
  redirect(`/acp/factions/armory?faction_id=${factionId}&type_id=${target}`)
}

/** Add a weapon to a type, or edit an existing row. Editing a faction-wide (legacy)
 *  weapon and saving with a type assigns it to that type. */
export async function saveWeapon(formData: FormData): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.GENERAL)
  const rowId = i(formData, 'armory_weapon_id')
  const typeId = i(formData, 'armory_type_id')
  const type = await prisma.factionArmoryType.findUnique({ where: { armory_type_id: typeId } })
  if (!type) redirect('/acp/factions/armory')
  const factionId = type!.faction_id

  const data = {
    weapon_id: i(formData, 'weapon_id'),
    weapon_ammo: Math.max(0, i(formData, 'weapon_ammo')),
    tier_limit: Math.max(0, Math.min(10, i(formData, 'tier_limit'))),
    squad_id: Math.max(0, i(formData, 'squad_id')),
    off_duty_allowed: chk(formData, 'off_duty_allowed'),
    weapon_enabled: chk(formData, 'weapon_enabled'),
    sort_order: Math.max(0, i(formData, 'sort_order')),
  }
  if (rowId > 0) {
    await prisma.factionArmoryWeapon.update({ where: { armory_weapon_id: rowId }, data: { faction_id: factionId, armory_type_id: typeId, ...data } })
  } else {
    await prisma.factionArmoryWeapon.create({ data: { faction_id: factionId, armory_type_id: typeId, ...data } })
  }
  await logAdminAction(user, 'armory_weapon_save', 'faction', factionId, `${rowId > 0 ? 'Updated' : 'Added'} armory weapon ${data.weapon_id} on type ${type!.type_name}`)
  redirect(`/acp/factions/armory?faction_id=${factionId}&type_id=${typeId}`)
}

export async function deleteWeapon(rowId: number): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.GENERAL)
  const row = await prisma.factionArmoryWeapon.findUnique({ where: { armory_weapon_id: rowId } })
  if (!row) return
  await prisma.factionArmoryWeapon.delete({ where: { armory_weapon_id: rowId } })
  await logAdminAction(user, 'armory_weapon_delete', 'faction', row.faction_id, `Deleted armory weapon row #${rowId}`)
  revalidatePath('/acp/factions/armory')
}
