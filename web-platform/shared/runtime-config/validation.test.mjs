import { test } from 'node:test';
import assert from 'node:assert/strict';
import { settings, locations, cargoModels, squads } from './catalog.mjs';
import { validateConfiguration, validateSettings, validateLocation } from './validation.mjs';
function snapshot() { return { settings:Object.fromEntries(settings.map(s=>[s.key,s.default])),locations:locations.map(l=>({...l,gpsEnabled:!!l.gps,modelId:l.pickup??0,sortOrder:0,vertices:[]})),models:Object.entries(cargoModels).map(([id,capacity])=>({modelId:Number(id),cargoSlots:capacity,price:null,enabled:true})),squads:squads.map(s=>({...s,enabled:true})) }; }
test('default catalogue forms a valid complete configuration',()=>{assert.equal(validateConfiguration(snapshot()).settings['dmv.fee'],250);});
test('unknown settings cannot become arbitrary database fields',()=>{assert.throws(()=>validateSettings({'rcon.password':'test'}),/Unknown setting/);});
test('non-finite, blank and out-of-range numeric values are rejected',()=>{for(const value of [NaN,Infinity,'',null,-1,1000001])assert.throws(()=>validateSettings({'dmv.fee':value}));});
test('integer settings reject fractional amounts',()=>{assert.throws(()=>validateSettings({'dmv.fee':0.5}));});
test('location supports a legitimate enabled origin without inferring disabled state',()=>{const value=validateLocation({...snapshot().locations[0],enabled:true});assert.equal(value.enabled,true);assert.equal(value.x,0);});
test('interior, world, coordinate and radius limits are enforced',()=>{for(const patch of [{interior:256},{world:-1},{radius:0},{z:Infinity},{x:20001}])assert.throws(()=>validateLocation({...snapshot().locations[0],...patch}));});
test('plain-text names and boolean fields reject malformed data',()=>{for(const patch of [{label:'line\nbreak'},{label:'<script>'},{enabled:'false'}])assert.throws(()=>validateLocation({...snapshot().locations[0],...patch}));});
test('core locations can be disabled but cannot be silently removed or retyped',()=>{const value=snapshot();value.locations.shift();assert.throws(()=>validateConfiguration(value),/must remain/);assert.throws(()=>validateLocation({...snapshot().locations[0],category:'spawn'}),/cannot be changed/);});
test('cross-field bounds prevent invalid pay and coverage ranges',()=>{for(const patch of [{'pizza.pay_min':900},{'pizza.min_x':5000},{'paycheck.minimum_minutes':61},{'medical.bill_min':3000}]){const value=snapshot();Object.assign(value.settings,patch);assert.throws(()=>validateConfiguration(value));}});
test('cargo capacity cannot exceed the existing vehicle slot allocation',()=>{const value=snapshot();value.models[0].cargoSlots=65;assert.throws(()=>validateConfiguration(value));});
test('duplicate location keys and squad IDs are rejected',()=>{const value=snapshot();value.locations.push(value.locations[0]);assert.throws(()=>validateConfiguration(value));const other=snapshot();other.squads.push(other.squads[0]);assert.throws(()=>validateConfiguration(other));});
test('valid polygons are accepted and crossing edges are rejected',()=>{const row={...snapshot().locations[0],key:'fish_test',category:'fishing',vertices:[{x:0,y:0},{x:4,y:0},{x:4,y:4},{x:0,y:4}]};assert.equal(validateLocation(row).vertices.length,4);assert.throws(()=>validateLocation({...row,vertices:[{x:0,y:0},{x:4,y:4},{x:0,y:3},{x:4,y:0}]}));});

test('prison cell codes stay unique and fit the existing sentence field',()=>{
  const value=snapshot(),cells=value.locations.filter(row=>row.category==='prison_cell');
  cells[0].label='Cell A';assert.throws(()=>validateConfiguration(value),/1-3 character/);
  cells[0].label=cells[1].label.toLowerCase();assert.throws(()=>validateConfiguration(value),/unique/);
});
test('GPS reserves enough entries for every dealership',()=>{
  const value=snapshot();
  for(let n=0;n<233;n++)value.locations.push({...value.locations[0],key:'service_'+n,category:'service',enabled:true,gpsEnabled:true});
  assert.throws(()=>validateConfiguration(value),/232/);
});
