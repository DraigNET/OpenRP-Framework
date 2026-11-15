'use client'
import { useEffect, useState } from 'react'
import { usePathname } from 'next/navigation'
import Link from 'next/link'
import { siteConfig as site } from '@/lib/site-config'

/** Responsive navigation; close the mobile menu on navigation or Escape. */
export default function SiteNav() {
  const [open, setOpen] = useState(false)
  const pathname = usePathname()
  useEffect(() => { setOpen(false) }, [pathname])
  useEffect(() => { const close = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false) }; window.addEventListener('keydown', close); return () => window.removeEventListener('keydown', close) }, [])
  return <header className="site-nav"><div className="site-wrap nav-inner">
    <Link href="/" className="site-brand" onClick={() => setOpen(false)}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={site.logo} alt="" width={38} height={38} /><span>{site.name}</span>
    </Link>
    <button className="menu-toggle" aria-controls="site-navigation" aria-expanded={open} onClick={() => setOpen(!open)}>{open ? 'Close' : 'Menu'}</button>
    <nav id="site-navigation" aria-label="Main navigation" className={open ? 'site-links is-open' : 'site-links'}>
      <Link href="/#about" onClick={() => setOpen(false)}>Discover</Link><Link href="/#factions" onClick={() => setOpen(false)}>Factions</Link><Link href="/guides" onClick={() => setOpen(false)}>Guides</Link><Link href="/changelog" onClick={() => setOpen(false)}>Updates</Link>
      {site.discordUrl && <a href={site.discordUrl} target="_blank" rel="noopener noreferrer">Discord ↗</a>}
      <Link href="/ucp" className="site-btn site-btn-small">Player panel <span aria-hidden="true">↗</span></Link>
    </nav>
  </div></header>
}

