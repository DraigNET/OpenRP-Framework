// ============================================================================
// File: admin/data.pwn
// Core admin data. Defines the admin ranks (ADMIN_LVL_*), their names/colours, the staff chat
// (/a), admin duty (/aduty), /makeadmin and the SendAdminMessage() family used across the
// script to notify staff.
// Commands: /a /achat /aduty /adminduty /man /togman /makeadmin /adminhex /helperhex /x
// /deletechar
// ============================================================================

#if defined _inc_data
	#undef _inc_data
#endif
enum { // admin ranks
	ADMIN_LVL_NONE,
	ADMIN_LVL_BETA = 1,
	ADMIN_LVL_JUNIOR,
	ADMIN_LVL_GENERAL,
	ADMIN_LVL_SENIOR,
	ADMIN_LVL_LEAD,
	ADMIN_LVL_HEAD,
	ADMIN_LVL_MANAGER,
	ADMIN_LVL_DEVELOPER
} ;

// Writes the display name of an admin rank (Junior Admin, etc.) into rank_name.
GetAdminRankName(rank, rank_name[], len = sizeof ( rank_name ) ) {

	rank_name [ 0 ] = EOS ;

	switch ( rank ) {

		case ADMIN_LVL_BETA:		strcat ( rank_name, "Beta Tester", len ) ;
		case ADMIN_LVL_JUNIOR:		strcat ( rank_name, "Junior Admin", len ) ;
		case ADMIN_LVL_GENERAL:		strcat ( rank_name, "General Admin", len ) ;
		case ADMIN_LVL_SENIOR:		strcat ( rank_name, "Senior Admin", len ) ;
		case ADMIN_LVL_LEAD:		strcat ( rank_name, "Lead Admin", len ) ;
		case ADMIN_LVL_HEAD:		strcat ( rank_name, "Head Admin", len ) ;
		case ADMIN_LVL_MANAGER:		strcat ( rank_name, "Manager", len ) ;
		case ADMIN_LVL_DEVELOPER:		strcat ( rank_name, "Developer", len ) ;
		default: strcat ( rank_name, "Regular", len ) ;
	}
}

// Writes the chat colour tag of an admin rank into rank_color.
GetAdminRankColor(rank, rank_color[], len = sizeof ( rank_color ) ) {

	rank_color [ 0 ] = EOS ;

	switch ( rank ) {

		case ADMIN_LVL_BETA:		strcat ( rank_color, "{dbd221}", len ) ;
		case ADMIN_LVL_JUNIOR:		strcat ( rank_color, "{ffc069}", len ) ;
		case ADMIN_LVL_GENERAL:		strcat ( rank_color, "{f4a442}", len ) ;
		case ADMIN_LVL_SENIOR:		strcat ( rank_color, "{f58840}", len ) ;
		case ADMIN_LVL_LEAD:		strcat ( rank_color, "{d47d44}", len ) ;
		case ADMIN_LVL_HEAD:		strcat ( rank_color, "{ce7032}", len ) ;
		case ADMIN_LVL_MANAGER:		strcat ( rank_color, "{5B2C79}", len ) ;
		case ADMIN_LVL_DEVELOPER:		strcat ( rank_color, "{63159e}", len ) ;
		default: strcat ( rank_color, "{FFFFFF}", len ) ;
	}
}

#define RGBA_DARKER(%0) (((%0 & 0x7E7E7E00) >> 1) | (%0 & 0x80808000))

// Returns true for developer-level staff.
stock IsDeveloper(playerid)
{
    return (GetPlayerAdminLevel(playerid) >= 7);
}

// chat - defines if the message being sent is from a staff chat, so that it can be toggled 
// if the player has toggled off staff chats.
stock SendAdminMessage(const text[], color = -1, bool:log=true, bool: chat = false) {

	#pragma unused log
	if ( color == -1 ) {

		color = RGBA_DARKER(Server [ E_SERVER_ADMIN_HEX ]) ;
	}

	foreach(new playerid: Player) {

		if ( Character [ playerid ] [ E_CHARACTER_ID ] == -1 ) {

			continue ;
		}

		if ( ! IsPlayerLogged ( playerid ) ) {

			continue ;
		}

		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] <= 0 && !Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ]) {
			continue ;
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] && !chat) {
			continue ;
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DESYNC_TOGGLED ] && !chat) {
			continue ;
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] && !chat) {
			continue ;
		}

		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] > ADMIN_LVL_NONE || Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ]) {

			ZMsg_SendClientMessage(playerid, color, text);
		}

		else continue ;
	}

	if (log) DCC_SendAdminLogMessage(text);
}

// Sends a message to developers only (and optionally to staff chat).
SendDevMessage(const text[], color = -1, bool:log=true, force = false, bool: chat = false) {
	#pragma unused log
	if ( color == -1 ) {

		color = RGBA_DARKER(Server [ E_SERVER_ADMIN_HEX ]) ;
	}

	foreach(new playerid: Player) {

		if ( Character [ playerid ] [ E_CHARACTER_ID ] == -1 ) {

			continue ;
		}

		if ( ! IsPlayerLogged ( playerid ) ) {

			continue ;
		}

		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] <= 0 && !Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ]) {
			continue ;
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] && !force) {
			continue ;
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] && chat) {
			continue ;
		}

		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] > ADMIN_LVL_LEAD) {

			ZMsg_SendClientMessage(playerid, color, text);
		}

		else continue ;
	}

	if (log) DCC_SendAdminLogMessage(text);
}

// Sends an anti-cheat warning to every staff member who has anti-cheat messages enabled. This is
// what SendAntiCheatMessage in the rest of the script calls.
stock SendAntiCheatMessage(const text[], color = -1, bool:log=true, force = false, bool: chat = false) {
	#pragma unused log
	if ( color == -1 ) {

		color = RGBA_DARKER(Server [ E_SERVER_ADMIN_HEX ]) ;
	}

	foreach(new playerid: Player) {

		if ( Character [ playerid ] [ E_CHARACTER_ID ] == -1 ) {

			continue ;
		}

		if ( ! IsPlayerLogged ( playerid ) ) {

			continue ;
		}

		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] <= 0 && !Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ]) {
			continue ;
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] && !force) {
			continue ;
		}

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] && chat) {
			continue ;
		}

		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] > ADMIN_LVL_NONE || Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ]) {

			ZMsg_SendClientMessage(playerid, color, text);
		}

		else continue ;
	}

	if (log) DCC_SendAntiCheatMessage(text);
}

// Sends a message to the manager chat in the manager colour.
SendManagerChat(const text[])
{
	return SendManagerMessage(text, true, 0xe37474FF);
}

// Sends a message to every manager online (nohide forces it even if they toggled warnings off).
SendManagerMessage(const text[], bool:nohide = false, color = 0x235F94FF) {

	foreach(new playerid: Player) {
		if ( Character [ playerid ] [ E_CHARACTER_ID ] == -1 ) {

			continue ;
		}

		if ( ! IsPlayerLogged ( playerid ) ) {

			continue ;
		}

		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] <= 0 ) {
			continue ;
		}
		
		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] >= ADMIN_LVL_LEAD && nohide) 
		{
			ZMsg_SendClientMessage(playerid, color, text);
		}

		else continue ;
	}

	return 1;
}

GetPlayerAdminLevel ( playerid ) {

	if ( IsPlayerAdmin ( playerid ) ) {

		return ADMIN_LVL_DEVELOPER ;
	}

	return Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] ; 
}
stock IsPlayerManager ( playerid ) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] >= ADMIN_LVL_HEAD || Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] >= ADMIN_LVL_LEAD ) {

		return true ;
	}

	else return false ;
}

// /a (staff chat) [text] - talk to every staff member and contributor online.
CMD:a(playerid, params[]) {
	if ( ! Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ] ) {
		if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] <= ADMIN_LVL_NONE ) {

			return false ;
		}
	}

	new text [ 144 ] ;

	if ( sscanf ( params, "s[144]", text ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/a(chat) [text]" ) ;
		return true ;
	}
	

	new string [ 256 ], rank_name [ 32 char ] ;

	if ( ! Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ] ) {
		GetAdminRankName ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ], rank_name, 32 ) ;
	}

	else {
		GetContributorRankName ( Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ], rank_name, 32 );
	}

	format ( string, sizeof ( string ), "{[ [ADMIN CHAT] (%d) %s %s: %s ]}", playerid, rank_name, Account[playerid][E_PLAYER_ACCOUNT_NAME], text ) ;
	SendAdminMessage(string, Server [ E_SERVER_ADMIN_HEX ], .log=false, .chat=true);

	AddLogEntry(playerid, LOG_TYPE_STAFFCHAT, text);
	return true ;
}
CMD:achat(playerid, params[]) {

	return cmd_a(playerid, params);
}

forward ORP_OnAdmDutyChange(playerid);
public ORP_OnAdmDutyChange(playerid)
{
	// Hook this
	// printf("ORP_OnAdmDutyChange: %d", playerid);
	return 1;
}

// /aduty - alias of /adminduty.
CMD:aduty(playerid, params[]) {

	return cmd_adminduty(playerid, params);
}

// /adminduty - toggles admin duty (changes name colour, enables staff powers, applies the on-duty
// rules).
CMD:adminduty(playerid, params[]) {
	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] <= ADMIN_LVL_NONE ) {

		return false ;
	}

	if ( ! PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ] ) {
		PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ] = true ;
		TextDrawShowForPlayer(playerid, E_ADMIN_DUTY_TEXT );


		UpdateTabListForOthers ( playerid ) ;
		AddLogEntry(playerid, LOG_TYPE_ADMIN, "Went on admin duty");
	}

	else if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ] ) {
		PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DUTY ] = false ;
		TextDrawHideForPlayer(playerid, E_ADMIN_DUTY_TEXT );

		UpdateTabListForOthers ( playerid ) ;
		AddLogEntry(playerid, LOG_TYPE_ADMIN, "Turned off admin duty");
	}

	CallLocalFunction("ORP_OnAdmDutyChange", "d", playerid);

	return true ;
}


// /man [text] - (lead admin+) manager chat.
CMD:man(playerid, params[]) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_LEAD ) {

		return false ;
	}

	new text [ 144 ] ;

	if ( sscanf ( params, "s[144]", text ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/man [text]" ) ;
		return true ;
	}

	
	new string [ 256 ], rank_name [ 32 char ] ;

	GetAdminRankName ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ], rank_name, 32 ) ;

	format ( string, sizeof ( string ), "{[ [MANAGER CHAT] (%d) %s %s: %s ]}", playerid, rank_name, Account[playerid][E_PLAYER_ACCOUNT_NAME], text ) ;
	SendManagerChat(string) ;

	
	AddLogEntry(playerid, LOG_TYPE_STAFFCHAT, text);

	return true ;
}

// /togman - toggles manager warnings.
CMD:togman(playerid) {

	if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_HEAD )
		return SendClientMessage ( playerid, COLOR_ERROR, "Only managers can use this command." ) ;

	if ( PlayerVar [ playerid ] [ E_PLAYER_MANAGER_WARNS_TOGGLED ] ) 
	{
		PlayerVar [ playerid ] [ E_PLAYER_MANAGER_WARNS_TOGGLED ] = false ;
		SendClientMessage ( playerid, COLOR_BLUE, "You've re-enabled manager warnings for you.");
	}
	else 
	{
		PlayerVar [ playerid ] [ E_PLAYER_MANAGER_WARNS_TOGGLED ] = true ;
		SendClientMessage ( playerid, COLOR_BLUE, "You've temporarily disabled manager warnings for you.");
	}

	return true ;
}


// /makeadmin [player] [level] - (head admin+) sets a player's staff level and saves it.
CMD:makeadmin(playerid, params[]) {


	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_HEAD ) {

		return false ;
	}

	new user, adminlvl, string [ 256 ] ;

	if ( sscanf ( params, "k<player>i", user, adminlvl ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/makeadmin [player] [level]" ) ;
		return true ;
	}

	if ( ! IsPlayerConnected(user)) {
		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Target isn't connected." ) ;
		return true ;	
	}

	if ( ! IsPlayerAdmin(playerid) ) {
		new own_level = GetPlayerAdminLevel ( playerid ) ;

		if ( adminlvl < ADMIN_LVL_NONE || adminlvl > own_level ) {

			format ( string, sizeof ( string ), "Level can't be less than 0 or higher than your own (%d).", own_level ) ;
			SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", string );
			return true ;
		}

		// Can't change the level of someone who outranks you (this also stops self-promotion via a loophole).
		if ( Account [ user ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] > own_level ) {

			SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't change the level of someone who outranks you." ) ;
			return true ;
		}
	}
	
	new rank_name [ 32 ] ;

	Account [ user ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] = adminlvl ;

	GetAdminRankName ( Account [ user ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ], rank_name, 32 ) ;

	format ( string, sizeof ( string ), "{[ %s (%d) has promoted %s (%d) to %s. ]}",  Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid,
		Account[user][E_PLAYER_ACCOUNT_NAME], user, rank_name ) ;
	SendAdminMessage(string) ;

	format(string, sizeof(string), "Made %s a %s", Account[user][E_PLAYER_ACCOUNT_NAME], rank_name);
	AddLogEntry(playerid, LOG_TYPE_ADMIN, string);

	mysql_format(mysql, string, sizeof(string), "UPDATE accounts SET account_stafflevel = %d WHERE account_id = %d", 
		Account [ user ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ], Account [ user ] [ E_PLAYER_ACCOUNT_ID ] ) ;

	mysql_tquery(mysql, string);

	return true ;
}

// /adminhex [hex] - (head admin+) sets the staff chat colour.
CMD:adminhex(playerid, params[]) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_HEAD ) {

		return false ;
	}

	new input ;

	if ( sscanf  (params, "h", input ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/adminhex [hex] (Default: 0xde6e1fFF)" ) ;
		return true ;
	}

	Server [ E_SERVER_ADMIN_HEX ] = input ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE server SET server_admin_hex = %d", Server [ E_SERVER_ADMIN_HEX ] ) ;
	mysql_tquery(mysql, query);

	SendClientMessage(playerid, Server [ E_SERVER_ADMIN_HEX ], "Admin chat colour changed! " ) ;

	return true ;
}


// /helperhex [hex] - (head admin+) sets the helper chat colour.
CMD:helperhex(playerid, params[]) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_HEAD ) {

		return false ;
	}

	new input ;

	if ( sscanf  (params, "h", input ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/helperhex [hex] (Default: 0xAEC77DFF)" ) ;
		return true ;
	}

	Server [ E_SERVER_HELPER_HEX ] = input ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE server SET server_helper_hex = %d", Server [ E_SERVER_HELPER_HEX ] ) ;
	mysql_tquery(mysql, query);

	SendClientMessage(playerid, Server [ E_SERVER_HELPER_HEX ], "Helper chat colour changed! " ) ;

	return true ;
}

// Returns whether this player may use the private /x chat (a developer-only channel hard-coded to
// account id 1).
static IsXChatter(playerid)
{
	if (!IsPlayerPlaying(playerid)) return 0;

	if (Account[playerid][E_PLAYER_ACCOUNT_ID] == 1) return 1; // Torque

	return 0;
}

// /x [text] - private chat for the account allowed by IsXChatter.
CMD:x(playerid, params[])
{
	new xchatter = IsXChatter(playerid);
	if (!xchatter) return false;

	new text[128], str[144];

	if (sscanf(params, "s[128]", text))
	{
		SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/x [text]");
		return true;
	}

	format(str, sizeof(str), "{[ [x] (%d) %s: %s ]}", playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME], text);

	foreach (new i: Player) 
	{
		if (IsXChatter(i))
		{
			ZMsg_SendClientMessage(i, 0xe374daFF, str);
		}
	}

	return true;
}

static DeleteCharDlgStr[1024];

// /deletechar [firstname_lastname] - (manager) permanently deletes a character and its data from
// the database.
CMD:deletechar(playerid, params[])
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_HEAD)
	{
		return SendClientMessage ( playerid, COLOR_ERROR, "Only managers can use this command." ) ;
	}

	new name[24];
	if (sscanf(params, "s[24]", name))
	{
		SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/deletechar [firstname_lastname]");
		return true;
	}

	if ( strlen ( name ) > MAX_PLAYER_NAME ) 
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Names can't be longer than 24 characters.");
	}

	new query [ 256 ] ;

	inline ReturnCharToDelete() 
	{
		new returned_char_id, returned_name[32], returned_account[32], level;
		if (!cache_num_rows()) 
		{
			return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  sprintf("Couldn't find a character with the name: \"%s\".", name) )  ;
		}

		cache_get_value_name_int(0, "player_id", returned_char_id);
		cache_get_value_name_int(0, "player_level", level);
		cache_get_value_name(0, "player_name", returned_name);
		cache_get_value_name(0, "account_name", returned_account);

		mysql_format(mysql, query, sizeof ( query ), "DELETE FROM `characters` WHERE `player_id` = %d", returned_char_id);

		inline DeleteCharDlg(pid, dialogid, response, listitem, string:inputtext[]) 
		{
        	#pragma unused pid, dialogid, inputtext, listitem
			if (response)
			{
				if (strcmp(inputtext, returned_name))
				{
					return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "You didn't type the character's name properly to validate." ) ;
				}

				//mysql_format(mysql, query, sizeof ( query ), "DELETE FROM `characters` WHERE `player_id` = %d", returned_char_id);
				mysql_tquery(mysql, query);

				// NEW LOGGING: Log this as a LOG_TYPE_SCRIPT for sender (playerid)
				AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Deleted Char %s (ID: %d, Account: %s)", returned_name, returned_char_id, returned_account));
				SendAdminMessage(sprintf("[!!!] [AdmWarn] (%d) %s has deleted character %s (ID %d, Account: %s).", playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME], returned_name, returned_char_id, returned_account));
			}
		}

		format(DeleteCharDlgStr, sizeof(DeleteCharDlgStr), "{FFFFFF}You are about to {AA3333}delete{FFFFFF} the character {5DB6E5}%s{FFFFFF}.", returned_name);
		strcat(DeleteCharDlgStr, sprintf("\n{ADBEE6}Character Account: {FFFFFF}%s{ADBEE6}, Level: {FFFFFF}%d, SQLID: {FFFFFF}%d", returned_account, level, returned_char_id));

		strcat(DeleteCharDlgStr, "\n\nNotes:{ADBEE6}");
		strcat(DeleteCharDlgStr, "\n- This causes the irreversible loss of the character forever.");
		strcat(DeleteCharDlgStr, "\n- Any properties or vehicles, etc. owned by the character will remain.");
		strcat(DeleteCharDlgStr, "\n- If you do this while the character is on the server, you will fuck shit up.\n\n");
		
		strcat(DeleteCharDlgStr, sprintf("{FFFFFF}Type the character's name \"%s\" and press {AA3333}Delete{FFFFFF} to confirm.", returned_name));
		strcat(DeleteCharDlgStr, "\n{ADBEE6}Only do this if there is a good reason to delete the character and it will never be needed again!");

		// strcat(DeleteCharDlgStr, sprintf("\n\n{FF0000}%s", query));

		Dialog_ShowCallback ( playerid, using inline DeleteCharDlg, DIALOG_STYLE_INPUT, sprintf("{FF0000}Confirm Delete %s", returned_name), DeleteCharDlgStr, "Delete", "Back" );
    }

	mysql_format ( mysql, query, sizeof ( query ), "SELECT `player_id`, `player_name`, `player_level`, `account_name` FROM `characters` JOIN `accounts` ON `characters`.`account_id` = `accounts`.`account_id` WHERE `player_name` LIKE '%e'", name ) ;
	MySQL_TQueryInline(mysql, using inline ReturnCharToDelete, query, "");	

	return true;
}
