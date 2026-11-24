import { entityTypes } from './entities.mjs';
import { ConfigurationError } from './validation.mjs';

export function validateEntityPatch(input) {
  if(!input || typeof input!=='object' || Array.isArray(input) || !Object.hasOwn(entityTypes,input.type)) throw new ConfigurationError('Unknown world entity type.');
  const definition=entityTypes[input.type];
  if(!Number.isInteger(input.id) || input.id<0 || input.id>2147483000) throw new ConfigurationError('Invalid world entity ID.');
  if(definition.editOnly && (!input.id || input.record===null)) throw new ConfigurationError('This editor only updates existing records; use the existing entity tools to create or delete them.');
  if(input.record===null) {
    if(!input.id) throw new ConfigurationError('A new entity cannot be deleted.');
    return {type:input.type,id:input.id,record:null,expectedRecord:input.expectedRecord};
  }
  if(!input.record || typeof input.record!=='object' || Array.isArray(input.record)) throw new ConfigurationError('Invalid entity fields.');
  if(Object.keys(input.record).some(key=>!Object.hasOwn(definition.fields,key))) throw new ConfigurationError('Unknown entity field.');
  const record={};
  for(const [key,field] of Object.entries(definition.fields)) {
    const value=input.record[key];
    if(field.text) {
      if(typeof value!=='string' || (!field.allowEmpty && !value.trim()) || value.length>field.maxLength || /[\u0000-\u001f\u007f<>]/.test(value)) throw new ConfigurationError(field.label+' must be plain text within its length limit.');
      record[key]=value.trim();
    }else {
      if(typeof value!=='number' || !Number.isFinite(value) || value<field.min || value>field.max || (field.integer && !Number.isInteger(value))) throw new ConfigurationError(field.label+' is outside the supported range.');
      record[key]=value;
    }
  }
  if(input.type==='repair_refuel') {
    if(record.rprf_desc.includes('{')) throw new ConfigurationError('Repair point descriptions cannot contain colour codes.');
    if(record.rprf_type===4 && ![0,1,2,3,4,5,6,7,10].includes(record.rprf_faction_type)) throw new ConfigurationError('Choose a supported faction type for this repair point.');
    if(record.rprf_type!==4 && record.rprf_faction_type!==-1) throw new ConfigurationError('Non-faction repair points must use faction type -1.');
  }
  if(input.type==='faction_skin' && record.faction_skin_skinid===74) throw new ConfigurationError('Skin 74 is not a valid stock skin.');
  return {type:input.type,id:input.id,record,expectedRecord:input.expectedRecord};
}

// The caller owns the revision lock and transaction. Audit snapshots and change
// events therefore commit with the actual entity writes, or all roll back.
export async function applyEntityChanges(db,input,revision) {
  if(!Array.isArray(input) || input.length>100) throw new ConfigurationError('At most 100 entity changes may be saved together.');
  const patches=input.map(validateEntityPatch).sort((a,b)=>Number(a.record!==null)-Number(b.record!==null)),seen=new Set(),before=[],after=[];
  await db.query('SET @orp_config_write=1');
  try {
  for(const patch of patches) {
    if(patch.id && seen.has(patch.type+':'+patch.id)) throw new ConfigurationError('Duplicate entity changes in one batch.');
    seen.add(patch.type+':'+patch.id);
    const definition=entityTypes[patch.type],columns=Object.keys(definition.fields);
    const [old]=patch.id?await db.query('SELECT '+columns.map(key=>'`'+key+'`').join(',')+' FROM `'+definition.table+'` WHERE `'+definition.id+'`=? FOR UPDATE',[patch.id]):[];
    if(definition.editOnly && !old) throw new ConfigurationError('This record no longer exists. Reload the row list.','conflict');
    const previous=old?Object.fromEntries(columns.map(key=>[key,definition.fields[key].text?String(old[key]):Number(old[key])])):null;
    if(patch.expectedRecord!==undefined && JSON.stringify(previous)!==JSON.stringify(patch.expectedRecord)) throw new ConfigurationError('This entity changed since it was opened. Reload its current fields before saving.','conflict');
    if(JSON.stringify(previous)===JSON.stringify(patch.record)) continue;
    if(patch.type==='property_placement' && previous && ['x','y','z','int','vw'].some(key=>previous['property_int_'+key]!==patch.record['property_int_'+key])) {
      const [occupants]=await db.query('SELECT COUNT(*) AS total FROM characters WHERE player_online=0 AND player_last_pos_int=? AND player_last_pos_vw=?',[previous.property_int_int,previous.property_int_vw]);
      if(Number(occupants.total)) throw new ConfigurationError('Move saved offline occupants out of the old interior before changing its destination.');
    }
    if(patch.type==='armory_type') {
      if(patch.record===null || (previous && previous.faction_id!==patch.record.faction_id)) {
        const [links]=await db.query('SELECT (SELECT COUNT(*) FROM faction_armories WHERE armory_type_id=?)+(SELECT COUNT(*) FROM faction_armory_weapons WHERE armory_type_id=?)+(SELECT COUNT(*) FROM faction_skins WHERE faction_skin_armory_type=?) AS total',[patch.id,patch.id,patch.id]);
        if(Number(links.total)) throw new ConfigurationError('Reassign linked lockers and weapons before deleting or moving an armory type.');
      }
    }
    if(patch.record && ['armory_type','locker','armory_weapon','faction_skin'].includes(patch.type)) {
      const faction=patch.record[definition.factionField??'faction_id'];
      const [owner]=await db.query('SELECT faction_id FROM factions WHERE faction_id=?',[faction]);
      if(!owner) throw new ConfigurationError('The faction does not exist.');
      const type=patch.record[definition.typeField??'armory_type_id'];
      if(type) {
        const [row]=await db.query('SELECT faction_id FROM faction_armory_types WHERE armory_type_id=?',[type]);
        if(!row || row.faction_id!==faction) throw new ConfigurationError('The armory type must belong to this faction.');
      }
      const squad=patch.record[definition.squadField??'armory_squad']??patch.record.squad_id;
      if(squad) {
        const [row]=await db.query('SELECT faction_id,enabled FROM runtime_faction_squads WHERE squad_id=?',[squad]);
        if(!row || !row.enabled || row.faction_id!==faction) throw new ConfigurationError('The enabled squad must belong to this faction.');
      }
      if(definition.groupLimit) {
        const [group]=await db.query('SELECT COUNT(*) AS total FROM `'+definition.table+'` WHERE `'+definition.factionField+'`=? AND `'+definition.id+'`<>?',[faction,patch.id]);
        if(Number(group.total)>=definition.groupLimit) throw new ConfigurationError('This faction already has the maximum '+definition.groupLimit+' uniform entries.');
      }
      if(patch.type==='faction_skin' && patch.record.faction_skin_skinid===74) throw new ConfigurationError('Skin 74 is not a valid stock skin.');
      if(patch.type==='armory_weapon' && [19,20,21].includes(patch.record.weapon_id)) throw new ConfigurationError('This weapon ID is not usable equipment.');
    }
    let id=patch.id;
    if(patch.record===null) await db.query('DELETE FROM `'+definition.table+'` WHERE `'+definition.id+'`=?',[id]);
    else if(old) await db.query('UPDATE `'+definition.table+'` SET '+columns.map(key=>'`'+key+'`=?').join(',')+' WHERE `'+definition.id+'`=?',[...columns.map(key=>patch.record[key]),id]);
    else {
      const [count]=await db.query('SELECT COUNT(*) AS total FROM `'+definition.table+'`');
      if(Number(count.total)>=definition.limit) throw new ConfigurationError(definition.label+' exceed the game capacity of '+definition.limit+'.');
      const names=id?[definition.id,...columns]:columns;
      const result=await db.query('INSERT INTO `'+definition.table+'` ('+names.map(key=>'`'+key+'`').join(',')+') VALUES('+names.map(()=>'?').join(',')+')',id?[id,...columns.map(key=>patch.record[key])]:columns.map(key=>patch.record[key]));
      if(!id) id=Number(result.insertId);
    }
    before.push({type:patch.type,id,record:previous});after.push({type:patch.type,id,record:patch.record});
    await db.query('INSERT INTO runtime_entity_changes(revision,entity_type,entity_id,operation) VALUES(?,?,?,?)',[revision,patch.type,id,patch.record===null?'delete':'upsert']);
  }
  return {before,after};
  }finally{await db.query('SET @orp_config_write=0');}
}

// A consistent row list and revision prevents an editor from opening with mixed data.
export async function getEntities(db,type) {
  if(!Object.hasOwn(entityTypes,type)) throw new ConfigurationError('Unknown world entity type.');
  const definition=entityTypes[type],columns=[definition.id,...Object.keys(definition.fields)];
  await db.beginTransaction();
  try {
    const [state]=await db.query('SELECT revision FROM runtime_config_state WHERE id=1');
    if(!state) throw new ConfigurationError('Import the complete database/schema.sql into an empty database first.','migration');
    const rows=await db.query('SELECT '+columns.map(key=>'`'+key+'`').join(',')+' FROM `'+definition.table+'` ORDER BY `'+definition.id+'`');
    await db.commit();return {revision:state.revision,rows:rows.map(row=>({id:row[definition.id],record:Object.fromEntries(Object.keys(definition.fields).map(key=>[key,definition.fields[key].text?String(row[key]):Number(row[key])]))}))};
  }catch(error){await db.rollback();throw error;}
}
