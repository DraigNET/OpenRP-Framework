import {describe,it,expect} from 'vitest'
import {publicRuntimeState} from './runtime-config-status'
describe('runtime status transport',()=>{
  it('normalizes unsigned raw-query bigint fields into a JSON-safe payload',()=>{
    const state=publicRuntimeState({revision:BigInt(14),applied_revision:BigInt(13),last_heartbeat:BigInt(1794818509),last_error:'',schema_version:BigInt(1)})
    expect(JSON.parse(JSON.stringify(state))).toEqual({revision:14,applied_revision:13,last_heartbeat:1794818509,last_error:'',schema_version:1})
  })
  it('preserves numeric drivers and unavailable state',()=>{
    expect(publicRuntimeState(null)).toBeNull()
    expect(publicRuntimeState(undefined)).toBeNull()
    expect(publicRuntimeState({revision:1,applied_revision:1,last_heartbeat:0,last_error:'offline',schema_version:1})?.last_error).toBe('offline')
  })
})
