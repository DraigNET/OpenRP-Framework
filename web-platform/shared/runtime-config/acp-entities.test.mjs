import {test} from 'node:test';
import assert from 'node:assert/strict';
import {acpEntityTypes,assertACPEntityChanges,assertACPEntityType} from './acp-entities.mjs';
test('ACP cannot bypass in-game-only placement editors with a crafted request',()=>{
 for(const type of ['atm','repair_refuel','property_placement','vehicle_spawn','dealership_placement']) {
  assert.equal(Object.hasOwn(acpEntityTypes,type),false);
  assert.throws(()=>assertACPEntityType(type),/in-game editor/);
  assert.throws(()=>assertACPEntityChanges([{type,id:1,record:null}]),/in-game editor/);
 }
 assert.throws(()=>assertACPEntityType('gate'));
 assert.throws(()=>assertACPEntityChanges([{type:'accounts'}]));
});
test('ACP equipment management remains available and scalar saves need no entity editor',()=>{
 for(const type of ['armory_type','locker','armory_weapon','faction_skin'])assert.doesNotThrow(()=>assertACPEntityType(type));
 assert.doesNotThrow(()=>assertACPEntityChanges(undefined));
 assert.doesNotThrow(()=>assertACPEntityChanges([]));
});
