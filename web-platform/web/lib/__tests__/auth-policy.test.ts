import { describe, expect, it } from 'vitest'
import { activeBanWhere, safeCallbackUrl } from '../auth-policy'

describe('authentication policy', () => {
  it('includes permanent bans and only future temporary bans', () => {
    expect(activeBanWhere(7, 100)).toEqual({ account_id: 7, OR: [{ unban_time: 0 }, { unban_time: { gt: 100 } }] })
  })
  it.each(['https://outside.test', '//outside.test', '/\\outside.test', 'javascript:alert(1)', '/\n/outside.test'])('rejects unsafe callback %j', value => {
    expect(safeCallbackUrl(value)).toBe('/ucp')
  })
  it('preserves internal paths, queries and anchors', () => {
    expect(safeCallbackUrl('/acp/players?page=2#list')).toBe('/acp/players?page=2#list')
  })
})
