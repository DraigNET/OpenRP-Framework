// ============================================================================
// File: vehicle/modules/dealer_owner.pwn
// Dealership owner commands: /dealerapply, /dealerinfo, /dealerorder (wholesale stock),
// /dealerbank and /dealerresign.
// Commands: /dealerapply /dealerinfo /dealerorder /dealerbank /dealerresign
// ============================================================================

// Owner side of the franchise dealerships (see dealer.pwn for the data and the buyer side):
//  /dealerapply   apply for a vacant dealership (an admin approves it, see dealer_admin.pwn)
//  /dealerinfo    stock levels, wholesale prices and bank of the dealership you own
//  /dealerorder   at your dealership, order more cars from the manufacturer
//  /dealerbank    at your dealership, check, deposit or withdraw the dealership's money
//  /dealerresign  give the dealership up
// An owner who stays offline for DEALER_INACTIVE_DAYS loses the dealership (foreclosure).

#include <YSI_Coding\y_hooks>

// The dealership the player owns, if they are standing at it.
static Dealer_GetOwnedHere(playerid) {

	new dealerid = Dealership_GetClosestEntity ( playerid ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return INVALID_DEALERSHIP_ID ;
	}

	if ( Dealerships [ dealerid ] [ dealership_owner_char ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

		return INVALID_DEALERSHIP_ID ;
	}

	return dealerid ;
}

// /dealerapply - applies to own a dealership.
CMD:dealerapply(playerid, params[]) {

	if ( ! IsPlayerLogged ( playerid ) || Character [ playerid ] [ E_CHARACTER_ID ] <= 0 ) {

		return false ;
	}

	if ( Dealership_GetOwnedBy ( Character [ playerid ] [ E_CHARACTER_ID ] ) != INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "You already own a dealership." ) ;
	}

	new sqlid, message [ 128 ] ;

	if ( sscanf ( params, "iS()[128]", sqlid, message ) ) {

		SendClientMessage ( playerid, COLOR_GRAD0, "/dealerapply [dealership id] [short message to the admins]" ) ;
		SendClientMessage ( playerid, COLOR_INFO, "Dealerships currently looking for an owner:" ) ;

		new found, type_name [ 16 ] ;

		for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

			if ( Dealerships [ i ] [ dealership_sqlid ] > 0 && ! Dealership_IsOwned ( i ) ) {

				Dealer_GetTypeName ( Dealerships [ i ] [ dealership_type ], type_name, sizeof ( type_name ) ) ;
				SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "  ID %d: %s (%s)", Dealerships [ i ] [ dealership_sqlid ], Dealerships [ i ] [ dealership_name ], type_name ) ) ;
				found ++ ;
			}
		}

		if ( ! found ) {

			SendClientMessage ( playerid, COLOR_GRAD0, "  None right now." ) ;
		}

		return true ;
	}

	new dealerid = Dealership_GetBySqlId ( sqlid ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That isn't a valid dealership id. Use /dealerapply to see them." ) ;
	}

	if ( Dealership_IsOwned ( dealerid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "That dealership already has an owner." ) ;
	}

	new query [ 512 ] ;

	mysql_format ( mysql, query, sizeof ( query ),
		"INSERT INTO dealership_applications (dealer_id, character_id, character_name, app_message, app_created_at) VALUES (%d, %d, '%e', '%e', %d) ON DUPLICATE KEY UPDATE app_message = VALUES(app_message), app_created_at = VALUES(app_created_at)",
		Dealerships [ dealerid ] [ dealership_sqlid ], Character [ playerid ] [ E_CHARACTER_ID ], ReturnRPName ( playerid ), message, gettime () ) ;
	mysql_tquery ( mysql, query ) ;

	SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "You applied to take over %s. An admin will review your application.", Dealerships [ dealerid ] [ dealership_name ] ) ) ;
	SendAdminMessage ( sprintf ( "[Dealership] %s applied for %s (ID %d). Use /dealeradmin apps %d.", ReturnRPName ( playerid ),
		Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ], Dealerships [ dealerid ] [ dealership_sqlid ] ), COLOR_YELLOW, false ) ;

	return true ;
}

// /dealerinfo - shows information about your dealership.
CMD:dealerinfo(playerid, params[]) {

	#pragma unused params

	new dealerid = Dealership_GetOwnedBy ( Character [ playerid ] [ E_CHARACTER_ID ] ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "You don't own a dealership." ) ;
	}

	new string [ 3072 ], title [ 96 ] ;

	strcat ( string, "Model\tIn stock\tWholesale price\n" ) ;

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_type ] != Dealerships [ dealerid ] [ dealership_type ] ) {

			continue ;
		}

		format ( string, sizeof ( string ), "%s%s\t%d / %d\t$%s\n", string, ReturnVehicleModelName ( DealershipCars [ i ] [ dealercar_carmodel ] ),
			DealerStock [ dealerid ] [ i ], DEALER_MAX_STOCK, IntegerWithDelimiter ( Dealer_GetWholesale ( DealershipCars [ i ] [ dealercar_price ] ) ) ) ;
	}

	format ( title, sizeof ( title ), "%s - Bank: $%s", Dealerships [ dealerid ] [ dealership_name ], IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ) ) ;

	inline DealerInfoDlg(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, response, listitem, inputtext
	}

	Dialog_ShowCallback ( playerid, using inline DealerInfoDlg, DIALOG_STYLE_TABLIST_HEADERS, title, string, "Close", "" ) ;

	SendClientMessage ( playerid, COLOR_INFO, sprintf ( "[Dealership] %s | Bank: $%s | %d cars in stock | Wholesale: %d%% of the sticker price. Order more with /dealerorder at the dealership.",
		Dealerships [ dealerid ] [ dealership_name ], IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ),
		Dealership_CountStock ( dealerid ), DEALER_WHOLESALE_PCT ) ) ;

	return true ;
}

// /dealerorder - orders stock for your dealership.
CMD:dealerorder(playerid, params[]) {

	#pragma unused params

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
	}

	new dealerid = Dealer_GetOwnedHere ( playerid ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "You must be standing at the dealership you own." ) ;
	}

	new row_name [ 64 ] ;
	ModelBrowser_ClearData ( playerid ) ;

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_type ] != Dealerships [ dealerid ] [ dealership_type ] ) {

			continue ;
		}

		format ( row_name, sizeof ( row_name ), "%s ($%s ea) ~w~x%d", ReturnVehicleModelName ( DealershipCars [ i ] [ dealercar_carmodel ] ),
			IntegerWithDelimiter ( Dealer_GetWholesale ( DealershipCars [ i ] [ dealercar_price ] ) ), DealerStock [ dealerid ] [ i ] ) ;

		ModelBrowser_AddData ( playerid, DealershipCars [ i ] [ dealercar_carmodel ], row_name ) ;
	}

	SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Pick a model to order. Bank: $%s, wholesale price is %d%% of the sticker price.",
		IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ), DEALER_WHOLESALE_PCT ) ) ;

	ModelBrowser_SetupTiles ( playerid, "Order Stock", "dealer_order" ) ;

	return true ;
}

// Model browser callback: the owner picks a vehicle to order.
mBrowser:dealer_order(playerid, response, row, model, name[]) {

	if ( ! response ) {

		return true ;
	}

	new dealerid = Dealer_GetOwnedHere ( playerid ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "You must be standing at the dealership you own." ) ;
	}

	new cat_index = Dealer_GetCatalogIndex ( Dealerships [ dealerid ] [ dealership_type ], model ) ;

	if ( cat_index == -1 ) {

		return SendClientMessage ( playerid, COLOR_ERROR, "Vehicle not found." ) ;
	}

	new room = DEALER_MAX_STOCK - DealerStock [ dealerid ] [ cat_index ], wholesale = Dealer_GetWholesale ( DealershipCars [ cat_index ] [ dealercar_price ] ) ;

	if ( room <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "You already hold the maximum of %d %s.", DEALER_MAX_STOCK, ReturnVehicleModelName ( model ) ) ) ;
	}

	new prompt [ 256 ] ;

	format ( prompt, sizeof ( prompt ), "{DEDEDE}Ordering {ed7f2b}%s{DEDEDE}\n\nWholesale price: {32CD32}$%s{DEDEDE} each\nIn stock: %d (room for %d more)\nDealership bank: {32CD32}$%s{DEDEDE}\n\nHow many do you want to order?",
		ReturnVehicleModelName ( model ), IntegerWithDelimiter ( wholesale ), DealerStock [ dealerid ] [ cat_index ], room, IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ) ) ;

	inline DealerOrderQty(pid, dialogid, response2, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, listitem

		if ( ! response2 ) {

			return true ;
		}

		// Re-check everything, the player could have walked off or someone could have bought the last car meanwhile.
		new dealer_now = Dealer_GetOwnedHere ( playerid ) ;

		if ( dealer_now != dealerid ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "You must be standing at the dealership you own." ) ;
		}

		new qty = strval ( inputtext ), space = DEALER_MAX_STOCK - DealerStock [ dealerid ] [ cat_index ] ;

		if ( qty < 1 || qty > space ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "Enter a quantity between 1 and %d.", space ) ) ;
		}

		new total = wholesale * qty ;

		if ( ! Dealership_TakeBank ( dealerid, total ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "The dealership bank only has $%s, that order costs $%s.",
				IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ), IntegerWithDelimiter ( total ) ) ) ;
		}

		Dealership_SetStock ( dealerid, cat_index, DealerStock [ dealerid ] [ cat_index ] + qty ) ;

		SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Ordered %d x %s for $%s. You now have %d in stock.",
			qty, ReturnVehicleModelName ( DealershipCars [ cat_index ] [ dealercar_carmodel ] ), IntegerWithDelimiter ( total ), DealerStock [ dealerid ] [ cat_index ] ) ) ;

		AddLogEntry ( playerid, LOG_TYPE_SCRIPT, sprintf ( "Ordered %d x %s for $%d for dealership %s (%d)", qty,
			ReturnVehicleModelName ( DealershipCars [ cat_index ] [ dealercar_carmodel ] ), total, Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ] ) ) ;

		return true ;
	}

	Dialog_ShowCallback ( playerid, using inline DealerOrderQty, DIALOG_STYLE_INPUT, "Order Stock", prompt, "Order", "Cancel" ) ;

	return true ;
}

// /dealerbank - deposit or withdraw from the dealership bank.
CMD:dealerbank(playerid, params[]) {

	new dealerid = Dealer_GetOwnedHere ( playerid ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "You must be standing at the dealership you own." ) ;
	}

	new action [ 16 ], amount ;

	if ( sscanf ( params, "s[16]i", action, amount ) ) {

		SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "Dealership balance: $%s.", IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ) ) ) ;

		return SendServerMessage ( playerid, COLOR_ERROR, "Usage", "A3A3A3", "/dealerbank [deposit/withdraw] [amount]" ) ;
	}

	if ( amount <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "Amount must be greater than 0." ) ;
	}

	if ( ! strcmp ( action, "deposit", true ) ) {

		if ( GetPlayerCash ( playerid ) < amount ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "You don't have $%s in cash.", IntegerWithDelimiter ( amount ) ) ) ;
		}

		TakePlayerCash ( playerid, amount, "Dealership bank deposit" ) ;
		Dealership_AddBank ( dealerid, amount ) ;

		AddLogEntry ( playerid, LOG_TYPE_SCRIPT, sprintf ( "Deposited $%d into dealership %s (%d)", amount, Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ] ), true ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "You deposited $%s. Balance: $%s.", IntegerWithDelimiter ( amount ), IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ) ) ) ;
	}

	if ( ! strcmp ( action, "withdraw", true ) ) {

		if ( ! Dealership_TakeBank ( dealerid, amount ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", sprintf ( "The dealership bank doesn't have that much. Balance: $%s.", IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ) ) ) ;
		}

		GivePlayerCash ( playerid, amount, "Dealership bank withdrawal" ) ;

		AddLogEntry ( playerid, LOG_TYPE_SCRIPT, sprintf ( "Withdrew $%d from dealership %s (%d)", amount, Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ] ), true ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", sprintf ( "You withdrew $%s. Balance: $%s.", IntegerWithDelimiter ( amount ), IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ) ) ) ;
	}

	return SendServerMessage ( playerid, COLOR_ERROR, "Usage", "A3A3A3", "/dealerbank [deposit/withdraw] [amount]" ) ;
}

// /dealerresign - gives up your dealership.
CMD:dealerresign(playerid, params[]) {

	#pragma unused params

	new dealerid = Dealership_GetOwnedBy ( Character [ playerid ] [ E_CHARACTER_ID ] ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Dealership", "A3A3A3", "You don't own a dealership." ) ;
	}

	new prompt [ 320 ] ;

	format ( prompt, sizeof ( prompt ), "{DEDEDE}You are about to give up {ed7f2b}%s{DEDEDE}.\n\nThe remaining stock goes back to the manufacturer and the {32CD32}$%s{DEDEDE} in the dealership bank is paid into your bank account.\n\nThe dealership will be open for new applications.",
		Dealerships [ dealerid ] [ dealership_name ], IntegerWithDelimiter ( Dealerships [ dealerid ] [ dealership_bank ] ) ) ;

	inline DealerResignConfirm(pid, dialogid, response, listitem, string:inputtext[]) {
		#pragma unused pid, dialogid, listitem, inputtext

		if ( ! response ) {

			return true ;
		}

		if ( Dealerships [ dealerid ] [ dealership_owner_char ] != Character [ playerid ] [ E_CHARACTER_ID ] ) {

			return true ;
		}

		AddLogEntry ( playerid, LOG_TYPE_SCRIPT, sprintf ( "Resigned as owner of dealership %s (%d)", Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ] ), true ) ;

		Dealership_Vacate ( dealerid, "resigned" ) ;

		SendServerMessage ( playerid, COLOR_BLUE, "Dealership", "A3A3A3", "You are no longer the owner of the dealership." ) ;

		return true ;
	}

	Dialog_ShowCallback ( playerid, using inline DealerResignConfirm, DIALOG_STYLE_MSGBOX, "Give Up Dealership", prompt, "Give up", "Cancel" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Foreclosure: an owner who stays away for DEALER_INACTIVE_DAYS loses the dealership
// ---------------------------------------------------------------------------------------------

// Records when the owner was last seen.
static Dealership_StampLastSeen(dealerid) {

	Dealerships [ dealerid ] [ dealership_last_seen ] = gettime () ;

	new query [ 128 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE dealerships SET dealer_owner_last_seen = %d WHERE dealer_id = %d",
		Dealerships [ dealerid ] [ dealership_last_seen ], Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

hook ORP_OnLoadCharacter(playerid, character_id)
{
	new dealerid = Dealership_GetOwnedBy ( character_id ) ;

	if ( dealerid != INVALID_DEALERSHIP_ID ) {

		Dealership_StampLastSeen ( dealerid ) ;
		SendClientMessage ( playerid, COLOR_INFO, sprintf ( "[Dealership] You own %s. Use /dealerinfo to check your stock and bank.", Dealerships [ dealerid ] [ dealership_name ] ) ) ;
	}

	return 1 ;
}

hook ORP_OnCloseConnection(playerid, reason)
{
	#pragma unused reason

	if ( IsPlayerLogged ( playerid ) ) {

		new dealerid = Dealership_GetOwnedBy ( Character [ playerid ] [ E_CHARACTER_ID ] ) ;

		if ( dealerid != INVALID_DEALERSHIP_ID ) {

			Dealership_StampLastSeen ( dealerid ) ;
		}
	}

	return 1 ;
}

// Task: takes dealerships from inactive owners.
task Dealership_InactivityCheck[3600000]() {

	new cutoff = gettime () - ( DEALER_INACTIVE_DAYS * 86400 ) ;

	for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

		if ( ! Dealership_IsOwned ( i ) ) {

			continue ;
		}

		new bool: online ;

		foreach ( new p : Player ) {

			if ( IsPlayerLogged ( p ) && Character [ p ] [ E_CHARACTER_ID ] == Dealerships [ i ] [ dealership_owner_char ] ) {

				online = true ;
				break ;
			}
		}

		// Owners who are online right now are, by definition, not inactive.
		if ( online ) {

			Dealership_StampLastSeen ( i ) ;
			continue ;
		}

		if ( Dealerships [ i ] [ dealership_last_seen ] > 0 && Dealerships [ i ] [ dealership_last_seen ] < cutoff ) {

			SendAdminMessage ( sprintf ( "[Dealership] %s has been foreclosed: %s was inactive for over %d days.",
				Dealerships [ i ] [ dealership_name ], Dealerships [ i ] [ dealership_owner_name ], DEALER_INACTIVE_DAYS ), COLOR_YELLOW, false ) ;

			Dealership_Vacate ( i, "foreclosed (owner inactive)" ) ;
		}
	}
}
