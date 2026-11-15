import Link from 'next/link'
import TemplatePage from '../TemplatePage'
import { siteGuides } from '@/lib/data/site-guides'
export const metadata = { title: 'Player guides' }
export default function GuidesPage() { return <TemplatePage title="Find your feet." intro="A starting point for life in San Andreas."><div className="guide-grid">{Object.entries(siteGuides).map(([slug,g]) => <Link className="guide-card" href={'/guides/' + slug} key={slug}><h2>{g.title} <span aria-hidden="true">↗</span></h2><p>{g.intro}</p></Link>)}</div></TemplatePage> }

