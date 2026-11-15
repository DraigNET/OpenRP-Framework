// ============================================================================
// File: drugs/cartel/player.pwn
// Passing drug supplies between members of the same faction (/drugsupplies, /passsupply) so
// growers and cooks can be supplied.
// Commands: /drugsupplies /passsupply /passsupplies /passdrugsupplies
// ============================================================================

// /drugsupplies - lists the drug supplies you carry (weed, cocaine, crack, meth).
CMD:drugsupplies(playerid, params[]) {

	new weed_string [ 64 ], coke_string [ 64 ], crack_string [ 64 ], meth_string [ 64 ] ;
	new index, weed_count, coke_count, crack_count, meth_count ;

	SendClientMessage(playerid, COLOR_DRUGS, "List of owned drug supplies." ) ;

	for ( new i, j = 3 ; i < j ; i ++ ) {

		if ( Character [ playerid ] [ E_CHARACTER_WEED_SUPPLIES ] [ i ] ) {
			index = Character [ playerid ] [ E_CHARACTER_WEED_SUPPLIES ] [ i ] ;

			if ( weed_count ) {
				format(weed_string, sizeof ( weed_string ), "%s, (%d) %s", weed_string, i, Weed [ index ] [ E_WEED_NAME ] ) ;
			}
			else format(weed_string, sizeof ( weed_string ), "%s(%d) %s", weed_string, i, Weed [ index ] [ E_WEED_NAME ] ) ;

			weed_count ++ ;
		}

		if ( Character [ playerid ] [ E_CHARACTER_COKE_SUPPLIES ] [ i ] ) {
			index = Character [ playerid ] [ E_CHARACTER_COKE_SUPPLIES ] [ i ] ;

			if ( coke_count ) {
				format(coke_string, sizeof ( coke_string ), "%s, (%d) %s", coke_string, i, Cocaine [ index ] [ E_COKE_NAME ] ) ;
			}
			else format(coke_string, sizeof ( coke_string ), "%s(%d) %s", coke_string, i, Cocaine [ index ] [ E_COKE_NAME ] ) ;
			coke_count ++ ;
		}

		if ( Character [ playerid ] [ E_CHARACTER_CRACK_SUPPLIES ] [ i ] ) {
			index = Character [ playerid ] [ E_CHARACTER_CRACK_SUPPLIES ] [ i ] ;

			if ( crack_count ) {
				format(crack_string, sizeof ( crack_string ), "%s, (%d) %s", crack_string, i, Crack [ index ] [ E_CRACK_NAME ] ) ;
			}
			else format(crack_string, sizeof ( crack_string ), "%s(%d) %s", crack_string, i, Crack [ index ] [ E_CRACK_NAME ] ) ;
			crack_count ++ ;
		}

		if ( Character [ playerid ] [ E_CHARACTER_METH_SUPPLIES ] [ i ] ) {
			index = Character [ playerid ] [ E_CHARACTER_METH_SUPPLIES ] [ i ] ;

			if ( meth_count ) {
				format(meth_string, sizeof ( meth_string ), "%s, (%d) %s", i, meth_string ) ;
			}
			else format(meth_string, sizeof ( meth_string ), "%s(%d) %s", i, meth_string ) ;
			meth_count ++ ;
		}
	}

	if ( ! weed_count ) {
		format ( weed_string, sizeof ( weed_string ), "None" ) ;
	}
	if ( ! coke_count ) {
		format ( coke_string, sizeof ( coke_string ), "None" ) ;
	}
	if ( ! crack_count ) {
		format ( crack_string, sizeof ( crack_string ), "None" ) ;
	}
	if ( ! meth_count ) {
		format ( meth_string, sizeof ( meth_string ), "None" ) ;
	}

	new string [ 512 ] ;

	format ( string, sizeof ( string ), "[WEED SUPPLIES]:{A3A3A3} %s", weed_string ) ;
	SendClientMessage(playerid, 0x539849FF, string ) ;


	format ( string, sizeof ( string ), "[COKE SUPPLIES]:{A3A3A3} %s", coke_string ) ;
	SendClientMessage(playerid, 0xC8D8E3FF, string ) ;

	format ( string, sizeof ( string ), "[CRACK SUPPLIES]:{A3A3A3} %s", crack_string ) ;
	SendClientMessage(playerid, 0xAF7C5BFF, string ) ;

	format ( string, sizeof ( string ), "[METH SUPPLIES]:{A3A3A3} %s", meth_string ) ;
	SendClientMessage(playerid, 0x4198C0FF, string ) ;

	return true ;
}


// Hands one of your seeds/powders (see /drugsupplies) to a member of your own faction. Supplies can only be
// bought by faction leaders and Street Bosses, so this is how they get them to the people who grow and cook.
static Drugs_GetSupplyName(type, param, name[], size = sizeof(name)) {

	switch ( type ) {
		case E_DRUG_TYPE_WEED:  format ( name, size, "%s", Weed [ param ] [ E_WEED_NAME ] ) ;
		case E_DRUG_TYPE_COKE:  format ( name, size, "%s", Cocaine [ param ] [ E_COKE_NAME ] ) ;
		case E_DRUG_TYPE_CRACK: format ( name, size, "%s", Crack [ param ] [ E_CRACK_NAME ] ) ;
		default:                format ( name, size, "supply" ) ;
	}
	return true ;
}

CMD:passsupply(playerid, params[]) return cmd_passdrugsupplies(playerid, params) ;
CMD:passsupplies(playerid, params[]) return cmd_passdrugsupplies(playerid, params) ;

// /passdrugsupplies [player] [type] [slot] - hands a supply to a member of your faction.
CMD:passdrugsupplies(playerid, params[]) {

	new targetid, input [ 32 ], slot ;

	if ( sscanf ( params, "k<player>s[32]i", targetid, input, slot ) ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "/passdrugsupplies [player] [weed/coke/crack/meth] [slot] (/drugsupplies)" ) ;
	}

	if ( slot < 0 || slot > 2 ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Slot can't be less than 0 or more than 2." ) ;
	}

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You can't do this right now." ) ;
	}

	if ( ! IsPlayerConnected ( targetid ) || ! IsPlayerPlaying ( targetid ) ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Target isn't connected." ) ;
	}

	if ( targetid == playerid ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You can't pass supplies to yourself." ) ;
	}

	if ( PlayerVar [ targetid ] [ E_PLAYER_IS_SPECTATING ] == playerid || ! IsPlayerNearPlayer ( playerid, targetid, 3.0 ) ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You're not near your target." ) ;
	}

	if ( ! Character [ playerid ] [ E_CHARACTER_FACTIONID ] || Character [ playerid ] [ E_CHARACTER_FACTIONID ] != Character [ targetid ] [ E_CHARACTER_FACTIONID ] ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You can only pass supplies to a member of your own faction." ) ;
	}

	new type, param ;

	if ( ! strcmp ( input, "weed", true ) )       type = E_DRUG_TYPE_WEED ;
	else if ( ! strcmp ( input, "coke", true ) )  type = E_DRUG_TYPE_COKE ;
	else if ( ! strcmp ( input, "crack", true ) ) type = E_DRUG_TYPE_CRACK ;
	else if ( ! strcmp ( input, "meth", true ) )  type = E_DRUG_TYPE_METH ;
	else {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Supply type must be weed, coke, crack or meth." ) ;
	}

	switch ( type ) {
		case E_DRUG_TYPE_WEED:  param = Character [ playerid ] [ E_CHARACTER_WEED_SUPPLIES ] [ slot ] ;
		case E_DRUG_TYPE_COKE:  param = Character [ playerid ] [ E_CHARACTER_COKE_SUPPLIES ] [ slot ] ;
		case E_DRUG_TYPE_CRACK: param = Character [ playerid ] [ E_CHARACTER_CRACK_SUPPLIES ] [ slot ] ;
		case E_DRUG_TYPE_METH:  param = Character [ playerid ] [ E_CHARACTER_METH_SUPPLIES ] [ slot ] ;
	}

	if ( ! param ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You have no supply in that slot. Check /drugsupplies." ) ;
	}

	new target_slot = Drugs_GetSupplySlot ( targetid, type ) ;

	if ( target_slot == INVALID_DRUG_ID ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Your target has no free slot left for this supply type!" ) ;
	}

	switch ( type ) {
		case E_DRUG_TYPE_WEED: {
			Character [ targetid ] [ E_CHARACTER_WEED_SUPPLIES ] [ target_slot ] = param ;
			Character [ playerid ] [ E_CHARACTER_WEED_SUPPLIES ] [ slot ] = 0 ;
		}
		case E_DRUG_TYPE_COKE: {
			Character [ targetid ] [ E_CHARACTER_COKE_SUPPLIES ] [ target_slot ] = param ;
			Character [ playerid ] [ E_CHARACTER_COKE_SUPPLIES ] [ slot ] = 0 ;
		}
		case E_DRUG_TYPE_CRACK: {
			Character [ targetid ] [ E_CHARACTER_CRACK_SUPPLIES ] [ target_slot ] = param ;
			Character [ playerid ] [ E_CHARACTER_CRACK_SUPPLIES ] [ slot ] = 0 ;
		}
		case E_DRUG_TYPE_METH: {
			Character [ targetid ] [ E_CHARACTER_METH_SUPPLIES ] [ target_slot ] = param ;
			Character [ playerid ] [ E_CHARACTER_METH_SUPPLIES ] [ slot ] = 0 ;
		}
	}

	new supply_name [ 32 ] ;
	Drugs_GetSupplyName ( type, param, supply_name ) ;

	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", sprintf("has passed %s some supplies.", ReturnRPName ( targetid )), .annonated=true);

	AddLogEntry(playerid, LOG_TYPE_DRUGS, sprintf("Passed %s a drug supply (%s, slot %d -> %d).", ReturnRPName ( targetid ), supply_name, slot, target_slot ) ) ;

	SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("You passed your %s to %s.", supply_name, ReturnRPName ( targetid )) ) ;
	SendServerMessage ( targetid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("%s passed you a %s. Check /drugsupplies.", ReturnRPName ( playerid ), supply_name) ) ;

	Drugs_SavePlayerSupplies ( playerid ) ;
	Drugs_SavePlayerSupplies ( targetid ) ;

	return true ;
}
