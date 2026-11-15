// ============================================================================
// File: gates/data.pwn
// Gate data: the Gate[] array (closed/open position, speed, owner/faction access), free-slot
// lookup and loading from the `gates` table.
// ============================================================================

enum E_GATE_DATA {

	E_GATE_SQLID,
	E_GATE_STATE,

	E_GATE_TYPE,
	E_GATE_OWNER,

	Float: E_GATE_SPEED,
	Float: E_GATE_RADIUS,
	E_GATE_SETUP,
	// 0 = closed pos
	// 1 = open pos

	E_GATE_OBJECTID,
	E_GATE_INTERIOR,
	E_GATE_VIRTUALWORLD,

	E_GATE_MODELID,
	E_GATE_TOLL,
	E_GATE_AUTOCLOSE,
	E_GATE_AUTOOPEN,

	E_GATE_TEXTUREID [ 16 ],

	Float: E_GATE_CLOSED_POS_X,
	Float: E_GATE_CLOSED_POS_Y,
	Float: E_GATE_CLOSED_POS_Z,

	Float: E_GATE_CLOSED_ROT_X,
	Float: E_GATE_CLOSED_ROT_Y,
	Float: E_GATE_CLOSED_ROT_Z,

	Float: E_GATE_OPEN_POS_X,
	Float: E_GATE_OPEN_POS_Y,
	Float: E_GATE_OPEN_POS_Z,

	Float: E_GATE_OPEN_ROT_X,
	Float: E_GATE_OPEN_ROT_Y,
	Float: E_GATE_OPEN_ROT_Z
} ;

#define MAX_GATE_PAIRS 10 // expand later if needed
#define MAX_GATE_FACTIONS 5

new GateSQLPairs[MAX_GATE_PAIRS][2] = {
    {17, 18}, // Top Plaza Gash Doors
    {19, 20}, // Bottom Plaza Gash Doors
    {-1, -1},
    {-1, -1},
    {-1, -1},
    {-1, -1},
    {-1, -1},
    {-1, -1},
    {-1, -1},
    {-1, -1}
};

#if !defined MAX_GATES 
	#define MAX_GATES 	500
#endif

#if !defined INVALID_GATE_ID
	#define INVALID_GATE_ID -1
#endif

#if !defined GATE_SETUP_ID // id assigned to gates that are being mapped.
	#define GATE_SETUP_ID MAX_GATES + 1 // don 't forget to reset xd
#endif

enum {
	E_GATE_TYPE_INVALID = 0,
	E_GATE_TYPE_PUBLIC, // operatable by anyone
	E_GATE_TYPE_PLAYER, // only usable by assigned character_id
	E_GATE_TYPE_PROPERTY, // only usable by owner of property
	E_GATE_TYPE_FACTION // only usable by faction members
} ;

new Gate [ MAX_GATES ] [ E_GATE_DATA ] ;
new GateFactionAccess[MAX_GATES][MAX_GATE_FACTIONS];

new Gate_Texture_TXD [ MAX_GATES ] [ 16 ] [ 64 ] ;
new Gate_Texture_Name [ MAX_GATES ] [ 16 ] [ 64 ] ;

// Returns a text description of a gate's access type.
Gate_GetType(enum_id) {

	new gatetype [ 32 ] ;

	if ( Gate [ enum_id ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		strcat(gatetype, "Undefined" ) ;
	}

	else {

		switch ( Gate [ enum_id ] [ E_GATE_TYPE ] ) {

			case E_GATE_TYPE_INVALID: strcat(gatetype, "INVALID" ) ;
			case E_GATE_TYPE_PUBLIC: strcat(gatetype, "PUBLIC: FREE TO USE" ) ;
			case E_GATE_TYPE_PLAYER: strcat(gatetype, "PLAYER-OWNED" ) ;
			case E_GATE_TYPE_PROPERTY: strcat(gatetype, "PROPERTY-LINKED" ) ;
			case E_GATE_TYPE_FACTION : strcat(gatetype, "FACTION-OWNED" ) ;
		}
	}

	return gatetype ;
}

// Returns the gate closest to the player, or INVALID_GATE_ID.
Gate_GetClosestEntity(playerid) {

	for ( new i, j = sizeof ( Gate ); i < j ; i ++ ) {

		if ( Gate [ i ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

			continue ;
		}

		if ( IsPlayerInRangeOfPoint(playerid, Gate [ i ] [ E_GATE_RADIUS ], Gate [ i ] [ E_GATE_CLOSED_POS_X ], Gate [ i ] [ E_GATE_CLOSED_POS_Y ], Gate [ i ] [ E_GATE_CLOSED_POS_Z ] ) ) {

			return i ;
		}
	}

	return INVALID_GATE_ID ;
}

// Returns the gate that owns a streamer object.
Gate_GetEnumIDFromObject(objectid) {

	for(new i, j = sizeof ( Gate ); i < j ; i ++ ) {

		if ( Gate [ i ] [ E_GATE_OBJECTID ] == objectid ) {

			return i ;
		}
	}

	return INVALID_GATE_ID ;
}

// Returns the first unused gate slot.
Gate_GetFreeID() {

	for(new i, j = sizeof ( Gate ); i < j ; i ++ ) {

		if ( Gate [ i ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

			return i ;
		}
	}

	return INVALID_GATE_ID ;
}

// Loads all gates from the database and creates their objects.
Gate_LoadEntities() {

	for(new i, j = sizeof ( Gate ); i < j ; i ++ ) {

		Gate [ i ] [ E_GATE_SQLID ] = INVALID_GATE_ID ;
	}

	for (new i = 0; i < MAX_GATES; i++)
	{
		for (new f = 0; f < MAX_GATE_FACTIONS; f++)
		{
			GateFactionAccess[i][f] = -1;
		}
	}

	print(" * [GATE] Loading all gates...");

	inline Gate_OnDataLoad() {
		for (new i = 0, r = cache_num_rows(); i < r; ++i) {
			cache_get_value_int (i, "gate_sqlid", Gate [ i ] [ E_GATE_SQLID ]);

			cache_get_value_int (i, "gate_type", Gate [ i ] [ E_GATE_TYPE ]);
			cache_get_value_int (i, "gate_owner", Gate [ i ] [ E_GATE_OWNER ]);

			cache_get_value_int (i, "gate_interior", Gate [ i ] [ E_GATE_INTERIOR ]);
			cache_get_value_int (i, "gate_virtualworld", Gate [ i ] [ E_GATE_VIRTUALWORLD ]);

			cache_get_value_int (i, "gate_modelid", Gate [ i ] [ E_GATE_MODELID ]);
			cache_get_value_int (i, "gate_toll", Gate [ i ] [ E_GATE_TOLL ]);
			cache_get_value_int (i, "gate_autoclose", Gate [ i ] [ E_GATE_AUTOCLOSE ]);
			cache_get_value_int (i, "gate_autoopen", Gate [ i ] [ E_GATE_AUTOOPEN ]);

			cache_get_value_float(i, "gate_speed", Gate [ i ] [ E_GATE_SPEED ]);
			cache_get_value_float(i, "gate_radius", Gate [ i ] [ E_GATE_RADIUS ]);

			cache_get_value_float( i, "gate_closed_pos_x", Gate [ i ] [ E_GATE_CLOSED_POS_X ]);
			cache_get_value_float( i, "gate_closed_pos_y", Gate [ i ] [ E_GATE_CLOSED_POS_Y ]);
			cache_get_value_float( i, "gate_closed_pos_z", Gate [ i ] [ E_GATE_CLOSED_POS_Z ]);

			cache_get_value_float( i, "gate_closed_rot_x", Gate [ i ] [ E_GATE_CLOSED_ROT_X ]);
			cache_get_value_float( i, "gate_closed_rot_y", Gate [ i ] [ E_GATE_CLOSED_ROT_Y ]);
			cache_get_value_float( i, "gate_closed_rot_z", Gate [ i ] [ E_GATE_CLOSED_ROT_Z ]);

			cache_get_value_float( i, "gate_open_pos_x", Gate [ i ] [ E_GATE_OPEN_POS_X ]);
			cache_get_value_float( i, "gate_open_pos_y", Gate [ i ] [ E_GATE_OPEN_POS_Y ]);
			cache_get_value_float( i, "gate_open_pos_z", Gate [ i ] [ E_GATE_OPEN_POS_Z ]);

			cache_get_value_float( i, "gate_open_rot_x", Gate [ i ] [ E_GATE_OPEN_ROT_X ]);
			cache_get_value_float( i, "gate_open_rot_y", Gate [ i ] [ E_GATE_OPEN_ROT_Y ]);
			cache_get_value_float( i, "gate_open_rot_z", Gate [ i ] [ E_GATE_OPEN_ROT_Z ]);


			if ( IsValidDynamicObject ( Gate [ i ] [ E_GATE_OBJECTID ])) {

				ORP_DestroyObject( Gate [ i ] [ E_GATE_OBJECTID ], "Gate/LoadEntities", true ) ;
			}

			Gate [ i ] [ E_GATE_OBJECTID ] = CreateDynamicObject(Gate [ i ] [ E_GATE_MODELID ],
				Gate [ i ] [ E_GATE_CLOSED_POS_X ], Gate [ i ] [ E_GATE_CLOSED_POS_Y ], Gate [ i ] [ E_GATE_CLOSED_POS_Z ],
				Gate [ i ] [ E_GATE_CLOSED_ROT_X ], Gate [ i ] [ E_GATE_CLOSED_ROT_Y ], Gate [ i ] [ E_GATE_CLOSED_ROT_Z ],
				Gate [ i ] [ E_GATE_VIRTUALWORLD ], Gate [ i ] [ E_GATE_INTERIOR ],
				.priority = STREAM_PRIORITY_INTERACTABLE );
		


			Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ i ] [ E_GATE_OBJECTID ], E_STREAMER_STREAM_DISTANCE, 500 );
			Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ i ] [ E_GATE_OBJECTID ], E_STREAMER_DRAW_DISTANCE, 500 );
			
			for ( new x, j = 16; x < j ; x ++ ) {

				cache_get_value_name_int (i, sprintf("gate_textureid%d", x), Gate [ i ] [ E_GATE_TEXTUREID ] [ x  ]);
				cache_get_value_name ( i, sprintf("gate_texturetxd%d", x), Gate_Texture_TXD [ i ] [ x ]);
				cache_get_value_name ( i, sprintf("gate_texturename%d", x), Gate_Texture_Name [ i ] [ x ]);

				if ( Gate [ i ] [ E_GATE_TEXTUREID ] [ x ] ) {

					SetDynamicObjectMaterial(Gate [ i ] [ E_GATE_OBJECTID ], x, Gate [ i ] [ E_GATE_TEXTUREID ] [ x  ], Gate_Texture_TXD [ i ] [ x ], Gate_Texture_Name [ i ] [ x ]);
				}
			}
		}

		printf(" * [GATE] Loaded %d gates.", cache_num_rows());
	}

	MySQL_TQueryInline(mysql, using inline Gate_OnDataLoad, "SELECT * FROM gates", "" ) ;

	inline GateFaction_OnLoad()
	{
		for (new i = 0, rows = cache_num_rows(); i < rows; i++)
		{
			new gate_sqlid, faction_sqlid;

			cache_get_value_int(i, "gate_sqlid", gate_sqlid);
			cache_get_value_int(i, "faction_id", faction_sqlid);

			new gate_enum = Gate_FindBySQL(gate_sqlid);
			if (gate_enum == INVALID_GATE_ID)
				continue;

			for (new x = 0; x < MAX_GATE_FACTIONS; x++)
			{
				if (GateFactionAccess[gate_enum][x] == -1)
				{
					GateFactionAccess[gate_enum][x] = faction_sqlid;
					break;
				}
			}
		}

		printf(" * [GATE] Loaded %d gate faction access entries.", cache_num_rows());
	}

	MySQL_TQueryInline(
		mysql,
		using inline GateFaction_OnLoad,
		"SELECT gate_sqlid, faction_id FROM gate_factions",
		""
	);


	return true ;
}
