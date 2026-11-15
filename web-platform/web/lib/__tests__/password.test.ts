import { describe, it, expect } from 'vitest'
import bcrypt from 'bcryptjs'
import { verifyPassword, hashPassword } from '../password'

describe('verifyPassword', () => {
  it('verifies a standard $2b$ hash', async () => {
    const hash = await bcrypt.hash('correct horse', 10)
    expect(await verifyPassword('correct horse', hash)).toBe(true)
    expect(await verifyPassword('wrong', hash)).toBe(false)
  })

  it('verifies a PHP-style $2y$ hash by normalising the prefix', async () => {
    // bcryptjs produces $2b$; PHP password_hash produces an identical $2y$ hash.
    const hash2b = await bcrypt.hash('secret123', 10)
    const hash2y = '$2y$' + hash2b.slice(4)
    expect(await verifyPassword('secret123', hash2y)).toBe(true)
    expect(await verifyPassword('nope', hash2y)).toBe(false)
  })

  it('round-trips hashPassword → verifyPassword', async () => {
    const h = await hashPassword('p@ssw0rd!')
    expect(h.startsWith('$2')).toBe(true)
    expect(await verifyPassword('p@ssw0rd!', h)).toBe(true)
  })
})
