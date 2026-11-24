import {test} from 'node:test';
import assert from 'node:assert/strict';
import {entityTypes} from './entities.mjs';
import {validateEntityPatch} from './entity-store.mjs';
const valid=()=>({type:'atm',id:0,record:{pos_x:0,pos_y:0,pos_z:0,angle:0}});
test('entity families are a whitelist, not arbitrary table access',()=>{for(const type of ['accounts','atms; DROP TABLE accounts','__proto__'])assert.throws(()=>validateEntityPatch({...valid(),type}));});
test('ATM input accepts an explicit origin and bounds its position/facing',()=>{assert.equal(validateEntityPatch(valid()).record.pos_x,0);for(const patch of [{pos_x:Infinity},{angle:361},{pos_z:20001}])assert.throws(()=>validateEntityPatch({...valid(),record:{...valid().record,...patch}}));});
test('entity IDs and fields cannot bypass the save contract',()=>{for(const id of [-1,0.5,'1'])assert.throws(()=>validateEntityPatch({...valid(),id}));assert.throws(()=>validateEntityPatch({...valid(),record:{...valid().record,account_stafflevel:8}}));assert.throws(()=>validateEntityPatch({...valid(),record:{pos_x:0}}));});
test('only persisted entities can be deleted',()=>{assert.throws(()=>validateEntityPatch({...valid(),record:null}));assert.equal(validateEntityPatch({type:'atm',id:1,record:null}).record,null);});

test('armory names reject markup/control characters and numeric fields stay integers',()=>{
  const type={type:'armory_type',id:0,record:{faction_id:1,type_name:'SAPD',type_enabled:1}};
  for(const type_name of ['<script>','line\nbreak','x'.repeat(32)])assert.throws(()=>validateEntityPatch({...type,record:{...type.record,type_name}}));
  assert.throws(()=>validateEntityPatch({...type,record:{...type.record,faction_id:1.5}}));
  assert.equal(validateEntityPatch(type).record.type_name,'SAPD');
});

test('uniform entries use valid stock skins and integer restrictions',()=>{
 const uniform={type:'faction_skin',id:0,record:{faction_skin_factionid:1,faction_skin_skinid:280,faction_skin_tier:2,faction_skin_squad:10,faction_skin_armory_type:0}};
 assert.equal(validateEntityPatch(uniform).record.faction_skin_skinid,280);
 for(const patch of [{faction_skin_skinid:74},{faction_skin_skinid:312},{faction_skin_tier:1.5},{faction_skin_squad:128}])assert.throws(()=>validateEntityPatch({...uniform,record:{...uniform.record,...patch}}));
});

test('repair points enforce vehicle/faction types and plain descriptions',()=>{
 const point={type:'repair_refuel',id:0,record:{rprf_desc:'Aircraft service',rprf_pos_x:0,rprf_pos_y:0,rprf_pos_z:0,rprf_type:2,rprf_faction_type:-1,rprf_hidden:0}};
 assert.equal(validateEntityPatch(point).record.rprf_type,2);
 for(const patch of [{rprf_type:5},{rprf_type:4,rprf_faction_type:8},{rprf_faction_type:3},{rprf_desc:'{FF0000}bad'},{rprf_hidden:2}])assert.throws(()=>validateEntityPatch({...point,record:{...point.record,...patch}}));
 assert.equal(validateEntityPatch({...point,record:{...point.record,rprf_type:4,rprf_faction_type:3}}).record.rprf_faction_type,3);
});

test('property placement is update-only and rejects economic fields',()=>{
 const record=Object.fromEntries(Object.entries(entityTypes.property_placement.fields).map(([key,field])=>[key,field.default]));
 assert.equal(validateEntityPatch({type:'property_placement',id:7,record}).id,7);
 for(const patch of [{id:0,record},{id:7,record:null},{id:7,record:{...record,property_owner:8}},{id:7,record:{...record,property_int_vw:-1}}])assert.throws(()=>validateEntityPatch({type:'property_placement',...patch}));
});

test('fleet placement rejects lifecycle fields and bounds delivery worlds',()=>{
 for(const type of ['vehicle_spawn','dealership_placement']) {
  const record=Object.fromEntries(Object.entries(entityTypes[type].fields).map(([key,field])=>[key,field.text?'Test dealer':field.default]));
  assert.equal(validateEntityPatch({type,id:1,record}).id,1);
  assert.throws(()=>validateEntityPatch({type,id:0,record}));assert.throws(()=>validateEntityPatch({type,id:1,record:null}));
  assert.throws(()=>validateEntityPatch({type,id:1,record:{...record,vehicle_owner:8}}));
 }
});
