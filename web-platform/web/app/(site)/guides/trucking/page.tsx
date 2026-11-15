import TemplatePage from '../../TemplatePage'
import { siteGuides } from '@/lib/data/site-guides'
const guide = siteGuides["trucking"]
export const metadata = { title: guide.title }
export default function GuidePage() { return <TemplatePage title={guide.title} intro={guide.intro}>{guide.sections.map(s => <section key={s.title}><h2>{s.title}</h2><p>{s.body}</p></section>)}</TemplatePage> }

