// ============================================================================
// File: vehicle/modules/dealer.pwn
// Franchise dealerships: the catalogue of vehicles each dealership type sells, prices, stock
// and discounts, and buying a new vehicle (/dealership). A vacant dealership is NPC run.
// Commands: /gotodealer /togds /dealership
// ============================================================================

enum { // dealership types

	DEALERSHIP_TYPE_BUDGET,
	DEALERSHIP_TYPE_MUSCLE,
	DEALERSHIP_TYPE_SPORTS, 
	DEALERSHIP_TYPE_UTILITY,
	DEALERSHIP_TYPE_BIKE,
	DEALERSHIP_TYPE_AIRCRAFT,
	DEALERSHIP_TYPE_BOAT,
	DEALERSHIP_TYPE_SHIP
}

// Franchise dealerships sell brand new vehicles from the catalogue below (DealershipCars, one
// catalogue per dealership type). Dealerships live in the `dealerships` table and are created by
// admins. A vacant dealership is NPC run: every model is always in stock and nothing is tracked.
// Once a player owns it, each model has a stock counter, every sale credits the dealership bank and
// the owner orders more cars from the manufacturer at DEALER_WHOLESALE_PCT of the catalogue price.
// Owner commands are in dealer_owner.pwn, admin commands in dealer_admin.pwn.

#define MAX_DEALERSHIPS             (24)
#define INVALID_DEALERSHIP_ID       (-1)

#define DEALER_WHOLESALE_PCT        (70)    // what an owner pays per car, as a % of the catalogue price
#define DEALER_MAX_STOCK            (10)    // most cars of a single model an owner can hold
#define DEALER_INACTIVE_DAYS        (7)     // owner offline this long and the dealership is foreclosed

enum DealershipData {

	dealership_sqlid,
	dealership_type,
	dealership_color,
	dealership_name [ 64 ],
	Float: dealership_pos_x,
	Float: dealership_pos_y,
	Float: dealership_pos_z,
	Float: dealership_spawn_x,
	Float: dealership_spawn_y,
	Float: dealership_spawn_z,
	Float: dealership_spawn_a,

	dealership_owner_char, // character id, 0 = vacant
	dealership_owner_name [ 32 ],
	dealership_bank,
	dealership_owner_since,
	dealership_last_seen, // owner's last login/logout/online heartbeat, for foreclosure

	DynamicText3D: dealership_label,
	dealership_pickup,
	dealership_icon
}

new Dealerships [ MAX_DEALERSHIPS ] [ DealershipData ] ;

enum DealershipCarData {

	dealercar_type,
	dealercar_carmodel,
	dealercar_price,
	dealercar_product
}

new DealershipCars[][DealershipCarData] = {

    // SPORTS (performance tier)
    { DEALERSHIP_TYPE_SPORTS, 496, 12000 },    // Blista Compact
    { DEALERSHIP_TYPE_SPORTS, 589, 15000 },    // Club
    { DEALERSHIP_TYPE_SPORTS, 587, 22000 },    // Euros
    { DEALERSHIP_TYPE_SPORTS, 565, 38000 },    // Flash
    { DEALERSHIP_TYPE_SPORTS, 558, 42000 },    // Uranus
    { DEALERSHIP_TYPE_SPORTS, 559, 45000 },    // Jester
    { DEALERSHIP_TYPE_SPORTS, 480, 48000 },    // Comet
    { DEALERSHIP_TYPE_SPORTS, 477, 52000 },    // ZR-350

    // SPORTS (EXOTIC)
    { DEALERSHIP_TYPE_SPORTS, 555, 120000 },   // Windsor
    { DEALERSHIP_TYPE_SPORTS, 429, 160000 },   // Banshee
    { DEALERSHIP_TYPE_SPORTS, 506, 190000 },   // Super GT
    { DEALERSHIP_TYPE_SPORTS, 415, 220000 },   // Cheetah
    { DEALERSHIP_TYPE_SPORTS, 541, 250000 },   // Bullet
    { DEALERSHIP_TYPE_SPORTS, 451, 300000 },   // Turismo
    { DEALERSHIP_TYPE_SPORTS, 562, 320000 },   // Elegy
    { DEALERSHIP_TYPE_SPORTS, 560, 350000 },   // Sultan
    { DEALERSHIP_TYPE_SPORTS, 561, 140000 },   // Stratum

    // BUDGET
    { DEALERSHIP_TYPE_BUDGET, 518, 32000 },    // Buccaneer
    { DEALERSHIP_TYPE_BUDGET, 527, 9500 },     // Cadrona
    { DEALERSHIP_TYPE_BUDGET, 419, 7000 },     // Esperanto
    { DEALERSHIP_TYPE_BUDGET, 533, 16500 },    // Feltzer
    { DEALERSHIP_TYPE_BUDGET, 526, 8000 },     // Fortune
    { DEALERSHIP_TYPE_BUDGET, 474, 12000 },    // Hermes
    { DEALERSHIP_TYPE_BUDGET, 517, 19000 },    // Majestic
    { DEALERSHIP_TYPE_BUDGET, 410, 3500 },     // Manana
    { DEALERSHIP_TYPE_BUDGET, 600, 9000 },     // Picador
    { DEALERSHIP_TYPE_BUDGET, 436, 4200 },     // Previon
    { DEALERSHIP_TYPE_BUDGET, 439, 13500 },    // Stallion
    { DEALERSHIP_TYPE_BUDGET, 549, 30000 },    // Tampa
    { DEALERSHIP_TYPE_BUDGET, 491, 10000 },    // Virgo
    { DEALERSHIP_TYPE_BUDGET, 445, 21000 },    // Admiral
    { DEALERSHIP_TYPE_BUDGET, 507, 16500 },    // Elegant
    { DEALERSHIP_TYPE_BUDGET, 585, 12000 },    // Emperor
    { DEALERSHIP_TYPE_BUDGET, 466, 18000 },    // Glendale
    { DEALERSHIP_TYPE_BUDGET, 492, 13500 },    // Greenwood
    { DEALERSHIP_TYPE_BUDGET, 546, 11000 },    // Intruder
    { DEALERSHIP_TYPE_BUDGET, 551, 15000 },    // Merit
    { DEALERSHIP_TYPE_BUDGET, 516, 14000 },    // Nebula
    { DEALERSHIP_TYPE_BUDGET, 467, 15500 },    // Oceanic
    { DEALERSHIP_TYPE_BUDGET, 404, 6500 },     // Perennial
    { DEALERSHIP_TYPE_BUDGET, 426, 12000 },    // Premier
    { DEALERSHIP_TYPE_BUDGET, 547, 8500 },     // Primo
    { DEALERSHIP_TYPE_BUDGET, 479, 7500 },     // Regina
    { DEALERSHIP_TYPE_BUDGET, 405, 11500 },    // Sentinel
    { DEALERSHIP_TYPE_BUDGET, 458, 6000 },     // Solair
    { DEALERSHIP_TYPE_BUDGET, 580, 26000 },    // Stafford
    { DEALERSHIP_TYPE_BUDGET, 550, 10000 },    // Sunrise
    { DEALERSHIP_TYPE_BUDGET, 540, 11500 },    // Vincent
    { DEALERSHIP_TYPE_BUDGET, 421, 10500 },    // Washington
    { DEALERSHIP_TYPE_BUDGET, 529, 8000 },     // Willard
    { DEALERSHIP_TYPE_BUDGET, 566, 15600 },    // Tahoma
    { DEALERSHIP_TYPE_BUDGET, 412, 9000 },     // Voodoo
    { DEALERSHIP_TYPE_BUDGET, 534, 15000 },    // Remington
    { DEALERSHIP_TYPE_BUDGET, 535, 16000 },    // Slamvan
    { DEALERSHIP_TYPE_BUDGET, 536, 19500 },    // Blade
    { DEALERSHIP_TYPE_BUDGET, 567, 22000 },    // Savanna
    { DEALERSHIP_TYPE_BUDGET, 575, 17500 },    // Broadway
    { DEALERSHIP_TYPE_BUDGET, 576, 19000 },    // Tornado
    { DEALERSHIP_TYPE_BUDGET, 418, 7000 },     // Moonbeam
    { DEALERSHIP_TYPE_BUDGET, 400, 14000 },    // Landstalker
    { DEALERSHIP_TYPE_BUDGET, 483, 18000 },    // Camper

    // UTILITY
    { DEALERSHIP_TYPE_UTILITY, 459, 18000 },   // Topfun Van
    { DEALERSHIP_TYPE_UTILITY, 482, 26000 },   // Burrito
    { DEALERSHIP_TYPE_UTILITY, 413, 15000 },   // Pony
    { DEALERSHIP_TYPE_UTILITY, 440, 22000 },   // Rumpo
    { DEALERSHIP_TYPE_UTILITY, 414, 30000 },   // Mule
    { DEALERSHIP_TYPE_UTILITY, 499, 55000 },   // Benson
    { DEALERSHIP_TYPE_UTILITY, 498, 48000 },   // Boxville
    { DEALERSHIP_TYPE_UTILITY, 456, 65000 },   // Yankee
    { DEALERSHIP_TYPE_UTILITY, 478, 10000 },   // Walton
    { DEALERSHIP_TYPE_UTILITY, 543, 9000 },    // Sadler
    { DEALERSHIP_TYPE_UTILITY, 422, 12000 },   // Bobcat
    { DEALERSHIP_TYPE_UTILITY, 455, 42000 },   // Flatbed
    { DEALERSHIP_TYPE_UTILITY, 554, 28000 },   // Yosemite
    { DEALERSHIP_TYPE_UTILITY, 403, 80000 },   // Linerunner
    { DEALERSHIP_TYPE_UTILITY, 514, 90000 },   // Tanker
    { DEALERSHIP_TYPE_UTILITY, 515, 95000 },   // Roadtrain
    { DEALERSHIP_TYPE_UTILITY, 420, 25000 },   // Taxi
    { DEALERSHIP_TYPE_UTILITY, 438, 15000 },   // Cabbie

    // MUSCLE
    { DEALERSHIP_TYPE_MUSCLE, 579, 27000 },    // Huntley
    { DEALERSHIP_TYPE_MUSCLE, 500, 19000 },    // Mesa
    { DEALERSHIP_TYPE_MUSCLE, 489, 16000 },    // Rancher
    { DEALERSHIP_TYPE_MUSCLE, 603, 46000 },    // Phoenix
    { DEALERSHIP_TYPE_MUSCLE, 402, 42000 },    // Buffalo
    { DEALERSHIP_TYPE_MUSCLE, 475, 28000 },    // Sabre
    { DEALERSHIP_TYPE_MUSCLE, 542, 18000 },    // Clover
    { DEALERSHIP_TYPE_MUSCLE, 545, 52000 },    // Hustler

    // BIKE
    { DEALERSHIP_TYPE_BIKE, 509, 400 },        // Bike
    { DEALERSHIP_TYPE_BIKE, 481, 550 },        // BMX
    { DEALERSHIP_TYPE_BIKE, 510, 1500 },       // Mountain Bike
    { DEALERSHIP_TYPE_BIKE, 462, 2250 },       // Faggio
    { DEALERSHIP_TYPE_BIKE, 448, 4000 },       // Pizzaboy
    { DEALERSHIP_TYPE_BIKE, 468, 25000 },      // Sanchez
    { DEALERSHIP_TYPE_BIKE, 581, 56500 },      // BF-400
    { DEALERSHIP_TYPE_BIKE, 586, 16500 },      // Wayfarer
    { DEALERSHIP_TYPE_BIKE, 471, 27000 },      // Quad
    { DEALERSHIP_TYPE_BIKE, 463, 30000 },      // Freeway
    { DEALERSHIP_TYPE_BIKE, 521, 84500 },      // FCR-900
    { DEALERSHIP_TYPE_BIKE, 461, 89000 },      // PCJ-600

    // BOAT
    { DEALERSHIP_TYPE_BOAT, 473, 30000 },      // Dinghy
    { DEALERSHIP_TYPE_BOAT, 453, 50000 },      // Reefer
    { DEALERSHIP_TYPE_BOAT, 446, 150000 },     // Squallo
    { DEALERSHIP_TYPE_BOAT, 452, 200000 },     // Speeder
    { DEALERSHIP_TYPE_BOAT, 454, 250000 },     // Tropic
    { DEALERSHIP_TYPE_BOAT, 484, 280000 },     // Marquis
    { DEALERSHIP_TYPE_BOAT, 493, 300000 },     // Jetmax

    // AIRCRAFT
    { DEALERSHIP_TYPE_AIRCRAFT, 593, 1550000 }, // Dodo
    { DEALERSHIP_TYPE_AIRCRAFT, 512, 1550000 }, // Cropduster
    { DEALERSHIP_TYPE_AIRCRAFT, 513, 1510000 }, // Stuntplane
    { DEALERSHIP_TYPE_AIRCRAFT, 511, 1800000 }, // Beagle
    { DEALERSHIP_TYPE_AIRCRAFT, 487, 1770000 }, // Maverick
    { DEALERSHIP_TYPE_AIRCRAFT, 519, 1800000 }, // Shamal
    { DEALERSHIP_TYPE_AIRCRAFT, 553, 2100000 }  // Nevada
};


// Stock per dealership per catalogue entry (same index as DealershipCars). Only meaningful while the
// dealership is owned; a vacant one ignores it.
new DealerStock [ MAX_DEALERSHIPS ] [ sizeof ( DealershipCars ) ] ;

// ---------------------------------------------------------------------------------------------
// Catalogue helpers
// ---------------------------------------------------------------------------------------------

// Returns the price of a model in the dealership catalogue.
stock DealerShip_GetModelPrice(modelid) {

    for ( new i, j = sizeof (DealershipCars ) ; i < j ; i ++ ) {

        if ( DealershipCars [ i ] [ dealercar_carmodel ] == modelid ) {

            return DealershipCars [ i ] [ dealercar_price ] ;
        }
    }

    return 7500 ;
}

// New price of a model from the catalogue, or 0 if no dealership sells it.
Vehicle_GetCatalogPrice(modelid) {

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_carmodel ] == modelid ) {

			return DealershipCars [ i ] [ dealercar_price ] ;
		}
	}

	return 0 ;
}

// Index into DealershipCars of a model sold by this dealership type, or -1.
Dealer_GetCatalogIndex(type, modelid) {

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_type ] == type && DealershipCars [ i ] [ dealercar_carmodel ] == modelid ) {

			return i ;
		}
	}

	return -1 ;
}

// What an owner pays the manufacturer for one car.
Dealer_GetWholesale(price) {

	return price * DEALER_WHOLESALE_PCT / 100 ;
}

// Starting stock a new owner is given for a model, scaled by price so a $2M aircraft doesn't come
// with five free copies. Admins can edit any of it afterwards with /dealeradmin stock.
Dealer_GetDefaultStock(price) {

	if ( price <= 50000 ) return 5 ;
	if ( price <= 150000 ) return 3 ;
	if ( price <= 500000 ) return 2 ;

	return 1 ;
}

// Writes the name of a dealership type.
Dealer_GetTypeName(type, name[], len = sizeof ( name )) {

	switch ( type ) {

		case DEALERSHIP_TYPE_BUDGET: 	format ( name, len, "Budget" ) ;
		case DEALERSHIP_TYPE_MUSCLE: 	format ( name, len, "Muscle" ) ;
		case DEALERSHIP_TYPE_SPORTS: 	format ( name, len, "Sports" ) ;
		case DEALERSHIP_TYPE_UTILITY: 	format ( name, len, "Utility" ) ;
		case DEALERSHIP_TYPE_BIKE: 		format ( name, len, "Bike" ) ;
		case DEALERSHIP_TYPE_AIRCRAFT: 	format ( name, len, "Aircraft" ) ;
		case DEALERSHIP_TYPE_BOAT: 		format ( name, len, "Boat" ) ;
		case DEALERSHIP_TYPE_SHIP: 		format ( name, len, "Ship" ) ;
		default: 						format ( name, len, "Unknown" ) ;
	}

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Lookups
// ---------------------------------------------------------------------------------------------

// Returns true if the dealership id is valid.
bool: Dealership_IsValid(dealerid) {

	return dealerid >= 0 && dealerid < MAX_DEALERSHIPS && Dealerships [ dealerid ] [ dealership_sqlid ] > 0 ;
}

// Returns true if the dealership has an owner.
bool: Dealership_IsOwned(dealerid) {

	return Dealership_IsValid ( dealerid ) && Dealerships [ dealerid ] [ dealership_owner_char ] > 0 ;
}

// Returns a dealership's type.
stock Dealership_GetType(dealerid)
{
    if ( ! Dealership_IsValid ( dealerid ) )
        return -1;

    return Dealerships[dealerid][dealership_type];
}

// Returns a free dealership slot.
Dealership_GetFreeID() {

	for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

		if ( Dealerships [ i ] [ dealership_sqlid ] == 0 ) {

			return i ;
		}
	}

	return INVALID_DEALERSHIP_ID ;
}

// Finds a dealership by SQL id.
Dealership_GetBySqlId(sqlid) {

	if ( sqlid <= 0 ) {

		return INVALID_DEALERSHIP_ID ;
	}

	for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

		if ( Dealerships [ i ] [ dealership_sqlid ] == sqlid ) {

			return i ;
		}
	}

	return INVALID_DEALERSHIP_ID ;
}

// The dealership a character owns, or INVALID_DEALERSHIP_ID.
Dealership_GetOwnedBy(character_id) {

	if ( character_id <= 0 ) {

		return INVALID_DEALERSHIP_ID ;
	}

	for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

		if ( Dealerships [ i ] [ dealership_sqlid ] > 0 && Dealerships [ i ] [ dealership_owner_char ] == character_id ) {

			return i ;
		}
	}

	return INVALID_DEALERSHIP_ID ;
}

// Returns the dealership closest to the player.
Dealership_GetClosestEntity(playerid) {

	for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

		if ( Dealerships [ i ] [ dealership_sqlid ] <= 0 ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint ( playerid, 2.5, Dealerships [ i ] [ dealership_pos_x ],
			Dealerships [ i ] [ dealership_pos_y ], Dealerships [ i ] [ dealership_pos_z ] ) ) {

			return i ;
		}
	}

	return INVALID_DEALERSHIP_ID ;
}

// Tells the owner (if they are online) something happened to their dealership.
Dealership_NotifyOwner(dealerid, const message[]) {

	if ( ! Dealership_IsOwned ( dealerid ) ) {

		return false ;
	}

	foreach ( new i : Player ) {

		if ( IsPlayerLogged ( i ) && Character [ i ] [ E_CHARACTER_ID ] == Dealerships [ dealerid ] [ dealership_owner_char ] ) {

			SendClientMessage ( i, COLOR_INFO, message ) ;
			return true ;
		}
	}

	return false ;
}

// ---------------------------------------------------------------------------------------------
// Bank and stock (all changes are written straight to the database)
// ---------------------------------------------------------------------------------------------

// Saves the dealership's bank balance.
Dealership_SaveBank(dealerid) {

	new query [ 128 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE dealerships SET dealer_bank = %d WHERE dealer_id = %d",
		Dealerships [ dealerid ] [ dealership_bank ], Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// Adds money to the dealership's bank.
Dealership_AddBank(dealerid, amount) {

	if ( ! Dealership_IsValid ( dealerid ) || amount <= 0 ) {

		return false ;
	}

	Dealerships [ dealerid ] [ dealership_bank ] += amount ;
	Dealership_SaveBank ( dealerid ) ;

	return true ;
}

// Takes money from the dealership's bank (false if there isn't enough).
bool: Dealership_TakeBank(dealerid, amount) {

	if ( ! Dealership_IsValid ( dealerid ) || amount <= 0 || Dealerships [ dealerid ] [ dealership_bank ] < amount ) {

		return false ;
	}

	Dealerships [ dealerid ] [ dealership_bank ] -= amount ;
	Dealership_SaveBank ( dealerid ) ;

	return true ;
}

// Sets the stock of a catalogue item.
Dealership_SetStock(dealerid, cat_index, qty) {

	if ( ! Dealership_IsValid ( dealerid ) || cat_index < 0 || cat_index >= sizeof ( DealershipCars ) ) {

		return false ;
	}

	if ( qty < 0 ) {

		qty = 0 ;
	}

	DealerStock [ dealerid ] [ cat_index ] = qty ;

	new query [ 160 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "REPLACE INTO dealership_stock (dealer_id, model_id, qty) VALUES (%d, %d, %d)",
		Dealerships [ dealerid ] [ dealership_sqlid ], DealershipCars [ cat_index ] [ dealercar_carmodel ], qty ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// Clears the stock of a dealership.
Dealership_ClearStock(dealerid) {

	if ( ! Dealership_IsValid ( dealerid ) ) {

		return false ;
	}

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		DealerStock [ dealerid ] [ i ] = 0 ;
	}

	new query [ 96 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM dealership_stock WHERE dealer_id = %d", Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// Replaces whatever stock there is with the starting stock for a new owner.
Dealership_FillDefaultStock(dealerid) {

	if ( ! Dealership_IsValid ( dealerid ) ) {

		return false ;
	}

	Dealership_ClearStock ( dealerid ) ;

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_type ] != Dealerships [ dealerid ] [ dealership_type ] ) {

			continue ;
		}

		Dealership_SetStock ( dealerid, i, Dealer_GetDefaultStock ( DealershipCars [ i ] [ dealercar_price ] ) ) ;
	}

	return true ;
}

// Total number of cars on the lot.
Dealership_CountStock(dealerid) {

	new total ;

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		if ( DealershipCars [ i ] [ dealercar_type ] == Dealerships [ dealerid ] [ dealership_type ] ) {

			total += DealerStock [ dealerid ] [ i ] ;
		}
	}

	return total ;
}

// ---------------------------------------------------------------------------------------------
// World objects: label, pickup and map icon
// ---------------------------------------------------------------------------------------------

// Refreshes the dealership's 3D label.
Dealership_RefreshLabel(dealerid) {

	if ( IsValidDynamic3DTextLabel ( Dealerships [ dealerid ] [ dealership_label ] ) ) {

		DestroyDynamic3DTextLabel ( Dealerships [ dealerid ] [ dealership_label ] ) ;
	}

	new text [ 192 ] ;

	if ( Dealership_IsOwned ( dealerid ) ) {

		format ( text, sizeof ( text ), "%s\n{A3A3A3}Owner: {DEDEDE}%s\n{DEDEDE}Commands: /dealership",
			Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_owner_name ] ) ;
	}

	else {

		format ( text, sizeof ( text ), "%s\n{DEDEDE}Commands: /dealership", Dealerships [ dealerid ] [ dealership_name ] ) ;
	}

	Dealerships [ dealerid ] [ dealership_label ] = CreateDynamic3DTextLabel ( text, Dealerships [ dealerid ] [ dealership_color ],
		Dealerships [ dealerid ] [ dealership_pos_x ], Dealerships [ dealerid ] [ dealership_pos_y ], Dealerships [ dealerid ] [ dealership_pos_z ],
		15.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, 0, 0, -1 ) ;

	return true ;
}

// Creates the dealership's pickup and label.
Dealership_CreateVisuals(dealerid) {

	Dealership_RefreshLabel ( dealerid ) ;

	// Loaded, created or moved: the GPS list follows the dealership.
	GPS_SyncDealerships () ;

	Dealerships [ dealerid ] [ dealership_pickup ] = CreateDynamicPickup ( 1581, 1, Dealerships [ dealerid ] [ dealership_pos_x ],
		Dealerships [ dealerid ] [ dealership_pos_y ], Dealerships [ dealerid ] [ dealership_pos_z ] ) ;

	Dealerships [ dealerid ] [ dealership_icon ] = CreateDynamicMapIcon ( Dealerships [ dealerid ] [ dealership_pos_x ],
		Dealerships [ dealerid ] [ dealership_pos_y ], Dealerships [ dealerid ] [ dealership_pos_z ], 55, 0, -1, -1, -1, STREAMER_MAP_ICON_SD, MAPICON_GLOBAL ) ;

	return true ;
}

// Destroys the dealership's pickup and label.
Dealership_DestroyVisuals(dealerid) {

	if ( IsValidDynamic3DTextLabel ( Dealerships [ dealerid ] [ dealership_label ] ) ) {

		DestroyDynamic3DTextLabel ( Dealerships [ dealerid ] [ dealership_label ] ) ;
	}

	if ( IsValidDynamicPickup ( Dealerships [ dealerid ] [ dealership_pickup ] ) ) {

		DestroyDynamicPickup ( Dealerships [ dealerid ] [ dealership_pickup ] ) ;
	}

	if ( IsValidDynamicMapIcon ( Dealerships [ dealerid ] [ dealership_icon ] ) ) {

		DestroyDynamicMapIcon ( Dealerships [ dealerid ] [ dealership_icon ] ) ;
	}

	Dealerships [ dealerid ] [ dealership_label ] = DynamicText3D: INVALID_STREAMER_ID ;
	Dealerships [ dealerid ] [ dealership_pickup ] = INVALID_STREAMER_ID ;
	Dealerships [ dealerid ] [ dealership_icon ] = INVALID_STREAMER_ID ;

	return true ;
}

// Clears a dealership's data.
Dealership_ClearEntity(dealerid) {

	new blank [ DealershipData ] ;

	Dealerships [ dealerid ] = blank ;
	Dealerships [ dealerid ] [ dealership_label ] = DynamicText3D: INVALID_STREAMER_ID ;
	Dealerships [ dealerid ] [ dealership_pickup ] = INVALID_STREAMER_ID ;
	Dealerships [ dealerid ] [ dealership_icon ] = INVALID_STREAMER_ID ;

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

		DealerStock [ dealerid ] [ i ] = 0 ;
	}

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Ownership changes
// ---------------------------------------------------------------------------------------------

// Hands a dealership to a character. The bank starts at zero (nothing to withdraw that the owner
// didn't earn) and the owner gets the starting stock.
Dealership_SetOwner(dealerid, character_id, const character_name[]) {

	if ( ! Dealership_IsValid ( dealerid ) ) {

		return false ;
	}

	Dealerships [ dealerid ] [ dealership_owner_char ] = character_id ;
	Dealerships [ dealerid ] [ dealership_owner_name ] [ 0 ] = EOS ;
	strcat ( Dealerships [ dealerid ] [ dealership_owner_name ], character_name, 32 ) ;
	Dealerships [ dealerid ] [ dealership_bank ] = 0 ;
	Dealerships [ dealerid ] [ dealership_owner_since ] = gettime () ;
	Dealerships [ dealerid ] [ dealership_last_seen ] = gettime () ;

	new query [ 384 ] ;

	mysql_format ( mysql, query, sizeof ( query ),
		"UPDATE dealerships SET dealer_owner_char_id = %d, dealer_owner_name = '%e', dealer_bank = 0, dealer_owner_since = %d, dealer_owner_last_seen = %d WHERE dealer_id = %d",
		character_id, Dealerships [ dealerid ] [ dealership_owner_name ], Dealerships [ dealerid ] [ dealership_owner_since ],
		Dealerships [ dealerid ] [ dealership_last_seen ], Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM dealership_applications WHERE character_id = %d", character_id ) ;
	mysql_tquery ( mysql, query ) ;

	Dealership_FillDefaultStock ( dealerid ) ;
	Dealership_RefreshLabel ( dealerid ) ;

	return true ;
}

// Removes the owner (foreclosure, resignation or an admin action). Whatever is in the bank was
// earned, so it's paid out to the former owner's bank account. Stock goes back to the manufacturer.
Dealership_Vacate(dealerid, const reason[]) {

	if ( ! Dealership_IsOwned ( dealerid ) ) {

		return false ;
	}

	new char_id = Dealerships [ dealerid ] [ dealership_owner_char ], payout = Dealerships [ dealerid ] [ dealership_bank ], query [ 256 ] ;

	if ( payout > 0 ) {

		foreach ( new i : Player ) {

			if ( IsPlayerLogged ( i ) && Character [ i ] [ E_CHARACTER_ID ] == char_id ) {

				Character [ i ] [ E_CHARACTER_BANKCASH ] += payout ;
				SendClientMessage ( i, COLOR_INFO, sprintf ( "[Dealership] $%s from the dealership bank was paid into your bank account.", IntegerWithDelimiter ( payout ) ) ) ;
				break ;
			}
		}

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE characters SET player_bankcash = player_bankcash + %d WHERE player_id = %d", payout, char_id ) ;
		mysql_tquery ( mysql, query ) ;
	}

	printf ( " * [DEALERSHIP] %s (%d) vacated: char %d, payout $%d, reason: %s", Dealerships [ dealerid ] [ dealership_name ], Dealerships [ dealerid ] [ dealership_sqlid ], char_id, payout, reason ) ;

	Dealerships [ dealerid ] [ dealership_owner_char ] = 0 ;
	Dealerships [ dealerid ] [ dealership_owner_name ] [ 0 ] = EOS ;
	Dealerships [ dealerid ] [ dealership_bank ] = 0 ;
	Dealerships [ dealerid ] [ dealership_owner_since ] = 0 ;
	Dealerships [ dealerid ] [ dealership_last_seen ] = 0 ;

	mysql_format ( mysql, query, sizeof ( query ),
		"UPDATE dealerships SET dealer_owner_char_id = 0, dealer_owner_name = '', dealer_bank = 0, dealer_owner_since = 0, dealer_owner_last_seen = 0 WHERE dealer_id = %d",
		Dealerships [ dealerid ] [ dealership_sqlid ] ) ;
	mysql_tquery ( mysql, query ) ;

	Dealership_ClearStock ( dealerid ) ;
	Dealership_RefreshLabel ( dealerid ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------------------------

// Loads dealership stock from the database.
Dealership_LoadStock() {

	inline Dealership_OnStockLoad() {

		for ( new i = 0, r = cache_num_rows(); i < r; i ++ ) {

			new sqlid, modelid, qty ;

			cache_get_value_name_int ( i, "dealer_id", sqlid ) ;
			cache_get_value_name_int ( i, "model_id", modelid ) ;
			cache_get_value_name_int ( i, "qty", qty ) ;

			new dealerid = Dealership_GetBySqlId ( sqlid ) ;

			if ( dealerid == INVALID_DEALERSHIP_ID ) {

				continue ;
			}

			new cat_index = Dealer_GetCatalogIndex ( Dealerships [ dealerid ] [ dealership_type ], modelid ) ;

			if ( cat_index != -1 ) {

				DealerStock [ dealerid ] [ cat_index ] = qty ;
			}
		}
	}

	MySQL_TQueryInline ( mysql, using inline Dealership_OnStockLoad, "SELECT dealer_id, model_id, qty FROM dealership_stock", "" ) ;

	return true ;
}

// Loads dealerships from the database.
Dealership_LoadEntities() {

	for ( new i; i < MAX_DEALERSHIPS; i ++ ) {

		Dealership_DestroyVisuals ( i ) ;
		Dealership_ClearEntity ( i ) ;
	}

	print ( " * [DEALERSHIP] Loading dealerships..." ) ;

	inline Dealership_OnDataLoad() {

		new loaded ;

		for ( new i = 0, r = cache_num_rows(); i < r && i < MAX_DEALERSHIPS; i ++ ) {

			cache_get_value_name_int ( i, "dealer_id", Dealerships [ i ] [ dealership_sqlid ] ) ;
			cache_get_value_name_int ( i, "dealer_type", Dealerships [ i ] [ dealership_type ] ) ;
			cache_get_value_name_int ( i, "dealer_color", Dealerships [ i ] [ dealership_color ] ) ;
			cache_get_value_name ( i, "dealer_name", Dealerships [ i ] [ dealership_name ], 64 ) ;

			cache_get_value_name_float ( i, "dealer_pos_x", Dealerships [ i ] [ dealership_pos_x ] ) ;
			cache_get_value_name_float ( i, "dealer_pos_y", Dealerships [ i ] [ dealership_pos_y ] ) ;
			cache_get_value_name_float ( i, "dealer_pos_z", Dealerships [ i ] [ dealership_pos_z ] ) ;
			cache_get_value_name_float ( i, "dealer_spawn_x", Dealerships [ i ] [ dealership_spawn_x ] ) ;
			cache_get_value_name_float ( i, "dealer_spawn_y", Dealerships [ i ] [ dealership_spawn_y ] ) ;
			cache_get_value_name_float ( i, "dealer_spawn_z", Dealerships [ i ] [ dealership_spawn_z ] ) ;
			cache_get_value_name_float ( i, "dealer_spawn_a", Dealerships [ i ] [ dealership_spawn_a ] ) ;

			cache_get_value_name_int ( i, "dealer_owner_char_id", Dealerships [ i ] [ dealership_owner_char ] ) ;
			cache_get_value_name ( i, "dealer_owner_name", Dealerships [ i ] [ dealership_owner_name ], 32 ) ;
			cache_get_value_name_int ( i, "dealer_bank", Dealerships [ i ] [ dealership_bank ] ) ;
			cache_get_value_name_int ( i, "dealer_owner_since", Dealerships [ i ] [ dealership_owner_since ] ) ;
			cache_get_value_name_int ( i, "dealer_owner_last_seen", Dealerships [ i ] [ dealership_last_seen ] ) ;

			Dealership_CreateVisuals ( i ) ;
			loaded ++ ;
		}

		printf ( " * [DEALERSHIP] Loaded %d dealerships.", loaded ) ;

		Dealership_LoadStock () ;
	}

	MySQL_TQueryInline ( mysql, using inline Dealership_OnDataLoad, "SELECT * FROM dealerships ORDER BY dealer_id ASC", "" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Staff commands carried over from the old system
// ---------------------------------------------------------------------------------------------

// /gotodealer [id] - (admin) teleports to a dealership.
CMD:gotodealer(playerid, params[]) {

    if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_LEAD ) {

        return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
    }

	new sqlid ;

	if ( sscanf ( params, "i", sqlid ) ) {

		SendClientMessage(playerid, COLOR_GRAD0, "/gotodealer [dealership id]");
		return SendClientMessage(playerid, COLOR_INFO, "Use /dealeradmin list to see the dealership ids.");
	}

	new dealerid = Dealership_GetBySqlId ( sqlid ) ;

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "That isn't a valid dealership id. Use /dealeradmin list.");
	}

	PauseAC(playerid, 3);
	SetPlayerPos ( playerid, Dealerships [ dealerid ] [ dealership_pos_x ], Dealerships [ dealerid ] [ dealership_pos_y ], Dealerships [ dealerid ] [ dealership_pos_z ] ) ;
	SetPlayerInterior(playerid, 0);
	SetPlayerVirtualWorld(playerid, 0);

	return true ;
}

// /togds - (admin) toggles the dealership system.
CMD:togds(playerid, params[]){

	if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_MANAGER)
		return false;

	if ( !Server [ E_SERVER_IS_DS_OFF ] ){

		Server [ E_SERVER_IS_DS_OFF ] = true;
		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You have closed all server dealerships." );

		return true;

	} else if ( Server [ E_SERVER_IS_DS_OFF ]) {

		Server [ E_SERVER_IS_DS_OFF ] = false;
		SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You have opened all server dealerships." );

		return true;
	}

	return true;
}

// ---------------------------------------------------------------------------------------------
// Buying a new car
// ---------------------------------------------------------------------------------------------

// Returns the discount percent a player gets at dealerships.
static stock Dealer_GetDiscountPercent(playerid)
{
    switch (Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL])
    {
        case E_PREMIUM_LVL_4: return 20; // Gold
        case E_PREMIUM_LVL_3: return 10; // Silver
    }

    return 0; // Regular + Early Supporter + Bronze
}

// /dealership - opens the dealership catalogue.
CMD:dealership(playerid, params[]) {
	if ( IsPlayerIncapacitated(playerid, false) ) {

        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new dealerid = Dealership_GetClosestEntity(playerid);

	if ( dealerid == INVALID_DEALERSHIP_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Error{A3A3A3}: You're not at a dealership!");
	}

	if( Server [ E_SERVER_IS_DS_OFF ] )
		return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Dealerships are currently unavailable." );

	if ( ! Character [ playerid ] [ E_CHARACTER_DRIVERSLICENSE ]) {
		SendClientMessage(playerid, COLOR_ERROR, "You don't own a drivers license, you need one to purchase a vehicle.");
	}

	if ( Player_GetOwnedVehicles ( playerid ) >= Player_GetMaxOwnedVehicles ( playerid ) ) {
		SendServerMessage ( playerid, COLOR_YELLOW, "Error", "A3A3A3", "You don't have any vehicle ownership slots left. Use /myslots to check." );
		SendClientMessage ( playerid, COLOR_ERROR, "You won't be able to buy anything in this store until you get more slots.");
	}

    new dealer_name [ 128 ], slot_hex[12], slots, bool: owned = Dealership_IsOwned ( dealerid ) ;
	ModelBrowser_ClearData(playerid);

	for ( new i, j = sizeof ( DealershipCars ); i < j; i ++ ) {

    	if ( DealershipCars [ i ] [ dealercar_type ] == Dealerships [ dealerid ] [ dealership_type] ) {

    		new stock_text [ 24 ] ;

    		// A vacant dealership always has everything. An owned one only sells what it has in stock.
    		if ( owned ) {

    			if ( DealerStock [ dealerid ] [ i ] > 0 ) {

    				format ( stock_text, sizeof ( stock_text ), " ~w~x%d", DealerStock [ dealerid ] [ i ] ) ;
    			}

    			else format ( stock_text, sizeof ( stock_text ), " ~r~OUT OF STOCK" ) ;
    		}

    		if ( Dealerships [ dealerid ] [ dealership_type]  == DEALERSHIP_TYPE_UTILITY ) {
    		 	slots = GetMaxStorageModel(DealershipCars [ i ] [ dealercar_carmodel ]) ;


    			if ( ! slots ) {

    				format ( slot_hex, sizeof ( slot_hex ), "~r~" ) ;
    			}

    			else format ( slot_hex, sizeof ( slot_hex ), "~g~" ) ;

				format ( dealer_name, sizeof ( dealer_name ), "%s ($%s) %s%d slots%s",
					ReturnVehicleModelName (  DealershipCars [ i ] [ dealercar_carmodel ] ),
					IntegerWithDelimiter( DealershipCars [ i ] [ dealercar_price ] ), slot_hex, slots, stock_text
				) ;
    		}

    		else {
				format ( dealer_name, sizeof ( dealer_name ), "%s ($%s)%s",
					ReturnVehicleModelName (  DealershipCars [ i ] [ dealercar_carmodel ] ),
					IntegerWithDelimiter( DealershipCars [ i ] [ dealercar_price ] ), stock_text
				) ;
			}

			ModelBrowser_AddData(playerid, DealershipCars [ i ] [ dealercar_carmodel ], dealer_name ) ;
		}
	}

	ModelBrowser_SetupTiles(playerid, "Dealership", "dealer_list" );

    return true ;
}

// Model browser callback: the player picks a vehicle to buy.
mBrowser:dealer_list(playerid, response, row, model, name[]) {

	if ( ! response ) {

		return true ;
	}

	else if ( response ) {
		new dealerid = Dealership_GetClosestEntity(playerid);

		if ( dealerid == INVALID_DEALERSHIP_ID ) {

			return SendClientMessage(playerid, COLOR_ERROR, "Error{A3A3A3}: You're not at a dealership!");
		}

		new enumid = Dealer_GetCatalogIndex ( Dealerships [ dealerid ] [ dealership_type ], model ) ;

		if (enumid == -1)
		{
			return SendClientMessage(playerid, COLOR_ERROR, "Vehicle not found.");
		}

		new basePrice = DealershipCars[enumid][dealercar_price];
		new discountPercent = Dealer_GetDiscountPercent(playerid);
		new finalPrice = basePrice;

		if (discountPercent > 0)
		{
			finalPrice = basePrice - (basePrice * discountPercent / 100);
		}

		new bool: owned = Dealership_IsOwned ( dealerid ) ;

		if ( owned && DealerStock [ dealerid ] [ enumid ] <= 0 ) {

			return SendClientMessage(playerid, COLOR_ERROR, "This vehicle is out of stock. The dealership owner needs to order more.");
		}

		if ( GetPlayerCash ( playerid ) < finalPrice ) {

			return SendClientMessage(playerid, COLOR_RED, "You don't have enough money for this vehicle!");
		}

		if ( Player_GetOwnedVehicles ( playerid ) >= Player_GetMaxOwnedVehicles ( playerid ) ) {
			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have any vehicle ownership slots left. Use /myslots to check." );
		}

		TakePlayerCash(playerid, finalPrice, "Vehicle dealer purchase");

		if ( owned ) {

			// The owner is always credited the full catalogue price, so a premium discount is paid for
			// by the server and never comes out of the owner's pocket.
			Dealership_SetStock ( dealerid, enumid, DealerStock [ dealerid ] [ enumid ] - 1 ) ;
			Dealership_AddBank ( dealerid, basePrice ) ;

			Dealership_NotifyOwner ( dealerid, sprintf ( "[Dealership] A %s was sold for $%s (%d left in stock).",
				ReturnVehicleModelName ( model ), IntegerWithDelimiter ( basePrice ), DealerStock [ dealerid ] [ enumid ] ) ) ;

			if ( DealerStock [ dealerid ] [ enumid ] == 0 ) {

				Dealership_NotifyOwner ( dealerid, sprintf ( "[Dealership] You are now out of %s. Use /dealerorder to restock.", ReturnVehicleModelName ( model ) ) ) ;
			}
		}

        //AddPlayerRespect(playerid, 15);
        //GiveFnRPoints(playerid, 20, "Purchased vehicle", false);

		Vehicle_CreateEntity ( playerid, model, E_VEHICLE_TYPE_PLAYER, Character [ playerid ] [ E_CHARACTER_ID ],  Dealerships[dealerid][dealership_spawn_x], Dealerships[dealerid][dealership_spawn_y], Dealerships[dealerid][dealership_spawn_z], Dealerships[dealerid][dealership_spawn_a], 0, 0, random (255), random (255), false, E_VEHICLE_JOB_NONE ) ;

		if (discountPercent > 0)
		{
			SendClientMessage(playerid, COLOR_VEHICLE,
				sprintf("You bought a (%d) %s, original: $%s, VIP discount: %d%%, final price: $%s.",
					DealershipCars[enumid][dealercar_carmodel],
					ReturnVehicleModelName(DealershipCars[enumid][dealercar_carmodel]),
					IntegerWithDelimiter(basePrice),
					discountPercent,
					IntegerWithDelimiter(finalPrice)
				)
			);
		}
		else
		{
			SendClientMessage(playerid, COLOR_VEHICLE,
				sprintf("You bought a (%d) %s, price: $%s. For help, use /carhelp.",
					DealershipCars[enumid][dealercar_carmodel],
					ReturnVehicleModelName(DealershipCars[enumid][dealercar_carmodel]),
					IntegerWithDelimiter(finalPrice)
				)
			);
		}

		// NEW LOGGING: Log this as a LOG_TYPE_SCRIPT for both
		AddLogEntry(playerid, LOG_TYPE_SCRIPT,
			sprintf("Bought a %s for $%d (discount %d%%)",
				ReturnVehicleModelName(DealershipCars[enumid][dealercar_carmodel]),
				finalPrice,
				discountPercent
			)
		);

	}

	return true ;
}
