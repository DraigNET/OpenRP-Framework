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
static RuntimeUniformGeneration, UniformMenuGeneration[MAX_PLAYERS];
static bool:UniformMenuIsFaction[MAX_PLAYERS];

// Tagged declarations keep cross-module calls from forcing a compiler reparse.
forward bool:FactionSkin_CanUseRow(playerid,faction,index,locker_type=-1);
forward bool:FactionSkin_CanWear(playerid,model,locker_type=-1);
forward bool:FactionSkin_NearLockerOrSpawn(playerid);
#if FEATURE_CUSTOM_SKINS
forward bool:CustomSkins_FactionModelLoaded(model,factionid);
#endif

// Callback of the uniform browser: puts the chosen uniform on the player.
mBrowser:fskin_list(playerid, response, row, model, name[]) {

	if ( response ) 
	{
        if(UniformMenuGeneration[playerid]!=RuntimeUniformGeneration) return SendClientMessage(playerid,COLOR_ERROR,"Uniforms changed. Reopen the uniform menu.");
        if(IsPlayerInDutyFaction(playerid) && UniformMenuIsFaction[playerid]!=bool:PlayerVar[playerid][E_PLAYER_FACTION_DUTY]) return SendClientMessage(playerid,COLOR_ERROR,"Your duty state changed. Reopen the uniform menu.");
        if(UniformMenuIsFaction[playerid] && (!FactionSkin_NearLockerOrSpawn(playerid) || !FactionSkin_CanWear(playerid,model,Armory_GetPlayerLockerType(playerid)))) return SendClientMessage(playerid,COLOR_ERROR,"This uniform is no longer available at your current locker.");
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
    UniformMenuIsFaction[playerid]=true;
	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	ModelBrowser_ClearData(playerid);
    UniformMenuGeneration[playerid]=RuntimeUniformGeneration;
	new count = 0, skinid = INVALID_FACTION_SKIN_ID, skinsquad = 0;

	for ( new i, j = MAX_FACTION_SKINS ; i < j ; i ++ ) 
	{
		skinid = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ];

		if ( skinid != INVALID_FACTION_SKIN_ID && skinid != 0 ) 
		{
			if (!FactionSkin_CanUseRow(playerid,faction_enum_id,i,locker_type))
			{
				// Not offered at this locker
				continue;
			}

			skinsquad = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_SQUAD ];

			if (skinsquad && !IsPlayerInFactionSquad(playerid, skinsquad) && Character [ playerid ] [ E_CHARACTER_FACTIONTIER ] > 1)
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
    UniformMenuGeneration[playerid]=RuntimeUniformGeneration;
	new skin_name [ 64 ], count = 0, skinid = INVALID_FACTION_SKIN_ID, squad = 0;

	if (!IsPlayerInDutyFaction(playerid) || PlayerVar [ playerid ] [ E_PLAYER_FACTION_DUTY ])
	{
        UniformMenuIsFaction[playerid]=true;
		// faction skins
		for ( new i, j = MAX_FACTION_SKINS ; i < j ; i ++ ) 
		{
			skinid = FactionSkin [ faction_enum_id ] [ i ] [ E_FACTION_SKIN_ID ];

			if ( skinid != INVALID_FACTION_SKIN_ID && skinid != 0 ) 
			{
				//printf("Found valid skin in slot %d", i);
				if (!FactionSkin_CanUseRow(playerid,faction_enum_id,i,locker_type))
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
        UniformMenuIsFaction[playerid]=false;
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
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is being applied. Try again shortly.");
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
    if(Runtime_ConfigurationBusy()) return 0;
    if(!Runtime_StageUniforms()) { print("[Uniforms] Reload rejected; previous uniform lists retained."); return 0; }
    return Runtime_CommitUniforms();
}



// Loads one faction's uniforms from the database.
FactionSkin_LoadEntities(faction_enum_id) {
    #pragma unused faction_enum_id
    return FactionSkin_LoadEntitiesNew();
}

// /reloadfskins - (admin) reloads all faction uniforms.
CMD:reloadfskins(playerid, params[]) {
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    if(!FactionSkin_LoadEntitiesNew()) return SendClientMessage(playerid,COLOR_ERROR,"Uniform reload could not run. Check configuration status and retry.");
    SendServerMessage(playerid, COLOR_BLUE, "Info", "A3A3A3", "Faction uniforms reloaded.");
    return true;
}

// 2025
CMD:fskindel(playerid, params[]) {
    if(Runtime_ConfigurationBusy()) return SendClientMessage(playerid,COLOR_ERROR,"Configuration is being applied. Try again shortly.");
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
// Check permissions against current data when listing AND when accepting a tile.
// A reload never strips a uniform already being worn; future choices use new rules.
stock bool:FactionSkin_CanUseRow(playerid,faction,index,locker_type=-1) {
    if(faction<0 || faction>=MAX_FACTIONS || index<0 || index>=MAX_FACTION_SKINS || FactionSkin[faction][index][E_FACTION_SKIN_ID]<=0) return false;
    if(FactionSkin[faction][index][E_FACTION_SKIN_FACTIONID]!=Character[playerid][E_CHARACTER_FACTIONID] || !FactionSkin_AtLocker(faction,index,locker_type)) return false;
    new tier=FactionSkin[faction][index][E_FACTION_SKIN_TIER], squad=FactionSkin[faction][index][E_FACTION_SKIN_SQUAD];
    if(tier && Character[playerid][E_CHARACTER_FACTIONTIER]>tier) return false;
    if(squad && !IsPlayerInFactionSquad(playerid,squad) && Character[playerid][E_CHARACTER_FACTIONTIER]>1) return false;
    return true;
}
stock bool:FactionSkin_CanWear(playerid,model,locker_type=-1) {
    new faction=Faction_GetEnumID(Character[playerid][E_CHARACTER_FACTIONID]);
    if(faction==INVALID_FACTION_ID || GetPlayerFactionSuspension(playerid)) return false;
    for(new i; i<MAX_FACTION_SKINS; i++) if(FactionSkin[faction][i][E_FACTION_SKIN_SKINID]==model && FactionSkin_CanUseRow(playerid,faction,i,locker_type)) return true;
    return false;
}
stock bool:FactionSkin_MenuCurrent(playerid) { return UniformMenuGeneration[playerid]==RuntimeUniformGeneration; }
stock bool:FactionSkin_NearLockerOrSpawn(playerid) {
    if(IsPlayerNearArmory(playerid)) return true;
    new faction=Faction_GetEnumID(Character[playerid][E_CHARACTER_FACTIONID]);
    if(faction==INVALID_FACTION_ID || Faction_CanID(faction,FAC_CAP_LAW) || Faction[faction][E_FACTION_TYPE]==FACTION_TYPE_EMS) return false;
    return GetPlayerInterior(playerid)==Faction[faction][E_FACTION_SPAWN_INT] && GetPlayerVirtualWorld(playerid)==Faction[faction][E_FACTION_SPAWN_VW] && IsPlayerInRangeOfPoint(playerid,5.0,Faction[faction][E_FACTION_SPAWN_X],Faction[faction][E_FACTION_SPAWN_Y],Faction[faction][E_FACTION_SPAWN_Z]);
}
stock bool:FactionSkin_NearTurnoutVehicle(playerid) {
    new vehicle=PlayerVar[playerid][E_PLAYER_SWAT_VEHICLE];
    if(!IsValidVehicle(vehicle) || GetVehicleFactionID(vehicle)!=Character[playerid][E_CHARACTER_FACTIONID] || GetVehicleVirtualWorld(vehicle)!=GetPlayerVirtualWorld(playerid)) return false;
    new Float:x,Float:y,Float:z; GetVehiclePos(vehicle,x,y,z);
    return IsPlayerInRangeOfPoint(playerid,10.0,x,y,z);
}

static RuntimeUniformStage[MAX_FACTIONS][MAX_FACTION_SKINS][E_FACTION_SKIN_DATA];
// Snapshot statements can run on the worker connection during live reloads.
Runtime_QueryUniforms(query[],size) {
    format(query,size,"SELECT 0 kind,u.faction_skin_id id,u.faction_skin_factionid faction,u.faction_skin_skinid model,u.faction_skin_tier tier,u.faction_skin_squad squad,u.faction_skin_armory_type locker_type,IFNULL(t.faction_id,0) type_faction,IFNULL(q.faction_id,0) squad_faction,s.revision FROM faction_skins u JOIN runtime_config_state s ON s.id=1 LEFT JOIN faction_armory_types t ON t.armory_type_id=u.faction_skin_armory_type LEFT JOIN runtime_faction_squads q ON q.squad_id=u.faction_skin_squad AND q.enabled=1 ");
    strcat(query,"UNION ALL SELECT -1,0,0,0,0,0,0,0,0,s.revision FROM runtime_config_state s WHERE s.id=1 ORDER BY kind,id",size);
    return 1;
}

Runtime_StageUniforms(expectedRevision=0,bool:fromCache=false) {
    for(new f; f<MAX_FACTIONS; f++) for(new i; i<MAX_FACTION_SKINS; i++) RuntimeUniformStage[f][i][E_FACTION_SKIN_ID]=INVALID_FACTION_SKIN_ID;
    new Cache:result=MYSQL_INVALID_CACHE;
    if(!fromCache) { new query[1536]; Runtime_QueryUniforms(query,sizeof query); result=mysql_query(mysql,query); }
    if(!fromCache && !cache_is_valid(result)) return 0;
    new rows=cache_num_rows(), revision, count[MAX_FACTIONS];
    if(!rows) { if(!fromCache) cache_delete(result); return 0; }
    cache_get_value_name_int(0,"revision",revision);
    if(expectedRevision && revision!=expectedRevision) { if(!fromCache) cache_delete(result); return 0; }
    for(new row=1; row<rows; row++) {
        new id,faction,model,tier,squad,locker_type,type_faction,squad_faction;
        cache_get_value_name_int(row,"id",id); cache_get_value_name_int(row,"faction",faction); cache_get_value_name_int(row,"model",model); cache_get_value_name_int(row,"tier",tier); cache_get_value_name_int(row,"squad",squad); cache_get_value_name_int(row,"locker_type",locker_type); cache_get_value_name_int(row,"type_faction",type_faction); cache_get_value_name_int(row,"squad_faction",squad_faction);
        new index=Faction_GetEnumID(faction);
        if(index==INVALID_FACTION_ID || count[index]>=MAX_FACTION_SKINS || id<1 || tier<0 || tier>10 || squad<0 || squad>127 || (locker_type && type_faction!=faction) || (squad && squad_faction!=faction)) { if(!fromCache) cache_delete(result); return 0; }
        if(model<0 || model==74 || model>311) {
            #if FEATURE_CUSTOM_SKINS
                if(!CustomSkins_FactionModelLoaded(model,faction)) { if(!fromCache) cache_delete(result); return 0; }
            #else
                if(!fromCache) cache_delete(result); return 0;
            #endif
        }
        new slot=count[index]++;
        RuntimeUniformStage[index][slot][E_FACTION_SKIN_ID]=id; RuntimeUniformStage[index][slot][E_FACTION_SKIN_FACTIONID]=faction; RuntimeUniformStage[index][slot][E_FACTION_SKIN_SKINID]=model; RuntimeUniformStage[index][slot][E_FACTION_SKIN_TIER]=tier; RuntimeUniformStage[index][slot][E_FACTION_SKIN_SQUAD]=squad; RuntimeUniformStage[index][slot][E_FACTION_SKIN_ARMORY_TYPE]=locker_type;
    }
    if(!fromCache) cache_delete(result);
    return 1;
}
Runtime_CommitUniforms() {
    for(new f; f<MAX_FACTIONS; f++) for(new i; i<MAX_FACTION_SKINS; i++) for(new c; c<E_FACTION_SKIN_DATA; c++) FactionSkin[f][i][E_FACTION_SKIN_DATA:c]=RuntimeUniformStage[f][i][E_FACTION_SKIN_DATA:c];
    RuntimeUniformGeneration++;
    return 1;
}
