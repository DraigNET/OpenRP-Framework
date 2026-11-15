import dgram from 'dgram'
import { lookup } from 'dns/promises'

export interface SampStatus {
  online: boolean
}

/**
 * Sends a minimal SA-MP info query ('i' opcode) via UDP and checks for a valid reply.
 * Resolves to { online: false } on timeout, DNS failure, or any error.
 */
export async function querySampStatus(host: string, port = 7777, timeoutMs = 2000): Promise<SampStatus> {
  let ip: string
  try {
    const res = await lookup(host, { family: 4 })
    ip = res.address
  } catch {
    return { online: false }
  }

  return new Promise((resolve) => {
    const socket = dgram.createSocket('udp4')
    let settled = false

    const done = (online: boolean) => {
      if (settled) return
      settled = true
      clearTimeout(timer)
      try { socket.close() } catch { /* already closed */ }
      resolve({ online })
    }

    const timer = setTimeout(() => done(false), timeoutMs)

    socket.on('message', (msg) => {
      done(msg.length >= 4 && msg.subarray(0, 4).toString() === 'SAMP')
    })
    socket.on('error', () => done(false))

    // SA-MP packet: "SAMP" + IP(4 bytes) + port(2 bytes LE) + opcode 'i'
    const parts = ip.split('.').map(Number)
    const pkt = Buffer.alloc(11)
    pkt.write('SAMP', 0)
    pkt[4] = parts[0]; pkt[5] = parts[1]; pkt[6] = parts[2]; pkt[7] = parts[3]
    pkt.writeUInt16LE(port, 8)
    pkt[10] = 0x69 // 'i'

    socket.send(pkt, port, ip, (err) => { if (err) done(false) })
  })
}
