/**
 * Single source of truth for ORP domain constants — staff levels, faction
 * types, 911 call types, vehicle model classes, etc. These mirror the in-game
 * gamemode's numeric codes; they are NOT stored differently in the DB, so
 * centralising them here changes no data, only removes scattered magic numbers.
 */

/* ── Staff levels (account_stafflevel) ─────────────────────────────
 * These MUST mirror the gamemode/PHP source of truth (ucp/includes/config.php).
 * Getting them wrong silently mis-gates the whole ACP, so they are exact. */
export const ADMIN_LVL = {
  NONE: 0,
  BETA: 1,
  JUNIOR: 2,
  GENERAL: 3,
  SENIOR: 4,
  LEAD: 5,
  HEAD: 6,
  MANAGER: 7,
  DEVELOPER: 8,
} as const;

/** Human-readable rank title for a staff level (matches PHP staff_level_title). */
export const STAFF_LEVEL_TITLE: Record<number, string> = {
  [ADMIN_LVL.BETA]: "Beta Tester",
  [ADMIN_LVL.JUNIOR]: "Junior Admin",
  [ADMIN_LVL.GENERAL]: "General Admin",
  [ADMIN_LVL.SENIOR]: "Senior Admin",
  [ADMIN_LVL.LEAD]: "Lead Admin",
  [ADMIN_LVL.HEAD]: "Head Admin",
  [ADMIN_LVL.MANAGER]: "Manager",
  [ADMIN_LVL.DEVELOPER]: "Developer",
};

export const staffLevelTitle = (level: number): string =>
  STAFF_LEVEL_TITLE[level] ?? "None";

/* ── Faction types (factions.faction_type) ───────────────────────── */
export const FACTION_TYPE_ID = {
  LEO: 0,          // all law-enforcement agencies share this type
  ILLEGAL: 1,
  LEGAL: 2,
  EMS: 3,
  NEWS: 4,
  TRUCKER: 5,
  GOV: 6,
  SECURITY: 7,
  FEDERAL: 10,
} as const;

/** Faction SQL ids for the core factions - used where something is specific to
 *  one agency rather than the shared LEO type (theme, logo, name). */
export const FACTION_ID = {
  SAPD: 1,
  FDSA: 2,
} as const;

/** Law-enforcement faction types treated as emergency services. */
export const LEA_FACTION_TYPES: readonly number[] = [
  FACTION_TYPE_ID.LEO,
  FACTION_TYPE_ID.EMS,
];

export const isLeaFaction = (factionType: number) =>
  LEA_FACTION_TYPES.includes(factionType);
export const isGangFaction = (factionType: number) =>
  factionType === FACTION_TYPE_ID.ILLEGAL;
export const isGovFaction = (factionType: number) =>
  factionType === FACTION_TYPE_ID.GOV;

export const FACTION_TYPE_LABEL: Record<number, string> = {
  [FACTION_TYPE_ID.LEO]: "Law Enforcement",
  [FACTION_TYPE_ID.ILLEGAL]: "Gang",
  [FACTION_TYPE_ID.LEGAL]: "Legal",
  [FACTION_TYPE_ID.EMS]: "Fire / EMS",
  [FACTION_TYPE_ID.NEWS]: "News",
  [FACTION_TYPE_ID.TRUCKER]: "Trucker",
  [FACTION_TYPE_ID.GOV]: "Government",
  [FACTION_TYPE_ID.SECURITY]: "Security",
  [FACTION_TYPE_ID.FEDERAL]: "Federal",
};
export const factionTypeLabel = (t: number): string =>
  FACTION_TYPE_LABEL[t] ?? `Type ${t}`;

/* ── Faction tiers (player_factiontier) ──────────────────────────── */
export const FACTION_TIER_ID = {
  OWNER: 1,
  COMMAND: 2,
  MEMBER: 3,
  RECRUIT: 4,
} as const;

export const FACTION_TIER_NAME: Record<number, string> = {
  1: "Owner",
  2: "Command",
  3: "Member",
  4: "Restricted",
};
export const factionTierName = (t: number): string =>
  FACTION_TIER_NAME[t] ?? `Tier ${t}`;

// Squad data is loaded by runtime-squads.ts; UI-only option formatting stays here.
/** Dropdown options for a faction's squads, [id, name]. A stored id that isn't in the list is kept so saving can't silently change it. */
export function squadOptions(
  map: Record<number, string>,
  current?: number,
): [number, string][] {
  const opts = Object.entries(map).map(([k, v]) => [Number(k), v] as [number, string]);
  if (current && !map[current]) opts.push([current, `Unknown squad ${current}`]);
  return opts;
}
/* ── 911 call types (call_type) ────────────────────── */
export const CALL_TYPE = {
  POLICE: 1,
  MEDICAL: 2,
  ROBBERY: 3,
  BURGLARY: 4,
} as const;

export const CALL_TYPE_LABEL: Record<number, string> = {
  [CALL_TYPE.POLICE]: "Police",
  [CALL_TYPE.MEDICAL]: "Medical",
  [CALL_TYPE.ROBBERY]: "Robbery",
  [CALL_TYPE.BURGLARY]: "Burglary",
};

export const CALL_TYPE_COLOR: Record<number, string> = {
  [CALL_TYPE.POLICE]: "#3b82f6",
  [CALL_TYPE.MEDICAL]: "#ef4444",
  [CALL_TYPE.ROBBERY]: "#a855f7",
  [CALL_TYPE.BURGLARY]: "#49ba47",
};

export const callLabel = (t: number) => CALL_TYPE_LABEL[t] ?? "Unknown";
export const callColor = (t: number) => CALL_TYPE_COLOR[t] ?? "#9ca3af";

/* ── Vehicle model classes ───────────────────────────────────────── */
/** SA-MP model IDs rendered as a helicopter icon on the dispatch map.
 *  Currently just the Police Maverick (497) to preserve existing behaviour. */
export const HELICOPTER_MODELS: ReadonlySet<number> = new Set([497]);
export const isHelicopter = (modelId: number) => HELICOPTER_MODELS.has(modelId);

/* ── Vehicle ownership types (vehicles.vehicle_type) ─────────────── */
export const VEHICLE_OWNER_TYPE = {
  PLAYER: 3,
  FACTION: 4,
} as const;

/* ── Character limits ────────────────────────────────────────────── */
export const MAX_CHARACTERS_PER_ACCOUNT = 5;

/* ── Faction types that support divisions (kept for reference) ───── */
export const DIVISION_FACTION_TYPES: readonly number[] = [
  0, 2, 4, 6, 7, 8, 9, 10,
];
