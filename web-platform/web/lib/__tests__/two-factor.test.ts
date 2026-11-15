import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
const mocks = vi.hoisted(() => ({ updateMany: vi.fn(), sendMail: vi.fn() }))
vi.mock('server-only', () => ({}))
vi.mock('@/lib/prisma', () => ({ prisma: { account: { updateMany: mocks.updateMany } } }))
vi.mock('@/lib/email', () => ({ sendLoginCode: mocks.sendMail }))
import { checkEmailCode, codeDigest } from '../two-factor'

describe('email second factor', () => {
  let row: Record<string, unknown>
  beforeEach(() => {
    vi.useFakeTimers(); vi.setSystemTime(new Date('2026-01-01T00:00:00Z'))
    vi.stubEnv('AUTH_SECRET', 'unit-test-secret-not-a-production-key'); vi.stubEnv('SMTP_HOST', 'mail.test')
    row = { account_id: 1, twofa_code_hash: null, twofa_expires: null, twofa_last_sent: null, twofa_attempts: 0 }
    mocks.sendMail.mockReset().mockResolvedValue(undefined)
    const matches = (where: Record<string, unknown>): boolean => Object.entries(where).every(([key, value]) => {
      if (key === 'OR') return (value as Record<string, unknown>[]).some(matches)
      if (value && typeof value === 'object') return Object.entries(value).every(([op, n]) => op === 'gt' ? Number(row[key]) > Number(n) : op === 'lt' ? Number(row[key]) < Number(n) : Number(row[key]) <= Number(n))
      return row[key] === value
    })
    mocks.updateMany.mockReset().mockImplementation(async ({ where, data }) => {
      if (!matches(where)) return { count: 0 }
      for (const [key, value] of Object.entries(data)) row[key] = value && typeof value === 'object' && 'increment' in value ? Number(row[key]) + Number(value.increment) : value
      return { count: 1 }
    })
  })
  afterEach(() => { vi.useRealTimers(); vi.unstubAllEnvs() })
  async function issue() {
    expect(await checkEmailCode(1, 'owner@example.test', '')).toBe('required')
    return String(mocks.sendMail.mock.calls[0][1])
  }
  it('stores a digest, not the emailed code, and prevents reuse', async () => {
    const code = await issue()
    expect(row.twofa_code_hash).toBe(codeDigest(1, code)); expect(row.twofa_code_hash).not.toBe(code)
    expect(await checkEmailCode(1, 'owner@example.test', code)).toBe('ok')
    expect(await checkEmailCode(1, 'owner@example.test', code)).toBe('invalid')
  })
  it('rejects expired codes', async () => {
    const code = await issue(); vi.advanceTimersByTime(301000)
    expect(await checkEmailCode(1, 'owner@example.test', code)).toBe('invalid')
  })
  it('locks a challenge after five wrong codes across callers', async () => {
    const code = await issue(); const wrong = code === '111111' ? '222222' : '111111'
    for (let i = 0; i < 5; i++) expect(await checkEmailCode(1, 'owner@example.test', wrong)).toBe('invalid')
    expect(await checkEmailCode(1, 'owner@example.test', code)).toBe('invalid')
  })
  it('rate limits email resends', async () => {
    await issue(); await checkEmailCode(1, 'owner@example.test', '')
    expect(mocks.sendMail).toHaveBeenCalledTimes(1)
    vi.advanceTimersByTime(61000); await checkEmailCode(1, 'owner@example.test', '')
    expect(mocks.sendMail).toHaveBeenCalledTimes(2)
  })
  it('clears an undeliverable challenge and fails closed', async () => {
    mocks.sendMail.mockRejectedValueOnce(new Error('mail offline'))
    await expect(checkEmailCode(1, 'owner@example.test', '')).rejects.toThrow('mail offline')
    expect(row.twofa_code_hash).toBeNull()
  })
})
