// Public, typed configuration definitions shared by server-side editors and the
// Pawn generator. Never put secrets, arbitrary SQL or executable expressions here.
const integer = (key, group, label, value, min, max, extra = {}) => ({ key, group, label, type: 'integer', default: value, min, max, ...extra });
const number = (key, group, label, value, min, max, extra = {}) => ({ key, group, label, type: 'number', default: value, min, max, ...extra });
const text = (key, group, label, value, maxLength = 128) => ({ key, group, label, type: 'text', default: value, maxLength });

// Pawn identifiers are limited to 31 characters. Persistent keys stay readable.
export function pawnId(key) {
  let value = 'RT_' + key.replace(/[^a-z0-9]+/gi, '_').toUpperCase();
  if (value.length > 31) value = value.replaceAll('VEHICLES','VEH').replaceAll('PROPERTIES','PROP').replaceAll('COOLDOWN','CD').replaceAll('SECONDS','SEC').replaceAll('PERCENT','PCT');
  if (value.length > 31) throw new Error('Choose a shorter Pawn identifier for ' + key);
  return value;
}

export const settings = [
  integer('dmv.fee', 'services', 'Driving licence test fee', 250, 0, 1000000, { macro: 'SERVER_DMV_FEE' }),
  integer('vehicles.rental_fee', 'vehicles', 'Vehicle rental fee', 125, 0, 1000000, { macro: 'SERVER_VEH_RENT_FEE' }),
  integer('licenses.pilot_fee', 'services', 'Pilot licence fee', 1500, 0, 10000000, { macro: 'SERVER_PILOT_FEE' }),
  integer('vehicles.impound_fee', 'vehicles', 'Impound release fee', 2500, 0, 10000000, { macro: 'IMPOUND_FEE' }),
  integer('identity.namechange_fee', 'services', 'Name change fee', 15000, 0, 10000000, { macro: 'NAMECHANGE_COST' }),
  integer('firms.creation_fee', 'economy', 'Firm creation base fee', 50000, 0, 100000000, { macro: 'FIRM_CREATE_BASE_FEE' }),
  integer('firms.mechanic_fee', 'economy', 'mechanic firm registration surcharge', 15000, 0, 100000000),
  integer('firms.security_fee', 'economy', 'security firm registration surcharge', 25000, 0, 100000000),
  integer('firms.lawyer_fee', 'economy', 'lawyer firm registration surcharge', 10000, 0, 100000000),
  integer('firms.transit_fee', 'economy', 'transit firm registration surcharge', 20000, 0, 100000000),
  integer('firms.logistics_fee', 'economy', 'logistics firm registration surcharge', 20000, 0, 100000000),
  integer('firms.media_fee', 'economy', 'media firm registration surcharge', 0, 0, 100000000),
  integer('firms.usedcars_fee', 'economy', 'usedcars firm registration surcharge', 35000, 0, 100000000),
  integer('firms.realestate_fee', 'economy', 'realestate firm registration surcharge', 35000, 0, 100000000),
  integer('firms.member_slots', 'economy', 'New firm member slots (including owner)', 10, 1, 100),
  integer('firms.vehicle_slots', 'economy', 'New firm vehicle slots', 15, 0, 200),
  integer('paycheck.base', 'economy', 'Base paycheck', 300, 0, 10000000, { macro: 'SERVER_PAYCHECK' }),
  integer('paycheck.minimum_minutes', 'economy', 'Minutes required for paycheck', 40, 0, 1440, { macro: 'MIN_PAYCHECK_MINUTES' }),
  integer('paycheck.interval_minutes', 'economy', 'Paycheck interval in minutes', 60, 1, 1440, { macro: 'PAYCHECK_INTERVAL', policy: 'reschedule' }),
  integer('tolls.base_fee', 'vehicles', 'Base toll fee', 150, 0, 1000000, { macro: 'SERVER_TOLL_FEE' }),
  integer('tolls.cargo_slot_fee', 'vehicles', 'Toll fee per cargo slot', 10, 0, 100000, { macro: 'TOLL_FEE_PER_SLOT' }),
  integer('medical.surgery_fee', 'medical', 'Surgery base fee', 50, 0, 1000000, { macro: 'SURGERY_FEE' }),
  integer('medical.bandage_fee', 'medical', 'Bandage fee', 15, 0, 1000000, { macro: 'BANDAGE_FEE' }),
  number('medical.bill_percent', 'medical', 'Hospital bill percentage of net worth', 1, 0, 100),
  integer('medical.bill_min', 'medical', 'Minimum hospital bill', 250, 0, 10000000),
  integer('medical.bill_max', 'medical', 'Maximum hospital bill', 2500, 0, 10000000),
  integer('repairs.bodykit_fee', 'vehicles', 'Bodykit repair fee', 150, 0, 1000000, { macro: 'PNS_BODYKIT_COST' }),
  integer('repairs.engine_fee', 'vehicles', 'Engine repair base fee', 200, 0, 1000000, { macro: 'PNS_ENGINE_COST' }),
  integer('repairs.bodywork_min', 'vehicles', 'Minimum bodywork fee', 1000, 0, 10000000, { macro: 'PNS_BODYWORK_MIN_COST' }),
  integer('repairs.bodywork_percent', 'vehicles', 'Bodywork percentage of vehicle value', 5, 0, 100, { macro: 'PNS_BODYWORK_PERCENT' }),
  integer('repairs.engine_min', 'vehicles', 'Minimum engine repair fee', 1500, 0, 10000000, { macro: 'PNS_ENGINE_MIN_COST' }),
  integer('repairs.modshop_fee', 'vehicles', 'Modshop fee', 25, 0, 1000000, { macro: 'MODSHOP_FEE' }),
  integer('properties.wardrobe_fee', 'properties', 'Wardrobe installation fee', 750, 0, 1000000, { macro: 'WARDROBE_COST' }),
  integer('vehicles.wholesale_percent', 'vehicles', 'Dealership wholesale percentage', 70, 0, 100, { macro: 'DEALER_WHOLESALE_PCT' }),
  integer('vehicles.used_sale_min_percent', 'vehicles', 'Used vehicle minimum resale percentage', 30, 0, 1000, { macro: 'USEDCARS_SALE_MIN_PCT' }),
  integer('vehicles.used_sale_max_percent', 'vehicles', 'Used vehicle maximum resale percentage', 100, 0, 1000, { macro: 'USEDCARS_SALE_MAX_PCT' }),
  integer('vehicles.used_alert_percent', 'vehicles', 'Used vehicle staff alert percentage', 100, 0, 1000, { macro: 'USEDCARS_ALERT_PCT' }),
  integer('firms.lawyer_minute_rate', 'economy', 'Minimum lawyer rate per minute', 100, 0, 1000000, { macro: 'LAWYER_MIN_RATE_PER_MINUTE' }),
  integer('properties.resale_min_percent', 'properties', 'Minimum firm property resale percentage', 100, 0, 1000, { macro: 'PROPERTY_RESALE_MIN_PCT' }),
  integer('fuel.station_purchase_fee', 'vehicles', 'Fuel station purchase price', 250000, 0, 100000000, { macro: 'FUEL_STATION_COST' }),
  integer('trucker.crate_pay', 'jobs', 'Delivery pay per crate', 40, 0, 1000000, { macro: 'TRUCKER_PAY_PER_CRATE', policy: 'new-job' }),
  number('trucker.distance_pay', 'jobs', 'Delivery pay per crate per map unit', 0.03, 0, 1000, { macro: 'TRUCKER_PAY_PER_YARD', policy: 'new-job' }),
  number('trucker.load_range', 'jobs', 'Depot vehicle acceptance range', 15, 1, 100, { macro: 'TRUCKER_LOAD_RANGE' }),
  number('trucker.pile_range', 'jobs', 'Crate pile interaction range', 4, 0.5, 30, { macro: 'TRUCKER_PILE_RANGE' }),
  number('trucker.rear_range', 'jobs', 'Cargo vehicle rear interaction range', 3, 0.5, 30, { macro: 'TRUCKER_REAR_RANGE' }),
  number('trucker.drop_range', 'jobs', 'Business drop-off interaction range', 6, 0.5, 50, { macro: 'TRUCKER_DROP_RANGE' }),
  number('trucker.unload_range', 'jobs', 'Maximum vehicle distance from delivery', 30, 1, 150, { macro: 'TRUCKER_UNLOAD_RANGE' }),
  number('trucker.minimum_distance', 'jobs', 'Minimum delivery destination distance', 300, 0, 20000, { macro: 'TRUCKER_MIN_DISTANCE', policy: 'new-job' }),
  number('trucker.checkpoint_size', 'jobs', 'Delivery checkpoint radius', 6, 0.5, 30, { macro: 'TRUCKER_CHECKPOINT_SIZE' }),
  integer('pizza.deliveries', 'jobs', 'Stops per pizza route', 5, 1, 20, { macro: 'PIZZA_DELIVERIES', policy: 'new-job', structuralMacro: true }),
  integer('pizza.pay_min', 'jobs', 'Minimum pizza payment', 120, 0, 1000000, { macro: 'PIZZA_PAY_MIN', policy: 'new-job' }),
  integer('pizza.pay_max', 'jobs', 'Maximum pizza payment', 200, 0, 1000000, { macro: 'PIZZA_PAY_MAX', policy: 'new-job' }),
  integer('pizza.bonus', 'jobs', 'Pizza route completion bonus', 350, 0, 1000000, { macro: 'PIZZA_BONUS_PAY', policy: 'new-job' }),
  number('pizza.vehicle_range', 'jobs', 'Pizza vehicle interaction range', 4, 0.5, 30, { macro: 'PIZZA_VEHICLE_RANGE' }),
  number('pizza.checkpoint_size', 'jobs', 'Pizza checkpoint radius', 3, 0.5, 30, { macro: 'PIZZA_CHECKPOINT_SIZE' }),
  number('pizza.min_x', 'jobs', 'Pizza coverage minimum X', -1213.91, -20000, 20000, { macro: 'PIZZA_AREA_MIN_X', policy: 'new-job' }),
  number('pizza.min_y', 'jobs', 'Pizza coverage minimum Y', -768.027, -20000, 20000, { macro: 'PIZZA_AREA_MIN_Y', policy: 'new-job' }),
  number('pizza.max_x', 'jobs', 'Pizza coverage maximum X', 2997.06, -20000, 20000, { macro: 'PIZZA_AREA_MAX_X', policy: 'new-job' }),
  number('pizza.max_y', 'jobs', 'Pizza coverage maximum Y', 596.349, -20000, 20000, { macro: 'PIZZA_AREA_MAX_Y', policy: 'new-job' }),
  integer('burglary.cooldown_seconds', 'properties', 'Burglary cooldown in seconds', 900, 0, 86400, { macro: 'BURGLARY_COOLDOWN' }),
  integer('properties.entry_cooldown_seconds', 'properties', 'Property entry cooldown in seconds', 1800, 0, 86400, { macro: 'PROPERTY_ENTRY_COOLDOWN' }),
  integer('police.breathalyzer_cooldown', 'police', 'Breathalyzer cooldown in seconds', 120, 0, 86400, { macro: 'BREATHALYZER_COOLDOWN' }),
  integer('police.metal_cooldown_ms', 'police', 'Metal detector cooldown in milliseconds', 5000, 100, 3600000, { macro: 'METAL_COOLDOWN_MS' }),
  integer('voice.line_cooldown_seconds', 'communication', 'Voiceline cooldown in seconds', 10, 0, 3600, { macro: 'VOICELINE_COOLDOWN_TIME' }),
  text('identity.name', 'identity', 'Server display name', 'OpenRP Framework'),
  text('identity.mode', 'identity', 'Server browser game mode', 'OpenRP Framework v0.1.0', 64),
  text('identity.map', 'identity', 'Server browser map name', 'San Andreas', 64),
  text('identity.website', 'identity', 'Public website', 'https://example.com', 192),
  integer('weather.automatic', 'environment', 'Automatic seasonal weather', 1, 0, 1),
  integer('weather.fixed_id', 'environment', 'Fixed weather ID', 10, 0, 20),
];

export const locationCategories = ['service', 'spawn', 'prison_cell', 'garbage', 'fishing', 'garage', 'gym_machine', 'gps'];
const location = (key, label, extra = {}) => ({ key, label, category: 'service', x: 0, y: 0, z: 0, angle: 0, interior: 0, world: 0, radius: 5, enabled: false, ...extra });
export const locations = [
  location('dmv', 'Department of Motor Vehicles', { pickup: 1581, gps: true }),
  location('admin_jail', 'Admin jail', { interior: 6, world: 1000 }),
  location('staff_room', 'Staff meeting room', { interior: 6, world: 1001 }),
  location('prison_release', 'Prison release'),
  location('sapd_desk', 'Police Department', { pickup: 1247, gps: true }),
  location('administration_desk', 'Administration Building', { pickup: 1239, gps: true }),
  location('hospital', 'Hospital', { gps: true }),
  location('trucker_depot', 'Delivery Depot', { gps: true, radius: 15 }),
  location('garbage_depot', 'Garbage Depot', { gps: true }),
  location('scrapyard_land', 'Car Scrapyard', { gps: true }),
  location('scrapyard_boat', 'Boat Scrapyard', { gps: true }),
  location('scrapyard_air', 'Plane Scrapyard', { gps: true }),
  location('chopshop', 'Chop Shop', { gps: true }),
  location('advert_agency', 'Advertisement Agency', { gps: true, pickup: 19807 }),
  location('impound', 'Vehicle Impound', { x: 1070.2982, y: -1762.1105, z: 13.3904, radius: 30, enabled: true, pickup: 1247, gps: true }),
  location('gym_ls', 'East Los Santos Gym', { z: -30, gps: true }),
  location('gym_sf', 'San Fierro Gym', { z: -30, gps: true }),
  location('gym_lv', 'Las Venturas Gym', { z: -30, gps: true }),
  location('gym_ganton', 'Ganton Gym', { z: -30, gps: true }),
  location('gym_beach', 'Beach Gym', { z: -30, gps: true }),
  location('public_spawn', 'Public spawn', { category: 'spawn' }),
  ...[1, 2, 3, 4].map(n => location('prison_cell_' + n, 'C0' + n, { category: 'prison_cell', world: 1 })),
  ...[1, 2, 3].map(n => location('garage_' + n, 'Garage ' + n, { category: 'garage', gps: true })),
];

export const cargoModels = { 413: 8, 414: 12, 456: 16, 499: 14, 498: 10, 609: 10, 440: 8, 482: 6, 435: 30, 450: 30, 584: 30, 591: 30 };
export const squads = [
  { id: 10, factionId: 1, name: 'SWAT', roles: 1 },
  { id: 11, factionId: 1, name: 'Traffic', roles: 0 },
  { id: 12, factionId: 1, name: 'Detectives', roles: 2 },
  { id: 20, factionId: 2, name: 'Fire', roles: 0 },
  { id: 21, factionId: 2, name: 'EMS', roles: 0 },
  { id: 22, factionId: 2, name: 'Rescue', roles: 0 },
];
