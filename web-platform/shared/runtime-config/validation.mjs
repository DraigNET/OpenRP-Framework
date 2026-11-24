// Pure validation: usable by ACP, a future desktop process and Node tests.
import { settings as catalogue, locations as coreLocations, locationCategories } from './catalog.mjs';
export const MAX_LOCATIONS = 512;
export const MAX_SQUADS = 127;
export class ConfigurationError extends Error {
  constructor(message, code = 'invalid') { super(message); this.name = 'ConfigurationError'; this.code = code; }
}
const fail = message => { throw new ConfigurationError(message); };
function numeric(value, name, min, max, integer = false) {
  if (value === '' || value === null || typeof value === 'boolean' || !['number', 'string'].includes(typeof value)) fail(`${name}: enter a number.`);
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < min || parsed > max || (integer && !Number.isInteger(parsed))) fail(`${name}: use ${integer ? 'an integer' : 'a number'} from ${min} to ${max}.`);
  return Object.is(parsed, -0) ? 0 : parsed;
}
function label(value, name, max) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max || /[\u0000-\u001f\u007f<>]/.test(value)) fail(`${name}: enter 1–${max} plain-text characters.`);
  return value.trim();
}
const bool = value => {
  if (![true, false, 0, 1].includes(value)) fail('Enabled and visibility fields must be boolean.');
  return value === true || value === 1;
};

export function validateSettings(input) {
  if (!input || Array.isArray(input) || typeof input !== 'object') fail('Settings must be an object.');
  const result = {};
  for (const [key, value] of Object.entries(input)) {
    const definition = catalogue.find(item => item.key === key);
    if (!definition) fail(`Unknown setting: ${key}`);
    result[key] = definition.type === 'text' ? label(value, definition.label, definition.maxLength) : numeric(value, definition.label, definition.min, definition.max, definition.type === 'integer');
  }
  return result;
}

export function validateLocation(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) fail('Invalid location.');
  const key = label(input.key, 'Location key', 64);
  if (!/^[a-z][a-z0-9_]*$/.test(key)) fail('Location keys use lowercase letters, numbers and underscores.');
  if (!locationCategories.includes(input.category)) fail('Unknown location category.');
  const core = coreLocations.find(item => item.key === key);
  if (core && core.category !== input.category) fail(`The category of ${key} cannot be changed.`);
  const result = {
    key, category: input.category, label: label(input.label, 'Location name', 64),
    x: numeric(input.x, 'X', -20000, 20000), y: numeric(input.y, 'Y', -20000, 20000), z: numeric(input.z, 'Z', -20000, 20000),
    angle: numeric(input.angle, 'Facing angle', 0, 360), interior: numeric(input.interior, 'Interior', 0, 255, true),
    world: numeric(input.world, 'Virtual world', 0, 2147483000, true), radius: numeric(input.radius, 'Radius', 0.2, 1000),
    enabled: bool(input.enabled), gpsEnabled: bool(input.gpsEnabled),
    modelId: numeric(input.modelId ?? 0, 'Stock model', 0, 19999, true), sortOrder: numeric(input.sortOrder ?? 0, 'Sort order', -10000, 10000, true),
    vertices: [],
  };
  if(input.category==='prison_cell' && !/^[A-Za-z0-9]{1,3}$/.test(result.label)) fail('Prison cell names are unique 1-3 character codes, such as C01.');
  if (input.category === 'fishing') {
    if (!Array.isArray(input.vertices) || input.vertices.length < 3 || input.vertices.length > 32) fail('Fishing areas need 3–32 polygon vertices.');
    result.vertices = input.vertices.map(point => ({ x: numeric(point.x, 'Vertex X', -20000, 20000), y: numeric(point.y, 'Vertex Y', -20000, 20000) }));
    let area = 0;
    for (let i = 0; i < result.vertices.length; i++) {
      const a = result.vertices[i], b = result.vertices[(i + 1) % result.vertices.length];
      if (a.x === b.x && a.y === b.y) fail('A polygon cannot have consecutive identical vertices.');
      area += a.x * b.y - b.x * a.y;
    }
    if (Math.abs(area) < 0.01) fail('Fishing polygon must have nonzero area.');
    const turn = (a,b,c) => (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
    for (let i=0; i<result.vertices.length; i++) for (let j=i+1; j<result.vertices.length; j++) {
      const n=result.vertices.length;
      if (j===i+1 || (i===0 && j===n-1)) continue;
      const a=result.vertices[i],b=result.vertices[(i+1)%n],c=result.vertices[j],d=result.vertices[(j+1)%n];
      if (turn(a,b,c)*turn(a,b,d)<=0 && turn(c,d,a)*turn(c,d,b)<=0 && Math.max(Math.min(a.x,b.x),Math.min(c.x,d.x))<=Math.min(Math.max(a.x,b.x),Math.max(c.x,d.x)) && Math.max(Math.min(a.y,b.y),Math.min(c.y,d.y))<=Math.min(Math.max(a.y,b.y),Math.max(c.y,d.y))) fail('Fishing polygon edges must not cross or overlap.');
    }
  }
  return result;
}

export function validateModels(input) {
  if (!Array.isArray(input) || input.length > 212) fail('Vehicle model configuration exceeds its limit.');
  const ids = new Set();
  return input.map(row => {
    const modelId = numeric(row.modelId, 'Vehicle model', 400, 611, true);
    if (ids.has(modelId)) fail('A vehicle model appears more than once.');
    ids.add(modelId);
    return { modelId, cargoSlots: numeric(row.cargoSlots, 'Cargo slots', 0, 64, true), price: row.price === null || row.price === '' || row.price === undefined ? null : numeric(row.price, 'Catalogue price', 0, 100000000, true), enabled: bool(row.enabled) };
  });
}

export function validateSquads(input) {
  if (!Array.isArray(input) || input.length > MAX_SQUADS) fail('Too many squads.');
  const ids = new Set();
  return input.map(row => {
    const id = numeric(row.id, 'Squad ID', 1, 127, true);
    if (ids.has(id)) fail('Squad IDs must be unique across factions.');
    ids.add(id);
    return { id, factionId: numeric(row.factionId, 'Faction ID', 1, 2147483000, true), name: label(row.name, 'Squad name', 23), roles: numeric(row.roles, 'Squad roles', 0, 3, true), enabled: bool(row.enabled) };
  });
}

export function validateConfiguration(snapshot) {
  const settings = validateSettings(snapshot.settings);
  for (const definition of catalogue) if (!Object.hasOwn(settings, definition.key)) fail(`Missing setting: ${definition.key}`);
  if (!Array.isArray(snapshot.locations) || snapshot.locations.length > MAX_LOCATIONS) fail('Too many locations.');
  const locations = snapshot.locations.map(validateLocation), keys = new Set();
  for (const row of locations) { if (keys.has(row.key)) fail('Location keys must be unique.'); keys.add(row.key); }
  for (const core of coreLocations) if (!keys.has(core.key)) fail(`Core location ${core.key} must remain; disable it instead of deleting it.`);
  const cells=locations.filter(row=>row.category==='prison_cell').map(row=>row.label.toUpperCase());
  if(new Set(cells).size!==cells.length) fail('Prison cell codes must be unique.');
  const limits = { spawn: 64, prison_cell: 64, garbage: 256, fishing: 32, garage: 64, gym_machine: 128, gps: 128 };
  for (const [category, limit] of Object.entries(limits)) if (locations.filter(row => row.category === category).length > limit) fail(`At most ${limit} ${category} locations are supported.`);
  if (locations.filter(row=>row.enabled && row.gpsEnabled && row.interior===0 && row.world===0).length>232) fail('At most 232 outdoor GPS destinations are supported; 24 slots are reserved for dealerships.');
  for (const [min, max] of [['pizza.pay_min', 'pizza.pay_max'], ['medical.bill_min', 'medical.bill_max'], ['vehicles.used_sale_min_percent', 'vehicles.used_sale_max_percent'], ['pizza.min_x', 'pizza.max_x'], ['pizza.min_y', 'pizza.max_y']]) if (settings[min] > settings[max]) fail(`${min} must not exceed ${max}.`);
  if (settings['paycheck.minimum_minutes'] > settings['paycheck.interval_minutes']) fail('Required paycheck minutes cannot exceed its interval.');
  return { settings, locations, models: validateModels(snapshot.models), squads: validateSquads(snapshot.squads) };
}
