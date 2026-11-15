import TemplatePage from '../TemplatePage'
import { siteConfig as site } from '@/lib/site-config'
export const metadata = { title: 'Support the community' }
export default function SupportPage() { return <TemplatePage title="Support the community." intro="Thank you for being part of the story.">{site.donationUrl ? <a className="site-btn" href={site.donationUrl} rel="noopener noreferrer" target="_blank">Visit support page ↗</a> : <p>Community support options have not been set up.</p>}</TemplatePage> }

