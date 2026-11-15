// ============================================================================
// File: admin/misc.pwn
// Miscellaneous admin commands: teleport to coordinates (/gotoxyz), set interior or virtual
// world, slap, view coordinates, hide admin status, change a player's password, and the
// endorsement leaderboard.
// Commands: /streamcount /slap /setinterior /setint /setvirtualworld /setvw /gotoxyz /gotopos
// /getcoordinates /ahide /getstate /getdistance /distance /dist /setpass /giverp /listendorsed
// /adminmessage /removemessage /playermessages /setadminmotd
// ============================================================================

// /streamcount - (senior admin) shows how many streamer objects you can see and how many exist in
// total, for performance checks.
CMD:streamcount(playerid) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new visible = Streamer_CountVisibleItems ( playerid, STREAMER_TYPE_OBJECT ) ;
	new total   = Streamer_CountItems ( STREAMER_TYPE_OBJECT ) ;

	return SendServerMessage ( playerid, COLOR_ORANGE, "Streamer", "A3A3A3", sprintf ( "Objects visible: %d | Total placed: %d", visible, total ) ) ;
}

// /slap [player] - throws a player up into the air (a light-hearted warning).
CMD:slap(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new targetid ;

	if ( sscanf ( params, "k<player>", targetid ) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/slap [targetid]");
	}

	if ( ! IsPlayerConnected ( targetid ) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Target isn't connected.");
	}

  	new Float:x, Float:y, Float:z;

	GetPlayerPos ( targetid, x, y, z ) ;
	PauseAC(targetid, 3);
	SetPlayerPos ( targetid, x, y, z + 4 ) ;

	PlayerPlaySound ( targetid, 1190, x, y, z ) ;
	
	AddLogEntry(targetid, LOG_TYPE_ADMIN, sprintf("Was slapped by %s", ReturnRPName(playerid)));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Slapped %s", ReturnRPName(targetid)));

	GPS_ClearCheckpoint(targetid);
	return true ;
}

CMD:setinterior(playerid, params[]) {

	return cmd_setint(playerid, params);
}
// /setint [player] [interior] - sets a player's interior id (alias /setinterior).
CMD:setint(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new targetid, interior ;

	if ( sscanf ( params, "k<player>i", targetid, interior ) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/setint(erior) [targetid] [interior]");
	}

	if ( ! IsPlayerConnected(targetid) ) {
		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Target isn't connected.");
	}	

	SetPlayerInterior(targetid, interior);

	new string [ 96 ] ;

	format ( string, sizeof ( string ), "Set %s's interior to %d", ReturnSettingsName(targetid, playerid, .color=false), interior ) ;
	SendClientMessage(playerid, -1, string );
	
	AddLogEntry(playerid, LOG_TYPE_ADMIN, string);

	format ( string, sizeof ( string ), "%s has set your interior to %d", ReturnSettingsName(targetid, playerid, .color=false), interior ) ;
	SendClientMessage(targetid, -1, string );

	return true ;
}

CMD:setvirtualworld(playerid, params[]) {

	return cmd_setvw(playerid, params);
}
// /setvw [player] [world] - sets a player's virtual world (alias /setvirtualworld).
CMD:setvw(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new targetid, virtualworld ;

	if ( sscanf ( params, "k<player>i",targetid, virtualworld ) ) {

		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/setv(irtual)w(orld) [targetid] [virtualworld]");
	}

	if ( ! IsPlayerConnected(targetid) ) {
		return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Target isn't connected.");
	}	

	SetPlayerVirtualWorld(targetid, virtualworld);

	new string [ 96 ] ;
	format ( string, sizeof ( string ), "Set %s's virtualworld to %d", ReturnSettingsName(targetid, playerid, .color=false), virtualworld ) ;
	SendClientMessage(playerid, -1, string );
	AddLogEntry(playerid, LOG_TYPE_ADMIN, string);

	format ( string, sizeof ( string ), "%s has set your virtualworld to %d", ReturnSettingsName(playerid, targetid, .color=false), virtualworld ) ;
	SendClientMessage(targetid, -1, string );

	return true ;
}


CMD:gotoxyz ( playerid, params [] ) {
	
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new Float: x, Float: y, Float: z, interior, virtualworld ;

	if ( sscanf ( params, "fffI(0)I(0)", x, y, z, interior, virtualworld ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/gotoxyz [x coord] [y coord] [z coord] [optional:interior] [optional:virtualworld]" )  ;
	}

	ORP_SetPlayerPos ( playerid, x, y, z ) ;

	SetPlayerInterior ( playerid, interior ) ;
	SetPlayerVirtualWorld ( playerid, virtualworld ) ;

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("teleported to %.02f, %.02f, %.02f in interior ID %i and virtual world ID %i.", x, y, z, interior, virtualworld));

	return true ;
}

CMD:gotopos ( playerid, params [] ) {
	return cmd_gotoxyz(playerid, params);
}


// /getcoordinates - prints your position, angle, interior and world; useful when placing things
// on the map.
CMD:getcoordinates(playerid, params[]) {
	
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}


	new Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;

	new Float: angle ;
	GetPlayerFacingAngle(playerid, angle ) ;

	new interior = GetPlayerInterior(playerid), virtualworld = GetPlayerVirtualWorld(playerid) ;

	SendClientMessage(playerid, COLOR_INFO, "Your current coordinates:" ) ;
	SendClientMessage(playerid, 0xDEDEDEFF, sprintf(" x(%f) y(%f) z(%f) a(%f)", x, y, z, angle ) ) ;
	SendClientMessage(playerid, 0xA3A3A3FF, sprintf(" int(%d) world (%d)", interior, virtualworld ) ) ;

	return true ;
}

// /ahide - toggles hiding your admin status from the /admins list.
CMD:ahide(playerid, params[]){

	if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;

	if(PlayerVar[playerid][E_PLAYER_ADMIN_HIDDEN]) {

		SendServerMessage ( playerid, COLOR_ERROR, "Admin Hide", "A3A3A3", "You are no longer admin hidden.") ;
		PlayerVar[playerid][E_PLAYER_ADMIN_HIDDEN] = false;

	} else {

		SendServerMessage ( playerid, COLOR_ERROR, "Admin Hide", "A3A3A3", "You have just hidden yourself as an admin. You are no longer shown on /admins. ") ;
		SendServerMessage ( playerid, COLOR_ERROR, "Admin Hide", "A3A3A3", "If you want to be hidden from /id aswell, go on admin duty.") ;

		PlayerVar[playerid][E_PLAYER_ADMIN_HIDDEN] = true;
	}

	return true;
}


// Just some extra stuff that might be helpful atm
static PlayerStates[10][40] = 
{
	"PLAYER_STATE_NONE",
	"PLAYER_STATE_ONFOOT",
	"PLAYER_STATE_DRIVER",
	"PLAYER_STATE_PASSENGER",
	"PLAYER_STATE_EXIT_VEHICLE",
	"PLAYER_STATE_ENTER_VEHICLE_DRIVER",
	"PLAYER_STATE_ENTER_VEHICLE_PASSENGER",
	"PLAYER_STATE_WASTED",
	"PLAYER_STATE_SPAWNED",
	"PLAYER_STATE_SPECTATING"
};

// /getstate [player] - shows a player's SA-MP state (on foot, driver, passenger, spectating...).
CMD:getstate(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) return 0;

	new targetid, playerstate;
    if (sscanf(params, "k<player>", targetid))
		return SendClientMessage(playerid, -1, "/getplayerstate [player]");

    if (!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, -1, "Invalid player target.");

	playerstate = GetPlayerState(targetid);
    SendClientMessage(playerid, -1, sprintf("%s (%d): %s (%d)", ReturnRPName(targetid), targetid, PlayerStates[playerstate], playerstate));

	return 1;
}

// /getdistance [player] - shows how far away a player is from you (aliases /distance, /dist).
CMD:getdistance(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) return 0;

	new targetid;
    if (sscanf(params, "k<player>", targetid) || !IsPlayerConnected(targetid))
		return SendClientMessage(playerid, -1, "/getdistance [player]");

	new Float:x, Float:y, Float:z;
	GetPlayerPos(targetid, x, y, z);

	new Float:distance = GetPlayerDistanceFromPoint(playerid, x, y, z);

	new address[64], zone[64];
	GetCoords2DZone(x, y, zone, sizeof ( zone ));
	GetPlayerAddress(x, y, address );

    SendClientMessage(playerid, -1, sprintf("You are %.02fm away from %s (%d), location: %s, %s.", distance, ReturnRPName(targetid), targetid, address, zone));

	return 1;
}

CMD:distance(playerid, params[])
{
	return cmd_getdistance(playerid, params);
}

CMD:dist(playerid, params[])
{
	return cmd_getdistance(playerid, params);
}


new ChangingPassword[MAX_PLAYERS][MAX_PLAYER_NAME];
// /setpass [account] [password] - (developer) changes an account's password; the new password is
// hashed with bcrypt.
CMD:setpass(playerid, params[]) {
	// master-acc
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_DEVELOPER ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new master_acc[MAX_PLAYER_NAME], pass [ MAX_PASSWORD_LENGTH ], query [ 256 ] ;

	if ( sscanf ( params, "s[34] s[64]", master_acc, pass ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/setpass [account name] [pass]") ;
	}

	if ( strlen ( master_acc ) < 0 || strlen ( master_acc ) > MAX_PLAYER_NAME ) {

		format ( query, sizeof ( query ), "Master account name can't be shorter than 0 or longer than %d.", MAX_PLAYER_NAME ) ;
		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3", query ) ;
	}

	if ( strlen ( pass ) > sizeof ( pass ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Password can't be longer than 64 characters.") ;
	}

	query[0]=EOS;

	// Log the attempt up front so it's recorded even if the account lookup fails. Never log the password itself.
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Attempted /setpass on account %s", master_acc), true);

	inline ReturnAccountName() {
		if (!cache_num_rows()) {
			return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Database didn't return any account data. Maybe your mistyped the name" )  ;
		}

		else {
			format(ChangingPassword[playerid], MAX_PLAYER_NAME, master_acc);
			bcrypt_hash(playerid, "OnPlayerPasswordChanged", pass, BCRYPT_COST);
		}
	}

	mysql_format ( mysql, query, sizeof ( query ), "SELECT account_id, account_lastip FROM accounts WHERE account_name = '%e'", master_acc ) ;
	MySQL_TQueryInline(mysql, using inline ReturnAccountName, query, "");


	return true ;
}

forward OnPlayerPasswordChanged(playerid);
// bcrypt callback for /setpass: writes the new password hash to the accounts table.
public OnPlayerPasswordChanged(playerid)
{
	new hash[BCRYPT_HASH_LENGTH], query[256], master_acc[MAX_PLAYER_NAME];
	bcrypt_get_hash(hash);
	format(master_acc, MAX_PLAYER_NAME, ChangingPassword[playerid]);
	ChangingPassword[playerid][0] = EOS;

	format ( query, sizeof ( query ), "[AdmCmd]: %s has changed the account password of %s.", Account[playerid][E_PLAYER_ACCOUNT_NAME], master_acc);
	SendAdminMessage(query);

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE `accounts` SET account_password = '%e' WHERE account_name = '%e'", hash, master_acc ) ;
	mysql_tquery(mysql, query);

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Updated password of %s", master_acc));
}


// /giverp [player] - gives an RP point to a player who earned it (account-level reward counter).
CMD:giverp(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendClientMessage(playerid, COLOR_ERROR, "You don't have permission to use this command.");

    new targetid;
    if (sscanf(params, "u", targetid) || !IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_ERROR, "Usage: /giverp [playerid/name]");

    if (targetid == playerid)
        return SendClientMessage(playerid, COLOR_ERROR, "You cannot endorse yourself.");

    if (!PlayerVar[targetid][player_islogged])
        return SendClientMessage(playerid, COLOR_ERROR, "That player is not logged in.");

    new query[256];
    mysql_format(mysql, query, sizeof(query), "SELECT endorsement_id FROM endorsements WHERE admin_account_id = %d AND target_account_id = %d LIMIT 1", Account[playerid][E_PLAYER_ACCOUNT_ID], Account[targetid][E_PLAYER_ACCOUNT_ID]);

    new extra[32];
    format(extra, sizeof(extra), "%d %d", playerid, targetid);
    mysql_tquery(mysql, query, "OnEndorseCheck", "s", extra);
    return 1;
}

forward OnEndorseCheck(extra[]);
// MySQL callback: checks whether a player can be endorsed before giving them an endorsement.
public OnEndorseCheck(extra[])
{
    new adminid, targetid;
    sscanf(extra, "ii", adminid, targetid);

    if (!IsPlayerConnected(adminid) || !IsPlayerConnected(targetid))
        return 1;

    if (!PlayerVar[targetid][player_islogged])
    {
        SendClientMessage(adminid, COLOR_ERROR, "That player has disconnected or logged out.");
        return 1;
    }

    if (cache_num_rows())
    {
        SendServerMessage(adminid, COLOR_ERROR, "Commend", "DEDEDE",
                          "You have already commended this player.");
        return 1;
    }

    new query1[256], query2[256];

	mysql_format(mysql, query1, sizeof(query1), "INSERT INTO endorsements (admin_account_id, target_account_id, endorsed_at) VALUES (%d, %d, %d)",
		Account[adminid][E_PLAYER_ACCOUNT_ID],
		Account[targetid][E_PLAYER_ACCOUNT_ID],
		gettime()
	);

	mysql_format(mysql, query2, sizeof(query2), "UPDATE accounts SET account_rppoints = account_rppoints + 1 WHERE account_id = %d",
		Account[targetid][E_PLAYER_ACCOUNT_ID]
	);

	new extra2[32];
	format(extra2, sizeof(extra2), "%d %d", adminid, targetid);

	mysql_tquery(mysql, query1, "OnEndorseGiven", "s", extra2);
	mysql_tquery(mysql, query2, "", "");
	return 1;
}

forward OnEndorseGiven(extra[]);
// MySQL callback: records the endorsement and rewards the player.
public OnEndorseGiven(extra[])
{
    new adminid, targetid;
    sscanf(extra, "ii", adminid, targetid);

    if (!IsPlayerConnected(targetid))
        return 1;

    Account[targetid][E_PLAYER_ACCOUNT_RPPOINTS]++;

    new targetName[MAX_PLAYER_NAME], adminName[MAX_PLAYER_NAME];
    GetPlayerName(targetid, targetName, sizeof(targetName));
    GetPlayerName(adminid,  adminName,  sizeof(adminName));

    new newPoints = Account[targetid][E_PLAYER_ACCOUNT_RPPOINTS];

    new gtText[128];
    format(gtText, sizeof(gtText), "~w~Roleplay Approval~n~+1 RP Point!");
    GameTextForPlayer(targetid, gtText, 4000, 16);
	PlayerPlaySound(targetid, 1085, 0.0, 0.0, 0.0);


    new str[192];
    format(str, sizeof(str),
           "{70A288}[Commend] {DEDEDE}You have been recognised for your roleplay performance on character %s", Character[targetid][E_CHARACTER_NAME]);
    SendClientMessage(targetid, -1, str);

    format(str, sizeof(str),
           "{70A288}[Commend] {DEDEDE}You commended {00a6ed}%s{DEDEDE}. They now have {00a6ed}%d RP point%s{DEDEDE}.",
           targetName, newPoints, (newPoints == 1) ? ("") : ("s"));
    SendClientMessage(adminid, -1, str);

    new broadcast[192];
    format(broadcast, sizeof(broadcast),
           "[Commend] %s commended %s. (%d total RP pts)",
           adminName, targetName, newPoints);
    SendAdminMessage(broadcast);

    return 1;
}

// /listendorsed - shows the endorsement leaderboard.
CMD:listendorsed(playerid, params[])
{
    new query[256];
    mysql_format(mysql, query, sizeof(query), "SELECT account_name, account_rppoints FROM accounts WHERE account_rppoints > 0 ORDER BY account_rppoints DESC LIMIT 20");
    mysql_tquery(mysql, query, "OnEndorsedLeaderboard", "i", playerid);
    return 1;
}

forward OnEndorsedLeaderboard(playerid);
// MySQL callback for /listendorsed: draws the leaderboard dialog.
public OnEndorsedLeaderboard(playerid)
{
    if (!IsPlayerConnected(playerid))
        return 1;

    new rows = cache_num_rows();

    if (!rows)
    {
        SendClientMessage(playerid, COLOR_ERROR, "No endorsements have been given yet.");
        return 1;
    }

    SendClientMessage(playerid, -1, " ");
    SendClientMessage(playerid, -1,
                      "{00a6ed}______________________________________________");
    SendClientMessage(playerid, -1,
                      "  {FFFFFF}RP Commend Leaderboard  {DEDEDE}(top 20)");
    SendClientMessage(playerid, -1,
                      "{00a6ed}______________________________________________");

    new colourMap[][] =
    {
        "FFD700",  // 1st  - gold
        "C0C0C0",  // 2nd  - silver
        "CD7F32",  // 3rd  - bronze
        "DEDEDE",  // 4th+
        "DEDEDE",
        "DEDEDE",
        "DEDEDE",
        "DEDEDE",
        "DEDEDE",
        "DEDEDE"
    };

    new accountName[MAX_PLAYER_NAME + 1], rpPoints, line[128], colour[8];

    for (new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "account_name", accountName, sizeof(accountName));
        cache_get_value_name_int(i, "account_rppoints", rpPoints);

        format(colour, sizeof(colour), "%s", (i < sizeof(colourMap)) ? colourMap[i] : "DEDEDE");

        format(line, sizeof(line),
               "{%s}#%02d  %-24s  %dpt%s",
               colour, i + 1,
               accountName,
               rpPoints,
               (rpPoints == 1) ? ("") : ("s"));

        SendClientMessage(playerid, -1, line);
    }

    SendClientMessage(playerid, -1, "{00a6ed}______________________________________________");
    SendClientMessage(playerid, -1, " ");

    new myPoints = Account[playerid][E_PLAYER_ACCOUNT_RPPOINTS];
    new myStr[128];
    format(myStr, sizeof(myStr),
           "{DEDEDE}Your RP points: {00a6ed}%d", myPoints);
    SendClientMessage(playerid, -1, myStr);
    SendClientMessage(playerid, -1, " ");

    return 1;
}

// /adminmessage [account id] [text] - leaves a message that is shown to a player the next time
// they log in.
CMD:adminmessage(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendClientMessage(playerid, 0xFF4444FF, "You don't have permission to use this command.");

    new accountid, message[256];

    if (sscanf(params, "dS(1)[256]", accountid, message))
        return SendClientMessage(playerid, 0xFFFFFFFF,
            "Usage: /adminmessage <accountid> <message>");

    if (!strlen(message) || strlen(message) < 2)
        return SendClientMessage(playerid, 0xFF4444FF, "Message cannot be empty.");

    new query[512];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE accounts SET admin_message = '%e' WHERE account_id = %d",
        message, accountid);
    mysql_tquery(mysql, query);

    foreach (new i : Player)
    {
        if (Account[i][E_PLAYER_ACCOUNT_ID] == accountid)
        {
            strmid(Account[i][E_PLAYER_ACCOUNT_ADMIN_MESSAGE],
                message, 0, strlen(message), 256);
            SendClientMessage(i, 0xED801AFF,
                "An admin has left you a message. Check below:");
            SendClientMessage(i, 0xFFFFFFFF, message);
            break;
        }
    }

    SendClientMessage(playerid, 0x7FB800FF,
        sprintf("Admin message set for account ID %d.", accountid));
    return true;
}

// /removemessage [account id] - deletes the pending login message for an account.
CMD:removemessage(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendClientMessage(playerid, 0xFF4444FF, "You don't have permission to use this command.");

    new accountid;

    if (sscanf(params, "d", accountid))
        return SendClientMessage(playerid, 0xFFFFFFFF,
            "Usage: /removemessage <accountid>");

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE accounts SET admin_message = '' WHERE account_id = %d",
        accountid);
    mysql_tquery(mysql, query);

    foreach (new i : Player)
    {
        if (Account[i][E_PLAYER_ACCOUNT_ID] == accountid)
        {
            Account[i][E_PLAYER_ACCOUNT_ADMIN_MESSAGE] = EOS;
            SendClientMessage(i, 0x888888FF, "Your admin message has been removed.");
            break;
        }
    }

    SendClientMessage(playerid, 0x7FB800FF,
        sprintf("Admin message removed for account ID %d.", accountid));
    return true;
}

forward OnPlayerMessagesLoaded(playerid);

// /playermessages - lists accounts that currently have a pending admin message.
CMD:playermessages(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < 1)
        return SendClientMessage(playerid, 0xFF4444FF, "You don't have permission to use this command.");

    new query[256];
    format(query, sizeof(query),
        "SELECT account_id, account_name, admin_message FROM accounts WHERE admin_message != '' AND admin_message IS NOT NULL");

    mysql_tquery(mysql, query, "OnPlayerMessagesLoaded", "d", playerid);
    SendClientMessage(playerid, 0x888888FF, "Fetching pending admin messages...");
    return true;
}

// MySQL callback for /playermessages: prints the list of pending messages.
public OnPlayerMessagesLoaded(playerid)
{
    new rows = cache_num_rows();

    SendClientMessage(playerid, -1, " ");
    SendClientMessage(playerid, 0xED801AFF,
        "Pending Admin Messages");
    SendClientMessage(playerid, -1, LOGIN_DIV);

    if (!rows)
    {
        SendClientMessage(playerid, 0x888888FF,
            "No pending admin messages.");
    }
    else
    {
        new str[512], id, username[MAX_PLAYER_NAME], message[256];

        for (new i = 0; i < rows; i++)
        {
            cache_get_value_int  (i, "account_id",    id);
            cache_get_value      (i, "account_name",      username, MAX_PLAYER_NAME);
            cache_get_value      (i, "admin_message", message,  256);

            format(str, sizeof(str),
                "{FFB400}#%d %s: {FFFFFF}%s",
                id, username, message);
            SendClientMessage(playerid, -1, str);
        }

        format(str, sizeof(str),
            "{DF5721}  %d messages total. Use {DDA680}/removemessage <accountid>{DF5721} to clear one.",
            rows);
        SendClientMessage(playerid, -1, str);
    }

    SendClientMessage(playerid, -1, LOGIN_DIV);
    SendClientMessage(playerid, -1, " ");
    return 1;
}

// /setadminmotd [1-3] [text] - sets one of the three staff-only message-of-the-day lines.
CMD:setadminmotd(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");

    new slot, text[96];

    if (sscanf(params, "is[96]", slot, text))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/setadminmotd [1, 2, 3] [text]");

    switch (slot)
    {
        case 1: format(Server[E_SERVER_ADMIN_MOTD_STRING_1], 96, "%s", text);
        case 2: format(Server[E_SERVER_ADMIN_MOTD_STRING_2], 96, "%s", text);
        case 3: format(Server[E_SERVER_ADMIN_MOTD_STRING_3], 96, "%s", text);
        default:
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Slot can't be lower than 1 or higher than 3.");
    }

    format(Server[E_SERVER_ADMIN_MOTD_EDITOR], MAX_PLAYER_NAME, "%s", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
    Server[E_SERVER_ADMIN_MOTD_EDIT_TIME] = gettime();

    new query[512];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE server SET admin_motd_1 = '%e', admin_motd_2 = '%e', admin_motd_3 = '%e', admin_motd_editor = '%e', admin_motd_edit_time = %d",
        Server[E_SERVER_ADMIN_MOTD_STRING_1], Server[E_SERVER_ADMIN_MOTD_STRING_2], Server[E_SERVER_ADMIN_MOTD_STRING_3],
        Server[E_SERVER_ADMIN_MOTD_EDITOR], Server[E_SERVER_ADMIN_MOTD_EDIT_TIME]);
    mysql_tquery(mysql, query);

    return SendServerMessage(playerid, 0xBA3F1DFF, "Admin MOTD", "DEDEDE", "Staff notice updated successfully.");
}
