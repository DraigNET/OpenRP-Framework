import { describe, it, expect } from 'vitest'
import { characterCreateSchema } from '../schemas'

describe('characterCreateSchema', () => {
  const valid = { first_name: 'John', last_name: 'Smith', sex: '1', age: '25', race: '1', hair: '2', eyes: '3', body: '3', height: '175', desc: '' }

  it('accepts valid input and coerces numeric strings', () => {
    const r = characterCreateSchema.safeParse(valid)
    expect(r.success).toBe(true)
    if (r.success) { expect(r.data.age).toBe(25); expect(r.data.sex).toBe(1) }
  })
  it('rejects lowercase first name', () => {
    expect(characterCreateSchema.safeParse({ ...valid, first_name: 'john' }).success).toBe(false)
  })
  it('rejects names with digits', () => {
    expect(characterCreateSchema.safeParse({ ...valid, last_name: 'Smith2' }).success).toBe(false)
  })
  it('rejects out-of-range age', () => {
    expect(characterCreateSchema.safeParse({ ...valid, age: '15' }).success).toBe(false)
    expect(characterCreateSchema.safeParse({ ...valid, age: '61' }).success).toBe(false)
  })
  it('rejects out-of-range height', () => {
    expect(characterCreateSchema.safeParse({ ...valid, height: '139' }).success).toBe(false)
  })
})
