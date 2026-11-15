'use server'

import { prisma } from '@/lib/prisma'
import { redirect } from 'next/navigation'
import { requireUser } from '@/lib/dal'
import { DEFAULT_SKIN } from '@/lib/data/attributes'
import { MAX_CHARACTERS_PER_ACCOUNT } from '@/lib/constants'
import { characterCreateSchema } from '@/lib/schemas'

type CreateState = { errors?: Record<string, string> } | undefined

export async function checkCharacterLimit(): Promise<boolean> {
  const user = await requireUser()
  const count = await prisma.character.count({ where: { account_id: user.id } })
  return count >= MAX_CHARACTERS_PER_ACCOUNT
}

export async function createCharacterAction(_prev: CreateState, formData: FormData): Promise<CreateState> {
  const user = await requireUser()

  const count = await prisma.character.count({ where: { account_id: user.id } })
  if (count >= MAX_CHARACTERS_PER_ACCOUNT) {
    return { errors: { general: `You already have the maximum of ${MAX_CHARACTERS_PER_ACCOUNT} characters.` } }
  }

  const parsed = characterCreateSchema.safeParse(Object.fromEntries(formData))
  if (!parsed.success) {
    // Map each field's first issue back to a per-field error for the form UI.
    const errors: Record<string, string> = {}
    for (const issue of parsed.error.issues) {
      const field = String(issue.path[0] ?? 'general')
      if (!errors[field]) errors[field] = issue.message
    }
    return { errors }
  }

  const d = parsed.data
  const playerName = `${d.first_name}_${d.last_name}`

  const existing = await prisma.character.findFirst({ where: { player_name: { equals: playerName } } })
  if (existing) return { errors: { first_name: 'A character with that name already exists.' } }

  await prisma.character.create({
    data: {
      account_id: user.id,
      player_name: playerName,
      player_skinid: DEFAULT_SKIN[d.sex] ?? 217,
      player_attribute_sex: d.sex,
      player_attribute_age: d.age,
      player_attribute_race: d.race,
      player_attribute_hair: d.hair,
      player_attribute_eyes: d.eyes,
      player_attribute_body: d.body,
      player_attribute_height: d.height,
      player_attribute_desc: d.desc,
      player_registered: 1,
      player_registerdate: Math.floor(Date.now() / 1000),
    },
  })

  redirect('/ucp/characters')
}
