// ============================================================================
// File: vehicle/data/data.pwn
// Core vehicle data. Defines the Vehicle[] array (model, owner, type, plate, colours, fuel,
// mileage, mods...) and VehicleVar[] runtime state, the vehicle types (personal, faction, job,
// rental...) and plate generation.
// ============================================================================

new const VehicleColoursTableRGBA[256][7] = {
    // The existing colours from San Andreas
    "FFFFFF", "F5F5F5", "2A77A1", "840410", "263739", "86446E", "D78E10", "4C75B7", "BDBEC6", "5E7072",
    "46597A", "656A79", "5D7E8D", "58595A", "D6DAD6", "9CA1A3", "335F3F", "730E1A", "7B0A2A", "9F9D94",
    "3B4E78", "732E3E", "691E3B", "96918C", "515459", "3F3E45", "A5A9A7", "635C5A", "3D4A68", "979592",
    "421F21", "5F272B", "8494AB", "767B7C", "646464", "5A5752", "252527", "2D3A35", "93A396", "6D7A88",
    "221918", "6F675F", "7C1C2A", "5F0A15", "193826", "5D1B20", "9D9872", "7A7560", "989586", "ADB0B0",
    "848988", "304F45", "4D6268", "162248", "272F4B", "7D6256", "9EA4AB", "9C8D71", "6D1822", "4E6881",
    "9C9C98", "917347", "661C26", "949D9F", "A4A7A5", "8E8C46", "341A1E", "6A7A8C", "AAAD8E", "AB988F",
    "851F2E", "6F8297", "585853", "9AA790", "601A23", "20202C", "A4A096", "AA9D84", "78222B", "0E316D",
    "722A3F", "7B715E", "741D28", "1E2E32", "4D322F", "7C1B44", "2E5B20", "395A83", "6D2837", "A7A28F",
    "AFB1B1", "364155", "6D6C6E", "0F6A89", "204B6B", "2B3E57", "9B9F9D", "6C8495", "4D8495", "AE9B7F",
    "406C8F", "1F253B", "AB9276", "134573", "96816C", "64686A", "105082", "A19983", "385694", "525661",
    "7F6956", "8C929A", "596E87", "473532", "44624F", "730A27", "223457", "640D1B", "A3ADC6", "695853",
    "9B8B80", "620B1C", "5B5D5E", "624428", "731827", "1B376D", "EC6AAE", "FFFFFF",
    // SA-MP extended colours (0.3x)
    "177517", "210606", "125478", "452A0D", "571E1E", "010701", "25225A", "2C89AA", "8A4DBD", "35963A",
    "B7B7B7", "464C8D", "84888C", "817867", "817A26", "6A506F", "583E6F", "8CB972", "824F78", "6D276A",
    "1E1D13", "1E1306", "1F2518", "2C4531", "1E4C99", "2E5F43", "1E9948", "1E9999", "999976", "7C8499",
    "992E1E", "2C1E08", "142407", "993E4D", "1E4C99", "198181", "1A292A", "16616F", "1B6687", "6C3F99",
    "481A0E", "7A7399", "746D99", "53387E", "222407", "3E190C", "46210E", "991E1E", "8D4C8D", "805B80",
    "7B3E7E", "3C1737", "733517", "781818", "83341A", "8E2F1C", "7E3E53", "7C6D7C", "020C02", "072407",
    "163012", "16301B", "642B4F", "368452", "999590", "818D96", "99991E", "7F994C", "839292", "788222",
    "2B3C99", "3A3A0B", "8A794E", "0E1F49", "15371C", "15273A", "375775", "060820", "071326", "20394B",
    "2C5089", "15426C", "103250", "241663", "692015", "8C8D94", "516013", "090F02", "8C573A", "52888E",
    "995C52", "99581E", "993A63", "998F4E", "99311E", "0D1842", "521E1E", "42420D", "4C991E", "082A1D",
    "96821D", "197F19", "3B141F", "745217", "893F8D", "7E1A6C", "0B370B", "27450D", "071F24", "784573",
    "8A653A", "732617", "319490", "56941D", "59163D", "1B8A2F", "38160B", "041804", "355D8E", "2E3F5B",
    "561A28", "4E0E27", "706C67", "3B3E42", "2E2D33", "7B7E7D", "4A4442", "28344E"
};

new const vehicleColorNames[][] = {
	// The existing colours from San Andreas
    "Black", "White", "Police Blue", "Cherry Red", "Midnight Blue", "Temple Curtain Purple", "Taxi Yellow", "Striking Blue",
    "Light Blue Grey", "Steel Grey", "Saxony Blue", "Concord Blue", "Jasper Green", "Pewter Grey", "Frost White", "Silver Stone",
    "Rio Red", "Torino Red Pearl", "Formula Red", "Honey Beige", "Mariner Blue", "Blaze Red", "Classic Red", "Winning Silver",
    "Steel Grey", "Shadow Silver", "Silver Stone", "Warm Grey Mica", "Harbor Blue", "Porcelain Silver", "Mellow Burgundy", "Graceful Red Mica",
    "Currant Blue", "Grey", "Arctic White", "Anthracite Grey", "Black", "Dark Green", "Seafoam", "Diamond Blue",
    "Biston Brown", "Desert Taupe", "Garnet Red", "Desert Red", "Green", "Cabernet Red", "Light Ivory", "Pueblo Beige",
    "Smoke Silver", "Astra Silver", "Ascot Grey", "Agate Green", "Petrol Blue Green", "Surf Blue", "Nautical Blue", "Woodrose",
    "Crystal Blue", "Bisque Frost", "Currant Red", "Light Crystal Blue", "Light Titanium", "Race Yellow", "Brt. Currant Red", "Clear Crystal Blue Frost",
    "Silver", "Pastel Alabaster", "Mid Currant Red", "Medium Regatta Blue", "Oxford White", "Alabaster", "Elec. Currant Red", "Spinnaker Blue",
    "Dark Titanium", "Pastel Alabaster", "Medium Cabernet", "Twilight Blue", "Titanium Frost", "Sandalwood Frost", "Wild Strawberry", "Ultra Blue",
    "Vermilion", "Medium Sandalwood", "Medium Red", "Deep Jewel Green", "Medium Woodrose", "Vermillion", "Green", "Bright Blue",
    "Bright Red", "Light Champagne", "Silver", "Steel Blue", "Medium Grey", "Arctic Pearl", "Nassau Blue", "Medium Sapphire Blue",
    "Silver", "Light Sapphire Blue", "Malachite", "Flax", "Medium Maui Blue", "Dark Sapphire Blue", "Copper Beige", "Bright Blue",
    "Medium Flax", "Medium Grey", "Bright Blue", "Light Driftwood", "Blue", "Steel Grey", "Light Beechwood", "Slate Grey",
    "Light Sapphire Blue", "Dark Beechwood", "Torch Red", "Bright Red", "Medium Sapphire Blue Firemist", "Medium Garnet Red", "White Diamond Pearl", "Dark Sable",
    "Antelope Beige", "Brilliant Red", "Gun Metal", "Medium Beechwood", "Brilliant Red", "Bright Blue", "Pink", "Black",
	// SA-MP extended colours (0.3x)
	"Forest Green", "Deep Brown", "Steel Blue", "Dark Chestnut", "Wine Red", "Midnight Green", "Indigo Blue", "Teal Blue", "Royal Purple", "Jungle Green",
	"Silver Grey", "Slate Blue", "Storm Grey", "Olive Tan", "Mustard Olive", "Plum Grey", "Dark Amethyst", "Fern Green", "Dusty Rose", "Dark Magenta",
	"Charcoal Brown", "Umber", "Deep Moss", "Dark Sage", "Cobalt Blue", "Deep Teal", "Emerald Green", "Sea Green", "Muted Olive", "Steel Teal",
	"Brick Red", "Burnt Umber", "Deep Olive", "Dusky Rose", "Azure Blue", "Dark Cyan", "Slate Teal", "Ocean Blue", "Deep Sky", "Royal Indigo",
	"Mahogany", "Muted Lavender", "Soft Lilac", "Grape Purple", "Dark Olive", "Rust Brown", "Cocoa Brown", "Crimson Red", "Heather Purple", "Dusty Violet",
	"Vintage Plum", "Deep Burgundy", "Rustic Brown", "Crimson Core", "Brandy Red", "Burnt Carmine", "Dusky Rosewood", "Muted Mauve", "Dark Forest", "Mosswood",
	"Deep Pine", "Teal Moss", "Muted Plum", "Forest Jade", "Ash Grey", "Muted Azure", "Golden Olive", "Moss Green", "Slate Grey", "Goldenrod",
	"Royal Navy", "Deep Olive", "Golden Brown", "Indigo Midnight", "Dark Fern", "Midnight Blue", "Deep Sapphire", "Storm Navy", "Twilight Blue", "Deep Aqua",
	"Steel Blue", "Deep Brown", "Indigo Blue", "Dark Chestnut", "Wine Red", "Silver Grey", "Jungle Green", "Midnight Green", "Plum Grey", "Teal Blue",
	"Rust Brown", "Mustard Olive", "Dark Magenta", "Olive Tan", "Burnt Umber", "Indigo Midnight", "Charcoal Brown", "Olive Tan", "Emerald Green", "Forest Green",
	"Golden Brown", "Emerald Green", "Crimson Red", "Rustic Brown", "Grape Purple", "Burnt Carmine", "Dark Green", "Jungle Green", "Storm Grey", "Dusty Violet",
	"Rust Brown", "Burnt Umber", "Teal Moss", "Fern Green", "Dark Magenta", "Forest Jade", "Charcoal Brown", "Midnight Green", "Cobalt Blue", "Royal Navy",
	"Crimson Red", "Crimson Core", "Slate Grey", "Storm Grey", "Dark Forest", "Silver Grey", "Charcoal Brown", "Indigo Blue"
};

#define MAX_VEHICLE_ATTACH_SLOTS (5)

enum VehicleData {

	E_VEHICLE_SQLID,
	E_VEHICLE_ID,
	E_VEHICLE_MODELID,

	E_VEHICLE_TYPE, // if type = faction, owner = factionid. if player, owner = player db id
	E_VEHICLE_JOBID, // 0: none, 1: dockw
	E_VEHICLE_OWNER,
	E_VEHICLE_COLOR_A,
	E_VEHICLE_COLOR_B,

	E_VEHICLE_ATTACH_MODEL[MAX_VEHICLE_ATTACH_SLOTS],
	Float: E_VEHICLE_ATTACH_X[MAX_VEHICLE_ATTACH_SLOTS],
	Float: E_VEHICLE_ATTACH_Y[MAX_VEHICLE_ATTACH_SLOTS],
	Float: E_VEHICLE_ATTACH_Z[MAX_VEHICLE_ATTACH_SLOTS],
	Float: E_VEHICLE_ATTACH_RX[MAX_VEHICLE_ATTACH_SLOTS],
	Float: E_VEHICLE_ATTACH_RY[MAX_VEHICLE_ATTACH_SLOTS],
	Float: E_VEHICLE_ATTACH_RZ[MAX_VEHICLE_ATTACH_SLOTS],

	E_VEHICLE_MILEAGE,

	E_VEHICLE_IS_SPAWNED,
	Float: E_VEHICLE_POS_X,
	Float: E_VEHICLE_POS_Y,
	Float: E_VEHICLE_POS_Z,
	Float: E_VEHICLE_POS_A,
	E_VEHICLE_VW,
	E_VEHICLE_INT,

	E_VEHICLE_LICENSE [ 16 ],
	E_VEHICLE_STATION,

	bool:E_VEHICLE_SIREN,
	E_VEHICLE_SQUAD,

	E_VEHICLE_ENGINE,
	E_VEHICLE_DOORS,
	E_VEHICLE_FUEL,
	E_VEHICLE_WINDOW,

	E_VEHICLE_TRUNK_WEP [ 10 ],
	E_VEHICLE_TRUNK_AMMO [ 10 ],

	E_VEHICLE_TRUNK_DRUGS_TYPE [ 10 ],
	E_VEHICLE_TRUNK_DRUGS_PARAM [ 10 ],
	E_VEHICLE_TRUNK_DRUGS_CONTAINER [ 10 ],
	Float: E_VEHICLE_TRUNK_DRUGS_AMOUNT [ 10 ],

	E_VEHICLE_TRUNK_BURGLARY_MODEL [ 10 ],

	E_VEHICLE_NOS,
	E_VEHICLE_NEON [ 2 ],

	E_VEHICLE_PAINTJOB,
	Float: E_VEHICLE_HEALTH, 
	E_VEHICLE_DMG_PANELS,
	E_VEHICLE_DMG_DOORS,
	E_VEHICLE_DMG_LIGHTS,
	E_VEHICLE_DMG_TIRES,

	DynamicText3D: E_VEHICLE_LABEL,
	DynamicText3D: E_VEHICLE_TAXISIGN,

	E_VEHICLE_PASSENGER, // Cached frontseat passenger - not reset if they leave vehicle so always check they are in it
	E_VEHICLE_DOOR_STATE[4], // For /cardoor

	E_VEHICLE_PARKED_AT, // For /carpark, saved in db

	E_VEHICLE_IMPOUNDED, // For impound

	E_VEHICLE_SALE_PRICE, // used car lot asking price, 0 = not for sale
	E_VEHICLE_POOLED_AT, // unix time a scrapped car entered the used pool (0 = not pooled)
	E_VEHICLE_POOL_VALUE, // what the scrapper was paid, and what a used car firm pays to take it

	E_VEHICLE_OIL_SERVICE_MILES, // odometer reading at the last oil change (oil is due OIL_SERVICE_INTERVAL miles later)
	E_VEHICLE_ENGINE_WEAR, // 0-1000, wears while running on overdue oil, 1000 = seized
	E_VEHICLE_REPAIR_READY, // unix time a car left at a Pay'n'Spray can be collected, 0 = not in the workshop
}
#if defined MAX_VEHICLES 
	#undef MAX_VEHICLES 
#endif
#define MAX_VEHICLES (3000) // default: 2000

new Vehicle [ MAX_VEHICLES ] [ VehicleData ]; //, vehicleCount ; 

// Resets the label handles of a vehicle.
stock Vehicle_ResetLabelHandles(vehicle_enum_id)
{
	Vehicle [ vehicle_enum_id ] [ E_VEHICLE_LABEL ] = DynamicText3D:INVALID_STREAMER_ID ;
	Vehicle [ vehicle_enum_id ] [ E_VEHICLE_TAXISIGN ] = DynamicText3D:INVALID_STREAMER_ID ;
}

// Destroys a vehicle's 3D label.
stock Vehicle_DestroyLabel(vehicle_enum_id)
{
	if ( IsValidDynamic3DTextLabel( Vehicle [ vehicle_enum_id ] [ E_VEHICLE_LABEL ] ) ) {
		DestroyDynamic3DTextLabel( Vehicle [ vehicle_enum_id ] [ E_VEHICLE_LABEL ] ) ;
	}

	Vehicle [ vehicle_enum_id ] [ E_VEHICLE_LABEL ] = DynamicText3D:INVALID_STREAMER_ID ;
}

// Destroys a taxi's roof sign.
stock Vehicle_DestroyTaxiSign(vehicle_enum_id)
{
	if ( IsValidDynamic3DTextLabel( Vehicle [ vehicle_enum_id ] [ E_VEHICLE_TAXISIGN ] ) ) {
		DestroyDynamic3DTextLabel( Vehicle [ vehicle_enum_id ] [ E_VEHICLE_TAXISIGN ] ) ;
	}

	Vehicle [ vehicle_enum_id ] [ E_VEHICLE_TAXISIGN ] = DynamicText3D:INVALID_STREAMER_ID ;
}

enum VehicleVarData {

	E_VEHICLE_VAR_FUEL_INCR,
	Timer: E_VEHICLE_NOS_TICK,

	E_VEHICLE_RECENT_DEATH,
	Float:E_VEHICLE_DEATH_POS[4],
	Float:E_VEHICLE_DEATH_HEALTH,

	E_VEHICLE_TRUCKER_ITEM [ 64 ],
	E_VEHICLE_TRUCKER_MODEL [ 64 ],
	E_VEHICLE_TRUCKER_ORIGIN [ 64 ],    // depot each crate was picked up at, for distance pay

    E_VEHICLE_STATION [ 126 ],

	E_VEHICLE_RENTEDBY,
	E_VEHICLE_RENTUNIX,
	E_VEHICLE_FLAME_OBJECT,
	E_VEHICLE_FIRE_OBJECTS[2],
	bool:E_VEHICLE_CAN_EXPLODE,

	E_VEHICLE_SCANNER_CHANNEL,

	E_VEHICLE_LAST_USED, // unix

	Float: E_VEHICLE_MILE_FRAC, // fraction of a mile driven since E_VEHICLE_MILEAGE last ticked over (not saved)
	Float: E_VEHICLE_MILE_LAST_X, // where the car was at the last mileage sample, to measure how far it really moved
	Float: E_VEHICLE_MILE_LAST_Y,
	Float: E_VEHICLE_MILE_LAST_Z,
	E_VEHICLE_MILE_LAST_TICK, // GetTickCount() of that sample (0 = no sample yet)

	// Percentage points of wrong-type fuel currently sitting in the tank (accumulates across
	// fills, cleared by a mechanic's /mechanic drainfuel). 0 = clean, 1-20 = rough start,
	// 21+ = explodes on start. Persisted via the vehicle_wrong_fuel_amount DB column
	// (loaded in Vehicle_LoadEntities, saved wherever this field changes) so contamination
	// survives logout/login and server restarts.
	E_VEHICLE_WRONG_FUEL_AMOUNT
} ;

new VehicleVar [ MAX_VEHICLES ] [ VehicleVarData ] ;

enum { // veh types

	E_VEHICLE_TYPE_INVALID = -1,
	E_VEHICLE_TYPE_DEFAULT = 0, // no lock, no engine, usable by anyone
	E_VEHICLE_TYPE_RENTAL,
	E_VEHICLE_TYPE_DMV,
	E_VEHICLE_TYPE_PLAYER,
	E_VEHICLE_TYPE_FACTION,
	E_VEHICLE_TYPE_JOB,
	E_VEHICLE_TYPE_FIRM
}

enum { // veh job ids
	E_VEHICLE_JOB_NONE = 0,
	E_VEHICLE_JOB_DOCKWORKER,
	E_VEHICLE_JOB_GARBAGEJOB,
	E_VEHICLE_JOB_BOATYARDJOB,
	E_VEHICLE_JOB_PIZZA,
	E_VEHICLE_JOB_TRUCKER,
}

// Clears the runtime-only variables of a vehicle slot (fuel timers, labels...).
Vehicle_ClearRuntimeVariables(vehicle_enum_id)
{
	// Wrong-fuel contamination belongs to the vehicle itself (it is saved in the database), so it has
	// to survive being parked and spawned again. Only a mechanic draining the tank (or an admin) clears it.
	new wrong_fuel = VehicleVar[vehicle_enum_id][E_VEHICLE_WRONG_FUEL_AMOUNT];

	new var_clear[VehicleVarData];
	VehicleVar[vehicle_enum_id] = var_clear;

	VehicleVar[vehicle_enum_id][E_VEHICLE_WRONG_FUEL_AMOUNT] = wrong_fuel;
}

#include "vehicle/data/staticveh.pwn"


Vehicle_CreateEntity ( playerid, veh_model, veh_type, veh_owner, Float: veh_pos_x, Float: veh_pos_y, Float: veh_pos_z, Float: veh_pos_a, veh_vw, veh_int, veh_color_a, veh_color_b, veh_siren = false, veh_job = E_VEHICLE_JOB_NONE ) {
	#pragma unused veh_siren

	new veh_enum_id = Vehicle_GetFreeID () ;
	new plate[8];
	new purchase_date = gettime();

	if (  veh_enum_id == -1 ) {

		return print("* [VEHICLE] No free enum IDs left - [Vehicle_CreateEntity] failed!!");
	}

	if ( ! IsValidVehicleModel ( veh_model ) ) {

		return printf("* [VEHICLE] Invalid model %d - [Vehicle_CreateEntity] refused, nothing inserted.", veh_model);
	}

	//new veh_enum_id = vehicleCount ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] 		= veh_model ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] 			= veh_type ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] 		= veh_owner ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_JOBID ]			= veh_job ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_SIREN ]			= false ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_SQUAD ]         = -1 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_A ] 		= veh_color_a ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_B ] 		= veh_color_b ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_IS_SPAWNED ]	= false ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ] 		= veh_pos_x ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ] 		= veh_pos_y ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ] 		= veh_pos_z ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ] 		= veh_pos_a ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ] 			= veh_vw ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ] 			= veh_int ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_STATION ]		= -1 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE ]		= false ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ]			= false ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ]			= 25 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ]		= true ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_PAINTJOB ] = 3 ;
 
	Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ]		= 1000.0;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_PANELS ] 	= 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_DOORS ] 	= 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_LIGHTS ] 	= 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_TIRES ] 	= 0 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_PARKED_AT ] = 0;
	Vehicle_AttachResetData(veh_enum_id);

	Vehicle [ veh_enum_id ] [ E_VEHICLE_IMPOUNDED ] = 0;
	Vehicle_ResetLabelHandles(veh_enum_id);
	Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_OIL_SERVICE_MILES ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_REPAIR_READY ] = 0 ;
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] = 0 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ] [ 0 ] = EOS ;
	do { GenerateLicensePlate(plate, sizeof(plate)); } while (IsLicensePlateTaken(plate));
	strcat(Vehicle[veh_enum_id][E_VEHICLE_LICENSE], plate);
	new query [ 1024 ] ; 

	mysql_format ( mysql, query, sizeof ( query ), "INSERT INTO vehicles (vehicle_modelid, vehicle_type, vehicle_jobid, vehicle_owner, vehicle_color_a, vehicle_color_b, vehicle_pos_x, vehicle_pos_y, vehicle_pos_z, vehicle_pos_a, vehicle_vw, vehicle_int, vehicle_license, vehicle_fuel, vehicle_health, vehicle_dmg_panels, vehicle_dmg_doors, vehicle_dmg_lights, vehicle_dmg_tires, vehicle_paintjob, vehicle_siren, vehicle_squad, vehicle_purchase_date) VALUES (%d, %d, %d, %d, %d, %d, '%f', '%f', '%f', '%f', %d, %d, '%e', %d, '1000.0', 0, 0, 0, 0, 3, 0, -1, %d)",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_JOBID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_B ],
		 Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ] , Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ] , Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ], Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ], Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ], purchase_date ) ;

	inline Vehicle_OnDatabaseInsert() {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] = cache_insert_id ();
		printf(" * [VEHICLE] Created vehicle (%d) with ID %d.", 
			veh_enum_id, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;

		SendServerMessage(playerid, COLOR_BLUE, "Vehicle", "A3A3A3", sprintf("To spawn your car, use /carspawn %d.", Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ) ;
	}

	MySQL_TQueryInline(mysql, using inline Vehicle_OnDatabaseInsert, query, "");


	return Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ;
}


Vehicle_CreateEntity_Spawn ( playerid, veh_model, veh_type, veh_owner, Float: veh_pos_x, Float: veh_pos_y, Float: veh_pos_z, Float: veh_pos_a, veh_vw, veh_int, veh_color_a, veh_color_b, veh_siren = false, veh_job = E_VEHICLE_JOB_NONE ) {
	#pragma unused veh_siren

	new veh_enum_id = Vehicle_GetFreeID () ;
	new plate[8];

	if (  veh_enum_id == -1 ) {

		return print("* [VEHICLE] No free enum IDs left - [Vehicle_CreateEntity] failed!!");
	}

	if ( ! IsValidVehicleModel ( veh_model ) ) {

		return printf("* [VEHICLE] Invalid model %d - [Vehicle_CreateEntity] refused, nothing inserted.", veh_model);
	}

	//new veh_enum_id = vehicleCount ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ] 		= veh_model ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ] 			= veh_type ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ] 		= veh_owner ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_JOBID ]			= veh_job ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_SIREN ]			= false ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_SQUAD ]         = -1 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_A ] 		= veh_color_a ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_B ] 		= veh_color_b ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ] 		= veh_pos_x ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ] 		= veh_pos_y ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ] 		= veh_pos_z ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ] 		= veh_pos_a ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_VW] 			= veh_vw ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ] 			= veh_int ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_STATION ]		= -1 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE ]		= false ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ]			= false ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ]			= 25 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_WINDOW ]		= true ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_PAINTJOB ] = 3 ;
 
	Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ]		= 1000.0;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_PANELS ] 	= 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_DOORS ] 	= 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_LIGHTS ] 	= 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_DMG_TIRES ] 	= 0 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_PARKED_AT ] = 0;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_IMPOUNDED ] = 0;
	Vehicle_ResetLabelHandles(veh_enum_id);
	Vehicle [ veh_enum_id ] [ E_VEHICLE_MILEAGE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_SALE_PRICE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOLED_AT ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_POOL_VALUE ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_OIL_SERVICE_MILES ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE_WEAR ] = 0 ;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_REPAIR_READY ] = 0 ;
	VehicleVar [ veh_enum_id ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] = 0 ;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ] [ 0 ] = EOS ;
	do { GenerateLicensePlate(plate, sizeof(plate)); } while (IsLicensePlateTaken(plate));
	strcat(Vehicle[veh_enum_id][E_VEHICLE_LICENSE], plate);
	new query [ 1024 ] ; 

	mysql_format ( mysql, query, sizeof ( query ), "INSERT INTO vehicles (vehicle_modelid, vehicle_type, vehicle_jobid, vehicle_owner, vehicle_color_a, vehicle_color_b, vehicle_pos_x, vehicle_pos_y, vehicle_pos_z, vehicle_pos_a, vehicle_vw, vehicle_int, vehicle_license, vehicle_fuel, vehicle_health, vehicle_dmg_panels, vehicle_dmg_doors, vehicle_dmg_lights, vehicle_dmg_tires, vehicle_paintjob, vehicle_siren, vehicle_squad) VALUES (%d, %d, %d, %d, %d, %d, '%f', '%f', '%f', '%f', %d, %d, '%e', %d, '1000.0', 0, 0, 0, 0, 3, 0, -1)",
		Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_JOBID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_OWNER ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_B ],
		 Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ] , Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ] , Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ], Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ],
		 Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ], Vehicle [ veh_enum_id ] [ E_VEHICLE_FUEL ]  ) ;

	inline Vehicle_OnDatabaseInsert() {

		Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] = cache_insert_id ();
		printf(" * [VEHICLE] Created vehicle (%d) with ID %d.", 
			veh_enum_id, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ] ) ;

		Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] = ORP_CreateVehicle(	Vehicle [ veh_enum_id ] [ E_VEHICLE_MODELID], 
			Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_X ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Y ], Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_Z ],
			Vehicle [ veh_enum_id ] [ E_VEHICLE_POS_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_VW ], Vehicle [ veh_enum_id ] [ E_VEHICLE_INT ],
			Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_A ], Vehicle [ veh_enum_id ] [ E_VEHICLE_COLOR_B ], -1
		) ;

		Temp_SetVehicleEnumId(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], veh_enum_id);

		Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ] = 1000 ;
		ORP_SetVehicleHealth ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_HEALTH ] ); 

		SetVehicleNumberPlate(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_LICENSE ] ) ;

		SetEngineStatus(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ENGINE ]);
		SetDoorStatus(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_DOORS ]);

		Vehicle [ veh_enum_id ] [ E_VEHICLE_IS_SPAWNED ] = true ;
		ChangeVehiclePaintjob(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_PAINTJOB ] ) ;
		Tune_ApplyComponents(veh_enum_id );
		Vehicle_ClearRuntimeVariables(veh_enum_id);
		Vehicle_ClearTruckerVariables(veh_enum_id);
		Scanner_Reset(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ]);

		JT_PutPlayerInVehicle(playerid, Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] , 0);
		Vehicle_SetDoorsEngineStatus(veh_enum_id ) ;
	}

	MySQL_TQueryInline(mysql, using inline Vehicle_OnDatabaseInsert, query, "");

	printf(" * [VEHICLE] Created entity ID %d (veh: %d) [type %d] at %0.2f, %0.2f, %0.2f", veh_enum_id, 
		Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], Vehicle [ veh_enum_id ] [ E_VEHICLE_TYPE ], veh_pos_x, veh_pos_y, veh_pos_z ) ;


	return Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ;
}

// Sets a vehicle's doors and engine status from its saved state.
Vehicle_SetDoorsEngineStatus(index ) {

	new i = index ;

	switch ( Vehicle [ i ] [ E_VEHICLE_TYPE ] ) {
		case E_VEHICLE_TYPE_INVALID: {

			SetEngineStatus(Vehicle [ i ] [ E_VEHICLE_ID ], false );
			SetDoorStatus(Vehicle [ i ] [ E_VEHICLE_ID ], true );
		}
		case E_VEHICLE_TYPE_DEFAULT: {

			SetEngineStatus(Vehicle [ i ] [ E_VEHICLE_ID ], false );
			SetDoorStatus(Vehicle [ i ] [ E_VEHICLE_ID ], true );
		}
		case E_VEHICLE_TYPE_FACTION: {

			SetEngineStatus(Vehicle [ i ] [ E_VEHICLE_ID ], false );
			SetDoorStatus(Vehicle [ i ] [ E_VEHICLE_ID ], true );
		}

		case E_VEHICLE_TYPE_FIRM: {

			SetEngineStatus(Vehicle [ i ] [ E_VEHICLE_ID ], false );
			SetDoorStatus(Vehicle [ i ] [ E_VEHICLE_ID ], true );
		}

		case E_VEHICLE_TYPE_JOB: {

			SetEngineStatus(Vehicle [ i ] [ E_VEHICLE_ID ], false );
			SetDoorStatus(Vehicle [ i ] [ E_VEHICLE_ID ], false );
		}

		default: {

			SetEngineStatus(Vehicle [ i ] [ E_VEHICLE_ID ], Vehicle [ i ] [ E_VEHICLE_ENGINE ]);
			SetDoorStatus(Vehicle [ i ] [ E_VEHICLE_ID ], Vehicle [ i ] [ E_VEHICLE_DOORS ]);	
		}
	}

	if (  Vehicle [ i ] [ E_VEHICLE_MODELID ] == 481 || Vehicle [ i ] [ E_VEHICLE_MODELID ] == 509 || Vehicle [ i ] [ E_VEHICLE_MODELID ] == 510 ) {

		Vehicle [ i ] [ E_VEHICLE_TYPE ] = E_VEHICLE_TYPE_DEFAULT ;
		SetEngineStatus(Vehicle [ i ] [ E_VEHICLE_ID ], true );
		SetDoorStatus(Vehicle [ i ] [ E_VEHICLE_ID ], false );
	}
}

// Loads every vehicle from the database and creates it.
Vehicle_LoadEntities() {

	new vehicle_wrong_fuel_amount_load [ MAX_VEHICLES ] ;

	for ( new i, j = sizeof ( Vehicle ); i < j ; i ++ ) {

		Vehicle [ i ] [ E_VEHICLE_SQLID ] = -1 ;
		Vehicle_ResetLabelHandles(i);

		VehicleVar [ i ] [ E_VEHICLE_RENTEDBY ] = INVALID_PLAYER_ID ;
		VehicleVar [ i ] [ E_VEHICLE_RENTUNIX ] = 0 ;
	}

	print(" * [VEHICLE] Loading all vehicles...");

	inline Vehicle_OnDataLoad() {
		new spawned_count, failed_count, dormant_count;
		for (new i = 0, r = cache_num_rows(); i < r; ++i) {
			cache_get_value_name_int (i, "vehicle_sqlid", Vehicle [ i ] [ E_VEHICLE_SQLID ]);

			cache_get_value_name_int (i, "vehicle_modelid", Vehicle [ i ] [ E_VEHICLE_MODELID ]);
			cache_get_value_name_int (i, "vehicle_type", Vehicle [ i ] [ E_VEHICLE_TYPE ]);
			cache_get_value_name_int (i, "vehicle_owner", Vehicle [ i ] [ E_VEHICLE_OWNER ]);

			cache_get_value_name_int (i, "vehicle_jobid", Vehicle [ i ] [ E_VEHICLE_JOBID ]);

			cache_get_value_name_int (i, "vehicle_color_a", Vehicle [ i ] [ E_VEHICLE_COLOR_A ]);
			cache_get_value_name_int (i, "vehicle_color_b", Vehicle [ i ] [ E_VEHICLE_COLOR_B ]);
			cache_get_value_name_int (i, "vehicle_mileage", Vehicle [ i ] [ E_VEHICLE_MILEAGE ]);


			cache_get_value_name_float ( i, "vehicle_pos_x", Vehicle [ i ] [ E_VEHICLE_POS_X ]);
			cache_get_value_name_float ( i, "vehicle_pos_y", Vehicle [ i ] [ E_VEHICLE_POS_Y ]);
			cache_get_value_name_float ( i, "vehicle_pos_z", Vehicle [ i ] [ E_VEHICLE_POS_Z ]);
			cache_get_value_name_float ( i, "vehicle_pos_a", Vehicle [ i ] [ E_VEHICLE_POS_A ]);
			cache_get_value_name_int ( i, "vehicle_vw", Vehicle [ i ] [ E_VEHICLE_VW ]);
			cache_get_value_name_int ( i, "vehicle_int", Vehicle [ i ] [ E_VEHICLE_INT ]);

			for (new va = 0; va < MAX_VEHICLE_ATTACH_SLOTS; ++va)
			{
				cache_get_value_name_int(i, sprintf("vehicle_attach_model%i", va + 1), Vehicle [ i ] [ E_VEHICLE_ATTACH_MODEL ] [ va ]);
				cache_get_value_name_float(i, sprintf("vehicle_attach_x%i", va + 1), Vehicle [ i ] [ E_VEHICLE_ATTACH_X ] [ va ]);
				cache_get_value_name_float(i, sprintf("vehicle_attach_y%i", va + 1), Vehicle [ i ] [ E_VEHICLE_ATTACH_Y ] [ va ]);
				cache_get_value_name_float(i, sprintf("vehicle_attach_z%i", va + 1), Vehicle [ i ] [ E_VEHICLE_ATTACH_Z ] [ va ]);
				cache_get_value_name_float(i, sprintf("vehicle_attach_rx%i", va + 1), Vehicle [ i ] [ E_VEHICLE_ATTACH_RX ] [ va ]);
				cache_get_value_name_float(i, sprintf("vehicle_attach_ry%i", va + 1), Vehicle [ i ] [ E_VEHICLE_ATTACH_RY ] [ va ]);
				cache_get_value_name_float(i, sprintf("vehicle_attach_rz%i", va + 1), Vehicle [ i ] [ E_VEHICLE_ATTACH_RZ ] [ va ]);
			}

			cache_get_value_name_int (i, "vehicle_siren", Vehicle [ i ] [ E_VEHICLE_SIREN ]);
			cache_get_value_name_int (i, "vehicle_squad", Vehicle [ i ] [ E_VEHICLE_SQUAD ]);
			cache_get_value_name_int (i, "vehicle_fuel", Vehicle [ i ] [ E_VEHICLE_FUEL ]);
			cache_get_value_name_int (i, "vehicle_wrong_fuel_amount", vehicle_wrong_fuel_amount_load [ i ]);

			for (new t = 0; t < 10; ++t) {
				cache_get_value_name_int (i, sprintf("vehicle_trunk_wep_%i", t + 1), Vehicle [ i ] [ E_VEHICLE_TRUNK_WEP ] [ t ]);
				cache_get_value_name_int (i, sprintf("vehicle_trunk_ammo_%i", t + 1), Vehicle [ i ] [ E_VEHICLE_TRUNK_AMMO ] [ t ]);

				cache_get_value_name_int(i, sprintf("vehicle_trunk_drugs_type_%i", t + 1), Vehicle [ i ] [ E_VEHICLE_TRUNK_DRUGS_TYPE ] [ t ]);
				cache_get_value_name_int(i, sprintf("vehicle_trunk_drugs_param_%i", t + 1), Vehicle [ i ] [ E_VEHICLE_TRUNK_DRUGS_PARAM ] [ t ]);
				cache_get_value_name_int(i, sprintf("vehicle_trunk_drugs_cont_%i", t + 1), Vehicle [ i ] [ E_VEHICLE_TRUNK_DRUGS_CONTAINER ] [ t ]);
				cache_get_value_name_float(i, sprintf("vehicle_trunk_drugs_amount_%i", t + 1), Vehicle [ i ] [ E_VEHICLE_TRUNK_DRUGS_AMOUNT ] [ t ]);
				cache_get_value_name_int(i, sprintf("vehicle_trunk_burg_%i", t + 1), Vehicle [ i ] [ E_VEHICLE_TRUNK_BURGLARY_MODEL ] [ t ]);
			}

			cache_get_value_name_int(i, "vehicle_paintjob", Vehicle [ i ] [ E_VEHICLE_PAINTJOB ]);

			cache_get_value_name_float ( i, "vehicle_health", Vehicle [ i ] [ E_VEHICLE_HEALTH ]);

			cache_get_value_name_int(i, "vehicle_dmg_panels", Vehicle [ i ] [ E_VEHICLE_DMG_PANELS ]);
			cache_get_value_name_int(i, "vehicle_dmg_doors", Vehicle [ i ] [ E_VEHICLE_DMG_DOORS ]);
			cache_get_value_name_int(i, "vehicle_dmg_lights", Vehicle [ i ] [ E_VEHICLE_DMG_LIGHTS ]);
			cache_get_value_name_int(i, "vehicle_dmg_tires", Vehicle [ i ] [ E_VEHICLE_DMG_TIRES ]);

			Vehicle [ i ] [ E_VEHICLE_STATION ]		= -1 ;

			Vehicle [ i ] [ E_VEHICLE_ENGINE ]		= false ;
			cache_get_value_name_int(i, "vehicle_doors", Vehicle [ i ] [ E_VEHICLE_DOORS ]);
			Vehicle [ i ] [ E_VEHICLE_WINDOW ]		= true ;

			cache_get_value_name_int(i, "vehicle_parked_at", Vehicle [ i ] [ E_VEHICLE_PARKED_AT ]);

			cache_get_value_name_int(i, "vehicle_impounded", Vehicle [ i ] [ E_VEHICLE_IMPOUNDED ]);
			cache_get_value_name_int(i, "vehicle_sale_price", Vehicle [ i ] [ E_VEHICLE_SALE_PRICE ]);
			cache_get_value_name_int(i, "vehicle_pooled_at", Vehicle [ i ] [ E_VEHICLE_POOLED_AT ]);
			cache_get_value_name_int(i, "vehicle_pool_value", Vehicle [ i ] [ E_VEHICLE_POOL_VALUE ]);
			cache_get_value_name_int(i, "vehicle_oil_service_miles", Vehicle [ i ] [ E_VEHICLE_OIL_SERVICE_MILES ]);
			cache_get_value_name_int(i, "vehicle_engine_wear", Vehicle [ i ] [ E_VEHICLE_ENGINE_WEAR ]);
			cache_get_value_name_int(i, "vehicle_repair_ready_at", Vehicle [ i ] [ E_VEHICLE_REPAIR_READY ]);

			cache_get_value_name(i, "vehicle_license", Vehicle [ i ] [ E_VEHICLE_LICENSE ]);

			if ( Vehicle [ i ] [ E_VEHICLE_TYPE ] != E_VEHICLE_TYPE_PLAYER )
			{
				// Faction (and firm, e.g. used car lot) vehicles must never auto-respawn via the engine timer - they
				// should only respawn through /ftow or /respawnallcars. -1 disables it.
				new veh_respawn_delay = ( Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FACTION || Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_FIRM ) ? -1 : 0 ;

				Vehicle [ i ] [ E_VEHICLE_ID ] = ORP_CreateVehicle(Vehicle [ i ] [ E_VEHICLE_MODELID ], Vehicle [ i ] [ E_VEHICLE_POS_X ], Vehicle [ i ] [ E_VEHICLE_POS_Y ], Vehicle [ i ] [ E_VEHICLE_POS_Z ],
					Vehicle [ i ] [ E_VEHICLE_POS_A ], Vehicle [ i ] [ E_VEHICLE_VW ], Vehicle [ i ] [ E_VEHICLE_INT ], Vehicle [ i ] [ E_VEHICLE_COLOR_A ], Vehicle [ i ] [ E_VEHICLE_COLOR_B ], veh_respawn_delay, Vehicle [ i ] [ E_VEHICLE_SIREN ]) ;

				if (Vehicle [ i ] [ E_VEHICLE_ID ] <= 0 || Vehicle [ i ] [ E_VEHICLE_ID ] >= MAX_VEHICLES)
				{
					failed_count ++;
					printf("VEH ERROR: tried to create invalid vehicle with SQL ID: %d, model: %d", Vehicle [ i ] [ E_VEHICLE_SQLID ], Vehicle [ i ] [ E_VEHICLE_MODELID ]);
					continue;
				}

				spawned_count ++;

				Temp_SetVehicleEnumId(Vehicle [ i ] [ E_VEHICLE_ID ], i);

				SetVehicleNumberPlate(Vehicle [ i ] [ E_VEHICLE_ID ], Vehicle [ i ] [ E_VEHICLE_LICENSE ] ) ;

				Vehicle_SetDoorsEngineStatus(i);

				Tune_ApplyComponents( i ) ;

				if ( Vehicle [ i ] [ E_VEHICLE_HEALTH ] <= 250.0 ) {

					ORP_SetVehicleHealth ( Vehicle [ i ] [ E_VEHICLE_ID ], 300 ); 
				}

				else ORP_SetVehicleHealth(Vehicle [ i ] [ E_VEHICLE_ID ], Vehicle [ i ] [ E_VEHICLE_HEALTH ] );

				ChangeVehiclePaintjob(Vehicle [ i ] [ E_VEHICLE_ID ], Vehicle [ i ] [ E_VEHICLE_PAINTJOB ] ) ;

				// Admin vehicle attachments are built by Temp_SetVehicleEnumId -> Vehicle_AttachApply

			}
			else
			{
				dormant_count ++;
				Vehicle [ i ] [ E_VEHICLE_ID ] = INVALID_VEHICLE_ID ;
			}

			Vehicle_ClearRuntimeVariables(i);
			Vehicle_ClearTruckerVariables(i);
			
			
			VehicleVar [ i ] [ E_VEHICLE_RENTEDBY ] = INVALID_PLAYER_ID ;
			VehicleVar [ i ] [ E_VEHICLE_RENTUNIX ] = 0 ;

			// Loaded above, before Vehicle_ClearRuntimeVariables wipes VehicleVar - restores
			// fuel contamination across logout/login and server restarts.
			VehicleVar [ i ] [ E_VEHICLE_WRONG_FUEL_AMOUNT ] = vehicle_wrong_fuel_amount_load [ i ] ;

			//Vehicle_Refund ( i ) ;
		}

		// Note: SA-MP 0.3DL hard-caps the live vehicle pool at 2000, regardless of
		// the script's MAX_VEHICLES define (which only sizes the in-memory arrays).
		printf(" * [VEHICLE] Loaded %d vehicle records into memory.", cache_num_rows() ) ;
		printf(" * [VEHICLE] Actually spawned %d / %d non-player vehicles (%d failed to spawn), %d player vehicles dormant (spawn on demand).",
			spawned_count, spawned_count + failed_count, failed_count, dormant_count ) ;
		printf(" * [VEHICLE] Live vehicle pool now at %d / 2000 (engine hard cap). %d slots free for /carspawn etc.",
			spawned_count, 2000 - spawned_count ) ;

		if (failed_count > 0)
		{
			if (spawned_count >= 1950)
			{
				printf(" * [VEHICLE] WARNING: %d non-player vehicles could NOT be spawned - the engine vehicle pool (2000) is full. Reduce the fleet.", failed_count) ;
			}
			else
			{
				printf(" * [VEHICLE] WARNING: %d non-player vehicle(s) failed to spawn despite %d free slots - likely a bad/unspawnable model (e.g. a train, which needs AddStaticVehicle). See the 'VEH ERROR' line(s) above for the SQL ID + model.", failed_count, 2000 - spawned_count) ;
			}
		}

		VehicleTickets_Load();
	}

	MySQL_TQueryInline(mysql, using inline Vehicle_OnDataLoad, "SELECT * FROM vehicles");

	return true ;
}

// Returns a free vehicle array slot.
Vehicle_GetFreeID() {

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( Vehicle [ i ] [ E_VEHICLE_SQLID ] == -1 ) {

			if ( ! IsValidVehicle ( Vehicle [ i ] [ E_VEHICLE_ID ] ) ) {

				return i ;
			}

			else {

				ORP_DestroyVehicle( Vehicle [ i ] [ E_VEHICLE_ID ], "getfreeid_cleanup" ) ;
				SendAdminMessage(sprintf("[Vehicle Debug] Tried to fetch new ID but found vehicle ID %d - despawning it (invalid vehicle).", Vehicle [ i ] [ E_VEHICLE_ID ]  )) ;
			}
		}

		else continue ;
	}

	return -1 ;

//	return vehicleCount ;
}

Vehicle_GetType ( vehicleid ) {

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( ! IsValidVehicle( Vehicle [ i ] [ E_VEHICLE_ID ] ) ) {

			continue ;
		}

		if ( Vehicle [ i ] [ E_VEHICLE_ID ] == vehicleid ) {

			return Vehicle [ i ] [ E_VEHICLE_TYPE ] ;
		}

		else continue ;
	}

	return -1 ;
}

/*
Vehicle_GetEnumID ( vehicleid ) {

	//#warning Make a static variable when a vehicle is created and destroyed TotalVehicleCount; (hook CreateVehicle / DestroyVehicle)

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {
	//for ( new i, j = TotalCarsSpawned; i < j; i ++ ) {

		if ( Vehicle [ i ] [ E_VEHICLE_SQLID ] == -1 ) {

			continue ;
		}


		// #warning This gets called over 5 million times within server restart. Reduce this "sizeof" to the amount of vehicles spawned.
		// #warning Uncomment this incase shit hits the roof
		
		if ( ! IsValidVehicle( Vehicle [ i ] [ E_VEHICLE_ID ] ) ) {

			continue ;
		}
		
		if ( Vehicle [ i ] [ E_VEHICLE_ID ] == vehicleid ) {

			return i ;
		}

		else continue ;
	}

	return -1 ;
}
*/

Vehicle_GetEnumIDFromSQLID ( sql_id ) {

	new index = -1 ;

	for ( new i, j = sizeof ( Vehicle ); i < j; i ++ ) {

		if ( Vehicle [ i ] [ E_VEHICLE_SQLID ] == sql_id ) {
			index = i ;
			
			break;
		}

		else continue ;
	}

	return index ;
}


// Returns the vehicle closest to the player within a radius.
Vehicle_GetClosestEntity(playerid, Float: radius = 5.0) {

    new Float:fPos[3], Float:curdistance, currentVehicle = INVALID_VEHICLE_ID;
    
    for(new v = 0; v < MAX_VEHICLES; v++) {

    	if ( IsValidVehicle ( v ) ) {
	        GetVehiclePos(v, fPos[0], fPos[1], fPos[2]);        
	        curdistance = GetPlayerDistanceFromPoint(playerid, fPos[0], fPos[1], fPos[2]);
	        
	        if(curdistance < radius) {
				if(GetVehicleVirtualWorld(v) == GetPlayerVirtualWorld(playerid))
				{
					currentVehicle = v;
	            	radius = curdistance;
				}
	        }
	    }
    }

    return currentVehicle;
}

/*
Vehicle_GetClosestEntity(playerid, Float: radius = 5.0) {
	new Float: x, Float: y, Float: z ;
	for ( new i; i < MAX_VEHICLES; i ++ ) {

		if ( IsPlayerInRangeOfPoint ( playerid, radius, x, y, z ) ) {

			return i ;
		}

		else continue ;
	}

	return INVALID_VEHICLE_ID ;
}
*/
// Returns the SQL id of the vehicle closest to the player.
stock Vehicle_GetClosestEntity_SQL(playerid) {

	new Float: x, Float: y, Float: z ;


	for ( new i; i < MAX_VEHICLES; i ++ ) {
		GetVehiclePos ( i, x, y, z ) ;

		if ( IsPlayerInRangeOfPoint ( playerid, 7.5, x, y, z ) ) {

			return Vehicle [ i ] [ E_VEHICLE_SQLID ] ;
		}

		else continue ;
	}

	return INVALID_VEHICLE_ID ;
}

// California passenger plate as of 2005: one series digit, three letters, three
// digits, no separator (e.g. "5ABC123"). Series 1 (issued from 1980) through 5
// (from 2004) were all still on the road in 2005, so older vehicles keep the
// lower series rather than every plate reading as brand new.
#define PLATE_SERIES_MAX (5)

// California skips I, O and Q in the alphabetic group to avoid 1/0 confusion.
static const PlateLetters[] = "ABCDEFGHJKLMNPRSTUVWXYZ";

// Generates a random licence plate.
stock GenerateLicensePlate(output[], size)
{
    if (size < 8) return 0;

    output[0] = '1' + random(PLATE_SERIES_MAX);            // 5
    output[1] = PlateLetters[random(sizeof(PlateLetters) - 1)]; // A
    output[2] = PlateLetters[random(sizeof(PlateLetters) - 1)]; // B
    output[3] = PlateLetters[random(sizeof(PlateLetters) - 1)]; // C
    output[4] = '0' + random(10);                          // 1
    output[5] = '0' + random(10);                          // 2
    output[6] = '0' + random(10);                          // 3
    output[7] = '\0';
    return 1;
}

// Returns true if a plate is already in use.
stock IsLicensePlateTaken(const plate[])
{
    for (new i = 0; i < MAX_VEHICLES; i++)
    {
        if (Vehicle[i][E_VEHICLE_SQLID] == -1) continue;
        if (!strcmp(Vehicle[i][E_VEHICLE_LICENSE], plate, true)) return true;
    }
    return false;
}
