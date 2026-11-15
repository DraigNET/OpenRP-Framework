import { describe, it, expect } from 'vitest'
import { parsePlayersPacket } from '../sampquery'

/** Builds a valid SA-MP 'd' response packet from a player list. */
function buildPacket(players: { id: number; name: string; score: number; ping: number }[]): Buffer {
  const header = Buffer.alloc(11) // contents irrelevant to the parser (it skips 11 bytes)
  const count = Buffer.alloc(2)
  count.writeUInt16LE(players.length, 0)
  const parts: Buffer[] = [header, count]
  for (const p of players) {
    const name = Buffer.from(p.name, 'utf8')
    const rec = Buffer.alloc(2 + name.length + 8)
    let o = 0
    rec[o++] = p.id
    rec[o++] = name.length
    name.copy(rec, o); o += name.length
    rec.writeInt32LE(p.score, o); o += 4
    rec.writeInt32LE(p.ping, o)
    parts.push(rec)
  }
  return Buffer.concat(parts)
}

describe('parsePlayersPacket', () => {
  it('parses an empty player list', () => {
    expect(parsePlayersPacket(buildPacket([]))).toEqual([])
  })

  it('parses players and sorts case-insensitively by nickname', () => {
    const packet = buildPacket([
      { id: 0, name: 'zebra', score: 10, ping: 50 },
      { id: 1, name: 'Alpha', score: 20, ping: 30 },
      { id: 2, name: 'beta', score: 5, ping: 99 },
    ])
    const result = parsePlayersPacket(packet)
    expect(result.map(p => p.nickname)).toEqual(['Alpha', 'beta', 'zebra'])
    expect(result[0]).toEqual({ playerid: 1, nickname: 'Alpha', score: 20, ping: 30 })
  })

  it('handles negative scores (signed int32)', () => {
    const result = parsePlayersPacket(buildPacket([{ id: 3, name: 'Neg', score: -5, ping: 12 }]))
    expect(result[0].score).toBe(-5)
  })
})
