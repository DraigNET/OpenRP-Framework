import type { ReactNode } from 'react'
import Link from 'next/link'
/** Shared readable shell for public guides, policies and community information. */
export default function TemplatePage({ title, intro, children }: { title: string; intro: string; children: ReactNode }) {
  return <section className="site-wrap article-page"><Link href="/" className="back-link">← Back to home</Link><p className="eyebrow">COMMUNITY INFORMATION</p><h1>{title}</h1><p className="article-intro">{intro}</p><div className="article-content">{children}</div></section>
}

