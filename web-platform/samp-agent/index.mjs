import { checkedModelPath } from './model-path.mjs'
import http from 'http'
import dgram from 'dgram'
import fs from 'fs'
import pty from 'node-pty'
import { EventEmitter } from 'events'
import { readFileSync, createReadStream, statSync } from 'fs'
import { join, extname, dirname } from 'path'

const BIND        = process.env.AGENT_BIND ?? '127.0.0.1'
const MAX_UPLOAD_BYTES = 32 * 1024 * 1024
const PORT        = Number(process.env.AGENT_PORT   ?? 7001)
const AGENT_KEY   = process.env.SAMP_AGENT_KEY      ?? ''
const SAMP_DIR    = process.env.SAMP_DIR            ?? '/opt/samp'
const MODELS_DIR  = join(SAMP_DIR, 'models')
const SAMP_BIN    = process.env.SAMP_BIN            ?? (process.platform === 'win32' ? './omp-server.exe' : './omp-server')
const SAMP_HOST   = process.env.SAMP_HOST           ?? '127.0.0.1'
const SAMP_PORT   = Number(process.env.SAMP_PORT    ?? 7777)
const RCON_PASS   = process.env.SAMP_RCON_PASSWORD  ?? ''

if (!AGENT_KEY) {
  console.error('[agent] FATAL: SAMP_AGENT_KEY is not set')
  process.exit(1)
}

const BANS_FILE      = join(SAMP_DIR, 'bans.json')
const LOG_FILE       = join(SAMP_DIR, 'log.txt')
const LOG_TAIL_LINES = 200

// bans.json is read by open.mp itself at startup, so entries must be in ITS format:
//   { "address": "1.2.3.4", "player": "Name", "reason": "...", "time": "2026-11-06T00:56:35+0000" }
// All four values are strings. open.mp aborts at startup if an entry doesn't match
// (the agent used to write `name` and a JS ISO time with milliseconds and a Z).
function ompTime(date = new Date()) {
  return date.toISOString().replace(/\.\d{3}Z$/, '+0000')
}

// Turn any entry - including ones written by the old agent - into open.mp's format.
function toOmpEntry(b) {
  const parsed = new Date(b?.time)
  return {
    address: String(b?.address ?? ''),
    player:  String(b?.player ?? b?.name ?? ''),
    reason:  String(b?.reason ?? ''),
    time:    ompTime(Number.isNaN(parsed.getTime()) ? new Date() : parsed),
  }
}

function readBans() {
  try {
    const parsed = JSON.parse(fs.readFileSync(BANS_FILE, 'utf8'))
    return Array.isArray(parsed) ? parsed.map(toOmpEntry) : []
  } catch { return [] }
}

function writeBans(bans) {
  // Write to a temp file and rename, so open.mp never reads a half-written file.
  const tmp = BANS_FILE + '.tmp'
  fs.writeFileSync(tmp, JSON.stringify(bans.map(toOmpEntry), null, 2))
  fs.renameSync(tmp, BANS_FILE)
}

// What the website gets from GET /bans: open.mp's fields plus `name`, which the ACP page shows.
function bansForWeb() {
  return readBans().map(b => ({ ...b, name: b.player }))
}

function tailLogFile() {
  try {
    const content = readFileSync(LOG_FILE, 'utf8')
    const lines = content.split('\n').filter(l => l.trim())
    return lines.slice(-LOG_TAIL_LINES)
  } catch {
    return []
  }
}

// Shared event bus — broadcast log lines to all SSE clients
const bus = new EventEmitter()
bus.setMaxListeners(50)

function pushLog(line) {
  bus.emit('log', line)
}

let sampProc  = null
let sampPid   = null
let startedAt = null

function isRunning() {
  return sampProc !== null
}

// Strip ANSI escape sequences from PTY output
function stripAnsi(str) {
  return str.replace(/\x1b\[[0-9;]*[a-zA-Z]/g, '').replace(/\r/g, '')
}

function spawnSamp() {
  if (isRunning()) return { ok: false, error: 'already_running' }

  let proc
  try {
    proc = pty.spawn(SAMP_BIN, [], {
      name: 'xterm',
      cols: 220,
      rows: 50,
      cwd: SAMP_DIR,
      env: process.env,
    })
  } catch (err) {
    return { ok: false, error: err.message }
  }

  sampProc  = proc
  sampPid   = proc.pid
  startedAt = Date.now()

  pushLog(`[agent] SAMP started — PID ${proc.pid}`)

  let lineBuffer = ''

  proc.on('data', (data) => {
    const clean = stripAnsi(data)
    lineBuffer += clean
    const parts = lineBuffer.split('\n')
    lineBuffer = parts.pop() ?? ''
    for (const part of parts) {
      const trimmed = part.trimEnd()
      if (trimmed) pushLog(trimmed)
    }
  })

  proc.on('exit', (code) => {
    if (lineBuffer.trim()) pushLog(lineBuffer.trim())
    lineBuffer = ''
    pushLog(`[agent] SAMP exited — code=${code ?? '-'}`)
    if (sampProc === proc) { sampProc = null; sampPid = null; startedAt = null }
  })

  return { ok: true, pid: proc.pid }
}

function stopSamp() {
  if (!isRunning()) return { ok: false, error: 'not_running' }
  const pid = sampPid
  const target = sampProc

  // Graceful: send RCON exit, then force-kill after 8s if still running
  if (RCON_PASS) sendRcon('exit').catch(() => {})
  else { try { target.write(process.platform === 'win32' ? 'exit\r' : 'exit\n') } catch { /* force-stop fallback below */ } }
  pushLog('[agent] Stop requested — waiting for clean shutdown (8s)…')

  setTimeout(() => {
    if (!isRunning() || sampPid !== pid || sampProc !== target) return
    pushLog('[agent] Process still running — sending SIGKILL…')
    try { target.kill() } catch { /* already gone */ }
  }, 8000)

  return { ok: true }
}

function sendRcon(cmd) {
  return new Promise((resolve) => {
    if (!isRunning()) return resolve({ ok: false, error: 'not_running' })
    if (!RCON_PASS)   return resolve({ ok: false, error: 'rcon_password_not_set' })

    const safe = cmd.replace(/[\r\n]/g, '').trim()
    if (!safe) return resolve({ ok: false, error: 'empty_command' })

    // Build SA-MP RCON packet
    const ip     = SAMP_HOST.split('.').map(Number)
    const passLen = Buffer.byteLength(RCON_PASS)
    const cmdLen  = Buffer.byteLength(safe)
    const pkt     = Buffer.alloc(11 + passLen + 4 + cmdLen)
    let   o       = 0

    pkt.write('SAMP', o); o += 4
    pkt[o++] = ip[0]; pkt[o++] = ip[1]; pkt[o++] = ip[2]; pkt[o++] = ip[3]
    pkt.writeUInt16LE(SAMP_PORT, o); o += 2
    pkt[o++] = 0x78 // 'x' = RCON
    pkt.writeUInt16LE(passLen, o); o += 2
    pkt.write(RCON_PASS, o); o += passLen
    pkt.writeUInt16LE(cmdLen, o); o += 2
    pkt.write(safe, o)

    const sock = dgram.createSocket('udp4')
    const timer = setTimeout(() => { sock.close(); resolve({ ok: true }) }, 1500)

    sock.on('message', () => { clearTimeout(timer); sock.close(); resolve({ ok: true }) })
    sock.on('error',   () => { clearTimeout(timer); sock.close(); resolve({ ok: false, error: 'udp_error' }) })
    sock.send(pkt, SAMP_PORT, SAMP_HOST, (err) => {
      if (err) { clearTimeout(timer); sock.close(); resolve({ ok: false, error: err.message }) }
    })

    pushLog(`> ${safe}`)
  })
}

function getStatus() {
  return {
    running: isRunning(),
    pid: sampPid,
    uptime: startedAt ? Math.floor((Date.now() - startedAt) / 1000) : null,
  }
}

// ── HTTP server ────────────────────────────────────────────────

function unauthorized(res) {
  res.writeHead(401, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify({ error: 'unauthorized' }))
}

function json(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify(data))
}

const MIME = {
  '.dff': 'application/octet-stream',
  '.txd': 'application/octet-stream',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost')

  // Public CDN — no auth, serves MODELS_DIR
  if (req.method === 'GET' && url.pathname.startsWith('/cdn/')) {
    let abs
    try { abs = checkedModelPath(MODELS_DIR, decodeURIComponent(url.pathname.slice(5))) }
    catch { res.writeHead(403); res.end('Forbidden'); return }
    let stat
    try { stat = statSync(abs) } catch {
      res.writeHead(404); res.end('Not found'); return
    }
    if (!stat.isFile()) { res.writeHead(404); res.end('Not found'); return }
    const mime = MIME[extname(abs).toLowerCase()] ?? 'application/octet-stream'
    res.writeHead(200, { 'Content-Type': mime, 'Content-Length': stat.size })
    createReadStream(abs).pipe(res)
    return
  }

  if (req.headers['x-agent-key'] !== AGENT_KEY) return unauthorized(res)

  // SSE log stream
  if (req.method === 'GET' && url.pathname === '/stream') {
    res.writeHead(200, {
      'Content-Type':      'text/event-stream',
      'Cache-Control':     'no-cache',
      'Connection':        'keep-alive',
      'X-Accel-Buffering': 'no',
    })

    // Replay last N lines from server_log.txt
    const history = tailLogFile()
    if (history.length > 0) {
      for (const line of history) {
        res.write(`data: ${JSON.stringify(line)}\n\n`)
      }
    } else {
      const init = isRunning()
        ? `[agent] Connected — SAMP is RUNNING (PID ${sampPid})`
        : '[agent] Connected — SAMP is OFFLINE'
      res.write(`data: ${JSON.stringify(init)}\n\n`)
    }

    const onLog = (line) => res.write(`data: ${JSON.stringify(line)}\n\n`)
    bus.on('log', onLog)

    // Keep the connection alive so nginx/EasyPanel don't time it out (60s default)
    const heartbeat = setInterval(() => {
      try { res.write(':\n\n') } catch { /* client gone */ }
    }, 25000)

    req.on('close', () => {
      clearInterval(heartbeat)
      bus.off('log', onLog)
    })
    return
  }

  if (req.method === 'GET' && url.pathname === '/status') {
    return json(res, 200, getStatus())
  }

  if (req.method === 'GET' && url.pathname === '/bans') {
    return json(res, 200, bansForWeb())
  }

  if (req.method === 'DELETE' && url.pathname === '/file') {
    const rel = url.searchParams.get('path') ?? ''
    if (!rel) return json(res, 400, { error: 'missing path param' })
    let abs
    try { abs = checkedModelPath(MODELS_DIR, rel) }
    catch { return json(res, 403, { error: 'path traversal denied' }) }
    fs.promises.rm(abs, { force: true })
      .then(() => json(res, 200, { ok: true }))
      .catch((e) => json(res, 500, { ok: false, error: e.message }))
    return
  }

  if (req.method === 'DELETE' && url.pathname === '/bans') {
    const address = url.searchParams.get('address')
    if (!address) return json(res, 400, { error: 'missing address param' })
    const bans = readBans().filter(b => b.address !== address)
    writeBans(bans)
    sendRcon('reloadbans').catch(() => {})   // the server only reads bans.json at start otherwise
    return json(res, 200, { ok: true })
  }

  if (req.method === 'POST') {
    // File upload — streams raw bytes so we collect as Buffer, not string
    if (url.pathname === '/upload') {
      const rel = url.searchParams.get('path') ?? ''
      if (!rel) { json(res, 400, { error: 'missing path param' }); return }
      let abs
      try { abs = checkedModelPath(MODELS_DIR, rel) }
      catch { return json(res, 403, { error: 'path traversal denied' }) }
      const chunks = []
      let bytes = 0, rejected = false
      req.on('data', (chunk) => {
        bytes += chunk.length
        if (rejected) return
        if (bytes > MAX_UPLOAD_BYTES) { rejected = true; json(res, 413, { error: 'Upload exceeds 32 MiB' }); return }
        chunks.push(chunk)
      })
      req.on('end', async () => {
        try {
          const dir = dirname(abs)
          await fs.promises.mkdir(dir, { recursive: true })
          await fs.promises.writeFile(abs, Buffer.concat(chunks))
          json(res, 200, { ok: true })
        } catch (e) {
          json(res, 500, { ok: false, error: e.message })
        }
      })
      return
    }

    let body = ''
    req.on('data', (chunk) => { body += chunk })
    req.on('end', () => {
      if (url.pathname === '/start') return json(res, 200, spawnSamp())
      if (url.pathname === '/stop')  return json(res, 200, stopSamp())
      if (url.pathname === '/bans') {
        let parsed
        try { parsed = JSON.parse(body) } catch { return json(res, 400, { error: 'bad_json' }) }
        const { address, name, reason } = parsed
        if (!address) return json(res, 400, { error: 'missing address' })
        const bans = readBans()
        if (!bans.find(b => b.address === address)) {
          bans.push({ address, player: name ?? '', time: ompTime(), reason: reason ?? '' })
          writeBans(bans)
          sendRcon('reloadbans').catch(() => {})   // take effect now, not at the next restart
        }
        return json(res, 200, { ok: true })
      }
      if (url.pathname === '/cmd') {
        let parsed
        try { parsed = JSON.parse(body) } catch {
          return json(res, 400, { error: 'bad_json' })
        }
        if (typeof parsed?.command !== 'string') {
          return json(res, 400, { error: 'missing_command' })
        }
        sendRcon(parsed.command).then(result => json(res, 200, result))
        return
      }
      json(res, 404, { error: 'not_found' })
    })
    return
  }

  json(res, 404, { error: 'not_found' })
})

server.listen(PORT, BIND, () => {
  console.log(`[agent] SAMP Control Agent listening on :${PORT}`)
})
