// ============================================================================
// File: admin/bans.pwn
// Banning system: /kick, /ban, /silentban, /offlineban, /unban, /banip, /unbanip and /banlist.
// Bans are saved in the database and checked when a player connects.
// Commands: /kick /offlineban /ban /silentban /unban /banip /unbanip /banlist
// ============================================================================

// /kick [player] [reason] - removes a player from the server and records it in their admin record.
CMD:kick(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR && Account [ playerid ] [ E_PLAYER_ACCOUNT_SUPPORTER ] < 3 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new target, reason [ 64 ] ;

	if ( sscanf ( params, "k<player>s[64]", target, reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/kick [target] [reason]") ;
	}


	if ( strlen ( reason ) > sizeof ( reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Reason can't be longer than 64 characters.") ;
	}

	if ( ! IsPlayerConnected ( target ) ) {

		return SendServerMessage ( playerid, COLOR_RED, "Error", "A3A3A3", "Selected player doesn't exist, they might be offline.");
	}

	SetAdminRecord ( Account [ target ] [ E_PLAYER_ACCOUNT_ID ], Character [ target ] [ E_CHARACTER_ID ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], ARECORD_TYPE_KICK, reason, 0, ReturnDateTime () ) ;

	new query [ 256 ] ;

	format ( query, sizeof ( query ), "[AdmCmd]: %s was kicked by %s. Reason: %s", ReturnRPName(target), Account[playerid][E_PLAYER_ACCOUNT_NAME], reason );
	ZMsg_SendClientMessageToAll(COLOR_RED, query);
	DCC_SendAdminPunishmentMessage(query);

	AddLogEntry(target, LOG_TYPE_ADMIN, sprintf("Was kicked by %s, reason: %s", GetPlayerNameEx(playerid), reason));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Kicked %s, reason: %s", ReturnRPName(target), reason));

	KickPlayer(target);
	return true ;
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////


// /offlineban [account] [hours, 0 = permanent] [reason] - bans an account that is not currently
// online.
CMD:offlineban(playerid, params[]) {
	// master-acc
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new master_acc[MAX_PLAYER_NAME], hours, reason [ 64 ], query [ 256 ] ;

	if ( sscanf ( params, "s[24]is[64]", master_acc, hours, reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/offlineban [account name] [hours (0=perm)] [reason]") ;
	}

	if ( strlen ( master_acc ) < 0 || strlen ( master_acc ) > MAX_PLAYER_NAME ) {

		format ( query, sizeof ( query ), "Master account name can't be shorter than 0 or longer than %d.", MAX_PLAYER_NAME ) ;
		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3", query ) ;
	}

	if ( hours > 720 ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "You can't temp ban someone for longer than 720 hours (4 weeks). For perm bans use 0.") ;
	}

	if ( strlen ( reason ) > sizeof ( reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Reason can't be longer than 64 characters.") ;
	}

	if(hours == 0) {
		hours = 99999;
	}

	query[0]=EOS;

	inline ReturnAccountName() {
		if (!cache_num_rows()) {
			return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Database didn't return any account data. Maybe your mistyped the name" )  ;
		}

		else {

		   	new secs = hours * 3600, unbants, acc_id, char_id ;
		    unbants = gettime() + secs;

			cache_get_value_name_int(0, "player_id", char_id);
		 	cache_get_value_name_int(0, "account_id", acc_id);

			new ip_address[32];
			cache_get_value_name ( 0, "account_lastip", ip_address);

			SendRconCommand(sprintf("banip %s", ip_address));

			SetAdminRecord ( acc_id, char_id, Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], ARECORD_TYPE_BAN, reason, hours, ReturnDateTime () ) ;

			mysql_escape_string(reason, reason, 64);

		    mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', %d, %d)",
			acc_id, master_acc, Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], reason, gettime(), unbants);

			mysql_tquery(mysql, query);

			if (hours == 99999)
			{
				format ( query, sizeof ( query ), "[AdmCmd]: %s was offline-banned by %s. Reason: %s.", master_acc, Account[playerid][E_PLAYER_ACCOUNT_NAME], reason );
			}
			else
			{
				format ( query, sizeof ( query ), "[AdmCmd]: %s was offline-banned for %d hours by %s. Reason: %s.", master_acc, hours, Account[playerid][E_PLAYER_ACCOUNT_NAME], reason );
			}
			
			ZMsg_SendClientMessageToAll(COLOR_RED, query);
			DCC_SendAdminPunishmentMessage(query);

			AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Offline banned %s, reason: %s", master_acc, reason));
		}
	}

	mysql_format ( mysql, query, sizeof ( query ), "SELECT account_id, account_lastip FROM accounts WHERE account_name = '%e'", master_acc ) ;
	MySQL_TQueryInline(mysql, using inline ReturnAccountName, query, "");


	return true ;
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

// /ban [player] [hours, 0 = permanent] [reason] - bans the player's account and announces it.
CMD:ban(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new target, hours, reason [ 64 ] ;

	if ( sscanf ( params, "k<player>is[64]", target, hours, reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/ban [target] [hours (0=perm)] [reason]") ;
	}

	if ( hours > 720 ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "You can't temp ban someone for longer than 720 hours (4 weeks). For perm bans use 0.") ;
	}

	if ( strlen ( reason ) > sizeof ( reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Reason can't be longer than 64 characters.") ;
	}

	if ( ! IsPlayerConnected ( target ) ) {

		return SendServerMessage ( playerid, COLOR_RED, "Error", "A3A3A3", "Selected player doesn't exist, they might be offline.");
	}

	if ( GetPlayerAdminLevel ( target ) >= GetPlayerAdminLevel ( playerid ) ) 
	{
		new str[144] ;
		format ( str, sizeof ( str ), "[!!!] [AdmWarn] (%d) %s attempted to ban (%d) %s.", playerid,  Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], target,  Account [ target ] [ E_PLAYER_ACCOUNT_NAME ] ) ;
		SendAdminMessage(str) ;

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You can't ban admins of equal or higher rank.") ;
	}

	if(hours == 0) {
		hours = 99999;
	}

    new secs = hours * 3600 ;
    new unbants = gettime() + secs;

  	new query[256] ;

	if (hours == 99999)
	{
		format ( query, sizeof ( query ), "[AdmCmd]: %s was banned by %s. Reason: %s.", ReturnRPName(target), Account[playerid][E_PLAYER_ACCOUNT_NAME], reason );
	}
	else
	{
		format ( query, sizeof ( query ), "[AdmCmd]: %s was banned for %d hours by %s. Reason: %s.", ReturnRPName(target), hours, Account[playerid][E_PLAYER_ACCOUNT_NAME], reason );
	}
	
	ZMsg_SendClientMessageToAll(COLOR_RED, query);
	DCC_SendAdminPunishmentMessage(query);

	AddLogEntry(target, LOG_TYPE_ADMIN, sprintf("Was banned by %s, reason: %s", GetPlayerNameEx(playerid), reason));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Banned %s, reason: %s", ReturnRPName(target), reason));

	mysql_escape_string(reason, reason, 64);
    mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
		Account [ target ] [ E_PLAYER_ACCOUNT_ID ], Account [ target ] [ E_PLAYER_ACCOUNT_NAME ], ReturnIP ( target ), GetPlayerNameEx(playerid), reason, gettime(), unbants);

	mysql_tquery(mysql, query);

	SetAdminRecord ( Account [ target ] [ E_PLAYER_ACCOUNT_ID ], Character [ target ] [ E_CHARACTER_ID ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], ARECORD_TYPE_BAN, reason, hours, ReturnDateTime () ) ;
	
	format ( query, sizeof ( query ), "banip %s", ReturnIP ( target ) ) ; 

	SendRconCommand(query);
	KickPlayer ( target ) ;

	return true ;	
}


// /silentban [player] [hours] [reason] - bans without the public announcement.
CMD:silentban(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new target, hours, reason [ 64 ] ;

	if ( sscanf ( params, "k<player>is[64]", target, hours, reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/silentban [target] [hours (0=perm)] [reason]") ;
	}

	if ( hours > 720 ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "You can't temp ban someone for longer than 720 hours (4 weeks). For perm bans use 0.") ;
	}

	if ( strlen ( reason ) > sizeof ( reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Reason can't be longer than 64 characters.") ;
	}

	if ( ! IsPlayerConnected ( target ) ) {

		return SendServerMessage ( playerid, COLOR_RED, "Error", "A3A3A3", "Selected player doesn't exist, they might be offline.");
	}

	if ( GetPlayerAdminLevel ( target ) >= GetPlayerAdminLevel ( playerid ) ) 
	{
		new str[144] ;
		format ( str, sizeof ( str ), "[!!!] [AdmWarn] (%d) %s attempted to ban (%d) %s.", playerid,  Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], target,  Account [ target ] [ E_PLAYER_ACCOUNT_NAME ] ) ;
		SendAdminMessage(str) ;

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You can't ban admins of equal or higher rank.") ;
	}

	if(hours == 0) {
		hours = 99999;
	}

    new secs = hours * 3600 ;
    new unbants = gettime() + secs;

  	new query[256] ;

	if (hours == 99999)
	{
		format ( query, sizeof ( query ), "[AdmCmd]: %s was silent-banned by %s. Reason: %s.", ReturnRPName(target), Account[playerid][E_PLAYER_ACCOUNT_NAME], reason );
	}
	else
	{
		format ( query, sizeof ( query ), "[AdmCmd]: %s was silent-banned for %d hours by %s. Reason: %s.", ReturnRPName(target), hours, Account[playerid][E_PLAYER_ACCOUNT_NAME], reason );
	}
	
	SendAdminMessage(query);
	DCC_SendAdminPunishmentMessage(query);

	AddLogEntry(target, LOG_TYPE_ADMIN, sprintf("Was silent banned by %s, reason: %s", GetPlayerNameEx(playerid), reason));
	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Silent banned %s, reason: %s", ReturnRPName(target), reason));

	mysql_escape_string(reason, reason, 64);
    mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
		Account [ target ] [ E_PLAYER_ACCOUNT_ID ], Account [ target ] [ E_PLAYER_ACCOUNT_NAME ], ReturnIP ( target ), GetPlayerNameEx(playerid), reason, gettime(), unbants);

	mysql_tquery(mysql, query);

	SetAdminRecord ( Account [ target ] [ E_PLAYER_ACCOUNT_ID ], Character [ target ] [ E_CHARACTER_ID ], Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ], ARECORD_TYPE_BAN, reason, hours, ReturnDateTime () ) ;
	
	format ( query, sizeof ( query ), "banip %s", ReturnIP ( target ) ) ; 

	SendRconCommand(query);
	KickPlayer ( target ) ;

	return true ;	
}



// /unban [account name] - lifts a ban from the database.
CMD:unban(playerid, params[] ) {
	// master-acc
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new master_acc [ MAX_PLAYER_NAME ], query[256] ;

	if ( sscanf ( params, "s[24]", master_acc) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/unban [master-account-name]") ;
	}

	if ( strlen ( master_acc ) < 0 || strlen( master_acc ) > MAX_PLAYER_NAME ) {

		format ( query, sizeof ( query ), "Master account name can't be shorter than 0 or longer than %s.", MAX_PLAYER_NAME  ) ;
		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3", query )  ;
	}

	inline ReturnAccountName() {
		if(!cache_num_rows()) {
			return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Database didn't return any account data. Maybe your mistyped the name" )  ;
		}

		else {
			new acc_id, last_ip[16] ;
			cache_get_value_name_int(0, "account_id", acc_id);
			cache_get_value_name(0, "account_lastip", last_ip);

			inline CheckUnban() {
				if(!cache_num_rows()) {
					format ( query, sizeof ( query ),"(%d) %s doesn't seem to be banned. Did you type the name correctly?", acc_id, master_acc );
					return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  query ) ;
				}
				else {
				    mysql_format ( mysql, query, sizeof ( query), "DELETE FROM bans WHERE account_id = %d", acc_id ) ;
					mysql_tquery(mysql, query);

					format ( query, sizeof ( query ), "[AdmWarn] %s has unbanned \"%s\"", Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], master_acc ) ;
					DCC_SendAdminPunishmentMessage(query);
					UnbanIPAddr(last_ip);

					AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Unbanned %s", master_acc));
					SendClientMessage(playerid, COLOR_YELLOW, sprintf("%s has been unbanned", master_acc)) ;
				}
			}

			mysql_format ( mysql, query, sizeof ( query ), "SELECT * FROM bans WHERE account_id = %d", acc_id ) ;
			MySQL_TQueryInline(mysql, using inline CheckUnban, query, "");
		}
	}

	mysql_format ( mysql, query, sizeof ( query ), "SELECT account_id, account_lastip FROM accounts WHERE account_name = '%e'", master_acc ) ;
	MySQL_TQueryInline(mysql, using inline ReturnAccountName, query, "");

	return true ;
}


///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

// /banip [ip] [hours] [reason] - bans an IP address using the server's ban list.
CMD:banip(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new ip [ 16 ], hours, reason[64], query[256] ;

	if ( sscanf ( params, "s[16]is[64]", ip, hours, reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/banip [ip address (including dots)] [hours] [reason]") ;
	}

	foreach(new targetid: Player ) {

		if ( ! strcmp(ip, ReturnIP(targetid), true ) ) {

			// User is online...
			format ( query, sizeof ( query ),"User seems to be connected as ID %d. Use /ban instead.", targetid  ) ;
			return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3", query ) ;
		}	
	}

	if ( hours > 720 ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "You can't temp ban someone for longer than 720 hours (4 weeks). For perm bans use 0.") ;
	}

	if ( strlen ( reason ) > sizeof ( reason ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Error", "A3A3A3",  "Reason can't be longer than 64 characters.") ;
	}

	if(hours == 0) {
		hours = 99999;
	}

    new secs = hours * 3600 ;
    new unbants = gettime() + secs;
    
	mysql_escape_string(reason, reason, 64);
    mysql_format(mysql, query, sizeof(query), "INSERT INTO bans (account_id, account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time) VALUES (%d, '%e', '%e', '%e', '%e', %d, %d)",
		-1, "Unknown", ip,  Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], reason, gettime(), unbants);

	mysql_tquery(mysql, query);

	format ( query, sizeof ( query ), "[AdmWarn] %s has banned IP %s for %d hours. Reason: %s.",  Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], ip, hours, reason ) ;
	DCC_SendAdminPunishmentMessage(query);

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Banned IP %s - %d hrs - %s", ip, hours, reason));

	format ( query, sizeof ( query ), "banip %s", ip ) ; 
	SendRconCommand(query ) ;

	return true ;
}

// Removes an IP from the server ban list by sending the `unbanip` rcon command.
UnbanIPAddr(ip[16])
{
	new string [ 128 ] ;
	format ( string, sizeof ( string ), "unbanip %s", ip ) ; 
	SendRconCommand(string ) ;
}

CMD:unbanip ( playerid, params [] ) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_JUNIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new ip [  16 ];
	new string [ 128 ] ;

	if ( sscanf ( params, "s[16]", ip ) ) {

		return SendServerMessage( playerid, COLOR_RED, "Syntax", "A3A3A3",  "/unbanip [ip]") ;
	}

	UnbanIPAddr(ip);
	format ( string, sizeof ( string ), "[AdmWarn] %s has unbanned IP %s.",  Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], ip ) ;
	DCC_SendAdminPunishmentMessage(string);

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Unbanned IP %s", ip ));

	return true ;
}

///////////////////////////////////////////////////////
///////////////////////////////////////////////////////

#define BANS_PER_PAGE 10

// /banlist - (staff) opens the paged list of current bans.
CMD:banlist(playerid, params[]) 
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
    }

    ShowBanList(playerid, 0);
    return true;
}

// Builds and shows page `page` of the ban list dialog from the database.
ShowBanList(playerid, page) 
{
    new query[512];
    
    inline CountBans() 
    {
        if (!cache_num_rows()) {
            return SendServerMessage(playerid, COLOR_RED, "Error", "A3A3A3", "No bans found in the database.");
        }
        
        new total_bans;
        cache_get_value_name_int(0, "total", total_bans);
        
        if (total_bans == 0) {
            return SendServerMessage(playerid, COLOR_RED, "Error", "A3A3A3", "No bans found in the database.");
        }
        
        new total_pages = (total_bans / BANS_PER_PAGE) + ((total_bans % BANS_PER_PAGE) ? 1 : 0);
        
        if (page < 0) page = 0;
        if (page >= total_pages) page = total_pages - 1;
        
        inline BanDataHandler() 
        {
            new dialog_string[2048], line[256];
            
            format(dialog_string, sizeof(dialog_string), "Account\tIP Address\tAdmin\tReason\tType");
            
            new account_name[MAX_PLAYER_NAME], ip_address[16], ban_admin[MAX_PLAYER_NAME], ban_reason[64];
            new ban_time, unban_time, items_count = 0;
            
            for (new i = 0, rows = cache_num_rows(); i < rows; i++) 
            {
                cache_get_value_name(i, "account_name", account_name);
                cache_get_value_name(i, "account_ip", ip_address);
                cache_get_value_name(i, "ban_admin", ban_admin);
                cache_get_value_name(i, "ban_reason", ban_reason);
                cache_get_value_name_int(i, "ban_time", ban_time);
                cache_get_value_name_int(i, "unban_time", unban_time);
                
                new ban_type[16];
                new ban_duration = unban_time - ban_time;

				
                if (ban_duration >= 99999 * 3600) {
                    format(ban_type, sizeof(ban_type), "{FF0000}PERM");
                } else {
                    new hours_left = (unban_time - gettime()) / 3600;
                    if (hours_left > 0) {
                        format(ban_type, sizeof(ban_type), "{FFFF00}%dH", hours_left);
                    } else {
                        format(ban_type, sizeof(ban_type), "{808080}EXP");
                    }
                }
				
                
                if (!strcmp(account_name, "Unknown", false)) {
                    format(line, sizeof(line), "\n{FF6600}IP BAN\t{DEDEDE}%s\t{DEDEDE}%s\t{DEDEDE}%s\t%s",
                        ip_address, ban_admin, ban_reason, ban_type);
                } else {
                    format(line, sizeof(line), "\n{DEDEDE}%s\t{DEDEDE}%s\t{DEDEDE}%s\t{DEDEDE}%s\t%s",
                        account_name, ip_address, ban_admin, ban_reason, ban_type);
                }
                
                strcat(dialog_string, line);
                items_count++;
            }
            
            if (page > 0) {
                strcat(dialog_string, "\n \n{DB8A11}<< Previous Page");
            }
            
            if (page < total_pages - 1) {
                strcat(dialog_string, "\n{DB8A11}>> Next Page");
            }
            
            new dialog_title[128];
            format(dialog_title, sizeof(dialog_title), 
                "Ban Database - Page %d/%d | Showing %d-%d of %d bans", 
                page + 1, total_pages, 
                (page * BANS_PER_PAGE) + 1, 
                (page * BANS_PER_PAGE) + items_count,
                total_bans);
            
            inline DlgBanList(pid, dialogid, response, listitem, string:inputtext[]) 
            {
                #pragma unused pid, dialogid, inputtext
                
                if (!response) return true;
                
                new prev_page_index = -1;
                new next_page_index = -1;
                
                if (page > 0) {
                    prev_page_index = items_count + 1;
                }
                
                if (page < total_pages - 1) {
                    if (page > 0) {
                        next_page_index = items_count + 2; 
                    } else {
                        next_page_index = items_count;
                    }
                }
                
                if (prev_page_index != -1 && listitem == prev_page_index) {
                    ShowBanList(playerid, page - 1);
                    return true;
                }
                
                if (next_page_index != -1 && listitem == next_page_index) {
                    ShowBanList(playerid, page + 1);
                    return true;
                }
                
                // maybe implement additional functionality when you click on a player (quick unban or some shit)
                return true;
            }
            
            Dialog_ShowCallback(playerid, using inline DlgBanList, DIALOG_STYLE_TABLIST_HEADERS, 
                dialog_title, dialog_string, "Select", "Close");
        }
        
        new offset = page * BANS_PER_PAGE;
        mysql_format(mysql, query, sizeof(query), 
            "SELECT account_name, account_ip, ban_admin, ban_reason, ban_time, unban_time FROM bans ORDER BY ban_time DESC LIMIT %d, %d",
            offset, BANS_PER_PAGE);
        MySQL_TQueryInline(mysql, using inline BanDataHandler, query, "");
    }
    
    mysql_format(mysql, query, sizeof(query), "SELECT COUNT(*) as total FROM bans");
    MySQL_TQueryInline(mysql, using inline CountBans, query, "");
    
    return true;
}


///////////////////////////////////////////////////////
///////////////////////////////////////////////////////
BanChecker ( playerid ) {
	new query[512];
	inline BanHandler() {
		if (!cache_num_rows()) {
			Account_DisplayCharacters(playerid);
			return true ;
		} else {
			new unbantimestamp, admin [ MAX_PLAYER_NAME ], reason [ 64 ], date [ 6 ]  ;
			for( new i, r = cache_num_rows(); i < r; ++i) {
				cache_get_value_name(i, "ban_admin", admin);
				cache_get_value_name(i, "ban_reason", reason);

			 	cache_get_value_name_int( i, "unban_time", unbantimestamp);
			}

			//if ( unbantimestamp > gettime () )  {

			query [ 0 ] = EOS ;

			stamp2datetime ( unbantimestamp,date[0], date[1], date[2], date[3], date[4], date[5], 1 );

			SendClientMessage(playerid, COLOR_RED, "" ) ;
			SendClientMessage(playerid, COLOR_RED, "This account has been temporarily suspended due to a breach of our rules." ) ;
			SendClientMessage(playerid, COLOR_RED, "" ) ;

			format ( query, sizeof ( query ), "You got banned by admin %s for %s.", admin, reason) ;
			SendClientMessage(playerid, COLOR_RED, query );

			format ( query, sizeof ( query ), "You will be unbanned at {DEDEDE}%02d/%02d/%02d %02d:%02d:%02d", date[2], date[1], date[0], date[3], date[4], date[5]) ;
			SendClientMessage(playerid, COLOR_RED, query );
			SendClientMessage(playerid, COLOR_RED, "" ) ;
			SendClientMessage(playerid, COLOR_RED, "Please do not try to evade this ban, as it is only temporary and ban evading results in a permanent ban." ) ;

			format ( query, sizeof ( query ), "If you do not agree with this ban, please appeal the ban on our forums. {DEDEDE}(%s)", SERVER_WEBSITE ) ;
			SendClientMessage(playerid, COLOR_RED,query ) ;
			
			SendClientMessage(playerid, COLOR_RED, "" ) ;

			format ( query, sizeof ( query ), "banip %s", ReturnIP ( playerid ) ) ; 
			SendRconCommand(query ) ;

	    	return KickPlayer ( playerid ) ;
			//}
		}
	}

	mysql_format ( mysql, query, sizeof ( query ), "SELECT unban_time, ban_admin, ban_reason FROM bans WHERE account_id = '%d'", Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ] ) ;
	MySQL_TQueryInline(mysql, using inline BanHandler, query, "" ) ;

	return false ;
}

