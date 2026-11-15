import TemplatePage from '../TemplatePage'
import { siteConfig as site } from '@/lib/site-config'
export const metadata = { title: 'Community updates', alternates: { types: { 'application/atom+xml': '/changelog/feed.xml' } } }
export default function UpdatesPage() { return <TemplatePage title="What’s new." intro="News and changes from your community.">{site.updates.length ? site.updates.map(u => <article className="update-entry" key={u.date + u.title}><time dateTime={u.date}>{u.date}</time><h2>{u.title}</h2><p>{u.body}</p></article>) : <div className="site-empty"><h2>A fresh chapter</h2><p>No updates have been published yet. Community news will appear here.</p></div>}</TemplatePage> }

