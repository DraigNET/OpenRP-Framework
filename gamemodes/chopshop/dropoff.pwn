// ============================================================================
// File: chopshop/dropoff.pwn
// Chop shop drop-off logic: picks a random drop point for a stolen vehicle, verifies it,
// applies the 10 minute cooldown and pays out when the car is delivered.
// ============================================================================

enum E_CHOP_SHOP_DATA {

	Float: E_DROP_OFF_POS_X,
	Float: E_DROP_OFF_POS_Y,
	Float: E_DROP_OFF_POS_Z,

} ;

new DropPoints [ ] [ E_CHOP_SHOP_DATA ] = {
	{684.7806,-442.1397,16.3359}, // Chopshop 1
	{772.7348,-598.7747,15.6919}, // Chopshop 2
	{881.6119,-595.1790,19.5039}, // Chopshop 3
	{634.3707,-508.6809,16.3359}, // Chopshop 4
	{1032.6980,-289.9400,73.9922}, // Chopshop 5
	{1095.5184,-352.1637,73.9922}, // Chopshop 6
	{1518.8723,4.7018,24.0024}, // Chopshop 7
	{1280.9161,129.7353,20.5713}, // Chopshop 8
	{1316.3048,160.4539,20.4333}, // Chopshop 9
	{1323.3143,205.7526,19.5547}, // Chopshop 10
	{1200.8738,171.2182,20.5080}, // Chopshop 11
	{1196.2393,146.2061,20.5122}, // Chopshop 12
	{1257.3157,368.1313,19.5614}, // Chopshop 13
	{1290.8496,404.0178,19.4216}, // Chopshop 14
	{1431.5813,252.0760,19.6477}, // Chopshop 15
	{2256.3506,73.2556,26.4844}, // Chopshop 16
	{2421.8142,-79.0369,26.6812}, // Chopshop 17
	{250.6781,-310.3964,1.5836}, // Chopshop 18
	{133.5989,-278.8570,1.5781}, // Chopshop 19
	{213.6685,-156.3947,1.5781}, // Chopshop 20
	{251.2996,-135.6329,1.5781}, // Chopshop 21
	{311.5181,-251.2246,1.5836}, // Chopshop 22
	{371.0401,-124.8949,1.2777}, // Chopshop 23
	{313.7466,-34.0520,1.5759}, // Chopshop 24
	{267.8886,39.1584,2.4382} // Chopshop 25
};

//new chopPayout;
ChopShop_CalculateRandomPoint(playerid, vehicleid) {

	
	// Cooldown of 10 minutes
	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;

	new index = random ( sizeof ( DropPoints ) ) ;
	GPS_MarkLocation(playerid, "~g~Dropoff point~w~ has been marked on your ~g~minimap.", E_GPS_COLOR_JOB, DropPoints [ index ] [ E_DROP_OFF_POS_X ], DropPoints [ index ] [ E_DROP_OFF_POS_Y ] , DropPoints [ index ] [ E_DROP_OFF_POS_Z ] ) ;
	
	ShowPlayerInfoMessage(playerid, "Drive to the hide point and ditch the car! Your money will be waiting for you...", .height=167.5, .width=180, .showtime=6000);


	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_CARID ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ;
	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_DROPPOINT ] = index ;

	new payout = GetVehicleModel(vehicleid) * 2 ;

	new Float: health ;
	GetVehicleHealth(vehicleid, health ) ;

	payout += floatround ( health );

	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ] = payout ;

	// Fuck the car up
	new panels, doors, lights, tires;
	GetVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	UpdateVehicleDamageStatus(vehicleid, 12345, 12345, 12345, 2);

	new Float: sync_health = health / 3 ;

	if ( sync_health <= 400.0 ) {

		sync_health = 400 ;
	}

	ORP_SetVehicleHealth ( vehicleid, sync_health ) ;

 	new chopshop_owner_cut = payout / 12 ; 
 	Server [ E_SERVER_CHOPSHOP_COLLECT ] += chopshop_owner_cut ;  
  
 	new query [ 256 ] ; 
  
 	mysql_format(mysql, query, sizeof ( query ), "UPDATE server SET server_chopshop_collect = %d", Server [ E_SERVER_CHOPSHOP_COLLECT ] ) ; 
 	mysql_tquery(mysql, query);

	//chopPayout = payout;
	return true ;
}

// Checks the player is in the stolen vehicle at the assigned drop-off point; if so pays them and
// blows up the car.
ChopShop_VerifyPointLocation(playerid, skip_range = false) {

	new vehicleid = GetPlayerVehicleID(playerid) ;
	new index = PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_DROPPOINT ] ;
	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;

	if ( veh_enum_id == -1 ) {

		return true ;
	}

	if ( index == -1 ) {

		return true ;
	}
	if ( ! IsPlayerInRangeOfPoint(playerid, 15.0, DropPoints [ index ] [ E_DROP_OFF_POS_X ], DropPoints [ index ] [ E_DROP_OFF_POS_Y ], DropPoints [ index ] [ E_DROP_OFF_POS_Z ] ) ) {
		if ( ! skip_range ) {
			return true ;
		}
	}

	if ( PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_CARID ] == Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ) {

		GivePlayerCash ( playerid, PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ], "Chopshop payout" ) ;

		ShowPlayerInfoMessage(playerid, "You've hidden the vehicle. You've lit it on fire to destroy evidence. Leave the area!", .height=167.5, .width=180, .showtime=6000);

#if defined FEATURE_FNR
		GameTextForPlayer(playerid, sprintf("~y~Job complete~n~~w~$%s~n~~w~Fear +", IntegerWithDelimiter( PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ] )), 7500, 6);
#else
		GameTextForPlayer(playerid, sprintf("~y~Job complete~n~~w~$%s", IntegerWithDelimiter( PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ] )), 7500, 6);
#endif
		GiveFnRPoints(playerid, 5, "Chop Shop job", false);
		AddPlayerRespect(playerid, 2);
		//GivePlayerFearAndRespect(playerid);
		//PlayerPlaySound(playerid, 183, 0, 0, 0);

 		PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ] = 0 ;
	 	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_CARID ] = INVALID_VEHICLE_ID ;
		PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_DROPPOINT ] = -1 ;	
		cmd_nocp(playerid);

		/*if (DockEntity[DOCK_ENTITY_SCRAPYARD][E_DOCK_FACTION_ID] != -1)
		{
			new chopshop_cut = chopPayout / 12;
			DockEntity[DOCK_ENTITY_SCRAPYARD][E_DOCK_BANK] += chopshop_cut;

			new query2[128];
			mysql_format(mysql, query2, sizeof(query2),
				"UPDATE dock_entities SET entity_bank = entity_bank + %d WHERE entity_slot = %d",
				chopshop_cut, DOCK_ENTITY_SCRAPYARD);
			mysql_tquery(mysql, query2);
			DockEntity_AddMission(DOCK_ENTITY_SCRAPYARD);
		}*/
		defer Chopshop_ExplodeVehicle(vehicleid);
	}

	else {
		GameTextForPlayer(playerid, "~r~Mission Failed~n~~w~You brought the wrong car..", 5000, 6);
		AddPlayerRespect(playerid, -2);

		ShowPlayerInfoMessage(playerid, "This isn't the right car! Are you trying to cheat the underworld? Get lost, fool!", .height=167.5, .width=180, .showtime=6000);

	 	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ] = 0 ;
	 	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_CARID ] = INVALID_VEHICLE_ID ;
		PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_DROPPOINT ] = -1 ;	
		cmd_nocp(playerid);

	}
	
	return true ;
}

// Timer: makes the chopped vehicle explode shortly after delivery.
timer Chopshop_ExplodeVehicle[2500](vehicleid) {

	ORP_SetVehicleCanExplode(vehicleid, true);
	SetVehicleHealth(vehicleid, 50 ) ;
}
