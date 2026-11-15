// ============================================================================
// File: vehicle/data/cmds/default.pwn
// Everyday vehicle commands for players: /carcheck, /neon, windows (/window, /rollwindows),
// toolkit, and sharing keys (GiveVehicleKey).
// Commands: /carcheck /toolkit /neon /rw /rws /cws /window /windows /rollwindow /rollwindows
// /carwindows /carwindow /helmet /sb /seatbelt /cl /carlights /lights /cartrunkrange /cartrunk
// /carhood /detach /carattach /cardoor /vehiclename /mydups /givecarkey /givekey /vkey /vdup
// ============================================================================

// /carcheck - shows information about the vehicle you are at.
CMD:carcheck(playerid, params[]) {

	new vehicleid = Vehicle_GetClosestEntity(playerid);
	new veh_enum_id = Vehicle_GetEnumID (vehicleid);

	if ( vehicleid == INVALID_VEHICLE_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any vehicle!");
	}

	SendClientMessage(playerid, COLOR_VEHICLE, "____________________________________ Vehicle Info ____________________________________");
	SendClientMessage(playerid, COLOR_ERROR, sprintf("[Vehicle Name]:{DEDEDE} %s", ReturnVehicleName ( vehicleid ) ));


	SendClientMessage(playerid, COLOR_ERROR, sprintf("[Windows]:{DEDEDE} %s", 
		(Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ]) ? ("Up") : ("Down") ) ) ;

	SendClientMessage(playerid, COLOR_ERROR, sprintf("[Doors]:{DEDEDE} %s", 
		(Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ]) ? ("Locked") : ("Unlocked") ) ) ;

	new driver_id = GetVehicleDriver ( vehicleid ) ;

	if ( driver_id != INVALID_PLAYER_ID ) {

		SendClientMessage(playerid, COLOR_ERROR, sprintf("[Seatbelt (Driver)]:{DEDEDE} %s", 
			(PlayerVar [ driver_id ] [ player_hasseatbelton ]) ? ("On") : ("Off") ) ) ;
	}

	else SendClientMessage ( playerid, COLOR_ERROR, "[Seatbelt (Driver)]:{DEDEDE} No Driver");

	SendClientMessage(playerid, COLOR_HINT,  sprintf("[License Plate]:{DEDEDE} %s", Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ]));

	SendClientMessage(playerid, COLOR_VEHICLE, "______________________________________________________________________");


	SendClientMessage(playerid, COLOR_YELLOW, sprintf("[Admin]{DEDEDE} [Vehicle ID: %d] [SQL ID: %d] [Owner Character ID: %d]",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] ) ) ;

	return true ;
}



// /toolkit - opens the toolkit to repair, refuel or fix a vehicle.
CMD:toolkit(playerid) {

	if ( ! PlayerVar [ playerid ] [ E_PLAYER_HAS_TOOLKIT ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have a toolkit! Buy one from a 24/7 or General Store.");
	}

	new vehicleid = GetPlayerVehicleID ( playerid );
	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;

	if ( veh_enum_id == -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "You're not in a proper vehicle.");
	}

	if ( IsPlayerInAnyVehicle(playerid) && GetPlayerState(playerid) == PLAYER_STATE_DRIVER ) {

		new Float: health ;
		GetVehicleHealth(vehicleid, health);

		if ( health > 375 ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Your vehicle still has more than 375 health. It's not broken!");
		}

	    Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ] = 450 ;
	    PlayerVar [ playerid ] [ E_PLAYER_HAS_TOOLKIT ] = false ;

	    SetVehicleHealth(vehicleid, 450);

	    new query [ 256 ] ;

	    mysql_format(mysql, query, sizeof ( query), "UPDATE vehicles SET vehicle_health = '%f' WHERE vehicle_sqlid = %d",
	        Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] );

	    mysql_tquery(mysql, query);

		ProxDetectorEx(playerid, 30, COLOR_ACTION, "**", sprintf("uses a toolkit to kickstart their %s.", ReturnVehicleName(vehicleid)), .annonated=true);
	    SendServerMessage ( playerid, COLOR_BLUE, "Toolkit", "A3A3A3", "You've kickstarted your vehicle using a toolkit." ) ;

	}

	return true ;
}

// /neon - toggles the neon lights.
CMD:neon(playerid, params[]) {

	if ( !IsPlayerAdmin(playerid)) {

		return false ;
	}

	new vehicleid = GetPlayerVehicleID(playerid);

	if ( vehicleid == INVALID_VEHICLE_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not in any vehicle!");
	}

	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );


	new color ;

	if ( sscanf ( params, "i", color ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/neon [color]");
		SendClientMessage(playerid, COLOR_GRAD0, "0: None - 1: pink - 2: yellow - 3: green - 4: red - 5: white - 6: blue");
		return true ;
	}

	if ( color < 0 || color > 6 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Color can't be less than 0 or more than 5.");
	}

	new objectid ;

	switch ( color ) {

		case 0: {

			if ( IsValidDynamicObject ( Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 0 ]) ) {

				ORP_DestroyObject(Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 0 ], "Vehicle/Neon", true ) ;
			}
			if ( IsValidDynamicObject ( Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 1 ]) ) {
				
				ORP_DestroyObject(Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 1 ], "Vehicle/Neon", true ) ;
			}

	 		SendServerMessage ( playerid, COLOR_VEHICLE, "Neon", "A3A3A3", "Neon removed!");
	
			return true ;
		}

		case 1: objectid = 18651 ;
		case 2: objectid = 18650 ;
		case 3: objectid = 18649 ;
		case 4: objectid = 18657 ;
		case 5: objectid = 18652 ;
		case 6: objectid = 18648 ;
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 0 ] = CreateDynamicObject(objectid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
	AttachDynamicObjectToVehicle(Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 0 ], vehicleid, -0.8, 0.0, -0.70, 0.0, 0.0, 0.0);

	Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 1 ] = CreateDynamicObject(objectid, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
	AttachDynamicObjectToVehicle(Vehicle [ veh_enum_id ] [ E_VEHICLE_NEON ] [ 1 ], vehicleid, 0.8, 0.0, -0.70, 0.0, 0.0, 0.0);

	SendServerMessage ( playerid, COLOR_VEHICLE, "Neon", "A3A3A3", "Neon attached!");    

	return true ;      
}

CMD:rw(playerid, params[]) return cmd_carwindow(playerid, params);
CMD:rws(playerid, params[]) return cmd_carwindow(playerid, params);
CMD:cws(playerid, params[]) return cmd_carwindow(playerid, params);
CMD:window(playerid, params[]) return cmd_carwindow(playerid, params);
CMD:windows(playerid, params[]) return cmd_carwindow(playerid, params);
CMD:rollwindow(playerid, params[]) return cmd_carwindow(playerid, params);
CMD:rollwindows(playerid, params[]) return cmd_carwindow(playerid, params);
CMD:carwindows(playerid, params[]) return cmd_carwindow(playerid, params);
// /carwindow - opens or closes a vehicle window.
CMD:carwindow(playerid,params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new vehicleid = GetPlayerVehicleID(playerid) ;
	new veh_enum_id = Vehicle_GetEnumID (vehicleid);
	if ( veh_enum_id == -1 ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any proper vehicle! (couldn't fetch ID)");
	}
	if (!IsWindowedVehicle(vehicleid))
		return SendClientMessage(playerid, COLOR_ERROR, "You are not in any vehicle with windows.");

    if(sscanf(params, "d", params[0]))
    {
        SendClientMessage(playerid,-1,"/(car/roll)window(s) [0, 1-2-3-4]");
        SendClientMessage(playerid,-1,"0 - All | 1 - Driver window | 2 - Passenger window | 3 - Rear-left window | 4 - Rear-right window");
        return 1;
    }
    if(params[0] > 4 || params[0] < 0) return SendClientMessage(playerid,-1,"0 - All | 1 - Driver window | 2 - Passenger window | 3 - Rear-left window | 4 - Rear-right window");
    new driver, passenger, backleft, backright;
    GetVehicleParamsCarWindows(GetPlayerVehicleID(playerid), driver, passenger, backleft, backright);
    switch(params[0])
    {
    	case 0: {

    		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] ) {

    			Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] = false ;
    			driver = 0, passenger = 0, backleft = 0, backright = 0 ;
    		}

    		else { 
    			driver = 1, passenger = 1, backleft = 1, backright = 1 ;
    			Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] = true ;
    		}
    	}
        case 1: driver = !driver ? (1) : (0);
        case 2: passenger = !passenger ? (1) : (0);
        case 3: backleft = !backleft ? (1) : (0);
        case 4: backright = !backright ? (1) : (0);
    }
	new string[256];
	switch(params[0])
	{
		case 0: {
			string = (Vehicle[veh_enum_id][E_VEHICLE_WINDOW]) ? sprintf("rolls up the windows of the %s.", ReturnVehicleName(vehicleid)) : sprintf("rolls down the windows of the %s.", ReturnVehicleName(vehicleid));
			SetPlayerChatBubble(playerid, string, COLOR_ACTION, 20.0, 5000);
		}

		case 1: { 
			string = (driver) 
				? sprintf("rolls up the front-left window of the %s.", ReturnVehicleName(vehicleid))
				: sprintf("rolls down the front-left window of the %s.", ReturnVehicleName(vehicleid));
			SetPlayerChatBubble(playerid, string, COLOR_ACTION, 20.0, 5000);
		}

		case 2: { 
			string = (passenger) 
				? sprintf("rolls up the front-right window of the %s.", ReturnVehicleName(vehicleid))
				: sprintf("rolls down the front-right window of the %s.", ReturnVehicleName(vehicleid));
			SetPlayerChatBubble(playerid, string, COLOR_ACTION, 20.0, 5000);
		}

		case 3: { 
			string = (backleft) ? sprintf("rolls up the rear-left window of the %s.", ReturnVehicleName(vehicleid)) : sprintf("rolls down the rear-left window of the %s.", ReturnVehicleName(vehicleid));
			SetPlayerChatBubble(playerid, string, COLOR_ACTION, 20.0, 5000);
		}

        case 4: { 
			string = (backright) ? sprintf("rolls up the rear-right window of the %s.", ReturnVehicleName(vehicleid)) : sprintf("rolls down the rear-right window of the %s.", ReturnVehicleName(vehicleid));
			SetPlayerChatBubble(playerid, string, COLOR_ACTION, 20.0, 5000);
		}
	}

	if ( driver == 0 || passenger == 0 || backleft == 0 || backright == 0 ) {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] = false ;
	}

	else if ( driver == 1 && passenger == 1 && backleft == 1 && backright == 1 ) {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ] = true ;
	}

    SetVehicleParamsCarWindows(GetPlayerVehicleID(playerid), driver, passenger, backleft, backright);
    return 1;
}


CMD:helmet(playerid, params[]) {

	return cmd_seatbelt(playerid, params);
}

CMD:sb(playerid, params[]) {

	return cmd_seatbelt(playerid, params);
}

// /seatbelt - fastens or unfastens your seatbelt.
CMD:seatbelt(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new vehicleid = GetPlayerVehicleID ( playerid ) ;

	if ( ! vehicleid ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not in a vehicle!");
	}

	new specifier [ 32] ;

	switch ( PlayerVar [ playerid ] [ player_hasseatbelton ] ) {

		case false: {

			if ( IsABike ( vehicleid ) ) {

			    format ( specifier, sizeof ( specifier ), "helmet" ) ;
			    SetPlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM, 18645, 2, 0.101, -0.0, 0.0, 5.50, 84.60, 83.7, 1, 1, 1);
			}

			else format ( specifier, sizeof ( specifier ), "seatbelt" ) ;
			PlayerVar [ playerid ] [ player_hasseatbelton ] = true ;
			ProxDetectorEx(playerid, 30, COLOR_ACTION, "**",  sprintf("puts their %s on.", specifier), .annonated=true);
		}

		case true : {
			if ( IsABike ( vehicleid ) ) {

			    format ( specifier, sizeof ( specifier ), "helmet" ) ;
				RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM);
			}

			else format ( specifier, sizeof ( specifier ), "seatbelt" ) ;
			
			PlayerVar [ playerid ] [ player_hasseatbelton ] = false ;
			ProxDetectorEx(playerid, 30, COLOR_ACTION, "**",  sprintf("takes their %s off.", specifier), .annonated=true);
		}
	}

	return true ;
}

CMD:cl(playerid) {

	return cmd_carlights(playerid);
}

// /carlights - toggles the headlights.
CMD:carlights(playerid) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new vehicleid = GetPlayerVehicleID ( playerid ) ;

	if ( ! vehicleid ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not in a vehicle!");
	}

	if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
	    return SendClientMessage(playerid, COLOR_ERROR, "You can't do this as you're not the driver.");

	switch (GetLightStatus(vehicleid))
	{
	    case false:
	    {
	        SetLightStatus(vehicleid, true);
			ProxDetectorEx(playerid, 30, COLOR_ACTION, "**", sprintf("switches on the lights of the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
			ShowInfoText(playerid, "~y~~h~~h~Lights On", 3000);
		}
		case true:
		{
		    SetLightStatus(vehicleid, false);
			ProxDetectorEx(playerid, 30, COLOR_ACTION, "**", sprintf("turns off lights of the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
			ShowInfoText(playerid, "~y~~h~Lights Off", 3000);
		}
	}

	return true ;
}

CMD:lights(playerid)
{
	return cmd_carlights(playerid);
}


// /cartrunkrange - sets how close you must be to a trunk.
CMD:cartrunkrange(playerid, params[]) {

	new Float: range ;

	if ( sscanf ( params, "f", range ) ) {

		return SendClientMessage(playerid, -1, "/cartrunkrange[trunk-radius]" ) ;
	}

	new vehicleid = INVALID_VEHICLE_ID;

	if ( ! IsPlayerInAnyVehicle(playerid) ) {
		vehicleid = GetClosestVehicleEx(playerid, 7.5);
	}

	else vehicleid = GetPlayerVehicleID(playerid);

	if ( vehicleid == INVALID_VEHICLE_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any vehicle!");
	}

	if (IsAircraft(vehicleid) || IsABoat(vehicleid) || IsABike(vehicleid))
	{
		return SendClientMessage(playerid, COLOR_ERROR, "This vehicle doesn't have a trunk!");
	}

	new Float: x, Float: y, Float: z ;
	GetPosBehindVehicle ( vehicleid, x, y, z );

	if ( IsPlayerInRangeOfPoint(playerid, range, x, y, z ) || GetPlayerVehicleID(playerid) == vehicleid ) {

		SendClientMessage(playerid, -1, sprintf("Found vehicle %d at trunk range %0.3f", vehicleid, range ) ) ;
	}

	return SendClientMessage(playerid, -1, "None found." ) ;
}


// /cartrunk - opens or closes the trunk.
CMD:cartrunk(playerid, params[]) {

	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
	new vehicleid = INVALID_VEHICLE_ID;

	if ( ! IsPlayerInAnyVehicle(playerid) ) {
		vehicleid = GetClosestVehicleEx(playerid, 7.5);
	}

	else vehicleid = GetPlayerVehicleID(playerid);

	if ( vehicleid == INVALID_VEHICLE_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any vehicle!");
	}

	if (IsAircraft(vehicleid) || IsABoat(vehicleid) || IsABike(vehicleid))
	{
		return SendClientMessage(playerid, COLOR_ERROR, "This vehicle doesn't have a trunk!");
	}

	new Float: x, Float: y, Float: z ;
	GetPosBehindVehicle ( vehicleid, x, y, z );

	new Float: range = 2.5 ;

	if ( IsPlayerInRangeOfPoint(playerid, range, x, y, z ) || GetPlayerVehicleID(playerid) == vehicleid ) {

		switch (GetTrunkStatus ( vehicleid )) {
		    case false: {

				if ( GetDoorStatus ( vehicleid ) ) {

					return SendClientMessage(playerid, COLOR_ERROR, "This vehicle is locked.");
				}

				SendServerMessage ( playerid, COLOR_BLUE, "Car Trunk", "A3A3A3", "Available commands: /cartrunkstoregun (/ctsgun), /cartrunktakegun (/cttgun), /cartrunkcheck (/cartrunkshow)");
				SendClientMessage ( playerid, COLOR_BLUE, "Storage:{A3A3A3} /cartrunkstoredrug (/ctsdrug), /cartrunktakedrug (/cttdrug)");
				SendClientMessage ( playerid, COLOR_BLUE, "Burglary:{A3A3A3} /cartrunkstoreburglary (/ctsburg), /cartrunktakeburglary (/cttburg)");

		        SetTrunkStatus(vehicleid, true);
				ProxDetectorEx(playerid, 30, COLOR_ACTION, "**", sprintf("pops open the trunk of the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
			}
			case true:
			{
			    SetTrunkStatus(vehicleid, false);
				ProxDetectorEx(playerid, 30, COLOR_ACTION, "**", sprintf("pushes the trunk of the %s closed.", ReturnVehicleName ( vehicleid )), .annonated=true);
			}
		}
	}

	else return SendClientMessage(playerid, COLOR_ERROR, "Not near trunk!");

	return true ;
}

// /carhood - opens or closes the hood.
CMD:carhood(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
    
	new vehicleid = Vehicle_GetClosestEntity(playerid);

	if ( vehicleid == INVALID_VEHICLE_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "You're not near any vehicle!");
	}

	if (IsAircraft(vehicleid) || IsABoat(vehicleid) || IsABike(vehicleid))
	{
		return SendClientMessage(playerid, COLOR_ERROR, "This vehicle doesn't have a hood!");
	}

	new Float: x, Float: y, Float: z ;
	GetPosInfrontVehicle ( vehicleid, x, y, z );

	if ( IsPlayerInRangeOfPoint(playerid, 2.0, x, y, z ) ) {

		switch (GetHoodStatus ( vehicleid )) {
		    case false: {

				if ( GetDoorStatus ( vehicleid ) ) {

					return SendClientMessage(playerid, COLOR_ERROR, "This vehicle is locked.");
				}

		        SetHoodStatus(vehicleid, true);
				ProxDetectorEx(playerid, 30, COLOR_ACTION, "**", sprintf("pops open the hood of the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
			}
			case true:
			{
			    SetHoodStatus(vehicleid, false);
				ProxDetectorEx(playerid, 30, COLOR_ACTION, "**", sprintf("pushes the hood of the %s closed.", ReturnVehicleName ( vehicleid )), .annonated=true);
			}
		}
	}

	else SendClientMessage(playerid, COLOR_ERROR, "Not near hood!");

	return true ;
}

// /detach - detaches a trailer.
CMD:detach(playerid, params[])
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
    
	if( !IsPlayerInAnyVehicle(playerid) )
	{
	    SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be in a vehicle.");
	    return 1;
	}

	new vModel = GetVehicleModel( GetPlayerVehicleID( playerid ) );

	if ( vModel != 403 && vModel != 514 && vModel != 515 && vModel != 552 ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You are not driving a truck that can haul a trailer.");
	}

	if(IsTrailerAttachedToVehicle(GetPlayerVehicleID(playerid))) {
		DetachTrailerFromVehicle(GetPlayerVehicleID(playerid));
		SendClientMessage(playerid, COLOR_YELLOW, "Trailer detached.") ;
		return true ;
	}
	return 1;
}

// /carattach - attaches a tow or trailer.
CMD:carattach(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
    
	if( !IsPlayerInAnyVehicle(playerid) )
	{
	    SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be in a vehicle.");
	    return 1;
	}

	new Float:Px,Float:Py,Float:Pz;
	GetPlayerPos(playerid,Px,Py,Pz);
	new Float:vX,Float:vY,Float:vZ;

	if ( GetVehicleModel( GetPlayerVehicleID( playerid ) ) != 525 ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle isn't powerful enough to tow other cars. Get inside a towtruck.");
	}	

	new veh_enum_id ;

	for ( new i, j = sizeof ( Vehicle ); i < j ; i ++ ) {

		GetVehiclePos(i,vX,vY,vZ);

		if ( ( floatabs ( Px - vX ) < 7.0 ) && ( floatabs ( Py - vY ) < 7.0 ) && ( floatabs ( Pz - vZ ) < 7.0 ) && ( i != GetPlayerVehicleID ( playerid ) ) ) {

			veh_enum_id = Vehicle_GetEnumID(i) ;

			if ( veh_enum_id == -1 ) {

				SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't attach this car (invalid enum ID).");
				return true ;
			}

			if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] == i ) {

				if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_PLAYER && Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FACTION ) {

					SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only attach player or faction vehicles.");
					return true ;
				}

				if ( IsVehicleOccupied (  Vehicle [ veh_enum_id] [ E_VEHICLE_ID ] ) ) {
					SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This vehicle is occupied. You can only attach unoccupied vehicles.");
					return true ;
				}

				if(IsTrailerAttachedToVehicle(GetPlayerVehicleID(playerid))) {

					SetDoorStatus ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ] );
					DetachTrailerFromVehicle(GetPlayerVehicleID(playerid));
					SendServerMessage(playerid, COLOR_YELLOW, "Attach", "A3A3A3", "Car untowed!");
					return true ;
				}

				else {
					AttachTrailerToVehicle(i,GetPlayerVehicleID(playerid));
					SendServerMessage(playerid, COLOR_YELLOW, "Attach", "A3A3A3", "You've towed a car!");
					SendAdminMessage(sprintf("[Attached Vehicle] (%d) %s has attached vehicle ID %d to their car. Check to avoid abuse!", playerid, ReturnRPName(playerid), i ) );
					SetDoorStatus ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], true );

					return true ;
				}
			}
		}
	}

	SendClientMessage(playerid, COLOR_ERROR, "You're not near any valid vehicle.") ;

	return 1;
}

// /cardoor - opens or closes a door.
CMD:cardoor(playerid, params[]) 
{
	if ( IsPlayerIncapacitated(playerid, false) )  return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;

	new vehicleid = INVALID_VEHICLE_ID;
	new seat = -1, newstate = -1;
	// new lf, rf, lr, rr;

	if ( ! IsPlayerInAnyVehicle(playerid) ) {
		vehicleid = GetClosestVehicleEx(playerid, 5.0);
	}

	else vehicleid = GetPlayerVehicleID(playerid);

	if ( vehicleid == INVALID_VEHICLE_ID ) return SendClientMessage(playerid, COLOR_ERROR, "You're not near any vehicle!");
	if ( !IsACar(vehicleid) ) return true;
	if (GetDoorStatus ( vehicleid ) ) return SendClientMessage(playerid, COLOR_ERROR, "The vehicle doors are locked.");

	new veh_enum_id = Vehicle_GetEnumID (vehicleid);
	if ( veh_enum_id == -1 ) return SendClientMessage(playerid, COLOR_ERROR, "You're not near any proper vehicle! (couldn't fetch ID)");

	if (GetPlayerVehicleID(playerid) == vehicleid)
	{
		seat = GetPlayerVehicleSeat(playerid);
	} 
	else
	{
		seat = GetVehicleClosestSeatToPlayer(vehicleid, playerid);
	}
		
	if (!strcmp(params, "open", true))
	{
		newstate = VEHICLE_PARAMS_ON;
	}
	else if (!strcmp(params, "close", true))
	{
		newstate = VEHICLE_PARAMS_OFF;
	}
	else if (params[0] != 1)
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/cardoor [open/close]");
	}

	if (seat != -1)
	{
		new oldstate = IsVehicleDoorOpen(vehicleid, seat, false, veh_enum_id);
		if (newstate == -1) newstate = (oldstate == VEHICLE_PARAMS_ON ? VEHICLE_PARAMS_OFF : VEHICLE_PARAMS_ON);
		SetVehicleDoorOpen(vehicleid, seat, newstate, veh_enum_id);

        if (newstate == VEHICLE_PARAMS_ON)
	    {
	    	ProxDetectorEx(playerid, 30, COLOR_ACTION, "**",  sprintf("opens the door of the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);
	    }
	    else ProxDetectorEx(playerid, 30, COLOR_ACTION, "**",  sprintf("closes the door of the %s.", ReturnVehicleName ( vehicleid )), .annonated=true);

		Vehicle[veh_enum_id][E_VEHICLE_DOOR_STATE][seat] = newstate;
	}

	return true ;
}

// /vehiclename - shows the name of the vehicle model.
CMD:vehiclename(playerid, params[]) {

	new vehicleid = GetPlayerVehicleID ( playerid ) ;

	if (!vehicleid){
		return SendClientMessage(playerid, COLOR_ERROR, "You're not in a vehicle!");
	}

    new modelid = GetVehicleModel(vehicleid);

	new string[64];
	format(string, sizeof(string), "Current Vehicle:{DEDEDE} %s [%d]", ReturnVehicleName(vehicleid), modelid);
	SendClientMessage ( playerid, COLOR_HINT, string ) ; 

	return true;

}


// /mydups - lists the duplicate keys you hold.
CMD:mydups(playerid, params[]) {

	SendClientMessage(playerid, -1, "Your Duplicate Keys:");

	new bool:hasVehKey = false;

	for (new i = 0; i < 2; i++) {

		new sqlid = Character [ playerid ] [ E_CHARACTER_VEH_KEYS ] [ i ];

		if (sqlid != -1) {
			SendClientMessage(playerid, -1, sprintf("{3F88C5}Vehicle Key [Slot %d] {DEDEDE}| SQL ID: %d - use /mykeys for details.", i + 1, sqlid));
			hasVehKey = true;
		}
	}

	if (!hasVehKey)
		SendClientMessage(playerid, -1, "{3F88C5}Vehicle {DEDEDE}| None");

	if(Character [ playerid ] [ E_CHARACTER_PROP_DUP ] == -1) {
		SendClientMessage(playerid, -1, "{DDB967}Property {DEDEDE}| None");
	} else {
		SendClientMessage(playerid, -1, sprintf("{DDB967}Property {DEDEDE}| %d", Character [ playerid ] [ E_CHARACTER_PROP_DUP ] ));
	}

	return true;
}

CMD:givecarkey(playerid, params[]){ return cmd_vdup(playerid, params); }
CMD:givekey(playerid, params[]){ return cmd_vdup(playerid, params); }
CMD:vkey(playerid, params[]){ return cmd_vdup(playerid, params); }
// /vdup [player] - gives a duplicate key of your vehicle to another player.
CMD:vdup(playerid, params[]){

	if(IsPlayerIncapacitated(playerid, false))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use this command right now.");
	
	new target;

	if(sscanf(params, "k<player>", target)) {
		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/vdup [playerid]");
		return SendServerMessage ( playerid, COLOR_ERROR, "Warning", "A3A3A3", "Duplicate keys are saved. Use /changelock to revoke a key.");
	}

	if(!IsPlayerConnected(target))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Target is not connected.");

	if(!IsPlayerNearPlayer(playerid, target, 10.0))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be closer to your taget to give them the keys.");

	if(playerid == target)
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You already have keys to your own vehicle.");

	if(!IsPlayerInAnyVehicle(playerid))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a vehicle to duplicate it's keys.");

	new vehicleid = GetPlayerVehicleID(playerid);
	new veh_enum_id = Vehicle_GetEnumID ( vehicleid );

	if(Vehicle[veh_enum_id][E_VEHICLE_OWNER] != Character[playerid][E_CHARACTER_ID])
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only duplicate keys to vehicles you own!");

	if (Character[target][E_CHARACTER_VEH_KEYS][0] != -1 && Character[target][E_CHARACTER_VEH_KEYS][1] != -1)
    	return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This player already has too many duplicate keys. (max 2)");

	SendServerMessage ( playerid, COLOR_SECURITY, "Keys", "A3A3A3", sprintf("You have given %s a pair of keys to your %s.", ReturnSettingsName(target, playerid), ReturnVehicleName(vehicleid)));
	SendServerMessage ( target, COLOR_SECURITY, "Keys", "A3A3A3", sprintf("%s has given your a pair of keys to their %s.", ReturnSettingsName(playerid, target), ReturnVehicleName(vehicleid)));

	GiveVehicleKey(target, veh_enum_id);

	return true;
}

// Gives a player a duplicate key to a vehicle.
GiveVehicleKey(playerid, veh_enum_id) {

    new slot = -1;

    if (Character[playerid][E_CHARACTER_VEH_KEYS][0] == -1) slot = 0;
    else if (Character[playerid][E_CHARACTER_VEH_KEYS][1] == -1) slot = 1;

    if (slot == -1) return false; 

    new sqlid = Vehicle[veh_enum_id][E_VEHICLE_SQLID];
    Character[playerid][E_CHARACTER_VEH_KEYS][slot] = sqlid;

    new query[256];
    format(query, sizeof(query),
        "INSERT INTO character_vehicle_keys (character_id, vehicle_sqlid, owner_character_id) VALUES (%d, %d, %d)",
        Character[playerid][E_CHARACTER_ID],
        sqlid,
        Vehicle[veh_enum_id][E_VEHICLE_OWNER]);
    mysql_tquery(mysql, query);

    return true;
}


// Returns true if the player holds a duplicate key to a vehicle.
HasCarDuplicateKey(playerid, veh_enum_id) {

    new sqlid = Vehicle[veh_enum_id][E_VEHICLE_SQLID];

    if (Character[playerid][E_CHARACTER_VEH_KEYS][0] == sqlid) return true;
    if (Character[playerid][E_CHARACTER_VEH_KEYS][1] == sqlid) return true;

    return false;
}

// /vdropkeys - drops all of your duplicate keys.
CMD:vdropkeys(playerid, params[]) {

    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use this command right now.");

    new sqlid;
    if (sscanf(params, "i", sqlid))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/vdropkeys [vehicle_sqlid] - use /mykeys to see your key IDs.");

    new dropped = false;

    for (new i = 0; i < 2; i++) {

        if (Character[playerid][E_CHARACTER_VEH_KEYS][i] == sqlid) {

            Character[playerid][E_CHARACTER_VEH_KEYS][i] = -1;
            dropped = true;

            new query[256];
            format(query, sizeof(query),
                "DELETE FROM character_vehicle_keys WHERE character_id = %d AND vehicle_sqlid = %d",
                Character[playerid][E_CHARACTER_ID], sqlid);
            mysql_tquery(mysql, query);

            SendServerMessage(playerid, COLOR_SECURITY, "Keys", "A3A3A3", "You have discarded the duplicate key.");
            break;
        }
    }

    if (!dropped)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have a key with that vehicle SQL ID.");

    return true;
}


// /mykeys - lists the keys you hold.
CMD:mykeys(playerid, params[]) {

    new bool:hasAny = false;
    SendClientMessage(playerid, 0x4373D3FF, "__________________ Your Duplicate Vehicle Keys __________________");

    for (new i = 0; i < 2; i++) {

        new sqlid = Character[playerid][E_CHARACTER_VEH_KEYS][i];

        if (sqlid == -1) continue;

        hasAny = true;
        new query[256];
        format(query, sizeof(query),"SELECT v.vehicle_modelid, c.player_name FROM vehicles v JOIN characters c ON c.player_id = v.vehicle_owner WHERE v.vehicle_sqlid = %d LIMIT 1", sqlid);
        mysql_tquery(mysql, query, "OnMyKeysResult", "ii", playerid, i);
    }

    if (!hasAny)
        SendClientMessage(playerid, -1, "You have no duplicate keys.");

    return true;
}

forward OnMyKeysResult(playerid, slot);
// MySQL callback: shows the result of /mykeys.
public OnMyKeysResult(playerid, slot) {

    if (!cache_num_rows()) {

        new msg[128];
        format(msg, sizeof(msg), "Slot %d | SQL ID: %d | Vehicle no longer exists.", slot + 1, Character[playerid][E_CHARACTER_VEH_KEYS][slot]);
        SendClientMessage(playerid, COLOR_ERROR, msg);
        return true;
    }

    new modelid, ownername[MAX_PLAYER_NAME];
    cache_get_value_name_int(0, "vehicle_modelid", modelid);
    cache_get_value_name(0, "player_name", ownername, MAX_PLAYER_NAME);

    new msg[128];
    format(msg, sizeof(msg), "Slot %d | SQL ID: %d | %s | Owner: %s",
        slot + 1,
        Character[playerid][E_CHARACTER_VEH_KEYS][slot],
        ReturnVehicleName(modelid),
        ownername);
    SendClientMessage(playerid, COLOR_HINT, msg);
    return true;
}

// /vandalcar - vandalises a vehicle.
CMD:vandalcar(playerid, params[])
{
    if(GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        SendClientMessage(playerid, COLOR_SERVER, "You must be on foot to vandalize the car");
        return 1;
    }

    new vehicleid = Vehicle_GetClosestEntity(playerid);
    if(vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, COLOR_SERVER, "You are not close to any vehicle");
        return 1;
    }

    // Vandal Car
    SetVehicleAngularVelocity(vehicleid, 0.02, 0.02, 0);

    new animChoice = random(4);    
    switch(animChoice)
    {
        case 0: ApplyAnimation(playerid, "gangs", "shake_cara", 4.1, 0, 0, 0, 0, 0);
        case 1: ApplyAnimation(playerid, "gangs", "shake_carK", 4.1, 0, 0, 0, 0, 0);
        case 2: ApplyAnimation(playerid, "gangs", "shake_carSH", 4.1, 0, 0, 0, 0, 0);
        case 3: ApplyAnimation(playerid, "police", "Door_Kick", 4.1, 0, 0, 0, 0, 0);
    }

    new 
        Float:carPos[3],
        Float:range = 10.0;

    GetVehiclePos(vehicleid, carPos[0], carPos[1], carPos[2]);

    foreach(new pid: Player)
    {
        if (IsPlayerConnected(pid)) 
		{
			new Float:dist = GetPlayerDistanceFromPoint(pid, carPos[0], carPos[1], carPos[2]);

			if (dist <= range)
			{
        		PlayerPlaySound(pid, 1140, carPos[0], carPos[1], carPos[2]);
			}
		}

	}

    return 1;
}
