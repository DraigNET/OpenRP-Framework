import { describe, it, expect } from 'vitest'
import { isLeaFaction, isGangFaction, isHelicopter, callLabel, callColor, FACTION_TYPE_ID } from '../constants'
import { factionHexToRgb } from '../format'

describe('faction type helpers', () => {
  it('classifies LEA factions', () => {
    expect(isLeaFaction(FACTION_TYPE_ID.LEO)).toBe(true)
    expect(isLeaFaction(FACTION_TYPE_ID.EMS)).toBe(true)
    expect(isLeaFaction(FACTION_TYPE_ID.ILLEGAL)).toBe(false)
  })
  it('classifies gang factions', () => {
    expect(isGangFaction(FACTION_TYPE_ID.ILLEGAL)).toBe(true)
    expect(isGangFaction(FACTION_TYPE_ID.LEO)).toBe(false)
  })
})

describe('helicopter + call helpers', () => {
  it('identifies the police maverick as a helicopter', () => {
    expect(isHelicopter(497)).toBe(true)
    expect(isHelicopter(411)).toBe(false)
  })
  it('labels call types', () => {
    expect(callLabel(1)).toBe('Police')
    expect(callLabel(2)).toBe('Medical')
    expect(callLabel(3)).toBe('Robbery')
    expect(callLabel(99)).toBe('Unknown')
  })
  it('colours call types', () => {
    expect(callColor(2)).toBe('#ef4444')
    expect(callColor(99)).toBe('#9ca3af')
  })
})

describe('factionHexToRgb', () => {
  it('reads SA-MP 0xRRGGBBAA, dropping the alpha byte', () => {
    // LSPD stored value 978514175 = 0x3A52F0FF → rgb(58, 82, 240)
    expect(factionHexToRgb(978514175)).toBe('rgb(58, 82, 240)')
  })
  it('handles signed (negative) 32-bit values', () => {
    // -12887809 → 0xFF3B58FF → rgb(255, 59, 88)
    expect(factionHexToRgb(-12887809)).toBe('rgb(255, 59, 88)')
  })
  it('falls back when null/zero', () => {
    expect(factionHexToRgb(null)).toBe('#3b82f6')
    expect(factionHexToRgb(0)).toBe('#3b82f6')
  })
})
