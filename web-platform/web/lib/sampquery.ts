import * as dgram from 'dgram'
import * as dns from 'dns/promises'

export interface SampPlayer {
  playerid: number
  nickname: string
  score: number
  /** null when only the basic player list ('c') was available */
  ping: number | null
}

/**
 * Parses a SA-MP "detailed players" (opcode 'd') response packet into a sorted
 * player list. Pure — exposed separately so it can be unit-tested without UDP.
 * Layout: 11-byte header (SAMP + ip[4] + port[2] + opcode) then uint16 count,
 * then per player: id(1), nameLen(1), name, score(int32), ping(int32) — all LE.
 */
export function parsePlayersPacket(msg: Buffer): SampPlayer[] {
  let offset = 11
  const count = msg.readUInt16LE(offset); offset += 2
  const players: SampPlayer[] = []

  for (let i = 0; i < count; i++) {
    const playerid = msg[offset++]
    const nameLen = msg[offset++]
    const nickname = msg.toString('utf8', offset, offset + nameLen)
    offset += nameLen
    const score = msg.readInt32LE(offset); offset += 4
    const ping = msg.readInt32LE(offset); offset += 4
    players.push({ playerid, nickname, score, ping })
  }

  players.sort((a, b) => a.nickname.toLowerCase().localeCompare(b.nickname.toLowerCase()))
  return players
}

/**
 * Parses a SA-MP "basic players" (opcode 'c') response. Same as 'd' but with no
 * player id or ping: count(uint16), then per player nameLen(1), name, score(int32).
 * Ids are synthesised from list order; ping is unavailable.
 */
export function parseBasicPlayersPacket(msg: Buffer): SampPlayer[] {
  let offset = 11
  const count = msg.readUInt16LE(offset); offset += 2
  const players: SampPlayer[] = []

  for (let i = 0; i < count; i++) {
    const nameLen = msg[offset++]
    const nickname = msg.toString('utf8', offset, offset + nameLen)
    offset += nameLen
    const score = msg.readInt32LE(offset); offset += 4
    players.push({ playerid: i, nickname, score, ping: null })
  }

  players.sort((a, b) => a.nickname.toLowerCase().localeCompare(b.nickname.toLowerCase()))
  return players
}

async function queryOpcode(
  host: string,
  port: number,
  opcode: number,
  parse: (msg: Buffer) => SampPlayer[],
  timeout: number
): Promise<SampPlayer[]> {
  // Resolve hostname → IP string
  const ip = await dns.resolve4(host)
    .then(addrs => addrs[0])
    .catch(() => host)

  const ipParts = ip.split('.').map(Number)
  if (ipParts.length !== 4) throw new Error('Invalid SA-MP query host')

  const packet = Buffer.allocUnsafe(11)
  packet.write('SAMP', 0, 'ascii')
  packet[4] = ipParts[0]
  packet[5] = ipParts[1]
  packet[6] = ipParts[2]
  packet[7] = ipParts[3]
  packet.writeUInt16LE(port, 8)
  packet[10] = opcode

  return new Promise((resolve, reject) => {
    const sock = dgram.createSocket('udp4')
    let done = false

    const finish = (fn: () => void) => {
      if (done) return
      done = true
      clearTimeout(timer)
      try { sock.close() } catch {}
      fn()
    }

    const timer = setTimeout(() => {
      finish(() => reject(new Error('SA-MP query timed out')))
    }, timeout)

    sock.on('error', err => finish(() => reject(err)))

    sock.on('message', msg => {
      finish(() => {
        try {
          resolve(parse(msg))
        } catch (e) {
          reject(e)
        }
      })
    })

    sock.send(packet, 0, packet.length, port, host, err => {
      if (err) finish(() => reject(err))
    })
  })
}

/**
 * Queries the player list. Prefers the detailed ('d') opcode for ping, but some
 * servers (e.g. open.mp) never answer it, so the basic ('c') opcode is queried in
 * parallel and used as a fallback when 'd' fails or times out.
 */
export async function queryPlayersDetailed(
  host: string,
  port: number,
  timeout = 2000
): Promise<SampPlayer[]> {
  const detailed = queryOpcode(host, port, 0x64, parsePlayersPacket, timeout)
  const basic = queryOpcode(host, port, 0x63, parseBasicPlayersPacket, timeout)
  // Avoid unhandled rejections for whichever promise we don't end up awaiting.
  detailed.catch(() => {})
  basic.catch(() => {})

  try {
    return await detailed
  } catch {
    return await basic
  }
}
