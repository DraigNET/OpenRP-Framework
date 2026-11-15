import TemplatePage from '../TemplatePage'
export const metadata = { title: 'Framework credits' }
const credits = [["Torque","Project lead; major code rework, UCP and ACP."],["DignitySAMP (PXL-DavyL)","Creator of the original SP-RP gamemode."],["Spooky / Sporky","Quality of life changes and much of the early rewrite."],["Rusu","Bug fixes and quality of life changes."],["Matz","Basketball system."],["LorenC","Pool script."],["LS-RP (DamianC)","Early furniture list."],["PatrickGTR, Kubi and Patryk","Open-source systems used in the project."],["DTVSamp","Minor quality of life changes."],["Shabo / plsegott","Earlier food and drink prop system."]]
export default function CreditsPage() { return <TemplatePage title="Built on shared work." intro="The people behind OpenRP Framework and the systems it builds on."><dl className="credits-list">{credits.map(([name,work]) => <div key={name}><dt>{name}</dt><dd>{work}</dd></div>)}</dl></TemplatePage> }

