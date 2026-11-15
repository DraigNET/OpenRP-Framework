// ============================================================================
// File: police/detaining/license.pwn
// Police licence tools: /issuelicense and /takelicense for firearm and concealed-carry
// licences, and /driverwarn.
// Commands: /driverwarn /takelicense /issuelicense
// ============================================================================


// /driverwarn [player] - law enforcement gives a driver a licence warning.
CMD:driverwarn(playerid, params[]) {
	
	if ( IsPlayerIncapacitated(playerid, false) ) 
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
    
	if (!IsPlayerInLEAFaction(playerid, true))
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You're not on duty as law enforcement." ) ;
	}

	new target ;

	if ( sscanf ( params, "k<player>", target ) ) {

		return SendServerMessage(playerid, COLOR_RED, "Syntax", "a3a3a3", "/licenses [targetid]");
	}

	if ( ! IsPlayerConnected(target ) ) {

		return SendServerMessage(playerid, COLOR_RED, "Error", "a3a3a3", "Target isn't connected.");
	}

 	if (!IsPlayerNearPlayer(playerid, target, 6.0)) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "You're not near your target." ) ;
    }

    new query [ 256 ] ;

    ProxDetectorEx(playerid, 15.0, COLOR_PURPLE, "**", sprintf("has given %s a warning mark in their license.", 
    	 ReturnRPName(target)), false, true);

    Character [ target ] [ E_CHARACTER_DRIVER_WARNINGS ] ++ ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE characters SET player_driver_warnings = %d WHERE player_id = %d",
		Character [ target ] [ E_CHARACTER_DRIVER_WARNINGS ],  Character [ target ] [ E_CHARACTER_ID ] ) ;

	mysql_tquery(mysql, query);

    if (  Character [ target ] [ E_CHARACTER_DRIVER_WARNINGS ] >= 3 ) {

    	mysql_format(mysql, query, sizeof ( query ), "UPDATE characters SET player_driver_warnings = 0, player_driverslicense = 0 WHERE player_id = %d",
    	 Character [ target ] [ E_CHARACTER_ID ] ) ;

    	mysql_tquery(mysql, query);

    	Character [ target ] [ E_CHARACTER_DRIVER_WARNINGS ]  = 0 ;
    	Character [ target ] [ E_CHARACTER_DRIVERSLICENSE]  = 0 ;

    	SendClientMessage(target, COLOR_INFO, "Your drivers license has recieved it's third warning. It has been confiscated!" ) ;
    	SendClientMessage(playerid, COLOR_YELLOW, "Your target's drivers license has recieved it's third warning! The license has been REMOVED!" ) ;
    }

	return true ;
}

// /takelicense [player] - law enforcement removes a licence.
CMD:takelicense(playerid, params[]) {
	
	if ( IsPlayerIncapacitated(playerid, false) ) 
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }
    
	if (!IsPlayerInLEAFaction(playerid, true))
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You're not on duty as law enforcement." ) ;
	}

	new targetid ;
	new factionid = Character [ playerid ] [ E_CHARACTER_FACTIONID ] ;
	new faction_enum_id = Faction_GetEnumID( factionid ); 

	if ( sscanf ( params, "k<player>", targetid ) ) {

		return SendServerMessage(playerid, COLOR_RED, "Syntax", "a3a3a3", "/takelicense [targetid]");
	}

	if ( ! IsPlayerConnected(targetid ) ) {

		return SendServerMessage(playerid, COLOR_RED, "Error", "a3a3a3", "Target isn't connected.");
	}

 	if (!IsPlayerNearPlayer(playerid, targetid, 3.0)) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "You're not near your target." ) ;
    }

    if ( ! Character [ targetid ] [ E_CHARACTER_DRIVERSLICENSE ] ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "Your target does not have a license, you can't take it away!" ) ;
    }


	Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s has revoked the driver's license of (%d) %s. }",

		Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], playerid, ReturnRPName ( playerid ), targetid, ReturnRPName ( targetid )
	), faction_enum_id, false ) ;

	new query [ 256 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_driverslicense = 0 WHERE player_id = %d", Character [ targetid ] [ E_CHARACTER_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	Character [ targetid ] [ E_CHARACTER_DRIVERSLICENSE ] = 0 ;

	ProxDetectorEx ( playerid, 20, COLOR_ACTION, "*", sprintf( "revokes the driver's license of %s.", ReturnRPName(targetid)) ) ;

	return true ;
}

// /issuelicense [fsc/ccw/guard/guardfp] [player] [days] - issues a licence for a number of days.
CMD:issuelicense(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3",
            "You're currently incapacitated and can't do this.");
    }

    new type[16], targetid, days;
    new licenseName[32];

    if (sscanf(params, "s[16]k<player>i", type, targetid, days))
    {
        SendClientMessage(playerid, -1,
            "/issuelicense [fsc/ccw/guard/guardfp] [playerid] [days]");
        return true;
    }

    if (!IsPlayerConnected(targetid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "Your target isn't connected.");
    }

    if (!IsPlayerNearPlayer(playerid, targetid, 10.0))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "You're not near this player.");
    }

    if (days < 0)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "Days must be 0 or higher.");
    }

    if (Character[playerid][E_CHARACTER_FACTIONTIER] > 2)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "You're not a high enough tier of employee to do this.");
    }

    new currentTime = gettime();
    new licenseTimestamp;

    if (days == 0)
        licenseTimestamp = 0;
    else
        licenseTimestamp = currentTime + (days * 86400);

    new query[256];
    new str[32] = "None";

    new year, month, day, hour, minute, second;

    if (licenseTimestamp > 0)
    {
        stamp2datetime(licenseTimestamp, year, month, day, hour, minute, second, 1);
        format(str, sizeof(str), "%02d/%02d/%04d", day, month, year);
    }

    // =====================================================
    // POLICE LICENSES (FSC + CCW)
    // =====================================================

    if (IsPlayerInPoliceFaction(playerid, true))
    {
        if (!strcmp(type, "fsc", true))
        {
            Character[targetid][E_CHARACTER_GUNLICENSE] = licenseTimestamp;

            mysql_format(mysql, query, sizeof(query),
                "UPDATE characters SET player_gunlicense = %d WHERE player_id = %d",
                licenseTimestamp,
                Character[targetid][E_CHARACTER_ID]);

            mysql_tquery(mysql, query);

            SendServerMessage(targetid, COLOR_YELLOW, "License Issued", "A3A3A3",
                sprintf("Your Firearms Permit is now valid until: %s.", str));

            format(licenseName, sizeof(licenseName), "Firearms Permit");
        }
        else if (!strcmp(type, "ccw", true))
        {
            Character[targetid][E_CHARACTER_CCWLICENSE] = licenseTimestamp;

            mysql_format(mysql, query, sizeof(query),
                "UPDATE characters SET player_ccwlicense = %d WHERE player_id = %d",
                licenseTimestamp,
                Character[targetid][E_CHARACTER_ID]);

            mysql_tquery(mysql, query);

            SendServerMessage(targetid, COLOR_YELLOW, "License Issued", "A3A3A3",
                sprintf("Your CCW License is now valid until: %s.", str));

            format(licenseName, sizeof(licenseName), "CCW License");
        }
        else if (!strcmp(type, "guard", true))
        {
            Character[targetid][E_CHARACTER_GUARDLICENSE] = licenseTimestamp;

            mysql_format(mysql, query, sizeof(query),
                "UPDATE characters SET player_guardlicense = %d WHERE player_id = %d",
                licenseTimestamp,
                Character[targetid][E_CHARACTER_ID]);

            mysql_tquery(mysql, query);

            SendServerMessage(targetid, COLOR_YELLOW, "License Issued", "A3A3A3",
                sprintf("Your Guard Card is now valid until: %s.", str));

            format(licenseName, sizeof(licenseName), "Guard Card");
        }
        else if (!strcmp(type, "guardfp", true))
		{
			// Must have valid Guard Card first
			if (Character[targetid][E_CHARACTER_GUARDLICENSE] == 0 ||
				(Character[targetid][E_CHARACTER_GUARDLICENSE] < gettime() &&
				Character[targetid][E_CHARACTER_GUARDLICENSE] != 0))
			{
				return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
					"Target must have a valid Guard Card before issuing a Firearms Permit.");
			}

			Character[targetid][E_CHARACTER_GUARDFPLICENSE] = licenseTimestamp;

			mysql_format(mysql, query, sizeof(query),
				"UPDATE characters SET player_guardfplicense = %d WHERE player_id = %d",
				licenseTimestamp,
				Character[targetid][E_CHARACTER_ID]);

			mysql_tquery(mysql, query);

			SendServerMessage(targetid, COLOR_YELLOW, "License Issued", "A3A3A3",
				sprintf("Your Guard Card Firearms Permit is now valid until: %s.", str));

			format(licenseName, sizeof(licenseName), "Guard Card Firearms Permit");
		}
        else
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
                "Invalid license type. Valid types: fsc, ccw, guard, guardfp.");
        }
    }

    // =====================================================
    // NOT AUTHORISED
    // =====================================================

    else
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Abuse", "A3A3A3",
            "You are not authorised to issue licenses.");
    }

    // =====================================================
    // SUCCESS MESSAGE
    // =====================================================

    SendServerMessage(playerid, COLOR_GREEN, "Success", "A3A3A3",
        sprintf("You have issued %s to %s (Expires: %s).",
        licenseName,
        ReturnRPName(targetid),
        str));

    // =====================================================
    // ADMIN LOG
    // =====================================================

    format(query, sizeof(query),
        "[LEO] %s has issued a %s to %s (Expires: %s).",
        Account[playerid][E_PLAYER_ACCOUNT_NAME],
        licenseName,
        ReturnRPName(targetid),
        str);

    SendAdminMessage(query);

    return true;
}
