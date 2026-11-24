'use client'
import { useEffect,useRef,useState,useTransition } from 'react'
import { acpEntityTypes as entityTypes } from '../../../../shared/runtime-config/acp-entities.mjs'
import { saveRuntimeConfiguration } from './actions'

type Row={id:number;record:Record<string,number|string>}
type Snapshot={revision:number;rows:Row[]}

// Entity writes use the same revision lock and audit history as scalar settings.
export default function EntityEditor({disabled,onCommitted}:{disabled:boolean;onCommitted:()=>void}) {
  const [type,setType]=useState('armory_type'),[snapshot,setSnapshot]=useState<Snapshot|null>(null)
  const [selected,setSelected]=useState<Row|null>(null),[error,setError]=useState(''),[notice,setNotice]=useState('')
  const [pending,startTransition]=useTransition()
  const [loading,setLoading]=useState(false)
  const loadVersion=useRef(0)
  const definition=entityTypes[type]
  async function load(signal?:AbortSignal) {
    const version=++loadVersion.current
    setLoading(true)
    try {
      const response=await fetch('/api/runtime-config/entities?type='+encodeURIComponent(type),{cache:'no-store',signal})
      if(!response.ok) throw new Error('Could not load world entities.')
      const value=await response.json() as Snapshot
      if(version!==loadVersion.current)return
      setSnapshot(value);setSelected(null);setError('')
    }catch(error){if(version===loadVersion.current && !(error instanceof DOMException && error.name==='AbortError'))setError(error instanceof Error?error.message:'Load failed.')}
    finally{if(version===loadVersion.current)setLoading(false)}
  }
  useEffect(()=>{const controller=new AbortController();void load(controller.signal);return()=>{controller.abort();loadVersion.current++}},[type])
  function save(remove=false) {
    if(!selected || !snapshot || disabled || pending || loading)return
    startTransition(async()=>{
      const result=await saveRuntimeConfiguration({expectedRevision:snapshot.revision,entities:[{type,id:selected.id,record:remove?null:selected.record,expectedRecord:snapshot.rows.find(row=>row.id===selected.id)?.record??null}],description:`${remove?'Removed':selected.id?'Updated':'Created'} ${type} #${selected.id||'new'}`})
      if(!result.ok){setError(result.error??'Save failed.');return}
      setNotice(`Saved revision ${result.revision}. Waiting for game application.`);setError('');await load();onCommitted()
    })
  }
  function renderFields(entries:[string,(typeof definition.fields)[string]][]) {
    if(!selected)return null
    return entries.map(([key,field])=><label className="config-field" key={key}><span>{field.label}</span>{field.text?<input disabled={pending||loading} className="acp-input" required={!field.allowEmpty} maxLength={field.maxLength} value={String(selected.record[key]??'')} onChange={event=>setSelected({...selected,record:{...selected.record,[key]:event.target.value}})}/>:<input className="acp-input" required type="number" step={field.integer?1:'any'} min={field.min} max={field.max} value={typeof selected.record[key]==='number'&&Number.isFinite(selected.record[key])?selected.record[key]:''} onChange={event=>setSelected({...selected,record:{...selected.record,[key]:event.target.value===''?NaN:Number(event.target.value)}})}/>} </label>)
  }
  const summaryColumns=Object.entries(definition.fields).slice(0,5)
  return <section className="config-panel"><h2>World entities</h2><p className="config-muted">Only families with a connected game adapter appear here. Edits preserve unrelated entities and use the shared history/restore system.</p>
    {disabled&&<p className="config-alert">Save or reload your settings draft before editing entities.</p>}
    <label className="config-field"><span>Entity family</span><select className="acp-input" disabled={pending||loading} value={type} onChange={event=>{setType(event.target.value);setSnapshot(null);setSelected(null);setNotice('')}}>{Object.entries(entityTypes).map(([key,value])=><option key={key} value={key}>{value.label}</option>)}</select></label>
    {definition.help&&<p className="config-muted">{definition.help}</p>}
    {error&&<p className="config-alert is-error" role="alert">{error} Reload the row list if another editor saved a revision.</p>}{notice&&<p className="config-alert" role="status">{notice}</p>}
    <div className="acp-actions"><button type="button" className="acp-btn" disabled={pending} onClick={()=>void load()}>Reload rows</button>{!definition.editOnly&&<button type="button" className="acp-btn" disabled={pending||loading||disabled||!snapshot} onClick={()=>setSelected({id:0,record:Object.fromEntries(Object.entries(definition.fields).map(([key,field])=>[key,field.default]))})}>+ Add {type}</button>}<small>{snapshot?.rows.length??0} / {definition.limit} · Revision {snapshot?.revision??'—'}</small></div>
    {selected&&<form onSubmit={event=>{event.preventDefault();save()}}><h3>{selected.id?`Edit #${selected.id}`:'New entity'}</h3><div className="config-fields">{renderFields(Object.entries(definition.fields))}</div><div className="acp-actions"><button className="acp-btn acp-btn-primary" disabled={pending||disabled} type="submit">Save entity</button>{selected.id>0&&!definition.editOnly&&<button className="acp-btn" type="button" disabled={pending||disabled} onClick={()=>save(true)}>Delete entity</button>}<button className="acp-btn" type="button" onClick={()=>setSelected(null)}>Close</button></div></form>}
    <div className="config-table-wrap"><table className="acp-table"><thead><tr><th>ID</th>{summaryColumns.map(([key,field])=><th key={key}>{field.label}</th>)}<th/></tr></thead><tbody>{snapshot?.rows.map(row=><tr key={row.id}><td>{row.id}</td>{summaryColumns.map(([key])=><td key={key}>{row.record[key]}</td>)}<td><button className="acp-btn" type="button" disabled={pending||disabled} onClick={()=>{setSelected(structuredClone(row));setNotice('')}}>Edit</button></td></tr>)}</tbody></table></div>
  </section>
}
