/** GET search form for log pages. Submitting drops the page param (back to 1). */
export default function LogSearch({ action, defaultValue, placeholder }: {
  action: string
  defaultValue: string
  placeholder: string
}) {
  return (
    <form className="acp-toolbar" method="GET" action={action}>
      <div className="acp-search">
        <i className="fa-solid fa-magnifying-glass" />
        <input type="text" name="q" defaultValue={defaultValue} placeholder={placeholder} />
      </div>
      <button type="submit" className="acp-btn acp-btn-primary">Search</button>
      {defaultValue && <a href={action} className="acp-btn">Clear</a>}
    </form>
  )
}
