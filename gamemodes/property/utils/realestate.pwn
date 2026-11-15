// ============================================================================
// File: property/utils/realestate.pwn
// Real estate firm field: only a real estate firm can buy a house from the server, then sells
// or rents it to players (/firmpropertybuy, /propertylist, /propertytier, /housetiers).
// Commands: /firmpropertybuy /firmdesk /propertylist /housetiers /propertytier /propertyfirm
// ============================================================================

// Real estate firms (FIRM_FIELD_REALESTATE). The ownership model and the house tiers are explained above
// Property_HasAccess in property/data/data.pwn. In short:
//
//  * Houses nobody owns are rentable, and only a real estate firm can buy them from the server, at the
//    house's price (tier price unless an admin set its own): /propertylist shows them, /firmpropertybuy buys.
//  * The firm becomes the landlord. A tenant keeps living there, and the rent they pay each payday goes
//    straight into the firm bank (Paycheck_CalculateRent).
//  * The firm lists a house with /propertyprice [price], between 100% and 200% of what it paid. Players
//    browse them with /propertylist sale and buy one with /propertybuy at the door. That pays the firm.
//  * Firm members need FIRM_PERM_PROPERTIES to manage the properties and FIRM_PERM_BANK as well to buy.
//    Owners and managers have both by default.

#define REALESTATE_BUY_PERMS            (FIRM_PERM_PROPERTIES | FIRM_PERM_BANK)
#define REALESTATE_LIST_PAGE            (40)

static RealEstate_List [ MAX_PLAYERS ] [ REALESTATE_LIST_PAGE ] ;
static RealEstate_ListCount [ MAX_PLAYERS ] ;

// "123 Some Street, Zone" for a property's entrance.
RealEstate_GetAddress(index, output[], len = sizeof ( output )) {

	new address [ 64 ], zone [ 64 ] ;

	GetCoords2DZone ( Property [ index ] [ E_PROPERTY_EXT_X ], Property [ index ] [ E_PROPERTY_EXT_Y ], zone, sizeof ( zone ) ) ;
	GetPlayerAddress ( Property [ index ] [ E_PROPERTY_EXT_X ], Property [ index ] [ E_PROPERTY_EXT_Y ], address ) ;

	return format ( output, len, "%d %s, %s", index, address, zone ) ;
}

// The firm a player can buy and sell properties for: a real estate firm member who has the permissions.
// Returns the firm's enum id or INVALID_FIRM_ID, and tells the player why when they pass notify.
static RealEstate_GetFirm(playerid, perms, bool: notify = true) {

	if ( ! IsPlayerInFirmField ( playerid, FIRM_FIELD_REALESTATE ) ) {

		if ( notify ) SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "Only members of a real estate firm can do this." ) ;
		return INVALID_FIRM_ID ;
	}

	if ( ! Firm_PlayerHasPerm ( playerid, perms ) ) {

		if ( notify ) SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "You don't have permission to manage the firm's properties and bank." ) ;
		return INVALID_FIRM_ID ;
	}

	new firm_enum_id = Firm_GetEnumID ( PlayerFirm [ playerid ] [ E_PLAYER_FIRM_ID ] ) ;

	if ( ! Firm_IsActive ( firm_enum_id ) ) {

		return INVALID_FIRM_ID ;
	}

	return firm_enum_id ;
}

// The price a firm's asking price is measured against: what it paid, or the server price if that isn't known.
static RealEstate_GetBasePrice(index) {

	return ( Property [ index ] [ E_PROPERTY_FIRM_COST ] > 0 ) ? Property [ index ] [ E_PROPERTY_FIRM_COST ] : Property [ index ] [ E_PROPERTY_PRICE ] ;
}

// Puts a property back in the server's hands: tenants stay, the listing and the firm are cleared. refund
// pays the firm back what it paid (used when an admin takes the property away from it).
RealEstate_ReturnToServer(index, bool: refund) {

	new firm_sql_id = Property [ index ] [ E_PROPERTY_FIRM ], cost = Property [ index ] [ E_PROPERTY_FIRM_COST ], query [ 256 ] ;

	if ( refund && firm_sql_id > 0 && cost > 0 ) {

		new firm_enum_id = Firm_GetEnumID ( firm_sql_id ) ;

		if ( Firm_IsValid ( firm_enum_id ) ) {

			Firm_AddBankMoney ( firm_enum_id, cost, sprintf ( "Refund for property %d, taken back by an admin", Property [ index ] [ E_PROPERTY_ID ] ) ) ;
		}
	}

	Property [ index ] [ E_PROPERTY_OWNER ] = INVALID_PROPERTY_OWNER ;
	Property [ index ] [ E_PROPERTY_FIRM ] = 0 ;
	Property [ index ] [ E_PROPERTY_FIRM_PRICE ] = 0 ;
	Property [ index ] [ E_PROPERTY_FIRM_COST ] = 0 ;
	Property [ index ] [ E_PROPERTY_COLLECT ] = 0 ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_owner = %d, property_firm = 0, property_firm_price = 0, property_firm_cost = 0, property_collect = 0 WHERE property_id = %d",
		INVALID_PROPERTY_OWNER, Property [ index ] [ E_PROPERTY_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	Property_SetupVisualEntities ( index ) ;

	return true ;
}

// A real estate firm closed (Firm_Close): every property it owned goes back to the server.
Property_OnFirmClosed(firm_sql_id) {

	RealEstate_RemoveFirmDesk ( firm_sql_id ) ;

	foreach ( new i : Properties ) {

		if ( Property [ i ] [ E_PROPERTY_FIRM ] == firm_sql_id && Property_IsFirmOwned ( i ) ) {

			RealEstate_ReturnToServer ( i, false ) ;
		}
	}

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Firm buys a house from the server
// ---------------------------------------------------------------------------------------------

// /firmpropertybuy - a real estate agent buys a property for their firm.
CMD:firmpropertybuy(playerid, params[]) {

	#pragma unused params

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return true ;
	}

	new firm_enum_id = RealEstate_GetFirm ( playerid, REALESTATE_BUY_PERMS ) ;

	if ( firm_enum_id == INVALID_FIRM_ID ) {

		return true ;
	}

	new index = Property_GetClosestEntity ( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "You're not near a property entrance." ) ;
	}

	if ( Property [ index ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_HOUSE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "Real estate firms only deal in houses." ) ;
	}

	if ( Property [ index ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "Somebody already owns this property." ) ;
	}

	new price = Property [ index ] [ E_PROPERTY_PRICE ] ;

	if ( price <= 0 || Property [ index ] [ E_PROPERTY_TIER ] <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "This property isn't for sale." ) ;
	}

	if ( Firm [ firm_enum_id ] [ E_FIRM_BANK ] < price ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", sprintf ( "The firm bank only has $%s, this house costs $%s.", IntegerWithDelimiter ( Firm [ firm_enum_id ] [ E_FIRM_BANK ] ), IntegerWithDelimiter ( price ) ) ) ;
	}

	new address [ 128 ], tier_name [ 24 ], prompt [ 512 ] ;

	RealEstate_GetAddress ( index, address, sizeof ( address ) ) ;
	Property_GetTierName ( Property [ index ] [ E_PROPERTY_TIER ], tier_name, sizeof ( tier_name ) ) ;

	format ( prompt, sizeof ( prompt ), "{DEDEDE}Buy this house for {ed7f2b}%s{DEDEDE}?\n\n{A3A3A3}Property: {DEDEDE}%s\n{A3A3A3}Type: {DEDEDE}%s\n{A3A3A3}Price: {32CD32}$%s{DEDEDE} (from the firm bank)\n{A3A3A3}Rent: {DEDEDE}$%s per payday\n\nAny tenant keeps their home. You become the landlord and can list it for sale with /propertyprice.",
		Firm [ firm_enum_id ] [ E_FIRM_NAME ], address, tier_name, IntegerWithDelimiter ( price ), IntegerWithDelimiter ( Property [ index ] [ E_PROPERTY_RENT ] ) ) ;

	new sqlid = Property [ index ] [ E_PROPERTY_ID ], firm_sql_id = Firm [ firm_enum_id ] [ E_FIRM_ID ] ;

	inline FirmPropertyBuyConfirm(pid, dialogid, response, listitem, string: inputtext[]) {

		#pragma unused pid, dialogid, listitem, inputtext

		if ( ! response ) {

			return true ;
		}

		// Everything could have changed while the dialog was open.
		if ( Property [ index ] [ E_PROPERTY_ID ] != sqlid || Property [ index ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER || Property [ index ] [ E_PROPERTY_PRICE ] != price ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "That property is no longer available at that price." ) ;
		}

		new firm_now = RealEstate_GetFirm ( playerid, REALESTATE_BUY_PERMS ) ;

		if ( firm_now == INVALID_FIRM_ID || Firm [ firm_now ] [ E_FIRM_ID ] != firm_sql_id ) {

			return true ;
		}

		if ( ! Firm_TakeBankMoney ( firm_now, price, sprintf ( "%s bought property %d (%s) for $%s", ReturnRPName ( playerid ), sqlid, address, IntegerWithDelimiter ( price ) ) ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "The firm bank can't afford it any more." ) ;
		}

		Property [ index ] [ E_PROPERTY_OWNER ] = PROPERTY_OWNER_FIRM ;
		Property [ index ] [ E_PROPERTY_FIRM ] = firm_sql_id ;
		Property [ index ] [ E_PROPERTY_FIRM_COST ] = price ;
		Property [ index ] [ E_PROPERTY_FIRM_PRICE ] = 0 ;
		Property [ index ] [ E_PROPERTY_COLLECT ] = 0 ;

		new query [ 256 ] ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_owner = %d, property_firm = %d, property_firm_cost = %d, property_firm_price = 0, property_collect = 0 WHERE property_id = %d",
			PROPERTY_OWNER_FIRM, firm_sql_id, price, sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		Property_SetupVisualEntities ( index ) ;

		Firm_Log ( firm_sql_id, Character [ playerid ] [ E_CHARACTER_ID ], 4, sprintf ( "Bought property %d (%s) for $%s", sqlid, address, IntegerWithDelimiter ( price ) ) ) ;
		AddLogEntry ( playerid, LOG_TYPE_FIRM, sprintf ( "Bought property %d (%s) for $%d for firm %s", sqlid, address, price, Firm [ firm_now ] [ E_FIRM_NAME ] ) ) ;

		Firm_SendMessage ( firm_sql_id, sprintf ( "[Real Estate] %s bought %s for $%s. It's rented at $%s per payday.", ReturnRPName ( playerid ), address, IntegerWithDelimiter ( price ), IntegerWithDelimiter ( Property [ index ] [ E_PROPERTY_RENT ] ) ) ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", sprintf ( "You bought %s for the firm. List it for sale with /propertyprice [%d-%d].",
			address, price * PROPERTY_RESALE_MIN_PCT / 100, price * PROPERTY_RESALE_MAX_PCT / 100 ) ) ;
	}

	Dialog_ShowCallback ( playerid, using inline FirmPropertyBuyConfirm, DIALOG_STYLE_MSGBOX, "Buy Property", prompt, "Buy", "Cancel" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Firm lists a house for sale: /propertyprice [price] (also the admin /propertyprice [id] [price])
// ---------------------------------------------------------------------------------------------

// Sets the listing price of a firm-owned property.
RealEstate_SetListingPrice(playerid, const params[]) {

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return true ;
	}

	new index = Property_GetClosestEntity ( playerid, PROPERTY_NEAR_ENTER ) ;

	if ( index == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "You're not near a property entrance." ) ;
	}

	if ( Property [ index ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_HOUSE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "Real estate firms only price houses. Business prices are set by staff with /propertyprice [id] [price]." ) ;
	}

	if ( ! Property_IsFirmOwned ( index ) || ! Property_HasAccess ( playerid, index ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "You can only price a property your real estate firm owns, and you need the properties permission." ) ;
	}

	new price, base = RealEstate_GetBasePrice ( index ), min_price = base * PROPERTY_RESALE_MIN_PCT / 100, max_price = base * PROPERTY_RESALE_MAX_PCT / 100 ;

	if ( sscanf ( params, "i", price ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Syntax", "A3A3A3", sprintf ( "/propertyprice [price $%s-$%s, or 0 to take it off sale]", IntegerWithDelimiter ( min_price ), IntegerWithDelimiter ( max_price ) ) ) ;

		return true ;
	}

	if ( price != 0 && ( price < min_price || price > max_price ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", sprintf ( "The asking price has to be between $%s and $%s (100%% to 200%% of what the firm paid).", IntegerWithDelimiter ( min_price ), IntegerWithDelimiter ( max_price ) ) ) ;
	}

	Property [ index ] [ E_PROPERTY_FIRM_PRICE ] = price ;

	new query [ 160 ], address [ 128 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_firm_price = %d WHERE property_id = %d", price, Property [ index ] [ E_PROPERTY_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	Property_SetupVisualEntities ( index ) ;

	RealEstate_GetAddress ( index, address, sizeof ( address ) ) ;

	Firm_Log ( Property [ index ] [ E_PROPERTY_FIRM ], Character [ playerid ] [ E_CHARACTER_ID ], 4, sprintf ( "Set the asking price of property %d (%s) to $%s", Property [ index ] [ E_PROPERTY_ID ], address, IntegerWithDelimiter ( price ) ) ) ;

	if ( price == 0 ) {

		return SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", sprintf ( "%s is no longer for sale.", address ) ) ;
	}

	return SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", sprintf ( "%s is now for sale for $%s. Players can find it with /propertylist sale.", address, IntegerWithDelimiter ( price ) ) ) ;
}

// ---------------------------------------------------------------------------------------------
// A player buys a house a firm listed (called from /propertybuy)
// ---------------------------------------------------------------------------------------------

// Buys a property listed by a real estate firm.
RealEstate_BuyFromFirm(playerid, index) {

	if ( Property [ index ] [ E_PROPERTY_FIRM_PRICE ] <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This property isn't for sale." ) ;
	}

	if ( Player_GetOwnedHouses ( playerid ) >= Player_GetMaxOwnedHouses ( playerid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any house ownership slots left. Use /myslots to check." ) ;
	}

	new price = Property [ index ] [ E_PROPERTY_FIRM_PRICE ] ;

	if ( GetPlayerCash ( playerid ) < price ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf ( "You don't have enough money. You need $%s, you have $%s.", IntegerWithDelimiter ( price ), IntegerWithDelimiter ( GetPlayerCash ( playerid ) ) ) ) ;
	}

	new address [ 128 ], tier_name [ 24 ], firm_name [ 64 ], prompt [ 512 ] ;

	RealEstate_GetAddress ( index, address, sizeof ( address ) ) ;
	Property_GetTierName ( Property [ index ] [ E_PROPERTY_TIER ], tier_name, sizeof ( tier_name ) ) ;
	Firm_GetName ( Property [ index ] [ E_PROPERTY_FIRM ], firm_name, sizeof ( firm_name ) ) ;

	format ( prompt, sizeof ( prompt ), "{DEDEDE}Buy this house from {ed7f2b}%s{DEDEDE}?\n\n{A3A3A3}Property: {DEDEDE}%s\n{A3A3A3}Type: {DEDEDE}%s\n{A3A3A3}Price: {32CD32}$%s\n\n{DEDEDE}If someone is renting it, they stay and you become their landlord.",
		firm_name, address, tier_name, IntegerWithDelimiter ( price ) ) ;

	new sqlid = Property [ index ] [ E_PROPERTY_ID ], firm_sql_id = Property [ index ] [ E_PROPERTY_FIRM ] ;

	inline PropertyBuyFromFirmConfirm(pid, dialogid, response, listitem, string: inputtext[]) {

		#pragma unused pid, dialogid, listitem, inputtext

		if ( ! response ) {

			return true ;
		}

		if ( Property [ index ] [ E_PROPERTY_ID ] != sqlid || ! Property_IsFirmOwned ( index ) || Property [ index ] [ E_PROPERTY_FIRM ] != firm_sql_id || Property [ index ] [ E_PROPERTY_FIRM_PRICE ] != price ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "That property is no longer for sale at that price." ) ;
		}

		if ( Player_GetOwnedHouses ( playerid ) >= Player_GetMaxOwnedHouses ( playerid ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any house ownership slots left. Use /myslots to check." ) ;
		}

		if ( GetPlayerCash ( playerid ) < price ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf ( "You need $%s in cash to buy this house.", IntegerWithDelimiter ( price ) ) ) ;
		}

		TakePlayerCash ( playerid, price, "Property purchase (from real estate firm)" ) ;

		new firm_enum_id = Firm_GetEnumID ( firm_sql_id ), cost = Property [ index ] [ E_PROPERTY_FIRM_COST ] ;

		if ( Firm_IsValid ( firm_enum_id ) ) {

			Firm_AddBankMoney ( firm_enum_id, price, sprintf ( "Sold property %d (%s) to %s for $%s", sqlid, address, ReturnRPName ( playerid ), IntegerWithDelimiter ( price ) ) ) ;
		}

		Property [ index ] [ E_PROPERTY_OWNER ] = Character [ playerid ] [ E_CHARACTER_ID ] ;
		Property [ index ] [ E_PROPERTY_FIRM ] = 0 ;
		Property [ index ] [ E_PROPERTY_FIRM_PRICE ] = 0 ;
		Property [ index ] [ E_PROPERTY_FIRM_COST ] = 0 ;
		Property [ index ] [ E_PROPERTY_COLLECT ] = 0 ;

		new query [ 256 ] ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_owner = %d, property_firm = 0, property_firm_price = 0, property_firm_cost = 0, property_collect = 0 WHERE property_id = %d",
			Character [ playerid ] [ E_CHARACTER_ID ], sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		Property_SetupVisualEntities ( index ) ;

		if ( firm_sql_id > 0 ) {

			Firm_Log ( firm_sql_id, 0, 4, sprintf ( "Sold property %d (%s) to %s for $%s (cost $%s)", sqlid, address, ReturnRPName ( playerid ), IntegerWithDelimiter ( price ), IntegerWithDelimiter ( cost ) ) ) ;
			Firm_SendMessage ( firm_sql_id, sprintf ( "[Real Estate] %s bought %s for $%s. The firm made $%s.", ReturnRPName ( playerid ), address, IntegerWithDelimiter ( price ), IntegerWithDelimiter ( price - cost ) ) ) ;
		}

		AddLogEntry ( playerid, LOG_TYPE_SCRIPT, sprintf ( "Bought property %d (%s) from firm %d for $%d", sqlid, address, firm_sql_id, price ) ) ;

		return SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf ( "You've bought %s for $%s. Type /propertyhelp for commands.", address, IntegerWithDelimiter ( price ) ) ) ;
	}

	Dialog_ShowCallback ( playerid, using inline PropertyBuyFromFirmConfirm, DIALOG_STYLE_MSGBOX, "Buy House", prompt, "Buy", "Cancel" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Firm help desks: each real estate firm has one, /propertylist next to it lists that firm's houses
// ---------------------------------------------------------------------------------------------

#define MAX_REALESTATE_DESKS        (64)
#define INVALID_DESK_ID             (-1)

enum E_RE_DESK_DATA {

	E_RE_DESK_FIRM,         // firm sql id, 0 = unused
	Float: E_RE_DESK_X,
	Float: E_RE_DESK_Y,
	Float: E_RE_DESK_Z,
	E_RE_DESK_INT,
	E_RE_DESK_VW,
	E_RE_DESK_PICKUP,
	DynamicText3D: E_RE_DESK_LABEL
} ;

static RealEstate_Desks [ MAX_REALESTATE_DESKS ] [ E_RE_DESK_DATA ] ;

// Removes the labels and pickups of a real estate desk.
static RealEstate_DestroyDeskVisuals(desk) {

	if ( IsValidDynamicPickup ( RealEstate_Desks [ desk ] [ E_RE_DESK_PICKUP ] ) ) DestroyDynamicPickup ( RealEstate_Desks [ desk ] [ E_RE_DESK_PICKUP ] ) ;
	if ( IsValidDynamic3DTextLabel ( RealEstate_Desks [ desk ] [ E_RE_DESK_LABEL ] ) ) DestroyDynamic3DTextLabel ( RealEstate_Desks [ desk ] [ E_RE_DESK_LABEL ] ) ;

	RealEstate_Desks [ desk ] [ E_RE_DESK_PICKUP ] = INVALID_STREAMER_ID ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_LABEL ] = DynamicText3D: INVALID_STREAMER_ID ;

	return true ;
}

// Creates the labels and pickups of a real estate desk.
static RealEstate_CreateDeskVisuals(desk) {

	RealEstate_DestroyDeskVisuals ( desk ) ;

	new name [ 64 ], text [ 128 ] ;

	Firm_GetName ( RealEstate_Desks [ desk ] [ E_RE_DESK_FIRM ], name, sizeof ( name ) ) ;
	format ( text, sizeof ( text ), "[%s]\n{DEDEDE}Help desk - /propertylist to see our houses for sale and rent", name ) ;

	RealEstate_Desks [ desk ] [ E_RE_DESK_PICKUP ] = CreateDynamicPickup ( 1239, 1, RealEstate_Desks [ desk ] [ E_RE_DESK_X ], RealEstate_Desks [ desk ] [ E_RE_DESK_Y ], RealEstate_Desks [ desk ] [ E_RE_DESK_Z ],
		RealEstate_Desks [ desk ] [ E_RE_DESK_VW ], RealEstate_Desks [ desk ] [ E_RE_DESK_INT ], -1, 30.0 ) ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_LABEL ] = CreateDynamic3DTextLabel ( text, 0x2ECC71FF, RealEstate_Desks [ desk ] [ E_RE_DESK_X ], RealEstate_Desks [ desk ] [ E_RE_DESK_Y ], RealEstate_Desks [ desk ] [ E_RE_DESK_Z ] + 0.5, 8.0,
		.worldid = RealEstate_Desks [ desk ] [ E_RE_DESK_VW ], .interiorid = RealEstate_Desks [ desk ] [ E_RE_DESK_INT ], .testlos = true ) ;

	return true ;
}

// Finds a desk by its firm's SQL id.
static RealEstate_FindDesk(firm_sql_id) {

	for ( new i; i < MAX_REALESTATE_DESKS; i ++ ) {

		if ( RealEstate_Desks [ i ] [ E_RE_DESK_FIRM ] == firm_sql_id && firm_sql_id > 0 ) return i ;
	}

	return INVALID_DESK_ID ;
}

// Returns the desk the player is standing at.
static RealEstate_GetNearbyDesk(playerid) {

	for ( new i; i < MAX_REALESTATE_DESKS; i ++ ) {

		if ( RealEstate_Desks [ i ] [ E_RE_DESK_FIRM ] <= 0 ) continue ;

		if ( GetPlayerVirtualWorld ( playerid ) == RealEstate_Desks [ i ] [ E_RE_DESK_VW ] && GetPlayerInterior ( playerid ) == RealEstate_Desks [ i ] [ E_RE_DESK_INT ]
			&& IsPlayerInRangeOfPoint ( playerid, 3.0, RealEstate_Desks [ i ] [ E_RE_DESK_X ], RealEstate_Desks [ i ] [ E_RE_DESK_Y ], RealEstate_Desks [ i ] [ E_RE_DESK_Z ] ) ) {

			return i ;
		}
	}

	return INVALID_DESK_ID ;
}

// Deletes a real estate desk.
static RealEstate_RemoveDesk(desk) {

	new query [ 96 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM firm_realestate_desks WHERE firm_id = %d", RealEstate_Desks [ desk ] [ E_RE_DESK_FIRM ] ) ;
	mysql_tquery ( mysql, query ) ;

	RealEstate_DestroyDeskVisuals ( desk ) ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_FIRM ] = 0 ;

	return true ;
}

// A closed firm's desk goes with it.
static RealEstate_RemoveFirmDesk(firm_sql_id) {

	new desk = RealEstate_FindDesk ( firm_sql_id ) ;

	if ( desk != INVALID_DESK_ID ) RealEstate_RemoveDesk ( desk ) ;

	return true ;
}

// Loads the real estate desks from the database.
RealEstate_LoadDesks() {

	for ( new i; i < MAX_REALESTATE_DESKS; i ++ ) {

		RealEstate_DestroyDeskVisuals ( i ) ;
		RealEstate_Desks [ i ] [ E_RE_DESK_FIRM ] = 0 ;
	}

	inline RealEstate_OnDesksLoad() {

		for ( new i = 0, r = cache_num_rows(); i < r && i < MAX_REALESTATE_DESKS; i ++ ) {

			cache_get_value_name_int ( i, "firm_id", RealEstate_Desks [ i ] [ E_RE_DESK_FIRM ] ) ;
			cache_get_value_name_float ( i, "desk_x", RealEstate_Desks [ i ] [ E_RE_DESK_X ] ) ;
			cache_get_value_name_float ( i, "desk_y", RealEstate_Desks [ i ] [ E_RE_DESK_Y ] ) ;
			cache_get_value_name_float ( i, "desk_z", RealEstate_Desks [ i ] [ E_RE_DESK_Z ] ) ;
			cache_get_value_name_int ( i, "desk_int", RealEstate_Desks [ i ] [ E_RE_DESK_INT ] ) ;
			cache_get_value_name_int ( i, "desk_vw", RealEstate_Desks [ i ] [ E_RE_DESK_VW ] ) ;

			RealEstate_CreateDeskVisuals ( i ) ;
		}

		printf ( " * [RealEstate] Loaded %d help desks.", cache_num_rows() ) ;
	}

	MySQL_TQueryInline ( mysql, using inline RealEstate_OnDesksLoad, "SELECT * FROM firm_realestate_desks", "" ) ;

	return true ;
}

// /firmdesk [set | remove] [firm abbreviation] - admins (senior and up) put a real estate firm's help desk
// where they're standing, or remove it.
CMD:firmdesk(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command." ) ;
	}

	new action [ 8 ], abbrev [ 8 ] ;

	if ( sscanf ( params, "s[8]s[8]", action, abbrev ) || ( strcmp ( action, "set", true ) && strcmp ( action, "remove", true ) ) ) {

		return SendClientMessage ( playerid, COLOR_GRAD0, "/firmdesk [set | remove] [real estate firm abbreviation] - set puts the firm's help desk where you stand." ) ;
	}

	new bool: remove = ! strcmp ( action, "remove", true ), firm_sql_id, firm_enum_id = INVALID_FIRM_ID ;

	for ( new i; i < MAX_FIRMS; i ++ ) {

		if ( Firm [ i ] [ E_FIRM_ID ] != INVALID_FIRM_ID && ! strcmp ( Firm [ i ] [ E_FIRM_ABBREV ], abbrev, true ) ) {

			firm_enum_id = i ;
			firm_sql_id = Firm [ i ] [ E_FIRM_ID ] ;
		}
	}

	if ( firm_enum_id == INVALID_FIRM_ID || Firm [ firm_enum_id ] [ E_FIRM_FIELD ] != FIRM_FIELD_REALESTATE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "No real estate firm found with that abbreviation." ) ;
	}

	new desk = RealEstate_FindDesk ( firm_sql_id ) ;

	if ( remove ) {

		if ( desk == INVALID_DESK_ID ) return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "That firm doesn't have a help desk." ) ;

		RealEstate_RemoveDesk ( desk ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", "The help desk was removed." ) ;
	}

	if ( desk == INVALID_DESK_ID ) {

		for ( new i; i < MAX_REALESTATE_DESKS; i ++ ) {

			if ( RealEstate_Desks [ i ] [ E_RE_DESK_FIRM ] <= 0 ) {

				desk = i ;
				break ;
			}
		}

		if ( desk == INVALID_DESK_ID ) return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "There are no help desk slots left." ) ;
	}

	new Float: x, Float: y, Float: z, query [ 256 ] ;

	GetPlayerPos ( playerid, x, y, z ) ;

	RealEstate_Desks [ desk ] [ E_RE_DESK_FIRM ] = firm_sql_id ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_X ] = x ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_Y ] = y ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_Z ] = z ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_INT ] = GetPlayerInterior ( playerid ) ;
	RealEstate_Desks [ desk ] [ E_RE_DESK_VW ] = GetPlayerVirtualWorld ( playerid ) ;

	mysql_format ( mysql, query, sizeof ( query ), "REPLACE INTO firm_realestate_desks (firm_id, desk_x, desk_y, desk_z, desk_int, desk_vw) VALUES (%d, %f, %f, %f, %d, %d)",
		firm_sql_id, x, y, z, RealEstate_Desks [ desk ] [ E_RE_DESK_INT ], RealEstate_Desks [ desk ] [ E_RE_DESK_VW ] ) ;
	mysql_tquery ( mysql, query ) ;

	RealEstate_CreateDeskVisuals ( desk ) ;

	return SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", sprintf ( "%s's help desk is here. Anyone standing next to it can use /propertylist to see the firm's houses.", Firm [ firm_enum_id ] [ E_FIRM_NAME ] ) ) ;
}

// ---------------------------------------------------------------------------------------------
// /propertylist
// ---------------------------------------------------------------------------------------------

#define REALESTATE_VIEW_SERVER      (0)     // houses a firm can buy from the server
#define REALESTATE_VIEW_SALE        (1)     // houses firms have listed for sale
#define REALESTATE_VIEW_MINE        (2)     // the firm's own properties

// Shows a list of properties for sale (all, or by one firm).
static RealEstate_ShowList(playerid, view, desk_firm = 0) {

	new string [ 3072 ], address [ 128 ], tier_name [ 24 ], firm_enum_id = INVALID_FIRM_ID ;

	if ( view == REALESTATE_VIEW_MINE ) {

		firm_enum_id = RealEstate_GetFirm ( playerid, FIRM_PERM_PROPERTIES ) ;

		if ( firm_enum_id == INVALID_FIRM_ID ) {

			return true ;
		}
	}

	if ( view == REALESTATE_VIEW_SERVER ) strcat ( string, "Property\tType\tPrice\tRent\n" ) ;
	else if ( view == REALESTATE_VIEW_SALE ) strcat ( string, "Property\tType\tFor sale\tRent\n" ) ;
	else strcat ( string, "Property\tType\tStatus\tRent\n" ) ;

	RealEstate_ListCount [ playerid ] = 0 ;

	foreach ( new i : Properties ) {

		if ( Property [ i ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_HOUSE || RealEstate_ListCount [ playerid ] >= REALESTATE_LIST_PAGE ) {

			continue ;
		}

		switch ( view ) {

			case REALESTATE_VIEW_SERVER: {

				if ( Property [ i ] [ E_PROPERTY_OWNER ] != INVALID_PROPERTY_OWNER || Property [ i ] [ E_PROPERTY_PRICE ] <= 0 || Property [ i ] [ E_PROPERTY_TIER ] <= 0 ) continue ;
			}

			case REALESTATE_VIEW_SALE: {

				if ( ! Property_IsFirmOwned ( i ) || Property [ i ] [ E_PROPERTY_FIRM ] != desk_firm || ( Property [ i ] [ E_PROPERTY_FIRM_PRICE ] <= 0 && Property [ i ] [ E_PROPERTY_RENT ] <= 0 ) ) continue ;
			}

			case REALESTATE_VIEW_MINE: {

				if ( ! Property_IsFirmOwned ( i ) || Property [ i ] [ E_PROPERTY_FIRM ] != Firm [ firm_enum_id ] [ E_FIRM_ID ] ) continue ;
			}
		}

		RealEstate_GetAddress ( i, address, sizeof ( address ) ) ;
		Property_GetTierName ( Property [ i ] [ E_PROPERTY_TIER ], tier_name, sizeof ( tier_name ) ) ;

		switch ( view ) {

			case REALESTATE_VIEW_SERVER: {

				format ( string, sizeof ( string ), "%s%s\t%s\t{52B788}$%s{FFFFFF}\t$%s\n", string, address, tier_name, IntegerWithDelimiter ( Property [ i ] [ E_PROPERTY_PRICE ] ), IntegerWithDelimiter ( Property [ i ] [ E_PROPERTY_RENT ] ) ) ;
			}

			case REALESTATE_VIEW_SALE: {

				new sale [ 24 ] = "-", rent [ 24 ] = "-" ;

				if ( Property [ i ] [ E_PROPERTY_FIRM_PRICE ] > 0 ) format ( sale, sizeof ( sale ), "{52B788}$%s{FFFFFF}", IntegerWithDelimiter ( Property [ i ] [ E_PROPERTY_FIRM_PRICE ] ) ) ;
				if ( Property [ i ] [ E_PROPERTY_RENT ] > 0 ) format ( rent, sizeof ( rent ), "$%s", IntegerWithDelimiter ( Property [ i ] [ E_PROPERTY_RENT ] ) ) ;

				format ( string, sizeof ( string ), "%s%s\t%s\t%s\t%s\n", string, address, tier_name, sale, rent ) ;
			}

			case REALESTATE_VIEW_MINE: {

				new status [ 48 ] ;

				if ( Property [ i ] [ E_PROPERTY_FIRM_PRICE ] > 0 ) format ( status, sizeof ( status ), "For sale $%s", IntegerWithDelimiter ( Property [ i ] [ E_PROPERTY_FIRM_PRICE ] ) ) ;
				else format ( status, sizeof ( status ), "Rented out (paid $%s)", IntegerWithDelimiter ( Property [ i ] [ E_PROPERTY_FIRM_COST ] ) ) ;

				format ( string, sizeof ( string ), "%s%s\t%s\t%s\t$%s\n", string, address, tier_name, status, IntegerWithDelimiter ( Property [ i ] [ E_PROPERTY_RENT ] ) ) ;
			}
		}

		RealEstate_List [ playerid ] [ RealEstate_ListCount [ playerid ] ++ ] = i ;
	}

	if ( ! RealEstate_ListCount [ playerid ] ) {

		switch ( view ) {

			case REALESTATE_VIEW_SERVER: SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", "There are no houses available from the server right now." ) ;
			case REALESTATE_VIEW_SALE: SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", "This firm has no houses for sale or rent right now." ) ;
			default: SendServerMessage ( playerid, COLOR_BLUE, "Real Estate", "A3A3A3", "Your firm doesn't own any properties yet." ) ;
		}

		return true ;
	}

	inline RealEstateList(pid, dialogid, response, listitem, string: inputtext[]) {

		#pragma unused pid, dialogid, inputtext

		if ( ! response || listitem < 0 || listitem >= RealEstate_ListCount [ playerid ] ) {

			return true ;
		}

		new index = RealEstate_List [ playerid ] [ listitem ], where [ 128 ] ;

		RealEstate_GetAddress ( index, where, sizeof ( where ) ) ;

		GPS_MarkLocation ( playerid, sprintf ( "~y~%s~w~ has been marked on your ~r~minimap~w~.", where ), E_GPS_COLOR_SCRIPT,
			Property [ index ] [ E_PROPERTY_EXT_X ], Property [ index ] [ E_PROPERTY_EXT_Y ], Property [ index ] [ E_PROPERTY_EXT_Z ] ) ;

		return true ;
	}

	new title [ 48 ] ;

	switch ( view ) {

		case REALESTATE_VIEW_SERVER: format ( title, sizeof ( title ), "Houses you can buy" ) ;
		case REALESTATE_VIEW_SALE: Firm_GetName ( desk_firm, title, sizeof ( title ) ) ;
		default: format ( title, sizeof ( title ), "%s properties", Firm [ firm_enum_id ] [ E_FIRM_ABBREV ] ) ;
	}

	Dialog_ShowCallback ( playerid, using inline RealEstateList, DIALOG_STYLE_TABLIST_HEADERS, title, string, "Mark on map", "Close" ) ;

	return true ;
}

// /propertylist - shows the properties listed for sale.
CMD:propertylist(playerid, params[]) {

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return true ;
	}

	if ( ! strcmp ( params, "mine", true ) ) {

		return RealEstate_ShowList ( playerid, REALESTATE_VIEW_MINE ) ;
	}

	// At a firm's help desk: that firm's houses for sale and rent, for everybody.
	new desk = RealEstate_GetNearbyDesk ( playerid ) ;

	if ( desk != INVALID_DESK_ID ) {

		return RealEstate_ShowList ( playerid, REALESTATE_VIEW_SALE, RealEstate_Desks [ desk ] [ E_RE_DESK_FIRM ] ) ;
	}

	// An agent away from a desk sees what the server has for the firm to buy.
	if ( IsPlayerInFirmField ( playerid, FIRM_FIELD_REALESTATE ) && Firm_PlayerHasPerm ( playerid, FIRM_PERM_PROPERTIES ) ) {

		SendClientMessage ( playerid, COLOR_GRAD0, "/propertylist mine shows your firm's properties. At a help desk it lists that firm's houses for sale and rent." ) ;

		return RealEstate_ShowList ( playerid, REALESTATE_VIEW_SERVER ) ;
	}

	return SendServerMessage ( playerid, COLOR_ERROR, "Real Estate", "A3A3A3", "Visit a real estate office's help desk to browse the houses it has for sale and rent." ) ;
}

// ---------------------------------------------------------------------------------------------
// Admin: /propertytier and /propertyfirm
// ---------------------------------------------------------------------------------------------

// What each house tier number means, for staff setting tiers and anyone buying, selling or renting.
CMD:housetiers(playerid, params[]) {

	new text [ 1024 ], tier_name [ 24 ] ;

	format ( text, sizeof ( text ), "Tier\tType\tFirm pays the server\tPrice range\tRent range" ) ;

	for ( new tier = 1 ; tier <= PROPERTY_MAX_TIER ; tier ++ ) {

		Property_GetTierName ( tier, tier_name, sizeof ( tier_name ) ) ;

		format ( text, sizeof ( text ), "%s\n%d\t%s\t$%s\t$%s - $%s\t$%s - $%s", text, tier, tier_name,
			IntegerWithDelimiter ( Property_GetTierPrice ( tier ) ),
			IntegerWithDelimiter ( Property_GetTierMinPrice ( tier ) ), IntegerWithDelimiter ( Property_GetTierMaxPrice ( tier ) ),
			IntegerWithDelimiter ( Property_GetTierMinRent ( tier ) ), IntegerWithDelimiter ( Property_GetTierMaxRent ( tier ) ) ) ;
	}

	// Kept out of the list: a long line in a tab list stretches the first column and pushes the others off the dialog.
	SendServerMessage ( playerid, COLOR_INFO, "House Tiers", "A3A3A3", "A firm buys a house from the server at the first price shown." ) ;
	SendServerMessage ( playerid, COLOR_INFO, "House Tiers", "A3A3A3", "The price range is what a house of that tier can be sold for. Rent is per payday." ) ;

	inline HouseTiersClosed(pid, dialogid, response, listitem, string: inputtext[]) {

		#pragma unused pid, dialogid, response, listitem, inputtext
	}

	Dialog_ShowCallback ( playerid, using inline HouseTiersClosed, DIALOG_STYLE_TABLIST_HEADERS, "House tiers", text, "Close", "" ) ;

	return true ;
}

// /propertytier [id] [tier] - sets the tier of a house.
CMD:propertytier(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command." ) ;
	}

	new id, tier ;

	if ( sscanf ( params, "ii", id, tier ) || tier < 0 || tier > PROPERTY_MAX_TIER ) {

		SendClientMessage ( playerid, COLOR_GRAD0, "/propertytier [id] [tier 0-5]. 0 clears the tier. /housetiers shows what each tier means." ) ;

		SendClientMessage ( playerid, COLOR_GRAD0, "On a house nobody owns this also sets the price a firm pays and the rent to the tier's default." ) ;
		return SendClientMessage ( playerid, COLOR_GRAD0, "Tier 0 on a vacant house makes it unbuyable and unrentable." ) ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES || Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered." ) ;
	}

	if ( Property [ id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_HOUSE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Only houses have tiers." ) ;
	}

	Property [ id ] [ E_PROPERTY_TIER ] = tier ;

	new query [ 192 ], tier_name [ 24 ] ;

	Property_GetTierName ( tier, tier_name, sizeof ( tier_name ) ) ;

	if ( tier > 0 && Property [ id ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER ) {

		Property [ id ] [ E_PROPERTY_PRICE ] = Property_GetTierPrice ( tier ) ;
		Property [ id ] [ E_PROPERTY_RENT ] = Property_GetTierDefaultRent ( tier ) ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_tier = %d, property_price = %d, property_rent = %d WHERE property_id = %d",
			tier, Property [ id ] [ E_PROPERTY_PRICE ], Property [ id ] [ E_PROPERTY_RENT ], Property [ id ] [ E_PROPERTY_ID ] ) ;
	}

	else if ( tier == 0 && Property [ id ] [ E_PROPERTY_OWNER ] == INVALID_PROPERTY_OWNER ) {

		// No tier on a vacant house means nobody can buy or rent it.
		Property [ id ] [ E_PROPERTY_RENT ] = 0 ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_tier = 0, property_rent = 0 WHERE property_id = %d", Property [ id ] [ E_PROPERTY_ID ] ) ;
	}

	else {

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_tier = %d WHERE property_id = %d", tier, Property [ id ] [ E_PROPERTY_ID ] ) ;
	}

	mysql_tquery ( mysql, query ) ;

	AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set the tier of property %d (SQL %d) to %d (%s)", id, Property [ id ] [ E_PROPERTY_ID ], tier, tier_name ) ) ;

	return SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf ( "Property %d is now tier %d (%s). Price $%s, rent $%s.", id, tier, tier_name,
		IntegerWithDelimiter ( Property [ id ] [ E_PROPERTY_PRICE ] ), IntegerWithDelimiter ( Property [ id ] [ E_PROPERTY_RENT ] ) ) ) ;
}

// /propertyfirm [id] [firm] - assigns a property to a real estate firm.
CMD:propertyfirm(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command." ) ;
	}

	new id, abbrev [ MAX_FIRM_ABBREV ] ;

	if ( sscanf ( params, "is[8]", id, abbrev ) ) {

		return SendClientMessage ( playerid, COLOR_GRAD0, "/propertyfirm [id] [real estate firm abbreviation | none]" ) ;
	}

	if ( id < 0 || id >= MAX_PROPERTIES || Property [ id ] [ E_PROPERTY_ID ] == INVALID_PROPERTY_ID ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid property ID entered." ) ;
	}

	if ( Property [ id ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_HOUSE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Only houses can belong to a real estate firm." ) ;
	}

	if ( ! strcmp ( abbrev, "none", true ) ) {

		if ( ! Property_IsFirmOwned ( id ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "No firm owns that property." ) ;
		}

		RealEstate_ReturnToServer ( id, false ) ;

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Took property %d (SQL %d) away from its real estate firm", id, Property [ id ] [ E_PROPERTY_ID ] ) ) ;

		return SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf ( "Property %d is back with the server.", id ) ) ;
	}

	new firm_enum_id = INVALID_FIRM_ID ;

	for ( new i; i < MAX_FIRMS; i ++ ) {

		if ( Firm [ i ] [ E_FIRM_ID ] != INVALID_FIRM_ID && ! strcmp ( Firm [ i ] [ E_FIRM_ABBREV ], abbrev, true ) ) {

			firm_enum_id = i ;
			break ;
		}
	}

	if ( firm_enum_id == INVALID_FIRM_ID || Firm [ firm_enum_id ] [ E_FIRM_FIELD ] != FIRM_FIELD_REALESTATE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "No real estate firm found with that abbreviation." ) ;
	}

	if ( Property [ id ] [ E_PROPERTY_OWNER ] > 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "A player owns that property. Use /propertyauction to refund them first." ) ;
	}

	Property [ id ] [ E_PROPERTY_OWNER ] = PROPERTY_OWNER_FIRM ;
	Property [ id ] [ E_PROPERTY_FIRM ] = Firm [ firm_enum_id ] [ E_FIRM_ID ] ;
	Property [ id ] [ E_PROPERTY_FIRM_COST ] = Property [ id ] [ E_PROPERTY_PRICE ] ;
	Property [ id ] [ E_PROPERTY_FIRM_PRICE ] = 0 ;

	new query [ 256 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE properties SET property_owner = %d, property_firm = %d, property_firm_cost = %d, property_firm_price = 0 WHERE property_id = %d",
		PROPERTY_OWNER_FIRM, Property [ id ] [ E_PROPERTY_FIRM ], Property [ id ] [ E_PROPERTY_FIRM_COST ], Property [ id ] [ E_PROPERTY_ID ] ) ;
	mysql_tquery ( mysql, query ) ;

	Property_SetupVisualEntities ( id ) ;

	AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Gave property %d (SQL %d) to real estate firm %s", id, Property [ id ] [ E_PROPERTY_ID ], Firm [ firm_enum_id ] [ E_FIRM_NAME ] ) ) ;

	return SendServerMessage ( playerid, COLOR_PROPERTY, "Property", "A3A3A3", sprintf ( "Property %d now belongs to %s [%s]. They count it as bought at $%s.", id, Firm [ firm_enum_id ] [ E_FIRM_NAME ], Firm [ firm_enum_id ] [ E_FIRM_ABBREV ], IntegerWithDelimiter ( Property [ id ] [ E_PROPERTY_FIRM_COST ] ) ) ) ;
}
