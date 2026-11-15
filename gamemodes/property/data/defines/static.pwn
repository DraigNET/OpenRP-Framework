// ============================================================================
// File: property/data/defines/static.pwn
// Static buy points (places to buy food, clothes and goods that are not tied to a property).
// Mostly commented out; Property_SetupBuyPoints creates the active ones.
// ============================================================================

enum E_STATIC_BUY_POSITIONS {

	Float: E_BUY_POS_X,
	Float: E_BUY_POS_Y,
	Float: E_BUY_POS_Z,
	E_BUY_TYPE,
	E_BUY_MAPICON,
	E_BUY_PICKUP_MODEL
} ;

new BuyPoint [ ] [ E_STATIC_BUY_POSITIONS ] = {

	// Plaza Buy Points
	/*{ 1307.1794,-1460.6634,13.2402, E_BUY_TYPE_AMMUNATION, 			true }, // Plaza Ammunation
	{ 1288.1493,-1460.7418,13.1248, E_BUY_TYPE_HARDWARE, 			true }, // Plaza Tools
	{ 1252.7659,-1459.4901,13.3926, E_BUY_TYPE_FOOD_PIZZASTACK, 			true }, // Plaza Pizza
	{ 1225.7854,-1443.5502,13.1556, E_BUY_TYPE_CLOTHING, 			true }, // Plaza Clothing 1
	{ 1257.3242,-1428.0272,13.3923, E_BUY_TYPE_FOOD_DONUTS, 			true }, // Plaza Coffee
	{ 1302.0421,-1429.0155,13.4042, E_BUY_TYPE_GENERAL, 			true }, // Plaza General
	{ 1289.0636,-1460.5795,20.0547, E_BUY_TYPE_RESTAURANT, 			true }, // Plaza Bar
	{ 1283.4172,-1460.0195,20.0442, E_BUY_TYPE_JEWELRY, 			true }, // Plaza Jewelery
	{ 1264.2312,-1457.3863,20.0362, E_BUY_TYPE_MUSIC, 			true }, // Plaza Music
	{ 1291.4759,-1425.7939,20.0380, E_BUY_TYPE_ELECTRONIC, 			true }, // Plaza Electronics

	// Others
	{ 1863.5028,	-1714.0606,     13.5735, E_BUY_TYPE_FOOD_RINGS, 		true }, // New Alhambra
	{ 2414.4395, 	-1504.0961, 	23.9969, E_BUY_TYPE_FOOD_CLUCKINBELL, 	true }, // els cluckinbell
	{ 1034.7678,	-1348.2057,		13.7301, E_BUY_TYPE_FOOD_DONUTS, 		true }, // market donuts
	{ 2114.4333,	-1806.1243,		13.5546, E_BUY_TYPE_FOOD_PIZZASTACK, 	true },  // Idlewood pizzastack
	{ 2393.3416, 	-1905.6464, 	13.5541, E_BUY_TYPE_FOOD_CLUCKINBELL, 	true }, // Willowfield cluck
	{ 1924.2190,	-1771.4872,		13.5781, E_BUY_TYPE_GENERAL, 			true }, // enex_idle_buy
	{ 2427.9097,	-1744.8375,		13.6750, E_BUY_TYPE_GENERAL, 			true }, // enex_buypoint_ganton
	{ 2239.7866,	-1157.2561,		25.8594, 999, 							true}, // jeff motel

	//{ 2108.5146, 	-1813.3501, 	13.3932, E_BUY_TYPE_FOOD_PIZZA_DT, 	false },  // idle pizza (Drivethru)
	{ 2409.3032,	-1487.8939,		23.4782, E_BUY_TYPE_FOOD_CLUCKINBELL_DT, 	false }, // cluck_drivethru_els
	{ 2377.5679,	-1909.2240,		13.0324, E_BUY_TYPE_FOOD_CLUCKINBELL_DT, 	false }, // cluck_drivethru_willowfield

	//{ 1859.7758,	-1671.1080,		13.3731, E_BUY_TYPE_FOOD_BURGERSHOT, false},
	{ 1901.3927,	-1701.4585,		13.4799, E_BUY_TYPE_MUSIC, true },

	// Prison
	{ 1386.5100,-51.6208,2545.8630, E_BUY_TYPE_RESTAURANT, 			true }, // Prison Cafe
	// Hospital Cafe (County General)
	{ 1151.6713,-1331.8446,3001.1013, E_BUY_TYPE_RESTAURANT, 			true }*/ // Plaza Bar

	// The static buy points are disabled, but Pawn won't accept an empty
	// initialiser - so one dead row keeps the array legal. It's typed NONE and
	// parked far under the map, so the setup loop skips it and no proximity
	// check can ever reach it. Delete it if you re-enable the list above.
	{ 0.0, 0.0, -5000.0, E_BUY_TYPE_NONE, false, 0 }

} ;

// Creates the static buy points (pickups/labels for places that sell things outside properties).
Property_SetupBuyPoints() {


	new label [ 256 ], icon ;

	for(new i, j = sizeof ( BuyPoint ); i < j ; i ++ ) {

		// Placeholder rows carry no shop - don't give them a label or an icon.
		if ( BuyPoint [ i ] [ E_BUY_TYPE ] == E_BUY_TYPE_NONE ) continue ;

		switch ( BuyPoint [ i ] [ E_BUY_TYPE ] ) {

			case E_BUY_TYPE_GENERAL: {

				format(label, sizeof(label), "[General Store]{DEDEDE}\nAvailable Commands: /buy");
				icon = 17 ;
			}
			
			case E_BUY_TYPE_LIQUOR: {

				format(label, sizeof(label), "[Liquor Store]{DEDEDE}\nAvailable Commands: /buy");
				icon = 49 ;
			}			
			case E_BUY_TYPE_JEWELRY: {

				format(label, sizeof(label), "[Jewelry Store]{DEDEDE}\nAvailable Commands: None\nView the Attach Points to access this shop.");
				icon = 33 ;
			}

			case E_BUY_TYPE_CLOTHING: {

				format(label, sizeof(label), "[Clothing Store]{DEDEDE}\nAvailable Commands: /buy");
				icon = 45 ;
			}		
				
			case E_BUY_TYPE_ELECTRONIC: {

				format(label, sizeof(label), "[Electronic Store]{DEDEDE}\nAvailable Commands: /buy");
				icon = 35 ;
			}
	
			case E_BUY_TYPE_RESTAURANT: {
				format(label, sizeof(label), "[Restaurant]{DEDEDE}\nAvailable Commands: /buy");
				icon = 50 ;	
			}

			case E_BUY_TYPE_BAITSHOP: {
				format(label, sizeof(label), "[Bait Shop]{DEDEDE}\nAvailable Commands: /buy, /sellfish");
				icon = 9 ;	
			}

			case E_BUY_TYPE_FOOD_CLUCKINBELL: {

				format(label, sizeof(label), "[Cluckin' Bell]{DEDEDE}\nAvailable Commands: /buy");
				icon = 14 ;
			}

			case E_BUY_TYPE_FOOD_CLUCKINBELL_DT: {
				format(label, sizeof(label), "[Cluckin' Bell Drive-thru]{DEDEDE}\nAvailable Commands: /buy");
				icon = 14 ;
			}

			case E_BUY_TYPE_FOOD_PIZZASTACK: {

				format(label, sizeof(label), "[Pizza Stack]{DEDEDE}\nAvailable Commands: /buy");
				icon = 29 ;
			}
			case E_BUY_TYPE_FOOD_PIZZA_DT: {
				format(label, sizeof(label), "[Pizza Stack Drive-thru]{DEDEDE}\nAvailable Commands: /buy");
				icon = 29 ;
			}


			case E_BUY_TYPE_FOOD_BURGERSHOT: {

				format(label, sizeof(label), "[Burger Shot]{DEDEDE}\nAvailable Commands: /buy");
				icon = 10 ;
			}
			case E_BUY_TYPE_FOOD_RINGS: {

				format(label, sizeof(label), "[Jim's Sticky Rings]{DEDEDE}\nAvailable Commands: /buy");
				icon = 10 ;
			}
			case E_BUY_TYPE_FOOD_DONUTS: {

				format(label, sizeof(label), "[Coffee Shop]{DEDEDE}\nAvailable Commands: /buy");
				icon = 16 ;
			}

			case E_BUY_TYPE_BARBERSHOP: {


				format(label, sizeof(label), "[Barbershop]{DEDEDE}\nAvailable Commands: None\nView the Attach Points to access this shop.");
				icon = 7 ;
			}

			case E_BUY_TYPE_AMMUNATION: {

				format(label, sizeof(label), "[Ammu-Nation]{DEDEDE}\nAvailable Commands: /buy");
				icon = 6 ;
			}

			case E_BUY_TYPE_HARDWARE: {

				format(label, sizeof(label), "[Hardware Store]{DEDEDE}\nAvailable Commands: /buy");
				icon = 11 ;
			}

			case E_BUY_TYPE_MUSIC: {

				format(label, sizeof(label), "[Music Shop]{DEDEDE}\nAvailable Commands: /buy");
				icon = 48 ;
			}

			case 999: {
				
				format(label, sizeof(label), "[Jefferson Motel]{DEDEDE}\nAvailable Commands: None");
				icon = 37 ;
			}

			case E_BUY_TYPE_PAWN: {
				format(label, sizeof(label), "[Pawn Shop]{DEDEDE}\nAvailable Commands: /sellgoods");
				icon = 35 ;	
			}

			default: {

				format(label, sizeof(label), "[Undefined]{DEDEDE}\nAvailable Commands: none");
			}
		}

		CreateDynamic3DTextLabel(label, COLOR_PROPERTY, 
			BuyPoint [ i ] [ E_BUY_POS_X ], BuyPoint [ i ] [ E_BUY_POS_Y ], BuyPoint [ i ] [ E_BUY_POS_Z ], 
			10.0, .testlos = 1
		) ;

		if ( BuyPoint [ i ] [ E_BUY_MAPICON ] ) {
			CreateDynamicMapIcon(BuyPoint [ i ] [ E_BUY_POS_X ], BuyPoint [ i ] [ E_BUY_POS_Y ], BuyPoint [ i ] [ E_BUY_POS_Z ], icon, 0xFFFFFFFF, -1, -1, -1, 20.0 ) ;
		}

		//new pickup_model = PropertyType_GetPickup(BuyPoint [ i ] [ E_BUY_TYPE ]);
		new pickup_model = BuyPoint [ i ] [ E_BUY_PICKUP_MODEL ];
		if (pickup_model)
		{
			CreateDynamicPickup(pickup_model, 1, BuyPoint [ i ] [ E_BUY_POS_X ], BuyPoint [ i ] [ E_BUY_POS_Y ], BuyPoint [ i ] [ E_BUY_POS_Z ], .streamdistance = 50.0);
		}

		
	}

	return true ;
}


