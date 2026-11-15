'use client'

import { useEffect, useRef, useState } from 'react'
import { usePathname, useRouter } from 'next/navigation'
import PageTitle from './PageTitle'
import { ADMIN_NAV, PLAYER_NAV, TOOLS_NAV } from './nav'

const HUES = [32, 8, 150, 205, 265, 330]

function SidebarToggle() {
  function toggle() {
    const layout = document.getElementById('ucpLayout')
    if (!layout) return
    if (window.innerWidth <= 900) {
      layout.classList.toggle('mob-open')
      return
    }
    const collapsed = layout.classList.toggle('sidebar-collapsed')
    try { localStorage.setItem('ucpSidebarCollapsed', collapsed ? '1' : '0') } catch { /* private mode */ }
  }
  return (
    <button className="ucp-icon-btn" onClick={toggle} title="Toggle sidebar" aria-label="Toggle sidebar">
      <i className="fa-solid fa-bars" />
    </button>
  )
}

function ServerPill() {
  const [state, setState] = useState<{ online: boolean; players: number } | null>(null)

  useEffect(() => {
    let alive = true
    const load = () =>
      fetch('/api/ucp/server-status')
        .then(r => (r.ok ? r.json() : null))
        .then(d => { if (alive && d) setState(d) })
        .catch(() => {})
    load()
    const t = setInterval(load, 30_000)
    return () => { alive = false; clearInterval(t) }
  }, [])

  const cls = state === null ? 'is-unknown' : state.online ? '' : 'is-offline'
  const label = state === null ? 'Checking…' : state.online ? `Server online · ${state.players} playing` : 'Server offline'
  return (
    <div className={`ucp-srv-pill ${cls}`}>
      <i className="ucp-pulse" /> <span>{label}</span>
    </div>
  )
}

function applyHue(h: number) {
  document.documentElement.style.setProperty('--hue', String(h))
  try { localStorage.setItem('ucpHue', String(h)) } catch { /* ignore */ }
}

function AccentPicker({ initialHue }: { initialHue: number | null }) {
  const [open, setOpen] = useState(false)
  const [hue, setHue] = useState(210)
  const wrap = useRef<HTMLDivElement>(null)

  // The account's saved colour wins; localStorage only covers pages shown before login.
  useEffect(() => {
    if (initialHue !== null) {
      setHue(initialHue)
      applyHue(initialHue)
      return
    }
    try {
      const saved = Number(localStorage.getItem('ucpHue'))
      if (saved) setHue(saved)
    } catch { /* ignore */ }
  }, [initialHue])

  useEffect(() => {
    const close = (e: MouseEvent) => { if (wrap.current && !wrap.current.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('mousedown', close)
    return () => document.removeEventListener('mousedown', close)
  }, [])

  function pick(h: number) {
    setHue(h)
    applyHue(h)
    fetch('/api/ucp/preferences', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ hue: h }),
    }).catch(() => { /* colour still applies locally */ })
  }

  return (
    <div className="ucp-pop-wrap" ref={wrap}>
      <button className="ucp-icon-btn" onClick={() => setOpen(o => !o)} title="Accent colour" aria-label="Accent colour">
        <i className="fa-solid fa-palette" />
      </button>
      {open && (
        <div className="ucp-pop">
          <b>Accent colour</b>
          <div className="ucp-muted" style={{ fontSize: 13 }}>Saved to your account.</div>
          <div className="ucp-swatches">
            {HUES.map(h => (
              <button key={h} className={h === hue ? 'on' : ''} style={{ background: `hsl(${h} 55% 55%)` }} onClick={() => pick(h)} aria-label={`Hue ${h}`} />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

interface NotificationItem {
  id: number
  type: string
  title: string
  body: string
  link: string | null
  created_at: number
  read_at: number | null
}

const TYPE_ICON: Record<string, string> = {
  faction: 'fa-shield-halved',
  career: 'fa-briefcase',
  admin: 'fa-gavel',
}

function ago(unix: number): string {
  const d = Math.max(0, Math.floor(Date.now() / 1000) - unix)
  if (d < 60) return 'just now'
  if (d < 3600) return `${Math.floor(d / 60)} min ago`
  if (d < 86400) return `${Math.floor(d / 3600)} h ago`
  return `${Math.floor(d / 86400)} d ago`
}

function NotificationBell() {
  const [open, setOpen] = useState(false)
  const [items, setItems] = useState<NotificationItem[]>([])
  const [unread, setUnread] = useState(0)
  const wrap = useRef<HTMLDivElement>(null)
  const router = useRouter()

  useEffect(() => {
    let alive = true
    const load = () =>
      fetch('/api/ucp/notifications')
        .then(r => (r.ok ? r.json() : null))
        .then(d => { if (alive && d) { setItems(d.items); setUnread(d.unread) } })
        .catch(() => {})
    load()
    const t = setInterval(load, 60_000)
    return () => { alive = false; clearInterval(t) }
  }, [])

  useEffect(() => {
    const close = (e: MouseEvent) => { if (wrap.current && !wrap.current.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('mousedown', close)
    return () => document.removeEventListener('mousedown', close)
  }, [])

  const post = (body: object) =>
    fetch('/api/ucp/notifications', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }).catch(() => {})

  function markAll() {
    const now = Math.floor(Date.now() / 1000)
    setItems(list => list.map(i => ({ ...i, read_at: i.read_at ?? now })))
    setUnread(0)
    post({ action: 'readAll' })
  }

  function openItem(n: NotificationItem) {
    if (!n.read_at) {
      setItems(list => list.map(i => (i.id === n.id ? { ...i, read_at: Math.floor(Date.now() / 1000) } : i)))
      setUnread(u => Math.max(0, u - 1))
      post({ action: 'read', id: n.id })
    }
    if (n.link) {
      setOpen(false)
      if (n.link.startsWith('/ucp')) router.push(n.link)
      else window.location.href = n.link
    }
  }

  return (
    <div className="ucp-pop-wrap" ref={wrap}>
      <button className="ucp-icon-btn" onClick={() => setOpen(o => !o)} title="Notifications" aria-label="Notifications">
        <i className="fa-solid fa-bell" />
        {unread > 0 && <span className="ucp-bell-badge">{unread > 9 ? '9+' : unread}</span>}
      </button>
      {open && (
        <div className="ucp-pop ucp-notif">
          <div className="ucp-notif-head">
            <b>Notifications</b>
            {unread > 0 && <button onClick={markAll}>Mark all read</button>}
          </div>
          {items.length === 0 ? (
            <div className="ucp-notif-empty"><i className="fa-regular fa-bell" /><span>You&apos;re all caught up.</span></div>
          ) : (
            <div className="ucp-notif-list">
              {items.map(n => (
                <button key={n.id} className={`ucp-notif-item ${n.read_at ? '' : 'unread'}`} onClick={() => openItem(n)}>
                  <span className="ucp-row-ico"><i className={`fa-solid ${TYPE_ICON[n.type] ?? 'fa-circle-info'}`} /></span>
                  <span className="ucp-notif-text">
                    <b>{n.title}</b>
                    {n.body && <span>{n.body}</span>}
                    <small>{ago(n.created_at)}</small>
                  </span>
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}

function CommandPalette({ staffLevel }: { staffLevel: number }) {
  const [open, setOpen] = useState(false)
  const [q, setQ] = useState('')
  const [sel, setSel] = useState(0)
  const router = useRouter()
  const pathname = usePathname()
  const input = useRef<HTMLInputElement>(null)

  const items = [...PLAYER_NAV, ...TOOLS_NAV, ...(staffLevel >= (ADMIN_NAV.staffOnly ?? 0) ? [ADMIN_NAV] : [])]
  const shown = items.filter(i => i.label.toLowerCase().includes(q.toLowerCase()))

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); setOpen(o => !o) }
      if (e.key === 'Escape') setOpen(false)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  useEffect(() => { setOpen(false) }, [pathname])
  useEffect(() => { if (open) { setQ(''); setSel(0); setTimeout(() => input.current?.focus(), 0) } }, [open])

  function go(href: string) { setOpen(false); router.push(href) }

  return (
    <>
      <button className="ucp-search" onClick={() => setOpen(true)}>
        <i className="fa-solid fa-magnifying-glass" /> <span>Jump to a page…</span> <kbd>Ctrl K</kbd>
      </button>
      {open && (
        <div className="ucp-palette-bg" onMouseDown={e => { if (e.target === e.currentTarget) setOpen(false) }}>
          <div className="ucp-palette" role="dialog" aria-label="Jump to a page">
            <input
              ref={input}
              value={q}
              placeholder="Jump to…"
              onChange={e => { setQ(e.target.value); setSel(0) }}
              onKeyDown={e => {
                if (e.key === 'ArrowDown') { e.preventDefault(); setSel(s => Math.min(s + 1, shown.length - 1)) }
                if (e.key === 'ArrowUp') { e.preventDefault(); setSel(s => Math.max(s - 1, 0)) }
                if (e.key === 'Enter' && shown[sel]) go(shown[sel].href)
              }}
            />
            <div className="ucp-palette-list">
              {shown.map((i, idx) => (
                <a key={i.href} href={i.href} className={idx === sel ? 'sel' : ''} onClick={e => { e.preventDefault(); go(i.href) }}>
                  <i className={`fa-solid ${i.icon}`} /> {i.label}
                </a>
              ))}
              {shown.length === 0 && <div className="ucp-muted" style={{ padding: '14px 22px' }}>No matching pages.</div>}
            </div>
          </div>
        </div>
      )}
    </>
  )
}

export default function Topbar({ staffLevel, initialHue }: { staffLevel: number; initialHue: number | null }) {
  return (
    <header className="ucp-header">
      <div className="ucp-header-left">
        <SidebarToggle />
        <PageTitle />
      </div>
      <div className="ucp-header-right">
        <CommandPalette staffLevel={staffLevel} />
        <ServerPill />
        <NotificationBell />
        <AccentPicker initialHue={initialHue} />
      </div>
    </header>
  )
}
