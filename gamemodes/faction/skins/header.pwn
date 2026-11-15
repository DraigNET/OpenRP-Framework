// ============================================================================
// File: faction/skins/header.pwn
// Faction uniforms. Lists the skins a faction member may wear at a locker (/uniform, /fskins)
// and lets leaders add or remove them (/factionskinadd, /fskindel, /reloadfskins). Stock skins
// only.
// Commands: /fskins /uniform /factionskinadd /fskinadd /reloadfskins /fskindel
// ============================================================================

enum E_FACTION_SKIN_DATA {

	E_FACTION_SKIN_ID,
	E_FACTION_SKIN_FACTIONID,
	E_FACTION_SKIN_SKINID,
	E_FACTION_SKIN_TIER,
	E_FACTION_SKIN_SQUAD,
	E_FACTION_SKIN_ARMORY_TYPE   // locker type (faction_armory_types id) this uniform is offered at; 0 = every locker
} ;

#if !defined MAX_FACTION_SKINS
	#define MAX_FACTION_SKINS 150
#endif

#if !defined INVALID_FACTION_SKIN_ID
	#define INVALID_FACTION_SKIN_ID -1
#endif

new FactionSkin [ MAX_FACTIONS ] [ MAX_FACTION_SKINS ] [ E_FACTION_SKIN_DATA ] ;

// Callback of the uniform browser: puts the chosen uniform on the player.
mBrowser:fskin_list(playerid, response, row, model, name[]) {

	if ( response ) 
	{
		SetPlayerSkinEx(playerid, model);
	}

	return true ;
}

// Is this uniform offered at the given locker type? A skin with no locker type
// shows everywhere; a typed skin only at that locker type. locker_type < 0 skips the check.
static bool:FactionSkin_AtLocker(faction_enum_id, index, locker_type)
{
	if (locker_type < 0) return true;

	new skin_type = FactionSkin [ faction_enum_id ] [ index ] [ E_FACTION_SKIN_ARMORY_TYPE ];
	return skin_type == 0 || skin_type == locker_type;
}

// For using elsewhere. locker_type: only offer skins for that locker type (-1 = don't filter).
ShowFactionSkinList(playerid, const title[64], const callback[64], squad, locker_type = -1)
{
	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	ModelBrowser_ClearData(playerid);
	new count = 0, skinid = INVALID_FACTION_SKIN_ID, skinsquad = 0;

	for ( new i, j = MAX_FACTION_SKINS ; i < j ; i ++ ) 
	{
		skinid = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ];

		if ( skinid != INVALID_FACTION_SKIN_ID && skinid != 0 ) 
		{
			if (!FactionSkin_AtLocker(faction_enum_id, i, locker_type))
			{
				// Not offered at this locker
				continue;
			}

			skinsquad = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SQUAD ];

			if (skinsquad && !IsPlayerInFactionSquad(playerid, squad) && Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] > 1)
			{
				// Don't show squad restricted skins
				continue;
			}

			if (squad && squad != skinsquad)
			{
				// Don't show non squad skins
				continue;
			}

			skinid = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SKINID ];
			ModelBrowser_AddData(playerid, skinid, Skin_GetName(skinid) ) ;
			count ++;
		}
	}

	ModelBrowser_SetupTiles(playerid, title, callback);
	return true;
}

// /fskins - opens the uniform browser for your faction's skins (or civilian skins).
CMD:fskins(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;
	//printf("Player faction ID: %d", factionid);

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 
	//printf("Faction enum ID: %d", faction_enum_id);

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	// Law enforcement and EMS have lockers, so their uniforms are only offered there.
	// The faction spawn point stays a valid place for factions without lockers (illegal etc).
	new bool:has_lockers = Faction_CanID(faction_enum_id, FAC_CAP_LAW) || Faction [ faction_enum_id ] [ E_FACTION_TYPE ] == FACTION_TYPE_EMS;
	new bool:near_spawn = !has_lockers && IsPlayerInRangeOfPoint(playerid, 5.0, Faction [ faction_enum_id ] [ E_FACTION_SPAWN_X ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Y ], Faction [ faction_enum_id ] [ E_FACTION_SPAWN_Z ] );

	if (!IsPlayerNearArmory(playerid) && !near_spawn)
	{
		if (has_lockers)
		{
			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only do this at one of your faction lockers!");
		}

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only do this at your faction spawn or armory!");
	}

	// Uniforms are per locker: offer this locker's type (0 = no locker, so only unrestricted skins).
	new locker_type = Armory_GetPlayerLockerType(playerid);

	ModelBrowser_ClearData(playerid);
	new skin_name [ 64 ], count = 0, skinid = INVALID_FACTION_SKIN_ID, squad = 0;

	if (!IsPlayerInDutyFaction(playerid) || PlayerVar [ playerid ] [ E_PLAYER_FACTION_DUTY ])
	{
		// faction skins
		for ( new i, j = MAX_FACTION_SKINS ; i < j ; i ++ ) 
		{
			skinid = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ];

			if ( skinid != INVALID_FACTION_SKIN_ID && skinid != 0 ) 
			{
				//printf("Found valid skin in slot %d", i);
				if (!FactionSkin_AtLocker(faction_enum_id, i, locker_type))
				{
					// Belongs to a different locker (e.g. sheriff uniforms at the fire locker)
					continue;
				}

				squad = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SQUAD ];

				if (squad && !IsPlayerInFactionSquad(playerid, squad) && Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] > 1)
				{
					// Don't show squad restricted skins
					continue;
				}

				//printf("Fskin YES: %d (SQL: %d), (faction: %d)", FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SKINID ], FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ], FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_FACTIONID ]);
				skinid = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SKINID ];
				ModelBrowser_AddData(playerid, skinid, Skin_GetName(skinid) ) ;
				count ++;
			}
		}

		format(skin_name, 64, "Faction Skins");
	}
	else
	{
		// civ skins
		for ( new i, j = 311 ; i < j ; i ++ ) 
		{
			if ( ! IsValidSkin ( i ) ) {

				continue ;
			}

			switch ( i ) {

				case // story char
				0, 4, 5, 6, 16, 61, 71, 86, 92, 99, 102, 103, 104, 105, 106, 107, 108, 109, 110, 
				114, 115, 116, 149, 155, 163, 164, 167, 173, 174, 175, 205, 208, 264, 265, 266, 267, 268, 269, 
				270, 271, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 
				285, 286, 287, 288, 292, 293, 294, 295, 297, 299, 300, 301, 302, 
				306, 307, 308, 309, 310, 311: {
				continue ;
				}
			}

			if (Character[playerid][E_CHARACTER_ATTRIB_SEX] != E_ATTRIBUTE_SEX_MALE && GetSkinGender(i) == SKIN_GENDER_MALE) continue;
			else if (Character[playerid][E_CHARACTER_ATTRIB_SEX] != E_ATTRIBUTE_SEX_FEMALE && GetSkinGender(i) == SKIN_GENDER_FEMALE) continue;

			GetSkinName(i, skin_name, sizeof ( skin_name ) ) ;
			ModelBrowser_AddData(playerid, i, skin_name ) ;
			count ++;
		}

		format(skin_name, 64, "Civilian Skins (Off Duty)");
	}
	
	if (!count)
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "There's no skins to show.");
	}

	ModelBrowser_SetupTiles(playerid, skin_name, "fskin_list" );
	return true ;
}

CMD:uniform(playerid, params[]) {

	return cmd_fskins(playerid, params);
}

CMD:factionskinadd(playerid, params[]) {

	return cmd_fskinadd(playerid, params);
}

// /fskinadd [skin] [tier] [squad] [locker type] - leaders add a uniform skin to their faction.
CMD:fskinadd(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}


	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	if (Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] > 1 ) {
		// 1 : owner, 2: command, 3 : member

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have permission to do this.");
	}
  
	new skinid, tier, squad, locker_type;

	if ( sscanf ( params, "iiI(0)I(0)", skinid, tier, squad, locker_type ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/fskinadd [skin] [tier] [squad (0)] [locker type id (0 = every locker)]");
	}

	FactionSkin_Create(playerid, faction_enum_id, skinid, tier, squad, locker_type);

	return true ;
}


// Returns the first free uniform slot of a faction.
FactionSkin_GetFreeID(factionid) {

	for ( new i; i < MAX_FACTION_SKINS; i ++ ) {

		if ( FactionSkin [ factionid ] [ i ] [ E_FACTION_SKIN_ID ] == INVALID_FACTION_SKIN_ID ) {

			return i ;		
		}
	}

	return INVALID_FACTION_SKIN_ID ;
}
 
// Creates a faction uniform in memory and the database.
FactionSkin_Create(playerid, factionid, skinid, tier, squad, locker_type = 0) {
	// factionid = enum id

	new index = FactionSkin_GetFreeID ( factionid ) ; 

	if ( index == INVALID_FACTION_SKIN_ID ) {

		SendClientMessage(playerid, COLOR_ERROR, "Invalid faction skin index passed. Are you sure there are free slots?");
		return printf(" * [FACTION SKIN] Tried to create add new skin for faction ID %d but FactionSkin_Create returned -1.", factionid);
	}

	SendClientMessage(playerid, 0xA3A3A3FF, "Inserting faction skin. Wait for blue confirmation message. If it doesn't show up, contact Torque.");

	FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_FACTIONID ] = Faction [ factionid ] [ E_FACTION_ID ] ;
	FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_SKINID ] = skinid ;
	FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_TIER ] = tier ;
	FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_SQUAD ] = squad ;
	FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_ARMORY_TYPE ] = locker_type ;

	new query [ 320 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "INSERT INTO faction_skins (faction_skin_factionid, faction_skin_skinid, faction_skin_tier, faction_skin_squad, faction_skin_armory_type) VALUES (%d, %d, %d, %d, %d)",
		FactionSkin [ factionid ]  [ index ] [ E_FACTION_SKIN_FACTIONID ], FactionSkin [ factionid ]  [ index ] [ E_FACTION_SKIN_SKINID ], FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_TIER ], FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_SQUAD], FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_ARMORY_TYPE ]
	 ) ;

	inline fSkin_OnDatabaseInsert() {

		FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_ID ] = cache_insert_id ();
		SendClientMessage(playerid, COLOR_BLUE, sprintf("Inserted skin id %d (slot %d) for faction ID %d successfully.", 
			FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_SKINID ], index,
			FactionSkin [ factionid ] [ index ] [ E_FACTION_SKIN_FACTIONID ] ) );
		//printf(" * [FACTION] Created faction (%d) with ID %d.",  factionid, Faction [ factionid ] [ E_FACTION_ID ] ) ;
	}

	MySQL_TQueryInline(mysql, using inline fSkin_OnDatabaseInsert, query, "");


	return true ;
}


// Loads all faction uniforms from the database.
FactionSkin_LoadEntitiesNew() {

	new loops = 0;

	for ( new f; f < MAX_FACTIONS; f ++ ) {

		for ( new i; i < MAX_FACTION_SKINS ; i ++ ) {
			FactionSkin [f] [ i ] [ E_FACTION_SKIN_ID ] = INVALID_FACTION_SKIN_ID ;
			loops++;
		}

		loops++;
	}

	inline FactionSkin_OnDataLoad() 
	{
		//printf("COUNT of skins for all facs: %d", cache_num_rows());
		new dbid, skinid, factionid, tier, squad, locker_type;

		new index[MAX_FACTIONS];
		for (new i = 0, r = cache_num_rows(); i < r; ++i)
		{ 
			cache_get_value_name_int(i, "faction_skin_id", dbid );
			cache_get_value_name_int(i, "faction_skin_factionid", factionid );
			cache_get_value_name_int(i, "faction_skin_skinid", skinid );
			cache_get_value_name_int(i, "faction_skin_tier", tier );
			cache_get_value_name_int(i, "faction_skin_squad", squad );

			// faction_skin_armory_type comes from the schema; missing column leaves it 0 (every locker)
			locker_type = 0;
			cache_get_value_name_int(i, "faction_skin_armory_type", locker_type );

			for ( new f; f < MAX_FACTIONS; f ++ )
			{
				if (factionid == Faction[f][E_FACTION_ID])
				{
					if (index[f] >= MAX_FACTION_SKINS)
					{
						printf("[FACTION SKINS] Skipped skin row %d for faction %d: MAX_FACTION_SKINS (%d) reached.",
							dbid, factionid, MAX_FACTION_SKINS);
						break;
					}

					FactionSkin [ f ] [ index[f] ] [ E_FACTION_SKIN_ID ] 		= dbid;
					FactionSkin [ f ] [ index[f] ] [ E_FACTION_SKIN_FACTIONID ] 	= factionid;
					FactionSkin [ f ] [ index[f] ] [ E_FACTION_SKIN_SKINID ] 	= skinid;
					FactionSkin [ f ] [ index[f] ] [ E_FACTION_SKIN_TIER ] 		= tier;
					FactionSkin [ f ] [ index[f] ] [ E_FACTION_SKIN_SQUAD ] = squad;
					FactionSkin [ f ] [ index[f] ] [ E_FACTION_SKIN_ARMORY_TYPE ] = locker_type;
					index[f] ++;
					// printf("Stored skin at [%d][%d]: ID=%d FactionID=%d SkinID=%d", 
                    //     f, index[f]-1, 
                    //     FactionSkin[f][index[f]-1][E_FACTION_SKIN_ID],
                    //     FactionSkin[f][index[f]-1][E_FACTION_SKIN_FACTIONID],
                    //     FactionSkin[f][index[f]-1][E_FACTION_SKIN_SKINID]
                    // );
				}

				loops++;
			}
			loops++;
		}

		//printf("The %d loops only took: %d ms", loops, GetTickCount() - tickc);
	}

	MySQL_TQueryInline(mysql, using inline FactionSkin_OnDataLoad, "SELECT * FROM faction_skins", "" ) ;

	return true ;
}



// Loads one faction's uniforms from the database.
FactionSkin_LoadEntities(faction_enum_id) {

	printf("FactionSkin_LoadEntities: %d (SQL: %d)", faction_enum_id, Faction[faction_enum_id][E_FACTION_ID]);
	

	for ( new i; i < MAX_FACTION_SKINS ; i ++ ) {

		FactionSkin [faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ] = INVALID_FACTION_SKIN_ID ;
	}

	inline FactionSkin_OnDataLoad(forfactionid) {

		new rows, fields ;
		cache_get_data ( rows, fields, mysql ) ;

		//printf("COUNT of skins for Fac SQL %d is: %d", forfactionid, rows);

		if ( rows ) {

			for ( new i; i < rows; i ++ ) { 
				if ( i >= MAX_FACTION_SKINS ) {
					continue;
				}
				
				FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ] 		= cache_get_field_int (i, "faction_skin_id");
				FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_FACTIONID ] 	= cache_get_field_int (i, "faction_skin_factionid");
				FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SKINID ] 	= cache_get_field_int (i, "faction_skin_skinid");
				FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_TIER ] 		= cache_get_field_int (i, "faction_skin_tier");
				FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SQUAD ] 		= cache_get_field_int (i, "faction_skin_squad");
				FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ARMORY_TYPE ] 	= 0;
				cache_get_value_name_int(i, "faction_skin_armory_type", FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ARMORY_TYPE ]);

				//printf("Fskin ADD: %d (SQL: %d), (faction: %d)", FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SKINID ], FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ], FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_FACTIONID ]);
			}
		}
	}

	new query [ 256 ] ;
	mysql_format(mysql, query, sizeof ( query ), "SELECT * FROM faction_skins WHERE faction_skin_factionid = %d", Faction [ faction_enum_id ] [ E_FACTION_ID ] ) ;
	print(query);
	MySQL_TQueryInline(mysql, query, using inline FactionSkin_OnDataLoad) ;



	return true ;
}

// /reloadfskins - (admin) reloads all faction uniforms.
CMD:reloadfskins(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    SendServerMessage(playerid, COLOR_BLUE, "Info", "A3A3A3", "Reloading faction skins from the database...");
    FactionSkin_LoadEntitiesNew(); 
    return true;
}

// 2025
CMD:fskindel(playerid, params[]) {
    if (IsPlayerIncapacitated(playerid, false)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");
    }

    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_LEAD) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    new factionid = Character[playerid][E_CHARACTER_FACTIONID];

    if (!factionid) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
    }

    new faction_enum_id = Faction_GetEnumID(factionid);

    if (faction_enum_id == INVALID_FACTION_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
    }

    if (Character[playerid][E_CHARACTER_FACTIONTIER] > 1) {
        // 1: owner, 2: command, 3: member
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have permission to do this.");
    }

    new skinid;

    if (sscanf(params, "i", skinid)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/fskindel [skin id]");
    }

    FactionSkin_Delete(playerid, faction_enum_id, skinid);

    return true;
}

// Removes a uniform skin from a faction.
FactionSkin_Delete(playerid, factionid, skinid) {
    new index = -1;
    
    for (new i = 0; i < MAX_FACTION_SKINS; i++) {
        if (FactionSkin[factionid][i][E_FACTION_SKIN_SKINID] == skinid && 
            FactionSkin[factionid][i][E_FACTION_SKIN_FACTIONID] == Faction[factionid][E_FACTION_ID]) {
            index = i;
            break;
        }
    }

    if (index == -1) {
        return SendClientMessage(playerid, COLOR_ERROR, "Invalid skin ID or skin not found for your faction.");
    }

    SendClientMessage(playerid, 0xA3A3A3FF, "Deleting faction skin. Wait for blue confirmation message. If it doesn't show up, contact Developers.");

    new query[256];
    
    mysql_format(mysql, query, sizeof(query), 
        "DELETE FROM faction_skins WHERE faction_skin_factionid = %d AND faction_skin_skinid = %d",
        FactionSkin[factionid][index][E_FACTION_SKIN_FACTIONID],
        FactionSkin[factionid][index][E_FACTION_SKIN_SKINID]
    );

    inline fSkin_OnDatabaseDelete() {
        if (cache_affected_rows() > 0) {
            FactionSkin[factionid][index][E_FACTION_SKIN_ID] = 0;
            FactionSkin[factionid][index][E_FACTION_SKIN_FACTIONID] = 0;
            FactionSkin[factionid][index][E_FACTION_SKIN_SKINID] = 0;
            FactionSkin[factionid][index][E_FACTION_SKIN_TIER] = 0;
            FactionSkin[factionid][index][E_FACTION_SKIN_SQUAD] = 0;

            SendClientMessage(playerid, COLOR_BLUE, sprintf("Successfully deleted skin id %d (slot %d) from faction ID %d.",
                skinid, index, Faction[factionid][E_FACTION_ID]));
        } else {
            SendClientMessage(playerid, COLOR_ERROR, "Failed to delete skin from database. Contact Developers.");
        }
    }

    MySQL_TQueryInline(mysql, using inline fSkin_OnDatabaseDelete, query, "");

    return true;
}
// <- 2025
