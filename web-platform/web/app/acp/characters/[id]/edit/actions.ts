'use server'

import { revalidatePath } from 'next/cache'
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'

export interface CharEditState { error: string; ok: boolean }

const int = (fd: FormData, k: string) => Math.trunc(Number(fd.get(k)) || 0)
const chk = (fd: FormData, k: string) => (fd.get(k) ? 1 : 0)

export async function updateCharacter(_prev: CharEditState, formData: FormData): Promise<CharEditState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const charId = Number(formData.get('player_id'))
  const character = await prisma.character.findUnique({ where: { player_id: charId } })
  if (!character) return { error: 'Character not found.', ok: false }

  const name = String(formData.get('player_name') ?? '').trim()
  if (!name) return { error: 'Name is required.', ok: false }

  try {
    await prisma.character.update({
      where: { player_id: charId },
      data: {
        player_name: name,
        player_cash: int(formData, 'player_cash'),
        player_bankcash: int(formData, 'player_bankcash'),
        player_savings: int(formData, 'player_savings'),
        player_level: int(formData, 'player_level'),
        player_hours: int(formData, 'player_hours'),
        player_factionid: int(formData, 'player_factionid'),
        player_factionrank: String(formData.get('player_factionrank') ?? ''),
        player_factiontier: int(formData, 'player_factiontier'),
        player_factionsquad: int(formData, 'player_factionsquad'),
        player_factionsquad2: int(formData, 'player_factionsquad2'),
        player_factionsquad3: int(formData, 'player_factionsquad3'),
        player_factionbadge: int(formData, 'player_factionbadge'),
        player_driverslicense: chk(formData, 'player_driverslicense'),
        player_gunlicense: chk(formData, 'player_gunlicense'),
        player_ccwlicense: chk(formData, 'player_ccwlicense'),
        player_outstanding_fines: int(formData, 'player_outstanding_fines'),
        player_ajail_time: int(formData, 'player_ajail_time'),
      },
    })
  } catch {
    return { error: 'Update failed (is the name already taken?).', ok: false }
  }

  await logAdminAction(user, 'character_edit', 'character', charId, `Edited character ${name}`)
  revalidatePath(`/acp/characters/${charId}/edit`)
  revalidatePath(`/acp/characters/${charId}`)
  return { error: '', ok: true }
}

export async function deleteOwnedVehicle(charId: number, vehicleSqlId: number): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const res = await prisma.vehicle.deleteMany({ where: { vehicle_sqlid: vehicleSqlId, vehicle_owner: charId, vehicle_type: 3 } })
  if (res.count > 0) await logAdminAction(user, 'vehicle_delete', 'character', charId, `Deleted owned vehicle #${vehicleSqlId}`)
  revalidatePath(`/acp/characters/${charId}/edit`)
}
