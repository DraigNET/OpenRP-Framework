'use server'

import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { revalidatePath } from 'next/cache'

export type CommandState = { error?: string; ok?: boolean } | undefined

export async function scheduleMaintenance(_prev: CommandState, formData: FormData): Promise<CommandState> {
  const user = await requireStaff(ADMIN_LVL.LEAD)

  const raw = Number(formData.get('seconds'))
  if (!Number.isInteger(raw) || raw < 30 || raw > 21600) {
    return { error: 'Seconds must be between 30 and 21600.' }
  }

  await prisma.webCommand.create({
    data: {
      command:   'maintenance',
      params:    String(raw),
      issued_by: user.id,
    },
  })

  revalidatePath('/acp/commands')
  return { ok: true }
}
