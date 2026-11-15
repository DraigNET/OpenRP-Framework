'use server'

import { redirect } from 'next/navigation'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'

const i = (fd: FormData, k: string) => Math.trunc(Number(fd.get(k)) || 0)

/** Create or edit a locker. New lockers start unplaced at 0,0,-1000 (placed in-game
 *  with /armoryplace). Editing never changes position/interior/vw. */
export async function saveLocker(formData: FormData): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.GENERAL)
  const armoryId = i(formData, 'armory_id')
  const factionId = i(formData, 'faction_id')
  const typeId = i(formData, 'armory_type_id')
  const name = String(formData.get('armory_name') ?? '').trim().slice(0, 64)
  const desc = String(formData.get('armory_desc') ?? '').trim().slice(0, 128)
  const enabled = formData.get('armory_enabled') ? 1 : 0
  const squad = Math.max(0, Math.min(127, i(formData, 'armory_squad')))

  if (!factionId || !typeId || !name) redirect(`/acp/factions/lockers?faction_id=${factionId}`)
  const type = await prisma.factionArmoryType.findUnique({ where: { armory_type_id: typeId } })
  if (!type || type.faction_id !== factionId) redirect(`/acp/factions/lockers?faction_id=${factionId}`)

  if (armoryId > 0) {
    await prisma.factionArmory.update({
      where: { armory_id: armoryId },
      data: { faction_id: factionId, armory_type_id: typeId, armory_name: name, armory_desc: desc, armory_enabled: enabled, armory_squad: squad },
    })
    await logAdminAction(user, 'armory_locker_save', 'faction', factionId, `Updated locker #${armoryId} "${name}"`)
  } else {
    const created = await prisma.factionArmory.create({
      data: { faction_id: factionId, armory_type_id: typeId, armory_name: name, armory_desc: desc, armory_x: 0, armory_y: 0, armory_z: -1000, armory_int: 0, armory_vw: 0, armory_enabled: enabled, armory_squad: squad },
    })
    await logAdminAction(user, 'armory_locker_save', 'faction', factionId, `Created locker #${created.armory_id} "${name}"`)
  }
  redirect(`/acp/factions/lockers?faction_id=${factionId}`)
}
