'use server'

import { randomBytes } from 'node:crypto'
import { env } from '@/lib/env'
import { prisma } from '@/lib/prisma'
import { revalidatePath } from 'next/cache'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { logAdminAction } from '@/lib/admin-log'

const AGENT_URL = process.env.SAMP_AGENT_URL ?? 'http://127.0.0.1:7001'
const AGENT_KEY = process.env.SAMP_AGENT_KEY ?? ''

export interface SkinUploadState { error: string; ok: boolean; message: string }

const MAX = 16 * 1024 * 1024

async function agentUpload(rel: string, bytes: Buffer): Promise<void> {
  const res = await fetch(`${AGENT_URL}/upload?path=${encodeURIComponent(rel)}`, {
    method: 'POST',
    headers: { 'X-Agent-Key': AGENT_KEY, 'Content-Type': 'application/octet-stream' },
    body: new Uint8Array(bytes),
    signal: AbortSignal.timeout(60000),
  })
  if (!res.ok) {
    const data = await res.json().catch(() => ({}))
    throw new Error(data.error ?? `Agent upload failed (${res.status})`)
  }
}

export async function uploadCustomSkin(_prev: SkinUploadState, formData: FormData): Promise<SkinUploadState> {
  try {
    return await uploadCustomSkinInner(formData)
  } catch (e) {
    // Production masks thrown action errors; return the real message so the form can show it.
    console.error('[custom-skins] upload failed', e)
    return { error: `Upload failed: ${(e as Error).message}`, ok: false, message: '' }
  }
}

async function uploadCustomSkinInner(formData: FormData): Promise<SkinUploadState> {
  const user = await requireStaff(ADMIN_LVL.MANAGER)
  const fail = (error: string): SkinUploadState => ({ error, ok: false, message: '' })
  if (!env.customSkinsEnabled) return fail('Custom skins are disabled. Configure both the web and gamemode feature flags first.')

  const name = String(formData.get('character_name') ?? '').trim()
  const baseSkinId = Number(formData.get('base_skin_id'))
  if (!name) return fail('Character name is required.')
  if (!Number.isInteger(baseSkinId) || baseSkinId < 0 || baseSkinId > 311 || baseSkinId === 74) {
    return fail('Base skin ID must be 0–311 (and not 74).')
  }

  const character = await prisma.character.findUnique({ where: { player_name: name }, select: { player_id: true, player_name: true } })
  if (!character) return fail(`Character "${name}" not found.`)

  const dff = formData.get('dff_file') as File | null
  const txd = formData.get('txd_file') as File | null
  if (!dff || !txd || dff.size === 0 || txd.size === 0) return fail('DFF and TXD files are required.')
  if (dff.size > MAX || txd.size > MAX) return fail('DFF and TXD files must be 16MB or smaller.')
  if (!dff.name.toLowerCase().endsWith('.dff')) return fail('Invalid DFF file.')
  if (!txd.name.toLowerCase().endsWith('.txd')) return fail('Invalid TXD file.')

  const cid = character.player_id
  const slot = randomBytes(8).toString('hex')
  const dffName = 'skin_' + slot + '.dff'
  const txdName = 'skin_' + slot + '.txd'
  if (await prisma.playerSkin.count() >= 500) return fail('The personal model limit (500) has been reached.')
  const record = await prisma.playerSkin.create({ data: { player_skin_charid: cid, player_skin_baseid: baseSkinId, player_skin_dff: dffName, player_skin_txd: txdName, player_skin_disabled: 1 } })
  if (record.player_skin_id > 4999) { await prisma.playerSkin.delete({ where: { player_skin_id: record.player_skin_id } }); return fail('The personal model ID range is exhausted.') }

  try {
    const dffBytes = Buffer.from(await dff.arrayBuffer())
    const txdBytes = Buffer.from(await txd.arrayBuffer())
    await agentUpload(`customskins/${cid}/${dffName}`, dffBytes)
    await agentUpload(`customskins/${cid}/${txdName}`, txdBytes)
    await prisma.playerSkin.update({ where: { player_skin_id: record.player_skin_id }, data: { player_skin_disabled: 0 } })
    await logAdminAction(user, 'customskin_upload', 'character', cid,
      `Uploaded custom skin baseid=${baseSkinId} slot ${slot} for ${character.player_name}`)
    return { error: '', ok: true, message: `Custom skin #${record.player_skin_id} uploaded. Restart the game server, then use /customskin ${record.player_skin_id}.` }
  } catch (e) {
    await prisma.playerSkin.delete({ where: { player_skin_id: record.player_skin_id } })
    await Promise.allSettled([agentDelete(`customskins/${cid}/${dffName}`), agentDelete(`customskins/${cid}/${txdName}`)])
    return fail(`File write failed: ${(e as Error).message}`)
  }
}

async function agentDelete(rel: string): Promise<void> {
  const res = await fetch(`${AGENT_URL}/file?path=${encodeURIComponent(rel)}`, {
    method: 'DELETE',
    headers: { 'X-Agent-Key': AGENT_KEY },
    signal: AbortSignal.timeout(15000),
  })
  if (!res.ok) {
    const data = await res.json().catch(() => ({}))
    throw new Error(data.error ?? `Agent delete failed (${res.status})`)
  }
}

export async function deleteCustomSkin(skinId: number): Promise<{ error: string }> {
  try {
    const user = await requireStaff(ADMIN_LVL.MANAGER)
    const rows = await prisma.$queryRaw<{ player_skin_charid: number; player_skin_baseid: number; player_skin_dff: string; player_skin_txd: string }[]>`
      SELECT player_skin_charid, player_skin_baseid, player_skin_dff, player_skin_txd
      FROM player_skins WHERE player_skin_id = ${skinId}`
    const row = rows[0]
    if (!row) return { error: 'Skin not found.' }
    for (const f of [row.player_skin_dff, row.player_skin_txd]) {
      if (!/^baseid=\d+_\d+\.(dff|txd)$/.test(f)) return { error: `Refusing to delete unexpected filename "${f}".` }
      await agentDelete(`customskins/${row.player_skin_charid}/${f}`)
    }
    await prisma.$executeRaw`DELETE FROM player_skins WHERE player_skin_id = ${skinId}`
    await logAdminAction(user, 'customskin_delete', 'character', row.player_skin_charid,
      `Deleted custom skin baseid=${row.player_skin_baseid} (${row.player_skin_dff}) from character #${row.player_skin_charid}`)
    revalidatePath('/acp/skins')
    return { error: '' }
  } catch (e) {
    console.error('[custom-skins] delete failed', e)
    return { error: `Delete failed: ${(e as Error).message}` }
  }
}
