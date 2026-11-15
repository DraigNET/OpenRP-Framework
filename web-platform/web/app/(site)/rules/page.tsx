import TemplatePage from '../TemplatePage'
import { siteConfig as site } from '@/lib/site-config'
export const metadata = { title: 'Server rules' }
export default function InformationPage() { return <TemplatePage title="Server rules" intro="Know the community before you join.">{site.rules.length ? site.rules.map(section => <section key={section.title}><h2>{section.title}</h2><p>{section.body}</p></section>) : <div className="site-empty"><h2>Not published yet</h2><p>The server owner has not published this information. Please check back before using the service.</p></div>}</TemplatePage> }

