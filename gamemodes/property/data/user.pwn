// ============================================================================
// File: property/data/user.pwn
// Player-facing property commands: invite, evict, rent a room (/rentroom, /unrentroom), name
// and colour (/propname), interior time and weather, furniture permissions, key handling
// (GivePropertyKey) and owned property limits.
// Commands: /furniperm /propertyinvite /propertyevict /unrentroom /rentroom /propname
// /propnamecolor /propertynamecolor /propertytime /propertyweather /propertyname /propfee
// /propertyfee /proprent /propertyrent /proplock /propertylock /propfind /bfind /propertyfind
// /propbuy /propertybuy /propsell /propertysell /propertytransfer /propertyscrap
// /checkproperties /propertycheck /propcheck /propinfo
// ============================================================================

static PropInviteDlgStr[512];
new bool: HasActivePropertyOffer[MAX_PLAYERS];

// /furniperm [player] - lets another player edit furniture in your property.
CMD:furniperm(playerid, params[]) 
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_EXIT ) ;

	if ( property_enum_id == INVALID_PROPERTY_ID ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be inside your property, near the door." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't own this property." );
	}

	new targetid;

	if (sscanf(params, "k<player>", targetid))
		return SendClientMessage(playerid, -1, "/furniperm [player]");

	if (!IsPlayerConnected(targetid) || !IsPlayerLogged(targetid))
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This player isn't connected." );
	}
	
	if (PlayerVar[targetid][E_PLAYER_FURNI_PERM] == Property[property_enum_id][E_PROPERTY_ID])
	{
		SendServerMessage(playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You have revoked furniture permission for (%d) %s.", targetid, ReturnSettingsName(targetid, playerid)));
		SendServerMessage(targetid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("(%d) %s has revoked your furniture permission for their property.", playerid, ReturnSettingsName(playerid, targetid)));
		PlayerVar[targetid][E_PLAYER_FURNI_PERM] = 0;
	}
	else if (!PlayerVar[targetid][E_PLAYER_FURNI_PERM])
	{
		SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You have allowed (%d) %s to fully manage your property furniture until they logout.", targetid, ReturnSettingsName(targetid, playerid)) );
		SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", "Note: you can do the command again to revoke permission.");

		SendServerMessage ( targetid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("(%d) %s has given you furniture permission for their property.", playerid, ReturnSettingsName(playerid, targetid)) );
		SendServerMessage ( targetid, COLOR_PROPERTY, "Property", "A3A3A3", "Note: furniture permission only lasts until you disconnect.");
		PlayerVar[targetid][E_PLAYER_FURNI_PERM] = Property[property_enum_id][E_PROPERTY_ID];
	}
	else
	{
		SendServerMessage ( playerid, COLOR_PROPERTY, "Error", "A3A3A3", "This player already has furniture permission for a different property.");
	}
	
	return true ;
}

// /propertyinvite [player] - invites a nearby player into your locked property.
CMD:propertyinvite(playerid, params[]) 
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER) ;

	if ( property_enum_id == INVALID_PROPERTY_ID ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if ( ! Property_HasAccess ( playerid, property_enum_id ) ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't own this property." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_HOUSE ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only invite a player to rent a residence." );
	}

	new targetid;

	if (sscanf(params, "k<player>", targetid))
		return SendClientMessage(playerid, -1, "/propertyinvite [player]");

	if (!IsPlayerConnected(targetid))
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This player isn't connected." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == Character [ targetid ] [ E_CHARACTER_ID ] ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You already own this property." );
	}

	if (!IsPlayerNearPlayer(playerid, targetid, 5.0))
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near this player." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_ID ] == Character [ targetid ] [ E_CHARACTER_RENTEDHOUSE ] ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This player already rents your property.  Type /propertyevict to evict them." );
	}

	new address [ 64 ], zone [ 64 ] ;

	GetCoords2DZone(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
	GetPlayerAddress(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], address );
	
	inline DlgPropInvite(pid, dialogid, response, listitem, string:inputtext[]) 
    {
        #pragma unused dialogid, inputtext, listitem, inputtext
        
        if (response)
        {
			if (Property [ property_enum_id ] [ E_PROPERTY_RENT ] > 0 && GetPlayerCash(pid) < Property [ property_enum_id ] [ E_PROPERTY_RENT ])
			{
				return SendServerMessage ( pid, COLOR_ERROR, "Error", "A3A3A3", "You can't afford to rent this property." );
			}

            Character [ pid ] [ E_CHARACTER_RENTEDHOUSE ] = Property [ property_enum_id ] [ E_PROPERTY_ID ] ;

			new query [ 256 ] ;
			mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_rentroom = %d WHERE player_id = %d", 

				Character [ pid ] [ E_CHARACTER_RENTEDHOUSE ], Character [ pid ] [ E_CHARACTER_ID] ) ;

			mysql_tquery(mysql, query);

			

			SendServerMessage ( pid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("You've rented %d %s, %s for $%s. Type /propertyhelp for commands.",
				property_enum_id, address, zone, IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_RENT ])  ) );

			if (Property [ property_enum_id ] [ E_PROPERTY_RENT ] > 0)
			{
				TakePlayerCash(pid, Property [ property_enum_id ] [ E_PROPERTY_RENT ], "Property rent invite");
			}

			SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("%s accepted your invite to rent at your property.", ReturnSettingsName(pid, playerid)) );

			AddLogEntry(pid, LOG_TYPE_SCRIPT, sprintf("Rented %d, %s %s (SQL: %d) for $%s", property_enum_id, address, zone, Property [ property_enum_id ] [ E_PROPERTY_ID ], Property [ property_enum_id ] [ E_PROPERTY_RENT ]));
        }

        return true;
    }

	format(PropInviteDlgStr, sizeof(PropInviteDlgStr), "%s has invited you to rent %d %s, %s.\nThe rental price is $%s per paycheck.\n\n{FFFFFF}Press {AA3333}OK{FFFFFF} to pay $%s and rent the property.\n{ADBEE6}If you are already renting a property, this will override it.",
		ReturnSettingsName(playerid, targetid), property_enum_id, address, zone, IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_RENT ]), IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_RENT ]));

    Dialog_ShowCallback ( targetid, using inline DlgPropInvite, DIALOG_STYLE_MSGBOX, "Property Invite", PropInviteDlgStr, "OK", "Back" );
	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You invited %s to rent at your property.", ReturnSettingsName(targetid, playerid)) );
	return true ;
}

// /propertyevict [player] - removes a player from your property.
CMD:propertyevict(playerid, params[]) 
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( property_enum_id == INVALID_PROPERTY_ID ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if ( ! Property_HasAccess ( playerid, property_enum_id ) ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't own this property." );
	}

	new targetid;

	if (sscanf(params, "k<player>", targetid))
		return SendClientMessage(playerid, -1, "/propertyevict [player]");

	if (!IsPlayerConnected(targetid))
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This player isn't connected." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == Character [ targetid ] [ E_CHARACTER_ID ] ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You already own this property." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_ID ] != Character [ targetid ] [ E_CHARACTER_RENTEDHOUSE ] ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This player doesn't rent at your property." );
	}

	AddLogEntry(targetid, LOG_TYPE_SCRIPT, sprintf("Evicted from property SQL ID %d", Character [ targetid ] [ E_CHARACTER_RENTEDHOUSE ]));

	Character [ targetid ] [ E_CHARACTER_RENTEDHOUSE ] = -1 ;
	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_rentroom = %d WHERE player_id = %d", 

		Character [ targetid ] [ E_CHARACTER_RENTEDHOUSE ], Character [ targetid ] [ E_CHARACTER_ID] ) ;

	mysql_tquery(mysql, query);
	SendServerMessage ( targetid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You have been evicted from the property you were renting at by %s.", ReturnSettingsName(playerid, targetid)) );
	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You evicted %s from renting your property.", ReturnSettingsName(targetid, playerid)) );

	return true ;
}

// /unrentroom - ends your room rental.
CMD:unrentroom(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Unrented property SQL ID %d", Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ]));

	Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ] = -1 ;
	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_rentroom = %d WHERE player_id = %d", 

		Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ], Character [ playerid ] [ E_CHARACTER_ID] ) ;

	mysql_tquery(mysql, query);
	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", "You have unrented the property you were renting at." );


	return true ;
}

// /rentroom - rents a room in the property you are at.
CMD:rentroom(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't rent at a static property." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't need to rent this property - you own it!");
	}

	if ( ! Property [ property_enum_id ] [ E_PROPERTY_RENT ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "This property isn't rentable." );
	}

	if ( Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ] == Property [ property_enum_id ] [ E_PROPERTY_ID ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You're already renting here!" );
	}

	if (GetPlayerCash( playerid ) < Property [ property_enum_id ] [ E_PROPERTY_RENT ]) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You can't afford to rent this property." );
	}

	Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ] = Property [ property_enum_id ] [ E_PROPERTY_ID ] ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_rentroom = %d WHERE player_id = %d", 

		Character [ playerid ] [ E_CHARACTER_RENTEDHOUSE ], Character [ playerid ] [ E_CHARACTER_ID] ) ;

	mysql_tquery(mysql, query);

	new address [ 64 ], zone [ 64 ] ;

	GetCoords2DZone(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
	GetPlayerAddress(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], address );


	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("You've rented %d %s, %s for $%s. Type /propertyhelp for commands.",
		property_enum_id, address, zone, IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_RENT ])  ) );

	TakePlayerCash(playerid, Property [ property_enum_id ] [ E_PROPERTY_RENT ], "Property rent room");
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Rented %d, %s %s (SQL: %d) for $%s", property_enum_id, address, zone, Property [ property_enum_id ] [ E_PROPERTY_ID ], Property [ property_enum_id ] [ E_PROPERTY_RENT ]));

	return true ;
}

CMD:propname(playerid, params[]) {

	return cmd_propertyname(playerid, params);
}

CMD:propnamecolor(playerid, params[]) {

	return cmd_propertynamecolor(playerid, params);
}

static const PropertyNameColors[][] = 
{
	"White",
	"Red",
	"Green",
	"Blue",
	"Yellow",
	"Purple",
	"Black"
};

CMD:propertynamecolor (playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    } 

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER) ;


	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You're not near a property entrance." );
	}

	if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL && ! Property_HasAccess ( playerid, property_enum_id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You don't own this property!" );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_BIZ ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You can only change the name of a business." );
	}

	new type = -1, type_name[10];

	new helpstr[128];
	format(helpstr, sizeof(helpstr), "Available Colors: ");

	sscanf ( params, "s[10]", type_name ); 

	for ( new i, j = sizeof ( PropertyNameColors ); i < j ; i ++ ) 
	{
		if (strlen(type_name) && !strcmp(type_name, PropertyNameColors[i], true))
		{
			type = i;
			break;
		}

		if (i > 0) strcat(helpstr, ", ");
		format(helpstr, sizeof(helpstr), "%s\"%s\"", helpstr, PropertyNameColors[i]);
	}

	if (type == -1)
	{
		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "/propertynamecolor [color]" );
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  helpstr );
	}

	Property [ property_enum_id ] [ E_PROPERTY_NAME_COLOR ] = type ;

	new query [ 128 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_name_color = %d WHERE property_id = %d", 

		Property [ property_enum_id ] [ E_PROPERTY_NAME_COLOR ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("Changed property name color to %s.", PropertyNameColors[type] ) );
	return true ;
}

// Defined in config/time_weather.pwn, which is included after the property system.
forward Player_RefreshTime(playerid);

// /propertytime [hour] [minute] - sets the interior's time of day.
CMD:propertytime(playerid, params[])
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    } 

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_EXIT ) ;


	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "You must be inside your property, near the door." );
		return true ;
	}

	if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL && ! Property_HasAccess ( playerid, property_enum_id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You don't own this property!" );
	}

	/*if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_BIZ ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You can only change the name of a business." );
	}*/

	new hour, minute ;

	if ( sscanf ( params, "ii", hour, minute ) ) {
		SendServerMessage ( playerid, COLOR_ERROR, "Incorrect Format", "A3A3A3", "/propertytime [hour] [minutes]") ;
		return SendClientMessage ( playerid, COLOR_GRAD0, "The time is fixed while you're inside, so the lighting stays the same. Use /propertytime -1 0 to follow the server time again." ) ;
	}

	if ( hour != -1 && ( hour < 0 || hour > 23 || minute < 0 || minute > 59 ) ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Use an hour from 0 to 23 and minutes from 0 to 59, or -1 0 to follow the server time." ) ;
	}

	Property [ property_enum_id ] [ E_PROPERTY_INT_HOURS ] = hour;
	Property [ property_enum_id ] [ E_PROPERTY_INT_MINS ] = minute;

	new query [ 128 ] ;
	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_int_hours = %d, property_int_mins = %d WHERE property_id = %d", 

		Property [ property_enum_id ] [ E_PROPERTY_INT_HOURS ],
		Property [ property_enum_id ] [ E_PROPERTY_INT_MINS ],
		Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query );

	Player_RefreshTime(playerid);

	if ( hour == -1 ) {
		return SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", "The property now follows the server time." ) ;
	}

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("Changed property time to %02d:%02d. The lighting inside stays fixed at that time.", hour, minute ) );
	return true ;
}

// /propertyweather [id] - sets the interior's weather.
CMD:propertyweather(playerid, params[])
{
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    } 

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_EXIT ) ;


	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "You must be inside your property, near the door." );
		return true ;
	}

	if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL && ! Property_HasAccess ( playerid, property_enum_id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You don't own this property!" );
	}

	/*if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_BIZ ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You can only change the name of a business." );
	}*/

	new weather ;

	if ( sscanf ( params, "i", weather ) ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Incorrect Format", "A3A3A3", "/propertyweather [weather id]") ;
	}

	if ( weather < 0 || weather > 20 ) {
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "That isn't a valid weather id. Use 0 to 20." ) ;
	}

	Property [ property_enum_id ] [ E_PROPERTY_INT_WEATHER ] = weather;

	new query [ 128 ] ;
	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_int_weather = %d WHERE property_id = %d", 

		Property [ property_enum_id ] [ E_PROPERTY_INT_WEATHER ],
		Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query );

	SetPlayerWeather(playerid, weather);

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("Changed weather to %d. It stays like this inside, whatever the weather does outside.", weather ) );
	return true ;
}

// Pure-Pawn whitelist equivalent of the regex ^[a-zA-Z0-9 \/,.'&]*$
// (was Regex_New/Regex_Check, which crashed the server via pawnregex.so on any
// /propertyname input -- a remote DoS reachable by any player).
stock IsValidPropertyName(const propname[])
{
	for (new i = 0; propname[i]; i++)
	{
		new c = propname[i];
		if ((c >= 'a' && c <= 'z') ||
		    (c >= 'A' && c <= 'Z') ||
		    (c >= '0' && c <= '9') ||
		    c == ' ' || c == '/' || c == ',' ||
		    c == '.' || c == '\'' || c == '&')
			continue;

		return false;
	}
	return true;
}


// /propertyname [name] - renames your property (3D label).
CMD:propertyname(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    } 

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;


	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You're not near a property entrance." );
	}

	if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL && ! Property_HasAccess ( playerid, property_enum_id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You don't own this property!" );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_BIZ ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You can only change the name of a business." );
	}

	new name [ 128 ] ;

	if ( sscanf ( params, "s[128]", name ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "/propertyname [name]" );
	}

	if ( strlen ( name ) <= 3 || strlen ( name ) > 64  ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "Property name can't be less than 3 or more than 64 characters." );
	}

	if (!IsValidPropertyName(name))
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "Keep it simple, your property name can't contain special characters." );
	}

	Property [ property_enum_id ] [ E_PROPERTY_NAME ] [ 0 ] = EOS ;
	format ( Property [ property_enum_id ] [ E_PROPERTY_NAME ], sizeof ( name ), "%s", name ) ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_name = '%e' WHERE property_id = %d", 

		Property [ property_enum_id ] [ E_PROPERTY_NAME ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("Changed property name to \"%s\".", Property [ property_enum_id ] [ E_PROPERTY_NAME ] ) );

	return true ;
}

CMD:propfee(playerid, params[]) {

	return cmd_propertyfee(playerid, params);
}
// /propertyfee [amount] - sets a business's entrance fee (0 to disable).
CMD:propertyfee(playerid, params[]) 
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",  "Contact a General Admin or higher to set property fees.");
	}

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;
	if ( property_enum_id == INVALID_PROPERTY_ID ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You're not near a property entrance." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You can't set the fee of a static property." );
	}

	new amount ;

	if ( sscanf ( params, "i", amount ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "/propertyfee [amount] (0 to disable)" );
	}

	if ( amount < 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "Entrance fee can't be less than 0." );
	}

	if ( amount > 500 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "Entrance fee can't be more than 500." );
	}

	Property [ property_enum_id ] [ E_PROPERTY_FEE ] = amount ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_fee = %d WHERE property_id = %d", 

		Property [ property_enum_id ] [ E_PROPERTY_FEE ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("You set the entrance fee to $%s.", IntegerWithDelimiter(amount) ) );
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Set the entrance fee of Property %d (SQL: %d) to $%s", property_enum_id, Property [ property_enum_id ] [ E_PROPERTY_ID ], IntegerWithDelimiter(amount)));
	SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s set the entrance fee of Property %d (SQL: %d) to $%s.", playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME], property_enum_id, Property [ property_enum_id ] [ E_PROPERTY_ID ], IntegerWithDelimiter(amount)));


	return true ;
}

CMD:proprent(playerid, params[]) {

	return cmd_propertyrent(playerid, params);
}
// /propertyrent [amount] - sets the rent for your house (0 to disable).
CMD:propertyrent(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;


	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You're not near a property entrance." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You can't rent a static property." );
	}

	if ( ! Property_HasAccess ( playerid, property_enum_id ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3",  "You don't own this property!" );
	}

	new amount ;

	if ( sscanf ( params, "i", amount ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  "/propertyrent [amount] (0 to disable)" );
	}

	if ( amount != 0 && ( amount < Property_GetMinRent ( property_enum_id ) || amount > Property_GetMaxRent ( property_enum_id ) ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3",  sprintf ( "Rent for this property has to be between $%d and $%d (or 0 to turn renting off).", Property_GetMinRent ( property_enum_id ), Property_GetMaxRent ( property_enum_id ) ) );
	}

	Property [ property_enum_id ] [ E_PROPERTY_RENT ] = amount ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_rent = %d WHERE property_id = %d", 

		Property [ property_enum_id ] [ E_PROPERTY_RENT ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3",  sprintf("Set rent fee to %d.", amount ) );

	return true ;
}

CMD:proplock(playerid, params[]) {

	return cmd_propertylock(playerid, params);
}

// /propertylock - locks or unlocks your property.
CMD:propertylock(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ANYWHERE );

	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be close to your property, near the door." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't lock a static property." );
	}

	new access = Property_HasAccess ( playerid, property_enum_id ) || Character[playerid][E_CHARACTER_RENTEDHOUSE] == Property[property_enum_id][E_PROPERTY_ID] || Character[playerid][E_CHARACTER_PROP_DUP] == Property[property_enum_id][E_PROPERTY_ID] ;

	if (!access)
	{
		if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR && PlayerVar[playerid][E_PLAYER_ADMIN_DUTY]) SendClientMessage(playerid, COLOR_YELLOW, "You're using your admin powers to lock/unlock this property." );
		else if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR) return SendClientMessage(playerid, -1, "You don't have normal access to this property, but can go on admin duty to do this.");
		else return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't own or rent this property." );
	}	

	new address [ 64 ], zone [ 64 ] ;
	GetCoords2DZone(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
	GetPlayerAddress(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], address );

	if ( Property [ property_enum_id ] [ E_PROPERTY_LOCKED ] ) {

		Property [ property_enum_id ] [ E_PROPERTY_LOCKED ] = 0 ;
		SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", "You've unlocked your property." );
		ShowInfoText(playerid, "~b~~h~~h~Property Unlocked!", 3000);
		AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Unlocked %d, %s %s (SQL: %d)", property_enum_id, address, zone, Property [ property_enum_id ] [ E_PROPERTY_ID ]));
	}

	else if ( ! Property [ property_enum_id ] [ E_PROPERTY_LOCKED ] ) {

		Property [ property_enum_id ] [ E_PROPERTY_LOCKED ] = 1 ;
		SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", "You've locked your property." );
		ShowInfoText(playerid, "~b~~h~~h~Property Locked!", 3000);
		AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Locked %d, %s %s (SQL: %d)", property_enum_id, address, zone, Property [ property_enum_id ] [ E_PROPERTY_ID ]));
	}

	new query [ 128 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_locked = %d WHERE property_id = %d", 

		Property [ property_enum_id ] [ E_PROPERTY_LOCKED ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query );

	return true ;
}



CMD:propfind(playerid, params[]) {

	return cmd_propertyfind(playerid, params);
}
CMD:bfind(playerid, params[]) {

	return cmd_propertyfind(playerid, params);
}
// /propertyfind [id] - marks one of your properties on the map.
CMD:propertyfind(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new id = -1;

	if ( sscanf ( params, "i", id ) || id == -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/propertyfind [id]" );
	}

	if ( id < 0 || id > MAX_PROPERTIES ) {

		return SendServerMessage ( playerid, COLOR_PROPERTY, "Error", "A3A3A3", sprintf("The ID you entered is out of bounds! Can't be less than 0 or more than %d.", MAX_PROPERTIES ));
	}

	new access = Property[id][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_BIZ || Property_HasAccess ( playerid, id );
	if (Property[id][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_HOUSE && Character[playerid][E_CHARACTER_RENTEDHOUSE] == Property[id][E_PROPERTY_ID]) access = 1;

	if (!access)
	{
		if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR) SendClientMessage(playerid, COLOR_YELLOW, "You're using your admin powers to find this property." );
		else return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have permission to find this property." );
	}	

	new Float: x, Float: y, Float: z ;

	x = Property [ id ] [ E_PROPERTY_EXT_X ] ; 
	y = Property [ id ] [ E_PROPERTY_EXT_Y ] ; 
	z = Property [ id ] [ E_PROPERTY_EXT_Z ] ; 

	new address [ 64 ], zone [ 64 ] ;
	GetCoords2DZone(x, y, zone, sizeof ( zone ));
	GetPlayerAddress(x, y, address );

	GPS_MarkLocation(playerid, sprintf("~y~%d %s, %s~w~ has been marked on your ~r~minimap~w~.", id, address, zone), E_GPS_COLOR_SCRIPT, x, y, z) ;

	return true ;
}

// Defined in property/utils/realestate.pwn
forward RealEstate_BuyFromFirm(playerid, index);

CMD:propbuy(playerid, params[]) {

	return cmd_propertybuy(playerid, params);
}

// /propertybuy - buys the property you are standing at (if for sale).
CMD:propertybuy(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;


	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_HOUSE ) {

		// Houses are sold by real estate firms (property/utils/realestate.pwn).
		if ( Property_IsFirmOwned ( property_enum_id ) ) {

			return RealEstate_BuyFromFirm ( playerid, property_enum_id ) ;
		}

		if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Houses are sold by real estate firms. Use /propertylist to find one for sale." );
		}
	}

	switch (  Property [ property_enum_id ] [ E_PROPERTY_TYPE ] ) {

		case E_PROPERTY_TYPE_STATIC: return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't buy this property." );
		case E_PROPERTY_TYPE_BIZ: {
		
			if ( Player_GetOwnedBusinesses ( playerid ) >= Player_GetMaxOwnedBusinesses ( playerid ) ) {

				return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any business ownership slots left. Use /myslots to check." );
			}	
		}
		case E_PROPERTY_TYPE_HOUSE: {
			
			if ( Player_GetOwnedHouses ( playerid ) >= Player_GetMaxOwnedHouses ( playerid ) ) {

				return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any house ownership slots left. Use /myslots to check." );
			}			
		}
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is already owned by someone else." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_PRICE ] <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is not for sale." );
	}

	if ( GetPlayerCash ( playerid ) < Property [ property_enum_id ] [ E_PROPERTY_PRICE ] ) {


		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("You don't have enough money. You need at least $%s. You have $%s.",

			IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_PRICE ]),  IntegerWithDelimiter(GetPlayerCash ( playerid )) 
		) ) ;

	}

	TakePlayerCash ( playerid, Property [ property_enum_id ] [ E_PROPERTY_PRICE ], "Property purchase" ) ;

	//AddPlayerRespect(playerid, 20);
	//GiveFnRPoints(playerid, 20, "Purchased property");

	Property [ property_enum_id ] [ E_PROPERTY_OWNER ] = Character [ playerid ] [ E_CHARACTER_ID ] ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_owner = %d WHERE property_id = %d", 
		Property [ property_enum_id ] [ E_PROPERTY_OWNER ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query);

	// Resetting property collect upon buying to avoid money hoarding / going out of bounds.
	Property [ property_enum_id ] [ E_PROPERTY_COLLECT ] = 0 ; 

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_collect = 0 WHERE property_id = %d",
		Property [ property_enum_id ] [ E_PROPERTY_ID ] ) ;
	
	mysql_tquery(mysql, query);

	new address [ 64 ], zone [ 64 ] ;
	GetCoords2DZone(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
	GetPlayerAddress(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], address );

	SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've bought %d %s, %s for $%s.", property_enum_id, address, zone, IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_PRICE ]) ) );

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Purchased %d, %s %s for $%s", property_enum_id, address, zone, IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_PRICE ])));

	foreach(new syncid: Player) {
		if ( IsPlayerInDynamicArea(syncid, Property [ property_enum_id ] [ E_PROPERTY_AREA ]  )) {

			PlayerTextDrawHide(syncid, house_info_box[playerid] );

			if (Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == playerid) {

				PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, Los Santos~n~~b~This is your property", address, property_enum_id, zone ) ) ;
			}

			else PlayerTextDrawSetString(syncid, house_info_box[playerid], sprintf("%s, %d~n~%s, Los Santos~n~~g~Player Owned", address, property_enum_id, zone ) ) ;

			PlayerTextDrawShow(syncid, house_info_box[playerid] );
		}
	}

	PlayerTextDrawHide(playerid, house_info_box[playerid]);

	return true ;
}

CMD:propsell(playerid, params[]) {

	return cmd_propertysell(playerid, params);
}


// /propertysell [player] [price] - offers to sell your property to another player.
CMD:propertysell(playerid, params[]) {

	if (HasActivePropertyOffer[playerid]){
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You already have sent an active offer to someone.") ;
	}

	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;
	new address [ 64 ], zone [ 64 ] ;

	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't sell this property." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER ) {

		if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is owned by someone else" );
		}
	}

	else if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is already for sale!" );
	}

	new targetid, price ;

	if ( sscanf ( params, "k<player>i", targetid, price ) ) {

		SendClientMessage(playerid, COLOR_ERROR, "/propertysell [playerid] [price]" ) ;
		return SendClientMessage(playerid, COLOR_ERROR, "INFO: This command SELLS your property. Use /propertytransfer if you want to transfer it for free.");
	}

	if(targetid == playerid)
		return SendServerMessage ( targetid, COLOR_ERROR, "Error", "A3A3A3", "You can't sell your property to yourself." );

	if ( ! IsPlayerConnected(targetid ) || !IsPlayerNearPlayer(playerid, targetid, 10.0) ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Target isn't online or near you.");
	}

	if ( Property [property_enum_id] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_HOUSE && Player_GetOwnedHouses(targetid) >= Player_GetMaxOwnedHouses(targetid)) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Your targetid doesn't have any house ownership slots left." );
		return SendServerMessage ( targetid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any house ownership slots left. Use /myslots to check." );

	} else if ( Property [property_enum_id] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_BIZ && Player_GetOwnedBusinesses(targetid) >= Player_GetMaxOwnedBusinesses(targetid) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Your targetid doesn't have any business ownership slots left." );
		return SendServerMessage ( targetid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any business ownership slots left. Use /myslots to check." );
	}

	if(price <= 0) 
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't sell your property for $0. Use /propertytransfer to transfer it for free instead." );

	if(price > Character[targetid][E_CHARACTER_CASH])
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Your target doesn't have that much cash on hand.");

	SendClientMessage(playerid, COLOR_INFO, sprintf("[SELL] {DEDEDE}You have sent %s an offer to buy your property for {32CD32}$%s{DEDEDE}.", ReturnSettingsName(targetid, playerid), IntegerWithDelimiter(price)));
	SendClientMessage(targetid, COLOR_INFO, sprintf("[BUY] {DEDEDE}%s has sent you an offer to buy their property for {32CD32}$%s{DEDEDE}.", ReturnSettingsName(playerid, targetid), IntegerWithDelimiter(price)));

	GetCoords2DZone(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
	GetPlayerAddress(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], address );

	HasActivePropertyOffer[playerid] = true;

	inline PropSellConfirm(pid, dialogid, response, listitem, string:inputtext[]) {
	    #pragma unused pid, dialogid, listitem, inputtext

		if ( ! response ) {

			HasActivePropertyOffer[playerid] = false;

			SendClientMessage(playerid, COLOR_INFO, sprintf("[SELL] {DEDEDE}%s has {db1233}declined{DEDEDE} your offer to buy your property.", ReturnSettingsName(targetid, playerid)));
			SendClientMessage(targetid, COLOR_INFO, sprintf("[BUY] {DEDEDE}You have {db1233}declined{DEDEDE} %s's offer to buy their property.", ReturnSettingsName(playerid, targetid)));

	    	return false ;
		}

		if ( response ) {

			HasActivePropertyOffer[playerid] = false;

			Property [ property_enum_id ] [ E_PROPERTY_OWNER ] = Character [ targetid ] [ E_CHARACTER_ID ] ;

			new query [ 256 ] ;

			mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_owner = %d WHERE property_id = %d", 
				Property [ property_enum_id ] [ E_PROPERTY_OWNER ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
			);

			mysql_tquery(mysql, query);

			// Resetting property collect upon buying to avoid money hoarding / going out of bounds.
			Property [ property_enum_id ] [ E_PROPERTY_COLLECT ] = 0 ; 

			mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_collect = 0 WHERE property_id = %d",
				Property [ property_enum_id ] [ E_PROPERTY_ID ] ) ;
			
			mysql_tquery(mysql, query);

			SendServerMessage ( targetid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've bought %d %s, %s for $%s.", property_enum_id, address, zone, IntegerWithDelimiter(price) ) );
			SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've sold %d %s, %s for $%s.", property_enum_id, address, zone, IntegerWithDelimiter(price) ) );

			AddLogEntry(targetid, LOG_TYPE_SCRIPT, sprintf("Purchased property %d for $%s from %s", property_enum_id, IntegerWithDelimiter(price), ReturnPlayerName(playerid)));
			AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Sold property %d for $%s to %s", property_enum_id, IntegerWithDelimiter(price), ReturnPlayerName(targetid)));

			GivePlayerCash(playerid, price, "Property sale");
			TakePlayerCash(targetid, price, "Property purchase (From player)");

			if(price <= 10000) {
				SendAdminMessage(sprintf("(%d) %s has sold their property (ID %d) to (%d) %s for a very small price ( < $10000 ).", playerid, ReturnRPName(playerid), Property [ property_enum_id ] [ E_PROPERTY_ID ], targetid, ReturnRPName(targetid)));
			}

			foreach(new syncid: Player) {
				if ( IsPlayerInDynamicArea(syncid, Property [ property_enum_id ] [ E_PROPERTY_AREA ]  )) {

					PlayerTextDrawHide(syncid, house_info_box[playerid] );
					PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, Los Santos", address, property_enum_id, zone) ) ;
					PlayerTextDrawShow(syncid, house_info_box[playerid] );
				}
			}

			PlayerTextDrawHide(playerid, house_info_box[playerid]);

			return true ;
		}

	}

	new confirmstring[1024];

	format(confirmstring, sizeof(confirmstring), "{DEDEDE}{ed7f2b}(%d) %s{DEDEDE} is offering to sell you their {ed7f2b}property{DEDEDE}.\n\n", playerid, ReturnSettingsName(playerid, targetid));
	format(confirmstring, sizeof(confirmstring), "%s{A3A3A3}Seller: {DEDEDE}%s\n", confirmstring, ReturnSettingsName(playerid, targetid));
	format(confirmstring, sizeof(confirmstring), "%s{A3A3A3}Buyer: {DEDEDE}%s\n", confirmstring, ReturnSettingsName(targetid, targetid));
	format(confirmstring, sizeof(confirmstring), "%s{A3A3A3}Address: {DEDEDE} %d, %s, %s\n", confirmstring, property_enum_id, address, zone);
	format(confirmstring, sizeof(confirmstring), "%s{A3A3A3}Price: {32CD32}$%s\n\n", confirmstring, IntegerWithDelimiter(price));
	strcat(confirmstring, "{DEDEDE}Make sure the property details and price are correct.\n");
	strcat(confirmstring, "Press {A3A3A3}Accept {DEDEDE}to confirm the sale.");

	Dialog_ShowCallback ( targetid, using inline PropSellConfirm, DIALOG_STYLE_MSGBOX, "{A3A3A3}PROPERTY PURCHASE CONFIRMATION", confirmstring, "Accept", "Decline" );

	return true ;
}


// /propertytransfer [player] - gives your property to another player for free.
CMD:propertytransfer(playerid, params[]){


	if ( IsPlayerIncapacitated(playerid, false) ) {
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;
	new address [ 64 ], zone [ 64 ] ;

	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't transfer this property." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER ) {

		if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is owned by someone else" );
		}
	}

	else if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is already for sale!" );
	}

	new targetid ;

	if ( sscanf ( params, "k<player>", targetid ) ) {

		SendClientMessage(playerid, COLOR_ERROR, "/propertytransfer [playerid]" ) ;
		return SendClientMessage(playerid, COLOR_ERROR, "INFO: This command TRANSFERS your property. Use /propertysell if you want to sell it to someone.");
	}

	if(targetid == playerid)
		return SendServerMessage ( targetid, COLOR_ERROR, "Error", "A3A3A3", "You can't transfer your property to yourself." );

	if ( ! IsPlayerConnected(targetid ) || !IsPlayerNearPlayer(playerid, targetid, 10.0) ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Target isn't online or near you.");
	}

	if ( Property [property_enum_id] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_HOUSE && Player_GetOwnedHouses(targetid) >= Player_GetMaxOwnedHouses(targetid)) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Your targetid doesn't have any house ownership slots left." );
		return SendServerMessage ( targetid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any house ownership slots left. Use /myslots to check." );

	} else if ( Property [property_enum_id] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_BIZ && Player_GetOwnedBusinesses(targetid) >= Player_GetMaxOwnedBusinesses(targetid) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Your targetid doesn't have any business ownership slots left." );
		return SendServerMessage ( targetid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any business ownership slots left. Use /myslots to check." );
	}

	SendClientMessage(playerid, COLOR_INFO, sprintf("[TRANSFER] {DEDEDE}You have transferred your property to %s.", ReturnSettingsName(targetid, playerid)));
	SendClientMessage(targetid, COLOR_INFO, sprintf("[TRANSFER] {DEDEDE}%s has sent transferred their property to you.", ReturnSettingsName(playerid, targetid)));

	GetCoords2DZone(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
	GetPlayerAddress(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], address );

	Property [ property_enum_id ] [ E_PROPERTY_OWNER ] = Character [ targetid ] [ E_CHARACTER_ID ] ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_owner = %d WHERE property_id = %d", 
		Property [ property_enum_id ] [ E_PROPERTY_OWNER ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
	);

	mysql_tquery(mysql, query);

	// Resetting property collect upon buying to avoid money hoarding / going out of bounds.
    Property [ property_enum_id ] [ E_PROPERTY_COLLECT ] = 0 ; 

	mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_collect = 0 WHERE property_id = %d",
	    Property [ property_enum_id ] [ E_PROPERTY_ID ] ) ;
			
	mysql_tquery(mysql, query);

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Transferred property %d to %s", property_enum_id, ReturnPlayerName(targetid)));
	AddLogEntry(targetid, LOG_TYPE_SCRIPT, sprintf("Was transferred property %d from %s", property_enum_id, ReturnPlayerName(playerid)));

	foreach(new syncid: Player) {
	    if ( IsPlayerInDynamicArea(syncid, Property [ property_enum_id ] [ E_PROPERTY_AREA ]  )) {

			PlayerTextDrawHide(syncid, house_info_box[playerid] );
			PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, Los Santos", address, property_enum_id, zone) ) ;
			PlayerTextDrawShow(syncid, house_info_box[playerid] );
		}
	}

    PlayerTextDrawHide(playerid, house_info_box[playerid]);

	return true ;
}

 
// /propertyscrap - sells your property back to the server for a part of its price.
CMD:propertyscrap(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return true ;
    }

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;


	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_STATIC ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't buy this property." );
	}

	if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER ) {

		if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is owned by someone else." );
		}
	}

	else if ( Property [ property_enum_id ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property is already for sale!" );
	}

	static ConfirmPropScrapStr[1024];

	inline ConfirmPropScrapDlg(pid, dialogid, response, listitem, string:inputtext[]) 
	{
	    #pragma unused pid, dialogid, listitem, inputtext

		if ( ! response ) {
			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You have cancelled the scrap, your property wasn't affected." ) ;
		}

		if ( response ) {

			Property [ property_enum_id ] [ E_PROPERTY_OWNER ] = INVALID_PROPERTY_OWNER ;
			GivePlayerCash ( playerid, Property [ property_enum_id ] [ E_PROPERTY_PRICE ] / 3, "Property scrap" ) ;

			new query [ 256 ] ;

			mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_owner = %d WHERE property_id = %d", 
				Property [ property_enum_id ] [ E_PROPERTY_OWNER ], Property [ property_enum_id ] [ E_PROPERTY_ID ]
			);

			mysql_tquery(mysql, query);

			new address [ 64 ], zone [ 64 ] ;
			GetCoords2DZone(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
			GetPlayerAddress(Property [ property_enum_id ] [ E_PROPERTY_EXT_X ], Property [ property_enum_id ] [ E_PROPERTY_EXT_Y ], address );

			SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You've sold %s, %d. You've been refunded some of the buy cost.", address, property_enum_id  ));

			AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Sold %d, %s %s (SQL: %d) for $%s", property_enum_id, address, zone, Property [ property_enum_id ] [ E_PROPERTY_ID ], IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_PRICE ] / 3)));

			if ( Property [ property_enum_id ] [ E_PROPERTY_COLLECT ]  ) {
				SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf("You have received the remaining money in your property till: $%s.", IntegerWithDelimiter ( Property [ property_enum_id ] [ E_PROPERTY_COLLECT ] ) ) );

				GivePlayerCash ( playerid, Property [ property_enum_id ] [ E_PROPERTY_COLLECT ], "Property scrap (Property till)" ) ;

				Property [ property_enum_id ] [ E_PROPERTY_COLLECT ] = 0 ; 

				mysql_format(mysql, query, sizeof(query), "UPDATE properties SET property_collect = 0 WHERE property_id = %d",
					Property [ property_enum_id ] [ E_PROPERTY_ID ] ) ;
				
				mysql_tquery(mysql, query);
			}

			foreach(new syncid: Player) {
				if ( IsPlayerInDynamicArea(syncid, Property [ property_enum_id ] [ E_PROPERTY_AREA ]  )) {

					PlayerTextDrawHide(syncid, house_info_box[playerid] );

					if ( Property [ property_enum_id ] [ E_PROPERTY_PRICE ] > 0 ) {
						PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, Los Santos~n~~r~For Sale: $%s", address, property_enum_id, zone, IntegerWithDelimiter(Property [ property_enum_id ] [ E_PROPERTY_PRICE ]) ) ) ;
					}

					else {
						PlayerTextDrawSetString(playerid, house_info_box[playerid], sprintf("%s, %d~n~%s, Los Santos", address, property_enum_id, zone) ) ;
					}

					PlayerTextDrawShow(syncid, house_info_box[playerid] );
				}
			}

			PlayerTextDrawHide(playerid, house_info_box[playerid]);

		}

		return true ;
	}

	format(ConfirmPropScrapStr, sizeof(ConfirmPropScrapStr), "{EC9424}Warning! {DEDEDE}This is a destructive action!");

	strcat(ConfirmPropScrapStr, "\n\n{DEDEDE}You are about to scrap and {EC9424}SELL{DEDEDE} your property.");
	strcat(ConfirmPropScrapStr, "\n{DEDEDE}You will only be refunded a 1/3 of the price you bought it for.");
	strcat(ConfirmPropScrapStr, "\n{DEDEDE}If you want to sell it to someone, use /propertysell.");
	strcat(ConfirmPropScrapStr, "\n\n{DEDEDE}Are you sure you want to continue?");
	strcat(ConfirmPropScrapStr, "\n{f1c38a}You will not be refunded if you change your mind.");

	Dialog_ShowCallback ( playerid, using inline ConfirmPropScrapDlg, DIALOG_STYLE_MSGBOX, "{EC9424}SCRAP WARNING{DEDEDE}", ConfirmPropScrapStr, "Scrap it", "Cancel" );

	return true ;
}


// new shit

static PropertiesDlgStr[2048];
// Shows a list of a player's properties.
static ShowPlayerProperties(playerid, showplayerid)
{
	new map[100];
	new count = 0;

	new address[64], zone[64];

	format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "Type\tAddress");
	
	foreach(new i: Properties) {
	
		if ( Property [ i ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) 
		{
			continue ;
		}

		if ( Property [ i ] [ E_PROPERTY_OWNER ] != Character [ playerid ] [ E_CHARACTER_ID ] && Character[playerid][E_CHARACTER_RENTEDHOUSE] != Property[i][E_PROPERTY_ID] )
		{
			continue;
		}

		address [ 0 ] = EOS, zone [ 0 ] = EOS ;

		GetCoords2DZone(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
		GetPlayerAddress(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], address );

		if (Property[i][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_BIZ) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\n{4FC3F7}Business\t%d %s, %s", PropertiesDlgStr, i, address, zone);
		else if (Character[playerid][E_CHARACTER_RENTEDHOUSE] == Property[i][E_PROPERTY_ID]) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\n{DCE775}Residence\t%d %s, %s (Rented)", PropertiesDlgStr, i, address, zone);
		else if (Property[i][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_HOUSE) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\n{AED581}Residence\t%d %s, %s", PropertiesDlgStr, i, address, zone);
		else format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nStatic\t%d %s, %s (SQL: %d)", PropertiesDlgStr, i, address, zone, Property[i][E_PROPERTY_ID]);

		map[count] = i;
		count ++;
	}

	if (!count)
	{
		if (playerid == showplayerid) SendClientMessage(showplayerid, COLOR_VEHICLE, "You don't own or rent any properties.");
		else SendClientMessage(showplayerid, COLOR_VEHICLE, "This player doesn't own or rent any properties.");
		return true;
	}

	inline MyPropertiesDlg(pid, dialogid, response, listitem, string:inputtext[]) 
	{
		#pragma unused dialogid, inputtext, listitem

		if ( response ) 
		{
			new chosen = map[listitem];

			if (response)
			{
				ShowPropertyToPlayer(playerid, chosen, pid);
			}
		}
	}

	Dialog_ShowCallback ( showplayerid, using inline MyPropertiesDlg, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Properties of %s (%d)", ReturnSettingsName(playerid, showplayerid), playerid), PropertiesDlgStr, "Select", "Close" );
	return true;
}

// Shows the details of one property to a player.
static ShowPropertyToPlayer(playerid, propid, showplayerid, bool:noback=false)
{
	new i = propid;
	new address[64], zone[64];

	GetCoords2DZone(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
	GetPlayerAddress(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], address );

	new query [ 256 ] ;
	inline ReturnPropertyShit() 
	{
		new charname[32], accname[32];
		if (cache_num_rows())
		{
			cache_get_value_name(0, "player_name", charname);
			cache_get_value_name(0, "account_name", accname);
			strreplace(charname, "_", " ");
		}


		format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "ID\t%d", propid);
		format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nSQL ID\t%d", PropertiesDlgStr, Property[i][E_PROPERTY_ID]);
		format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nAddress\t%d %s, %s", PropertiesDlgStr, propid, address, zone);
		if (Property[i][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_HOUSE) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nType\t%s", PropertiesDlgStr, "{AED581}Residence");
		else if (Property[i][E_PROPERTY_TYPE] == E_PROPERTY_TYPE_BIZ) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nType\t%s", PropertiesDlgStr, "{4FC3F7}Business");
		else format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nType\t%s", PropertiesDlgStr, "Static");
		format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nLocked\t%s", PropertiesDlgStr, Property[i][E_PROPERTY_LOCKED] ? "{A5D6A7}Yes" : "{EF9A9A}No");
		
		if (cache_num_rows()) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nOwner\t%s (%s)", PropertiesDlgStr, charname, accname);
		else format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nOwner\t%s", PropertiesDlgStr, "{EF9A9A}None");

		new facID = Property[i][E_PROPERTY_FACTION];
		if (facID == 0) {
			format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nFaction\t(%d) {EF9A9A}None", PropertiesDlgStr, facID);
		} else {
			format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nFaction\t(%d) %s", PropertiesDlgStr, facID, Faction [ facID-1 ] [ E_FACTION_NAME ]);
		}
		
		format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nPrice\t$%s", PropertiesDlgStr, IntegerWithDelimiter(Property[i][E_PROPERTY_PRICE]));
		
		if (Property[i][E_PROPERTY_RENT])
		{
			format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nRentable\t{A5D6A7}Yes ($%s)", PropertiesDlgStr, IntegerWithDelimiter(Property[i][E_PROPERTY_RENT]));
		}
		else
		{
			format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nRentable\t%s", PropertiesDlgStr, "{EF9A9A}No");
		}

		if (Property[i][E_PROPERTY_FEE])
		{
			format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nEntrance Fee\t$%s", PropertiesDlgStr, IntegerWithDelimiter(Property[i][E_PROPERTY_FEE]));
		}
		else
		{
			format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nEntrance Fee\t%s", PropertiesDlgStr, "None");
		}
		
		if (Property [ i ] [ E_PROPERTY_OWNER ] == Character [ showplayerid ] [ E_CHARACTER_ID ] || GetPlayerAdminLevel(showplayerid))
		{
			new weapons = 0;
			for (new x = 0; x < 10; x ++)
			{
				if (Property [ i ] [ E_PROPERTY_GUN ] [ x ] && Property [ i ] [ E_PROPERTY_AMMO ] [ x ])
				{
					weapons ++;
				}
			}

			if (weapons) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nWeapons\t%d", PropertiesDlgStr, weapons);
			else format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nWeapons\t%s", PropertiesDlgStr, "None");

			new Float:drugs;
			for (new x = 0; x < 10; x ++)
			{
				if (Property [ i ] [ E_PROPERTY_DRUGS_AMOUNT ] [ x ] > 0)
				{
					drugs += Property [ i ] [ E_PROPERTY_DRUGS_AMOUNT ] [ x ];
				}
			}

			if (drugs) format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nDrugs\t%0.1fg", PropertiesDlgStr, drugs);
			else format(PropertiesDlgStr, sizeof(PropertiesDlgStr), "%s\nDrugs\t%s", PropertiesDlgStr, "None");
		}

		inline MyPropertiesDlg(pid, dialogid, response, listitem, string:inputtext[]) 
		{
			#pragma unused dialogid, inputtext, listitem

			if ( !response && !noback ) 
			{
				ShowPlayerProperties(playerid, pid);
				return true;
			}
		}

		if (!noback) Dialog_ShowCallback ( showplayerid, using inline MyPropertiesDlg, DIALOG_STYLE_TABLIST, sprintf("%d %s, %s", i, address, zone), PropertiesDlgStr, "OK", "Back" );
		else Dialog_ShowCallback ( showplayerid, using inline MyPropertiesDlg, DIALOG_STYLE_TABLIST, sprintf("%d %s, %s", i, address, zone), PropertiesDlgStr, "OK" );
	}

	mysql_format ( mysql, query, sizeof ( query ), "SELECT `characters`.`player_name`, `accounts`.`account_name` FROM `characters` JOIN `accounts` ON `accounts`.`account_id` = `characters`.`account_id` WHERE `player_id` = '%d'", Property [ i ] [ E_PROPERTY_OWNER ] ) ;
	MySQL_TQueryInline(mysql, using inline ReturnPropertyShit, query, "");

	return true;

}

// /checkproperties [player] - (staff) lists a player's properties.
CMD:checkproperties(playerid, params[]) {

	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR)
		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");

	new targetid;

	if (sscanf(params, "k<player>", targetid))
		return SendClientMessage(playerid, -1, "/checkproperties [player]");

	if (!IsPlayerConnected(targetid))
		return SendClientMessage(playerid, -1, "Target isn't connected.");

	ShowPlayerProperties(targetid, playerid);

	new string[100];
	format(string, sizeof(string), "used /checkproperties on (%d) %s", targetid, ReturnRPName(targetid));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, string);

	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR)
	{
		format (string, sizeof ( string ), "[AdminCmd]: (%d) %s %s", playerid, ReturnRPName(playerid), string);
		SendAdminMessage(string);
	}

	return true ;
}

// /propertycheck [id] - (staff) shows the details of a property.
CMD:propertycheck(playerid, params[])
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR)
		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");

	new id;

	if (sscanf(params, "d", id))
	{
		id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER );
	}

	if (id == INVALID_PROPERTY_ID)
	{
		return SendClientMessage(playerid, -1, "/propertycheck [property id]");
	}
		
	if ( id < 0 || id > MAX_PROPERTIES) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (doesn't exist)!") ;
	}

	if ( Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered (not set up)!") ;
	}

	ShowPropertyToPlayer(playerid, id, playerid, true);
	return true;
}

CMD:propcheck(playerid, params[])
{
	return cmd_propertycheck(playerid, params);
}

CMD:propinfo(playerid, params[])
{
	return cmd_propertycheck(playerid, params);
}

// /myproperties - lists your properties.
CMD:myproperties(playerid, params[]) 
{
	ShowPlayerProperties(playerid, playerid);
	return true ;
}

// Prints the properties a player owns to chat.
Property_ShowPlayerProperties(playerid, target ) {
	new address [ 64 ], zone [ 64 ] ;

	foreach(new i: Properties) {

		if ( Property [ i ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

			continue ;
		}

		if ( Property [ i ] [ E_PROPERTY_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ] ) {

			address [ 0 ] = EOS, zone [ 0 ] = EOS ;

			GetCoords2DZone(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ));
			GetPlayerAddress(Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], address );

			SendClientMessage(target, 0x3A84C4FF, sprintf("[Owned Property]{DEDEDE} (id. %d) Located at %s, %s", i, address, zone ) );
		}

		else continue ;
	}

	return true ;
}

CMD:givepropertykey(playerid, params[]){ return cmd_pdup(playerid, params); }
CMD:givepropkey(playerid, params[]){ return cmd_pdup(playerid, params); }
CMD:givepkey(playerid, params[]){ return cmd_pdup(playerid, params); }
CMD:propertykey(playerid, params[]){ return cmd_pdup(playerid, params); }

// /pdup [player] - gives another player a duplicate key to your property.
CMD:pdup(playerid, params[]){

	if(IsPlayerIncapacitated(playerid, false))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use this command right now.");
	
	new target;

	if(sscanf(params, "k<player>", target)) {
		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/pdup [playerid]");
		return SendServerMessage ( playerid, COLOR_ERROR, "Warning", "A3A3A3", "Duplicate keys are saved. Use /changelock to revoke a key.");
	}

	if(!IsPlayerConnected(target))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Target is not connected.");

	if(!IsPlayerNearPlayer(playerid, target, 10.0))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be closer to your taget to give them the keys.");

	if(playerid == target)
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You already have keys to your own property.");

	new property_enum_id = Property_GetClosestEntity( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( property_enum_id == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near a property entrance." );
	}

	if(Property[property_enum_id][E_PROPERTY_OWNER] != Character[playerid][E_CHARACTER_ID])
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only duplicate keys to properties you own!");

	SendServerMessage ( playerid, COLOR_SECURITY, "Keys", "A3A3A3", sprintf("You have given %s a pair of keys to your property.", ReturnSettingsName(target, playerid)));
	SendServerMessage ( target, COLOR_SECURITY, "Keys", "A3A3A3", sprintf("%s has given your a pair of keys to their property.", ReturnSettingsName(playerid, target)));

	GivePropertyKey(target, property_enum_id);

	return true;
}

// Gives a player a duplicate key to a property.
GivePropertyKey(playerid, propid){

	new query[256];

	Character [ playerid ] [ E_CHARACTER_PROP_DUP ] = Property [propid] [E_PROPERTY_ID];

	format(query, sizeof(query), "UPDATE characters SET player_propdup = %d WHERE player_id = %d", Character [ playerid ] [ E_CHARACTER_PROP_DUP ], Character [ playerid ] [ E_CHARACTER_ID ] );
	mysql_tquery(mysql, query);

	return true;
}

CMD:duprevoke(playerid, params[]){ return cmd_changelock(playerid, params); }
// /changelock - changes the lock on your vehicle or property (invalidates old duplicate keys).
CMD:changelock(playerid, params[]){

	if(IsPlayerIncapacitated(playerid, false))
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use this command right now.");
	
	new vehicleid = Vehicle_GetClosestEntity(playerid, .radius = 5.0);
	new propertyid = Property_GetClosestEntity(playerid, PROPERTY_NEAR_ENTER, .radius = 5.0);
	new type; 

	if ( vehicleid == INVALID_VEHICLE_ID && propertyid != INVALID_PROPERTY_ID) {
		type = 1;
	} else if(vehicleid != INVALID_VEHICLE_ID && propertyid == INVALID_PROPERTY_ID) {

		new veh_enum_id = Vehicle_GetEnumID ( vehicleid );
		if ( veh_enum_id == -1 ) return SendClientMessage(playerid, COLOR_ERROR, "You're not near any proper vehicle! (couldn't fetch ID)");	
		type = 2;

	} else {
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near any vehicle / property entrance!");
	}

	new query[256];

	switch(type) {

		case 1: { // property

			new access = Property [ propertyid ] [ E_PROPERTY_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ];

			if(!access) {
				return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You do not own this property.");
			} else {
				SendServerMessage ( playerid, COLOR_SECURITY, "Lock", "A3A3A3", "You have changed your property's lock. No one but you can unlock / lock it now.");

				foreach(new userid: Player){

					if ( Character [ userid ] [ E_CHARACTER_PROP_DUP ] == Property [ propertyid ] [ E_PROPERTY_ID ] ) {
						Character [ userid ] [ E_CHARACTER_PROP_DUP ] = -1;
					} else continue;

				}

				format(query, sizeof(query), "UPDATE characters SET player_propdup = %d WHERE player_propdup = %d", -1, Property [ propertyid ] [ E_PROPERTY_ID ] );
				mysql_tquery(mysql, query);
			}
		}

		case 2: { // vehicle

			new veh_enum_id = Vehicle_GetEnumID ( vehicleid );
			new access = Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ];

			if(!access) {
				return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You do not own this vehicle.");
			} else {

				SendServerMessage ( playerid, COLOR_SECURITY, "Lock", "A3A3A3", "You have changed your vehicle's lock. No one but you can unlock / lock it now.");

				new sqlid = Vehicle[veh_enum_id][E_VEHICLE_SQLID];

				foreach(new userid: Player) {
					for (new i = 0; i < 2; i++) {
						if (Character[userid][E_CHARACTER_VEH_KEYS][i] == sqlid) {
							Character[userid][E_CHARACTER_VEH_KEYS][i] = -1;
						}
					}
				}

				format(query, sizeof(query),
					"DELETE FROM character_vehicle_keys WHERE vehicle_sqlid = %d", sqlid);
				mysql_tquery(mysql, query);

			}
		}
	}

	return true;
}



// Returns true if the player holds a duplicate key to a property.
HasPropertyDuplicateKey(playerid, propid){

	if( Character [playerid] [E_CHARACTER_PROP_DUP] == Property [propid] [E_PROPERTY_ID])
		return true;

	return false;
}

// Returns true if the player rents the property.
ORP_IsPropertyRenter(playerid, prop_enum_id)
{
	if (Character[playerid][E_CHARACTER_RENTEDHOUSE] == Property[prop_enum_id][E_PROPERTY_ID]) return true;
	return false;
}

// Returns true if the player owns the property.
ORP_IsPropertyOwner(playerid, prop_enum_id)
{
	return Property_HasAccess(playerid, prop_enum_id);
}

// Slots system


// /myslots - shows how many houses and businesses you own and may own.
CMD:myslots(playerid)
{
    new owned_houses = Player_GetOwnedHouses(playerid);
    new max_houses   = Player_GetMaxOwnedHouses(playerid);

    new owned_bizzes = Player_GetOwnedBusinesses(playerid);
    new max_bizzes   = Player_GetMaxOwnedBusinesses(playerid);

    new owned_cars   = Player_GetOwnedVehicles(playerid);
    new max_cars     = Player_GetMaxOwnedVehicles(playerid);

    new premium = Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL];

    SendClientMessage(playerid, COLOR_BLUE, "[Player Ownable Slots]:");

    SendClientMessage(playerid, COLOR_GRAD0, 
        sprintf("[Cars]{DEDEDE} %d / %d slots used.", owned_cars, max_cars));

    SendClientMessage(playerid, COLOR_GRAD0, 
        sprintf("[Houses]{DEDEDE} %d / %d slots used.", owned_houses, max_houses));

    SendClientMessage(playerid, COLOR_GRAD0, 
        sprintf("[Businesses]{DEDEDE} %d / %d slots used.", owned_bizzes, max_bizzes));

	// Base system explanation
	ZMsg_SendClientMessage(playerid, COLOR_WARNING,
		"[Base Houses]{A3A3A3} (<75h):{DEDEDE} 1 {A3A3A3}| (75-199h):{DEDEDE} 2 {A3A3A3}| (>=200h):{DEDEDE} 3");

	ZMsg_SendClientMessage(playerid, COLOR_WARNING,
		"[Base Businesses]{A3A3A3} (<75h):{DEDEDE} 0 {A3A3A3}| (75-199h):{DEDEDE} 1 {A3A3A3}| (>=200h):{DEDEDE} 2");

	ZMsg_SendClientMessage(playerid, COLOR_WARNING,
		"[Vehicles]{A3A3A3} (<75h):{DEDEDE} 2 {A3A3A3}| (75-149h):{DEDEDE} 3 {A3A3A3}| (150-249h):{DEDEDE} 4 {A3A3A3}| (>=250h):{DEDEDE} 5");

    // VIP bonus display
    switch (premium)
    {
        case E_PREMIUM_LVL_3: // Silver
        {
            ZMsg_SendClientMessage(playerid, 0xC0C0C0FF,
            "[Silver VIP Bonus]{DEDEDE} +1 House Slot, +1 Business Slot");
        }
        case E_PREMIUM_LVL_4: // Gold
        {
            ZMsg_SendClientMessage(playerid, 0xFFD700FF,
            "[Gold VIP Bonus]{DEDEDE} +2 House Slots, +1 Business Slot");
        }
    }

    return true;
}


Player_GetOwnedHouses ( playerid ) {

	new count = 0 ;

	foreach(new i: Properties) {

		if ( Property [ i ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_HOUSE ) {
			if ( Property [ i ] [ E_PROPERTY_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ] ) {

				count ++ ;
			}

			else continue ;
		}
	}

	return count ;
}

// Returns how many houses a player may own (grows with hours played).
Player_GetMaxOwnedHouses(playerid)
{
    new hours = Character[playerid][E_CHARACTER_HOURS];
    new max_houses = 1;

    // Base slots from hours
    if (hours >= 130) max_houses = 3;
    else if (hours >= 50) max_houses = 2;

    // VIP bonus
    switch (Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL])
    {
        case E_PREMIUM_LVL_3: // Silver
        {
            max_houses += 1;
        }
        case E_PREMIUM_LVL_4: // Gold
        {
            max_houses += 2;
        }
    }

    return max_houses;
}

Player_GetOwnedBusinesses ( playerid ) {

	new count = 0 ;

	foreach(new i: Properties) {

		if ( Property [ i ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_BIZ ) {
			if ( Property [ i ] [ E_PROPERTY_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ] ) {

				count ++ ;
			}

			else continue ;
		}
	}

	return count ;
}

// Returns how many businesses a player may own (grows with hours played).
Player_GetMaxOwnedBusinesses(playerid)
{
    new hours = Character[playerid][E_CHARACTER_HOURS];
    new max_businesses = 0;

    // Base slots from hours
    if (hours >= 130) max_businesses = 2;
    else if (hours >= 50) max_businesses = 1;

    // VIP bonus
    switch (Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL])
    {
        case E_PREMIUM_LVL_3: // Silver
        {
            max_businesses += 1;
        }
        case E_PREMIUM_LVL_4: // Gold
        {
            max_businesses += 1;
        }
    }

    return max_businesses;
}
