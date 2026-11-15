// ============================================================================
// File: message/ooc.pwn
// Out-of-character chat: /b (local OOC), /ooc (global), /pm and /rpm, /disablepm, and blocking
// other players' PMs.
// Commands: /disablepm /b /blow /bl /carb /cb /toggleooc /ooc /o /aooc /pm /rpm /blockpm
// /blockpms /unblockpm /togglepms /listblockedpms
// ============================================================================

new bool:g_PMsDisabled = false;

// /disablepm - (lead admin) toggles private messages for the whole server.
CMD:disablepm(playerid, params[])
{
    if (Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL] < ADMIN_LVL_LEAD)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "You must be a Lead Administrator to use this command.");
    }

    new string[256];

    g_PMsDisabled = !g_PMsDisabled;

    if (g_PMsDisabled)
    {
        format(string, sizeof(string),
            "[!!!] [AdmWarn] %s has disabled private messages server-wide.",
            Account[playerid][E_PLAYER_ACCOUNT_NAME]);

        AddLogEntry(playerid, LOG_TYPE_SCRIPT, "disabled private messages server-wide");
    }
    else
    {
        format(string, sizeof(string),
            "[!!!] [AdmWarn] %s has enabled private messages server-wide.",
            Account[playerid][E_PLAYER_ACCOUNT_NAME]);

        AddLogEntry(playerid, LOG_TYPE_SCRIPT, "enabled private messages server-wide");
    }

    SendAdminMessage(string);
    return 1;
}

// Sends an out-of-character /b message to nearby players.
static SendPlayerLocalOOC(playerid, text[144], bool:islow=false, bool:insidecar = false)
{
    if ( PlayerVar [ playerid ] [ E_PLAYER_LOGOUT_TICK ] ) 
	{
    	SendClientMessage(playerid, COLOR_YELLOW, "You can't use local chat while your /logout timer is ticking." ) ;
        return 0 ;
    }

	new string[256];

	if (!insidecar)
	{
		if (islow)
		{
			if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY])  {
				format(string,sizeof(string), "{A3A3A3} [low]: %s ))", text);
				ProxDetectorEx(playerid, 10.0, 0xA3A3A3FF, sprintf("(( (%d){E8871B}", playerid), string, .autospacing=false); 
			}
			else if (PlayerVar[playerid][E_PLAYER_IS_MASKED]) {

				format(string,sizeof(string), "[low]: %s ))", text);
				ProxDetectorEx(playerid, 10.0, 0xA3A3A3FF, sprintf("(( (%d)", Character[playerid][E_CHARACTER_MASKID]), string, .autospacing=false); 
			}
			else {
				format ( string, sizeof ( string ), "[low]: %s ))", text ) ;
				ProxDetectorEx(playerid, 10.0, 0xA3A3A3FF, "((", string, .showid = true, .autospacing=false); 
			}
		}
		else
		{
			if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY])  {
				format(string,sizeof(string), "{A3A3A3}: %s ))", text);
				ProxDetectorEx(playerid, 10.0, 0xA3A3A3FF, sprintf("(( (%d){E8871B}", playerid), string, .autospacing=false); 
			}
			else if (PlayerVar[playerid][E_PLAYER_IS_MASKED]) {

				format(string,sizeof(string), ": %s ))", text);
				ProxDetectorEx(playerid, 10.0, 0xA3A3A3FF, sprintf("(( (%d)", Character[playerid][E_CHARACTER_MASKID]), string, .autospacing=false); 
			}
			else {
				format ( string, sizeof ( string ), ": %s ))", text ) ;
				ProxDetectorEx(playerid, 10.0, 0xA3A3A3FF, "((", string, .showid = true, .autospacing=false); 
			}
		}

		AddLogEntry(playerid, LOG_TYPE_OOC, sprintf("(( %s ))", text));
	}
	else
	{
		new vehicleid = GetPlayerVehicleID(playerid);
		foreach(new targetid: Player) 
		{
			if (GetPlayerVehicleID(targetid) == vehicleid)
			{
				if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY]) format ( string, sizeof ( string ), "(( [%s] (%d) %s{A3A3A3}: %s ))", ReturnVehicleName(vehicleid), playerid, ReturnSettingsName(playerid, targetid), text );
				else if (PlayerVar[playerid][E_PLAYER_IS_MASKED]) format ( string, sizeof ( string ), "(( [%s] (%d) %s: %s ))", ReturnVehicleName(vehicleid), Character[playerid][E_CHARACTER_MASKID], ReturnSettingsName(playerid, targetid), text ); 
				else format ( string, sizeof ( string ), "(( [%s] (%d) %s: %s ))", ReturnVehicleName(vehicleid), playerid, ReturnSettingsName(playerid, targetid), text ) ;

				ZMsg_SendClientMessage ( targetid, 0xA3A3A3FF, string);
			}
		}

		AddLogEntry(playerid, LOG_TYPE_OOC, sprintf("(( [CAR] %s ))", text));
	}

	return true ;
}

// /b [text] - local out-of-character chat.
CMD:b(playerid, params[]) {

	new text[144], bool:quiet = Character[playerid][E_CHARACTER_ARREST_TIME] > 0;

	if ( sscanf ( params, "s[144]", text ) ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/b [text]" ) ;
	}

	SendPlayerLocalOOC(playerid, text, quiet);
	return true;
}

// /blow [text] - quiet local out-of-character chat.
CMD:blow(playerid, params[]) {

	new text[144];

	if ( sscanf ( params, "s[144]", text ) ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/blow [text]" ) ;
	}

	SendPlayerLocalOOC(playerid, text, true);
	return true ;
}

CMD:bl(playerid, params[])
{
	return cmd_blow(playerid, params);
}

// /carb [text] - out-of-character chat to the people in your vehicle.
CMD:carb(playerid, params[]) {

	new text[144];

	if ( sscanf ( params, "s[144]", text ) ) 
	{
		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/carb [text]" ) ;
	}

	if (!IsPlayerInAnyVehicle(playerid))
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a vehicle to use this chat.");
	}

	SendPlayerLocalOOC(playerid, text, false, .insidecar = true);
	return true ;
}

CMD:cb(playerid, params[])
{
	return cmd_carb(playerid, params);
}

// /toggleooc - (admin) turns the global OOC chat on or off.
CMD:toggleooc(playerid) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_JUNIOR ) {

		return false ;
	}

	new string [ 256 ] ;

	if ( ! Server [ E_SERVER_OOC_ENABLED ] ) {

		AddLogEntry(playerid, LOG_TYPE_SCRIPT, "has enabled OOC chat");
		format ( string, sizeof ( string ), "[!!!] [AdmWarn] %s has enabled OOC chat.", Account [playerid][E_PLAYER_ACCOUNT_NAME]) ;
		Server [ E_SERVER_OOC_ENABLED ] = true ;
	}

	else if ( Server [ E_SERVER_OOC_ENABLED ] ) {

		AddLogEntry(playerid, LOG_TYPE_SCRIPT, "has disabled OOC chat");
		format ( string, sizeof ( string ), "[!!!] [AdmWarn] %s has disabled OOC chat.", Account [playerid][E_PLAYER_ACCOUNT_NAME]) ;
		Server [ E_SERVER_OOC_ENABLED ] = false ;
	}

	SendAdminMessage(string) ;

	return true ;
}

// /ooc [text] - global out-of-character chat.
CMD:ooc(playerid, params[]) {

	new text [ 144 ] ;

	if ( sscanf ( params, "s[144]", text ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/ooc [text]" ) ;
	}

	if ( ! Server [ E_SERVER_OOC_ENABLED ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "OOC is currently disabled." ) ;
	}
	
	new string [ 256 ] ;

	foreach(new targetid: Player) {

		format ( string, sizeof ( string ), "(( [GLOBAL] (%d) %s{AAC4E5}: %s ))",  playerid, ReturnSettingsName(playerid, targetid, false, false), text ) ;

		if ( ! PlayerVar [ targetid ] [ E_PLAYER_HIDING_OOC ] ) {
			ZMsg_SendClientMessage ( targetid, COLOR_OOC, string);
		}

		else continue ;
	}
	
	AddLogEntry(playerid, LOG_TYPE_OOC, text);
	SendAdminListen(playerid, string) ;
	return true ;
}

CMD:o(playerid, params[]) {

	return cmd_ooc(playerid, params);
}

// /aooc [text] - (staff) an announcement in the OOC chat.
CMD:aooc(playerid, params[]) {
	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_GENERAL ) {

		return SendServerMessage( playerid, COLOR_RED, "Warning", "A3A3A3",  "You need to be a general administrator + in order to be able to do this!" );
	}

	new text [ 144 ] ;

	if ( sscanf ( params, "s[144]", text ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/aooc [text]" ) ;
	}

	
	new string [ 256 ] ;


	foreach(new targetid: Player) {
		format ( string, sizeof ( string ), "(( [AOOC] (%d) %s: %s ))",  playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME], text ) ;
		ZMsg_SendClientMessage ( targetid, COLOR_STAFF, string);
	}

	AddLogEntry(playerid, LOG_TYPE_OOC, text);
	return true ;
}

// PMS
#include <YSI_Coding\y_hooks>
#define MAX_PM_BLOCKS 15

enum E_BLOCKED_PM
{
    E_BLOCKED_PM_ACCOUNT_ID,
    E_BLOCKED_PM_ACCOUNT_NAME[24]
}
new BlockedPMs[MAX_PLAYERS][MAX_PM_BLOCKS][E_BLOCKED_PM];

// Loads the list of accounts a player has blocked from private messaging.
LoadPlayerBlockedPMs(playerid)
{
    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT blocked_account_id, blocked_account_name FROM blocked_pms WHERE account_id = %d LIMIT %d",
        Account[playerid][E_PLAYER_ACCOUNT_ID], MAX_PM_BLOCKS);
    mysql_tquery(mysql, query, "OnLoadBlockedPMs", "d", playerid);
}

forward OnLoadBlockedPMs(playerid);
// MySQL callback: stores the blocked accounts for a player.
public OnLoadBlockedPMs(playerid)
{
    if (!IsPlayerConnected(playerid)) return 1;

    PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT] = 0;

    new rows = cache_num_rows();
    for (new i = 0; i < rows && i < MAX_PM_BLOCKS; i++)
    {
        cache_get_value_name_int(i, "blocked_account_id",   BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_ID]);
        cache_get_value_name    (i, "blocked_account_name", BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_NAME], 24);
        PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT]++;
    }
    return 1;
}

new LastPMFrom[MAX_PLAYERS] = {INVALID_PLAYER_ID, ...}; // last player who PMed each player, for /rpm

hook OnPlayerDisconnect(playerid, reason)
{
    // Clear reply targets pointing at this slot so a reused ID can't receive a stranger's /rpm.
    LastPMFrom[playerid] = INVALID_PLAYER_ID;
    foreach (new i: Player)
    {
        if (LastPMFrom[i] == playerid)
            LastPMFrom[i] = INVALID_PLAYER_ID;
    }

    PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT] = 0;
    PlayerVar[playerid][E_PLAYER_PM_BLOCKED]       = 0;
    for (new i = 0; i < MAX_PM_BLOCKS; i++)
    {
        BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_ID]      = 0;
        BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_NAME][0] = EOS;
    }
    return 1;
}

// Returns true if the player has blocked a given account.
IsAccountBlockedByPlayer(playerid, account_id)
{
    for (new i = 0; i < PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT]; i++)
    {
        if (BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_ID] == account_id)
            return 1;
    }
    return 0;
}

// Bans a player for spamming private messages.
stock PMSpamBan(playerid)
{
    new hours   = 99999;
    new secs    = hours * 3600;
    new unbants = gettime() + secs;
    new reason[64], string[300];

    format(string, sizeof(string), "[AntiCheat]: (%d) %s has been banned for PM spamming.", playerid, ReturnRPName(playerid));
    SendAdminMessage(string, COLOR_ANTICHEAT);

    format(reason, sizeof(reason), "Anticheat Detection: PM Spamming");
    SetAdminRecord(Account[playerid][E_PLAYER_ACCOUNT_ID], Character[playerid][E_CHARACTER_ID], -1337, ARECORD_TYPE_BAN, reason, -1, ReturnDateTime());

    mysql_format(mysql, string, sizeof(string),
        "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
        Account[playerid][E_PLAYER_ACCOUNT_ID], Account[playerid][E_PLAYER_ACCOUNT_NAME], ReturnIP(playerid), "Anticheat", reason, gettime(), unbants);
    mysql_tquery(mysql, string);

    format(string, sizeof(string), "banip %s", ReturnIP(playerid));
    SendRconCommand(string);

    Kick(playerid);
}
// /pm [id] [text] - sends a private message to another player.
CMD:pm(playerid, params[])
{
    new userid, text[144];

    if (g_PMsDisabled &&
    Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL] < ADMIN_LVL_GENERAL)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",
            "Private messages are currently disabled by administration.");
    }

    if (sscanf(params, "k<unmaskedplayer>s[144]", userid, text))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/pm [id] [text]");

    if (!IsPlayerConnected(userid) || !IsPlayerLogged(userid) || !IsPlayerPlaying(userid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Player isn't connected.");

    if (!IsPlayerPlaying(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must spawn as a character first.");

    if (userid == playerid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't PM yourself.");

    if (IsPlayerPaused(userid))
        SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "The player you are messaging is AFK. Use /afklist.");

    if (PlayerVar[userid][E_PLAYER_PM_BLOCKED])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "The person you are trying to message is blocking their private messages.");

    if (IsAccountBlockedByPlayer(userid, Account[playerid][E_PLAYER_ACCOUNT_ID]))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "The person you are trying to message has blocked you.");

    if (PlayerVar[playerid][E_PLAYER_LAST_PM_SENT_AT])
    {
        if (gettime() == PlayerVar[playerid][E_PLAYER_LAST_PM_SENT_AT])
        {
            if (!CanPlayerUseGuns(playerid, 4))
            {
                SendAdminMessage(sprintf("[AdmWarn] (%d) %s might be PM spamming: %s", playerid, ReturnRPName(playerid), text), COLOR_ANTICHEAT);
                PlayerVar[playerid][E_PLAYER_PM_SPAM_COUNT]++;

                if (PlayerVar[playerid][E_PLAYER_PM_SPAM_COUNT] >= 3)
                    PMSpamBan(playerid);
            }

            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Stop spamming and wait before sending another PM.");
        }
    }

    PlayerVar[playerid][E_PLAYER_PM_SPAM_COUNT]   = 0;
    PlayerVar[playerid][E_PLAYER_LAST_PM_SENT_AT] = gettime();

    new string[384];

    if (Account[userid][E_PLAYER_ACCOUNT_STAFFLEVEL] > ADMIN_LVL_NONE && !PlayerVar[playerid][E_PLAYER_PM_MOD_WARNING] && !Account[userid][E_PLAYER_ACCOUNT_CONTRIBUTOR])
    {
        inline PMingAdminResponse(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused pid, dialogid, listitem, inputtext

            if (response)
            {
                GameTextForPlayer(userid, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~y~New message!", 3000, 3);
                PlayerPlaySound(userid, 1085, 0.0, 0.0, 0.0);

                if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY])
                    format(string, sizeof(string), "(( PM from {E9971B}%s (%d):{FFCC22} %s ))", ReturnRPName(playerid), playerid, text);
                else if (PlayerVar[playerid][E_PLAYER_HELPER_DUTY])
                    format(string, sizeof(string), "(( PM from {38C751}%s (%d):{FFCC22} %s ))", ReturnRPName(playerid), playerid, text);
                else
                    format(string, sizeof(string), "(( PM from %s (%d):{FFFF22} %s ))", ReturnSettingsName(playerid, userid), playerid, text);
                ZMsg_SendClientMessage(userid, 0xFFCC2299, string);

                if (PlayerVar[userid][E_PLAYER_ADMIN_DUTY])
                    format(string, sizeof(string), "(( PM to {E9971B}%s (%d):{FFFF22} %s ))", ReturnRPName(userid), userid, text);
                else if (PlayerVar[userid][E_PLAYER_HELPER_DUTY])
                    format(string, sizeof(string), "(( PM to {38C751}%s (%d):{FFFF22} %s ))", ReturnRPName(userid), userid, text);
                else
                    format(string, sizeof(string), "(( PM to %s (%d):{FFFF22} %s ))", ReturnSettingsName(userid, playerid), userid, text);
                ZMsg_SendClientMessage(playerid, 0xFFFF22AA, string);

                LastPMFrom[userid] = playerid;
                AddLogEntry(playerid, LOG_TYPE_PM, string);
            }
        }

        format(string, sizeof(string),
            "{D63C3C}WARNING:{DEDEDE} You're sending a private message to an administrator.\n\n\
            Please make sure your query isn't related to their tasks, since there is /report for that.\n\n\
            If this administrator is helping you or you have something else to talk about, go ahead.\n\n\
            Thanks for understanding.");

        Dialog_ShowCallback(playerid, using inline PMingAdminResponse, DIALOG_STYLE_MSGBOX, "{D63C3C}PRIVATE MESSAGE WARNING:{DEDEDE}", string, "Proceed", "Cancel");
        PlayerVar[playerid][E_PLAYER_PM_MOD_WARNING] = true;
        return true;
    }

    GameTextForPlayer(userid, "~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~y~New message!", 3000, 3);
    PlayerPlaySound(userid, 1085, 0.0, 0.0, 0.0);

    if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY])
        format(string, sizeof(string), "(( PM from {E9971B}%s (%d):{FFCC22} %s ))", Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid, text);
    else
        format(string, sizeof(string), "(( PM from %s (%d): %s ))", ReturnSettingsName(playerid, userid), playerid, text);
    ZMsg_SendClientMessage(userid, 0xFFCC2299, string);

    if (PlayerVar[userid][E_PLAYER_ADMIN_DUTY])
        format(string, sizeof(string), "(( PM to {E9971B}%s (%d):{FFFF22} %s ))", Account[userid][E_PLAYER_ACCOUNT_NAME], userid, text);
    else
        format(string, sizeof(string), "(( PM to %s (%d): %s ))", ReturnSettingsName(userid, playerid), userid, text);
    ZMsg_SendClientMessage(playerid, 0xFFFF22AA, string);

    LastPMFrom[userid] = playerid;
    AddLogEntry(playerid, LOG_TYPE_PM, string);

    format(string, sizeof(string), "[PM] %s sends to %s: %s", ReturnRPName(playerid), ReturnRPName(userid), text);
    SendAdminListen(playerid, string);

    return 1;
}

// /rpm [text] - replies to the last private message you received.
CMD:rpm(playerid, params[])
{
    if (isnull(params))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/rpm [text] - replies to the last private message you received.");

    new target = LastPMFrom[playerid];

    if (target == INVALID_PLAYER_ID || !IsPlayerConnected(target))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You have no one to reply to.");

    return cmd_pm(playerid, sprintf("%d %s", target, params));
}

// /blockpm [id] - blocks a player's private messages.
CMD:blockpm(playerid, params[])
{
    new userid;
    if (sscanf(params, "k<unmaskedplayer>", userid))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/blockpm [id]");

    if (!IsPlayerConnected(userid) || !IsPlayerLogged(userid) || !IsPlayerPlaying(userid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Player isn't connected.");

    if (userid == playerid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't block yourself.");

    if (!GetPlayerAdminLevel(playerid) && GetPlayerAdminLevel(userid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You cannot block an administrator.");

    new target_account_id = Account[userid][E_PLAYER_ACCOUNT_ID];
    new target_account_name[24];
    format(target_account_name, sizeof(target_account_name), "%s", Account[userid][E_PLAYER_ACCOUNT_NAME]);

    if (IsAccountBlockedByPlayer(playerid, target_account_id))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You have already blocked that player.");

    if (PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT] >= MAX_PM_BLOCKS)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only block up to 15 accounts.");

    new slot = PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT];
    BlockedPMs[playerid][slot][E_BLOCKED_PM_ACCOUNT_ID] = target_account_id;
    format(BlockedPMs[playerid][slot][E_BLOCKED_PM_ACCOUNT_NAME], 24, "%s", target_account_name);
    PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT]++;

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "INSERT IGNORE INTO blocked_pms (account_id, blocked_account_id, blocked_account_name) VALUES (%d, %d, '%e')",
        Account[playerid][E_PLAYER_ACCOUNT_ID], target_account_id, target_account_name);
    mysql_tquery(mysql, query);

    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("blocked PMs from account %s (%d)", target_account_name, target_account_id));

    new msg[64];
    format(msg, sizeof(msg), "You have blocked PMs from %s.", target_account_name);
    return SendServerMessage(playerid, COLOR_ERROR, "Info", "A3A3A3", msg);
}

CMD:blockpms(playerid, params[]) { return cmd_blockpm(playerid, params); }

// /unblockpm [account] - unblocks a player.
CMD:unblockpm(playerid, params[])
{
    new name[24];
    if (sscanf(params, "s[24]", name))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/unblockpm [account name]");

    new found = -1;
    for (new i = 0; i < PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT]; i++)
    {
        if (!strcmp(BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_NAME], name, true))
        {
            found = i;
            break;
        }
    }

    if (found == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That account isn't in your block list. Use /listblockedpms to see your list.");

    new target_account_id = BlockedPMs[playerid][found][E_BLOCKED_PM_ACCOUNT_ID];
    new count = PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT];

    for (new i = found; i < count - 1; i++)
    {
        BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_ID] = BlockedPMs[playerid][i + 1][E_BLOCKED_PM_ACCOUNT_ID];
        format(BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_NAME], 24, "%s", BlockedPMs[playerid][i + 1][E_BLOCKED_PM_ACCOUNT_NAME]);
    }
    BlockedPMs[playerid][count - 1][E_BLOCKED_PM_ACCOUNT_ID]      = 0;
    BlockedPMs[playerid][count - 1][E_BLOCKED_PM_ACCOUNT_NAME][0] = EOS;
    PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT]--;

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "DELETE FROM blocked_pms WHERE account_id = %d AND blocked_account_id = %d",
        Account[playerid][E_PLAYER_ACCOUNT_ID], target_account_id);
    mysql_tquery(mysql, query);

    AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("unblocked PMs from account %s (%d)", name, target_account_id));

    new msg[64];
    format(msg, sizeof(msg), "You have unblocked PMs from %s.", name);
    return SendServerMessage(playerid, COLOR_ERROR, "Info", "A3A3A3", msg);
}

// /togglepms - turns all private messages on or off for yourself.
CMD:togglepms(playerid, params[])
{
    if (!PlayerVar[playerid][E_PLAYER_PM_BLOCKED])
    {
        PlayerVar[playerid][E_PLAYER_PM_BLOCKED] = true;
        AddLogEntry(playerid, LOG_TYPE_SCRIPT, "disabled all PMs");
        return SendServerMessage(playerid, COLOR_ERROR, "Info", "A3A3A3", "You are now blocking ALL private messages.");
    }

    PlayerVar[playerid][E_PLAYER_PM_BLOCKED] = false;
    AddLogEntry(playerid, LOG_TYPE_SCRIPT, "enabled all PMs");
    return SendServerMessage(playerid, COLOR_ERROR, "Info", "A3A3A3", "You have unblocked ALL private messages.");
}

// /listblockedpms - lists the accounts you have blocked.
CMD:listblockedpms(playerid, params[])
{
    if (!PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT])
        return SendServerMessage(playerid, COLOR_ERROR, "Info", "A3A3A3", "You have no blocked accounts.");

    new string[512], line[48];
    format(string, sizeof(string), "Blocked accounts (%d/%d):\n", PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT], MAX_PM_BLOCKS);

    for (new i = 0; i < PlayerVar[playerid][E_PLAYER_BLOCKED_PM_COUNT]; i++)
    {
        format(line, sizeof(line), "%d. %s\n", i + 1, BlockedPMs[playerid][i][E_BLOCKED_PM_ACCOUNT_NAME]);
        strcat(string, line, sizeof(string));
    }

    Dialog_Show(playerid, DIALOG_STYLE_MSGBOX, "Blocked PMs", string, "Close", "");
    return 1;
}
