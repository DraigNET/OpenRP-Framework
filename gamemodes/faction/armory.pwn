// ============================================================================
// File: faction/armory.pwn
// Faction armory and lockers: /armory, /equipment, /kevlar and /duty let members take weapons
// and go on duty at a locker point; admins place lockers with /armoryplace and /reloadarmories.
// Weapons per faction come from the faction_armory_* tables.
// Commands: /equipment /armory /duty /kevlar /kevlaroff /armoryplace /reloadarmories /kev
// ============================================================================

#define MAX_FACTION_ARMORY_TYPES      (128)
#define MAX_FACTION_ARMORIES          (128)
#define MAX_FACTION_ARMORY_WEAPONS    (512)
#define MAX_ARMORY_DIALOG_WEAPONS     (64)
#define INVALID_ARMORY_ID             (-1)
#define ARMORY_RANGE                  (5.0)

static enum E_ARMORY_TYPE_DATA
{
	E_ARMORY_TYPE_SQLID,
	E_ARMORY_TYPE_FACTION_ID,
	E_ARMORY_TYPE_NAME[32],
	bool:E_ARMORY_TYPE_ENABLED,
	bool:E_ARMORY_TYPE_USED
}

static enum E_ARMORY_DATA
{
	E_ARMORY_SQLID,
	E_ARMORY_FACTION_ID,
	E_ARMORY_TYPE_ID,
	E_ARMORY_NAME[64],
	E_ARMORY_DESC[128],
	Float:E_ARMORY_X,
	Float:E_ARMORY_Y,
	Float:E_ARMORY_Z,
	E_ARMORY_INT,
	E_ARMORY_VW,
	E_ARMORY_SQUAD,    // 0 = general locker; otherwise only members of this squad can use it
	bool:E_ARMORY_ENABLED,
	DynamicText3D:E_ARMORY_LABEL,
	E_ARMORY_PICKUP,
	bool:E_ARMORY_USED
}

static enum E_ARMORY_WEAPON_DATA
{
	E_ARMORY_WEAPON_SQLID,
	E_ARMORY_WEAPON_FACTION_ID,
	E_ARMORY_WEAPON_TYPE_ID,
	E_ARMORY_WEAPON_ID,
	E_ARMORY_WEAPON_AMMO,
	E_ARMORY_WEAPON_TIER,
	E_ARMORY_WEAPON_SQUAD,
	bool:E_ARMORY_WEAPON_OFF_DUTY,
	bool:E_ARMORY_WEAPON_ENABLED,
	E_ARMORY_WEAPON_SORT,
	bool:E_ARMORY_WEAPON_USED
}

static ArmoryType[MAX_FACTION_ARMORY_TYPES][E_ARMORY_TYPE_DATA];
static Armory[MAX_FACTION_ARMORIES][E_ARMORY_DATA];
static ArmoryWeapon[MAX_FACTION_ARMORY_WEAPONS][E_ARMORY_WEAPON_DATA];
static ArmoryDlgStr[2048];

// Clears one armory type slot.
static Armory_ResetType(index)
{
	ArmoryType[index][E_ARMORY_TYPE_SQLID] = INVALID_ARMORY_ID;
	ArmoryType[index][E_ARMORY_TYPE_FACTION_ID] = INVALID_FACTION_ID;
	ArmoryType[index][E_ARMORY_TYPE_NAME][0] = EOS;
	ArmoryType[index][E_ARMORY_TYPE_ENABLED] = false;
	ArmoryType[index][E_ARMORY_TYPE_USED] = false;
	return 1;
}

// Removes an armory's pickup and label from the world.
static Armory_ClearVisuals(index)
{
	if (IsValidDynamicPickup(Armory[index][E_ARMORY_PICKUP]))
	{
		DestroyDynamicPickup(Armory[index][E_ARMORY_PICKUP]);
	}
	Armory[index][E_ARMORY_PICKUP] = INVALID_STREAMER_ID;

	if (IsValidDynamic3DTextLabel(Armory[index][E_ARMORY_LABEL]))
	{
		DestroyDynamic3DTextLabel(Armory[index][E_ARMORY_LABEL]);
	}
	Armory[index][E_ARMORY_LABEL] = DynamicText3D:INVALID_STREAMER_ID;
	return 1;
}

// Clears one armory (locker) slot.
static Armory_Reset(index)
{
	Armory_ClearVisuals(index);

	Armory[index][E_ARMORY_SQLID] = INVALID_ARMORY_ID;
	Armory[index][E_ARMORY_FACTION_ID] = INVALID_FACTION_ID;
	Armory[index][E_ARMORY_TYPE_ID] = INVALID_ARMORY_ID;
	Armory[index][E_ARMORY_NAME][0] = EOS;
	Armory[index][E_ARMORY_DESC][0] = EOS;
	Armory[index][E_ARMORY_X] = 0.0;
	Armory[index][E_ARMORY_Y] = 0.0;
	Armory[index][E_ARMORY_Z] = 0.0;
	Armory[index][E_ARMORY_INT] = 0;
	Armory[index][E_ARMORY_VW] = 0;
	Armory[index][E_ARMORY_SQUAD] = 0;
	Armory[index][E_ARMORY_ENABLED] = false;
	Armory[index][E_ARMORY_USED] = false;
	return 1;
}

// Clears one armory weapon slot.
static Armory_ResetWeapon(index)
{
	ArmoryWeapon[index][E_ARMORY_WEAPON_SQLID] = INVALID_ARMORY_ID;
	ArmoryWeapon[index][E_ARMORY_WEAPON_FACTION_ID] = INVALID_FACTION_ID;
	ArmoryWeapon[index][E_ARMORY_WEAPON_TYPE_ID] = 0;
	ArmoryWeapon[index][E_ARMORY_WEAPON_ID] = 0;
	ArmoryWeapon[index][E_ARMORY_WEAPON_AMMO] = 0;
	ArmoryWeapon[index][E_ARMORY_WEAPON_TIER] = 0;
	ArmoryWeapon[index][E_ARMORY_WEAPON_SQUAD] = 0;
	ArmoryWeapon[index][E_ARMORY_WEAPON_OFF_DUTY] = false;
	ArmoryWeapon[index][E_ARMORY_WEAPON_ENABLED] = false;
	ArmoryWeapon[index][E_ARMORY_WEAPON_SORT] = 0;
	ArmoryWeapon[index][E_ARMORY_WEAPON_USED] = false;
	return 1;
}

// Returns the first free armory type slot.
static Armory_GetFreeTypeSlot()
{
	for (new i = 0; i < MAX_FACTION_ARMORY_TYPES; i ++)
	{
		if (!ArmoryType[i][E_ARMORY_TYPE_USED]) return i;
	}
	return INVALID_ARMORY_ID;
}

// Returns the first free armory slot.
static Armory_GetFreeSlot()
{
	for (new i = 0; i < MAX_FACTION_ARMORIES; i ++)
	{
		if (!Armory[i][E_ARMORY_USED]) return i;
	}
	return INVALID_ARMORY_ID;
}

// Returns the first free armory weapon slot.
static Armory_GetFreeWeaponSlot()
{
	for (new i = 0; i < MAX_FACTION_ARMORY_WEAPONS; i ++)
	{
		if (!ArmoryWeapon[i][E_ARMORY_WEAPON_USED]) return i;
	}
	return INVALID_ARMORY_ID;
}

// Finds an armory type slot by its database id.
static Armory_GetTypeSlot(type_sqlid)
{
	for (new i = 0; i < MAX_FACTION_ARMORY_TYPES; i ++)
	{
		if (ArmoryType[i][E_ARMORY_TYPE_USED] && ArmoryType[i][E_ARMORY_TYPE_SQLID] == type_sqlid)
		{
			return i;
		}
	}
	return INVALID_ARMORY_ID;
}

// Finds an armory slot by its database id.
static Armory_GetSlotByDBID(armory_sqlid)
{
	for (new i = 0; i < MAX_FACTION_ARMORIES; i ++)
	{
		if (Armory[i][E_ARMORY_USED] && Armory[i][E_ARMORY_SQLID] == armory_sqlid)
		{
			return i;
		}
	}
	return INVALID_ARMORY_ID;
}

// Writes the name of an armory type into name.
static Armory_GetTypeName(type_sqlid, name[], len = sizeof(name))
{
	new type_index = Armory_GetTypeSlot(type_sqlid);
	if (type_index == INVALID_ARMORY_ID)
	{
		format(name, len, "Unknown");
		return 0;
	}

	format(name, len, "%s", ArmoryType[type_index][E_ARMORY_TYPE_NAME]);
	return 1;
}

// Writes the name of a faction into name for armory messages.
static Armory_GetFactionName(faction_sqlid, name[], len = sizeof(name))
{
	new faction_enum_id = Faction_GetEnumID(faction_sqlid);
	if (faction_enum_id == INVALID_FACTION_ID)
	{
		format(name, len, "Faction %d", faction_sqlid);
		return 0;
	}

	format(name, len, "%s", Faction[faction_enum_id][E_FACTION_ABBREV]);
	return 1;
}

// Creates the pickup and label for an armory.
static Armory_SetVisuals(index)
{
	Armory_ClearVisuals(index);

	if (!Armory[index][E_ARMORY_USED] || !Armory[index][E_ARMORY_ENABLED])
	{
		return 1;
	}

	new label[256], faction_name[64], type_name[32];
	Armory_GetFactionName(Armory[index][E_ARMORY_FACTION_ID], faction_name, sizeof(faction_name));
	Armory_GetTypeName(Armory[index][E_ARMORY_TYPE_ID], type_name, sizeof(type_name));

	format(label, sizeof(label), "[%d][%s]\n{DEDEDE}%s %s", Armory[index][E_ARMORY_SQLID], Armory[index][E_ARMORY_NAME], faction_name, type_name);

	if (strlen(Armory[index][E_ARMORY_DESC]))
	{
		format(label, sizeof(label), "%s\n%s", label, Armory[index][E_ARMORY_DESC]);
	}

	Armory[index][E_ARMORY_LABEL] = CreateDynamic3DTextLabel(label, 0x3479E3FF,
		Armory[index][E_ARMORY_X], Armory[index][E_ARMORY_Y], Armory[index][E_ARMORY_Z],
		15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1,
		Armory[index][E_ARMORY_VW], Armory[index][E_ARMORY_INT]);

	Armory[index][E_ARMORY_PICKUP] = CreateDynamicPickup(1275, 1,
		Armory[index][E_ARMORY_X], Armory[index][E_ARMORY_Y], Armory[index][E_ARMORY_Z],
		Armory[index][E_ARMORY_VW], Armory[index][E_ARMORY_INT]);

	return 1;
}

// Stores an armory type loaded from the database.
static Armory_RegisterType(sqlid, faction_id, const name[], enabled)
{
	new index = Armory_GetFreeTypeSlot();
	if (index == INVALID_ARMORY_ID)
	{
		printf(" * [ARMORY] ERROR: No free armory type slot for SQL ID %d.", sqlid);
		return INVALID_ARMORY_ID;
	}

	ArmoryType[index][E_ARMORY_TYPE_SQLID] = sqlid;
	ArmoryType[index][E_ARMORY_TYPE_FACTION_ID] = faction_id;
	format(ArmoryType[index][E_ARMORY_TYPE_NAME], 32, "%s", name);
	ArmoryType[index][E_ARMORY_TYPE_ENABLED] = bool:enabled;
	ArmoryType[index][E_ARMORY_TYPE_USED] = true;
	return index;
}

// Stores an armory (locker) loaded from the database.
static Armory_Register(sqlid, faction_id, type_id, const name[], const desc[], Float:x, Float:y, Float:z, interior, virtualworld, enabled, squad = 0)
{
	new index = Armory_GetFreeSlot();
	if (index == INVALID_ARMORY_ID)
	{
		printf(" * [ARMORY] ERROR: No free armory slot for SQL ID %d.", sqlid);
		return INVALID_ARMORY_ID;
	}

	Armory[index][E_ARMORY_SQLID] = sqlid;
	Armory[index][E_ARMORY_FACTION_ID] = faction_id;
	Armory[index][E_ARMORY_TYPE_ID] = type_id;
	format(Armory[index][E_ARMORY_NAME], 64, "%s", name);
	format(Armory[index][E_ARMORY_DESC], 128, "%s", desc);
	Armory[index][E_ARMORY_X] = x;
	Armory[index][E_ARMORY_Y] = y;
	Armory[index][E_ARMORY_Z] = z;
	Armory[index][E_ARMORY_INT] = interior;
	Armory[index][E_ARMORY_VW] = virtualworld;
	Armory[index][E_ARMORY_SQUAD] = squad;
	Armory[index][E_ARMORY_ENABLED] = bool:enabled;
	Armory[index][E_ARMORY_USED] = true;
	Armory[index][E_ARMORY_LABEL] = DynamicText3D:INVALID_STREAMER_ID;
	Armory[index][E_ARMORY_PICKUP] = INVALID_STREAMER_ID;

	Armory_SetVisuals(index);
	return index;
}

// Stores an armory weapon loaded from the database.
static Armory_RegisterWeapon(sqlid, faction_id, type_id, weapon_id, ammo, tier, squad, off_duty, enabled, sort_order)
{
	new index = Armory_GetFreeWeaponSlot();
	if (index == INVALID_ARMORY_ID)
	{
		printf(" * [ARMORY] ERROR: No free armory weapon slot for SQL ID %d.", sqlid);
		return INVALID_ARMORY_ID;
	}

	ArmoryWeapon[index][E_ARMORY_WEAPON_SQLID] = sqlid;
	ArmoryWeapon[index][E_ARMORY_WEAPON_FACTION_ID] = faction_id;
	ArmoryWeapon[index][E_ARMORY_WEAPON_TYPE_ID] = type_id;
	ArmoryWeapon[index][E_ARMORY_WEAPON_ID] = weapon_id;
	ArmoryWeapon[index][E_ARMORY_WEAPON_AMMO] = ammo;
	ArmoryWeapon[index][E_ARMORY_WEAPON_TIER] = tier;
	ArmoryWeapon[index][E_ARMORY_WEAPON_SQUAD] = squad;
	ArmoryWeapon[index][E_ARMORY_WEAPON_OFF_DUTY] = bool:off_duty;
	ArmoryWeapon[index][E_ARMORY_WEAPON_ENABLED] = bool:enabled;
	ArmoryWeapon[index][E_ARMORY_WEAPON_SORT] = sort_order;
	ArmoryWeapon[index][E_ARMORY_WEAPON_USED] = true;
	return index;
}

// Loads all faction armory types, lockers and weapons from the database.
Armory_LoadEntities()
{
	for (new i = 0; i < MAX_FACTION_ARMORY_TYPES; i ++) Armory_ResetType(i);
	for (new i = 0; i < MAX_FACTION_ARMORIES; i ++) Armory_Reset(i);
	for (new i = 0; i < MAX_FACTION_ARMORY_WEAPONS; i ++) Armory_ResetWeapon(i);

	print(" * [ARMORY] Loading all armory types, locations and weapons...");

	inline ArmoryWeapons_OnLoad()
	{
		for (new i = 0, r = cache_num_rows(); i < r; ++i)
		{
			new sqlid, faction_id, type_id, weapon_id, ammo, tier, squad, off_duty, enabled, sort_order;
			cache_get_value_name_int(i, "armory_weapon_id", sqlid);
			cache_get_value_name_int(i, "faction_id", faction_id);
			cache_get_value_name_int(i, "armory_type_id", type_id);
			cache_get_value_name_int(i, "weapon_id", weapon_id);
			cache_get_value_name_int(i, "weapon_ammo", ammo);
			cache_get_value_name_int(i, "tier_limit", tier);
			cache_get_value_name_int(i, "squad_id", squad);
			cache_get_value_name_int(i, "off_duty_allowed", off_duty);
			cache_get_value_name_int(i, "weapon_enabled", enabled);
			cache_get_value_name_int(i, "sort_order", sort_order);

			Armory_RegisterWeapon(sqlid, faction_id, type_id, weapon_id, ammo, tier, squad, off_duty, enabled, sort_order);
		}

		printf(" * [ARMORY] Loaded %d armory weapon row(s).", cache_num_rows());
	}

	inline Armories_OnLoad()
	{
		for (new i = 0, r = cache_num_rows(); i < r; ++i)
		{
			new sqlid, faction_id, type_id, interior, virtualworld, enabled, squad;
			new name[64], desc[128];
			new Float:x, Float:y, Float:z;

			cache_get_value_name_int(i, "armory_id", sqlid);
			cache_get_value_name_int(i, "faction_id", faction_id);
			cache_get_value_name_int(i, "armory_type_id", type_id);
			cache_get_value_name(i, "armory_name", name);
			cache_get_value_name(i, "armory_desc", desc);
			cache_get_value_name_float(i, "armory_x", x);
			cache_get_value_name_float(i, "armory_y", y);
			cache_get_value_name_float(i, "armory_z", z);
			cache_get_value_name_int(i, "armory_int", interior);
			cache_get_value_name_int(i, "armory_vw", virtualworld);
			cache_get_value_name_int(i, "armory_enabled", enabled);

			// armory_squad comes from the schema. If the column isn't there yet squad stays 0.
			squad = 0;
			cache_get_value_name_int(i, "armory_squad", squad);

			Armory_Register(sqlid, faction_id, type_id, name, desc, x, y, z, interior, virtualworld, enabled, squad);
		}

		printf(" * [ARMORY] Loaded %d armory location(s).", cache_num_rows());

		MySQL_TQueryInline(mysql, using inline ArmoryWeapons_OnLoad,
			"SELECT armory_weapon_id, faction_id, IFNULL(armory_type_id, 0) AS armory_type_id, weapon_id, weapon_ammo, tier_limit, squad_id, off_duty_allowed, weapon_enabled, sort_order FROM faction_armory_weapons ORDER BY faction_id, IFNULL(armory_type_id, 0), sort_order, armory_weapon_id", "");
	}

	inline ArmoryTypes_OnLoad()
	{
		for (new i = 0, r = cache_num_rows(); i < r; ++i)
		{
			new sqlid, faction_id, enabled, name[32];
			cache_get_value_name_int(i, "armory_type_id", sqlid);
			cache_get_value_name_int(i, "faction_id", faction_id);
			cache_get_value_name(i, "type_name", name);
			cache_get_value_name_int(i, "type_enabled", enabled);

			Armory_RegisterType(sqlid, faction_id, name, enabled);
		}

		printf(" * [ARMORY] Loaded %d armory type(s).", cache_num_rows());

		MySQL_TQueryInline(mysql, using inline Armories_OnLoad,
			"SELECT * FROM faction_armories ORDER BY armory_id", "");
	}

	MySQL_TQueryInline(mysql, using inline ArmoryTypes_OnLoad,
		"SELECT armory_type_id, faction_id, type_name, type_enabled FROM faction_armory_types ORDER BY faction_id, type_name", "");

	return 1;
}

// Locker squad rule. A locker with a squad is for that squad only; a general
// (squad 0) locker is closed to full-time fire/EMT, who use fire lockers only.
static bool:Armory_PlayerCanAccess(playerid, index)
{
	if (Armory[index][E_ARMORY_FACTION_ID] != Character[playerid][E_CHARACTER_FACTIONID])
	{
		return false;
	}

	new squad = Armory[index][E_ARMORY_SQUAD];

	if (squad)
	{
		return IsPlayerInFactionSquad(playerid, squad) != 0;
	}

	return true;
}

// Index of the locker the player is standing at AND may use, or INVALID_ARMORY_ID.
static Armory_GetUsable(playerid)
{
	new vw = GetPlayerVirtualWorld(playerid);
	new int = GetPlayerInterior(playerid);

	for (new i = 0; i < MAX_FACTION_ARMORIES; i ++)
	{
		if (!Armory[i][E_ARMORY_USED] || !Armory[i][E_ARMORY_ENABLED]) continue;
		if (!IsPlayerInRangeOfPoint(playerid, ARMORY_RANGE, Armory[i][E_ARMORY_X], Armory[i][E_ARMORY_Y], Armory[i][E_ARMORY_Z])) continue;
		if (Armory[i][E_ARMORY_INT] != -1 && int != Armory[i][E_ARMORY_INT]) continue;
		if (Armory[i][E_ARMORY_VW] != -1 && vw != Armory[i][E_ARMORY_VW]) continue;
		if (!Armory_PlayerCanAccess(playerid, i)) continue;

		return i;
	}

	return INVALID_ARMORY_ID;
}

// Locker type (faction_armory_types id) of the usable locker the player is at,
// or 0 if they are not at one. Per-locker uniforms are filtered by this.
Armory_GetPlayerLockerType(playerid)
{
	new k = Armory_GetUsable(playerid);
	if (k == INVALID_ARMORY_ID) return 0;

	return Armory[k][E_ARMORY_TYPE_ID];
}

// Returns true if the player is standing at an armory (kiosk) inside the right world.
IsAtKisok(playerid)
{
	new vw = GetPlayerVirtualWorld(playerid);
	new int = GetPlayerInterior(playerid);

	for (new i = 0; i < MAX_FACTION_ARMORIES; i ++)
	{
		if (!Armory[i][E_ARMORY_USED] || !Armory[i][E_ARMORY_ENABLED]) continue;

		if (IsPlayerInRangeOfPoint(playerid, ARMORY_RANGE, Armory[i][E_ARMORY_X], Armory[i][E_ARMORY_Y], Armory[i][E_ARMORY_Z]))
		{
			if (Armory[i][E_ARMORY_INT] != -1 && int != Armory[i][E_ARMORY_INT]) return INVALID_ARMORY_ID;
			if (Armory[i][E_ARMORY_VW] != -1 && vw != Armory[i][E_ARMORY_VW]) return INVALID_ARMORY_ID;

			return i;
		}
	}

	return INVALID_ARMORY_ID;
}

// Returns true if the player is allowed to take a given weapon (faction, tier, squad, duty).
static bool:Armory_PlayerCanSeeWeapon(playerid, armory_index, weapon_index)
{
	if (!ArmoryWeapon[weapon_index][E_ARMORY_WEAPON_USED]) return false;
	if (!ArmoryWeapon[weapon_index][E_ARMORY_WEAPON_ENABLED]) return false;
	if (ArmoryWeapon[weapon_index][E_ARMORY_WEAPON_FACTION_ID] != Character[playerid][E_CHARACTER_FACTIONID]) return false;

	new weapon_type = ArmoryWeapon[weapon_index][E_ARMORY_WEAPON_TYPE_ID];
	if (weapon_type && weapon_type != Armory[armory_index][E_ARMORY_TYPE_ID]) return false;

	return true;
}

CMD:equipment(playerid)
{
	return cmd_armory(playerid);
}

// /armory - opens the weapon menu at a faction locker. You must be on duty unless the weapon
// allows off duty.
CMD:armory(playerid)
{
	new factionid = Character[playerid][E_CHARACTER_FACTIONID];
	new faction_enum_id = Faction_GetEnumID(factionid);

	if (!factionid || faction_enum_id == INVALID_FACTION_ID)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction.");
	}

	new k = Armory_GetUsable(playerid);
	if (k == INVALID_ARMORY_ID)
	{
		k = IsAtKisok(playerid);
	}

	if (k == INVALID_ARMORY_ID)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near any faction kiosk.");
	}
	else if (Armory[k][E_ARMORY_FACTION_ID] != factionid)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use this kiosk.");
	}
	else if (!Armory_PlayerCanAccess(playerid, k))
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This locker is restricted to a different department or squad.");
	}

	if (GetPlayerFactionSuspension(playerid))
	{
		Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s tried to use the armory while suspended. }", Faction[faction_enum_id][E_FACTION_ABBREV], playerid, ReturnRPName(playerid)), faction_enum_id, false);
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't access this because you're currently suspended from the faction.");
	}

	new gun_name[32];
	new count, map[MAX_ARMORY_DIALOG_WEAPONS];

	inline Armory_Selection(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, listitem, inputtext

		if (response)
		{
			new index = map[listitem];

			if (!Armory_PlayerCanSeeWeapon(playerid, k, index))
			{
				return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This equipment is no longer available here.");
			}

			if (ArmoryWeapon[index][E_ARMORY_WEAPON_TIER] && (Character[playerid][E_CHARACTER_FACTIONTIER] > ArmoryWeapon[index][E_ARMORY_WEAPON_TIER]))
			{
				return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not a high enough tier of employee to take this.");
			}

			if (ArmoryWeapon[index][E_ARMORY_WEAPON_SQUAD] && !IsPlayerInFactionSquad(playerid, ArmoryWeapon[index][E_ARMORY_WEAPON_SQUAD]))
			{
				return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in the necessary faction squad or division to take this.");
			}

			if (!ArmoryWeapon[index][E_ARMORY_WEAPON_OFF_DUTY] && !PlayerVar[playerid][E_PLAYER_FACTION_DUTY])
			{
				return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be on duty to take this.");
			}

			{
				Weapon_GetGunName(ArmoryWeapon[index][E_ARMORY_WEAPON_ID], gun_name, sizeof(gun_name));
				GiveCustomWeapon(playerid, ArmoryWeapon[index][E_ARMORY_WEAPON_ID], ArmoryWeapon[index][E_ARMORY_WEAPON_AMMO]);
			}
		}
	}

	format(ArmoryDlgStr, sizeof(ArmoryDlgStr), "Weapon\tTier Limit");
	for (new i = 0; i < MAX_FACTION_ARMORY_WEAPONS; i ++)
	{
		if (!Armory_PlayerCanSeeWeapon(playerid, k, i)) continue;

		Weapon_GetGunName(ArmoryWeapon[i][E_ARMORY_WEAPON_ID], gun_name, sizeof(gun_name));
		format(ArmoryDlgStr, sizeof(ArmoryDlgStr), "%s\n%s\tTier %d", ArmoryDlgStr, gun_name, ArmoryWeapon[i][E_ARMORY_WEAPON_TIER]);

		map[count] = i;
		count ++;
		if (count >= MAX_ARMORY_DIALOG_WEAPONS) break;
	}

	if (!count)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Armory", "A3A3A3", "There is no equipment configured for this armory.");
	}

	Dialog_ShowCallback(playerid, using inline Armory_Selection, DIALOG_STYLE_TABLIST_HEADERS, Armory[k][E_ARMORY_NAME], ArmoryDlgStr, "Take", "Close");
	return 1;
}

// /duty - goes on or off faction duty at a locker or in a faction vehicle.
CMD:duty(playerid)
{
	if (!IsPlayerInDutyFaction(playerid))
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction that can go on or off duty.");
	}

	new vehicleid = INVALID_VEHICLE_ID;

	if (!IsPlayerNearArmory(playerid))
	{
		if (PlayerVar[playerid][E_PLAYER_FACTION_DUTY])
		{
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only go off duty at a faction armory.");
		}

		vehicleid = GetClosestVehicleEx(playerid, 7.5);

		if (vehicleid == INVALID_VEHICLE_ID || !IsFactionVehicle(vehicleid, Character[playerid][E_CHARACTER_FACTIONID]))
		{
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not at a faction armory or vehicle.");
		}
	}

	new factionid = Character[playerid][E_CHARACTER_FACTIONID];
	new faction_enum_id = Faction_GetEnumID(factionid);
	new string[144];
	new suspension = GetPlayerFactionSuspension(playerid);

	if (PlayerVar[playerid][E_PLAYER_FACTION_DUTY])
	{
		PlayerVar[playerid][E_PLAYER_FACTION_DUTY] = false;

		new query[256];
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_on_duty = %d WHERE player_id = %d",
			PlayerVar[playerid][E_PLAYER_FACTION_DUTY], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);

		if (GetCharacterArmour(playerid) != 0)
		{
			SetCharacterArmour(playerid, 0);
		}

		if (IsPlayerInLEAFaction(playerid))
		{
			Weapon_ResetPlayerWeapons(playerid);
		}
		else
		{
			for (new i = 0; i < MAX_FACTION_ARMORY_WEAPONS; i ++)
			{
				if (!ArmoryWeapon[i][E_ARMORY_WEAPON_USED]) continue;
				if (ArmoryWeapon[i][E_ARMORY_WEAPON_FACTION_ID] != factionid) continue;
				RemovePlayerCustomWeapon(playerid, ArmoryWeapon[i][E_ARMORY_WEAPON_ID]);
			}
		}

		if (PlayerVar[playerid][E_PLAYER_TASER_EQUIPPED])
		{
			RemovePlayerCustomWeapon(playerid, 65);
			PlayerVar[playerid][E_PLAYER_TASER_EQUIPPED] = false;
		}

		format(string, sizeof(string), "has gone off duty");
	}
	else
	{
		if (suspension && factionid && faction_enum_id)
		{
			Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s tried to go on duty while suspended. }", Faction[faction_enum_id][E_FACTION_ABBREV], playerid, ReturnRPName(playerid)), faction_enum_id, false);
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't do this because you're currently suspended from the faction.");
		}

		PlayerVar[playerid][E_PLAYER_FACTION_DUTY] = true;
		new query[256];
		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_on_duty = %d WHERE player_id = %d",
			PlayerVar[playerid][E_PLAYER_FACTION_DUTY], Character[playerid][E_CHARACTER_ID]);
		mysql_tquery(mysql, query);

		if (vehicleid != INVALID_VEHICLE_ID)
		{
			format(string, sizeof(string), "has gone on duty at a \"%s\" (%d)", ReturnVehicleName(vehicleid), vehicleid);
		}
		else
		{
			format(string, sizeof(string), "has gone on duty");
		}

	}

	CallLocalFunction("ORP_OnDutyStateChange", "d", playerid);

	SetCharacterHealth(playerid, 100);
	Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s %s. }",
		Faction[faction_enum_id][E_FACTION_ABBREV], playerid, ReturnRPName(playerid), string), faction_enum_id, false);

	return 1;
}

// /kevlar - puts on body armour from the faction (law enforcement, security and some government
// squads).
CMD:kevlar(playerid, params[])
{
    if (!IsPlayerInLEAFaction(playerid, true)
        && !IsPlayerInSecurityFaction(playerid, true)
        && !IsPlayerInFactionSquad(playerid, FACTION_SQUAD_GOV_DAI, FACTION_TYPE_GOV, true))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "You're not on duty in a faction that has kevlar.");
    }

    if (Character[playerid][E_CHARACTER_FACTIONTIER] > 3)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "You're not a high enough tier of employee to do this.");
    }

    if (!IsPlayerNearArmory(playerid))
    {
        if (IsPlayerInAnyVehicle(playerid))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
                "You can't do this while in a car, get out first.");
        }

        new vehicleid = GetClosestVehicleEx(playerid, 7.5);
        if (vehicleid == INVALID_VEHICLE_ID)
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "You're not near the locker room or a faction vehicle trunk!");
        }

        if (IsAircraft(vehicleid) || IsABoat(vehicleid) || IsABike(vehicleid)
            || !IsFactionVehicle(vehicleid, Character[playerid][E_CHARACTER_FACTIONID]))
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "This vehicle doesn't have a trunk or isn't a faction car!");
        }

        new Float:x, Float:y, Float:z;
        GetPosBehindVehicle(vehicleid, x, y, z);

        if (!IsPlayerInRangeOfPoint(playerid, 2.5, x, y, z))
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "You can only do this standing at the trunk (rear) of the vehicle.");
        }

        if (!GetTrunkStatus(vehicleid))
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "The vehicle trunk is closed, open it first (/cartrunk).");
        }

		if (Character[playerid][E_CHARACTER_RECENT_DAMAGE] > gettime()) {
			new cdStr[16];
			FormatCooldownTime(Character[playerid][E_CHARACTER_RECENT_DAMAGE] - gettime(), cdStr, sizeof(cdStr));
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("You've recently taken damage and can't equip kevlar for another %s.", cdStr));
		}
    }

    SetCharacterHealth(playerid, 100);
    SetCharacterArmour(playerid, 100);

    SendServerMessage(playerid, COLOR_POLICE, "Kevlar", "A3A3A3",
        "You equipped kevlar.");

    return 1;
}

// /kevlaroff - takes off body armour.
CMD:kevlaroff(playerid, params[])
{
    if (!IsPlayerInLEAFaction(playerid, true)
        && !IsPlayerInSecurityFaction(playerid, true)
        && !IsPlayerInFactionSquad(playerid, FACTION_SQUAD_GOV_DAI, FACTION_TYPE_GOV, true))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "You're not on duty in a faction that has kevlar.");
    }

    if (Character[playerid][E_CHARACTER_FACTIONTIER] > 3)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "You're not a high enough tier of employee to do this.");
    }

    if (!IsPlayerNearArmory(playerid))
    {
        if (IsPlayerInAnyVehicle(playerid))
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
                "You can't do this while in a car, get out first.");
        }

        new vehicleid = GetClosestVehicleEx(playerid, 7.5);
        if (vehicleid == INVALID_VEHICLE_ID)
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "You're not near the locker room or a faction vehicle trunk!");
        }

        if (IsAircraft(vehicleid) || IsABoat(vehicleid) || IsABike(vehicleid)
            || !IsFactionVehicle(vehicleid, Character[playerid][E_CHARACTER_FACTIONID]))
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "This vehicle doesn't have a trunk or isn't a faction car!");
        }

        new Float:x, Float:y, Float:z;
        GetPosBehindVehicle(vehicleid, x, y, z);

        if (!IsPlayerInRangeOfPoint(playerid, 2.5, x, y, z))
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "You can only do this standing at the trunk (rear) of the vehicle.");
        }

        if (!GetTrunkStatus(vehicleid))
        {
            return SendClientMessage(playerid, COLOR_ERROR,
                "The vehicle trunk is closed, open it first (/cartrunk).");
        }
    }

    SetCharacterHealth(playerid, 100);
    SetCharacterArmour(playerid, 0);

    SendServerMessage(playerid, COLOR_POLICE, "Kevlar", "A3A3A3",
        "You placed your kevlar back into the locker.");

    return 1;
}

// Returns true if the player is near their faction's armory.
IsPlayerNearArmory(playerid)
{
	new factionid = Character[playerid][E_CHARACTER_FACTIONID];
	if (!factionid) return false;

	new faction_enum_id = Faction_GetEnumID(factionid);
	if (faction_enum_id == INVALID_FACTION_ID) return false;

	// Only a locker this player is actually allowed to use counts.
	return Armory_GetUsable(playerid) != INVALID_ARMORY_ID;
}

// /armoryplace [armory db id] - (admin) moves an armory locker to your position.
CMD:armoryplace(playerid, params[])
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
	}

	new armory_sqlid;
	if (sscanf(params, "i", armory_sqlid))
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/armoryplace [armory db id]");
	}

	new index = Armory_GetSlotByDBID(armory_sqlid);
	if (index == INVALID_ARMORY_ID)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Armory", "A3A3A3", "Invalid armory DB ID.");
	}

	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	Armory[index][E_ARMORY_X] = x;
	Armory[index][E_ARMORY_Y] = y;
	Armory[index][E_ARMORY_Z] = z;
	Armory[index][E_ARMORY_INT] = GetPlayerInterior(playerid);
	Armory[index][E_ARMORY_VW] = GetPlayerVirtualWorld(playerid);
	Armory_SetVisuals(index);

	new query[256];
	mysql_format(mysql, query, sizeof(query),
		"UPDATE faction_armories SET armory_x = %.4f, armory_y = %.4f, armory_z = %.4f, armory_int = %d, armory_vw = %d WHERE armory_id = %d",
		Armory[index][E_ARMORY_X], Armory[index][E_ARMORY_Y], Armory[index][E_ARMORY_Z],
		Armory[index][E_ARMORY_INT], Armory[index][E_ARMORY_VW], armory_sqlid);
	mysql_tquery(mysql, query);

	SendServerMessage(playerid, COLOR_INFO, "Armory", "A3A3A3", sprintf("Placed armory #%d at your position.", armory_sqlid));
	if (!Armory[index][E_ARMORY_ENABLED])
	{
		SendClientMessage(playerid, COLOR_YELLOW, "This armory is currently disabled in the ACP, so it will not appear until enabled.");
	}

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Placed armory #%d at %.2f, %.2f, %.2f", armory_sqlid, Armory[index][E_ARMORY_X], Armory[index][E_ARMORY_Y], Armory[index][E_ARMORY_Z]));
	return 1;
}

// /reloadarmories - (admin) reloads armory types, lockers and weapons from the database.
CMD:reloadarmories(playerid, params[])
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
	}

	Armory_LoadEntities();
	SendServerMessage(playerid, COLOR_INFO, "Armory", "A3A3A3", "Reloading armory types, locations and weapons from the database.");
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, "Reloaded faction armories from the database");
	return 1;
}

forward ORP_OnDutyStateChange(playerid);
// Hook point that runs when a player's duty state changes.
public ORP_OnDutyStateChange(playerid)
{
	// Hook this
	printf("ORP_OnDutyStateChange: %d", playerid);
	return 1;
}

CMD:kev(playerid, params[])
{
	return cmd_kevlar(playerid, params);
}

// Returns the price a faction pays per weapon type for pricing the armory.
stock Armory_GetGunPrice(weapon)
{
	new gun_cost;

	switch (weapon)
	{
		case 1 .. 8: 	gun_cost = 25;
		case 9:	 		gun_cost = 50;
		case 10 .. 15: 	gun_cost = 20;
		case 16 .. 18: 	gun_cost = 125;
		case 22 .. 23: 	gun_cost = 150;
		case 24: 		gun_cost = 250;
		case 25: 		gun_cost = 300;
		case 26: 		gun_cost = 325;
		case 27: 		gun_cost = 350;
		case 28: 		gun_cost = 250;
		case 29:		gun_cost = 275;
		case 30: 		gun_cost = 500;
		case 31: 		gun_cost = 750;
		case 32: 		gun_cost = 225;
		case 33: 		gun_cost = 800;
		case 34: 		gun_cost = 1000;
		default: 		gun_cost = 25;
	}

	return gun_cost;
}
