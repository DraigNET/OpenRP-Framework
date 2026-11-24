import type {RuntimeState} from './runtime-config-types'
type DatabaseState={revision:number|bigint;applied_revision:number|bigint;last_heartbeat:number|bigint;last_error:string;schema_version:number|bigint}
/** Prisma raw MariaDB unsigned INTs may be bigint; HTTP payloads use safe numbers. */
export function publicRuntimeState(state:DatabaseState|null|undefined):RuntimeState|null {
  return state?{revision:Number(state.revision),applied_revision:Number(state.applied_revision),last_heartbeat:Number(state.last_heartbeat),last_error:state.last_error,schema_version:Number(state.schema_version)}:null
}
