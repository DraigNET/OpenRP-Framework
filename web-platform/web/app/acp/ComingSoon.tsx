/** Shared placeholder for ACP sections not yet built / not yet modelled. */
export default function ComingSoon({ title, note, path, icon = 'fa-helmet-safety' }: {
  title: string
  note: string
  path: string
  icon?: string
}) {
  return (
    <div className="acp-coming-soon">
      <div className="acp-coming-icon"><i className={`fa-solid ${icon}`} /></div>
      <h1>{title}</h1>
      <p>{note}</p>
      <p className="acp-coming-path"><i className="fa-solid fa-link" /> {path}</p>
    </div>
  )
}
