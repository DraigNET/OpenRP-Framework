// ============================================================================
// File: jobs/garbage/data.pwn
// Garbage job data: pickup points, the bags players carry, payout and the vehicle attachments.
// ============================================================================


new Float: garbageJobStartPosX[MAX_PLAYERS], Float: garbageJobStartPosY[MAX_PLAYERS], Float: garbageJobStartPosZ[MAX_PLAYERS];

#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {
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

new GarbagePoint [ ] [ E_GARBAGE_POINT_DATA ] = {
	{255.6008,20.4950,2.4475},      // Garbage 1
	{215.0402,-5.6737,2.5371},      // Garbage 2
	{204.5641,-33.1239,1.5781},     // Garbage 3
	{162.3470,-10.7469,1.5781},     // Garbage 4
	{182.7723,-91.8026,1.5427},     // Garbage 5
	{175.6007,-118.9284,1.5503},    // Garbage 6
	{210.9835,-163.2349,1.5781},    // Garbage 7
	{215.6126,-181.7471,1.5781},    // Garbage 8
	{121.1602,-154.7676,1.5781},    // Garbage 9
	{199.9074,-325.5791,1.7051},    // Garbage 10
	{654.3475,-439.0498,16.3359},   // Garbage 11
	{644.6218,-511.1986,16.3359},   // Garbage 12
	{661.9570,-541.7520,16.3359},   // Garbage 13
	{662.0895,-623.0569,16.3359},   // Garbage 14
	{740.5894,-539.7310,16.3359},   // Garbage 15
	{797.1172,-520.6215,16.3359},   // Garbage 16
	{835.7222,-599.8776,16.3359},   // Garbage 17
	{1276.0763,188.9603,19.6586},   // Garbage 18
	{1299.7666,214.5239,19.5547},   // Garbage 19
	{1244.8755,246.6298,19.5547},   // Garbage 20
	{1293.5852,345.7444,19.5547},   // Garbage 21
	{1383.8431,293.5231,19.5547},   // Garbage 22
	{1392.2594,210.4175,19.4574},   // Garbage 23
	{2214.2256,52.6979,26.4844},    // Garbage 24
	{2236.6643,69.7013,26.4844},    // Garbage 25
	{2283.2935,101.0556,26.4844},   // Garbage 26
	{2323.7600,59.8555,26.4922},    // Garbage 27
	{2361.8550,-37.9262,26.4844},   // Garbage 28
	{2417.0471,51.0469,26.4844},    // Garbage 29
	{2543.8750,27.6838,26.4844},    // Garbage 30
	{2334.4702,-52.8211,26.4844},   // Garbage 31
	{2275.9382,-69.1702,26.5751}    // Garbage 32
}, garbage_object [ sizeof ( GarbagePoint )] ;

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

// Creates the garbage pickup points and their bags.
GarbageJob_LoadEntities() {

	new modelid, Float: fixed_z ;

	for ( new i, j =sizeof ( GarbagePoint ); i < j ; i ++ ) {


		switch ( random ( 4 ) ) {

			case 0: modelid = 1265 ;
			case 1: modelid = 1264 ;
			case 2: modelid = 1220 ;
			case 3: modelid = 1271 ;
		}

		//CA_FindZ_For2DCoord(GarbagePoint [ i ] [ E_GARBAGE_POS_X ], GarbagePoint [ i ] [ E_GARBAGE_POS_Y ], fixed_z );

		fixed_z = GarbagePoint [ i ] [ E_GARBAGE_POS_Z ] - 0.75;
		garbage_object [ i ] = CreateDynamicObject(modelid, GarbagePoint [ i ] [ E_GARBAGE_POS_X ], GarbagePoint [ i ] [ E_GARBAGE_POS_Y ], fixed_z, 0.0, 0.0, 0.0, .priority = STREAM_PRIORITY_INTERACTABLE);
		CreateDynamic3DTextLabel("[Garbage Job]\n{DEDEDE}LALT to pick up", 0xDEDEDEFF, GarbagePoint [ i ] [ E_GARBAGE_POS_X ], GarbagePoint [ i ] [ E_GARBAGE_POS_Y ], fixed_z, 7.5, .testlos = false );
	}
}

GarbageJob_FetchNewPoint ( playerid ) {

	new point = random ( sizeof ( GarbagePoint ) ) ;

	new address[ 64 ],Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;
	GetPlayerAddress(GarbagePoint [ point ] [ E_GARBAGE_POS_X ], GarbagePoint [ point ] [ E_GARBAGE_POS_Y ], address) ;

	// Store start point.
	garbageJobStartPosX[playerid] = x;
	garbageJobStartPosY[playerid] = y;
	garbageJobStartPosZ[playerid] = z;

	GPS_MarkLocation(playerid, sprintf("Collect the ~g~trash bags~w~ at %s.", address), E_GPS_COLOR_JOB,GarbagePoint [ point ] [ E_GARBAGE_POS_X ], GarbagePoint [ point ] [ E_GARBAGE_POS_Y ], GarbagePoint [ point ] [ E_GARBAGE_POS_Z ] ) ;

	ShowPlayerInfoMessage(playerid, "Drive to the ~g~checkpoint~w~ on your map and collect the trash bags.", .height=167.5, .width=180, .showtime=6000);


	if ( IsValidDynamicArea(PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] ) ) {
		DestroyDynamicArea(PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] ) ;
		PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] = -1 ;
	}

	if ( point == PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_OLD_INDEX ] ) {

		if ( (point + 1) >= sizeof ( GarbagePoint ) ) {

			point -= 1 ;
		}

		else point += 1 ;
	}

	PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_AREA ] = CreateDynamicCircle(GarbagePoint [ point ] [ E_GARBAGE_POS_X ], GarbagePoint [ point ] [ E_GARBAGE_POS_Y ], 3.0, -1, -1, playerid ) ;
	PlayerVar [ playerid ] [ E_PLAYER_GARBAGEJOB_INDEX ] = point ;

	return true ;
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
