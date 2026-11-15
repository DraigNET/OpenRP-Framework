import Link from 'next/link'

interface ToolCard {
  icon: string
  name: string
  desc: string
  href: string
  action: string
  external?: boolean
}

const TOOLS: ToolCard[] = [
  {
    icon: 'fa-camera', name: 'Screenshot Overlay',
    desc: 'Upload a screenshot, crop/zoom, apply filters, and overlay chat text. Download instantly.',
    href: '/ucp/tools/screenshots', action: 'Open Tool',
  },
  {
    icon: 'fa-map', name: 'Gang Territories',
    desc: 'View live controlled and contested turf across San Andreas.',
    href: '/ucp/tools/gang-zones', action: 'View Map',
  },
  {
    icon: 'fa-car', name: 'Vehicle Catalogue',
    desc: 'Browse dealership vehicles, pricing updates, and storage capacity.',
    href: '/ucp/tools/vehicles', action: 'Browse Vehicles',
  },
  {
    icon: 'fa-couch', name: 'Furniture Catalogue',
    desc: 'Browse all purchasable furniture items, props, and decorations with in-game prices.',
    href: '/ucp/tools/furniture', action: 'Browse Furniture',
  },
  {
    icon: 'fa-gun', name: 'Weapon Statistics',
    desc: 'View detailed weapon specs, damage ranges, ammo bonuses, and performance breakdowns.',
    href: '/ucp/tools/weapons', action: 'View Weapons',
  },
  {
    icon: 'fa-flask', name: 'Drug Reference',
    desc: 'View all drugs, their effects, grow and cook times, addiction rates, and withdrawal consequences.',
    href: '/ucp/tools/drugs', action: 'View Drugs',
  },
]

export default function ToolsHomePage() {
  return (
    <div className="tools-wrap">
      <div className="tools-header">
        <h2 className="tools-title">Tools &amp; Utilities</h2>
        <p className="tools-subtitle">Helpful utilities available to all logged-in users.</p>
      </div>

      <div className="tools-grid">
        {TOOLS.map(tool => (
          <div key={tool.name} className="tool-card">
            <div className="tool-card-top">
              <div className="tool-icon"><i className={`fa-solid ${tool.icon}`} /></div>
              <div className="tool-meta">
                <div className="tool-name">{tool.name}</div>
                <div className="tool-desc">{tool.desc}</div>
              </div>
            </div>
            <div className="tool-actions">
              {tool.external ? (
                <a className="tool-btn" href={tool.href}>{tool.action}<i className="fa-solid fa-arrow-right" /></a>
              ) : (
                <Link className="tool-btn" href={tool.href}>{tool.action}<i className="fa-solid fa-arrow-right" /></Link>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
