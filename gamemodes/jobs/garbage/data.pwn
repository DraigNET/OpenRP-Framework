// ============================================================================
// File: jobs/garbage/data.pwn
// Garbage job data: pickup points, the bags players carry, payout and the vehicle attachments.
// ============================================================================


new Float: garbageJobStartPosX[MAX_PLAYERS], Float: garbageJobStartPosY[MAX_PLAYERS], Float: garbageJobStartPosZ[MAX_PLAYERS];

new GarbageAssignedObject[MAX_PLAYERS], GarbageAssignedModel[MAX_PLAYERS];

#include <YSI_Coding\y_hooks>
hook OnPlayerDisconnect(playerid, reason) {
    GarbageJob_CancelData(playerid);
    return 1;
}

hook OnPlayerConnect(playerid) {
    GarbageAssignedObject[playerid]=0;
	garbageJobStartPosX[playerid] = 0;
	garbageJobStartPosY[playerid] = 0;
	garbageJobStartPosZ[playerid] = 0;

	return 1;
}

// Getting back into the job truck after storing trash continues the job
// automatically - no key press needed.
hook OnPlayerStateChange(playerid, newstate, oldstate) {

	if ( newstate == PLAYER_STATE_DRIVER
		&& IsPlayerDoingGarbageJob(playerid)
		&& ! PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_CARRYING ]
		&& PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_INDEX ] == -1
		&& IsPlayerInGarbageJobVehicle(playerid) ) {

		GarbageJob_FetchNewPoint(playerid);
	}

	return 1;
}


enum E_GARBAGE_POINT_DATA {

	Float: E_GARBAGE_POS_X,
	Float: E_GARBAGE_POS_Y,
	Float: E_GARBAGE_POS_Z
} ;

// Menus use a compact cache, while an assigned collection keeps its own bag.
// A location edit therefore affects future assignments without moving an active target.
new GarbagePoint[256][E_GARBAGE_POINT_DATA], GarbagePointCount;
new GarbageSource[256], garbage_object[256], DynamicText3D:GarbageLabels[256];

// Attaches the garbage bag or box model to the player's hands.
GarbageJob_SetAttachment(playerid, modelid) {

	switch ( modelid ) {
		case 1265: SetPlayerAttachedObject(playerid,E_ATTACH_INDEX_SYSTEM, modelid, E_ATTACH_BONE_HAND_L,0.272000,0.041000,0.000000,0.000000,-58.600017,0.000000,0.500000,0.500000,0.500000 ) ;
		case 1264: SetPlayerAttachedObject(playerid,E_ATTACH_INDEX_SYSTEM, modelid, E_ATTACH_BONE_HAND_L,0.189999,0.011000,-0.081000,0.000000,-116.200057,0.000000,0.500000,0.500000,0.500000 ) ;
		case 1220: SetPlayerAttachedObject(playerid,E_ATTACH_INDEX_SYSTEM, modelid, E_ATTACH_BONE_HAND_L,0.188000,-0.130999,-0.072000,96.700141,-59.399906,-165.800094,0.811000,0.696000,0.752999 ) ;
		case 1271: SetPlayerAttachedObject(playerid,E_ATTACH_INDEX_SYSTEM, modelid, E_ATTACH_BONE_HAND_L,0.128999,-0.057000,0.024000,-8.000018,-103.500007,94.999992,0.677999,0.685999,0.805000 ) ;
	}

	return true ;
}

// Stage replacement handles first; active player-only bags are owned separately.
GarbageJob_LoadEntities() {
    new objects[256], DynamicText3D:labels[256], sources[256], count;
    for(new i; i<RuntimeLocationCount; i++) {
        if(RuntimeLocations[i][RLOC_CATEGORY]!=RT_CATEGORY_GARBAGE || !RuntimeLocations[i][RLOC_ENABLED]) continue;
        if(count>=256) return 0;
        sources[count]=i;
        objects[count]=CreateDynamicObject(1265,RuntimeLocations[i][RLOC_X],RuntimeLocations[i][RLOC_Y],RuntimeLocations[i][RLOC_Z]-0.75,0.0,0.0,0.0,RuntimeLocations[i][RLOC_WORLD],RuntimeLocations[i][RLOC_INTERIOR]);
        labels[count]=CreateDynamic3DTextLabel("[Garbage Job]\n{DEDEDE}LALT to pick up",0xDEDEDEFF,RuntimeLocations[i][RLOC_X],RuntimeLocations[i][RLOC_Y],RuntimeLocations[i][RLOC_Z],7.5,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,false,RuntimeLocations[i][RLOC_WORLD],RuntimeLocations[i][RLOC_INTERIOR]);
        count++;
        if(!IsValidDynamicObject(objects[count-1]) || !IsValidDynamic3DTextLabel(labels[count-1])) {
            for(new n; n<count; n++) { if(IsValidDynamicObject(objects[n])) DestroyDynamicObject(objects[n]); if(IsValidDynamic3DTextLabel(labels[n])) DestroyDynamic3DTextLabel(labels[n]); }
            return 0;
        }
    }
    for(new i; i<GarbagePointCount; i++) { if(IsValidDynamicObject(garbage_object[i])) DestroyDynamicObject(garbage_object[i]); if(IsValidDynamic3DTextLabel(GarbageLabels[i])) DestroyDynamic3DTextLabel(GarbageLabels[i]); }
    GarbagePointCount=count;
    for(new i; i<count; i++) {
        garbage_object[i]=objects[i]; GarbageLabels[i]=labels[i]; GarbageSource[i]=sources[i];
        GarbagePoint[i][E_GARBAGE_POS_X]=RuntimeLocations[sources[i]][RLOC_X]; GarbagePoint[i][E_GARBAGE_POS_Y]=RuntimeLocations[sources[i]][RLOC_Y]; GarbagePoint[i][E_GARBAGE_POS_Z]=RuntimeLocations[sources[i]][RLOC_Z];
    }
    return 1;
}

// Choose only a reachable world/interior and keep the selected target until collection.
GarbageJob_FetchNewPoint(playerid) {
    new candidates[256], count;
    for(new i; i<GarbagePointCount; i++) {
        new source=GarbageSource[i];
        if(GetPlayerVirtualWorld(playerid)==RuntimeLocations[source][RLOC_WORLD] && GetPlayerInterior(playerid)==RuntimeLocations[source][RLOC_INTERIOR]) candidates[count++]=i;
    }
    if(!count) return SendClientMessage(playerid,COLOR_ERROR,"No collection points are configured in this world. Ask an administrator.");
    new point=candidates[random(count)], source=GarbageSource[point];
    if(IsValidDynamicObject(GarbageAssignedObject[playerid])) DestroyDynamicObject(GarbageAssignedObject[playerid]);
    if(IsValidDynamicArea(PlayerVar[playerid][E_PLAYER_GARBAGEJOB_AREA])) DestroyDynamicArea(PlayerVar[playerid][E_PLAYER_GARBAGEJOB_AREA]);
    GarbageAssignedModel[playerid]=1265;
    GarbageAssignedObject[playerid]=CreateDynamicObject(1265,GarbagePoint[point][E_GARBAGE_POS_X],GarbagePoint[point][E_GARBAGE_POS_Y],GarbagePoint[point][E_GARBAGE_POS_Z]-0.75,0.0,0.0,0.0,RuntimeLocations[source][RLOC_WORLD],RuntimeLocations[source][RLOC_INTERIOR],playerid);
    PlayerVar[playerid][E_PLAYER_GARBAGEJOB_AREA]=CreateDynamicCircle(GarbagePoint[point][E_GARBAGE_POS_X],GarbagePoint[point][E_GARBAGE_POS_Y],3.0,RuntimeLocations[source][RLOC_WORLD],RuntimeLocations[source][RLOC_INTERIOR],playerid);
    if(!IsValidDynamicObject(GarbageAssignedObject[playerid]) || !IsValidDynamicArea(PlayerVar[playerid][E_PLAYER_GARBAGEJOB_AREA])) {
        GarbageJob_CancelData(playerid);
        return SendClientMessage(playerid,COLOR_ERROR,"The collection could not be started. Try again.");
    }
    PlayerVar[playerid][E_PLAYER_GARBAGEJOB_INDEX]=point;
    GetPlayerPos(playerid,garbageJobStartPosX[playerid],garbageJobStartPosY[playerid],garbageJobStartPosZ[playerid]);
    new address[64]; GetPlayerAddress(GarbagePoint[point][E_GARBAGE_POS_X],GarbagePoint[point][E_GARBAGE_POS_Y],address);
    GPS_MarkLocation(playerid,sprintf("Collect the ~g~trash bags~w~ at %s.",address),E_GPS_COLOR_JOB,GarbagePoint[point][E_GARBAGE_POS_X],GarbagePoint[point][E_GARBAGE_POS_Y],GarbagePoint[point][E_GARBAGE_POS_Z]);
    return 1;
}

// When a player gets near a garbage bag, shows the prompt to pick it up.
public OnPlayerEnterDynamicArea(playerid, STREAMER_TAG_AREA:areaid ) {

	if ( PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB ] ) {
	
		if ( areaid == PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] ) {

			ShowPlayerInfoMessage(playerid, "Approach the ~g~garbage bag~w~ and press ~k~~SNEAK_ABOUT~ to pick it up.", .height=167.5, .width=180, .showtime=6000);

		}
	}

	#if defined garbage_OnPlayerEnterDynArea
		return garbage_OnPlayerEnterDynArea(playerid, STREAMER_TAG_AREA:areaid );
	#else
		return 1;
	#endif
}
#if defined _ALS_OnPlayerEnterDynamicArea
	#undef OnPlayerEnterDynamicArea
#else
	#define _ALS_OnPlayerEnterDynamicArea
#endif

#define OnPlayerEnterDynamicArea garbage_OnPlayerEnterDynArea
#if defined garbage_OnPlayerEnterDynArea
	forward garbage_OnPlayerEnterDynArea(playerid, STREAMER_TAG_AREA:areaid );
#endif

// Works out the pay for a garbage run based on how far the player went.
GarbageJob_CalculatePayout(playerid) {

	new payout = 75 ;
	new Float: distance = GetPlayerDistanceFromPoint(playerid, garbageJobStartPosX[playerid], garbageJobStartPosY[playerid], garbageJobStartPosZ[playerid]) ;

	if(distance > 100.0) {
		payout = 100;
		payout += random(75);

		if(distance >= 250.0 && distance < 800.0) {
			payout = 200;
			payout += random(100);
		}
		else if(distance >= 800.0) {
			payout = 200;
			payout += random(200);
		}
	}

#if defined FEATURE_FNR
	GameTextForPlayer(playerid, sprintf("~y~Job complete~n~~w~$%s~n~~w~Respect +", IntegerWithDelimiter(payout ), IntegerWithDelimiter ( payout )), 3500, 6);
#else
	GameTextForPlayer(playerid, sprintf("~y~Job complete~n~~w~$%s", IntegerWithDelimiter(payout )), 3500, 6);
#endif
	GivePlayerCash ( playerid, payout, "Garbage job payout" ) ;
	GiveFnRPoints(playerid, 1, "Garbage job");
					


	AddLogEntry(playerid, LOG_TYPE_JOB, sprintf(" earned %i from garbagejob.", payout ));
	ShowPlayerInfoMessage(playerid, "To continue working, get back ~y~inside your job truck~w~. To stop, press ~k~~TOGGLE_SUBMISSIONS~ in the truck.", .height=167.5, .width=180, .showtime=6000);

	PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_OLD_INDEX ] = PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_INDEX ] ;

	PlayerVar[playerid][E_PLAYER_GARBAGEJOB_COUNT] = 0;
	PlayerVar[playerid][E_PLAYER_GARBAGEJOB_TIMEOUT] = 0;

	return true ;
}

// Cancels the garbage job and clears the player's data.
GarbageJob_CancelData(playerid) {
    if(IsValidDynamicObject(GarbageAssignedObject[playerid])) DestroyDynamicObject(GarbageAssignedObject[playerid]);
    GarbageAssignedObject[playerid]=0;

	// Stopped doing job !
	PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB ] = false ;

	if ( IsValidDynamicArea(PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] ) ) {
		DestroyDynamicArea(PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] ) ;
		PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] = -1 ;
	}

	if ( IsValidVehicle( PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_VEHICLE ] )  ) {

		new veh_enum_id = Vehicle_GetEnumID(PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_VEHICLE ]) ;
		SetEngineStatus(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], false );
		SetDoorStatus(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], false );
	}

	PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_VEHICLE ] = INVALID_VEHICLE_ID ;
	PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_INDEX ] = -1 ;
	PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_CARRYING ] = false ;
	RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM);
	cmd_nocp(playerid);
}
