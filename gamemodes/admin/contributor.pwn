// ============================================================================
// File: admin/contributor.pwn
// Contributor / special-role system (non-staff helpers such as testers or donators) and the
// /togadmin toggle. Applies the extra rights a contributor rank grants.
// Commands: /makecontributor /togadmin
// ============================================================================

enum {
	E_CONTRIBUTOR_NONE = 0,
	E_CONTRIBUTOR_VETERAN, // old, down to earth ex admins i.e. street, TNT, ... (NO ADMIN POWER!)
	E_CONTRIBUTOR_INVITED // contributors that do/did a lot of work like ryhes / janichar
} ;

// Returns true if the player's account has a contributor rank.
IsPlayerContributor(playerid) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ] ) {
		return true ;
	}

	return false ;
}

// Writes the display name of a contributor rank (Veteran, etc.) into rank_name.
GetContributorRankName(rank, rank_name[], len = sizeof ( rank_name ) ) {

	rank_name [ 0 ] = EOS ;

	switch ( rank ) {

		case E_CONTRIBUTOR_NONE:		strcat ( rank_name, "None", len ) ;
		case E_CONTRIBUTOR_VETERAN:		strcat ( rank_name, "Veteran", len ) ;
		case E_CONTRIBUTOR_INVITED:		strcat ( rank_name, "Invited", len ) ;
		default: strcat ( rank_name, "Regular", len ) ;
	}
}

// Applies the rights that come with a contributor rank when the player logs in (and clears
// invalid ranks).
Contributor_ApplyRights(playerid) {

	// Types above Invited (the old Developer / Hidden Manager grants) no longer exist - clear them.
	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ] > E_CONTRIBUTOR_INVITED ) {

		Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ] = E_CONTRIBUTOR_NONE ;

		new query [ 96 ] ;
		mysql_format(mysql, query, sizeof ( query ), "UPDATE accounts SET account_contributor = 0 WHERE account_id = %d", Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ] ) ;
		mysql_tquery(mysql, query);
		return ;
	}

	switch ( Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ] ) {

		case E_CONTRIBUTOR_VETERAN: {
			SendClientMessage ( playerid, COLOR_YELLOW, "You have been invited to the admin chat. You will be able to talk in /achat as a");
			SendClientMessage ( playerid, COLOR_YELLOW, "thank you for your community efforts and past contributions. You have been given");
			SendClientMessage ( playerid, COLOR_YELLOW, "helper status. It is recommended to help out during rush hour, but not obligated.");
			SendClientMessage ( playerid, 0xDEDEDEFF, "To disable spam, use /togadmin.}");
			Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] = ADMIN_LVL_NONE;
			Account [ playerid ] [ E_PLAYER_ACCOUNT_SUPPORTER ] = true ;
		}
		case E_CONTRIBUTOR_INVITED: {

			SendClientMessage ( playerid, COLOR_YELLOW, "You have been invited to the admin chat. You have the same rights as a Junior Admin");
			SendClientMessage ( playerid, COLOR_YELLOW, "due to your past contributions. You do not have any direct obligations, but it is");
			SendClientMessage ( playerid, COLOR_YELLOW, "encouraged to help out during rush hour.{DEDEDE}To disable spam, use /togadmin.");
			SendClientMessage ( playerid, COLOR_RED, "Only use admin commands during admin sessions, not for your own benefit!");

			Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] = ADMIN_LVL_JUNIOR ;
			Account [ playerid ] [ E_PLAYER_ACCOUNT_SUPPORTER ] = true ;
		}
	}
}

// /makecontributor [player] [type] - (head admin) sets a player's contributor rank.
CMD:makecontributor(playerid, params[]) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_HEAD ) {

		return false ;
	}

	new user, type ;

	if ( sscanf ( params, "k<player>i", user, type) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/makecontributor [player] [type]" ) ;

		SendClientMessage(playerid, COLOR_YELLOW, "List of types:");
		SendClientMessage(playerid, COLOR_RED, "0: None");
		SendClientMessage(playerid, COLOR_RED, "1: Veteran{DEDEDE} (No Admin Powers)");
		SendClientMessage(playerid, COLOR_RED, "2: Invited{DEDEDE} (Junior Admin Powers)");
		return true ;
	}

	if ( ! IsPlayerConnected ( user ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Target isn't connected." ) ;
	}

	if ( type < E_CONTRIBUTOR_NONE || type > E_CONTRIBUTOR_INVITED ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Type must be between 0 and 2." ) ;
	}

	Account [ user ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ] = type ;

	new rank_name [ 32 ], string [ 256 ] ;

	GetContributorRankName ( Account [ user ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ], rank_name, 32 ) ;

	format ( string, sizeof ( string ), "{[ %s (%d) has invited %s (%d) as a %s. ]}",  Account [playerid][E_PLAYER_ACCOUNT_NAME], playerid,
		Account [user][E_PLAYER_ACCOUNT_NAME], user, rank_name ) ;

	SendAdminMessage(string) ;

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("made %s a %s", Account [ user ] [ E_PLAYER_ACCOUNT_NAME ], rank_name ) ) ;

	mysql_format(mysql, string, sizeof(string), "UPDATE accounts SET account_contributor = %d WHERE account_id = %d", 

		Account [ user ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ], Account [ user ] [ E_PLAYER_ACCOUNT_ID ] ) ;

	mysql_tquery(mysql, string);
	Contributor_ApplyRights(user);


	return true ;
}

// /togadmin [warnings/desync/chat] - toggles which staff notifications you receive.
CMD:togadmin(playerid, params[]) {

	if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] < ADMIN_LVL_JUNIOR ) {

		return false ;
	}

	new option[16];

	if ( sscanf(params, "s[16]", option) ) {

		// Enable all warnings if they're disabled and haven't specified a setting.
		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] || PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] || PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DESYNC_TOGGLED ]) {

			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] = false ;
			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] = false;
			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DESYNC_TOGGLED ] = false;
			SendClientMessage ( playerid, COLOR_BLUE, "You've enabled admin/helper warnings, desyncs and chats.");

			return true;
		}


		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/togadmin [warnings/desync/chat]" ) ;
		SendClientMessage(playerid, 0xA3A3A3FF, "warnings - toggles admin messages & warnings.");
		SendClientMessage(playerid, 0xA3A3A3FF, "chat - toggles admin & helper chats.");
		SendClientMessage(playerid, 0xA3A3A3FF, "desync - toggles desync logs.");

		return true ;
	}

	if ( !strcmp(option, "warnings", true) ) {

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] ) {

			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] = false ;
			SendClientMessage ( playerid, COLOR_BLUE, "You've enabled admin/helper warnings.");

		} else {
			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_WARNS_TOGGLED ] = true ;
			SendClientMessage ( playerid, COLOR_BLUE, "You've disabled admin/helper warnings.");

			if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR) {
				SendClientMessage ( playerid, COLOR_ERROR, "Admin warnings are essential to an admin's duty. Re-enable this as soon as possible.");
			}

		}

		return true ;
	}

	if ( !strcmp(option, "desync", true) ) {

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DESYNC_TOGGLED ] ) {

			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DESYNC_TOGGLED ] = false ;
			SendClientMessage ( playerid, COLOR_BLUE, "You've enabled desync logs.");

		} else {
			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_DESYNC_TOGGLED ] = true ;
			SendClientMessage ( playerid, COLOR_BLUE, "You've disabled desync logs.");

			if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR) {
				SendClientMessage ( playerid, COLOR_ERROR, "Desync logs are essential to an admin's duty. Re-enable this as soon as possible.");
			}

		}

		return true ;
	}

	if ( !strcmp(option, "chat", true) ) {

		if ( PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] ) {

			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] = false ;
			SendClientMessage ( playerid, COLOR_BLUE, "You've enabled admin/helper chats.");

		} else {
			PlayerVar [ playerid ] [ E_PLAYER_ADMIN_CHATS_TOGGLED ] = true ;
			SendClientMessage ( playerid, COLOR_BLUE, "You've disabled admin/helper chats.");

			if ( GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR) {
				SendClientMessage ( playerid, COLOR_ERROR, "Admin chats are essential to an admin's duty. Re-enable this as soon as possible.");
			}

		}

		return true ;
	}


	return true ;
}
