// SQL transport-neutral repository. Pass a transaction-capable MariaDB connection;
// no web server, browser API or ORM is required by this shared implementation.
import { settings as catalogue } from './catalog.mjs';
import { ConfigurationError, validateConfiguration, validateSettings } from './validation.mjs';
import { applyEntityChanges } from './entity-store.mjs';
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

async function readSnapshot(db) {
  const [state] = await db.query('SELECT revision, applied_revision, last_heartbeat, last_error, schema_version FROM runtime_config_state WHERE id=1');
  if (!state || state.schema_version !== 4) throw new ConfigurationError('Use the complete database/schema.sql shipped with this build.', 'migration');
  const [values, rows, vertices, models, squads] = await Promise.all([
    db.query('SELECT setting_key, value_type, number_value, text_value FROM runtime_config_settings ORDER BY setting_key'),
    db.query('SELECT * FROM runtime_locations ORDER BY sort_order, location_id'),
    db.query('SELECT * FROM runtime_location_vertices ORDER BY location_id, vertex_index'),
    db.query('SELECT * FROM runtime_vehicle_models ORDER BY model_id'),
    db.query('SELECT * FROM runtime_faction_squads ORDER BY squad_id'),
  ]);
  return { state, settings: Object.fromEntries(values.map(row => [row.setting_key, row.value_type === 'text' ? row.text_value : Number(row.number_value)])),
    locations: rows.map(row => ({ key: row.location_key, category: row.category, label: row.label, x: Number(row.x), y: Number(row.y), z: Number(row.z), angle: Number(row.angle), interior: row.interior, world: row.virtual_world, radius: Number(row.radius), enabled: row.enabled === 1, gpsEnabled: row.gps_enabled === 1, modelId: row.model_id, sortOrder: row.sort_order, vertices: vertices.filter(v => v.location_id === row.location_id).map(v => ({ x: Number(v.x), y: Number(v.y) })) })),
    models: models.map(row => ({ modelId: row.model_id, cargoSlots: row.cargo_slots, price: row.catalogue_price, enabled: row.enabled === 1 })),
    squads: squads.map(row => ({ id: row.squad_id, factionId: row.faction_id, name: row.squad_name, roles: row.role_flags, enabled: row.enabled === 1 })),
  };
}

// Returns a consistent editor snapshot. A read cannot combine two revisions.
export async function getConfiguration(db) {
  await db.beginTransaction();
  try { const result = await readSnapshot(db); await db.commit(); return result; }
  catch (error) { await db.rollback(); throw error; }
}

export async function getHistory(db) {
  return db.query('SELECT CAST(audit_id AS CHAR) AS id, revision, account_name, source, description, created_at FROM runtime_config_audit ORDER BY revision DESC LIMIT 100');
}

// One batch = one revision. Validate before writing, then audit and commit together.
async function saveConfigurationOnce(db, patch, actor) {
  if (!Number.isInteger(patch?.expectedRevision) || patch.expectedRevision < 1) throw new ConfigurationError('Reload the editor before saving.');
  if (!actor || !Number.isInteger(actor.id) || !actor.name || !['acp', 'desktop', 'integration-test'].includes(actor.source)) throw new ConfigurationError('Authenticated editor context is required.', 'forbidden');
  await db.beginTransaction();
  try {
    const [lock] = await db.query('SELECT revision FROM runtime_config_state WHERE id=1 FOR UPDATE');
    if (!lock) throw new ConfigurationError('Runtime configuration migration is missing.', 'migration');
    if (lock.revision !== patch.expectedRevision) throw new ConfigurationError('Another editor changed the configuration. Reload to review their changes before saving.', 'conflict');
    const [account] = await db.query('SELECT account_stafflevel FROM accounts WHERE account_id=? AND account_name=?', [actor.id, actor.name]);
    if (!account || account.account_stafflevel < 7) throw new ConfigurationError('Manager access is required to change server configuration.', 'forbidden');
    const before = await readSnapshot(db);
    const next = validateConfiguration({ settings: { ...before.settings, ...validateSettings(patch.settings ?? {}) }, locations: patch.locations ?? before.locations, models: patch.models ?? before.models, squads: patch.squads ?? before.squads });
    const prior = { settings: before.settings, locations: before.locations, models: before.models, squads: before.squads };
    if (!patch.entities?.length && same(prior, next)) { await db.commit(); return { revision: lock.revision, changed: false }; }
    const factions = await db.query('SELECT faction_id FROM factions');
    const factionIds = new Set(factions.map(f => f.faction_id));
    if (next.squads.some(squad => !factionIds.has(squad.factionId))) throw new ConfigurationError('Every squad must belong to an existing faction.');
    if(!next.locations.find(row=>row.key==='admin_jail')?.enabled) {
      const [inmates]=await db.query('SELECT COUNT(*) AS total FROM characters WHERE player_ajail_time>0');
      if(Number(inmates.total)>0) throw new ConfigurationError('Admin jail cannot be disabled while any character has an active sentence.');
    }
    // A sentenced cell must stay usable at its existing position. Administrators
    // can move prisoners to another cell first, including offline sentences.
    for(const old of before.locations.filter(row=>row.category==='prison_cell')) {
      const replacement=next.locations.find(row=>row.key===old.key);
      const changed=!replacement || ['label','enabled','x','y','z','angle','interior','world'].some(key=>replacement[key]!==old[key]);
      if(changed) {
        const [occupied]=await db.query('SELECT COUNT(*) AS total FROM characters WHERE player_arrest_cell=? AND (player_arrest_time<>0 OR player_jfl<>0)',[old.label]);
        if(Number(occupied.total)>0) throw new ConfigurationError('Move all sentenced characters out of cell '+old.label+' before changing or disabling it.');
      }
    }
    const revision = lock.revision + 1;
    if (revision > 2147483000) throw new ConfigurationError('Configuration revision limit reached.');
    for (const definition of catalogue) if (before.settings[definition.key] !== next.settings[definition.key]) {
      await db.query('INSERT INTO runtime_config_settings(setting_key,value_type,number_value,text_value,revision) VALUES(?,?,?,?,?) ON DUPLICATE KEY UPDATE value_type=VALUES(value_type),number_value=VALUES(number_value),text_value=VALUES(text_value),revision=VALUES(revision)', [definition.key, definition.type, definition.type === 'text' ? 0 : next.settings[definition.key], definition.type === 'text' ? next.settings[definition.key] : '', revision]);
    }
    for (const row of next.locations) {
      const previous = before.locations.find(item => item.key === row.key);
      if (same(previous, row)) continue;
      await db.query('INSERT INTO runtime_locations(location_key,category,label,x,y,z,angle,interior,virtual_world,radius,enabled,gps_enabled,model_id,sort_order,revision) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE category=VALUES(category),label=VALUES(label),x=VALUES(x),y=VALUES(y),z=VALUES(z),angle=VALUES(angle),interior=VALUES(interior),virtual_world=VALUES(virtual_world),radius=VALUES(radius),enabled=VALUES(enabled),gps_enabled=VALUES(gps_enabled),model_id=VALUES(model_id),sort_order=VALUES(sort_order),revision=VALUES(revision)', [row.key,row.category,row.label,row.x,row.y,row.z,row.angle,row.interior,row.world,row.radius,Number(row.enabled),Number(row.gpsEnabled),row.modelId,row.sortOrder,revision]);
      const [stored] = await db.query('SELECT location_id FROM runtime_locations WHERE location_key=?', [row.key]);
      await db.query('DELETE FROM runtime_location_vertices WHERE location_id=?', [stored.location_id]);
      for (let i=0; i<row.vertices.length; i++) await db.query('INSERT INTO runtime_location_vertices(location_id,vertex_index,x,y) VALUES(?,?,?,?)', [stored.location_id,i,row.vertices[i].x,row.vertices[i].y]);
    }
    for (const row of before.locations) if (!next.locations.some(item => item.key === row.key)) await db.query('DELETE FROM runtime_locations WHERE location_key=?', [row.key]);
    if (!same(before.models, next.models)) {
      await db.query('DELETE FROM runtime_vehicle_models');
      for (const row of next.models) await db.query('INSERT INTO runtime_vehicle_models(model_id,cargo_slots,catalogue_price,enabled,revision) VALUES(?,?,?,?,?)', [row.modelId,row.cargoSlots,row.price,Number(row.enabled),revision]);
    }
    if (!same(before.squads, next.squads)) {
      const removed = before.squads.filter(row => !next.squads.some(item => item.id === row.id && item.factionId === row.factionId && item.enabled));
      for (const row of removed) {
        const [members] = await db.query('SELECT COUNT(*) AS total FROM characters WHERE player_factionid=? AND (player_factionsquad=? OR player_factionsquad2=? OR player_factionsquad3=?)', [row.factionId,row.id,row.id,row.id]);
        const [references]=await db.query('SELECT (SELECT COUNT(*) FROM faction_armories WHERE faction_id=? AND armory_squad=?)+(SELECT COUNT(*) FROM faction_armory_weapons WHERE faction_id=? AND squad_id=?)+(SELECT COUNT(*) FROM faction_skins WHERE faction_skin_factionid=? AND faction_skin_squad=?) AS total',[row.factionId,row.id,row.factionId,row.id,row.factionId,row.id]);
        if(Number(references.total)) throw new ConfigurationError('Squad '+row.name+' is referenced by lockers, equipment or uniforms. Reassign those restrictions first.');
        if (Number(members.total)) throw new ConfigurationError(`Squad ${row.name} still has assigned members. Reassign them before removing or disabling it.`);
      }
      await db.query('DELETE FROM runtime_faction_squads');
      for (const row of next.squads) await db.query('INSERT INTO runtime_faction_squads(squad_id,faction_id,squad_name,role_flags,enabled,revision) VALUES(?,?,?,?,?,?)', [row.id,row.factionId,row.name,row.roles,Number(row.enabled),revision]);
    }
    const entities=await applyEntityChanges(db,patch.entities??[],revision);
    if(entities.before.length) { prior.entities=entities.before; next.entities=entities.after; }
    await db.query('INSERT INTO runtime_config_audit(revision,account_id,account_name,source,description,before_json,after_json,created_at) VALUES(?,?,?,?,?,?,?,?)', [revision,actor.id,actor.name,actor.source,String(patch.description || 'Updated server configuration').slice(0,256),JSON.stringify(prior),JSON.stringify(next),Math.floor(Date.now()/1000)]);
    await db.query('UPDATE runtime_config_state SET revision=?,last_error=? WHERE id=1', [revision,'']);
    await db.commit();
    return { revision, changed: true };
  } catch (error) { await db.rollback(); throw error; }
}

// Triggered legacy writes take row locks before the revision lock. A bounded
// deadlock retry reruns the whole transaction and rechecks the expected revision.
export async function saveConfiguration(db,patch,actor) {
  for(let attempt=0;attempt<3;attempt++) {
    try{return await saveConfigurationOnce(db,patch,actor)}
    catch(error){
      if(error.errno!==1213 && error.sqlState!=='40001') throw error;
      if(attempt===2) throw new ConfigurationError('A concurrent database writer prevented the save. Reload and retry.','conflict');
    }
  }
  throw new ConfigurationError('Configuration save did not complete.');
}

// Restoring creates a new audited revision; it never rewinds the change counter.
export async function restoreConfiguration(db, revision, expectedRevision, actor) {
  if (!Number.isInteger(revision) || revision < 1) throw new ConfigurationError('Invalid history revision.');
  const [row] = await db.query('SELECT before_json FROM runtime_config_audit WHERE revision=?', [revision]);
  if (!row) throw new ConfigurationError('History entry does not exist.');
  const snapshot = typeof row.before_json === 'string' ? JSON.parse(row.before_json) : row.before_json;
  return saveConfiguration(db, { ...snapshot, expectedRevision, description: `Restored configuration before revision ${revision}` }, actor);
}
