// ============================================================================
// File: vehicle/modules/dealer_admin.pwn
// /dealeradmin (lead admin and above): create, rename, move, assign and delete dealerships and
// approve owner applications.
// Commands: /dealeradmin
// ============================================================================

// Admin side of the franchise dealerships: /dealeradmin (lead admin and above).
//
//   /dealeradmin list
//   /dealeradmin create [type 0-7] [name]     at your position (then /dealeradmin setspawn)
//   /dealeradmin delete [id]                  vacant dealerships only
//   /dealeradmin setpos [id]                  move the dealership pickup to where you stand
//   /dealeradmin setspawn [id]                where bought cars appear (uses your vehicle if you are in one)
//   /dealeradmin rename [id] [name]
//   /dealeradmin apps [id]                    review applications, approve or deny
//   /dealeradmin assign [id] [playerid]       give a dealership straight to an online player
//   /dealeradmin stock [id]                   edit stock levels (new owners start with the default stock)
//   /dealeradmin foreclose [id]               remove the owner (their bank is paid out to them)

#define DEALER_ADMIN_MAX_STOCK      (99)
#define DEALER_APPS_PER_PAGE        (12)

static DealerApp_Count [ MAX_PLAYERS ] ;
static DealerApp_CharId [ MAX_PLAYERS ] [ DEALER_APPS_PER_PAGE ] ;
static DealerApp_CharName [ MAX_PLAYERS ] [ DEALER_APPS_PER_PAGE ] [ 32 ] ;

// Returns the colour for a dealership type.
static Dealer_GetTypeColor(type) {

	switch ( type ) {

		case DEALERSHIP_TYPE_BUDGET: 	return 0x9ACD32FF ;
		case DEALERSHIP_TYPE_MUSCLE: 	return 0x3299CDFF ;
		case DEALERSHIP_TYPE_SPORTS: 	return 0xCD3232FF ;
		case DEALERSHIP_TYPE_UTILITY: 	return 0xCDC032FF ;
		case DEALERSHIP_TYPE_AIRCRAFT: 	return 0xB1924CFF ;
	}

	return 0x4C6BB1FF ;
}

// Index into DealershipCars of the nth model sold by a dealership type, so a dialog row can be
// mapped back to a model without storing the rows anywhere.
static Dealer_NthCatalogIndex(type, n) {

	new count ;

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_type ] != type ) {

			continue ;
		}

		if ( count == n ) {

			return i ;
		}

		count ++ ;
	}

	return -1 ;
}

// Shows /dealeradmin usage.
static Dealer_AdminShowUsage(playerid) {

	SendClientMessage ( playerid, COLOR_GRAD0, "/dealeradmin [list / create / delete / setpos / setspawn / rename / apps / assign / stock / foreclose]" ) ;
	SendClientMessage ( playerid, COLOR_GRAD0, "create [type] [name] | delete [id] | setpos [id] | setspawn [id] | rename [id] [name]" ) ;
	SendClientMessage ( playerid, COLOR_GRAD0, "apps [id] | assign [id] [playerid] | stock [id] | foreclose [id]" ) ;

	return SendClientMessage ( playerid, COLOR_INFO, "Types: 0 budget, 1 muscle, 2 sports, 3 utility, 4 bike, 5 aircraft, 6 boat, 7 ship" ) ;
}

// Lists the dealerships.
static Dealer_AdminList(playerid) {

	new type_name [ 16 ], count ;

	SendClientMessage ( playerid, COLOR_INFO, "[ID] Name (type) | Owner | Bank | Cars in stock" ) ;

	for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

		if ( Dealerships [ i ] [ dealership_sqlid ] <= 0 ) {

			continue ;
		}

		Dealer_GetTypeName ( Dealerships [ i ] [ dealership_type ], type_name, sizeof ( type_name ) ) ;

		if ( Dealership_IsOwned ( i ) ) {

			SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "[%d] %s (%s) | %s | $%s | %d", Dealerships [ i ] [ dealership_sqlid ], Dealerships [ i ] [ dealership_name ], type_name,
				Dealerships [ i ] [ dealership_owner_name ], IntegerWithDelimiter ( Dealerships [ i ] [ dealership_bank ] ), Dealership_CountStock ( i ) ) ) ;
		}

		else {

			SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "[%d] %s (%s) | vacant", Dealerships [ i ] [ dealership_sqlid ], Dealerships [ i ] [ dealership_name ], type_name ) ) ;
		}

		count ++ ;
	}

	if ( ! count ) {

		SendClientMessage ( playerid, COLOR_GRAD0, "There are no dealerships. Use /dealeradmin create." ) ;
	}

	return true ;
}

// Creates a dealership.
static Dealer_AdminCreate(playerid, const rest[]) {

	new type, name [ 64 ] ;

	if ( sscanf ( rest, "is[64]", type, name ) || type < 0 || type > DEALERSHIP_TYPE_SHIP ) {

		return SendClientMessage ( playerid, COLOR_GRAD0, "/dealeradmin create [type 0-7] [name]" ) ;
	}

	new dealerid = Dealership_GetFreeID () ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "The dealership limit (%d) has been reached.", MAX_DEALERSHIPS ) ) ;
	}

	new Float: x, Float: y, Float: z, Float: a ;

	GetPlayerPos ( playerid, x, y, z ) ;
	GetPlayerFacingAngle ( playerid, a ) ;

	// Reserve the slot until the insert comes back.
	Dealership_ClearEntity ( dealerid ) ;
	Dealerships [ dealerid ] [ dealership_sqlid ] = -1 ;

	new query [ 640 ], color = Dealer_GetTypeColor ( type ) ;

	mysql_format ( mysql, query, sizeof ( query ),
		"INSERT INTO dealerships (dealer_type, dealer_name, dealer_color, dealer_pos_x, dealer_pos_y, dealer_pos_z, dealer_spawn_x, dealer_spawn_y, dealer_spawn_z, dealer_spawn_a) VALUES (%d, '%e', %d, '%f', '%f', '%f', '%f', '%f', '%f', '%f')",
		type, name, color, x, y, z, x, y, z, a ) ;

	inline Dealer_OnCreate() {

		new sqlid = cache_insert_id () ;

		if ( sqlid <= 0 ) {

			Dealerships [ dealerid ] [ dealership_sqlid ] = 0 ;
			return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "The dealership couldn't be saved. Is the dealerships table there?" ) ;
		}

		Dealerships [ dealerid ] [ dealership_sqlid ] = sqlid ;
		Dealerships [ dealerid ] [ dealership_type ] = type ;
		Dealerships [ dealerid ] [ dealership_color ] = color ;
		Dealerships [ dealerid ] [ dealership_name ] [ 0 ] = EOS ;
		strcat ( Dealerships [ dealerid ] [ dealership_name ], name, 64 ) ;
		Dealerships [ dealerid ] [ dealership_pos_x ] = x ;
		Dealerships [ dealerid ] [ dealership_pos_y ] = y ;
		Dealerships [ dealerid ] [ dealership_pos_z ] = z ;
		Dealerships [ dealerid ] [ dealership_spawn_x ] = x ;
		Dealerships [ dealerid ] [ dealership_spawn_y ] = y ;
		Dealerships [ dealerid ] [ dealership_spawn_z ] = z ;
		Dealerships [ dealerid ] [ dealership_spawn_a ] = a ;

		Dealership_CreateVisuals ( dealerid ) ;

		SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Created dealership %d (%s). Bought cars appear at your position until you use /dealeradmin setspawn %d.", sqlid, name, sqlid ) ) ;
		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Created dealership %d (%s)", sqlid, name ) ) ;

		return true ;
	}

	MySQL_TQueryInline ( mysql, using inline Dealer_OnCreate, query, "" ) ;

	return true ;
}

// Deletes a dealership.
static Dealer_AdminDelete(playerid, dealerid) {

	if ( Dealership_IsOwned ( dealerid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "This dealership has an owner. Use /dealeradmin foreclose first." ) ;
	}

	new query [ 128 ], sqlid = Dealerships [ dealerid ] [ dealership_sqlid ] ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM dealerships WHERE dealer_id = %d", sqlid ) ;
	mysql_tquery ( mysql, query ) ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM dealership_stock WHERE dealer_id = %d", sqlid ) ;
	mysql_tquery ( mysql, query ) ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM dealership_applications WHERE dealer_id = %d", sqlid ) ;
	mysql_tquery ( mysql, query ) ;

	AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Deleted dealership %d (%s)", sqlid, Dealerships [ dealerid ] [ dealership_name ] ) ) ;
	SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Deleted dealership %d (%s).", sqlid, Dealerships [ dealerid ] [ dealership_name ] ) ) ;

	Dealership_DestroyVisuals ( dealerid ) ;
	Dealership_ClearEntity ( dealerid ) ;
	GPS_SyncDealerships () ;

	return true ;
}

// Sets a dealership's entrance position.
static Dealer_AdminSetPos(playerid, dealerid) {

	new Float: x, Float: y, Float: z, query [ 256 ] ;

	GetPlayerPos ( playerid, x, y, z ) ;

	Dealerships [ dealerid ] [ dealership_pos_x ] = x ;
	Dealerships [ dealerid ] [ dealership_pos_y ] = y ;
	Dealerships [ dealerid ] [ dealership_pos_z ] = z ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE dealerships SET dealer_pos_x = '%f', dealer_pos_y = '%f', dealer_pos_z = '%f' WHERE dealer_id = %d",
		x, y, z, Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	Dealership_DestroyVisuals ( dealerid ) ;
	Dealership_CreateVisuals ( dealerid ) ;

	AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Moved dealership %d (%s)", Dealerships [ dealerid ] [ dealership_sqlid ], Dealerships [ dealerid ] [ dealership_name ] ) ) ;

	return SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", "The dealership pickup has been moved to your position." ) ;
}

// Sets the position where bought vehicles spawn.
static Dealer_AdminSetSpawn(playerid, dealerid) {

	new Float: x, Float: y, Float: z, Float: a, query [ 256 ] ;

	if ( IsPlayerInAnyVehicle ( playerid ) ) {

		new vehicleid = GetPlayerVehicleID ( playerid ) ;

		GetVehiclePos ( vehicleid, x, y, z ) ;
		GetVehicleZAngle ( vehicleid, a ) ;
	}

	else {

		GetPlayerPos ( playerid, x, y, z ) ;
		GetPlayerFacingAngle ( playerid, a ) ;
	}

	Dealerships [ dealerid ] [ dealership_spawn_x ] = x ;
	Dealerships [ dealerid ] [ dealership_spawn_y ] = y ;
	Dealerships [ dealerid ] [ dealership_spawn_z ] = z ;
	Dealerships [ dealerid ] [ dealership_spawn_a ] = a ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE dealerships SET dealer_spawn_x = '%f', dealer_spawn_y = '%f', dealer_spawn_z = '%f', dealer_spawn_a = '%f' WHERE dealer_id = %d",
		x, y, z, a, Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set the spawn of dealership %d (%s)", Dealerships [ dealerid ] [ dealership_sqlid ], Dealerships [ dealerid ] [ dealership_name ] ) ) ;

	return SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", "Bought cars will now appear here." ) ;
}

// Renames a dealership.
static Dealer_AdminRename(playerid, dealerid, const name[]) {

	if ( strlen ( name ) < 3 || strfind ( name, "{", true ) != -1 ) {

		return SendClientMessage ( playerid, COLOR_GRAD0, "/dealeradmin rename [id] [name] (at least 3 characters, no colour codes)" ) ;
	}

	Dealerships [ dealerid ] [ dealership_name ] [ 0 ] = EOS ;
	strcat ( Dealerships [ dealerid ] [ dealership_name ], name, 64 ) ;

	new query [ 192 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE dealerships SET dealer_name = '%e' WHERE dealer_id = %d", Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	Dealership_RefreshLabel ( dealerid ) ;

	return SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Dealership %d is now called %s.", Dealerships [ dealerid ] [ dealership_sqlid ], name ) ) ;
}

// Assigns a dealership to a player.
static Dealer_AdminAssign(playerid, dealerid, targetid) {

	if ( ! IsPlayerConnected ( targetid ) || ! IsPlayerLogged ( targetid ) || Character [ targetid ] [ E_CHARACTER_ID ] <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That player isn't logged in." ) ;
	}

	if ( Dealership_IsOwned ( dealerid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That dealership already has an owner." ) ;
	}

	if ( Dealership_GetOwnedBy ( Character [ targetid ] [ E_CHARACTER_ID ] ) != INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That player already owns a dealership." ) ;
	}

	Dealership_SetOwner ( dealerid, Character [ targetid ] [ E_CHARACTER_ID ], ReturnRPName ( targetid ) ) ;

	SendServerMessage ( targetid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "You are now the owner of %s! It starts with some stock and an empty bank. Use /dealerinfo and /dealerorder at the dealership.", Dealerships [ dealerid ] [ dealership_name ] ) ) ;
	SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "%s now owns %s with the default stock. Use /dealeradmin stock %d to adjust it.",
		ReturnRPName ( targetid ), Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ] ) ) ;

	AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Gave dealership %d (%s) to %s", Dealerships [ dealerid ] [ dealership_sqlid ], Dealerships [ dealerid ] [ dealership_name ], ReturnRPName ( targetid ) ) ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Stock editor
// ---------------------------------------------------------------------------------------------

// Opens the stock editor of a dealership.
static Dealer_AdminStockEditor(playerid, dealerid) {

	new string [ 3072 ], title [ 96 ], type = Dealerships [ dealerid ] [ dealership_type ], sqlid = Dealerships [ dealerid ] [ dealership_sqlid ] ;

	strcat ( string, "Model\tIn stock\tSticker price\n" ) ;
	strcat ( string, "{ADBEE6}>> Reset to the default starting stock\t\t\n" ) ;
	strcat ( string, "{ADBEE6}>> Remove all stock\t\t\n" ) ;

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_type ] != type ) {

			continue ;
		}

		format ( string, sizeof ( string ), "%s{FFFFFF}%s\t%d\t$%s\n", string, ReturnVehicleModelName ( DealershipCars [ i ] [ dealercar_carmodel ] ),
			DealerStock [ dealerid ] [ i ], IntegerWithDelimiter ( DealershipCars [ i ] [ dealercar_price ] ) ) ;
	}

	format ( title, sizeof ( title ), "Stock: %s%s", Dealerships [ dealerid ] [ dealership_name ], Dealership_IsOwned ( dealerid ) ? ("") : (" (vacant, unlimited)") ) ;

	inline DealerStockEditor(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, inputtext

		if ( ! response ) {

			return true ;
		}

		if ( Dealerships [ dealerid ] [ dealership_sqlid ] != sqlid ) {

			return true ;
		}

		if ( listitem == 0 ) {

			Dealership_FillDefaultStock ( dealerid ) ;
			SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", "Stock reset to the default starting levels." ) ;
			AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Reset the stock of dealership %d (%s) to default", sqlid, Dealerships [ dealerid ] [ dealership_name ] ) ) ;

			return Dealer_AdminStockEditor ( playerid, dealerid ) ;
		}

		if ( listitem == 1 ) {

			Dealership_ClearStock ( dealerid ) ;
			SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", "All stock removed." ) ;
			AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Cleared the stock of dealership %d (%s)", sqlid, Dealerships [ dealerid ] [ dealership_name ] ) ) ;

			return Dealer_AdminStockEditor ( playerid, dealerid ) ;
		}

		new cat_index = Dealer_NthCatalogIndex ( type, listitem - 2 ) ;

		if ( cat_index == -1 ) {

			return true ;
		}

		new prompt [ 160 ] ;

		format ( prompt, sizeof ( prompt ), "{DEDEDE}%s\nCurrently in stock: %d\n\nNew amount (0-%d):", ReturnVehicleModelName ( DealershipCars [ cat_index ] [ dealercar_carmodel ] ),
			DealerStock [ dealerid ] [ cat_index ], DEALER_ADMIN_MAX_STOCK ) ;

		inline DealerStockQty(pid2, dialogid2, response2, listitem2, string:inputtext2[]) {
			#pragma unused pid2, dialogid2, listitem2

			if ( response2 && Dealerships [ dealerid ] [ dealership_sqlid ] == sqlid ) {

				new qty = strval ( inputtext2 ) ;

				if ( qty < 0 || qty > DEALER_ADMIN_MAX_STOCK ) {

					SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "Enter an amount between 0 and %d.", DEALER_ADMIN_MAX_STOCK ) ) ;
				}

				else {

					Dealership_SetStock ( dealerid, cat_index, qty ) ;
					AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set the stock of %s at dealership %d (%s) to %d", ReturnVehicleModelName ( DealershipCars [ cat_index ] [ dealercar_carmodel ] ),
						sqlid, Dealerships [ dealerid ] [ dealership_name ], qty ) ) ;
				}
			}

			return Dealer_AdminStockEditor ( playerid, dealerid ) ;
		}

		Dialog_ShowCallback ( playerid, using inline DealerStockQty, DIALOG_STYLE_INPUT, "Set Stock", prompt, "Set", "Back" ) ;

		return true ;
	}

	Dialog_ShowCallback ( playerid, using inline DealerStockEditor, DIALOG_STYLE_TABLIST_HEADERS, title, string, "Edit", "Close" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Applications
// ---------------------------------------------------------------------------------------------

forward Dealer_AdminShowApps(playerid, dealerid);

// Accepts or denies an application for a dealership.
static Dealer_AdminAppAction(playerid, dealerid, sqlid, index) {

	new char_id = DealerApp_CharId [ playerid ] [ index ], char_name [ 32 ] ;

	strcat ( char_name, DealerApp_CharName [ playerid ] [ index ], sizeof ( char_name ) ) ;

	inline DealerAppAction(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, inputtext

		if ( ! response ) {

			return Dealer_AdminShowApps ( playerid, dealerid ) ;
		}

		if ( Dealerships [ dealerid ] [ dealership_sqlid ] != sqlid ) {

			return true ;
		}

		new query [ 128 ] ;

		if ( listitem == 0 ) {

			if ( Dealership_IsOwned ( dealerid ) ) {

				return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That dealership already has an owner." ) ;
			}

			if ( Dealership_GetOwnedBy ( char_id ) != INVALID_DEALERSHIP_ID ) {

				return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That character already owns a dealership." ) ;
			}

			Dealership_SetOwner ( dealerid, char_id, char_name ) ;

			SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "%s now owns %s with the default stock. Use /dealeradmin stock %d to adjust it.", char_name, Dealerships [ dealerid ] [ dealership_name ], sqlid ) ) ;
			AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Approved %s as the owner of dealership %d (%s)", char_name, sqlid, Dealerships [ dealerid ] [ dealership_name ] ) ) ;

			foreach ( new i : Player ) {

				if ( IsPlayerLogged ( i ) && Character [ i ] [ E_CHARACTER_ID ] == char_id ) {

					SendServerMessage ( i, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Your application was approved! You now own %s. Use /dealerinfo and /dealerorder at the dealership.", Dealerships [ dealerid ] [ dealership_name ] ) ) ;
					break ;
				}
			}

			return true ;
		}

		mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM dealership_applications WHERE dealer_id = %d AND character_id = %d", sqlid, char_id ) ;
		mysql_tquery ( mysql, query ) ;

		SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Denied %s's application for %s.", char_name, Dealerships [ dealerid ] [ dealership_name ] ) ) ;
		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Denied %s's application for dealership %d (%s)", char_name, sqlid, Dealerships [ dealerid ] [ dealership_name ] ) ) ;

		foreach ( new i : Player ) {

			if ( IsPlayerLogged ( i ) && Character [ i ] [ E_CHARACTER_ID ] == char_id ) {

				SendServerMessage ( i, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "Your application for %s was denied.", Dealerships [ dealerid ] [ dealership_name ] ) ) ;
				break ;
			}
		}

		return Dealer_AdminShowApps ( playerid, dealerid ) ;
	}

	Dialog_ShowCallback ( playerid, using inline DealerAppAction, DIALOG_STYLE_LIST, sprintf ( "Application: %s", char_name ), "Approve and make them the owner\nDeny the application", "Select", "Back" ) ;

	return true ;
}

// Shows the applications for a dealership.
Dealer_AdminShowApps(playerid, dealerid) {

	new query [ 256 ], sqlid = Dealerships [ dealerid ] [ dealership_sqlid ] ;

	mysql_format ( mysql, query, sizeof ( query ),
		"SELECT character_id, character_name, app_message, app_created_at FROM dealership_applications WHERE dealer_id = %d ORDER BY app_created_at ASC LIMIT %d",
		sqlid, DEALER_APPS_PER_PAGE ) ;

	inline Dealer_OnAppsLoad() {

		DealerApp_Count [ playerid ] = 0 ;

		new string [ 2048 ] ;

		strcat ( string, "Applicant\tApplied\tMessage\n" ) ;

		for ( new i = 0, r = cache_num_rows(); i < r && i < DEALER_APPS_PER_PAGE; i ++ ) {

			new created, message [ 128 ] ;

			cache_get_value_name_int ( i, "character_id", DealerApp_CharId [ playerid ] [ i ] ) ;
			cache_get_value_name ( i, "character_name", DealerApp_CharName [ playerid ] [ i ], 32 ) ;
			cache_get_value_name ( i, "app_message", message, sizeof ( message ) ) ;
			cache_get_value_name_int ( i, "app_created_at", created ) ;

			format ( string, sizeof ( string ), "%s%s\t%d days ago\t%s\n", string, DealerApp_CharName [ playerid ] [ i ], ( gettime () - created ) / 86400, message ) ;

			DealerApp_Count [ playerid ] ++ ;
		}

		if ( ! DealerApp_Count [ playerid ] ) {

			return SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "There are no applications for %s.", Dealerships [ dealerid ] [ dealership_name ] ) ) ;
		}

		inline DealerAppList(pid, dialogid, response, listitem, string:inputtext[]) {
			#pragma unused pid, dialogid, inputtext

			if ( response && listitem >= 0 && listitem < DealerApp_Count [ playerid ] ) {

				Dealer_AdminAppAction ( playerid, dealerid, sqlid, listitem ) ;
			}
		}

		Dialog_ShowCallback ( playerid, using inline DealerAppList, DIALOG_STYLE_TABLIST_HEADERS, sprintf ( "Applications: %s", Dealerships [ dealerid ] [ dealership_name ] ), string, "Review", "Close" ) ;

		return true ;
	}

	MySQL_TQueryInline ( mysql, using inline Dealer_OnAppsLoad, query, "" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------

// /dealeradmin - (admin) manages dealerships.
CMD:dealeradmin(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command." ) ;
	}

	new sub [ 16 ], rest [ 128 ] ;

	if ( sscanf ( params, "s[16]S()[128]", sub, rest ) ) {

		return Dealer_AdminShowUsage ( playerid ) ;
	}

	if ( ! strcmp ( sub, "list", true ) ) {

		return Dealer_AdminList ( playerid ) ;
	}

	if ( ! strcmp ( sub, "create", true ) ) {

		return Dealer_AdminCreate ( playerid, rest ) ;
	}

	// Everything below takes a dealership id first.
	new sqlid, extra [ 64 ] ;

	if ( sscanf ( rest, "iS()[64]", sqlid, extra ) ) {

		return Dealer_AdminShowUsage ( playerid ) ;
	}

	new dealerid = Dealership_GetBySqlId ( sqlid ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That isn't a valid dealership id. Use /dealeradmin list." ) ;
	}

	if ( ! strcmp ( sub, "delete", true ) ) {

		return Dealer_AdminDelete ( playerid, dealerid ) ;
	}

	if ( ! strcmp ( sub, "setpos", true ) ) {

		return Dealer_AdminSetPos ( playerid, dealerid ) ;
	}

	if ( ! strcmp ( sub, "setspawn", true ) ) {

		return Dealer_AdminSetSpawn ( playerid, dealerid ) ;
	}

	if ( ! strcmp ( sub, "rename", true ) ) {

		return Dealer_AdminRename ( playerid, dealerid, extra ) ;
	}

	if ( ! strcmp ( sub, "apps", true ) ) {

		return Dealer_AdminShowApps ( playerid, dealerid ) ;
	}

	if ( ! strcmp ( sub, "stock", true ) ) {

		return Dealer_AdminStockEditor ( playerid, dealerid ) ;
	}

	if ( ! strcmp ( sub, "assign", true ) ) {

		new targetid ;

		if ( sscanf ( extra, "k<player>", targetid ) ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, "/dealeradmin assign [id] [playerid]" ) ;
		}

		return Dealer_AdminAssign ( playerid, dealerid, targetid ) ;
	}

	if ( ! strcmp ( sub, "foreclose", true ) ) {

		if ( ! Dealership_IsOwned ( dealerid ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That dealership is already vacant." ) ;
		}

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Foreclosed dealership %d (%s) owned by %s", sqlid, Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_owner_name ] ) ) ;

		Dealership_NotifyOwner ( dealerid, "[Dealership] Your dealership has been foreclosed by an admin." ) ;
		Dealership_Vacate ( dealerid, "foreclosed by an admin" ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", "The dealership is vacant again and open for applications." ) ;
	}

	return Dealer_AdminShowUsage ( playerid ) ;
}
