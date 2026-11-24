import {checkFirmLifecycle} from './firm-lifecycle.test.mjs';
import {entityTypes} from '../../web-platform/shared/runtime-config/entities.mjs';
import {getEntities} from '../../web-platform/shared/runtime-config/entity-store.mjs';
import fs from 'node:fs';
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import { getConfiguration,saveConfiguration,restoreConfiguration } from '../../web-platform/shared/runtime-config/store.mjs';
const require=createRequire(new URL('../../web-platform/web/package.json',import.meta.url));
const mariadb=require('mariadb');
// Deliberately requires a pre-created, empty test database; never targets production.
const rawUrl=process.env.ORP_TEST_DATABASE_URL;
if(!rawUrl) throw Error('Set ORP_TEST_DATABASE_URL to an empty orp_test_* MariaDB database');
const url=new URL(rawUrl), database=decodeURIComponent(url.pathname.slice(1));
if(url.protocol!=='mysql:' || !/^orp_test_[A-Za-z0-9_]{1,48}$/.test(database)) throw Error('A mysql URL with an orp_test_* database is required');
const connection={host:url.hostname,port:Number(url.port||3306),user:decodeURIComponent(url.username),password:decodeURIComponent(url.password),database};
let db=await mariadb.createConnection({...connection,multipleStatements:true});
const results=[];
const check=(condition,message)=>{if(!condition)throw Error(message);results.push(message);};
try {
  if((await db.query('SHOW TABLES')).length) throw Error('Test database is not empty; refusing to modify it');
  const schema=fs.readFileSync(new URL('../../database/schema.sql',import.meta.url),'utf8')
    .replace(/^CREATE DATABASE[^;]*;/gmi,'').replace(/^USE[^;]*;/gmi,'')
    .replace(/^DELIMITER.*$/gm,'').replace(/\/\/[ \t]*$/gm,';');
  await db.query(schema);
  await db.end();
  db=await mariadb.createConnection({...connection,connectTimeout:5000,queryTimeout:10000,socketTimeout:15000});
  execFileSync(process.execPath,['scripts/create-admin.mjs','--name','RuntimeAdmin','--email','runtime@example.test'],{cwd:new URL('../../web-platform/web/',import.meta.url),env:{...process.env,DATABASE_URL:url.href},stdio:'pipe'});
  const [account]=await db.query("SELECT account_id FROM accounts WHERE account_name='RuntimeAdmin'");
  const actor={id:account.account_id,name:'RuntimeAdmin',source:'integration-test'};
  let current=await getConfiguration(db);
  check(current.state.revision===1,'fresh runtime schema/defaults load');
  const [motdDefaults]=await db.query('SELECT admin_motd_1,admin_motd_edit_time FROM server LIMIT 1');check(motdDefaults.admin_motd_1===''&&motdDefaults.admin_motd_edit_time===0,'fresh administrative MOTD defaults do not produce NULL startup cache warnings');
  const changed=await saveConfiguration(db,{expectedRevision:1,settings:{'dmv.fee':375}},actor);
  check(changed.revision===2,'validated save increments revision');
  current=await getConfiguration(db);check(current.settings['dmv.fee']===375,'saved values persist');
  let conflict=false;try{await saveConfiguration(db,{expectedRevision:1,settings:{'dmv.fee':999}},actor);}catch(e){conflict=e.code==='conflict';}
  check(conflict,'stale writer is rejected');
  let invalid=false;try{await saveConfiguration(db,{expectedRevision:2,settings:{'pizza.pay_min':999999}},actor);}catch{invalid=true;}
  check(invalid,'cross-field invalid save rolls back');
  current=await getConfiguration(db);check(current.state.revision===2&&current.settings['dmv.fee']===375,'failed save leaves prior revision intact');
  const [audit]=await db.query('SELECT COUNT(*) AS total FROM runtime_config_audit');check(Number(audit.total)===1,'successful mutation has an audit record');
  await restoreConfiguration(db,2,2,actor);current=await getConfiguration(db);
  check(current.state.revision===3&&current.settings['dmv.fee']===250,'restore creates a new revision with prior values');
  let cellConfig=await getConfiguration(db);
  const prison=cellConfig.locations.map(row=>row.key==='prison_cell_1'?{...row,enabled:true,x:100,y:100,z:20,world:600,interior:6}:row);
  let cellSave=await saveConfiguration(db,{expectedRevision:cellConfig.state.revision,locations:prison},actor);
  await db.query("INSERT INTO characters(account_id,player_name,player_arrest_cell,player_arrest_time) VALUES(?,'Cell_Test','C01',60)",[actor.id]);
  cellConfig=await getConfiguration(db);
  let protectedCell=false;try{await saveConfiguration(db,{expectedRevision:cellSave.revision,locations:cellConfig.locations.map(row=>row.key==='prison_cell_1'?{...row,x:110}:row)},actor);}catch(e){protectedCell=e.message.includes('sentenced');}
  check(protectedCell,'occupied prison cell cannot move, including offline prisoners');
  let protectedJail=false;await db.query("UPDATE characters SET player_ajail_time=60 WHERE player_name='Cell_Test'");
  try{await saveConfiguration(db,{expectedRevision:cellSave.revision,settings:{'dmv.fee':400}},actor);}catch(e){protectedJail=e.message.includes('Admin jail');}
  check(protectedJail,'admin jail cannot remain disabled while offline sentences exist');
  await db.query("DELETE FROM characters WHERE player_name='Cell_Test'");
  const entityCreated=await saveConfiguration(db,{expectedRevision:cellSave.revision,entities:[{type:'atm',id:0,record:{pos_x:10,pos_y:20,pos_z:30,angle:90},expectedRecord:null}]},actor);
  let entities=await getEntities(db,'atm');const atm=entities.rows[0];
  check(atm.id>0&&atm.record.pos_x===10,'entity creation and revision commit together');
  const [eventCount]=await db.query('SELECT COUNT(*) AS total FROM runtime_entity_changes');check(Number(eventCount.total)===1,'entity transaction writes one change event');
  await db.query('SET @orp_config_write=1');
  await db.query('UPDATE atms SET pos_x=77 WHERE id=?',[atm.id]);
  await db.query('SET @orp_config_write=0');
  let rowConflict=false;try{await saveConfiguration(db,{expectedRevision:entityCreated.revision,entities:[{type:'atm',id:atm.id,record:{...atm.record,pos_x:99},expectedRecord:atm.record}]},actor);}catch(e){rowConflict=e.code==='conflict';}
  check(rowConflict,'row fingerprint detects an in-game edit outside the revision editor');
  entities=await getEntities(db,'atm');const removed=await saveConfiguration(db,{expectedRevision:entities.revision,entities:[{type:'atm',id:atm.id,record:null,expectedRecord:entities.rows[0].record}]},actor);
  check((await getEntities(db,'atm')).rows.length===0,'entity deletion is transactional');
  let restored=await restoreConfiguration(db,removed.revision,removed.revision,actor);
  entities=await getEntities(db,'atm');check(entities.rows[0].id===atm.id&&entities.rows[0].record.pos_x===77,'restoring an entity deletion preserves its persistent ID');
  restored=await restoreConfiguration(db,entityCreated.revision,restored.revision,actor);
  check((await getEntities(db,'atm')).rows.length===0,'restoring before entity creation removes it');
  const defaults=type=>Object.fromEntries(Object.entries(entityTypes[type].fields).map(([key,value])=>[key,value.default]));
  const armoryType=await saveConfiguration(db,{expectedRevision:restored.revision,entities:[{type:'armory_type',id:0,record:{...defaults('armory_type'),faction_id:1,type_name:'SAPD Standard'}}]},actor);
  const typeRow=(await getEntities(db,'armory_type')).rows.find(row=>row.record.type_name==='SAPD Standard');
  check(typeRow.record.type_name==='SAPD Standard','armory type text fields persist without numeric coercion');
  const armorySaved=await saveConfiguration(db,{expectedRevision:armoryType.revision,entities:[{type:'locker',id:0,record:{...defaults('locker'),faction_id:1,armory_type_id:typeRow.id,armory_name:'SAPD Locker',armory_x:1500,armory_y:-1600,armory_z:13.5}},{type:'armory_weapon',id:0,record:{...defaults('armory_weapon'),faction_id:1,armory_type_id:typeRow.id,weapon_id:24}}]},actor);
  check((await getEntities(db,'locker')).rows.some(row=>row.record.armory_name==='SAPD Locker'),'locker and typed weapon creation commit in one revision');
  let wrongFaction=false;try{await saveConfiguration(db,{expectedRevision:armorySaved.revision,entities:[{type:'locker',id:0,record:{...defaults('locker'),faction_id:2,armory_type_id:typeRow.id,armory_name:'Wrong faction'}}]},actor);}catch(e){wrongFaction=e.message.includes('belong');}
  check(wrongFaction,'locker cannot use another faction armory type');
  let dependent=false;try{await saveConfiguration(db,{expectedRevision:armorySaved.revision,entities:[{type:'armory_type',id:typeRow.id,record:null}]},actor);}catch(e){dependent=e.message.includes('Reassign');}
  check(dependent,'referenced armory type cannot be deleted');
  const uniformSaved=await saveConfiguration(db,{expectedRevision:armorySaved.revision,entities:[{type:'faction_skin',id:0,record:{...defaults('faction_skin'),faction_skin_factionid:1,faction_skin_skinid:285,faction_skin_tier:2,faction_skin_squad:10,faction_skin_armory_type:typeRow.id}}]},actor);
  check((await getEntities(db,'faction_skin')).rows.some(row=>row.record.faction_skin_armory_type===typeRow.id),'uniform skin/tier/squad/locker restrictions persist together');
  let skinFaction=false;try{await saveConfiguration(db,{expectedRevision:uniformSaved.revision,entities:[{type:'faction_skin',id:0,record:{...defaults('faction_skin'),faction_skin_factionid:2,faction_skin_armory_type:typeRow.id}}]},actor);}catch(e){skinFaction=e.message.includes('belong');}
  check(skinFaction,'uniform cannot reference another faction locker type');
  const beforeSquads=await getConfiguration(db);let referencedSquad=false;
  try{await saveConfiguration(db,{expectedRevision:uniformSaved.revision,squads:beforeSquads.squads.map(row=>row.id===10?{...row,enabled:false}:row)},actor);}catch(e){referencedSquad=e.message.includes('referenced');}
  check(referencedSquad,'squad restrictions cannot be orphaned by disabling a referenced squad');
  const [uniformCount]=await db.query('SELECT COUNT(*) AS total FROM faction_skins WHERE faction_skin_factionid=1');const bulk=[];
  for(let n=Number(uniformCount.total);n<150;n++){const inserted=await db.query('INSERT INTO faction_skins(faction_skin_factionid,faction_skin_skinid,faction_skin_tier) VALUES(1,280,0)');bulk.push(Number(inserted.insertId));}
  const capRevision=(await getConfiguration(db)).state.revision;
  let capped=false;try{await saveConfiguration(db,{expectedRevision:capRevision,entities:[{type:'faction_skin',id:0,record:{...defaults('faction_skin')}}]},actor);}catch(e){capped=e.message.includes('maximum');}
  check(capped,'uniform limit is enforced per faction before game staging');
  if(bulk.length) await db.query('DELETE FROM faction_skins WHERE faction_skin_id IN ('+bulk.map(()=>'?').join(',')+')',bulk);
  restored={revision:(await getConfiguration(db)).state.revision};

  let repairState=await getConfiguration(db);
  const repairSaved=await saveConfiguration(db,{expectedRevision:repairState.state.revision,entities:[{type:'repair_refuel',id:0,record:{...defaults('repair_refuel'),rprf_desc:'Test aircraft service',rprf_type:2}}]},actor);
  const repair=(await getEntities(db,'repair_refuel')).rows.find(row=>row.record.rprf_desc==='Test aircraft service');
  check(repair.id>0&&repair.record.rprf_faction_type===-1,'repair point coordinates and vehicle restrictions persist transactionally');
  restored=await restoreConfiguration(db,repairSaved.revision,repairSaved.revision,actor);
  check(!(await getEntities(db,'repair_refuel')).rows.some(row=>row.id===repair.id),'repair point creation is restorable through common history');

  const propertyInsert=await db.query("INSERT INTO properties(property_type,property_price,property_owner,property_ext_x,property_ext_y,property_ext_z,property_int_x,property_int_y,property_int_z,property_int_int,property_int_vw,property_gun_0,property_ammo_0,property_collect) VALUES(0,500,321,100,100,20,200,200,30,5,9001,24,80,4567)");
  const propertyId=Number(propertyInsert.insertId), propertyRow=(await getEntities(db,'property_placement')).rows.find(row=>row.id===propertyId);
  let placementSave=await saveConfiguration(db,{expectedRevision:(await getConfiguration(db)).state.revision,entities:[{type:'property_placement',id:propertyId,record:{...propertyRow.record,property_ext_x:150,property_buy_pos_x:151},expectedRecord:propertyRow.record}]},actor);
  const [preserved]=await db.query('SELECT property_owner,property_gun_0,property_ammo_0,property_collect FROM properties WHERE property_id=?',[propertyId]);
  check(preserved.property_owner===321&&preserved.property_gun_0===24&&preserved.property_ammo_0===80&&preserved.property_collect===4567,'property placement preserves owner, weapons, ammunition and collected money');
  await db.query("INSERT INTO characters(account_id,player_name,player_online,player_last_pos_int,player_last_pos_vw) VALUES(?,'Offline_Property',0,5,9001)",[actor.id]);
  let occupiedProperty=false;const occupiedRow=(await getEntities(db,'property_placement')).rows.find(row=>row.id===propertyId);
  try{await saveConfiguration(db,{expectedRevision:placementSave.revision,entities:[{type:'property_placement',id:propertyId,record:{...occupiedRow.record,property_int_x:250}}]},actor);}catch(e){occupiedProperty=e.message.includes('offline occupants');}
  check(occupiedProperty,'saved offline occupants prevent an interior destination move');
  placementSave=await saveConfiguration(db,{expectedRevision:placementSave.revision,entities:[{type:'property_placement',id:propertyId,record:{...occupiedRow.record,property_ext_y:160}}]},actor);
  check((await getEntities(db,'property_placement')).rows.find(row=>row.id===propertyId).record.property_ext_y===160,'exterior placement remains editable while an interior is occupied');
  restored=await restoreConfiguration(db,placementSave.revision,placementSave.revision,actor);
  check((await getEntities(db,'property_placement')).rows.find(row=>row.id===propertyId).record.property_ext_y===100,'property placement restores through shared history');
  await db.query("DELETE FROM characters WHERE player_name='Offline_Property'");
  await db.query('DELETE FROM properties WHERE property_id=?',[propertyId]);
  restored={revision:(await getConfiguration(db)).state.revision};

  check((await getConfiguration(db)).state.schema_version===4,'fresh schema includes the current runtime version without upgrade scripts');
  const carInsert=await db.query('INSERT INTO vehicles(vehicle_modelid,vehicle_type,vehicle_owner,vehicle_pos_x,vehicle_pos_y,vehicle_pos_z,vehicle_pos_a,vehicle_fuel,vehicle_health,vehicle_trunk_wep_1,vehicle_trunk_ammo_1) VALUES(499,0,321,100,100,20,90,43,825,24,95)');
  const carId=Number(carInsert.insertId),carRow=(await getEntities(db,'vehicle_spawn')).rows.find(row=>row.id===carId);
  let fleetSaved=await saveConfiguration(db,{expectedRevision:(await getConfiguration(db)).state.revision,entities:[{type:'vehicle_spawn',id:carId,record:{...carRow.record,vehicle_pos_x:120,vehicle_vw:42}}]},actor);
  const [carData]=await db.query('SELECT vehicle_owner,vehicle_fuel,vehicle_health,vehicle_trunk_wep_1,vehicle_trunk_ammo_1 FROM vehicles WHERE vehicle_sqlid=?',[carId]);
  check(carData.vehicle_owner===321&&carData.vehicle_fuel===43&&carData.vehicle_health===825&&carData.vehicle_trunk_wep_1===24&&carData.vehicle_trunk_ammo_1===95,'vehicle spawn edits preserve owner, fuel, health and trunk inventory');
  restored=await restoreConfiguration(db,fleetSaved.revision,fleetSaved.revision,actor);check((await getEntities(db,'vehicle_spawn')).rows.find(row=>row.id===carId).record.vehicle_pos_x===100,'vehicle saved spawn restores through history');
  const dealerInsert=await db.query("INSERT INTO dealerships(dealer_type,dealer_name,dealer_color,dealer_pos_x,dealer_pos_y,dealer_pos_z,dealer_spawn_x,dealer_spawn_y,dealer_spawn_z,dealer_spawn_a,dealer_bank,dealer_owner_char_id) VALUES(0,'Test dealer',-1,100,100,20,110,110,20,90,5432,321)");
  const dealerId=Number(dealerInsert.insertId);await db.query('INSERT INTO dealership_stock(dealer_id,model_id,qty) VALUES(?,400,7)',[dealerId]);
  const dealerRow=(await getEntities(db,'dealership_placement')).rows.find(row=>row.id===dealerId);
  fleetSaved=await saveConfiguration(db,{expectedRevision:(await getConfiguration(db)).state.revision,entities:[{type:'dealership_placement',id:dealerId,record:{...dealerRow.record,dealer_name:'Moved dealer',dealer_world:12,dealer_spawn_interior:6,dealer_spawn_world:13}}]},actor);
  const [dealerData]=await db.query('SELECT dealer_bank,dealer_owner_char_id FROM dealerships WHERE dealer_id=?',[dealerId]);const[stockData]=await db.query('SELECT qty FROM dealership_stock WHERE dealer_id=? AND model_id=400',[dealerId]);
  check(dealerData.dealer_bank===5432&&dealerData.dealer_owner_char_id===321&&stockData.qty===7,'dealership placement preserves owner, bank and catalogue stock');
  restored=await restoreConfiguration(db,fleetSaved.revision,fleetSaved.revision,actor);check((await getEntities(db,'dealership_placement')).rows.find(row=>row.id===dealerId).record.dealer_name==='Test dealer','dealership name and delivery worlds restore through history');
  await db.query('DELETE FROM vehicles WHERE vehicle_sqlid=?',[carId]);await db.query('DELETE FROM dealership_stock WHERE dealer_id=?',[dealerId]);await db.query('DELETE FROM dealerships WHERE dealer_id=?',[dealerId]);restored={revision:(await getConfiguration(db)).state.revision};

  const journalStart=(await getConfiguration(db)).state.revision;
  const journalInsert=await db.query('INSERT INTO atms(pos_x,pos_y,pos_z,angle) VALUES(99,99,99,0)');
  const journalId=Number(journalInsert.insertId),journalState=await getConfiguration(db);
  check(journalId>0&&journalState.state.revision===journalStart+1,'legacy/direct entity writes publish a revision without changing INSERT IDs');
  const [journalAudit]=await db.query('SELECT source,before_json FROM runtime_config_audit WHERE revision=?',[journalState.state.revision]);
  const journalBefore=typeof journalAudit.before_json==='string'?JSON.parse(journalAudit.before_json):journalAudit.before_json;
  check(journalAudit.source==='database'&&journalBefore.entities[0].record===null,'database journal keeps a restorable before snapshot');
  await db.query('UPDATE atms SET pos_x=pos_x WHERE id=?',[journalId]);check((await getConfiguration(db)).state.revision===journalState.state.revision,'no-op legacy writes do not publish spurious revisions');
  await db.beginTransaction();await db.query('UPDATE atms SET pos_x=88 WHERE id=?',[journalId]);await db.rollback();
  check((await getConfiguration(db)).state.revision===journalState.state.revision,'legacy entity write rollback includes its journal revision');
  restored=await restoreConfiguration(db,journalState.state.revision,journalState.state.revision,actor);
  check(!(await getEntities(db,'atm')).rows.some(row=>row.id===journalId),'database-writer history restores through the authenticated editor');
  await checkFirmLifecycle(db,check,()=>mariadb.createConnection({...connection,queryTimeout:10000,socketTimeout:15000}));
  restored={revision:(await getConfiguration(db)).state.revision};
  await db.query('UPDATE accounts SET account_stafflevel=2 WHERE account_id=?',[actor.id]);
  let forbidden=false;try{await saveConfiguration(db,{expectedRevision:restored.revision,settings:{'dmv.fee':400}},actor);}catch(e){forbidden=e.code==='forbidden';}
  check(forbidden,'current database staff rank is enforced');
  console.log(JSON.stringify({database,checks:results.length,results}));
} finally { await db.end(); }
