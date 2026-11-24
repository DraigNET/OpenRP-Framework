import { assertACPEntityChanges,assertACPEntityType } from '../../shared/runtime-config/acp-entities.mjs'
import { getEntities } from '../../shared/runtime-config/entity-store.mjs'
import 'server-only'
import * as mariadb from 'mariadb'
import type { RuntimeConfiguration, RuntimeHistory, RuntimePatch } from '../../shared/runtime-config/types'
import { getConfiguration, getHistory, saveConfiguration, restoreConfiguration } from '../../shared/runtime-config/store.mjs'
import type { SessionUser } from './dal'

// A short-lived connection bounds the transaction to one request. The shared
// repository has no dependency on Next.js and is reusable by the desktop editor.
async function connection() {
  const url = new URL(process.env.DATABASE_URL!)
  return mariadb.createConnection({ host:url.hostname, port:Number(url.port||3306), user:decodeURIComponent(url.username), password:decodeURIComponent(url.password), database:url.pathname.slice(1), connectTimeout:5000,queryTimeout:10000,socketTimeout:15000 })
}
export async function loadRuntimeConfiguration():Promise<RuntimeConfiguration> {
  const db=await connection()
  try { return await getConfiguration(db) as RuntimeConfiguration } finally { await db.end() }
}
export async function loadRuntimeHistory():Promise<RuntimeHistory[]> {
  const db=await connection()
  try { return await getHistory(db) as RuntimeHistory[] } finally { await db.end() }
}
export async function commitRuntimeConfiguration(patch:RuntimePatch,user:SessionUser) {
  assertACPEntityChanges(patch.entities)
  const db=await connection()
  try { return await saveConfiguration(db,patch,{id:user.id,name:user.name,source:'acp'}) } finally { await db.end() }
}
export async function restoreRuntimeConfiguration(revision:number,expectedRevision:number,user:SessionUser) {
  const db=await connection()
  try { return await restoreConfiguration(db,revision,expectedRevision,{id:user.id,name:user.name,source:'acp'}) } finally { await db.end() }
}

export async function loadRuntimeEntities(type:string) {
  assertACPEntityType(type)
  const db=await connection()
  try { return await getEntities(db,type) } finally { await db.end() }
}
