// ============================================================================
// File: firm/jobs/usedcars.pwn
// Used-car firm field: buy scrapped cars from the scrapyard pool (/usedpool), stock a lot
// (/firmsetslots) and sell to players (/usedcar, /buyusedcar).
// Commands: /usedpool /usedcar /buyusedcar /firmsetslots
// ============================================================================

// Used car firms (FIRM_FIELD_USEDCARS). Players start one like any other firm and then stock a lot:
//
//  * Buy from the scrapyard pool: cars players scrap (/carscrap) wait in a pool until a used car firm
//    buys them for what the scrapper was paid (/usedpool at a scrapyard). See carscrap.pwn.
//  * Buy from a player: /carsell to a firm member, who chooses to buy for the firm or for themselves
//    (see /carsell in vehicle/data/cmds/owner.pwn, which calls UsedCars_BuyCarForFirm).
//  * Lot cars are ordinary firm vehicles (E_VEHICLE_TYPE_FIRM): only members can drive them and they
//    stay where /usedcar park left them. /usedcar price puts one on sale with a floating label.
//  * Customers walk up to a car on sale, find its vehicle id with /dl and use /buyusedcar [vehicle id]. The money goes to the firm bank and the
//    car becomes theirs (E_VEHICLE_TYPE_PLAYER).
//
// Every purchase needs both FIRM_PERM_VEHICLES and FIRM_PERM_BANK.

#define USEDCARS_PERMS              (FIRM_PERM_VEHICLES | FIRM_PERM_BANK)
#define USEDCARS_SALE_MIN_PCT       (30)    // lowest asking price, as a % of the new price
#define USEDCARS_SALE_MAX_PCT       (100)   // highest asking price, as a % of the new price
#define USEDCARS_ALERT_PCT          (100)   // admins are told when a firm pays more than this % of the new price
#define USEDCARS_POOL_PAGE          (25)
#define USEDCARS_SALE_RANGE         (6.0)   // how close a customer has to be to a car to buy it

static DynamicText3D: UsedCars_Label [ MAX_VEHICLES ] ;
static UsedCars_LabelVeh [ MAX_VEHICLES ] ;

static UsedPool_List [ MAX_PLAYERS ] [ USEDCARS_POOL_PAGE ] ;
static UsedPool_Count [ MAX_PLAYERS ] ;

// ---------------------------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------------------------

// Member of a used car firm with the vehicles and bank permissions, i.e. allowed to spend firm money on cars.
UsedCars_CanBuyForFirm(playerid) {

	if ( ! IsPlayerInFirmField ( playerid, FIRM_FIELD_USEDCARS ) ) {

		return 0 ;
	}

	if ( ! Firm_PlayerHasPerm ( playerid, USEDCARS_PERMS ) ) {

		return 0 ;
	}

	return 1 ;
}

// Returns how many vehicles a used-car firm currently has on its lot.
UsedCars_CountVehicles(firm_sql_id) {

	new count ;

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( Vehicle [ i ] [ E_VEHICLE_SQLID ] != -1 && Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FIRM && Vehicle [ i ] [ E_VEHICLE_OWNER ] == firm_sql_id ) {

			count ++ ;
		}
	}

	return count ;
}

// The buyer's firm bank balance and how many more cars its lot can take (used by /carsell).
UsedCars_GetFirmStatus(playerid, &funds, &room) {

	new firm_enum_id = Firm_GetEnumID ( PlayerFirm [ playerid ] [ E_PLAYER_FIRM_ID ] ) ;

	funds = 0 ;
	room = 0 ;

	if ( ! Firm_IsValid ( firm_enum_id ) ) {

		return 0 ;
	}

	funds = Firm [ firm_enum_id ] [ E_FIRM_BANK ] ;
	room = Firm [ firm_enum_id ] [ E_FIRM_VEHICLE_SLOTS ] - UsedCars_CountVehicles ( Firm [ firm_enum_id ] [ E_FIRM_ID ] ) ;

	return 1 ;
}

// Writes the name of the firm the player is working for.
UsedCars_GetFirmName(playerid, name[], len) {

	return Firm_GetName ( PlayerFirm [ playerid ] [ E_PLAYER_FIRM_ID ], name, len ) ;
}

// The lowest and highest asking price allowed for a model: a share of its new price. Models no
// dealership sells have no reference price so they get a wide fixed range.
UsedCars_GetPriceRange(modelid, &min_price, &max_price) {

	new catalog = Vehicle_GetCatalogPrice ( modelid ) ;

	if ( catalog <= 0 ) {

		min_price = 100 ;
		max_price = 500000 ;

		return 0 ;
	}

	min_price = catalog * USEDCARS_SALE_MIN_PCT / 100 ;
	max_price = catalog * USEDCARS_SALE_MAX_PCT / 100 ;

	return catalog ;
}

// Writes a used-car firm log entry.
static UsedCars_Log(firm_sql_id, character_id, const text[]) {

	return Firm_Log ( firm_sql_id, character_id, 3, text ) ;
}

// Saves where a lot car is now, so it is still there after a restart.
static UsedCars_SavePosition(veh_enum_id, interior) {

	new vehicleid = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Float: x, Float: y, Float: z, Float: a, query [ 320 ] ;

	if ( ! IsValidVehicle ( vehicleid ) ) {

		return false ;
	}

	GetVehiclePos ( vehicleid, x, y, z ) ;
	GetVehicleZAngle ( vehicleid, a ) ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ] = x ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ] = y ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ] = z ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ] = a ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ] = GetVehicleVirtualWorld ( vehicleid ) ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ] = interior ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE vehicles SET vehicle_pos_x = '%f', vehicle_pos_y = '%f', vehicle_pos_z = '%f', vehicle_pos_a = '%f', vehicle_vw = %d, vehicle_int = %d WHERE vehicle_sqlid = %d",
		x, y, z, a, Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ], Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// Saves a vehicle's ownership after it moves to or from a used-car firm.
static UsedCars_SaveOwnership(veh_enum_id) {

	new query [ 256 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE vehicles SET vehicle_type = %d, vehicle_owner = %d, vehicle_sale_price = %d, vehicle_pooled_at = %d, vehicle_pool_value = %d, vehicle_fuel = %d WHERE vehicle_sqlid = %d",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// For sale labels
// ---------------------------------------------------------------------------------------------

// Updates the 3D label that shows a lot car's price.
UsedCars_UpdateLabel(veh_enum_id) {

	if ( IsValidDynamic3DTextLabel ( UsedCars_Label [ veh_enum_id ] ) ) {

		DestroyDynamic3DTextLabel ( UsedCars_Label [ veh_enum_id ] ) ;
	}

	UsedCars_Label [ veh_enum_id ] = DynamicText3D: INVALID_STREAMER_ID ;
	UsedCars_LabelVeh [ veh_enum_id ] = INVALID_VEHICLE_ID ;

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] == -1 || Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FIRM || Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] <= 0 ) {

		return false ;
	}

	new vehicleid = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], text [ 160 ] ;

	if ( ! IsValidVehicle ( vehicleid ) ) {

		return false ;
	}

	format ( text, sizeof ( text ), "{2ECC71}FOR SALE\n{FFFFFF}%s\n{32CD32}$%s\n{A3A3A3}%s miles {DEDEDE}| /buyusedcar [id]",
		ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ), IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] ), IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ) ) ;

	UsedCars_Label [ veh_enum_id ] = CreateDynamic3DTextLabel ( text, 0xFFFFFFFF, 0.0, 0.0, 1.4, 12.0, INVALID_PLAYER_ID, vehicleid, 1, -1, -1, -1 ) ;
	UsedCars_LabelVeh [ veh_enum_id ] = vehicleid ;

	return true ;
}

// Vehicles are loaded and respawned from several places, so rather than hook them all the labels are
// reconciled every few seconds.
task UsedCars_LabelSync[10000]() {

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		new bool: has = IsValidDynamic3DTextLabel ( UsedCars_Label [ i ] ) ;

		new bool: wants = Vehicle [ i ] [ E_VEHICLE_SQLID ] != -1 && Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FIRM
			&& Vehicle [ i ] [ E_VEHICLE_SALE_PRICE ] > 0 && IsValidVehicle ( Vehicle [ i ] [ E_VEHICLE_ID ] ) ;

		if ( wants && ( ! has || UsedCars_LabelVeh [ i ] != Vehicle [ i ] [ E_VEHICLE_ID ] ) ) {

			UsedCars_UpdateLabel ( i ) ;
		}

		else if ( ! wants && has ) {

			UsedCars_UpdateLabel ( i ) ;
		}
	}
}

// ---------------------------------------------------------------------------------------------
// Buying a car from a player for the firm (called from /carsell)
// ---------------------------------------------------------------------------------------------

// The seller (sellerid) is selling the vehicle to the firm of buyerid. Returns true when it went through.
UsedCars_BuyCarForFirm(sellerid, buyerid, veh_enum_id, price) {

	if ( ! UsedCars_CanBuyForFirm ( buyerid ) ) {

		SendServerMessage ( buyerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You need the vehicles and bank permissions in a used car firm to buy for it." ) ;
		return false ;
	}

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] == -1 || Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_PLAYER
		|| Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != Character [ sellerid ] [ E_CHARACTER_ID ] ) {

		SendServerMessage ( buyerid, COLOR_ERROR, "Used Cars", "A3A3A3", "That vehicle is no longer for sale." ) ;
		return false ;
	}

	new firm_enum_id = Firm_GetEnumID ( PlayerFirm [ buyerid ] [ E_PLAYER_FIRM_ID ] ) ;

	if ( ! Firm_IsActive ( firm_enum_id ) ) {

		return false ;
	}

	new firm_sql_id = Firm [ firm_enum_id ] [ E_FIRM_ID ] ;

	if ( UsedCars_CountVehicles ( firm_sql_id ) >= Firm [ firm_enum_id ] [ E_FIRM_VEHICLE_SLOTS ] ) {

		SendServerMessage ( buyerid, COLOR_ERROR, "Used Cars", "A3A3A3", "Your firm's lot is full. Sell a car or ask an admin for more vehicle slots." ) ;
		return false ;
	}

	new model_name [ 32 ] ;
	format ( model_name, sizeof ( model_name ), "%s", ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ) ) ;

	if ( ! Firm_TakeBankMoney ( firm_enum_id, price, sprintf ( "%s bought a %s from %s for $%s", ReturnRPName ( buyerid ), model_name, ReturnRPName ( sellerid ), IntegerWithDelimiter ( price ) ) ) ) {

		SendServerMessage ( buyerid, COLOR_ERROR, "Used Cars", "A3A3A3", sprintf ( "The firm bank only has $%s.", IntegerWithDelimiter ( Firm [ firm_enum_id ] [ E_FIRM_BANK ] ) ) ) ;
		return false ;
	}

	new vehicleid = Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], interior = GetPlayerInterior ( sellerid ) ;

	// Get the seller out first, a locked firm car shouldn't strand them in the driver's seat.
	JT_RemovePlayerFromVehicle ( sellerid ) ;
	GivePlayerCash ( sellerid, price, "Vehicle sale (to used car firm)" ) ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] = E_VEHICLE_TYPE_FIRM ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] = firm_sql_id ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] = 0 ;

	Vehicle_WipeKeys ( Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
	UsedCars_SaveOwnership ( veh_enum_id ) ;

	if ( IsValidVehicle ( vehicleid ) ) {

		UsedCars_SavePosition ( veh_enum_id, interior ) ;
		Vehicle_SetDoorsEngineStatus ( veh_enum_id ) ;
	}

	UsedCars_Log ( firm_sql_id, Character [ buyerid ] [ E_CHARACTER_ID ], sprintf ( "Bought a %s from %s for $%s", model_name, ReturnRPName ( sellerid ), IntegerWithDelimiter ( price ) ) ) ;

	SendClientMessage ( sellerid, COLOR_INFO, sprintf ( "[SELL] {DEDEDE}You've sold your %s to %s for {32CD32}$%s{DEDEDE}.", model_name, Firm [ firm_enum_id ] [ E_FIRM_NAME ], IntegerWithDelimiter ( price ) ) ) ;
	SendClientMessage ( buyerid, COLOR_INFO, sprintf ( "[BUY] {DEDEDE}You've bought a %s for %s for {32CD32}$%s{DEDEDE}. Drive it to the lot and use /usedcar price to put it on sale.", model_name, Firm [ firm_enum_id ] [ E_FIRM_NAME ], IntegerWithDelimiter ( price ) ) ) ;

	AddLogEntry ( sellerid, LOG_TYPE_SCRIPT, sprintf ( "Sold their %s to firm %s for $%d (SQLID: %d)", model_name, Firm [ firm_enum_id ] [ E_FIRM_NAME ], price, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ) ;
	AddLogEntry ( buyerid, LOG_TYPE_FIRM, sprintf ( "Bought a %s from %s for firm %s for $%d", model_name, ReturnRPName ( sellerid ), Firm [ firm_enum_id ] [ E_FIRM_NAME ], price ) ) ;

	new catalog = Vehicle_GetCatalogPrice ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ) ;

	if ( price <= 1000 || ( catalog > 0 && price > catalog * USEDCARS_ALERT_PCT / 100 ) ) {

		SendAdminMessage ( sprintf ( "(%d) %s sold a %s to the used car firm %s (run by %s) for $%s, new price is $%s.", sellerid, ReturnRPName ( sellerid ), model_name,
			Firm [ firm_enum_id ] [ E_FIRM_NAME ], ReturnRPName ( buyerid ), IntegerWithDelimiter ( price ), IntegerWithDelimiter ( catalog ) ) ) ;
	}

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Buying from the scrapyard pool
// ---------------------------------------------------------------------------------------------

// Buys a scrapped car out of the scrapyard pool for the firm.
static UsedCars_BuyFromPool(playerid, veh_enum_id, yard) {

	if ( ! UsedCars_CanBuyForFirm ( playerid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You need the vehicles and bank permissions in a used car firm to buy for it." ) ;
	}

	if ( ScrapYard_GetNearby ( playerid ) != yard ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You've left the scrapyard." ) ;
	}

	if ( ! Vehicle_IsPooled ( veh_enum_id ) || Vehicle_GetYardForModel ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ) != yard ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "That vehicle has already been sold." ) ;
	}

	new firm_enum_id = Firm_GetEnumID ( PlayerFirm [ playerid ] [ E_PLAYER_FIRM_ID ] ) ;

	if ( ! Firm_IsActive ( firm_enum_id ) ) {

		return false ;
	}

	new firm_sql_id = Firm [ firm_enum_id ] [ E_FIRM_ID ], price = Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] ;

	if ( UsedCars_CountVehicles ( firm_sql_id ) >= Firm [ firm_enum_id ] [ E_FIRM_VEHICLE_SLOTS ] ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "Your firm's lot is full. Sell a car or ask an admin for more vehicle slots." ) ;
	}

	if ( Firm [ firm_enum_id ] [ E_FIRM_BANK ] < price ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", sprintf ( "The firm bank only has $%s, this car costs $%s.", IntegerWithDelimiter ( Firm [ firm_enum_id ] [ E_FIRM_BANK ] ), IntegerWithDelimiter ( price ) ) ) ;
	}

	new Float: x, Float: y, Float: z, Float: a ;

	GetPlayerPos ( playerid, x, y, z ) ;
	GetPlayerFacingAngle ( playerid, a ) ;
	GetXYInFrontOfPlayer ( playerid, x, y, 5.0 ) ;

	// Spawn it as a firm car first, and only take the money once it exists.
	Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] = E_VEHICLE_TYPE_FIRM ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] = firm_sql_id ;

	if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] < 25 ) {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ] = 25 ;
	}

	new vehicleid = Vehicle_SpawnRecord ( veh_enum_id, x, y, z, a, GetPlayerVirtualWorld ( playerid ), GetPlayerInterior ( playerid ), -1 ) ;

	if ( ! IsValidVehicle ( vehicleid ) ) {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] = E_VEHICLE_TYPE_PLAYER ;
		Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] = 0 ;

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "The vehicle couldn't be spawned right now (the vehicle pool may be full). You haven't been charged." ) ;
	}

	new model_name [ 32 ] ;
	format ( model_name, sizeof ( model_name ), "%s", ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ) ) ;

	Firm_TakeBankMoney ( firm_enum_id, price, sprintf ( "%s bought a used %s from the scrapyard for $%s", ReturnRPName ( playerid ), model_name, IntegerWithDelimiter ( price ) ) ) ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = 0 ;

	UsedCars_SaveOwnership ( veh_enum_id ) ;
	UsedCars_SavePosition ( veh_enum_id, GetPlayerInterior ( playerid ) ) ;

	JT_PutPlayerInVehicle ( playerid, vehicleid, 0 ) ;

	UsedCars_Log ( firm_sql_id, Character [ playerid ] [ E_CHARACTER_ID ], sprintf ( "Bought a used %s (%d miles) from the scrapyard for $%s", model_name, Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ], IntegerWithDelimiter ( price ) ) ) ;
	AddLogEntry ( playerid, LOG_TYPE_FIRM, sprintf ( "Bought a used %s from the scrapyard pool for $%d for firm %s (SQLID %d)", model_name, price, Firm [ firm_enum_id ] [ E_FIRM_NAME ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ) ;

	return SendServerMessage ( playerid, COLOR_BLUE, "Used Cars", "A3A3A3", sprintf ( "You bought a %s for $%s. Drive it to your lot, park it with /usedcar park and put it on sale with /usedcar price.", model_name, IntegerWithDelimiter ( price ) ) ) ;
}

// /usedpool - lists cars in the scrapyard pool that the firm can buy.
CMD:usedpool(playerid, params[]) {

	#pragma unused params

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
	}

	if ( ! IsPlayerInFirmField ( playerid, FIRM_FIELD_USEDCARS ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "Only members of a used car firm can buy from the scrapyard pool." ) ;
	}

	if ( ! UsedCars_CanBuyForFirm ( playerid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You need the vehicles and bank permissions in your firm to buy cars for it." ) ;
	}

	new yard = ScrapYard_GetNearby ( playerid ) ;

	if ( yard == -1 ) {

		GPS_MarkLocation ( playerid, "The ~r~scrapyard~w~ has been marked on your ~r~minimap~w~.", E_GPS_COLOR_SCRIPT, SCRAPYARD_POS_X, SCRAPYARD_POS_Y, SCRAPYARD_POS_Z ) ;

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You must be at a scrapyard (cars, boats and aircraft each have their own)." ) ;
	}

	// Newest first, up to one page.
	UsedPool_Count [ playerid ] = 0 ;

	new last_time = cellmax, last_index = -1 ;

	for ( new n; n < USEDCARS_POOL_PAGE; n ++ ) {

		new best = -1 ;

		for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

			if ( ! Vehicle_IsPooled ( i ) || Vehicle_GetYardForModel ( Vehicle [ i ] [ E_VEHICLE_MODELID ] ) != yard ) {

				continue ;
			}

			new t = Vehicle [ i ] [ E_VEHICLE_POOLED_AT ] ;

			// Only cars that sort after the previous pick.
			if ( t > last_time || ( t == last_time && i <= last_index ) ) {

				continue ;
			}

			if ( best == -1 || t > Vehicle [ best ] [ E_VEHICLE_POOLED_AT ] || ( t == Vehicle [ best ] [ E_VEHICLE_POOLED_AT ] && i < best ) ) {

				best = i ;
			}
		}

		if ( best == -1 ) {

			break ;
		}

		UsedPool_List [ playerid ] [ n ] = best ;
		UsedPool_Count [ playerid ] ++ ;

		last_time = Vehicle [ best ] [ E_VEHICLE_POOLED_AT ] ;
		last_index = best ;
	}

	if ( ! UsedPool_Count [ playerid ] ) {

		return SendServerMessage ( playerid, COLOR_BLUE, "Used Cars", "A3A3A3", "There are no scrapped vehicles waiting at this scrapyard right now." ) ;
	}

	new string [ 2048 ] ;

	strcat ( string, "Vehicle\tMileage\tPrice\tScrapped\n" ) ;

	for ( new n; n < UsedPool_Count [ playerid ]; n ++ ) {

		new veh_enum_id = UsedPool_List [ playerid ] [ n ] ;

		format ( string, sizeof ( string ), "%s%s\t%s mi\t$%s\t%d days ago\n", string, ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ),
			IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ), IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] ),
			( gettime () - Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ] ) / 86400 ) ;
	}

	inline UsedPoolList(pid, dialogid, response, listitem, string: inputtext[]) {
		#pragma unused pid, dialogid, inputtext

		if ( ! response || listitem < 0 || listitem >= UsedPool_Count [ playerid ] ) {

			return true ;
		}

		new veh_enum_id = UsedPool_List [ playerid ] [ listitem ] ;

		if ( ! Vehicle_IsPooled ( veh_enum_id ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "That vehicle has already been sold." ) ;
		}

		new confirm [ 384 ] ;

		format ( confirm, sizeof ( confirm ), "{DEDEDE}Buy this scrapped vehicle for your firm?\n\n{A3A3A3}Vehicle: {DEDEDE}%s\n{A3A3A3}Mileage: {DEDEDE}%s miles\n{A3A3A3}Price: {32CD32}$%s{DEDEDE} (from the firm bank)\n\nIt will appear in front of you, ready to drive to your lot.",
			ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ), IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ),
			IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] ) ) ;

		inline UsedPoolConfirm(pid2, dialogid2, response2, listitem2, string: inputtext2[]) {
			#pragma unused pid2, dialogid2, listitem2, inputtext2

			if ( response2 ) {

				UsedCars_BuyFromPool ( playerid, veh_enum_id, yard ) ;
			}
		}

		Dialog_ShowCallback ( playerid, using inline UsedPoolConfirm, DIALOG_STYLE_MSGBOX, "Buy Scrapped Vehicle", confirm, "Buy", "Cancel" ) ;

		return true ;
	}

	Dialog_ShowCallback ( playerid, using inline UsedPoolList, DIALOG_STYLE_TABLIST_HEADERS, "Scrapyard Pool", string, "Select", "Close" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Running the lot
// ---------------------------------------------------------------------------------------------

// The firm vehicle the player is driving, if it belongs to their used car firm. -1 otherwise.
static UsedCars_GetDrivenLotCar(playerid) {

	if ( GetPlayerState ( playerid ) != PLAYER_STATE_DRIVER ) {

		return -1 ;
	}

	new vehicleid = GetPlayerVehicleID ( playerid ), veh_enum_id = Vehicle_GetEnumID ( vehicleid ) ;

	if ( veh_enum_id == -1 || Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FIRM || Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] != PlayerFirm [ playerid ] [ E_PLAYER_FIRM_ID ] ) {

		return -1 ;
	}

	return veh_enum_id ;
}

// /usedcar [price/unlist/park/list] - manage the car you are in on your firm's lot.
CMD:usedcar(playerid, params[]) {

	if ( ! IsPlayerInFirmField ( playerid, FIRM_FIELD_USEDCARS ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "Only members of a used car firm can use this." ) ;
	}

	new sub [ 16 ], rest [ 32 ] ;

	if ( sscanf ( params, "s[16]S()[32]", sub, rest ) ) {

		SendClientMessage ( playerid, COLOR_GRAD0, "/usedcar [price / unlist / park / list]" ) ;
		SendClientMessage ( playerid, COLOR_GRAD0, "price [amount]: put the car you're driving on sale | unlist: take it off sale | park: it stays where it is now" ) ;

		return SendClientMessage ( playerid, COLOR_GRAD0, "list: your firm's cars. /usedpool buys scrapped cars at a scrapyard and /carsell buys from a player." ) ;
	}

	new firm_sql_id = PlayerFirm [ playerid ] [ E_PLAYER_FIRM_ID ] ;

	if ( ! strcmp ( sub, "list", true ) ) {

		new count ;

		SendClientMessage ( playerid, COLOR_INFO, "[Used Cars] Your firm's cars:" ) ;

		for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

			if ( Vehicle [ i ] [ E_VEHICLE_SQLID ] == -1 || Vehicle [ i ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FIRM || Vehicle [ i ] [ E_VEHICLE_OWNER ] != firm_sql_id ) {

				continue ;
			}

			if ( Vehicle [ i ] [ E_VEHICLE_SALE_PRICE ] > 0 ) {

				SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "  %s [%s] | %s miles | on sale for $%s", ReturnVehicleModelName ( Vehicle [ i ] [ E_VEHICLE_MODELID ] ), Vehicle [ i ] [ E_VEHICLE_LICENSE ],
					IntegerWithDelimiter ( Vehicle [ i ] [ E_VEHICLE_MILEAGE ] ), IntegerWithDelimiter ( Vehicle [ i ] [ E_VEHICLE_SALE_PRICE ] ) ) ) ;
			}

			else {

				SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "  %s [%s] | %s miles | not on sale", ReturnVehicleModelName ( Vehicle [ i ] [ E_VEHICLE_MODELID ] ), Vehicle [ i ] [ E_VEHICLE_LICENSE ],
					IntegerWithDelimiter ( Vehicle [ i ] [ E_VEHICLE_MILEAGE ] ) ) ) ;
			}

			count ++ ;
		}

		return SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "  %d cars, lot size %d.", count, Firm [ Firm_GetEnumID ( firm_sql_id ) ] [ E_FIRM_VEHICLE_SLOTS ] ) ) ;
	}

	// Everything else works on the car you are driving, and needs the vehicles permission.
	if ( ! Firm_PlayerHasPerm ( playerid, FIRM_PERM_VEHICLES ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You don't have permission to manage the firm's vehicles." ) ;
	}

	new veh_enum_id = UsedCars_GetDrivenLotCar ( playerid ) ;

	if ( veh_enum_id == -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You must be driving one of your firm's cars." ) ;
	}

	if ( ! strcmp ( sub, "park", true ) ) {

		UsedCars_SavePosition ( veh_enum_id, GetPlayerInterior ( playerid ) ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Used Cars", "A3A3A3", "The car will stay parked here, even after a restart." ) ;
	}

	if ( ! strcmp ( sub, "unlist", true ) ) {

		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] <= 0 ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "This car isn't on sale." ) ;
		}

		Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = 0 ;
		UsedCars_SaveOwnership ( veh_enum_id ) ;
		UsedCars_UpdateLabel ( veh_enum_id ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Used Cars", "A3A3A3", "The car is no longer on sale." ) ;
	}

	if ( ! strcmp ( sub, "price", true ) ) {

		new price ;

		if ( sscanf ( rest, "i", price ) ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, "/usedcar price [amount]" ) ;
		}

		new min_price, max_price ;

		UsedCars_GetPriceRange ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ], min_price, max_price ) ;

		if ( price < min_price || price > max_price ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", sprintf ( "Pick an asking price between $%s and $%s for this model.", IntegerWithDelimiter ( min_price ), IntegerWithDelimiter ( max_price ) ) ) ;
		}

		// A car on sale has to be parked where customers can find it.
		UsedCars_SavePosition ( veh_enum_id, GetPlayerInterior ( playerid ) ) ;

		Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = price ;
		UsedCars_SaveOwnership ( veh_enum_id ) ;
		UsedCars_UpdateLabel ( veh_enum_id ) ;

		new trade_in = Vehicle_GetTradeInValue ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ) ;

		SendServerMessage ( playerid, COLOR_BLUE, "Used Cars", "A3A3A3", sprintf ( "The %s is on sale for $%s and parked here. Customers use /dl next to it to get its vehicle id, then /buyusedcar [vehicle id].",
			ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ), IntegerWithDelimiter ( price ) ) ) ;

		if ( trade_in > 0 ) {

			SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "Trade-in guide for %s miles: $%s.", IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ), IntegerWithDelimiter ( trade_in ) ) ) ;
		}

		return true ;
	}

	return SendClientMessage ( playerid, COLOR_GRAD0, "/usedcar [price / unlist / park / list]" ) ;
}

// ---------------------------------------------------------------------------------------------
// Customers
// ---------------------------------------------------------------------------------------------

// /buyusedcar [vehicle id] - buy a car from a used-car firm's lot.
CMD:buyusedcar(playerid, params[]) {

	if ( IsPlayerIncapacitated ( playerid, false ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
	}

	if ( ! IsPlayerLogged ( playerid ) || Character [ playerid ] [ E_CHARACTER_ID ] <= 0 ) {

		return false ;
	}

	// The buyer names the car by its vehicle id (/dl shows it), so two cars parked close together can't be mixed up.
	new vehicleid ;

	if ( sscanf ( params, "i", vehicleid ) ) {

		SendClientMessage ( playerid, COLOR_GRAD0, "/buyusedcar [vehicle id]" ) ;

		return SendClientMessage ( playerid, COLOR_INFO, "Stand next to the car and use /dl to see its vehicle id." ) ;
	}

	new veh_enum_id = Vehicle_GetEnumID ( vehicleid ) ;

	if ( veh_enum_id == -1 || Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] == -1 || Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FIRM || Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] <= 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "That vehicle isn't for sale. Use /dl next to the car to check its vehicle id." ) ;
	}

	new Float: car_x, Float: car_y, Float: car_z ;

	GetVehiclePos ( vehicleid, car_x, car_y, car_z ) ;

	if ( GetPlayerDistanceFromPoint ( playerid, car_x, car_y, car_z ) > USEDCARS_SALE_RANGE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You're too far from that car. Stand next to it first." ) ;
	}

	if ( Player_GetOwnedVehicles ( playerid ) >= Player_GetMaxOwnedVehicles ( playerid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any vehicle ownership slots left. Use /myslots to check." ) ;
	}

	new price = Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ], firm_name [ MAX_FIRM_NAME ] ;

	if ( GetPlayerCash ( playerid ) < price ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", sprintf ( "You need $%s in cash to buy this car.", IntegerWithDelimiter ( price ) ) ) ;
	}

	Firm_GetName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ], firm_name, sizeof ( firm_name ) ) ;

	new confirm [ 448 ] ;

	format ( confirm, sizeof ( confirm ), "{DEDEDE}Buy this car from {ed7f2b}%s{DEDEDE}?\n\n{A3A3A3}Vehicle: {DEDEDE}%s\n{A3A3A3}Plate: {DEDEDE}%s\n{A3A3A3}Mileage: {DEDEDE}%s miles\n{A3A3A3}Price: {32CD32}$%s\n\n{DEDEDE}The car becomes yours and counts towards your vehicle slots. Use /carspawn to find it later.",
		firm_name, ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ), Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ],
		IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ), IntegerWithDelimiter ( price ) ) ;

	inline UsedCarBuyConfirm(pid, dialogid, response, listitem, string: inputtext[]) {
		#pragma unused pid, dialogid, listitem, inputtext

		if ( ! response ) {

			return true ;
		}

		// Everything could have changed while the dialog was open.
		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] == -1 || Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FIRM || Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] != price ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "That car is no longer on sale at that price." ) ;
		}

		if ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] != vehicleid || ! IsValidVehicle ( vehicleid ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "That car isn't available right now." ) ;
		}

		new Float: x, Float: y, Float: z ;

		GetVehiclePos ( vehicleid, x, y, z ) ;

		if ( GetPlayerDistanceFromPoint ( playerid, x, y, z ) > USEDCARS_SALE_RANGE + 2.0 ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", "You've walked away from the car." ) ;
		}

		if ( Player_GetOwnedVehicles ( playerid ) >= Player_GetMaxOwnedVehicles ( playerid ) ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any vehicle ownership slots left. Use /myslots to check." ) ;
		}

		if ( GetPlayerCash ( playerid ) < price ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Used Cars", "A3A3A3", sprintf ( "You need $%s in cash to buy this car.", IntegerWithDelimiter ( price ) ) ) ;
		}

		new firm_sql_id = Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ], firm_enum_id = Firm_GetEnumID ( firm_sql_id ), model_name [ 32 ] ;

		format ( model_name, sizeof ( model_name ), "%s", ReturnVehicleModelName ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] ) ) ;

		TakePlayerCash ( playerid, price, "Vehicle purchase (used car firm)" ) ;

		if ( Firm_IsValid ( firm_enum_id ) ) {

			Firm_AddBankMoney ( firm_enum_id, price, sprintf ( "Sold a %s to %s for $%s", model_name, ReturnRPName ( playerid ), IntegerWithDelimiter ( price ) ) ) ;
		}

		// Nobody sits in a car that has just been sold from under them.
		foreach ( new i : Player ) {

			if ( IsPlayerInVehicle ( i, vehicleid ) && i != playerid ) {

				JT_RemovePlayerFromVehicle ( i ) ;
			}
		}

		Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] = E_VEHICLE_TYPE_PLAYER ;
		Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] = Character [ playerid ] [ E_CHARACTER_ID ] ;
		Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = 0 ;
		Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE ] = false ;
		Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ] = true ;

		Vehicle_WipeKeys ( Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;
		UsedCars_SaveOwnership ( veh_enum_id ) ;
		UsedCars_UpdateLabel ( veh_enum_id ) ;
		Vehicle_SetDoorsEngineStatus ( veh_enum_id ) ;

		if ( firm_sql_id > 0 ) {

			UsedCars_Log ( firm_sql_id, 0, sprintf ( "Sold a %s (%s miles) to %s for $%s", model_name, IntegerWithDelimiter ( Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] ), ReturnRPName ( playerid ), IntegerWithDelimiter ( price ) ) ) ;
			Firm_SendMessage ( firm_sql_id, sprintf ( "[Used Cars] %s bought the %s for $%s.", ReturnRPName ( playerid ), model_name, IntegerWithDelimiter ( price ) ) ) ;
		}

		SendServerMessage ( playerid, COLOR_BLUE, "Used Cars", "A3A3A3", sprintf ( "You bought the %s for $%s. It's yours now, the doors are locked. For help, use /carhelp.", model_name, IntegerWithDelimiter ( price ) ) ) ;

		AddLogEntry ( playerid, LOG_TYPE_SCRIPT, sprintf ( "Bought a used %s from firm %d for $%d (SQLID %d)", model_name, firm_sql_id, price, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ) ;

		return true ;
	}

	Dialog_ShowCallback ( playerid, using inline UsedCarBuyConfirm, DIALOG_STYLE_MSGBOX, "Buy Used Car", confirm, "Buy", "Cancel" ) ;

	return true ;
}

// A closed firm's lot goes back to the scrapyard pool (the owner gets nothing for it, closing is
// final) so the cars don't sit locked forever under a firm that no longer exists.
UsedCars_OnFirmClosed(firm_sql_id) {

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( Vehicle [ i ] [ E_VEHICLE_SQLID ] == -1 || Vehicle [ i ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_FIRM || Vehicle [ i ] [ E_VEHICLE_OWNER ] != firm_sql_id ) {

			continue ;
		}

		new value = Vehicle_GetTradeInValue ( Vehicle [ i ] [ E_VEHICLE_MODELID ], Vehicle [ i ] [ E_VEHICLE_MILEAGE ] ) ;

		if ( value <= 0 ) {

			value = 300 ;
		}

		UsedCars_UpdateLabel ( i ) ;
		Vehicle_MoveToPool ( i, value ) ;
	}

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Admin
// ---------------------------------------------------------------------------------------------

// /firmsetslots [firm abbrev] [slots] - (staff) sets how many cars a used-car firm may hold.
CMD:firmsetslots(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command." ) ;
	}

	new abbrev [ MAX_FIRM_ABBREV ], slots ;

	if ( sscanf ( params, "s[8]i", abbrev, slots ) || slots < 0 || slots > 200 ) {

		return SendClientMessage ( playerid, COLOR_GRAD0, "/firmsetslots [firm abbrev] [vehicle slots 0-200]" ) ;
	}

	for ( new i; i < MAX_FIRMS; i ++ ) {

		if ( Firm [ i ] [ E_FIRM_ID ] == INVALID_FIRM_ID || strcmp ( Firm [ i ] [ E_FIRM_ABBREV ], abbrev, true ) ) {

			continue ;
		}

		Firm [ i ] [ E_FIRM_VEHICLE_SLOTS ] = slots ;

		new query [ 128 ] ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE firms SET firm_vehicle_slots = %d WHERE firm_id = %d", slots, Firm [ i ] [ E_FIRM_ID ] ) ;
		mysql_tquery ( mysql, query ) ;

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set the vehicle slots of firm %s [%s] to %d", Firm [ i ] [ E_FIRM_NAME ], Firm [ i ] [ E_FIRM_ABBREV ], slots ) ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Firm", "A3A3A3", sprintf ( "%s [%s] now has %d vehicle slots.", Firm [ i ] [ E_FIRM_NAME ], Firm [ i ] [ E_FIRM_ABBREV ], slots ) ) ;
	}

	return SendServerMessage ( playerid, COLOR_ERROR, "Firm", "A3A3A3", "No firm found with that abbreviation." ) ;
}
