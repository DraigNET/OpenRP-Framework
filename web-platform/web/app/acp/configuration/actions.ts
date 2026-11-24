'use server'
import { revalidatePath } from 'next/cache'
import { requireStaff } from '@/lib/dal'
import { ADMIN_LVL } from '@/lib/constants'
import { commitRuntimeConfiguration, restoreRuntimeConfiguration } from '@/lib/runtime-config'
import type { RuntimePatch, RuntimeActionResult } from '@/lib/runtime-config-types'

// JSON transport is still untrusted: the shared store checks every field, the
// current database rank and the expected revision inside the save transaction.
export async function saveRuntimeConfiguration(patch:RuntimePatch):Promise<RuntimeActionResult> {
  const user=await requireStaff(ADMIN_LVL.MANAGER)
  try {
    const result=await commitRuntimeConfiguration(patch,user)
    revalidatePath('/acp/configuration')
    return {ok:true,revision:result.revision}
  } catch(error) {
    const e=error as Error & {code?:string}
    if(e.name==='ConfigurationError')return {ok:false,error:e.message,conflict:e.code==='conflict'}
    console.error('Runtime configuration save failed:',e.message)
    return {ok:false,error:'Configuration could not be saved. Check database connectivity and migrations.'}
  }
}
export async function restoreRuntimeRevision(revision:number,expectedRevision:number):Promise<RuntimeActionResult> {
  const user=await requireStaff(ADMIN_LVL.MANAGER)
  try {
    const result=await restoreRuntimeConfiguration(revision,expectedRevision,user)
    revalidatePath('/acp/configuration')
    return {ok:true,revision:result.revision}
  } catch(error) {
    const e=error as Error & {code?:string}
    return {ok:false,error:e.name==='ConfigurationError'?e.message:'Restore failed. Check the database and application logs.',conflict:e.code==='conflict'}
  }
}
