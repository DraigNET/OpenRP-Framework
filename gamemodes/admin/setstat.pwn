// ============================================================================
// File: admin/setstat.pwn
// /setstat: lets staff change almost any character stat (cash, level, mask id, phone number,
// licences, skills...). Every change is logged.
// Commands: /setstat
// ============================================================================

// /setstat [option] [player] [value] - (lead admin+) edits almost any character stat: cash,
// level, mask id, phone number, licences, skills and more. One big switch on the option; every
// change is logged.
CMD:setstat(playerid, params[]) { // player

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}


	new choice[32], targetid, input ;
	new currentTime = gettime();

	if ( sscanf ( params, "s[32]k<player>i", choice, targetid, input ) ) {

		SendClientMessage(playerid, COLOR_RED, "/setstat [option] [targetid] [input]");
#if defined FEATURE_FNR
		SendClientMessage(playerid, COLOR_YELLOW, "Available options: mask / donator / phone / rppoints / respect / fear / stamps");
#else
		SendClientMessage(playerid, COLOR_YELLOW, "Available options: mask / donator / phone / stamps");
#endif
		SendClientMessage(playerid, COLOR_YELLOW, "fines / wood / metal / parts / hours / license");
		SendClientMessage(playerid, COLOR_YELLOW, "gunlicense / ccwlicense / guardcard / guardcardfp");
		return true ;
	}

	if ( ! IsPlayerConnected(targetid)) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "Target isn't connected.") ;
	}
	new query [ 256 ], buffer [ 64 ] ;

	// Changes the mask ID of the player
	if ( ! strcmp(choice, "mask", true)) {

		Character [ targetid ] [ E_CHARACTER_MASKID ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_maskid = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_MASKID ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's mask ID to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_MASKID ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your mask ID to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_MASKID ] ) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}

	// Changes the donator level of the player
	else if ( ! strcmp(choice, "donator", true)) {
	
		if ( input < 0 || input > 7 ) {

			SendClientMessage(playerid, COLOR_RED, "Donator values: 0: Regular Player, 1: Early Supporter, 2: Bronze Player, 3: Silver Player");
			return SendClientMessage(playerid, COLOR_RED, "4: Gold Player");
		}

		Account [ targetid ] [ E_PLAYER_ACCOUNT_PREMIUMLEVEL ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE accounts SET account_premiumlevel = %d WHERE account_id = %d",
			Account [ targetid ] [ E_PLAYER_ACCOUNT_PREMIUMLEVEL ], Account [ targetid ] [ E_PLAYER_ACCOUNT_ID ] ) ;

		mysql_tquery(mysql, query);

		buffer[0]=EOS;
		GetPremiumRank ( Account [ targetid ] [ E_PLAYER_ACCOUNT_PREMIUMLEVEL ], buffer ) ;


		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's donator level to %d (%s).", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), 
			Account [ targetid ] [ E_PLAYER_ACCOUNT_PREMIUMLEVEL ], buffer ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your donator level to %d (%s).", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, 
			Account [ targetid ] [ E_PLAYER_ACCOUNT_PREMIUMLEVEL ], buffer ) ;

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	// Changes the phone number of the player
	else if ( ! strcmp(choice, "phone", true)) {
		Character [ targetid ] [ E_CHARACTER_PHONE_NUMBER ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_phnumber = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_PHONE_NUMBER ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's phone number to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_PHONE_NUMBER ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your phone number to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_PHONE_NUMBER ] ) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	else if ( ! strcmp(choice, "hours", true)) {
		Character [ targetid ] [ E_CHARACTER_HOURS ] = input ;

		SetPlayerScore(playerid, Character [ playerid ] [ E_CHARACTER_LEVEL ] ) ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_hours = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_HOURS ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's playing hours to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_HOURS ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your playing hours to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_HOURS ] ) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	else if ( ! strcmp(choice, "license", true)) {
		Character [ targetid ] [ E_CHARACTER_DRIVERSLICENSE ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_driverslicense = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_DRIVERSLICENSE ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's driving license to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_DRIVERSLICENSE ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your driving license to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_DRIVERSLICENSE ] ) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	else if ( ! strcmp(choice, "pilotlicense", true)) {
		Character [ targetid ] [ E_CHARACTER_PILOTSLICENSE ] = input ? 1 : 0 ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_pilotslicense = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_PILOTSLICENSE ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's pilot license to %d.",
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_PILOTSLICENSE ] ) ;

		SendAdminMessage(query) ;

		format ( query, sizeof ( query ), "Admin %s (%d) has set your pilot license to %d.",
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_PILOTSLICENSE ] ) ;

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	else if ( ! strcmp(choice, "gunlicense", true)) {
		
		if (input <= 0)
		{
			Character[targetid][E_CHARACTER_GUNLICENSE] = 0; // Remove licence
		}
		else
		{
			Character[targetid][E_CHARACTER_GUNLICENSE] = currentTime + (input * 86400); // Days → timestamp
		}

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_gunlicense = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_GUNLICENSE ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		new year, month, day, hour, minute, second, str[32];
		format(str, sizeof(str), "None");

		if (Character [ targetid ] [ E_CHARACTER_GUNLICENSE ] > 0)
		{
			stamp2datetime(Character [ targetid ] [ E_CHARACTER_GUNLICENSE ], year, month, day, hour, minute, second, 1 );
			format(str, sizeof(str), "%02d/%02d/%04d", day, month, year);
		}
		
		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's firearms license to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), str) ;
		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your firearms license to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, str) ;	
		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	else if ( ! strcmp(choice, "ccwlicense", true)) {
		
		if (input <= 0)
		{
			Character[targetid][E_CHARACTER_CCWLICENSE] = 0; // Remove licence
		}
		else
		{
			Character[targetid][E_CHARACTER_CCWLICENSE] = currentTime + (input * 86400); // Days → timestamp
		}

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_ccwlicense = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_CCWLICENSE ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		new year, month, day, hour, minute, second, str[32];
		format(str, sizeof(str), "None");

		if (Character [ targetid ] [ E_CHARACTER_CCWLICENSE ] > 0)
		{
			stamp2datetime(Character [ targetid ] [ E_CHARACTER_CCWLICENSE ], year, month, day, hour, minute, second, 1 );
			format(str, sizeof(str), "%02d/%02d/%04d", day, month, year);
		}
		
		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's CCW license to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), str) ;
		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your CCW license to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, str) ;	
		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	else if ( ! strcmp(choice, "guardcard", true)) {
		
		if (input <= 0)
		{
			Character[targetid][E_CHARACTER_GUARDLICENSE] = 0; // Remove licence
		}
		else
		{
			Character[targetid][E_CHARACTER_GUARDLICENSE] = currentTime + (input * 86400); // Days → timestamp
		}

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_guardlicense = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_GUARDLICENSE ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		new year, month, day, hour, minute, second, str[32];
		format(str, sizeof(str), "None");

		if (Character [ targetid ] [ E_CHARACTER_GUARDLICENSE ] > 0)
		{
			stamp2datetime(Character [ targetid ] [ E_CHARACTER_GUARDLICENSE ], year, month, day, hour, minute, second, 1 );
			format(str, sizeof(str), "%02d/%02d/%04d", day, month, year);
		}
		
		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's Guard Card to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), str) ;
		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your Guard Card to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, str) ;	
		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	else if ( ! strcmp(choice, "guardcardfp", true)) {
		
		if (input <= 0)
		{
			Character[targetid][E_CHARACTER_GUARDFPLICENSE] = 0; // Remove licence
		}
		else
		{
			Character[targetid][E_CHARACTER_GUARDFPLICENSE] = currentTime + (input * 86400); // Days → timestamp
		}

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_guardfplicense = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_GUARDFPLICENSE ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		new year, month, day, hour, minute, second, str[32];
		format(str, sizeof(str), "None");

		if (Character [ targetid ] [ E_CHARACTER_GUARDFPLICENSE ] > 0)
		{
			stamp2datetime(Character [ targetid ] [ E_CHARACTER_GUARDFPLICENSE ], year, month, day, hour, minute, second, 1 );
			format(str, sizeof(str), "%02d/%02d/%04d", day, month, year);
		}
		
		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's Guard Card FP to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), str) ;
		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your Guard Card FP to %s.",  Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, str) ;	
		SendClientMessage(targetid, COLOR_YELLOW, query);
	}

#if defined FEATURE_FNR
	// Changes the givable respect points of the player
	else if ( ! strcmp(choice, "rppoints", true)) {
		Character [ targetid ] [ E_CHARACTER_FnR_GIVABLE ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_fnr_givable = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_FnR_GIVABLE ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's giveable rp points to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_FnR_GIVABLE ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your giveable rp points to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_FnR_GIVABLE  ]) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}

	// Changes the respect of the player
	else if ( ! strcmp(choice, "respect", true)) {
		Character [ targetid ] [ E_CHARACTER_RESPECT ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_respect = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_RESPECT ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's respect to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_RESPECT ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your respect to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_RESPECT ] ) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	// Changes the fear of the player
	else if ( ! strcmp(choice, "fear", true)) {
		Character [ targetid ] [ E_CHARACTER_FEAR ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_fear = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_FEAR ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's fear to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_FEAR ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your fear to %d.", 
			Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_FEAR ] ) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
#endif // FEATURE_FNR
	else if ( ! strcmp(choice, "stamps", true)) {
		Character [ targetid ] [ E_CHARACTER_PRISON_STAMPS ] = input ;

		mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_prison_stamps = %d WHERE player_id = %d",
			Character [ targetid ] [ E_CHARACTER_PRISON_STAMPS ], Character [ targetid ] [ E_CHARACTER_ID ] ) ;

		mysql_tquery(mysql, query);

		format ( query, sizeof ( query ), "[!!!] [AdmWarn] %s has set %s's stamps to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnRPName(targetid), Character [ targetid ] [ E_CHARACTER_PRISON_STAMPS ] ) ;

		SendAdminMessage(query) ;	

		format ( query, sizeof ( query ), "Admin %s (%d) has set your stamps to %d.", 
			 Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, Character [ targetid ] [ E_CHARACTER_PRISON_STAMPS ] ) ;	

		SendClientMessage(targetid, COLOR_YELLOW, query);
	}
	// Changes the outstanding fines of the player
	else if ( ! strcmp(choice, "fines", true)) {

		SendClientMessage(playerid, COLOR_YELLOW, "Not added yet.");
	}

	// Changes the wood of the player
	else if ( ! strcmp(choice, "wood", true)) {

		SendClientMessage(playerid, COLOR_YELLOW, "Not added yet.");
	}
	// Changes the metal of the player
	else if ( ! strcmp(choice, "metal", true)) {

		SendClientMessage(playerid, COLOR_YELLOW, "Not added yet.");
	}
	// Changes the parts of the player
	else if ( ! strcmp(choice, "parts", true)) {
		SendClientMessage(playerid, COLOR_YELLOW, "Not added yet.");
	}

	else {
		SendClientMessage(playerid, -1, "/setstat [option] [targetid] [input]");
#if defined FEATURE_FNR
		SendClientMessage(playerid, -1, "Available options: mask / donator / phone / rppoints / respect / fear");
#else
		SendClientMessage(playerid, -1, "Available options: mask / donator / phone");
#endif
		SendClientMessage(playerid, -1, "stamina / muscle / fat / fines / wood / metal / parts");
	}

	return true ;
}
