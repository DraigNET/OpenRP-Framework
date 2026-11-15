import Link from 'next/link'
import { siteConfig as site } from '@/lib/site-config'
export default function SiteFooter() {
  return <footer className="site-footer"><div className="site-wrap footer-grid"><div><Link href="/" className="site-brand">
    {/* eslint-disable-next-line @next/next/no-img-element */}
    <img src={site.logo} alt="" width={32} height={32} /><span>{site.name}</span></Link><p>A place for your next chapter.</p><small>Powered by OpenRP Framework · Built for open.mp</small></div>
    <nav aria-label="Footer navigation"><Link href="/rules">Server rules</Link><Link href="/credits">Credits</Link><Link href="/terms">Terms</Link><Link href="/privacy">Privacy</Link>{site.forumUrl && <a href={site.forumUrl}>Community forum ↗</a>}{site.supportEmail && <a href={'mailto:' + site.supportEmail}>Contact</a>}</nav></div></footer>
}

