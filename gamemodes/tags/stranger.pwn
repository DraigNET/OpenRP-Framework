// ============================================================================
// File: tags/stranger.pwn
// Masks and strangers: /mask, /removemask hide a character's name behind a Mask ID, /showmasks
// and /checkmasks for staff, and fake names.
// Commands: /mask /removemask /showmasks /checkmasks /fakename
// ============================================================================

// /mask - puts on or takes off a mask.
CMD:mask(playerid) {

	if(Character[playerid][E_CHARACTER_HOURS] < 8) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You need at least 8 playing hours before you can use a /mask.");
	}


	if(! Character[playerid][E_CHARACTER_MASKID] && !IsPlayerInAnyGovFaction(playerid, false)) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have a mask! Buy one from the 24/7.");
	}

	if(IsPlayerIncapacitated(playerid, false) && !PlayerVar[playerid][E_PLAYER_IS_MASKED]) 
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't put on a mask just now.");
	}

	// Special case if they're a cop and never had a mask before
	if(!Character[playerid][E_CHARACTER_MASKID] && IsPlayerInAnyGovFaction(playerid, false)) {
		Character [ playerid ] [ E_CHARACTER_MASKID ] = CalculateMaskID(playerid)  ;
    	SendServerMessage ( playerid, COLOR_SERVER, "Server", "DEDEDE", sprintf("You recieved a mask from your faction. Your new mask ID is %d.", Character [ playerid ] [ E_CHARACTER_MASKID ] ) ) ;

    	new query [ 256 ] ;

    	mysql_format(mysql, query, sizeof(query), "UPDATE characters SET player_maskid = %d WHERE player_id = %d", 

    		Character [ playerid ] [ E_CHARACTER_MASKID ], 
    		Character [ playerid ] [ E_CHARACTER_ID ] ) ;

    	mysql_tquery(mysql, query);
	}

	if(PlayerVar[playerid][E_PLAYER_IS_MASKED]) {

		ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "**", "takes off their mask.", .showid = false, .annonated=true);
        PlayerVar[playerid][E_PLAYER_IS_MASKED]= false ;
        ToggleMask(playerid, false);

		new year, month, day, hour, minute, second;
		stamp2datetime(gettime(), year, month, day, hour, minute, second, 1);
		SendServerMessage(playerid, COLOR_ORANGE, "Mask", "A3A3A3", sprintf("You removed your mask at %02d:%02d:%02d, it will be discoverable in your inventory for 30 minutes.", hour, minute, second));
    }

    else if(! PlayerVar[playerid][E_PLAYER_IS_MASKED]) 
	{

		if(!Attachments_CountMask(playerid) && !GetPlayerAdminLevel(playerid) && !Character[playerid][E_CHARACTER_FACTIONID])
		{
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You aren't wearing a face covering object, check /toys.");
		}

		ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "**", "puts on their mask.", .showid = false, .annonated=true);
        PlayerVar[playerid][E_PLAYER_IS_MASKED]= true ;
        ToggleMask(playerid, true);

		new year, month, day, hour, minute, second;
		stamp2datetime(gettime(), year, month, day, hour, minute, second, 1);
		SendServerMessage(playerid, COLOR_ORANGE, "Mask", "A3A3A3", sprintf("You put on your mask at %02d:%02d:%02d.", hour, minute, second));
    }

	PlayerVar[playerid][E_PLAYER_LAST_MASKED_AT]= gettime();

	return true ;
}

// /removemask [player] - pulls a mask off a nearby cuffed or injured player.
CMD:removemask(playerid, params[]) {

	new userid ;

	if(sscanf(params, "u", userid)) {

		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/removemask [targetid]");
	}

	if(! IsPlayerConnected(userid)) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Target isn't connected.") ;
	}

	// If no admin
	if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) {

		if(! IsPlayerIncapacitated(userid, false)) {

			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Your target must be incapacitated!(injured/tased/cuffed/...)");
		}
		else if(!IsPlayerNearPlayer(playerid, userid, 5.0))
		{
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're too far away from this player.");
		}
	}

	if(!PlayerVar[userid][E_PLAYER_IS_MASKED])
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This player isn't masked.");
	}

	SendClientMessage(userid, COLOR_GRAD0, sprintf("%s has removed your mask.",  ReturnSettingsName(playerid, userid, false))) ;
	SendClientMessage(playerid, COLOR_GRAD0, sprintf("You removed the mask from(%d) %s.",  userid, ReturnSettingsName(userid, playerid, false))) ;
	cmd_mask(userid);

	return true ;
}

// /showmasks - (staff) shows who is masked.
CMD:showmasks(playerid) {

	new Float: x, Float: y, Float: z;
	GetPlayerPos(playerid, x, y, z);

	foreach(new targetid: Player) {

		if(GetPlayerDistanceFromPoint(targetid, x, y, z) < 10.0 && PlayerVar[targetid][E_PLAYER_IS_MASKED]) {

			SetPlayerChatBubble(targetid, sprintf("Stranger %i", GetPlayerMaskID(targetid)), 0xA3A3A3AA, 15.0, 10000);
		}
		else if(!PlayerVar[targetid][E_PLAYER_IS_MASKED]) continue;
	}

	return 1;
}

CMD:checkmasks(playerid) {
	return cmd_showmasks(playerid);
}

// Fake Names for FEB
CMD:fakename(playerid, params[]) {


	if(!IsPlayerInFederalFaction(playerid, true)) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be an agent on duty to use this command.");
	}

	if(PlayerVar[playerid][E_PLAYER_IS_MASKED]) {

        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must remove your mask before using this command.");
    }

	if (!IsPlayerNearArmory(playerid)) 
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not at the locker room.");

	new name[MAX_PLAYER_NAME];
	if (sscanf(params, "s[32]", name))
	{
		SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/fakename [firstname_lastname]/[OFF]");
		return true;
	}

	if(IsPlayerIncapacitated(playerid, false) && !PlayerVar[playerid][E_PLAYER_IS_FAKENAME]) 
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use a fake name right now.");
	}

	if(!strcmp(name, "off")) {
		if(PlayerVar[playerid][E_PLAYER_IS_FAKENAME])
		{
			PlayerVar[playerid][E_PLAYER_IS_FAKENAME] = false ;
			SetPlayerName(playerid, Character [ playerid ] [ E_CHARACTER_NAME ]);
			return SendServerMessage(playerid, COLOR_ORANGE, "Fake Name", "A3A3A3", "You changed back to you real name.");
		} else {
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You weren't using a fake name.");
		}
        
    }
	else if(!IsRPNameRegex(name)) {
		SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/fakename [firstname_lastname]/[OFF]");
		return true;
	}
    else if(! PlayerVar[playerid][E_PLAYER_IS_FAKENAME]) 
	{
		new query[256];
		inline CheckIfCharacterExists() 
		{
			if (cache_num_rows()) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can not use an exiting player name.");
			
			PlayerVar[playerid][E_PLAYER_IS_FAKENAME] = true ;
			strcpy(PlayerVar[playerid][E_PLAYER_FAKENAME], name, sizeof(name));
        	SetPlayerName(playerid, name);
		}

		mysql_format ( mysql, query, sizeof ( query ), "SELECT player_name FROM characters WHERE player_name LIKE '%e'", name ) ;
		MySQL_TQueryInline(mysql, using inline CheckIfCharacterExists, query, "");
    }

	return true ;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {
    foreach(new targetid: Player) {
        ShowPlayerNameTagForPlayer(targetid, playerid, true); // Enable names from connector for everybody.
    }
	return 1;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerSpawn(playerid) {
	foreach(new targetid: Player) {
        if(IsPlayerMasked(targetid)) {
            ShowPlayerNameTagForPlayer(playerid, targetid, false); // If target is masked, make sure to hide their names for new connector
        }
    }
	return 1;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerStreamIn(playerid, forplayerid) { 
	if(IsPlayerMasked(playerid)) {
		ShowPlayerNameTagForPlayer(forplayerid, playerid, false); 
	}
    return 1;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid) { 
	foreach(new targetid: Player) {
        if(IsPlayerMasked(targetid)) {
            ShowPlayerNameTagForPlayer(playerid, targetid, false); // If target is masked, make sure to hide their names for new connector
        }
    }
    return 1;
}

// Turns the mask on or off for a player and updates their name tag.
ToggleMask(playerid, bool: status) {
    foreach(new targetid: Player) {

        if(status) {
            ShowPlayerNameTagForPlayer(targetid, playerid, false);
        }
        else ShowPlayerNameTagForPlayer(targetid, playerid, true);
		UpdateTabList(targetid, playerid); // this might be laggy as fuck
    }
}

// Creates a unique mask id for the player (Stranger_1234).
CalculateMaskID(playerid) {

	new accid = Account[playerid][E_PLAYER_ACCOUNT_ID], 
		charid = Character[playerid][E_CHARACTER_ID];

	new mask_id =((accid + charid) / 2);

	// Since this algorithm consists of accid and charid, it will fail for the first few hundred players.(and provide ids below MAX_PLAYERS)
	// To prevent this, let's check if it's smaller than MAX_PLAYERS and edit it if so.
	if(mask_id < MAX_PLAYERS) {
		mask_id += MAX_PLAYERS;
	} 

	mask_id += random(99) ;

	return mask_id ;
}

// Returns true if the player is masked.
IsPlayerMasked(playerid) {

	if(playerid == INVALID_PLAYER_ID) {

		return false ;
	}

	return PlayerVar[playerid][E_PLAYER_IS_MASKED];
}

// Returns the player's mask id.
GetPlayerMaskID(playerid) {

	if(playerid == INVALID_PLAYER_ID) {

		return false ;
	}

	return Character[playerid][E_CHARACTER_MASKID];
}

// Returns true if the player has a fake name.
IsPlayerFakeName(playerid) {
	if(playerid == INVALID_PLAYER_ID) {
		return false ;
	}

	return PlayerVar[playerid][E_PLAYER_IS_FAKENAME];
}
