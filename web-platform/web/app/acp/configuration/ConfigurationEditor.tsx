'use client'
import { useEffect,useState,useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { settings as definitions,locations as coreLocations,locationCategories } from '../../../../shared/runtime-config/catalog.mjs'
import type { RuntimeConfiguration,RuntimeHistory,RuntimeLocation } from '@/lib/runtime-config-types'
import { vehicleName } from '@/lib/data/vehicles'
import { saveRuntimeConfiguration,restoreRuntimeRevision } from './actions'
import './configuration.css'
import EntityEditor from './EntityEditor'

const groups=[...new Set(definitions.map(s=>s.group))]
const title=(value:string)=>value.replaceAll('_',' ').replace(/^./,c=>c.toUpperCase())
const copy=<T,>(value:T):T=>structuredClone(value)
function Numeric({label,value,onChange,min,max,integer=false}:{label:string;value:number;onChange:(value:number)=>void;min?:number;max?:number;integer?:boolean}) {
  return <label className="config-field"><span>{label}</span><input className="acp-input" type="number" value={Number.isFinite(value)?value:''} min={min} max={max} step={integer?1:'any'} onChange={e=>onChange(e.target.value===''?NaN:Number(e.target.value))}/></label>
}

export default function ConfigurationEditor({initial,history}:{initial:RuntimeConfiguration;history:RuntimeHistory[]}) {
  const router=useRouter()
  const [draft,setDraft]=useState(()=>copy(initial))
  const [dirty,setDirty]=useState(false)
  const [tab,setTab]=useState('settings')
  const [group,setGroup]=useState(groups[0])
  const [query,setQuery]=useState('')
  const [selected,setSelected]=useState(initial.locations[0]?.key??'')
  const [status,setStatus]=useState(initial.state)
  const [now,setNow]=useState(()=>Date.now())
  const [message,setMessage]=useState('')
  const [error,setError]=useState(false)
  const [pending,startTransition]=useTransition()
  useEffect(()=>{if(!dirty){setDraft(copy(initial));setStatus(initial.state)}},[initial,dirty])
  useEffect(()=>{
    const controller=new AbortController()
    const poll=async()=>{setNow(Date.now());if(document.hidden)return;try{const response=await fetch('/api/runtime-config/status',{cache:'no-store',signal:controller.signal});if(response.ok){const state=await response.json();if(state)setStatus(state)}}catch{/* next poll retries */}}
    const timer=setInterval(poll,2000)
    return()=>{controller.abort();clearInterval(timer)}
  },[])
  const change=(updater:(value:RuntimeConfiguration)=>RuntimeConfiguration)=>{setDraft(previous=>updater(previous));setDirty(true);setMessage('')}
  const selectedLocation=draft.locations.find(row=>row.key===selected)
  const updateLocation=(patch:Partial<RuntimeLocation>)=>change(value=>({...value,locations:value.locations.map(row=>row.key===selected?{...row,...patch}:row)}))
  const online=now/1000-status.last_heartbeat<12
  const applied=online&&status.applied_revision>=draft.state.revision&&!status.last_error
  function save() {
    startTransition(async()=>{
      const result=await saveRuntimeConfiguration({expectedRevision:draft.state.revision,settings:draft.settings,locations:draft.locations,models:draft.models,squads:draft.squads,description:`Updated ${tab} from ACP`})
      setError(!result.ok)
      setMessage(result.ok?`Saved revision ${result.revision}. Waiting for the game to apply it.`:result.error??'Save failed.')
      if(result.ok){setDirty(false);router.refresh()}
    })
  }
  function addLocation() {
    let n=1;while(draft.locations.some(row=>row.key===`location_${n}`))n++
    const row:RuntimeLocation={key:`location_${n}`,label:'New location',category:'gps',x:0,y:0,z:0,angle:0,interior:0,world:0,radius:5,enabled:false,gpsEnabled:false,modelId:0,sortOrder:0,vertices:[]}
    change(value=>({...value,locations:[...value.locations,row]}));setSelected(row.key)
  }
  const resultCount=draft.locations.filter(row=>(row.label+' '+row.key+' '+row.category).toLowerCase().includes(query.toLowerCase())).length
  return <div className="runtime-editor">
    <section className="config-intro"><div><span className="config-eyebrow">LIVE SERVER CONFIGURATION</span><h1>Build your world. Keep it running.</h1><p>Stage changes, then save one revision. The game applies supported updates without a restart.</p></div><div className={`config-state ${status.last_error?'is-error':applied?'is-applied':''}`} role="status"><b>{status.last_error?'Application failed':dirty?'Unsaved changes':applied?'Applied':online?'Waiting for application':'Server offline'}</b><span>Saved {status.revision} · Applied {status.applied_revision}</span></div></section>
    {status.last_error&&<p className="config-alert is-error" role="alert">{status.last_error} The game keeps its last working configuration. Review and save a corrected revision.</p>}
    {status.revision!==draft.state.revision&&dirty&&<p className="config-alert" role="alert">Another saved revision is available. Saving will check for a conflict; reload and review before replacing someone else’s changes.</p>}
    <nav className="config-tabs" aria-label="Configuration sections">{['settings','locations','vehicles','squads','entities','history'].map(name=><button key={name} type="button" className={tab===name?'is-active':''} onClick={()=>{setTab(name);setQuery('')}}>{title(name)}</button>)}</nav>

    {tab==='entities'&&<EntityEditor disabled={dirty} onCommitted={()=>router.refresh()}/>}
    {tab==='settings'&&<section className="config-layout"><aside className="config-groups">{groups.map(name=><button key={name} type="button" className={group===name?'is-active':''} onClick={()=>setGroup(name)}>{title(name)}</button>)}</aside><div className="config-panel"><h2>{title(group)} settings</h2><p className="config-muted">Values are validated before saving. Application status confirms when the game has accepted the saved revision.</p><div className="config-fields">{definitions.filter(d=>d.group===group).map(d=><div key={d.key}>
      {d.type==='text'?<label className="config-field"><span>{d.label}</span><input className="acp-input" value={String(draft.settings[d.key]??'')} maxLength={d.maxLength} onChange={e=>change(v=>({...v,settings:{...v.settings,[d.key]:e.target.value}}))}/></label>:<Numeric label={d.label} value={Number(draft.settings[d.key])} min={d.min} max={d.max} integer={d.type==='integer'} onChange={number=>change(v=>({...v,settings:{...v.settings,[d.key]:number}}))}/>}
      <small className="config-hint">{d.policy==='new-job'?'Applies to new jobs.':d.policy==='reschedule'?'Reschedules the repeating interval.':d.type==='text'?`Up to ${d.maxLength} characters.`:`Allowed: ${d.min}–${d.max}.`}</small>
    </div>)}</div></div></section>}

    {tab==='locations'&&<section className="config-layout"><aside className="config-location-list"><div className="config-list-head"><input className="acp-input" type="search" aria-label="Search locations" placeholder="Find a service or location…" value={query} onChange={e=>setQuery(e.target.value)}/><button className="acp-btn" type="button" onClick={addLocation}>+ Add location</button><small>{resultCount} locations</small></div>{draft.locations.filter(row=>(row.label+' '+row.key+' '+row.category).toLowerCase().includes(query.toLowerCase())).map(row=><button type="button" key={row.key} className={selected===row.key?'is-active':''} onClick={()=>setSelected(row.key)}><b>{row.label}</b><span>{title(row.category)} · {row.enabled?'Enabled':'Disabled'}</span></button>)}</aside>
      {selectedLocation&&<div className="config-panel" key={selectedLocation.key}><h2>{selectedLocation.label}</h2><p className="config-muted">Position, interaction range, interior and virtual world are applied together. A disabled service does not appear at its placeholder coordinates.</p><div className="config-fields">
        <label className="config-field"><span>Name</span><input className="acp-input" value={selectedLocation.label} maxLength={64} onChange={e=>updateLocation({label:e.target.value})}/></label>
        <label className="config-field"><span>Category</span><select className="acp-input" value={selectedLocation.category} disabled={coreLocations.some(l=>l.key===selected)} onChange={e=>updateLocation({category:e.target.value})}>{locationCategories.map(name=><option key={name} value={name} disabled={name==='gym_machine'}>{title(name)}</option>)}</select></label>
        {(['x','y','z','angle','interior','world','radius','modelId','sortOrder'] as const).map(field=><Numeric key={field} label={({x:'X',y:'Y',z:'Z',angle:'Facing angle',interior:'Interior',world:'Virtual world',radius:'Interaction radius',modelId:'Stock marker/model ID',sortOrder:'List order'})[field]} value={selectedLocation[field]} integer={['interior','world','modelId','sortOrder'].includes(field)} onChange={value=>updateLocation({[field]:value})}/>)}
      </div><div className="config-checks"><label><input type="checkbox" checked={selectedLocation.enabled} onChange={e=>updateLocation({enabled:e.target.checked})}/> Enabled</label><label><input type="checkbox" checked={selectedLocation.gpsEnabled} onChange={e=>updateLocation({gpsEnabled:e.target.checked})}/> Show in GPS</label></div>
      {selectedLocation.category==='fishing'&&<label className="config-field"><span>Polygon vertices — one X, Y pair per line</span><textarea className="acp-input" rows={10} defaultValue={selectedLocation.vertices.map(p=>`${p.x}, ${p.y}`).join('\n')} onChange={e=>updateLocation({vertices:e.target.value.trim().split('\n').filter(Boolean).map(line=>{const values=line.trim().split(/[\s,]+/).map(Number);return{x:values[0]??NaN,y:values[1]??NaN}})})}/></label>}
      <p className="config-hint">Stable key: <code>{selectedLocation.key}</code>. {coreLocations.some(l=>l.key===selected)?'Core service records can be disabled, but remain available for configuration.':''}</p>
      {!coreLocations.some(l=>l.key===selected)&&<button type="button" className="acp-btn" onClick={()=>{change(value=>({...value,locations:value.locations.filter(row=>row.key!==selected)}));setSelected(draft.locations.find(row=>row.key!==selected)?.key??'')}}>Remove location from draft</button>}
      </div>}
    </section>}

    {tab==='vehicles'&&<section className="config-panel"><h2>Vehicle catalogue and cargo</h2><p className="config-muted">Cargo limits are bounded by the existing 64-slot allocation. Loaded deliveries retain their accepted capacity and pay. Leave a price blank to use the model’s existing fallback.</p><input className="acp-input config-search" type="search" aria-label="Search vehicle models" placeholder="Model ID or vehicle name" value={query} onChange={e=>setQuery(e.target.value)}/><div className="config-table-wrap"><table className="acp-table"><thead><tr><th>Model</th><th>Catalogue price</th><th>Delivery slots</th><th>Enabled</th></tr></thead><tbody>{draft.models.filter(row=>(row.modelId+' '+vehicleName(row.modelId)).toLowerCase().includes(query.toLowerCase())).map(row=><tr key={row.modelId}><td>{vehicleName(row.modelId)} <small>#{row.modelId}</small></td><td><input aria-label={`Price for model ${row.modelId}`} className="acp-input" type="number" min={0} value={row.price??''} onChange={e=>change(value=>({...value,models:value.models.map(item=>item.modelId===row.modelId?{...item,price:e.target.value===''?null:Number(e.target.value)}:item)}))}/></td><td><input aria-label={`Cargo slots for model ${row.modelId}`} className="acp-input" type="number" min={0} max={64} value={row.cargoSlots} onChange={e=>change(value=>({...value,models:value.models.map(item=>item.modelId===row.modelId?{...item,cargoSlots:Number(e.target.value)}:item)}))}/></td><td><input aria-label={`Enable model ${row.modelId}`} type="checkbox" checked={row.enabled} onChange={e=>change(value=>({...value,models:value.models.map(item=>item.modelId===row.modelId?{...item,enabled:e.target.checked}:item)}))}/></td></tr>)}</tbody></table></div></section>}

    {tab==='squads'&&<section className="config-panel"><h2>Faction squads</h2><p className="config-muted">IDs stay unique across factions. Assigned squads cannot be deleted or disabled until their members are reassigned. Roles: 1 tactical, 2 detective, 3 both.</p><div className="config-table-wrap"><table className="acp-table"><thead><tr><th>ID</th><th>Faction ID</th><th>Name</th><th>Roles</th><th>Enabled</th><th/></tr></thead><tbody>{draft.squads.map((row,index)=><tr key={index}><td>{row.id}</td><td><input className="acp-input" type="number" aria-label={`Faction for squad ${row.id}`} value={row.factionId} onChange={e=>change(v=>({...v,squads:v.squads.map((item,i)=>i===index?{...item,factionId:Number(e.target.value)}:item)}))}/></td><td><input className="acp-input" maxLength={23} aria-label={`Name for squad ${row.id}`} value={row.name} onChange={e=>change(v=>({...v,squads:v.squads.map((item,i)=>i===index?{...item,name:e.target.value}:item)}))}/></td><td><select className="acp-input" aria-label={`Roles for squad ${row.id}`} value={row.roles} onChange={e=>change(v=>({...v,squads:v.squads.map((item,i)=>i===index?{...item,roles:Number(e.target.value)}:item)}))}><option value={0}>None</option><option value={1}>Tactical</option><option value={2}>Detective</option><option value={3}>Both</option></select></td><td><input aria-label={`Enable squad ${row.id}`} type="checkbox" checked={row.enabled} onChange={e=>change(v=>({...v,squads:v.squads.map((item,i)=>i===index?{...item,enabled:e.target.checked}:item)}))}/></td><td><button type="button" className="acp-btn" onClick={()=>change(v=>({...v,squads:v.squads.filter((_,i)=>i!==index)}))}>Remove</button></td></tr>)}</tbody></table></div><button className="acp-btn" type="button" onClick={()=>{let id=1;while(draft.squads.some(row=>row.id===id))id++;change(v=>({...v,squads:[...v.squads,{id,factionId:1,name:'New squad',roles:0,enabled:true}]}))}}>+ Add squad</button></section>}

    {tab==='history'&&<section className="config-panel"><h2>Configuration history</h2><p className="config-muted">Restore creates a new revision containing the values before the selected change. It is validated and audited like a normal save.</p><div className="config-table-wrap"><table className="acp-table"><thead><tr><th>Revision</th><th>Operator</th><th>Change</th><th>Time</th><th/></tr></thead><tbody>{history.map(row=><tr key={row.id}><td>{row.revision}</td><td>{row.account_name}<small> {row.source}</small></td><td>{row.description}</td><td>{new Date(row.created_at*1000).toISOString().replace('T',' ').slice(0,19)} UTC</td><td><button className="acp-btn" type="button" disabled={pending||dirty} onClick={()=>{if(!window.confirm(`Restore the configuration before revision ${row.revision}?`))return;startTransition(async()=>{const result=await restoreRuntimeRevision(row.revision,draft.state.revision);setError(!result.ok);setMessage(result.ok?`Restored as revision ${result.revision}.`:result.error??'Restore failed.');if(result.ok)router.refresh()})}}>Restore prior values</button></td></tr>)}</tbody></table>{!history.length&&<p className="config-muted">No changes have been saved yet.</p>}</div></section>}

    <footer className="config-savebar"><div aria-live="polite" className={error?'config-error':''}>{message||(dirty?'You have unsaved changes.':`Editing revision ${draft.state.revision}`)}</div><div><button type="button" className="acp-btn" disabled={pending} onClick={()=>{if(dirty&&!window.confirm('Discard unsaved configuration changes?'))return;setDirty(false);setDraft(copy(initial));setMessage('');router.refresh()}}>Reload / discard</button><button type="button" className="acp-btn acp-btn-primary" disabled={!dirty||pending} onClick={save}>{pending?'Saving…':'Save changes'}</button></div></footer>
  </div>
}
