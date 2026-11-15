// ============================================================================
// File: jobs/trucker/header.pwn
// Trucker delivery job: take an order at the depot, carry crates into the vehicle's cargo
// slots, drive to a business and unload for pay. See the comment block at the top of the file
// for the full flow.
// Commands: /truckerjob /loadtruck /canceldelivery
// ============================================================================

// ============================================================================
// Trucker job (simple version, crates in real vehicle slots).
//
// Every delivery vehicle has a number of cargo slots (see Trucker_GetVehicleCapacity).
// Each crate takes one slot. The cargo, and the delivery order it belongs to, stay
// with the VEHICLE: if you walk away or someone else drives it, the crates are still
// inside, and whoever unloads them at the business is paid.
//
//   /truckerjob     - how it works
//   /loadtruck      - at the depot, in an empty delivery vehicle: take a delivery order
//   /canceldelivery - scrap the order and empty the vehicle
//   Y (KEY_YES)     - pick up / put down a crate (depot pile, rear of the vehicle, drop-off)
//
// Delivery targets are the server's own business properties (E_PROPERTY_TYPE_BIZ),
// so the job adapts to whatever businesses you create. Change the depot, the pay
// and the product list below.
//
// Storage: VehicleVar[veh][E_VEHICLE_TRUCKER_ITEM][slot] holds the crate's product
// (a buy type) or -1 if the slot is empty; VehicleVar[veh][E_VEHICLE_TRUCKER_ORIGIN][0]
// holds the destination property's SQL id (or -1 for no order).
// ============================================================================

// Depot. TODO: set coordinates for your map (the crate pile and /loadtruck point).
#define TRUCKER_DEPOT_X         (0.0) // TODO: set coordinates for your map
#define TRUCKER_DEPOT_Y         (0.0) // TODO: set coordinates for your map
#define TRUCKER_DEPOT_Z         (0.0) // TODO: set coordinates for your map
#define TRUCKER_DEPOT_NAME      "Delivery Depot"

#define TRUCKER_CRATE_MODEL     (1271)      // stock crate; swap for a custom model if you add one
#define TRUCKER_LOAD_RANGE      (15.0)      // how close the vehicle must be to the depot to take an order
#define TRUCKER_PILE_RANGE      (4.0)       // how close you must be to the depot crate pile
#define TRUCKER_REAR_RANGE      (3.0)       // how close you must be to the rear of the vehicle
#define TRUCKER_DROP_RANGE      (6.0)       // how close you must be to the drop-off point
#define TRUCKER_UNLOAD_RANGE    (30.0)      // how close the vehicle must be to the business to unload
#define TRUCKER_MIN_DISTANCE    (300.0)     // don't send people to a business right next door
#define TRUCKER_PAY_PER_CRATE   (40)
#define TRUCKER_PAY_PER_YARD    (0.03)      // extra per crate, per yard between the depot and the business
#define TRUCKER_CHECKPOINT_SIZE (6.0)

#define TRUCKER_NO_ORDER        (-1)

static bool:   TruckerHeldFromVehicle[MAX_PLAYERS];     // the crate in your hands came out of a vehicle
static TruckerEarned[MAX_PLAYERS];                       // paid so far on the current unload

// ---------------------------------------------------------------------------
// Vehicles that can haul deliveries. The capacity is the number of crate slots.
// ---------------------------------------------------------------------------
Trucker_GetVehicleCapacity(modelid) {

	switch ( modelid ) {

		case 413: return 8 ;    // Pony
		case 414: return 12 ;   // Mule
		case 456: return 16 ;   // Yankee
		case 499: return 14 ;   // Benson
		case 498, 609: return 10 ;  // Boxville
		case 440: return 8 ;    // Rumpo
		case 482: return 6 ;    // Burrito
		case 435, 450, 584, 591: return 30 ;    // Trailers
	}

	return 0 ;
}

// Returns true if the vehicle can carry cargo (is one of the delivery vehicles or trailers).
bool: IsCargoVehicle(vehicleid) {

	return ( Trucker_GetVehicleCapacity ( GetVehicleModel(vehicleid) ) > 0 ) ;
}

// Kept because the rest of the gamemode asks about it.
IsTruckingVehicle(vehicleid) {

	return ( IsCargoVehicle(vehicleid) ? 1 : 0 ) ;
}

// Returns the number of cargo slots of a vehicle model (used by tolls and the dealership).
GetMaxStorageModel(modelid) {

	return Trucker_GetVehicleCapacity(modelid) ;
}

// Tractor units: they pull trailers, they never carry cargo themselves (used by the toll booths).
bool: IsTractorUnit(modelid) {

	switch ( modelid ) {

		case 403, 514, 515: return true ;   // Linerunner, Tanker, Roadtrain
	}

	return false ;
}

// ---------------------------------------------------------------------------
// Vehicle cargo slots
// ---------------------------------------------------------------------------

// Empties every slot and cancels the order. Called whenever a vehicle respawns, is reset or sold.
Vehicle_ClearTruckerVariables(veh_enum_id) {

	if ( veh_enum_id == -1 ) {

		return true ;
	}

	for ( new i ; i < 64 ; i ++ ) {

		VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ITEM ] [ i ]   = -1 ;
		VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_MODEL ] [ i ]  = -1 ;
		VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ORIGIN ] [ i ] = -1 ;
	}

	return true ;
}

// Returns the vehicle's array index in Vehicle[].
static Trucker_GetEnumID(vehicleid) {

	return Vehicle_GetEnumID(vehicleid) ;
}

// Returns the vehicle's usable cargo slot count (max 64).
static Trucker_GetCapacity(vehicleid) {

	return min ( Trucker_GetVehicleCapacity ( GetVehicleModel(vehicleid) ), 64 ) ;
}

// Counts how many crates are in a vehicle's cargo slots.
static Trucker_CountCrates(veh_enum_id, vehicleid) {

	new used, cap = Trucker_GetCapacity(vehicleid) ;

	for ( new i ; i < cap ; i ++ ) {

		if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ITEM ] [ i ] != -1 ) {

			used ++ ;
		}
	}

	return used ;
}

// Puts a crate into the first free cargo slot. Returns false if the vehicle is full.
static bool: Trucker_AddCrate(veh_enum_id, vehicleid, product) {

	new cap = Trucker_GetCapacity(vehicleid) ;

	for ( new i ; i < cap ; i ++ ) {

		if ( VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ITEM ] [ i ] == -1 ) {

			VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ITEM ] [ i ] = product ;
			return true ;
		}
	}

	return false ;
}

// Takes the last crate out and returns its product, or -1 if the vehicle is empty.
static Trucker_RemoveCrate(veh_enum_id, vehicleid) {

	for ( new i = Trucker_GetCapacity(vehicleid) - 1 ; i >= 0 ; i -- ) {

		new product = VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ITEM ] [ i ] ;

		if ( product != -1 ) {

			VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ITEM ] [ i ] = -1 ;
			return product ;
		}
	}

	return -1 ;
}

// Returns the property SQL id this vehicle is delivering to, or TRUCKER_NO_ORDER.
static Trucker_GetOrder(veh_enum_id) {

	return VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ORIGIN ] [ 0 ] ;
}

// Stores the destination property for a vehicle's delivery order.
static Trucker_SetOrder(veh_enum_id, property_sqlid) {

	VehicleVar [ veh_enum_id ] [ E_VEHICLE_TRUCKER_ORIGIN ] [ 0 ] = property_sqlid ;
}

// ---------------------------------------------------------------------------
// Products: which businesses get deliveries, and what we bring them.
// ---------------------------------------------------------------------------
static bool: Trucker_GetProduct(buytype, product[], len = sizeof ( product )) {

	switch ( buytype ) {

		case E_BUY_TYPE_GENERAL:            format ( product, len, "fresh groceries" ) ;
		case E_BUY_TYPE_LIQUOR:             format ( product, len, "beer, wine and spirits" ) ;
		case E_BUY_TYPE_RESTAURANT:         format ( product, len, "fresh produce and meat" ) ;
		case E_BUY_TYPE_FOOD_CLUCKINBELL:   format ( product, len, "poultry and eggs" ) ;
		case E_BUY_TYPE_FOOD_PIZZASTACK:    format ( product, len, "tomatoes, flour and cheese" ) ;
		case E_BUY_TYPE_FOOD_BURGERSHOT:    format ( product, len, "beef, buns and lettuce" ) ;
		case E_BUY_TYPE_FOOD_DONUTS:        format ( product, len, "flour, sugar and coffee beans" ) ;
		case E_BUY_TYPE_FOOD_RINGS:         format ( product, len, "dough and sugar" ) ;
		default: return false ;
	}

	return true ;
}

// Finds a business property by its SQL id, or -1.
static Trucker_FindProperty(sqlid) {

	foreach (new i : Properties) {

		if ( Property [ i ] [ E_PROPERTY_ID ] == sqlid ) {

			return i ;
		}
	}

	return -1 ;
}

// Picks a random eligible business at least TRUCKER_MIN_DISTANCE from the depot.
static Trucker_PickBusiness() {

	new candidates[64], count ;

	foreach (new i : Properties) {

		if ( Property [ i ] [ E_PROPERTY_TYPE ] != E_PROPERTY_TYPE_BIZ ) continue ;
		if ( Property [ i ] [ E_PROPERTY_EXT_VW ] != 0 || Property [ i ] [ E_PROPERTY_EXT_INT ] != 0 ) continue ;

		new product[48] ;
		if ( ! Trucker_GetProduct ( Property [ i ] [ E_PROPERTY_BUY_TYPE ], product ) ) continue ;

		new Float:dx = Property [ i ] [ E_PROPERTY_EXT_X ] - TRUCKER_DEPOT_X ;
		new Float:dy = Property [ i ] [ E_PROPERTY_EXT_Y ] - TRUCKER_DEPOT_Y ;

		if ( floatsqroot ( dx * dx + dy * dy ) < TRUCKER_MIN_DISTANCE ) continue ;

		if ( count < sizeof ( candidates ) ) candidates [ count ++ ] = i ;
	}

	return ( count ) ? candidates [ random ( count ) ] : -1 ;
}

// Returns the distance from the depot to a business, used to scale the pay.
static Float: Trucker_DepotDistance(prop) {

	new Float:dx = Property [ prop ] [ E_PROPERTY_EXT_X ] - TRUCKER_DEPOT_X ;
	new Float:dy = Property [ prop ] [ E_PROPERTY_EXT_Y ] - TRUCKER_DEPOT_Y ;

	return floatsqroot ( dx * dx + dy * dy ) ;
}

// Puts the delivery checkpoint on a business for a player.
static Trucker_SetCheckpoint(playerid, prop) {

	SetPlayerCheckpoint(playerid, Property [ prop ] [ E_PROPERTY_EXT_X ], Property [ prop ] [ E_PROPERTY_EXT_Y ], Property [ prop ] [ E_PROPERTY_EXT_Z ], TRUCKER_CHECKPOINT_SIZE) ;
}

// ---------------------------------------------------------------------------
// Carrying
// ---------------------------------------------------------------------------
static bool: Trucker_IsCarrying(playerid) {

	return ( PlayerVar [ playerid ] [ E_PLAYER_TRUCKER_CARRY_BOX ] != -1 ) ;
}

// Makes the player pick up and carry a crate (animation and attached object).
static Trucker_PickUpCrate(playerid, product, bool:from_vehicle) {

	PlayerVar [ playerid ] [ E_PLAYER_TRUCKER_CARRY_BOX ] = 1 ;
	PlayerVar [ playerid ] [ E_PLAYER_TRUCKER_CARRY_BOX_ITEM ] = product ;
	TruckerHeldFromVehicle [ playerid ] = from_vehicle ;

	SetPlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM, TRUCKER_CRATE_MODEL, 1, 0.4, 0.6, 0.0, 0.0, 90.0, 0.0, 1.0, 1.0, 1.0) ;
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY) ;
}

// Makes the player put down the crate they are carrying.
static Trucker_PutDownCrate(playerid) {

	PlayerVar [ playerid ] [ E_PLAYER_TRUCKER_CARRY_BOX ] = -1 ;
	TruckerHeldFromVehicle [ playerid ] = false ;

	RemovePlayerAttachedObject(playerid, E_ATTACH_INDEX_SYSTEM) ;
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE) ;
}

// A point just behind the vehicle, where crates go in and out.
static Trucker_GetRearPos(vehicleid, &Float:x, &Float:y, &Float:z) {

	new Float:sx, Float:sy, Float:sz, Float:angle ;

	GetVehicleModelInfo(GetVehicleModel(vehicleid), VEHICLE_MODEL_INFO_SIZE, sx, sy, sz) ;
	GetVehiclePos(vehicleid, x, y, z) ;
	GetVehicleZAngle(vehicleid, angle) ;

	x += ( ( sy / 2.0 ) + 0.5 ) * floatsin ( angle, degrees ) ;
	y -= ( ( sy / 2.0 ) + 0.5 ) * floatcos ( angle, degrees ) ;
}

// The cargo vehicle whose rear the player is standing at, or INVALID_VEHICLE_ID.
static Trucker_GetRearVehicle(playerid) {

	new vehicleid = Vehicle_GetClosestEntity(playerid, 10.0) ;

	if ( vehicleid == INVALID_VEHICLE_ID || ! IsCargoVehicle(vehicleid) || Trucker_GetEnumID(vehicleid) == -1 ) {

		return INVALID_VEHICLE_ID ;
	}

	new Float:x, Float:y, Float:z ;
	Trucker_GetRearPos(vehicleid, x, y, z) ;

	return IsPlayerInRangeOfPoint(playerid, TRUCKER_REAR_RANGE, x, y, z) ? vehicleid : INVALID_VEHICLE_ID ;
}

// Start-up: creates the depot label and the pile of crates.
Trucker_LoadEntities() {

	CreateDynamic3DTextLabel(TRUCKER_DEPOT_NAME "\n{DEDEDE}Take an order with /loadtruck in a delivery vehicle,\nthen press Y here to pick up crates.", 0xC6944CFF, TRUCKER_DEPOT_X, TRUCKER_DEPOT_Y, TRUCKER_DEPOT_Z + 1.0, 20.0, .testlos = false) ;

	// A small pile of crates marks the pickup point.
	CreateDynamicObject(TRUCKER_CRATE_MODEL, TRUCKER_DEPOT_X, TRUCKER_DEPOT_Y, TRUCKER_DEPOT_Z - 0.4, 0.0, 0.0, 0.0) ;
	CreateDynamicObject(TRUCKER_CRATE_MODEL, TRUCKER_DEPOT_X + 1.2, TRUCKER_DEPOT_Y, TRUCKER_DEPOT_Z - 0.4, 0.0, 0.0, 20.0) ;
	CreateDynamicObject(TRUCKER_CRATE_MODEL, TRUCKER_DEPOT_X + 0.6, TRUCKER_DEPOT_Y, TRUCKER_DEPOT_Z + 0.4, 0.0, 0.0, 10.0) ;

	printf(" * [TRUCKER] Delivery job loaded (depot: %s).", TRUCKER_DEPOT_NAME) ;

	return true ;
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------
CMD:truckerjob(playerid, params[]) {

	#pragma unused params

	SendClientMessage(playerid, 0xC6944CFF, "[TRUCKER]: Drive a delivery vehicle (Pony, Mule, Yankee, Benson, Boxville, Rumpo, Burrito) to the " TRUCKER_DEPOT_NAME " and type /loadtruck.") ;
	SendClientMessage(playerid, 0xC6944CFF, "[TRUCKER]: Press Y at the crate pile to pick up a crate, then press Y at the back of the vehicle to load it. Each crate fills one slot, so a bigger vehicle carries more.") ;
	SendClientMessage(playerid, 0xC6944CFF, "[TRUCKER]: Drive to the marked business. Press Y at the back of the vehicle to take a crate out, carry it to the checkpoint and press Y to drop it. You're paid per crate.") ;
	SendClientMessage(playerid, 0xC6944CFF, "[TRUCKER]: /canceldelivery scraps the order and empties the vehicle.") ;

	return true ;
}

// /loadtruck - at the depot in an empty delivery vehicle: takes a delivery order for a random
// business.
CMD:loadtruck(playerid, params[]) {

	#pragma unused params

	new vehicleid = GetPlayerVehicleID(playerid) ;

	if ( ! vehicleid || GetPlayerState(playerid) != PLAYER_STATE_DRIVER ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "You must be driving a delivery vehicle." ) ;
	}

	new veh_enum_id = Trucker_GetEnumID(vehicleid) ;

	if ( ! IsCargoVehicle(vehicleid) || veh_enum_id == -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "This vehicle can't carry deliveries." ) ;
	}

	if ( Trucker_GetOrder(veh_enum_id) != TRUCKER_NO_ORDER || Trucker_CountCrates(veh_enum_id, vehicleid) > 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "This vehicle already has an order or cargo. Deliver it, or use /canceldelivery." ) ;
	}

	if ( GetVehicleDistanceFromPoint(vehicleid, TRUCKER_DEPOT_X, TRUCKER_DEPOT_Y, TRUCKER_DEPOT_Z) > TRUCKER_LOAD_RANGE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "You must be at the " TRUCKER_DEPOT_NAME " to take an order." ) ;
	}

	new prop = Trucker_PickBusiness() ;

	if ( prop == -1 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "There are no businesses to deliver to right now. Ask an admin to create some." ) ;
	}

	new product[48] ;
	Trucker_GetProduct ( Property [ prop ] [ E_PROPERTY_BUY_TYPE ], product ) ;

	Trucker_SetOrder(veh_enum_id, Property [ prop ] [ E_PROPERTY_ID ]) ;
	Trucker_SetCheckpoint(playerid, prop) ;

	SendServerMessage ( playerid, COLOR_JOB, "Trucker", "DEDEDE",
		sprintf ( "Order: %s for {FFFFFF}%s{DEDEDE}. This vehicle holds up to %d crates. Press Y at the crate pile, then Y at the back of the vehicle to load. Drive to the checkpoint when you're done.",
			product, Property [ prop ] [ E_PROPERTY_NAME ], Trucker_GetCapacity(vehicleid) ) ) ;

	AddLogEntry(playerid, LOG_TYPE_JOB, "started a trucker delivery") ;

	return true ;
}

// /canceldelivery - cancels the order and empties the vehicle.
CMD:canceldelivery(playerid, params[]) {

	#pragma unused params

	new vehicleid = GetPlayerVehicleID(playerid) ;

	if ( ! vehicleid ) {

		vehicleid = Trucker_GetRearVehicle(playerid) ;
	}

	new veh_enum_id = ( vehicleid && vehicleid != INVALID_VEHICLE_ID ) ? Trucker_GetEnumID(vehicleid) : -1 ;

	if ( veh_enum_id == -1 || ! IsCargoVehicle(vehicleid) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "Sit in your delivery vehicle, or stand at the back of it." ) ;
	}

	if ( Trucker_GetOrder(veh_enum_id) == TRUCKER_NO_ORDER && Trucker_CountCrates(veh_enum_id, vehicleid) == 0 ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "This vehicle has no delivery order." ) ;
	}

	Vehicle_ClearTruckerVariables(veh_enum_id) ;
	DisablePlayerCheckpoint(playerid) ;

	SendServerMessage ( playerid, COLOR_JOB, "Trucker", "DEDEDE", "Delivery order cancelled and the vehicle emptied." ) ;

	return true ;
}

// ---------------------------------------------------------------------------
// Hooks
// ---------------------------------------------------------------------------
#include <YSI_Coding\y_hooks>

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {

	if ( ! ( newkeys & KEY_YES ) || ( oldkeys & KEY_YES ) ) return 1 ;
	if ( IsPlayerInAnyVehicle(playerid) ) return 1 ;

	new bool: carrying = Trucker_IsCarrying(playerid) ;
	new rear_vehicle = Trucker_GetRearVehicle(playerid) ;
	new rear_enum = ( rear_vehicle != INVALID_VEHICLE_ID ) ? Trucker_GetEnumID(rear_vehicle) : -1 ;
	new bool: at_pile = IsPlayerInRangeOfPoint(playerid, TRUCKER_PILE_RANGE, TRUCKER_DEPOT_X, TRUCKER_DEPOT_Y, TRUCKER_DEPOT_Z) ;

	// ---- Not carrying anything ------------------------------------------------
	if ( ! carrying ) {

		// Pick up from the depot pile (only worth it if a nearby vehicle has an order, but we don't force that).
		if ( at_pile ) {

			Trucker_PickUpCrate(playerid, 0, false) ;
			return 1 ;
		}

		if ( rear_enum == -1 ) return 1 ;

		new order = Trucker_GetOrder(rear_enum) ;

		if ( order == TRUCKER_NO_ORDER ) return 1 ;

		new prop = Trucker_FindProperty(order) ;

		if ( prop == -1 ) {

			SendServerMessage ( playerid, COLOR_ERROR, "Trucker", "A3A3A3", "The business for this order no longer exists. The order has been scrapped." ) ;
			Vehicle_ClearTruckerVariables(rear_enum) ;
			return 1 ;
		}

		// Take a crate out, but only at the business.
		if ( GetVehicleDistanceFromPoint(rear_vehicle, Property [ prop ] [ E_PROPERTY_EXT_X ], Property [ prop ] [ E_PROPERTY_EXT_Y ], Property [ prop ] [ E_PROPERTY_EXT_Z ]) > TRUCKER_UNLOAD_RANGE ) {

			ShowPlayerFooter(playerid, sprintf ( "Take the cargo to %s first.", Property [ prop ] [ E_PROPERTY_NAME ] ), 3000) ;
			return 1 ;
		}

		new product = Trucker_RemoveCrate(rear_enum, rear_vehicle) ;

		if ( product == -1 ) {

			// Empty vehicle at the business: the order is done.
			Vehicle_ClearTruckerVariables(rear_enum) ;
			DisablePlayerCheckpoint(playerid) ;

			if ( TruckerEarned [ playerid ] > 0 ) {

				SendServerMessage ( playerid, COLOR_JOB, "Trucker", "DEDEDE", sprintf ( "All crates delivered. You earned {FFFFFF}$%d{DEDEDE} on this run. Head back to the depot for another.", TruckerEarned [ playerid ] ) ) ;
				TruckerEarned [ playerid ] = 0 ;
			}

			return 1 ;
		}

		Trucker_SetCheckpoint(playerid, prop) ;
		Trucker_PickUpCrate(playerid, product, true) ;
		ShowPlayerFooter(playerid, "Carry the crate to the checkpoint and press Y.", 3000) ;

		return 1 ;
	}

	// ---- Carrying a crate ------------------------------------------------------

	// At the back of a vehicle with an order: load it (or put it back).
	if ( rear_enum != -1 && Trucker_GetOrder(rear_enum) != TRUCKER_NO_ORDER ) {

		if ( ! Trucker_AddCrate(rear_enum, rear_vehicle, PlayerVar [ playerid ] [ E_PLAYER_TRUCKER_CARRY_BOX_ITEM ]) ) {

			ShowPlayerFooter(playerid, "This vehicle is full.", 3000) ;
			return 1 ;
		}

		Trucker_PutDownCrate(playerid) ;
		ShowPlayerFooter(playerid, sprintf ( "Loaded %d/%d crates.", Trucker_CountCrates(rear_enum, rear_vehicle), Trucker_GetCapacity(rear_vehicle) ), 3000) ;

		return 1 ;
	}

	// Otherwise: a crate that came out of a vehicle can be dropped at the business it was meant for.
	if ( TruckerHeldFromVehicle [ playerid ] ) {

		new vehicleid = Vehicle_GetClosestEntity(playerid, 40.0) ;
		new veh_enum_id = ( vehicleid != INVALID_VEHICLE_ID ) ? Trucker_GetEnumID(vehicleid) : -1 ;
		new prop = ( veh_enum_id != -1 ) ? Trucker_FindProperty(Trucker_GetOrder(veh_enum_id)) : -1 ;

		// The delivery vehicle should be right next to us; if it isn't we fall back to the nearest business we're standing at.
		if ( prop == -1 ) {

			foreach (new i : Properties) {

				if ( Property [ i ] [ E_PROPERTY_TYPE ] == E_PROPERTY_TYPE_BIZ && IsPlayerInRangeOfPoint(playerid, TRUCKER_DROP_RANGE, Property [ i ] [ E_PROPERTY_EXT_X ], Property [ i ] [ E_PROPERTY_EXT_Y ], Property [ i ] [ E_PROPERTY_EXT_Z ]) ) {

					prop = i ;
					break ;
				}
			}
		}

		if ( prop != -1 && IsPlayerInRangeOfPoint(playerid, TRUCKER_DROP_RANGE, Property [ prop ] [ E_PROPERTY_EXT_X ], Property [ prop ] [ E_PROPERTY_EXT_Y ], Property [ prop ] [ E_PROPERTY_EXT_Z ]) ) {

			new pay = TRUCKER_PAY_PER_CRATE + floatround ( Trucker_DepotDistance(prop) * TRUCKER_PAY_PER_YARD ) ;

			Trucker_PutDownCrate(playerid) ;
			GivePlayerCash(playerid, pay, "Trucker delivery payout") ;
			TruckerEarned [ playerid ] += pay ;

			ShowPlayerFooter(playerid, sprintf ( "Crate delivered: $%d", pay ), 3000) ;
			AddLogEntry(playerid, LOG_TYPE_JOB, sprintf ( "delivered a trucker crate for $%d", pay )) ;

			// Last crate out? Close the order.
			if ( veh_enum_id != -1 && Trucker_CountCrates(veh_enum_id, vehicleid) == 0 ) {

				Vehicle_ClearTruckerVariables(veh_enum_id) ;
				DisablePlayerCheckpoint(playerid) ;

				SendServerMessage ( playerid, COLOR_JOB, "Trucker", "DEDEDE", sprintf ( "All crates delivered. You earned {FFFFFF}$%d{DEDEDE} on this run. Head back to the depot for another.", TruckerEarned [ playerid ] ) ) ;
				TruckerEarned [ playerid ] = 0 ;
			}

			return 1 ;
		}

		ShowPlayerFooter(playerid, "Carry the crate to the checkpoint and press Y.", 3000) ;
		return 1 ;
	}

	ShowPlayerFooter(playerid, "Take the crate to the back of your delivery vehicle and press Y.", 3000) ;

	return 1 ;
}

// A driver who gets into a vehicle that has cargo is pointed at its destination.
hook OnPlayerStateChange(playerid, newstate, oldstate) {

	if ( newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER ) {

		// Can't get in with a crate in your hands.
		if ( Trucker_IsCarrying(playerid) ) {

			Trucker_PutDownCrate(playerid) ;
			ShowPlayerFooter(playerid, "You put the crate down to get in the vehicle.", 3000) ;
		}
	}

	if ( newstate == PLAYER_STATE_DRIVER ) {

		new vehicleid = GetPlayerVehicleID(playerid) ;
		new veh_enum_id = Trucker_GetEnumID(vehicleid) ;

		if ( veh_enum_id != -1 && IsCargoVehicle(vehicleid) && Trucker_GetOrder(veh_enum_id) != TRUCKER_NO_ORDER ) {

			new prop = Trucker_FindProperty(Trucker_GetOrder(veh_enum_id)) ;

			if ( prop != -1 ) {

				Trucker_SetCheckpoint(playerid, prop) ;
				ShowPlayerFooter(playerid, sprintf ( "This vehicle is carrying %d crates for %s.", Trucker_CountCrates(veh_enum_id, vehicleid), Property [ prop ] [ E_PROPERTY_NAME ] ), 4000) ;
			}
		}
	}

	return 1 ;
}

// A wrecked vehicle loses its cargo.
hook OnVehicleDeath(vehicleid, killerid) {

	new veh_enum_id = Trucker_GetEnumID(vehicleid) ;

	if ( veh_enum_id != -1 ) {

		Vehicle_ClearTruckerVariables(veh_enum_id) ;
	}

	return 1 ;
}

hook OnPlayerDisconnect(playerid, reason) {

	if ( Trucker_IsCarrying(playerid) ) {

		Trucker_PutDownCrate(playerid) ;
	}

	TruckerEarned [ playerid ] = 0 ;

	return 1 ;
}

hook OnPlayerConnect(playerid) {

	TruckerHeldFromVehicle [ playerid ] = false ;
	TruckerEarned [ playerid ] = 0 ;

	return 1 ;
}
