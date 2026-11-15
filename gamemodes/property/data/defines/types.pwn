// ============================================================================
// File: property/data/defines/types.pwn
// Buy point types (E_BUY_TYPE_*: 24/7, liquor, clothing, restaurant, fast food, bank, hospital,
// hardware...) with their names, map icons, pickups and commands. /buypointtypes lists them.
// Commands: /buypointtypes
// ============================================================================

enum {

	E_BUY_TYPE_NONE = 0,
	E_BUY_TYPE_GENERAL = 1, // 24/7
	E_BUY_TYPE_LIQUOR,
	E_BUY_TYPE_CLOTHING,
	E_BUY_TYPE_ELECTRONIC,
	E_BUY_TYPE_JEWELRY,
	E_BUY_TYPE_RESTAURANT,

	E_BUY_TYPE_FOOD_CLUCKINBELL,
	E_BUY_TYPE_FOOD_PIZZASTACK,
	E_BUY_TYPE_FOOD_BURGERSHOT,
	E_BUY_TYPE_FOOD_DONUTS,
	E_BUY_TYPE_FOOD_RINGS,

	E_BUY_TYPE_BANK,
	E_BUY_TYPE_HOSPITAL,
	E_BUY_TYPE_BARBERSHOP,
	E_BUY_TYPE_DEALERSHIP,
	E_BUY_TYPE_GASSTATION,
	E_BUY_TYPE_MODSHOP,
	E_BUY_TYPE_AMMUNATION,
	E_BUY_TYPE_MUSIC,
	E_BUY_TYPE_HARDWARE,
	E_BUY_TYPE_POLICE_STATION,
	
	E_BUY_TYPE_FOOD_CLUCKINBELL_DT,
	E_BUY_TYPE_FOOD_PIZZA_DT,
	E_BUY_TYPE_GYM,
	E_BUY_TYPE_GOV,
	E_BUY_TYPE_BAITSHOP,
	E_BUY_TYPE_PAWN,
	E_BUY_TYPE_COMMISSARY
	// add more when the need is there
}

enum E_PROPERTY_TYPE_DATA {

	E_PROPERTY_TYPE_CONST,
	E_PROPERTY_TYPE_PICKUP,
	E_PROPERTY_TYPE_MAPICON,
	E_PROPERTY_TYPE_NAME [ 32 ],
	E_PROPERTY_TYPE_CMDS [128]
} ;

new PropertyTypeData [ ] [ E_PROPERTY_TYPE_DATA ] = {

	{ E_BUY_TYPE_NONE,					19524, 0, "Undefined",						"None" } ,
	{ E_BUY_TYPE_GENERAL,				19523, 17, "General",						"/buy" } ,
	{ E_BUY_TYPE_LIQUOR,				19523, 49, "Liquor",						"/buy" } ,
	{ E_BUY_TYPE_CLOTHING,				19523, 45, "Clothing",						"/buy\nView the Attach Points to access this shop." } ,
	{ E_BUY_TYPE_ELECTRONIC,			19523, 35, "Electronic",					"/buy" } ,
	{ E_BUY_TYPE_JEWELRY,				19523, 33, "Jewelry",						"None\nView the Attach Points to access this shop." } ,
	{ E_BUY_TYPE_RESTAURANT,			19523, 50, "Restaurant",					"/buy" } ,
	{ E_BUY_TYPE_BAITSHOP,				19523, 9,  "Bait Shop",						"/buy, /sellfish" } ,
	{ E_BUY_TYPE_FOOD_CLUCKINBELL,		19523, 14, "Cluckin' Bell",					"/buy" } ,
	{ E_BUY_TYPE_FOOD_CLUCKINBELL_DT,	19523, 14, "Cluckin' Bell Drive-thru",		"/buy" } ,
	{ E_BUY_TYPE_FOOD_PIZZASTACK,		19523, 29, "Pizza Stack",					"/buy" } ,
	{ E_BUY_TYPE_FOOD_PIZZA_DT, 		19523, 29, "Pizza Stack Drive-thru",		"/buy" } ,
	{ E_BUY_TYPE_FOOD_BURGERSHOT,		19523, 10, "Burgershot",					"/buy" } ,
	{ E_BUY_TYPE_FOOD_DONUTS,			19523, 16, "Rusty's Donuts",				"/buy" } ,
	{ E_BUY_TYPE_FOOD_RINGS,			19523, 16, "Jim's Sticky Rings",			"/buy" }, // new alhambra
	{ E_BUY_TYPE_BANK,					1274, 52, "Bank",							"/balance, /withdraw, /deposit, /savings" } ,
	{ E_BUY_TYPE_HOSPITAL,				1240, 22, "Hospital",						"/surgery\nWarning: Surgery may cost up to $1,000!" } ,
	{ E_BUY_TYPE_POLICE_STATION,		1247, 30, "Police Station", 				"None" },
	{ E_BUY_TYPE_BARBERSHOP,			19523, 7, "Barbershop",						"None\nView the Attach Points to access this shop." } ,
	{ E_BUY_TYPE_DEALERSHIP,			1581, 55, "Dealership",						"/dealership" } ,
	{ E_BUY_TYPE_GASSTATION,			19523, 53, "Gas Station",					"/gascan, /fillcar" } ,
	{ E_BUY_TYPE_MODSHOP,				19627, 27, "Mod Shop",						"/tune" },
	{ E_BUY_TYPE_AMMUNATION,			19523, 6, "Ammu-Nation",					"/buy" }, 
	{ E_BUY_TYPE_MUSIC,					19523, 48, "Music Shop",					"/buy" }, 
	{ E_BUY_TYPE_HARDWARE,				19523, 27, "Hardware",						"/buy" },
	{ E_BUY_TYPE_GYM,					2916, 54, "Gym",			 				"None" },
	{ E_BUY_TYPE_GOV,					19522, 32, "Government",					"None" },
	{ E_BUY_TYPE_PAWN,					19522, 35, "Pawn Shop",						"/sellgoods" },
	{ E_BUY_TYPE_COMMISSARY,			19592, 36, "Commissary",					"/buy" }
} ;

// /buypointtypes - lists the buy point type ids for admins.
CMD:buypointtypes(playerid, params[]) {

	SendClientMessage(playerid, COLOR_PROPERTY, "Buy Point Types" ) ;
	for ( new i, j = sizeof ( PropertyTypeData ); i < j ; i ++ ) {

		SendClientMessage(playerid, COLOR_INFO, sprintf("(%d) %s", PropertyTypeData [ i ] [ E_PROPERTY_TYPE_CONST ], PropertyTypeData [ i ] [ E_PROPERTY_TYPE_NAME ]));
	}

	return true ;
}

// Writes a buy point type's name.
PropertyType_GetName(constant, name[], len = sizeof ( name ) ) {

	format ( name, len, "Invalid" ) ;

	// Looping and finding the index to avoid enum changes messing up indexes
	for ( new i , j = sizeof ( PropertyTypeData ); i < j ; i ++ ) {
		if ( PropertyTypeData [ i ] [ E_PROPERTY_TYPE_CONST ] == constant ) {

			format ( name, len, "%s", PropertyTypeData [ i ] [ E_PROPERTY_TYPE_NAME ]  ) ;
		}
	}
}
// Writes the command used at a buy point type.
PropertyType_GetCommand(constant, name[], len = sizeof ( name ) ) {

	format ( name, len, "Invalid" ) ;

	// Looping and finding the index to avoid enum changes messing up indexes
	for ( new i , j = sizeof ( PropertyTypeData ); i < j ; i ++ ) {
		if ( PropertyTypeData [ i ] [ E_PROPERTY_TYPE_CONST ] == constant ) {

			format ( name, len, "%s", PropertyTypeData [ i ] [ E_PROPERTY_TYPE_CMDS ]  ) ;
		}
	}
}

// Returns the pickup model for a buy point type.
PropertyType_GetPickup(constant ) {

	// Looping and finding the index to avoid enum changes messing up indexes
	for ( new i , j = sizeof ( PropertyTypeData ); i < j ; i ++ ) {
		if ( PropertyTypeData [ i ] [ E_PROPERTY_TYPE_CONST ] == constant ) {

			return PropertyTypeData [ i ] [ E_PROPERTY_TYPE_PICKUP ]  ;
		}
	}

	return 1272 ;
}

// Returns the map icon for a buy point type.
PropertyType_GetMapIcon(constant ) {

	// Looping and finding the index to avoid enum changes messing up indexes
	for ( new i , j = sizeof ( PropertyTypeData ); i < j ; i ++ ) {
		if ( PropertyTypeData [ i ] [ E_PROPERTY_TYPE_CONST ] == constant ) {

			return PropertyTypeData [ i ] [ E_PROPERTY_TYPE_MAPICON ]  ;
		}
	}

	return 0 ;
}
