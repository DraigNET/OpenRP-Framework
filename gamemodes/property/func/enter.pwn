// ============================================================================
// File: property/func/enter.pwn
// Entering and leaving properties (/enter, /exit): checks locks, keys and faction access, then
// moves the player into the interior world.
// Commands: /enter /exit
// ============================================================================

new PlayerBurglaryProperty[MAX_PLAYERS] = { INVALID_PROPERTY_ID, ... };

#define COMBAT_ENTER_DELAY 20 // seconds after hurting/being hurt by a player before a property can be entered

// /enter - goes through the door you are standing at.
CMD:enter(playerid) {
	if ( IsPlayerIncapacitated(playerid, true) ) {
    
        return true ;
    }

	if (IsPlayerFading(playerid)) return true; // Make them wait first

    //if ( ! Gym_Enter(playerid) ) {

	Property_Enter(playerid);
	//}
	return true ;
}

// /exit - leaves the property you are in.
CMD:exit(playerid) {
	if ( IsPlayerIncapacitated(playerid, true) ) {
    
        return true ;
    }

	if (IsPlayerFading(playerid)) return true; // Make them wait first

    if ( ! Gym_Exit(playerid) ) {

		Property_Exit(playerid);
	}
	return true ;
}

// Moves the player into the nearest property (checks lock, fee, faction, keys).
Property_Enter(playerid) {
	new index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		//SendClientMessage(playerid, -1, "You're not near a valid property you can enter.");
		return true ;
	}

	if ( !IsPlayerInRangeOfPoint ( playerid, 5.0, Property [ index ] [ E_PROPERTY_EXT_X ], Property [ index ] [ E_PROPERTY_EXT_Y ], Property [ index ] [ E_PROPERTY_EXT_Z ] )) 
	{
		// Forbid exit when not outside
		return true ;
	}

	if ( ! PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ] && PlayerLastCombatAt [ playerid ] ) {

		new remaining = COMBAT_ENTER_DELAY - ( gettime ( ) - PlayerLastCombatAt [ playerid ] ) ;

		if ( remaining > 0 ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf ( "You were recently in combat. You can't enter for another %d second(s).", remaining ) ) ;
		}
	}

	// =========================================================
	// BURGLARY OVERRIDE (must be before locked/faction checks)
	// =========================================================

	if ( Burglary_ShouldOverrideEnter(playerid, index) )
	{
		return Burglary_Enter(playerid, index);
	}

	if ( Property [ index ] [ E_PROPERTY_LOCKED ] ) {

		return SendClientMessage(playerid, -1, "This property is locked.");
	}

	if ( Property [ index ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendClientMessage(playerid, -1, "This business type can't be entered.");
	}

	switch ( Property [ index ] [ E_PROPERTY_BUY_TYPE ] ) {
		case E_BUY_TYPE_DEALERSHIP, E_BUY_TYPE_GASSTATION, E_BUY_TYPE_MODSHOP: {
			return SendClientMessage(playerid, -1, "This business type can't be entered.");
		}
	}

	if ( Property [ index ] [ E_PROPERTY_FACTION ] != INVALID_PROPERTY_FACTION ) {
		if(Character[playerid][E_CHARACTER_FACTIONID] != Property [ index ] [ E_PROPERTY_FACTION ]) {
			return SendClientMessage(playerid, -1, "This property is faction restricted.");
		}
	}

	PlayerVar [ playerid ] [ E_PLAYER_LAST_PROPERTY_ENTERED ] = index ;
	PlayerVar [ playerid ] [ E_PLAYER_BIZ_MENU ] = index ;

	if ( Property [ index ] [ E_PROPERTY_FEE ] ) 
	{
		if (  Property_HasAccess ( playerid, index ) || Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ] == Property [ index ] [ E_PROPERTY_ID ] ) 
		{
			SendClientMessage(playerid, COLOR_YELLOW, sprintf("You weren't charged the entrance fee of $%s to enter this property as you own or rent it.",  IntegerWithDelimiter(Property [ index ] [ E_PROPERTY_FEE ] ) ) ) ;
		}
		else
		{
			new currentTime = gettime();
			new fee = Property[index][E_PROPERTY_FEE];

			// If player has previously paid AND cooldown still active → silent free entry
			if (PropertyEntryCooldown[playerid][index] != 0 &&
				currentTime - PropertyEntryCooldown[playerid][index] < PROPERTY_ENTRY_COOLDOWN)
			{
				// Silent free entry
			}
			else
			{
				// Cooldown expired OR first-time entry → must pay

				if (GetPlayerCash(playerid) < fee)
				{
					return SendClientMessage(playerid, COLOR_YELLOW,
						sprintf("You need at least $%s to enter this property.",
						IntegerWithDelimiter(fee)));
				}

				TakePlayerCash(playerid, fee, "Property entry fee");
				Property_AddMoneyToTill(playerid, fee, .margin=false);

				PropertyEntryCooldown[playerid][index] = currentTime;

				SendClientMessage(playerid, COLOR_YELLOW,
					sprintf("You've been charged the entrance fee of $%s to enter this property.",
					IntegerWithDelimiter(fee)));

				Property[index][E_PROPERTY_COLLECT] += fee;

				new query[128];
				mysql_format(mysql, query, sizeof(query),
					"UPDATE properties SET property_collect = %d WHERE property_id = %d",
					Property[index][E_PROPERTY_COLLECT],
					Property[index][E_PROPERTY_ID]);

				mysql_tquery(mysql, query);
			}
		}

	}

	// =========================================================
	// NORMAL PROPERTY ENTER
	// =========================================================

	SetPlayerInterior(playerid, Property [ index ] [ E_PROPERTY_INT_INT ]) ;
	SetPlayerVirtualWorld(playerid, Property [ index ] [ E_PROPERTY_INT_VW ]) ;
	//ORP_SetPlayerPos(playerid, Property [ index ] [ E_PROPERTY_INT_X ], Property [ index ] [ E_PROPERTY_INT_Y ], Property [ index ] [ E_PROPERTY_INT_Z ] + 0.1 );
	ORP_SetPosWithFade(playerid, Property [ index ] [ E_PROPERTY_INT_X ], Property [ index ] [ E_PROPERTY_INT_Y ], Property [ index ] [ E_PROPERTY_INT_Z ], FormatPropertyName(index));

	if ( Property [ index ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_BIZ ) {
		
		if(strcmp(Property [ index ] [ E_PROPERTY_NAME ], "Undefined", true)) {

			new name_style[64];

			switch(Property [ index ] [ E_PROPERTY_NAME_COLOR ]) {

				case 0: format ( name_style, sizeof ( name_style ), "~w~" ) ;
				case 1: format ( name_style, sizeof ( name_style ), "~r~" ) ;
				case 2: format ( name_style, sizeof ( name_style ), "~g~" ) ;
				case 3: format ( name_style, sizeof ( name_style ), "~b~" ) ;
				case 4: format ( name_style, sizeof ( name_style ), "~y~" ) ;
				case 5: format ( name_style, sizeof ( name_style ), "~p~" ) ;
				case 6: format ( name_style, sizeof ( name_style ), "~l~" ) ;
			}

           	//ShowPlayerSubtitle(playerid, sprintf("Welcome to %s%s", name_style, Property [ index ] [ E_PROPERTY_NAME ]), .showtime = 4000 );
			ShowZoneMessage(playerid, sprintf("%s%s", name_style, Property [ index ] [ E_PROPERTY_NAME ]), true);

		}
	}

	SetPlayerWeather(playerid, Property [ index ] [ E_PROPERTY_INT_WEATHER ]);

	if(Property [ index ] [ E_PROPERTY_INT_HOURS ] == -1)
	{
		SetPlayerTime(playerid, Server [ E_SERVER_TIME_HOURS], Server [ E_SERVER_TIME_MINUTES]);
	} else {
		SetPlayerTime(playerid, Property [ index ] [ E_PROPERTY_INT_HOURS ], Property [ index ] [ E_PROPERTY_INT_MINS ]);
	}
	
	if(Property [ index ] [ E_PROPERTY_INT_AUDIO_ON ])
	{
		if (strlen(Property [ index ] [ E_PROPERTY_INT_AUDIOURL ]))
		{
			ORP_PlayAudioStreamForPlayer ( playerid, Property [ index ] [ E_PROPERTY_INT_AUDIOURL ], Property [ index ] [ E_PROPERTY_INT_AUDIOX ], Property [ index ] [ E_PROPERTY_INT_AUDIOY ], Property [ index ] [ E_PROPERTY_INT_AUDIOZ ], 50.0, true );
		}
	}


	UpdateTabListForPlayer ( playerid );
	UpdateTabListForOthers ( playerid );

	PlayerPlaySound(playerid, 1, 0, 0, 0);

	if ( GetPlayerAdminLevel ( playerid ) > ADMIN_LVL_JUNIOR && PlayerVar[playerid][E_PLAYER_ADMIN_DUTY] ) {

		SendClientMessage(playerid, COLOR_YELLOW, 
			sprintf("[ADMIN/ENTER_PROP]: [ID %d] [SQL: %d] [Owner: %d] [Type: %d] [Buy Type: %d]", index, Property [ index ] [ E_PROPERTY_ID ], Property [ index ] [ E_PROPERTY_OWNER ],
			Property [ index ] [ E_PROPERTY_TYPE ], Property [ index ] [ E_PROPERTY_BUY_TYPE ]
	 	) ) ;
	}

	if (  Property [ index ] [ E_PROPERTY_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ] ) {

		SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "DEDEDE", sprintf("You have $%s waiting for you in your property till. (/propertycollect)", IntegerWithDelimiter ( Property [ index ] [ E_PROPERTY_COLLECT ] ) ) ) ;
	}

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Entered Property %d (SQL: %d)", index, Property [ index ] [ E_PROPERTY_ID ]));

	return true ;
}


// Moves the player out of the property they are in.
Property_Exit(playerid)
{
    // =========================================================
    // BURGLARY EXIT OVERRIDE (MUST BE FIRST)
    // =========================================================

    if (Burglary_IsPlayerInside(playerid))
	{
		new prop = PlayerBurglaryProperty[playerid];

		Burglary_Exit(playerid);

		if (prop == INVALID_PROPERTY_ID)
		{
			return true;
		}

		SetPlayerInterior(playerid, Property[prop][E_PROPERTY_EXT_INT]);
		SetPlayerVirtualWorld(playerid, Property[prop][E_PROPERTY_EXT_VW]);
		SetPlayerWeather(playerid, Server[E_SERVER_WEATHER]);
		SetPlayerTime(playerid, Server[E_SERVER_TIME_HOURS], Server[E_SERVER_TIME_MINUTES]);

		if (IsPlayerListeningToAudioStream(playerid))
		{
			ORP_StopAudioStreamForPlayer(playerid);
		}

		ORP_SetPosWithFade(playerid,
			Property[prop][E_PROPERTY_EXT_X],
			Property[prop][E_PROPERTY_EXT_Y],
			Property[prop][E_PROPERTY_EXT_Z]
		);
		return true;
	}

    // =========================================================
    // NORMAL PROPERTY EXIT
    // =========================================================

    new index = Property_GetClosestEntity(playerid, PROPERTY_NEAR_EXIT);

    if (index == INVALID_PROPERTY_ID)
    {
        //SendClientMessage(playerid, -1, "You're not near a valid property you can exit.");
        return true;
    }

    if (!IsPlayerInRangeOfPoint(playerid, 5.0,
        Property[index][E_PROPERTY_INT_X],
        Property[index][E_PROPERTY_INT_Y],
        Property[index][E_PROPERTY_INT_Z]))
    {
        return true;
    }

    SetPlayerInterior(playerid, Property[index][E_PROPERTY_EXT_INT]);
    SetPlayerVirtualWorld(playerid, Property[index][E_PROPERTY_EXT_VW]);

    ORP_SetPosWithFade(playerid,
        Property[index][E_PROPERTY_EXT_X],
        Property[index][E_PROPERTY_EXT_Y],
        Property[index][E_PROPERTY_EXT_Z]
    );

    SetPlayerWeather(playerid, Server[E_SERVER_WEATHER]);
    SetPlayerTime(playerid, Server[E_SERVER_TIME_HOURS], Server[E_SERVER_TIME_MINUTES]);

    if (IsPlayerListeningToAudioStream(playerid))
    {
        ORP_StopAudioStreamForPlayer(playerid);
    }

    UpdateTabListForPlayer(playerid);
    UpdateTabListForOthers(playerid);

    PlayerVar[playerid][E_PLAYER_LAST_PROPERTY_ENTERED] = INVALID_PROPERTY_ID;
    PlayerVar[playerid][E_PLAYER_FURNI_MODE] = INVALID_PROPERTY_ID;

    if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR && PlayerVar[playerid][E_PLAYER_ADMIN_DUTY])
    {
        SendClientMessage(playerid, COLOR_YELLOW,
            sprintf("[ADMIN/LEAVE_PROP]: [ID %d] [SQL: %d] [Owner: %d] [Type: %d] [Buy Type: %d]",
            index,
            Property[index][E_PROPERTY_ID],
            Property[index][E_PROPERTY_OWNER],
            Property[index][E_PROPERTY_TYPE],
            Property[index][E_PROPERTY_BUY_TYPE]
        ));
    }

    AddLogEntry(playerid, LOG_TYPE_SCRIPT,
        sprintf("Exited Property %d (SQL: %d)", index, Property[index][E_PROPERTY_ID]));

    return true;
}
 

// Returns the closest property entrance or exit within the radius, or INVALID_PROPERTY_ID.
Property_GetClosestEntity( playerid, type, Float: radius = PROPERTY_NEAREST_DIST )  {

	new Float: dis = 99999.99, Float: dis2, index = INVALID_PROPERTY_ID ;

	if(type == PROPERTY_NEAR_ENTER) { // Checking for EXTERIOR point!
		
		foreach(new x: Properties) {

			if ( Property [ x ] [ E_PROPERTY_ID ] != INVALID_PROPERTY_ID ) {

				dis2 = GetPlayerDistanceFromPoint(playerid, 
					Property [ x ] [ E_PROPERTY_EXT_X ], 
					Property [ x ] [ E_PROPERTY_EXT_Y ], 
					Property [ x ] [ E_PROPERTY_EXT_Z ]
				);

				if(dis2 < dis && GetPlayerInterior ( playerid ) == Property [ x ] [ E_PROPERTY_EXT_INT ] 
					&& GetPlayerVirtualWorld ( playerid ) == Property [ x ] [ E_PROPERTY_EXT_VW ] ) {

					dis = dis2;
					index = x;
				}
			}
		}

		if ( dis <= radius ) {

			return index;
		}

		else return INVALID_PROPERTY_ID ;
	}
 
	else if(type == PROPERTY_NEAR_EXIT) { // Checking for INTERIOR point!

		foreach(new x: Properties) {

			if ( Property [ x ] [ E_PROPERTY_ID ] != INVALID_PROPERTY_ID ) {

				dis2 = GetPlayerDistanceFromPoint(playerid, 
					Property [ x ] [ E_PROPERTY_INT_X ], 
					Property [ x ] [ E_PROPERTY_INT_Y ], 
					Property [ x ] [ E_PROPERTY_INT_Z ]
				);

				if(dis2 < dis && GetPlayerInterior ( playerid ) == Property [ x ] [ E_PROPERTY_INT_INT ] 
					&& GetPlayerVirtualWorld ( playerid ) == Property [ x ] [ E_PROPERTY_INT_VW ] ) {

					dis = dis2;
					index = x;
				}
			}
		}

		if ( dis <= radius ) {

			return index;
		}

		else return INVALID_PROPERTY_ID ;
		
	} else if (type == PROPERTY_NEAR_ANYWHERE) {

		index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER, radius ) ;

		if ( index == INVALID_PROPERTY_ID ) {
			index = Property_GetClosestEntity( playerid, PROPERTY_NEAR_EXIT, radius ) ;
		}

		return index;

	}

	return INVALID_PROPERTY_ID ;
}

// Returns the property the player is inside, or INVALID_PROPERTY_ID.
Property_GetInside( playerid, Float: radius = 100.0 )  {

	new Float: dis = 99999.99, Float: dis2, index = INVALID_PROPERTY_ID ;

	// Checking for INTERIOR point!
	foreach(new x: Properties) {

		if ( Property [ x ] [ E_PROPERTY_ID ] != INVALID_PROPERTY_ID ) {

			dis2 = GetPlayerDistanceFromPoint(playerid, 
				Property [ x ] [ E_PROPERTY_INT_X ], 
				Property [ x ] [ E_PROPERTY_INT_Y ], 
				Property [ x ] [ E_PROPERTY_INT_Z ]
			);

			if(dis2 < dis && GetPlayerInterior ( playerid ) == Property [ x ] [ E_PROPERTY_INT_INT ] 
				&& GetPlayerVirtualWorld ( playerid ) == Property [ x ] [ E_PROPERTY_INT_VW ] ) {

	            dis = dis2;
	            index = x;
			}
		}
	}

	if ( dis <= radius ) {

		return index;
	}

	return INVALID_PROPERTY_ID ;
}

