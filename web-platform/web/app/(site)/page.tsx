import Link from 'next/link'
import { siteConfig as site } from '@/lib/site-config'
import CopyIpButton from './CopyIpButton'

const FEATURES = [
  ['01', 'A character. A fresh start.', 'Create your identity, meet other players and let your decisions shape what happens next.'],
  ['02', 'Find your own way.', 'Earn a living, get behind the wheel, deliver supplies or work towards a business of your own.'],
  ['03', 'A world built together.', 'Join a faction, build connections and turn everyday encounters into stories worth remembering.'],
]
/** Neutral server landing page. Community branding and connection details live in site-config.ts. */
export default function HomePage() {
  return <>
    <section className="site-hero">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img className="site-hero-art" src={site.heroImage} alt="" fetchPriority="high" />
      <div className="site-wrap hero-inner"><p className="eyebrow">SAN ANDREAS. YOUR STORY.</p><h1>{site.tagline}</h1><p className="hero-description">A city of possibilities. People to meet. A life to make your own.<br />Welcome to {site.name}.</p><div className="site-actions"><Link href="/ucp/register" className="site-btn">Create your character <span aria-hidden="true">↗</span></Link><a href="#about" className="site-btn site-btn-quiet">Explore the world ↓</a></div><div className="hero-caption"><span>LOS SANTOS / SAN ANDREAS</span><span>POWERED BY OPEN.MP</span></div></div>
    </section>
    <div className="site-strip"><div className="site-wrap"><span>Character-driven stories</span><span>Jobs &amp; businesses</span><span>Police &amp; fire services</span><span>Your community. Your world.</span></div></div>
    <section id="about" className="site-section site-wrap"><div className="section-heading"><p className="eyebrow">A DIFFERENT LIFE, A FAMILIAR WORLD</p><h2>More than a place.<br /><span>A place to belong.</span></h2><p>{site.about}</p></div><div className="feature-row">{FEATURES.map(([n,title,body]) => <article key={n}><span className="feature-number">{n}</span><h3>{title}</h3><p>{body}</p></article>)}</div></section>
    <section id="factions" className="faction-section"><div className="site-wrap site-section"><div className="section-heading split-heading"><div><p className="eyebrow">ANSWER THE CALL</p><h2>Two services.<br /><span>One community.</span></h2></div><p>Protect the streets or be there when help is needed. Discover the police and fire services available in the framework.</p></div><div className="faction-grid">
      <article className="faction-card police"><div><p className="eyebrow">01 / PUBLIC SAFETY</p><h3>San Andreas<br />Police Department</h3><p>Serve the community, respond to incidents and build your career on the right side of the law.</p><Link href="/ucp/faction">Open faction panel ↗</Link></div>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/img/departments/1.png" alt="SAPD badge" width={190} height={190} /></article>
      <article className="faction-card fire"><div><p className="eyebrow">02 / FIRE &amp; MEDICAL</p><h3>Fire Department<br />of San Andreas</h3><p>From emergency medical care to fire response, make a difference when it matters most.</p><Link href="/ucp/faction">Open faction panel ↗</Link></div>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/img/departments/2.png" alt="FDSA badge" width={190} height={190} /></article>
    </div></div></section>
    <section id="join" className="site-section site-wrap"><div className="join-grid"><div className="section-heading"><p className="eyebrow">YOUR FIRST CHAPTER</p><h2>Make yourself<br /><span>at home.</span></h2><p>Start with an account. Get to know the rules. Then step into San Andreas.</p></div><ol className="join-steps"><li><span>01</span><div><h3>Create an account</h3><p>Your player panel keeps your account and characters in one place.</p><Link href="/ucp/register">Get started ↗</Link></div></li><li><span>02</span><div><h3>Get to know the server</h3><p>Read the community rules and player guides before your first session.</p><Link href="/rules">Read the rules ↗</Link></div></li><li><span>03</span><div><h3>Connect with open.mp</h3>{site.serverAddress ? <><p>Use this address in your multiplayer client.</p><CopyIpButton address={site.serverAddress} /><a href={'samp://' + site.serverAddress}>Launch client ↗</a></> : <p>Connection details will appear here when the server is ready.</p>}</div></li></ol></div></section>
    <section className="site-wrap community-banner"><div><p className="eyebrow">THE BEST STORIES START WITH PEOPLE</p><h2>Find your people.</h2><p>Bring a friend. Meet someone new. Make the next chapter yours.</p></div><Link href={site.discordUrl || '/ucp/register'} className="site-btn">{site.discordUrl ? 'Join our community ↗' : 'Create an account ↗'}</Link></section>
  </>
}

