// ============================================================================
// File: police/systems/911.pwn
// Emergency alerts: Log911Call records a 911 call, Alarm_SendPoliceAlert /
// Robbery_SendPoliceAlert notify police, and /lastalarm, /lastrobbery, /lastburglary mark the
// last call on an officer's map.
// Commands: /admin911 /lastrobbery /lastalarm /lastburglary
// ============================================================================

// /admin911 [police/fire] [number] [text] - (staff) sends a test 911 call.
CMD:admin911(playerid, params[])
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) return SendServerMessage (playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");

	new service[10], call_text[100], ph_number, random_number[12], string[144], services[40];
    if (sscanf(params, "s[10] ds[100]", service, ph_number, call_text)) return SendClientMessage(playerid, -1, "/admin911 [police/fire] [ph number (0 for random)] [call text]");

	if (!strcmp(service, "Police", true))
	{
		PlayerVar [ playerid ] [ E_PLAYER_PHONE_EMERGENCY ] = 1; // police
	}
	else if (!strcmp(service, "Medic", true))
	{
		PlayerVar [ playerid ] [ E_PLAYER_PHONE_EMERGENCY ] = 2; // fire/ems
	}
	else
	{	
		SendClientMessage(playerid, -1, "Service must be (\"police\", \"medic\"");
		return 0;
	}

	if (ph_number) format(random_number, sizeof(random_number), "%d", ph_number);
	else format (random_number, sizeof(random_number), "16%d - %d%d%d", random(9),random(9),random(9),random(9));
	
	new address [ 64 ], zone [ 64 ], Float: x, Float: y, Float: z  ;
	GetPlayerPos ( playerid, x, y, z ) ;
	
	if (GetPlayerVirtualWorld(playerid) > 0)
	{
		// They are probably in a property, so use the exterior of that if they are
		new property = Property_GetInside(playerid);
		if (property != INVALID_PROPERTY_ID)
		{
			x = Property [ property ] [ E_PROPERTY_EXT_X ]; 
			y = Property [ property ] [ E_PROPERTY_EXT_Y ]; 
			z = Property [ property ] [ E_PROPERTY_EXT_Z ];
		}
	}

	GetCoords2DZone(x, y, zone, sizeof ( zone ));
	GetPlayerAddress(x, y, address );

	Server [ E_SERVER_LAST_911_POS_X ] = x ;
	Server [ E_SERVER_LAST_911_POS_Y ] = y ;
	Server [ E_SERVER_LAST_911_POS_Z ] = z ;
	Server [ E_SERVER_LAST_911_TYPE ] = 0;

	format ( string, sizeof ( string ), "[Emergency]: %s", call_text ) ;
	if(PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 1)
		format ( services, sizeof ( services ), "[Services Requested]: Police") ;
	else if(PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2)
		format ( services, sizeof ( services ), "[Services Requested]: Medic") ;

	new color = COLOR_FACTION; // police color
	if (PlayerVar[playerid][E_PLAYER_PHONE_EMERGENCY] == 2) color = COLOR_FIRE;
	//if (IsPlayerInMallArea(playerid)) Server [ E_SERVER_LAST_911_TYPE ] = 1;

	foreach(new policeid: Player) 
	{
		if (policeid == playerid || Faction_Can(policeid, FAC_CAP_911) || Faction_Can(policeid, FAC_CAP_MEDICAL))
		{
			SendClientMessage(policeid, color, sprintf("[Dispatch Forwards 911 Call]: From %s", random_number ) ) ;
			SendClientMessage(policeid, color, sprintf("[Location]: %s, %s", address, zone ) ) ;
			ZMsg_SendClientMessage(policeid, color, services);
			ZMsg_SendClientMessage(policeid, color, string);
			SendClientMessage(policeid, color, "To track this 911 call, type /lastalarm. (Puts GPS blip on map)" ) ;
		}
	}

	return 1;
}

// /lastrobbery - marks the last robbery location on an officer's map.
CMD:lastrobbery(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;

	if ( ! factionid ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in a faction!");
	}

	new faction_enum_id = Faction_GetEnumID(factionid ); 

	if ( faction_enum_id == INVALID_FACTION_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");
	}

	if (!IsPlayerInLEAFaction(playerid) && !IsPlayerInMedicFaction(playerid)) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not in an emergency services faction.");
	}

	if (Character[ playerid ] [ E_CHARACTER_FACTIONTIER ] > 3)
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You are unable to use this command." ) ;
	}

	DisablePlayerCheckpoint(playerid);
    GPS_MarkLocation ( playerid, "The last ~r~911 call~w~ has been ~b~marked~w~!", E_GPS_COLOR_SCRIPT, Server [ E_SERVER_LAST_911_POS_X ], Server [ E_SERVER_LAST_911_POS_Y ], Server [ E_SERVER_LAST_911_POS_Z ] ) ;
    //SendClientMessage(playerid, COLOR_INFO, "Last 911 call has been marked on your minimap!");

	return true ;
}

CMD:lastalarm(playerid, params[]) {

	return cmd_lastrobbery(playerid, params);
}
CMD:lastburglary(playerid, params[]) {

	return cmd_lastrobbery(playerid, params);
}



// Alerts police to a robbery of a shop actor.
Robbery_SendPoliceAlert(actorid, playerid) {

	new Float: x, Float: y, Float: z ;
	GetActorPos(actorid, x, y, z );

	new address [ 64 ], zone [ 64 ], area [ 12 ], city [ 64 ] ;

	GetPlayerAddress(x, y, address) ;
	GetCoords2DZone(x, y, zone, sizeof ( zone ));
	GetPlayerAreaZone(x, y, area ) ;
	GetCoords2DMainZone(x, y, city, sizeof ( city ) ) ;

	new disMsg[512];
	new desc[256];

	if (IsPlayerMasked(playerid))
	{
		format(desc, sizeof(desc), "The suspect was masked. ((** description of %s **))", ReturnSettingsName(playerid, playerid));
	}
	else
	{
		format(desc, sizeof(desc), "The suspect was NOT masked. ((** description of %s **))", ReturnSettingsName(playerid, playerid));
	}

	format(disMsg, sizeof(disMsg),
		"**[Store Robbery Alert]:**\n"\
		"**[Location]:** %s, %s, %s\n"\
		"**[Services Requested]:** Police\n"\
		"**[Description]:** The property is being robbed!\n"\
		"%s",
		address, zone, city, desc
	);

	DCC_Send911RobberyMessage(disMsg);
	Log911Call(playerid, 3, desc, x, y, z, address, zone, city);

	Server [ E_SERVER_LAST_911_POS_X ] = x ;
	Server [ E_SERVER_LAST_911_POS_Y ] = y ;
	Server [ E_SERVER_LAST_911_POS_Z ] = z ;
	Server [ E_SERVER_LAST_911_TYPE ] = 0 ;

	new random_number [ 12 ], string [ 256 ] ;

	foreach(new policeid: Player) 
	{
		if (IsPlayerInLEAFaction(policeid, true)) 
		{
			format ( random_number, sizeof ( random_number ), "16%d - %d%d%d", random(9),random(9),random(9),random(9) ) ;
			
			format ( string, sizeof ( string ), "[Dispatch Forwards 911 Call]: From: %s", random_number )  ;
			ZMsg_SendClientMessage(policeid, COLOR_FACTION, string);

			format ( string, sizeof ( string ), "[Location] %s, %s, %s, %s", address, zone, area, city ) ;
			ZMsg_SendClientMessage(policeid, COLOR_FACTION, string);

			SendClientMessage(policeid, COLOR_FACTION, "[Services Requested]: Police");

			ZMsg_SendClientMessage(policeid, COLOR_FACTION, "[Description]: The property is getting robbed! Send a unit here quickly!");
		
			if ( IsPlayerMasked(playerid) ) {
				format ( string, sizeof ( string ), "The perpetrator had his face covered! {C2A2DA}(** description of %s **)", ReturnSettingsName ( playerid, policeid ) ) ;
			}
			else format ( string, sizeof ( string ), "I saw his face, it wasn't covered! {C2A2DA}(** description of %s **)", ReturnSettingsName ( playerid, policeid ) ) ;
			
			ZMsg_SendClientMessage(policeid, COLOR_FACTION, string ) ;

			SendClientMessage(policeid, COLOR_FACTION, "To track this 911 call, type /lastalarm. (Puts GPS blip on map)" ) ;
		}
	}
}

// Alerts police to a vehicle alarm.
Alarm_SendPoliceAlert(vehicleid) {

	new Float: x, Float: y, Float: z ;
	GetVehiclePos ( vehicleid, x, y, z ) ;

	new address [ 64 ], zone [ 64 ], area [ 12 ], city [ 64 ] ;

	GetPlayerAddress(x, y, address) ;
	GetCoords2DZone(x, y, zone, sizeof ( zone ));
	GetPlayerAreaZone(x, y, area ) ;
	GetCoords2DMainZone(x, y, city, sizeof ( city ) ) ;

	Server [ E_SERVER_LAST_911_POS_X ] = x ;
	Server [ E_SERVER_LAST_911_POS_Y ] = y ;
	Server [ E_SERVER_LAST_911_POS_Z ] = z ;
	Server [ E_SERVER_LAST_911_TYPE ] = 0 ;

	new random_number [ 12 ], string [ 256 ] ;

	foreach(new policeid: Player)
	{
		if (IsPlayerInLEAFaction(policeid, true))
		{ 
			format ( random_number, sizeof ( random_number ), "16%d - %d%d%d", random(9),random(9),random(9),random(9) ) ;
			
			format ( string, sizeof ( string ), "[Dispatch Forwards 911 Call]: From: %s", random_number )  ;
			ZMsg_SendClientMessage(policeid, COLOR_FACTION, string);

			format ( string, sizeof ( string ), "[Location] %s, %s, %s, %s", address, zone, area, city ) ;
			ZMsg_SendClientMessage(policeid, COLOR_FACTION, string);

			SendClientMessage(policeid, COLOR_FACTION, "[Services Requested]: Police");

			ZMsg_SendClientMessage(policeid, COLOR_FACTION, sprintf("[Description]: A car alarm is going off! I-I think it was a %s!", ReturnVehicleName ( vehicleid ) ));
			SendClientMessage(policeid, COLOR_FACTION, "To track this 911 call, type /lastalarm. (Puts GPS blip on map)" ) ;
		}
	}
}

// Records a 911 call in the database (`mdc_911_calls`).
Log911Call(playerid, call_type, const message[], Float:x, Float:y, Float:z, const address[], const zone[], const city[])
{
    new query[512];

    mysql_format(mysql, query, sizeof(query),
		"INSERT INTO mdc_911_calls \
		(caller_number, caller_char_id, call_type, message, pos_x, pos_y, pos_z, address, zone, city) \
		VALUES (%d, %d, %d, '%e', %f, %f, %f, '%e', '%e', '%e')",
		Character[playerid][E_CHARACTER_PHONE_NUMBER],
		Character[playerid][E_CHARACTER_ID],
		call_type,
		message,
		x, y, z,
		address,
		zone,
		city
	);

    mysql_tquery(mysql, query);
}
