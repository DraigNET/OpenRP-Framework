import type { ReactNode } from 'react'
import type { Metadata } from 'next'
import { siteConfig as site } from '@/lib/site-config'
import SiteNav from './SiteNav'
import SiteFooter from './SiteFooter'
import './site.css'

export const metadata: Metadata = {
  ...(site.siteUrl ? { metadataBase: new URL(site.siteUrl) } : {}),
  title: { default: site.name, template: '%s | ' + site.name },
  description: site.description,
  applicationName: site.name,
  icons: { icon: site.logo },
  openGraph: { type: 'website', siteName: site.name, title: site.name, description: site.description,
    ...(site.siteUrl ? { url: site.siteUrl, images: [{ url: new URL(site.heroImage, site.siteUrl).href, alt: 'San Andreas at dusk' }] } : {}) },
  twitter: { card: 'summary_large_image', title: site.name, description: site.description,
    ...(site.siteUrl ? { images: [new URL(site.heroImage, site.siteUrl).href] } : {}) },
}

/** Public website shell; account and admin routes use their own layouts. */
export default function SiteLayout({ children }: { children: ReactNode }) {
  return <div className="site-root"><a className="site-skip" href="#main-content">Skip to content</a><SiteNav /><main id="main-content" tabIndex={-1}>{children}</main><SiteFooter /></div>
}

