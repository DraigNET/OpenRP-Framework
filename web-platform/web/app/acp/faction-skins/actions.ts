'use server'

import { env } from '@/lib/env'
import { revalidatePath } from 'next/cache'

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''
import { prisma } from '@/lib/prisma'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'
import {
  FSKIN_MIN_ID, FSKIN_MAX_ID, FSKIN_MAX_ENABLED, FSKIN_RESERVED,
  fskinValidateFilename, fskinNormalizeSubfolder, fskinRelativePath, fskinReservedReason,
} from '@/lib/faction-skins'

export interface UploadState { error: string; ok: boolean; message: string }

async function findNextSkinId(): Promise<number | null> {
  const rows = await prisma.factionCustomModel.findMany({
    where: { faction_model_skinid: { gte: FSKIN_MIN_ID, lte: FSKIN_MAX_ID } },
    select: { faction_model_skinid: true },
  })
  const used = new Set<number>(rows.map(r => r.faction_model_skinid))
  for (const id of Object.keys(FSKIN_RESERVED)) used.add(Number(id))
  for (let id = FSKIN_MIN_ID; id <= FSKIN_MAX_ID; id++) if (!used.has(id)) return id
  return null
}

async function writeModelFile(factionId: number, subfolder: string, filename: string, bytes: Buffer): Promise<void> {
  const rel = subfolder
    ? `skins_faction/${factionId}/${subfolder}/${filename}`
    : `skins_faction/${factionId}/${filename}`
  const res = await fetch(`${AGENT_URL}/upload?path=${encodeURIComponent(rel)}`, {
    method: 'POST',
    headers: { 'X-Agent-Key': AGENT_KEY, 'Content-Type': 'application/octet-stream' },
    body: new Uint8Array(bytes),
    signal: AbortSignal.timeout(15000),
  })
  if (!res.ok) {
    const data = await res.json().catch(() => ({}))
    throw new Error(data.error ?? `Agent upload failed (${res.status})`)
  }
}

export async function uploadModel(_prev: UploadState, formData: FormData): Promise<UploadState> {
  try {
    return await uploadModelInner(formData)
  } catch (e) {
    // Production masks thrown action errors; return the real message so the form can show it.
    console.error('[faction-skins] upload failed', e)
    return { error: `Upload failed: ${(e as Error).message}`, ok: false, message: '' }
  }
}

async function uploadModelInner(formData: FormData): Promise<UploadState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const fail = (error: string): UploadState => ({ error, ok: false, message: '' })
  if (!env.customSkinsEnabled) return fail('Custom model uploads are disabled. Enable both the web and gamemode feature flags first.')

  const factionId = Number(formData.get('faction_id'))
  const baseSkinId = Number(formData.get('base_skin_id'))
  const skinIdInput = String(formData.get('skin_id') ?? '').trim()
  const enabled = formData.get('enabled') ? 1 : 0

  let subfolder: string
  try { subfolder = fskinNormalizeSubfolder(String(formData.get('subfolder') ?? '')) }
  catch (e) { return fail((e as Error).message) }

  if (!factionId || !(await prisma.faction.findUnique({ where: { faction_id: factionId } }))) return fail('Faction does not exist.')
  if (!Number.isInteger(baseSkinId) || baseSkinId < 0 || baseSkinId > 311 || baseSkinId === 74) return fail('Base skin ID must be between 1 and 311.')

  let skinId: number
  if (skinIdInput === '') {
    const next = await findNextSkinId()
    if (next === null) return fail('No custom skin IDs are available.')
    skinId = next
  } else {
    if (!/^\d+$/.test(skinIdInput)) return fail('Custom skin ID must be a number.')
    skinId = Number(skinIdInput)
  }
  if (skinId < FSKIN_MIN_ID || skinId > FSKIN_MAX_ID) return fail(`Custom skin ID must be between ${FSKIN_MIN_ID} and ${FSKIN_MAX_ID}.`)
  const reserved = fskinReservedReason(skinId)
  if (reserved) return fail(`Custom skin ID ${skinId} is reserved: ${reserved}.`)
  if (await prisma.factionCustomModel.findFirst({ where: { faction_model_skinid: skinId } })) return fail('That custom skin ID is already registered.')

  if (enabled) {
    const enabledCount = await prisma.factionCustomModel.count({ where: { faction_model_enabled: 1 } })
    if (enabledCount >= FSKIN_MAX_ENABLED) return fail('The enabled faction model limit has already been reached.')
  }

  const dff = formData.get('dff_file') as File | null
  const txd = formData.get('txd_file') as File | null
  if (dff && txd && (dff.size > 16 * 1024 * 1024 || txd.size > 16 * 1024 * 1024)) return fail('Model files must be 16 MiB or smaller.')
  if (!dff || !txd || dff.size === 0 || txd.size === 0) return fail('DFF and TXD files are required.')
  if (!fskinValidateFilename(dff.name, 'dff')) return fail('DFF filename may only contain letters, numbers, underscores, and hyphens.')
  if (!fskinValidateFilename(txd.name, 'txd')) return fail('TXD filename may only contain letters, numbers, underscores, and hyphens.')

  let dffPath: string, txdPath: string
  try { dffPath = fskinRelativePath(factionId, dff.name, subfolder); txdPath = fskinRelativePath(factionId, txd.name, subfolder) }
  catch (e) { return fail((e as Error).message) }

  try {
    const dffBytes = Buffer.from(await dff.arrayBuffer())
    const txdBytes = Buffer.from(await txd.arrayBuffer())
    await writeModelFile(factionId, subfolder, dff.name, dffBytes)
    await writeModelFile(factionId, subfolder, txd.name, txdBytes)
    await prisma.factionCustomModel.create({
      data: {
        faction_model_factionid: factionId, faction_model_baseid: baseSkinId, faction_model_skinid: skinId,
        faction_model_dff: dffPath, faction_model_txd: txdPath, faction_model_enabled: enabled,
      },
    })
    await logAdminAction(user, 'fskin_upload', 'faction', factionId, `Uploaded faction model ${skinId} (base ${baseSkinId})`)
    revalidatePath('/acp/faction-skins')
    return { error: '', ok: true, message: `Model ${skinId} uploaded. Restart the server before it loads.` }
  } catch (e) {
    return fail(`File write failed: ${(e as Error).message}`)
  }
}

export async function toggleModel(modelId: number, enable: boolean): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const model = await prisma.factionCustomModel.findUnique({ where: { faction_model_id: modelId } })
  if (!model) return
  if (enable) {
    const enabledCount = await prisma.factionCustomModel.count({ where: { faction_model_enabled: 1 } })
    if (enabledCount >= FSKIN_MAX_ENABLED) return
  }
  await prisma.factionCustomModel.update({ where: { faction_model_id: modelId }, data: { faction_model_enabled: enable ? 1 : 0 } })
  await logAdminAction(user, 'fskin_toggle', 'faction', model.faction_model_factionid, `${enable ? 'Enabled' : 'Disabled'} faction model ${model.faction_model_skinid}`)
  revalidatePath('/acp/faction-skins')
}

export async function updateBaseSkin(modelId: number, baseSkinId: number): Promise<{ error: string }> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  if (!Number.isInteger(baseSkinId) || baseSkinId < 1 || baseSkinId > 311) return { error: 'Base skin ID must be between 1 and 311.' }
  const model = await prisma.factionCustomModel.findUnique({ where: { faction_model_id: modelId } })
  if (!model) return { error: 'Model not found.' }
  if (model.faction_model_baseid === baseSkinId) return { error: '' }
  await prisma.factionCustomModel.update({ where: { faction_model_id: modelId }, data: { faction_model_baseid: baseSkinId } })
  await logAdminAction(user, 'fskin_edit_base', 'faction', model.faction_model_factionid, `Changed base skin of model ${model.faction_model_skinid} from ${model.faction_model_baseid} to ${baseSkinId}`)
  revalidatePath('/acp/faction-skins')
  return { error: '' }
}

export async function addUsable(formData: FormData): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const factionId = Number(formData.get('faction_id'))
  const skinId = Number(formData.get('skin_id'))
  const tier = Math.max(0, Math.min(4, Number(formData.get('tier')) || 0))
  const squad = Math.max(0, Math.min(127, Number(formData.get('squad')) || 0))
  const lockerType = Math.max(0, Math.trunc(Number(formData.get('locker_type')) || 0))
  if (!factionId || !skinId) return
  await prisma.factionSkin.create({
    data: { faction_skin_factionid: factionId, faction_skin_skinid: skinId, faction_skin_tier: tier, faction_skin_squad: squad, faction_skin_armory_type: lockerType },
  })
  await logAdminAction(user, 'fskin_add_usable', 'faction', factionId, `Made skin ${skinId} usable (tier ${tier}, squad ${squad}, locker type ${lockerType})`)
  revalidatePath('/acp/faction-skins')
}

/** Save every edited usable-skin row of a faction in one go. Only rows that changed are written. */
export async function updateAllUsable(formData: FormData): Promise<string> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const factionId = Math.trunc(Number(formData.get('faction_id')) || 0)
  if (!factionId) return 'Nothing to save'
  const rows = await prisma.factionSkin.findMany({ where: { faction_skin_factionid: factionId } })

  const num = (key: string, fallback: number, max: number) => {
    const raw = formData.get(key)
    if (raw === null || raw === '') return fallback
    return Math.max(0, Math.min(max, Math.trunc(Number(raw)) || 0))
  }

  const updates = []
  for (const r of rows) {
    const id = r.faction_skin_id
    const tier = num(`tier_${id}`, r.faction_skin_tier, 4)
    const squad = num(`squad_${id}`, r.faction_skin_squad, 127)
    const lockerType = num(`locker_${id}`, r.faction_skin_armory_type, 1_000_000)
    if (tier === r.faction_skin_tier && squad === r.faction_skin_squad && lockerType === r.faction_skin_armory_type) continue
    updates.push(prisma.factionSkin.update({
      where: { faction_skin_id: id },
      data: { faction_skin_tier: tier, faction_skin_squad: squad, faction_skin_armory_type: lockerType },
    }))
  }

  if (updates.length) {
    await prisma.$transaction(updates)
    await logAdminAction(user, 'fskin_edit_usable', 'faction', factionId, `Saved ${updates.length} usable skin row(s)`)
  }
  revalidatePath('/acp/faction-skins')
  return updates.length ? 'All changes saved' : 'No changes to save'
}

/** Give every usable skin of a faction that is still offered at every locker a locker type. */
export async function setLockerTypeForUntyped(formData: FormData): Promise<string> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const factionId = Math.trunc(Number(formData.get('faction_id')) || 0)
  const lockerType = Math.trunc(Number(formData.get('locker_type')) || 0)
  if (!factionId || lockerType < 1) return 'Enter a locker type id'
  const res = await prisma.factionSkin.updateMany({
    where: { faction_skin_factionid: factionId, faction_skin_armory_type: 0 },
    data: { faction_skin_armory_type: lockerType },
  })
  await logAdminAction(user, 'fskin_bulk_locker', 'faction', factionId, `Set locker type ${lockerType} on ${res.count} usable skin row(s)`)
  revalidatePath('/acp/faction-skins')
  return res.count ? `Locker type set on ${res.count} row${res.count === 1 ? '' : 's'}` : 'No rows were set to Every locker'
}

export async function deleteUsable(rowId: number): Promise<void> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const row = await prisma.factionSkin.findUnique({ where: { faction_skin_id: rowId } })
  if (!row) return
  await prisma.factionSkin.delete({ where: { faction_skin_id: rowId } })
  await logAdminAction(user, 'fskin_remove_usable', 'faction', row.faction_skin_factionid, `Removed usable skin ${row.faction_skin_skinid}`)
  revalidatePath('/acp/faction-skins')
}
