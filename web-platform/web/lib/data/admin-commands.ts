import { ADMIN_LVL } from "@/lib/constants";

/**
 * ACP command reference — every in-game staff command, grouped by the rank
 * that unlocks it. Higher ranks inherit everything below them, so each tier
 * lists only the commands *introduced* at that rank.
 *
 * Transcribed by hand from the gamemode. The gate for each
 * command is the first hard permission check in its body, NOT the in-game
 * /staffhelp lists, which are out of date in places. Only commands that are
 * actually #included are listed (the Emmet admin commands, dock entities,
 * hitman, event commands, etc. are compiled out and deliberately omitted).
 *
 * To keep this honest when the gamemode changes: re-check the command's
 * `GetPlayerAdminLevel(playerid) < ADMIN_LVL_*` line and move it between tiers.
 */

export type AdminCategory =
  | "Moderation"
  | "Teleport"
  | "Lookup"
  | "Chat & Duty"
  | "Player"
  | "Vehicle"
  | "Property"
  | "Faction"
  | "World"
  | "Minigames"
  | "Economy"
  | "Server"
  | "Staff"
  | "Testing";

export const ADMIN_CATEGORIES: AdminCategory[] = [
  "Moderation",
  "Teleport",
  "Lookup",
  "Chat & Duty",
  "Player",
  "Vehicle",
  "Property",
  "Faction",
  "World",
  "Minigames",
  "Economy",
  "Server",
  "Staff",
  "Testing",
];

export interface AdminCommand {
  name: string;
  /** Arguments after the command name, e.g. "[player] [minutes] [reason]". */
  usage?: string;
  aliases?: string[];
  desc: string;
  cat: AdminCategory;
  /** Extra caveat shown under the description (who else can use it, quirks). */
  note?: string;
  /** Gate in the code is Beta Tester, one rank below Junior. */
  beta?: boolean;
}

export interface AdminTier {
  id: string;
  level: number;
  blurb: string;
  commands: AdminCommand[];
}

const c = (
  name: string,
  usage: string,
  desc: string,
  cat: AdminCategory,
  extra: { aliases?: string[]; note?: string; beta?: boolean } = {},
): AdminCommand => ({ name, usage: usage || undefined, desc, cat, ...extra });

/* ── Junior ───────────────────────────────────────────────────────── */
const JUNIOR: AdminCommand[] = [
  // Punishments
  c(
    "kick",
    "[player] [reason]",
    "Kick a player from the server.",
    "Moderation",
    { note: "Also usable by Supporters rank 3+." },
  ),
  c(
    "ban",
    "[player] [hours] [reason]",
    "Ban an online player's account. 0 hours is permanent; temporary bans max out at 720 hours (4 weeks).",
    "Moderation",
  ),
  c(
    "unban",
    "[master account]",
    "Lift a ban by master account name.",
    "Moderation",
  ),
  c(
    "banip",
    "[ip] [hours] [reason]",
    "Ban an IP address. Refuses if that IP is connected right now, so use /ban for online players.",
    "Moderation",
  ),
  c("unbanip", "[ip]", "Remove an IP ban.", "Moderation"),
  c(
    "banlist",
    "",
    "Open the list of every active ban with account, IP, admin, reason and length.",
    "Moderation",
  ),
  c(
    "ajail",
    "[player] [minutes] [reason]",
    "Send an online player to admin jail. Minimum 5 minutes.",
    "Moderation",
  ),
  c(
    "unajail",
    "[player]",
    "Release a player from admin jail early.",
    "Moderation",
  ),
  c(
    "offlineajail",
    "[firstname_lastname] [minutes] [reason]",
    "Admin-jail a character who is offline. The sentence applies when they next log in. Minimum 10 minutes.",
    "Moderation",
  ),
  c(
    "warn",
    "[player] [reason]",
    "Issue an admin warning to a player. You cannot warn an admin of equal or higher rank.",
    "Moderation",
  ),
  c(
    "owarn",
    "[account name] [reason]",
    "Warn an account that is offline.",
    "Moderation",
  ),
  c("slap", "[player]", "Slap a player into the air.", "Moderation"),
  c("freeze", "[player]", "Freeze a player in place.", "Moderation"),
  c("unfreeze", "[player]", "Unfreeze a player.", "Moderation"),
  c(
    "setnote",
    "[player] [note]",
    "Attach an admin note to a player. Five notes maximum per player.",
    "Moderation",
  ),
  c(
    "notes",
    "[player]",
    "Read the admin notes on an online player.",
    "Moderation",
  ),
  c(
    "onotes",
    "[account id]",
    "Read the admin notes on an offline account. Find the ID with /getma or /getc.",
    "Moderation",
  ),
  c(
    "adminrecord",
    "[player]",
    "Show a player's admin record: kicks, jails, bans and warnings.",
    "Moderation",
    {
      note: "Players can use it on themselves; targeting someone else needs Junior.",
    },
  ),
  c(
    "punishlist",
    "",
    "Show the standard punishment guide: which rule breaks are kicks, and the jail length for each.",
    "Moderation",
  ),
  c(
    "forcenamechange",
    "[player] [character|account] [reason]",
    "Force a player to change their character or account name.",
    "Moderation",
    { aliases: ["forcenc"] },
  ),
  c(
    "resetemail",
    "[player]",
    "Force a player to re-enter a valid email address.",
    "Moderation",
  ),
  c(
    "clearinjuries",
    "[player]",
    "Clear a player's injuries and revive them.",
    "Moderation",
    { aliases: ["arevive"] },
  ),
  c(
    "clearinjuriesradius",
    "[radius 1-250]",
    "Clear the injuries of everyone within a radius of you.",
    "Moderation",
    { aliases: ["reviveradius"] },
  ),
  c(
    "toggleooc",
    "",
    "Turn global OOC chat on or off for the whole server.",
    "Moderation",
  ),

  // Reports and name changes
  c("reports", "", "List pending player reports.", "Chat & Duty"),
  c(
    "acceptreport",
    "[player]",
    "Accept a player's pending report.",
    "Chat & Duty",
    { aliases: ["ar"] },
  ),
  c(
    "denyreport",
    "[player] [reason]",
    "Deny a pending report. A reason is required.",
    "Chat & Duty",
    { aliases: ["dr"] },
  ),
  c(
    "answer",
    "[player] [answer]",
    "Answer a player's /question.",
    "Chat & Duty",
    { aliases: ["ans"] },
  ),
  c("namechanges", "", "List pending name change requests.", "Chat & Duty", {
    note: "Also usable by Supporters rank 2+.",
  }),
  c(
    "processnamechange",
    "[player] [accept|deny] [reason]",
    "Approve or deny a pending name change. The player pays a $15,000 fee on approval.",
    "Chat & Duty",
    { aliases: ["processnc"], note: "Also usable by Supporters rank 2+." },
  ),
  c(
    "togadmin",
    "[warnings|desync|chat]",
    "Toggle whether you receive admin warnings, desync logs, or the admin and helper chats.",
    "Chat & Duty",
  ),
  c(
    "acinvite",
    "[player]",
    "Add a player to the private admin conversation.",
    "Chat & Duty",
  ),
  c(
    "acuninvite",
    "[player]",
    "Remove a player from the admin conversation.",
    "Chat & Duty",
  ),
  c(
    "adminhelp",
    "",
    "List staff commands by rank (older format).",
    "Chat & Duty",
    { note: "Also usable by Helpers." },
  ),
  c(
    "adminrumour",
    "[text]",
    "Post a server-wide rumour as staff, with no charge or location requirement.",
    "Chat & Duty",
    { aliases: ["arumour"] },
  ),

  // Teleport and movement
  c(
    "goto",
    "[player]",
    "Teleport to a player. Not allowed while that admin is spectating someone.",
    "Teleport",
    { aliases: ["tp"] },
  ),
  c("gethere", "[player]", "Teleport a player to you.", "Teleport", {
    aliases: ["bring"],
  }),
  c(
    "fw",
    "[distance]",
    "Warp yourself forward. Negative goes backwards. Default 2.0.",
    "Teleport",
  ),
  c(
    "up",
    "[distance]",
    "Warp yourself up. Negative goes down. Default 2.0.",
    "Teleport",
  ),
  c(
    "dn",
    "[distance]",
    "Warp yourself down. Negative goes up. Default 2.0.",
    "Teleport",
  ),
  c("gotoadminroom", "", "Teleport to the admin meeting room.", "Teleport", {
    aliases: ["staffroom", "adminroom"],
  }),
  c("gotoajail", "", "Teleport to the admin jail.", "Teleport"),
  c("gotocar", "[car id]", "Teleport to a vehicle by ID.", "Teleport", {
    aliases: ["fcargoto", "fgotocar"],
  }),
  c(
    "factiongoto",
    "[faction id]",
    "Teleport to a faction's spawn point.",
    "Teleport",
    { aliases: ["fgoto"] },
  ),
  c(
    "gotojunkie",
    "[slot]",
    "Teleport to a drug-junkie spawn location by slot.",
    "Teleport",
  ),
  c("setint", "[player] [interior]", "Set a player's interior.", "Teleport", {
    aliases: ["setinterior"],
  }),
  c("setvw", "[player] [world]", "Set a player's virtual world.", "Teleport", {
    aliases: ["setvirtualworld"],
  }),
  c(
    "spectate",
    "[player|off]",
    "Spectate a player. Use /spectate off to stop.",
    "Teleport",
    { aliases: ["spec"] },
  ),

  // Lookups
  c(
    "getma",
    "[character name]",
    "Find the master account that owns a character.",
    "Lookup",
    { aliases: ["getmasteraccount"], beta: true },
  ),
  c(
    "getc",
    "[master account]",
    "List every character on a master account.",
    "Lookup",
    { aliases: ["getcharacters"], beta: true },
  ),
  c(
    "getnumber",
    "[phone number]",
    "Find which character owns a phone number, online or offline.",
    "Lookup",
  ),
  c("maskid", "[player]", "Show a player's mask ID.", "Lookup"),
  c(
    "omaskid",
    "[mask id]",
    "Look up the character behind a mask ID, even when they are offline.",
    "Lookup",
  ),
  c(
    "whonear",
    "[range]",
    "List players within range of you. Default 20.",
    "Lookup",
  ),
  c(
    "getcoordinates",
    "",
    "Show your own coordinates, angle, interior and virtual world.",
    "Lookup",
  ),
  c(
    "getdistance",
    "[player]",
    "Show how far away a player is and where they are.",
    "Lookup",
    { aliases: ["distance", "dist"] },
  ),
  c("checkrefunds", "[player]", "View a player's refund history.", "Lookup"),
  c("checkguns", "[player]", "List the weapons a player owns.", "Lookup"),
  c("checkcars", "[player]", "List the vehicles a player owns.", "Lookup", {
    note: "Also usable by Helpers.",
  }),
  c(
    "checkproperties",
    "[player]",
    "List the properties a player owns.",
    "Lookup",
  ),
  c("propertycheck", "[property id]", "Show details of a property.", "Lookup", {
    aliases: ["propcheck", "propinfo"],
  }),
  c(
    "propertygetid",
    "[sql id]",
    "Convert a property's database ID to its in-game ID.",
    "Lookup",
  ),
  c(
    "phcheck",
    "[player]",
    "Show a player's anticheat cheat history and whether they are on mobile.",
    "Lookup",
  ),
  c("carname", "[model]", "Search vehicle model names and IDs.", "Lookup"),
  c(
    "findrentals",
    "",
    "List every rental vehicle with its rented and occupied state.",
    "Lookup",
  ),
  c(
    "junkiestatus",
    "",
    "Show junkie spawn totals: active, on cooldown and available.",
    "Lookup",
  ),
  c(
    "playerlogs",
    "[log type]",
    "Browse the server logs for one log type.",
    "Lookup",
    {
      aliases: ["plogs"],
      beta: true,
      note: "Log types unlock by rank: Chat, Script, Game, Damage, Admin and Drugs from Beta; OOC, Action, Phone and others from Junior; PM and All from General.",
    },
  ),
  c(
    "playerlog",
    "[player] [log type]",
    "Browse one online player's logs.",
    "Lookup",
    { aliases: ["plog"], beta: true },
  ),
  c(
    "offlineplayerlog",
    "[character id] [log type]",
    "Browse an offline character's logs. Get the ID with /gcid.",
    "Lookup",
    { aliases: ["oplog"], beta: true },
  ),

  // Vehicles
  c("carrespawn", "[player]", "Respawn a player's vehicle.", "Vehicle"),
  c("carfix", "[player]", "Repair a player's vehicle.", "Vehicle"),
  c("getcar", "[car id]", "Teleport a vehicle to you.", "Vehicle", {
    aliases: ["carget"],
  }),
  c(
    "takecar",
    "[car id]",
    "Respawn a vehicle, ejecting anyone inside, and put yourself in the driver seat.",
    "Vehicle",
    { aliases: ["respawncar"], note: "Also usable by Helpers." },
  ),
  c("boomboxremove", "", "Remove the nearest boombox.", "World"),

  // World and misc
  c(
    "respawnplayer",
    "[player]",
    "Show a player the spawn selection screen.",
    "Player",
    { note: "Also usable by Supporters rank 2+." },
  ),
  c(
    "basketrefresh",
    "",
    "Refresh the nearest basketball court after a bug.",
    "Minigames",
  ),
  c(
    "customspawn",
    "[model] [draw distance] [minutes]",
    "Place a temporary object that lasts the given number of minutes (10 minutes to 7 days). Defaults to 100.0 draw distance and 60 minutes.",
    "World",
  ),
  c(
    "allspawns",
    "",
    "List every placed temporary object and delete the ones you pick.",
    "World",
  ),
  c(
    "fchatban",
    "[faction id]",
    "Toggle a faction's chat on or off.",
    "Faction",
  ),
  c("reloadfskins", "", "Reload faction skins from the database.", "Faction"),

  // Beta-gated (reachable from Junior)
  c(
    "adminduty",
    "",
    "Toggle admin duty, showing the duty tag above your name.",
    "Chat & Duty",
    { aliases: ["aduty"], beta: true },
  ),
  c("a", "[text]", "Send a message in admin chat.", "Chat & Duty", {
    aliases: ["achat"],
    beta: true,
  }),
  c(
    "staffhelp",
    "[helper|admin|vehicle|property|faction|dynamic|misc]",
    "Show in-game staff command help by category.",
    "Chat & Duty",
    {
      beta: true,
      note: "The in-game lists lag behind the code, so this page is the reference.",
    },
  ),
  c(
    "playermessages",
    "",
    "List accounts that currently have a pending admin message waiting for them.",
    "Chat & Duty",
    { beta: true },
  ),
  c(
    "resetattributes",
    "[player]",
    "Reset a character's attributes.",
    "Player",
    { beta: true, note: "Also usable by Supporters rank 2+." },
  ),
  c("jetpack", "", "Give yourself a jetpack.", "Testing", { beta: true }),
  c(
    "propertycreate",
    "[price] [type]",
    "Create a property at your position. Price 0 means not for sale. Type 0 is a house, 1 a business, 2 static.",
    "Property",
    {
      beta: true,
      note: "Gated at Beta Tester in the code, though /staffhelp lists it for Senior.",
    },
  ),
];

/* ── General ──────────────────────────────────────────────────────── */
const GENERAL: AdminCommand[] = [
  c(
    "offlineban",
    "[account name] [hours] [reason]",
    "Ban a master account that is offline.",
    "Moderation",
  ),
  c(
    "silentban",
    "[player] [hours] [reason]",
    "Ban an online player without the public ban announcement.",
    "Moderation",
  ),
  c(
    "blockaccounts",
    "[seconds 0-3600]",
    "Stop new accounts being created for a number of seconds, for example during a raid.",
    "Moderation",
  ),
  c(
    "makeooc",
    "[player]",
    "Toggle a player Out-Of-Character, which also clears their injured, tased or beanbagged state.",
    "Moderation",
  ),
  c(
    "processjfl",
    "[player] [accept|deny] [reason]",
    "Approve or deny a pending Jail For Life request.",
    "Moderation",
  ),
  c(
    "removejfl",
    "[player] [reason]",
    "Remove a Jail For Life sentence.",
    "Moderation",
  ),

  c(
    "geoip",
    "[player]",
    "Show a player's IP address, geolocation and timezone.",
    "Lookup",
  ),
  c(
    "getplayernumber",
    "[player]",
    "Show the phone number of a player.",
    "Lookup",
  ),
  c(
    "getstate",
    "[player]",
    "Show a player's current state, such as on foot or driving.",
    "Lookup",
  ),
  c("checkstats", "[player]", "Show a player's character stats.", "Lookup"),
  c("timeinfo", "", "Show the server clock, date, weather and tick.", "Lookup"),
  c(
    "fservervehs",
    "",
    "List how many server-owned vehicles each faction has.",
    "Lookup",
  ),
  c("listvpn", "", "List the accounts on the VPN whitelist.", "Lookup"),
  c("industries", "", "List trucker industries with their storages.", "Lookup"),
  c(
    "prisonlocations",
    "",
    "List the prison laundry locations and their coordinates.",
    "Lookup",
  ),
  c("objnear", "", "List admin objects near you.", "Lookup"),
  c("atmnearby", "", "List ATMs within 50m.", "Lookup"),
  c("listatms", "", "List every loaded ATM.", "Lookup"),
  c("gatenear", "", "Show details of the nearest gates.", "Lookup"),

  c("sethealth", "[player] [0-100]", "Set a player's health.", "Player"),
  c("setarmor", "[player] [0-100]", "Set a player's armor.", "Player"),
  c("setskin", "[player] [skin id]", "Change a player's skin.", "Player"),
  c(
    "setduty",
    "[player] [0|1]",
    "Set a player's faction duty status on or off.",
    "Player",
  ),
  c(
    "setattribute",
    "[player] [attribute] [value]",
    "Set one of a character's attributes.",
    "Player",
  ),
  c("givejetpack", "[player]", "Give a player a jetpack.", "Player"),
  c(
    "giverp",
    "[player]",
    "Endorse a player for good roleplay. Once per admin per player.",
    "Player",
  ),
  c(
    "spawnallow",
    "[player]",
    'Let a player use "Other" spawnables until they log out.',
    "Player",
  ),
  c(
    "makehelper",
    "[player] [remove|trial|helper|senior]",
    "Set a player's helper rank.",
    "Staff",
  ),
  c(
    "listen",
    "[player]",
    "Mirror a player's local and faction chat into your chat window as [LISTEN] lines until you use /listenoff.",
    "Player",
  ),
  c("listenoff", "", "Stop listening in.", "Player"),

  c(
    "gotoxyz",
    "[x] [y] [z] [interior] [world]",
    "Teleport to exact coordinates.",
    "Teleport",
    { aliases: ["gotopos"] },
  ),
  c("gotomarker", "", "Teleport to your map waypoint marker.", "Teleport"),
  c(
    "mark",
    "[1-3]",
    "Save your current location to one of three mark slots.",
    "Teleport",
  ),
  c("gotomark", "[1-3]", "Teleport to a saved mark slot.", "Teleport"),
  c(
    "noclip",
    "",
    "Toggle free-camera fly mode. Cannot be used while spectating.",
    "Teleport",
    { aliases: ["freecam"] },
  ),
  c(
    "togglenoclip",
    "[player]",
    "Toggle free-camera mode on another player.",
    "Teleport",
    { aliases: ["togglefreecam"] },
  ),
  c(
    "prisonlocation",
    "[0-4]",
    "Place a prison laundry point at your position: clock-in, pickup, washer, dryer or dropoff.",
    "Teleport",
  ),
  c(
    "gotoprisonloc",
    "[0-4]",
    "Teleport to a prison laundry point.",
    "Teleport",
  ),
  c("gotoatm", "[id]", "Teleport to an ATM.", "Teleport"),
  c("propertygoto", "[id]", "Teleport to a property.", "Teleport", {
    aliases: ["propgoto"],
  }),
  c("spraytaggoto", "[id]", "Teleport to a static spray tag.", "Teleport", {
    aliases: ["stgoto"],
  }),
  c("gategoto", "[gate id]", "Teleport to a gate.", "Teleport"),
  c("objgoto", "[id]", "Teleport to an admin object.", "Teleport"),
  c("gotowardrobe", "[wardrobe id]", "Teleport to a wardrobe.", "Teleport", {
    aliases: ["wardrobegoto"],
  }),
  c(
    "propertyinteriorlist",
    "",
    "Open the list of property interiors and click one to teleport inside.",
    "Teleport",
    { aliases: ["propertyintlist"] },
  ),

  c("ahide", "", "Hide yourself from the /admins list.", "Chat & Duty"),
  c("aooc", "[text]", "Send a global OOC message as staff.", "Chat & Duty"),
  c(
    "ado",
    "[radius] [text]",
    "Broadcast a /do-style description message to everyone within a radius.",
    "Chat & Duty",
  ),
  c(
    "setadminmotd",
    "[1-3] [text]",
    "Set one of the three staff notice lines shown to staff on login.",
    "Chat & Duty",
  ),
  c("adminad", "[text]", "Post an advertisement for free.", "Chat & Duty"),
  c(
    "adminbreaking",
    "[text]",
    "Post an anonymous breaking-news message.",
    "Chat & Duty",
  ),
  c(
    "admin911",
    "[police|medic|fire] [number] [text]",
    "Place a fake 911 call. Number 0 picks a random phone number.",
    "Chat & Duty",
  ),

  c("carflip", "[player]", "Flip a player's vehicle upright.", "Vehicle"),
  c("carslap", "[player]", "Slap a player's vehicle into the air.", "Vehicle"),
  c(
    "carhp",
    "[player] [health]",
    "Set the health of the vehicle a player is in.",
    "Vehicle",
  ),
  c(
    "acarfuel",
    "[player] [percent]",
    "Set the fuel level of a player's vehicle.",
    "Vehicle",
  ),
  c("ecc", "", "Enter the closest vehicle.", "Vehicle"),
  c(
    "entercar",
    "[car id] [seat]",
    "Warp into a vehicle by ID and seat.",
    "Vehicle",
  ),
  c(
    "caradmincolor",
    "[color a] [color b]",
    "Set the colours of the vehicle you are in.",
    "Vehicle",
  ),
  c(
    "caradminpaintjob",
    "[0-2|3]",
    "Set the paintjob of your vehicle. 3 removes it.",
    "Vehicle",
  ),
  c(
    "caradminpark",
    "",
    "Save your vehicle's current position, health and damage as its saved state.",
    "Vehicle",
  ),
  c(
    "carsavesiren",
    "",
    "Save or remove a siren on a faction vehicle.",
    "Vehicle",
  ),
  c(
    "deletecar",
    "[vehicle id]",
    "Permanently delete a vehicle. Use carefully.",
    "Vehicle",
  ),

  c(
    "propertyintid",
    "[property id] [interior]",
    "Set only the interior ID of a property.",
    "Property",
    { aliases: ["propintid"] },
  ),
  c(
    "propertyfee",
    "[amount]",
    "Set a property's entrance fee. 0 disables it.",
    "Property",
    { aliases: ["propfee"] },
  ),
  c(
    "passpointmoveint",
    "[passpoint id] [interior]",
    "Set the interior of a passpoint's original point.",
    "Property",
    { aliases: ["passmoveint"] },
  ),
  c(
    "passpointlinkint",
    "[passpoint id] [interior]",
    "Set the interior of a passpoint's linked point.",
    "Property",
    { aliases: ["passlinkint"] },
  ),
  c("burglary", "", "Start a burglary for testing. Admins only.", "Testing"),

  c(
    "armoryplace",
    "[armory id]",
    "Place a faction armory at your position.",
    "Faction",
  ),
  c(
    "reloadarmories",
    "",
    "Reload armory types, locations and weapons from the database.",
    "Faction",
  ),
  c("afjoin", "[faction]", "Make yourself leader of a faction.", "Faction", {
    aliases: ["adminfactionjoin"],
  }),

  c("gatecreate", "[model]", "Create a gate from an object model.", "World"),
  c("gatestyle", "[gate id] [style]", "Set a gate's style preset.", "World"),
  c(
    "gateautoclose",
    "[gate id] [0|1]",
    "Make a gate close itself automatically.",
    "World",
  ),
  c(
    "gateautoopen",
    "[gate id] [0|1]",
    "Make a gate open itself automatically as players approach.",
    "World",
  ),
  c(
    "gateradius",
    "[gate id] [radius]",
    "Set how close a player must be to use a gate.",
    "World",
  ),
  c(
    "gateopen",
    "[gate id]",
    "Edit a gate's open position by dragging it to where it should rest when open.",
    "World",
  ),
  c(
    "gatemove",
    "[gate id]",
    "Edit a gate's closed position with the object editor.",
    "World",
  ),
  c(
    "gatetome",
    "[gate id]",
    "Pull a gate to a spot in front of you and open the editor on it.",
    "World",
  ),
  c("gateworld", "[gate id] [world]", "Set a gate's virtual world.", "World"),
  c("gateint", "[gate id] [interior]", "Set a gate's interior.", "World"),
  c(
    "gatetype",
    "[gate id] [type] [owner]",
    "Set who owns a gate. 1 public, 2 player, 3 property, 4 faction.",
    "World",
  ),
  c(
    "gatefaction",
    "[add|remove] [gate id] [faction id]",
    "Give a faction extra access to a faction-owned gate.",
    "World",
  ),
  c("copygate", "[gate id]", "Duplicate a gate.", "World"),
  c("gatedelete", "[gate id]", "Delete a gate.", "World"),
  c(
    "gatespeed",
    "[gate id] [speed]",
    "Set how fast a gate opens and closes.",
    "World",
  ),
  c("objcreate", "[model]", "Create a persistent admin object.", "World"),
  c("objedit", "[object id]", "Edit an admin object's position.", "World"),
  c("objclone", "[object id]", "Duplicate an admin object.", "World"),
  c("objdelete", "[object id]", "Delete an admin object.", "World"),
  c("createatm", "", "Create an ATM at your position.", "World"),
  c("moveatm", "", "Move the nearest ATM to your position.", "World"),
  c("deleteatm", "", "Delete the nearest ATM after confirming.", "World"),
  c(
    "spraytagclearcd",
    "[player]",
    "Clear a player's spray tag cooldowns.",
    "World",
    { aliases: ["stclearcd"] },
  ),
  c("checkwardrobe", "[wardrobe id]", "Show details of a wardrobe.", "World", {
    aliases: ["wardrobecheck"],
  }),
  c("addwardrobe", "[type]", "Create a wardrobe at your position.", "World", {
    aliases: ["wardrobeadd", "wardrobecreate", "createwardrobe"],
  }),
  c(
    "movewardrobe",
    "[wardrobe id]",
    "Move a wardrobe to your position.",
    "World",
    { aliases: ["wardrobemove"] },
  ),
  c(
    "wardrobetype",
    "[type]",
    "Change the type of the wardrobe you are standing at.",
    "World",
  ),
  c(
    "wardrobeowner",
    "[owner sql id]",
    "Set the owner of the wardrobe you are standing at.",
    "World",
  ),
  c("deletewardrobe", "[wardrobe id]", "Delete a wardrobe.", "World", {
    aliases: ["wardrobedel", "wardrobedelete", "wardrobedestroy"],
  }),

  c("settime", "[hour] [minute]", "Set the server time.", "Server"),
  c("setweather", "[weather id 0-20]", "Set the server weather.", "Server"),
  c(
    "addvpn",
    "[account name]",
    "Add an account to the VPN whitelist.",
    "Server",
  ),
  c(
    "removevpn",
    "[account name]",
    "Remove an account from the VPN whitelist.",
    "Server",
  ),

  c(
    "runeconomy",
    "",
    "Force an economy tick so every trucker industry produces.",
    "Economy",
  ),
  c(
    "spoofattach",
    "[slot 0-9] [model] [bone]",
    "Attach an object to yourself on a bone. Model 0 removes it.",
    "Testing",
  ),
  c("arrestme", "", "Put yourself in a prison cell for testing.", "Testing"),
];

/* ── Senior ───────────────────────────────────────────────────────── */
const SENIOR: AdminCommand[] = [
  c(
    "setgunrights",
    "[player] [0|1]",
    "Gun ban a player (1) or restore their gun rights (0).",
    "Moderation",
    { aliases: ["gunban"] },
  ),
  c(
    "akill",
    "[player] [reason]",
    "Kill a player with an admin death reason.",
    "Moderation",
  ),
  c(
    "adminmessage",
    "<account id> <message>",
    "Leave a message that the account sees the next time they log in.",
    "Moderation",
  ),
  c(
    "removemessage",
    "<account id>",
    "Remove a pending admin message from an account.",
    "Moderation",
  ),
  c(
    "setfightstyle",
    "[player] [style] [paychecks]",
    "Grant a fighting style (normal, grabkick, boxing, kungfu) for a number of paychecks.",
    "Player",
  ),

  c("viewcars", "[model]", "List every spawned vehicle of a model.", "Lookup"),
  c(
    "streamcount",
    "",
    "Show visible and total placed objects, for performance checks.",
    "Lookup",
  ),
  c(
    "actornear",
    "",
    "Show the nearest decorative actor within 30 units.",
    "Lookup",
  ),
  c("actorinfo", "[actor id]", "Show details of a decorative actor.", "Lookup"),
  c(
    "junkietest",
    "[tick|expire|cooldown|clearcd|info]",
    "Test the junkie system: force a tick, expire junkies or clear cooldowns.",
    "Testing",
  ),

  c(
    "setcarhp",
    "[vehicle id] [health]",
    "Set a vehicle's health by ID.",
    "Vehicle",
  ),
  c(
    "respawnallcars",
    "",
    "Respawn every unoccupied vehicle after a 15 second warning.",
    "Vehicle",
  ),
  c(
    "respawnrentals",
    "",
    "Respawn all public and rental vehicles after a warning.",
    "Vehicle",
  ),
  c(
    "respawnjobcars",
    "",
    "Respawn all job vehicles after a warning.",
    "Vehicle",
  ),
  c(
    "respawnmissingvehicles",
    "",
    "Check memory and the database for missing non-player vehicles and restore them.",
    "Vehicle",
  ),

  c(
    "propertymove",
    "[id]",
    "Move a property's entrance to your position.",
    "Property",
  ),
  c(
    "propertydelete",
    "[id]",
    "Delete an unowned property. Owned ones must be auctioned first.",
    "Property",
  ),
  c(
    "propertyprice",
    "[id] [price]",
    "Set a property's price (2,500 to 1,000,000). 0 disables buying.",
    "Property",
  ),
  c(
    "propertytype",
    "[id] [type]",
    "Set a property's type: 0 house, 1 business, 2 static.",
    "Property",
  ),
  c(
    "propertyfaction",
    "[id] [faction sql id]",
    "Assign a property to a faction.",
    "Property",
  ),
  c(
    "propertyowner",
    "[id] [character id]",
    "Set the owning character of a property.",
    "Property",
  ),
  c(
    "propertyauction",
    "[id]",
    "Sell a player's property back, refunding them on next login.",
    "Property",
  ),
  c(
    "propertybuytype",
    "[id] [type]",
    "Set what a business sells. See /buypointtypes.",
    "Property",
  ),
  c(
    "propertybuypoint",
    "[id]",
    "Place a business's buy point at your position.",
    "Property",
  ),
  c(
    "propertyextra",
    "[id] [type]",
    "Set the vehicle type a car dealership sells and where cars spawn.",
    "Property",
  ),
  c(
    "propertyinterior",
    "[id]",
    "Set a property's interior to your current location.",
    "Property",
  ),
  c(
    "propertyworld",
    "[id] [world]",
    "Set a property's interior virtual world.",
    "Property",
  ),

  c(
    "passpointcreate",
    "[0 player|1 vehicle]",
    "Create a passpoint, a linked door pair, at your position.",
    "Property",
  ),
  c(
    "passpointlink",
    "[id]",
    "Set a passpoint's linked end to your position.",
    "Property",
  ),
  c(
    "passpointmove",
    "[id]",
    "Move a passpoint's original end to your position.",
    "Property",
  ),
  c("passpointdelete", "[id]", "Delete a passpoint.", "Property"),
  c("passpointgoto", "[id]", "Teleport to a passpoint.", "Property"),
  c(
    "passpointfaction",
    "[id] [faction sql id]",
    "Restrict a passpoint to a faction. 0 disables.",
    "Property",
  ),
  c(
    "passpointplayer",
    "[id] [character sql id]",
    "Restrict a passpoint to one character. 0 clears.",
    "Property",
  ),
  c(
    "passpointtype",
    "[id] [0 player|1 vehicle]",
    "Set whether a passpoint is for players or vehicles.",
    "Property",
  ),
  c("passpointname", "[id] [name]", "Rename a passpoint.", "Property"),
  c(
    "passpointlinkname",
    "[id] [name]",
    'Name only the linked end. "none" shares the main name again.',
    "Property",
  ),
  c(
    "passpointcolor",
    "[id] [hex]",
    "Set a passpoint's colour, e.g. 0xDEDEDEFF.",
    "Property",
  ),
  c(
    "passpointradius",
    "[id] [radius]",
    "Set a passpoint's trigger radius (0.1 to 10, default 7.5).",
    "Property",
  ),

  c(
    "factionextra",
    "[id] [type]",
    "Set a faction's extra type: guns, weed, crack, cocaine, meth, cartel or gang.",
    "Faction",
    { aliases: ["fextra"] },
  ),
  c(
    "factionresetperkcd",
    "[id]",
    "Reset a faction's perk cooldown.",
    "Faction",
  ),
  c(
    "gangzoneassign",
    "[faction]",
    "Assign the gangzone you are standing in to a faction.",
    "Faction",
  ),
  c(
    "gangzonecontest",
    "",
    "Toggle the contested state of the gangzone you are in.",
    "Faction",
  ),

  c(
    "actorcreate",
    "[skin id]",
    "Create a decorative actor at your position.",
    "World",
  ),
  c(
    "actordelete",
    "[actor id]",
    "Permanently delete a decorative actor.",
    "World",
  ),
  c("actormove", "[actor id]", "Move an actor to your position.", "World"),
  c(
    "actoranim",
    "[actor id] [lib] [name] [loop] [freeze]",
    'Set an actor\'s animation. "none none" clears it.',
    "World",
  ),
  c("reloadactors", "", "Reload decorative actors from the database.", "World"),
  c(
    "addattachpoint",
    "[type 0-18]",
    "Create a clothing attach point at your position.",
    "World",
  ),
  c(
    "attachpointlink",
    "[point id] [business id]",
    "Link an attach point to a business.",
    "World",
  ),
  c("attachpointdelete", "[point id]", "Delete an attach point.", "World"),
  c("forceskinupdate", "", "Reload custom skins without a restart.", "World"),
  c("gatetoll", "[gate id] [0|1]", "Make a gate a toll gate.", "World"),
  c(
    "gatetexture",
    "[gate id] [index] [txd model] [txd] [texture]",
    "Retexture a gate object slot.",
    "World",
  ),
  c("addjunkie", "", "Add a junkie spawn location at your position.", "World"),
  c(
    "setjunkieskin",
    "[skin 0-311|-1]",
    "Set the skin of the junkie spawn within 10m. -1 picks a random skin.",
    "World",
  ),
  c(
    "removejunkie",
    "",
    "Permanently remove the junkie spawn within 10m.",
    "World",
  ),
  c(
    "removestreetboss",
    "[player]",
    "Remove a player's street boss dealer NPC and return their earnings.",
    "Faction",
  ),
  c(
    "basketcreate",
    "",
    "Create a basketball court at your position.",
    "Minigames",
  ),

  c(
    "poolcreate",
    "[angle]",
    "Create a pool table under you. Angle must be 0, 90, 270 or 360.",
    "Minigames",
  ),
  c(
    "poolmove",
    "[angle]",
    "Move the nearest pool table to your position.",
    "Minigames",
  ),
  c(
    "poolcolor",
    "[0-36]",
    "Change the nearest pool table's colour.",
    "Minigames",
  ),
  c("poolgoto", "[pool id]", "Teleport to a pool table.", "Minigames"),
  c(
    "poolendgame",
    "",
    "Force-end the game at the nearest pool table.",
    "Minigames",
  ),
  c("pooldelete", "", "Delete the nearest pool table.", "Minigames"),
  c(
    "pokercreate",
    "[small blind] [big blind]",
    "Place a poker table by dragging it into position, then saving.",
    "Minigames",
  ),
  c("pokernear", "", "List poker tables within 50m.", "Minigames"),
  c(
    "pokerseat",
    "[1-n]",
    "Record the chair you are standing on as seat n for every table. `/pokerseat n test` jumps to it.",
    "Minigames",
  ),
  c(
    "pokerchips",
    "",
    "Debug the chip objects on the table you are at.",
    "Minigames",
  ),
  c(
    "pokerdelete",
    "[table id]",
    "Delete a poker table permanently and cash players out.",
    "Minigames",
  ),
  c(
    "pokerendgame",
    "[table id]",
    "Cancel the hand on a table and return all bets.",
    "Minigames",
  ),
  c(
    "pokerbots",
    "[count|clear]",
    "Seat test bots with fake chips at the table you are sitting at.",
    "Testing",
  ),
];

/* ── Lead ─────────────────────────────────────────────────────────── */
const LEAD: AdminCommand[] = [
  c("man", "[text]", "Send a message in manager chat.", "Chat & Duty"),
  c(
    "disablepm",
    "",
    "Turn private messages on or off server-wide.",
    "Moderation",
  ),
  c(
    "factionban",
    "[player]",
    "Faction ban a player, removing them from their faction.",
    "Moderation",
  ),
  c("factionunban", "[player]", "Lift a faction ban.", "Moderation"),
  c(
    "ofactionban",
    "[account name] [0|1]",
    "Faction ban (1) or unban (0) an offline account.",
    "Moderation",
  ),
  c(
    "sprintban",
    "[player] [0|1]",
    "Sprint ban a player (1) or restore sprinting (0).",
    "Moderation",
  ),
  c(
    "purgenotes",
    "[account id]",
    "Delete every admin note on an account.",
    "Moderation",
  ),
  c(
    "addrefund",
    "[player] [type]",
    "Create a refund for an online player. Type 0 money, 1 weapon, 2 drug.",
    "Economy",
  ),
  c(
    "oaddrefund",
    "[character id] [type]",
    "Create a refund for an offline character.",
    "Economy",
  ),
  c(
    "setstat",
    "[option] [player] [value]",
    "Set a player stat such as mask, donator, phone, rppoints, respect, fear, stamps, fines or hours.",
    "Player",
  ),

  c(
    "setmotd",
    "[1-3] [text]",
    "Set one of the three server-wide message-of-the-day lines.",
    "Server",
  ),
  c(
    "maintenance",
    "",
    "Schedule or cancel a server maintenance timer (30 seconds to 6 hours).",
    "Server",
  ),
  c("acstatus", "", "Show which anticheat modules are on or off.", "Server"),
  c(
    "toggleac",
    "[health|tp|airbreak|mod]",
    "Turn an anticheat module on or off.",
    "Server",
  ),
  c("nodc", "", "Turn donator chat on or off for everyone.", "Server", {
    aliases: ["nodonatorchat"],
  }),
  c("reloadfurniture", "", "Reload furniture from the database.", "Server"),

  c(
    "factioncreate",
    "[type]",
    "Create a new faction. Set its name afterwards with /factionname.",
    "Faction",
    { aliases: ["fcreate"] },
  ),
  c("factionname", "[id] [name]", "Rename a faction.", "Faction", {
    aliases: ["fname"],
  }),
  c("factionhex", "[id] [hex]", "Set a faction's colour.", "Faction", {
    aliases: ["fhex"],
  }),
  c(
    "factionvisible",
    "[id]",
    "Toggle whether a faction is visible in the public list.",
    "Faction",
    { aliases: ["fvisible"] },
  ),
  c(
    "fskinadd",
    "[skin] [tier] [squad]",
    "Add a skin to your faction's skin list.",
    "Faction",
    { aliases: ["factionskinadd"] },
  ),
  c(
    "fskindel",
    "[skin id]",
    "Remove a skin from your faction's skin list.",
    "Faction",
  ),
  c(
    "fixfactiontiers",
    "[gang|all]",
    "Demote extra tier 1 members to tier 3 in factions with more than one owner.",
    "Faction",
  ),
  c(
    "chopshopfaction",
    "[faction id]",
    "Give a faction control of the chop shop.",
    "Faction",
  ),
  c(
    "firmvehicle",
    "[firm abbreviation]",
    'Assign the vehicle you are in to a firm. "none" unassigns it.',
    "Faction",
  ),

  c(
    "carcreate",
    "[model] [type] [owner]",
    "Create a vehicle. Set its details with /cartype and /carowner.",
    "Vehicle",
  ),
  c("cartype", "[type]", "Set the type of the vehicle you are in.", "Vehicle"),
  c(
    "carowner",
    "[owner]",
    "Set the owner of your vehicle: faction ID, character ID, or -1.",
    "Vehicle",
  ),
  c(
    "carjob",
    "[type]",
    "Make your vehicle a job vehicle. This clears its owner.",
    "Vehicle",
  ),
  c(
    "carsquad",
    "[squad id]",
    "Assign your vehicle to a squad. -1 removes it.",
    "Vehicle",
  ),
  c("sirenedit", "", "Open the siren editor for your vehicle.", "Vehicle"),
  c("vattach", "", "Open the vehicle attachment editor.", "Vehicle"),
  c(
    "gotodealer",
    "[dealer id]",
    "Teleport to a vehicle dealership.",
    "Teleport",
  ),

  c(
    "createfuelstation",
    "",
    "Create a fuel station at your position.",
    "World",
  ),
  c("gotostation", "[sql id]", "Teleport to a fuel station.", "Teleport"),
  c(
    "movestation",
    "[sql id]",
    "Move a fuel station to your position.",
    "World",
  ),
  c(
    "auctionstation",
    "[sql id]",
    "Sell a player-owned fuel station, refunding them on login.",
    "World",
  ),
  c("deletestation", "[sql id]", "Delete a fuel station.", "World"),
  c("stationinfo", "", "Show details of the nearest fuel station.", "Lookup"),
  c(
    "createfuelpump",
    "[1 ron|2 terroil|3 globe]",
    "Create a fuel pump of a brand.",
    "World",
  ),
  c(
    "linkpumptostation",
    "[pump id] [station id]",
    "Link a pump to a station so it earns revenue.",
    "World",
  ),
  c("unlinkpump", "[pump id]", "Unlink a pump from its station.", "World"),
  c(
    "viewlinkedpumps",
    "[station id]",
    "List the pumps linked to a station.",
    "Lookup",
  ),
  c("unlinkedpumps", "", "List pumps not linked to any station.", "Lookup"),
  c("gotopump", "[pump id]", "Teleport to a fuel pump.", "Teleport"),
  c("movepump", "[pump id]", "Edit a pump's position.", "World"),
  c("deletepump", "[pump id]", "Delete a fuel pump.", "World"),
  c(
    "spraytagcreate",
    "",
    "Create a static spray tag by positioning it and saving.",
    "World",
    { aliases: ["stcreate"] },
  ),
  c(
    "spraytagdelete",
    "[array id]",
    "Delete a static spray tag by the array ID on its label.",
    "World",
    { aliases: ["stdelete"] },
  ),
];

/* ── Head ─────────────────────────────────────────────────────────── */
const HEAD: AdminCommand[] = [
  c(
    "makeadmin",
    "[player] [level]",
    "Promote or demote a player's staff level (0 to 8).",
    "Staff",
  ),
  c(
    "omakehelper",
    "[account name] [none|trial|normal|senior]",
    "Set an offline account's helper rank.",
    "Staff",
  ),
  c(
    "makecontributor",
    "[player] [type]",
    "Make a player a contributor: 1 Veteran with no powers, 2 Invited with Junior powers, and so on.",
    "Staff",
  ),
  c(
    "adminhex",
    "[hex]",
    "Set the admin chat colour. Default 0xde6e1fFF.",
    "Staff",
  ),
  c(
    "helperhex",
    "[hex]",
    "Set the helper chat colour. Default 0xAEC77DFF.",
    "Staff",
  ),
  c("togman", "", "Toggle your own manager-level warnings.", "Staff"),
  c(
    "deletechar",
    "[firstname_lastname]",
    "Permanently delete a character. You must type the full name to confirm.",
    "Player",
  ),
  c(
    "setintrosong",
    "[url]",
    "Set the intro song URL players hear on joining.",
    "Server",
  ),
];

/* ── Manager ──────────────────────────────────────────────────────── */
const MANAGER: AdminCommand[] = [
  c("paycheck", "", "Force a paycheck for every online player.", "Economy"),
  c("togds", "", "Open or close all server dealerships.", "Economy"),
  c(
    "forcechopshop",
    "",
    "Run the chop shop location check without the range limit.",
    "Testing",
  ),
  c(
    "tempclearchopshopcd",
    "[player]",
    "Reset a player's chop shop cooldown. Not saved.",
    "Testing",
  ),
  c(
    "spoofbuy",
    "[type]",
    "Trigger a property purchase of a buy type without a property.",
    "Testing",
  ),
  c("spoofgun", "[weapon id] [ammo]", "Give yourself a weapon.", "Testing"),
  c(
    "spoofgivegun",
    "[player] [weapon id] [ammo]",
    "Give a player a weapon.",
    "Testing",
  ),
  c(
    "spoofpool",
    "",
    "Start a solo test game at the nearest pool table.",
    "Testing",
  ),
  c(
    "spoofgymstat",
    "[player] [stat id] [amount]",
    "Set a gym stat on a player.",
    "Testing",
  ),
  c(
    "spoofrespect",
    "[player] [amount]",
    "Give a player respect points.",
    "Testing",
  ),
  c("spooffear", "[player] [amount]", "Give a player fear points.", "Testing"),
  c(
    "givefnrpoints",
    "[player] [amount] [reason]",
    "Give a player Fear and Respect points.",
    "Testing",
  ),
  c(
    "setfnrlevel",
    "[player] [level 1-11]",
    "Set a player's Fear and Respect level.",
    "Testing",
  ),
  c(
    "testlevelup",
    "[player]",
    "Trigger a Fear and Respect level up on a player.",
    "Testing",
  ),
  c(
    "spoofdrug",
    "[1 weed|2 cocaine|3 crack] [subtype 1-4] [container 0-8] [amount]",
    "Give yourself drugs.",
    "Testing",
  ),
  c(
    "spoofdrugstation",
    "[1 weed|2 cocaine|3 crack]",
    "Create a drug station for testing.",
    "Testing",
  ),
  c(
    "drugsetticks",
    "[plant index] [ticks]",
    "Set the growth ticks of a drug plant.",
    "Testing",
  ),
  c(
    "drugforcefinish",
    "[plant index]",
    "Finish a drug plant's grow and calculate its haul.",
    "Testing",
  ),
  c(
    "drugsetparam",
    "[plant index] [param]",
    "Set a drug plant's parameter.",
    "Testing",
  ),
  c(
    "drugsetstage",
    "[plant index] [stage]",
    "Set a drug plant's growth stage.",
    "Testing",
  ),
  c("drugsuppliergoto", "[id]", "Teleport to a drug supplier.", "Testing"),
];

/* ── Developer ────────────────────────────────────────────────────── */
const DEVELOPER: AdminCommand[] = [
  c(
    "givemoney",
    "[player] [amount] [reason]",
    "Give a player cash.",
    "Economy",
  ),
  c(
    "takemoney",
    "[player] [amount]",
    "Take cash from a player as a fine.",
    "Economy",
  ),
  c(
    "setpass",
    "[account name] [password]",
    "Overwrite an account's password.",
    "Staff",
  ),
  c(
    "createstreetboss",
    "",
    "Create a street boss dealer NPC at your position.",
    "Testing",
  ),
  c(
    "testdeathanim",
    "[option] [weapon id]",
    "Preview a death animation.",
    "Testing",
  ),
  c(
    "clearcd",
    "",
    "Clear your own chop shop and robbery cooldowns. Not saved.",
    "Testing",
    { note: "RCON login required." },
  ),
  c("neon", "[0-5]", "Set neon underglow on your vehicle.", "Testing", {
    note: "RCON login required.",
  }),
  c(
    "togvehpatch",
    "",
    "Switch the vehicle lookup between the static variable and the loop implementation.",
    "Testing",
    { note: "RCON login required." },
  ),
  c("afly", "", "Toggle surfly mode, flying with your camera.", "Testing", {
    aliases: ["surfly"],
    note: "RCON login required. Provided by the afly filterscript.",
  }),
];

export const ADMIN_TIERS: AdminTier[] = [
  {
    id: "junior",
    level: ADMIN_LVL.JUNIOR,
    blurb:
      "Everyday moderation: punishments, reports, teleporting, spectating and player lookups.",
    commands: JUNIOR,
  },
  {
    id: "general",
    level: ADMIN_LVL.GENERAL,
    blurb:
      "Bans without a player online, player editing, world building tools such as gates, ATMs and objects.",
    commands: GENERAL,
  },
  {
    id: "senior",
    level: ADMIN_LVL.SENIOR,
    blurb:
      "Property, passpoint and vehicle-fleet management, minigame tables, actors and gun bans.",
    commands: SENIOR,
  },
  {
    id: "lead",
    level: ADMIN_LVL.LEAD,
    blurb:
      "Faction creation and bans, refunds, server settings, anticheat and fuel infrastructure.",
    commands: LEAD,
  },
  {
    id: "head",
    level: ADMIN_LVL.HEAD,
    blurb:
      "Staff management: promotions, helper and contributor ranks, character deletion.",
    commands: HEAD,
  },
  {
    id: "manager",
    level: ADMIN_LVL.MANAGER,
    blurb:
      "Spoof and testing tools for drugs, weapons, Fear and Respect, plus forced paychecks.",
    commands: MANAGER,
  },
  {
    id: "developer",
    level: ADMIN_LVL.DEVELOPER,
    blurb: "Direct money and password control and RCON-only debug commands.",
    commands: DEVELOPER,
  },
];
