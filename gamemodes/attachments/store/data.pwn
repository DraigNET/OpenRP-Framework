// ============================================================================
// File: attachments/store/data.pwn
// Attach points: the shops where toys are sold. Admin commands /addattachpoint,
// /attachpointdelete and /attachpointlink create them in the database;
// AttachPoint_RequiredFaction restricts a point to one faction.
// Commands: /addattachpoint /attachpointdelete /attachpointlink
// ============================================================================

enum E_ATTACH_POINT_DATA {

	E_ATTACH_POINT_ID,
	E_ATTACH_POINT_TYPE,
	E_ATTACH_POINT_LINKEDBIZ,
	
	Float: E_ATTACH_POINT_POS_X,
	Float: E_ATTACH_POINT_POS_Y,
	Float: E_ATTACH_POINT_POS_Z,
	E_ATTACH_POINT_INT,
	E_ATTACH_POINT_VW,

	DynamicText3D: E_ATTACH_POINT_LABEL
} ;

#if !defined MAX_ATTACH_POINTS
	#define MAX_ATTACH_POINTS	250
#endif

#if !defined INVALID_ATTACH_POINT_ID
	#define INVALID_ATTACH_POINT_ID	-1
#endif

new AttachPoint [ MAX_ATTACH_POINTS ] [ E_ATTACH_POINT_DATA ] ;

// Prints the list of attach point (shop) types to a staff member.
AttachPoint_AddTypeErrorMsg(playerid) {
	SendClientMessage(playerid, 0xDEDEDEFF, "Available Types:" ) ;
	SendClientMessage(playerid, 0xDEDEDEFF, "[CLOTHING STORE] 0: Facewear | 1: Headwear | 2: Neckwear | 3: Miscellaneous | 4: Police (SAPD) Restricted | 5: Fire (FDSA) Restricted" ) ;	SendClientMessage(playerid, 0xDEDEDEFF, "[JEWELRY STORE] 6: Chains | 7: Watches | 8: Rings | 9: Miscellaneous" ) ;	SendClientMessage(playerid, 0xDEDEDEFF, "[BARBERSHOP] 10: Hairstyles" ) ;
	SendClientMessage(playerid, 0xDEDEDEFF, "[JEWELRY STORE] 6: Chains | 7: Watches | 8: Rings | 9: Miscellaneous" ) ;
	SendClientMessage(playerid, 0xDEDEDEFF, "[BARBERSHOP] 10: Hairstyles" ) ;
	return true ;
}

// /addattachpoint [type] - (senior admin) creates a toy shop point at your position for the
// chosen store type.
CMD:addattachpoint(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new type ;

	if ( sscanf ( params, "i", type ) ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "/addattachpoint [type]" ) ;
		return AttachPoint_AddTypeErrorMsg(playerid);
	}

	if ( type < 0 || type > ATTACH_TYPE_MAX ) {

		SendServerMessage ( playerid, COLOR_ERROR, "Error", "DEDEDE", "Type must be between 0 and 10!" ) ;
		return AttachPoint_AddTypeErrorMsg(playerid) ;
	}

	AttachPoint_Create ( playerid, type ) ;

	return true; 
}

// /attachpointdelete [point id] - removes a toy shop point.
CMD:attachpointdelete(playerid, params[] ) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new apid ;

	if ( sscanf  (params, "i", apid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Attach", "DEDEDE", "/attachpointdelete [point-id]" ) ;
	}

	if ( AttachPoint [ apid ] [ E_ATTACH_POINT_ID ] == INVALID_ATTACH_POINT_ID ) {
	
		return SendServerMessage ( playerid, COLOR_ERROR, "Attach", "DEDEDE", "Invalid attach point ID entered!");
	}

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "DELETE FROM attachpoint WHERE attach_point_id = %d", 
		AttachPoint [ apid ] [ E_ATTACH_POINT_ID] 
	) ;

	mysql_tquery(mysql, query);

	if ( IsValidDynamic3DTextLabel ( AttachPoint [ apid ] [ E_ATTACH_POINT_LABEL ] ) ) {
		DestroyDynamic3DTextLabel( AttachPoint [ apid ] [ E_ATTACH_POINT_LABEL ] ) ;
	}

	AttachPoint [ apid ] [ E_ATTACH_POINT_ID]  = INVALID_ATTACH_POINT_ID ;

	return true ;
}

// /attachpointlink [point id] [business id] - links a toy shop to a business so its sales go to
// that business.
CMD:attachpointlink(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}


	new apid, bizid ;

	if ( sscanf  (params, "ii", apid, bizid ) ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Attach", "DEDEDE", "/attachpointlink [point-id] [biz-enum-id]" ) ;
	}

	if ( ! IsValidProperty(bizid)) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Attach", "DEDEDE", "Invalid property ID entered!");
	}

	if ( AttachPoint [ apid ] [ E_ATTACH_POINT_ID ] == INVALID_ATTACH_POINT_ID ) {
	
		return SendServerMessage ( playerid, COLOR_ERROR, "Attach", "DEDEDE", "Invalid attach point ID entered!");
	}

	AttachPoint [ apid ] [ E_ATTACH_POINT_LINKEDBIZ] = bizid ; 

	new query [ 256 ], name [ 64 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE attachpoint SET attach_point_linkedbiz = %d WHERE attach_point_id = %d", 
		AttachPoint [ apid ] [ E_ATTACH_POINT_LINKEDBIZ], AttachPoint [ apid ] [ E_ATTACH_POINT_ID] 
	) ;

	mysql_tquery(mysql, query);


	query [ 0 ] = EOS ;

	AttachPoint_GetName(AttachPoint [ apid ] [ E_ATTACH_POINT_TYPE ], name, sizeof ( name ) );
	format ( query, sizeof ( query ), "[%d] [%s] [%d]\n{DEDEDE}Available commands: /buytoys", apid, name, AttachPoint [ apid ] [ E_ATTACH_POINT_LINKEDBIZ ] );

	UpdateDynamic3DTextLabelText( AttachPoint [ apid ] [ E_ATTACH_POINT_LABEL ], COLOR_ATTACH, query );

	return true ;
}

// Pays the money for a toy purchase into the business linked to the nearest attach point.
AttachPoint_HandlePayment(playerid, amount) {

	new idx = AttachPoint_GetNearestEntity(playerid);

	if ( idx == INVALID_ATTACH_POINT_ID ) {

		return true ;
	}

	new bizid = AttachPoint [ idx ] [ E_ATTACH_POINT_LINKEDBIZ ];

	if ( IsValidProperty(bizid) ) {

		PlayerVar [ playerid ] [ E_PLAYER_BIZ_MENU ] = GetPropertyID(bizid);
		Property_AddMoneyToTill(playerid, amount, false );
	}

	return true ;
}

// Returns the index of the toy shop point the player is standing at, or INVALID_ATTACH_POINT_ID.
AttachPoint_GetNearestEntity(playerid) {

	for ( new i, j = sizeof ( AttachPoint ); i < j ; i ++ ) {

		if ( AttachPoint [ i ] [ E_ATTACH_POINT_ID ] != INVALID_ATTACH_POINT_ID ) {

			if ( IsPlayerInRangeOfPoint(playerid, 2.0, AttachPoint [ i ] [ E_ATTACH_POINT_POS_X ], AttachPoint [ i ] [ E_ATTACH_POINT_POS_Y ], AttachPoint [ i ] [ E_ATTACH_POINT_POS_Z ] ) ) {

				return i ;
			}

			else continue ;
		}

		else continue ;
	}

	return INVALID_ATTACH_POINT_ID ;
}

// Creates an attach point at the player's position, saves it and draws its 3D label.
AttachPoint_Create(playerid, type ){

	new idx = AttachPoint_GetFreeID();

	if ( idx == INVALID_ATTACH_POINT_ID ) {

		return SendClientMessage(playerid, COLOR_ERROR, "Can't create attach point - limit reached!" ) ;
	}

	new Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;

	AttachPoint [ idx ] [ E_ATTACH_POINT_TYPE ] = type ;
	AttachPoint [ idx ] [ E_ATTACH_POINT_LINKEDBIZ ] = -1 ;
	
	AttachPoint [ idx ] [ E_ATTACH_POINT_POS_X ] = x ;
	AttachPoint [ idx ] [ E_ATTACH_POINT_POS_Y ] = y ;
	AttachPoint [ idx ] [ E_ATTACH_POINT_POS_Z ] = z ;
	AttachPoint [ idx ] [ E_ATTACH_POINT_INT ] = GetPlayerInterior(playerid);
	AttachPoint [ idx ] [ E_ATTACH_POINT_VW ] = GetPlayerVirtualWorld(playerid);

	new string [ 256 ], name [ 64 ] ;

	string[0]=EOS;
	mysql_format(mysql, string, sizeof(string), 
		"INSERT INTO attachpoint(attach_point_type, attach_point_linkedbiz, attach_point_pos_x, attach_point_pos_y, attach_point_pos_z, attach_point_int, attach_point_vw)\
	 VALUES (%d, %d, '%f', '%f', '%f', %d, %d)",

		AttachPoint [ idx ] [ E_ATTACH_POINT_TYPE ] ,
		AttachPoint [ idx ] [ E_ATTACH_POINT_LINKEDBIZ ] ,
		AttachPoint [ idx ] [ E_ATTACH_POINT_POS_X ] ,
		AttachPoint [ idx ] [ E_ATTACH_POINT_POS_Y ] ,
		AttachPoint [ idx ] [ E_ATTACH_POINT_POS_Z ],
		AttachPoint [ idx ] [ E_ATTACH_POINT_INT ] ,
		AttachPoint [ idx ] [ E_ATTACH_POINT_VW ]
	);

	inline AttachPoint_OnDBInsert() {

		AttachPoint [ idx ] [ E_ATTACH_POINT_ID ] = cache_insert_id ();
		printf(" * [Attach Point] Created attach point (%d) with ID %d.", 
			idx, AttachPoint [ idx ] [ E_ATTACH_POINT_ID ] ) ;

		if ( IsValidDynamic3DTextLabel(AttachPoint [ idx ] [ E_ATTACH_POINT_LABEL ])) {

			DestroyDynamic3DTextLabel(AttachPoint [ idx ] [ E_ATTACH_POINT_LABEL ]);
		}

		AttachPoint_GetName(type, name, sizeof ( name ) );
		format ( string, sizeof ( string ), "[%d] [%s] [%d]\n{DEDEDE}Available commands: /buytoys", idx, name, AttachPoint [ idx ] [ E_ATTACH_POINT_LINKEDBIZ ] ) ;

		AttachPoint [ idx ] [ E_ATTACH_POINT_LABEL ] = CreateDynamic3DTextLabel(string, COLOR_ATTACH, 

			AttachPoint [ idx ] [ E_ATTACH_POINT_POS_X ], AttachPoint [ idx ] [ E_ATTACH_POINT_POS_Y ], AttachPoint [ idx ] [ E_ATTACH_POINT_POS_Z ],
			7.5, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, true, 
			AttachPoint [ idx ] [ E_ATTACH_POINT_VW ], AttachPoint [ idx ] [ E_ATTACH_POINT_INT ]
		);
	}

	MySQL_TQueryInline(mysql, using inline AttachPoint_OnDBInsert, string);

	return true ;
}

// A faction-restricted toy point maps to the one faction allowed to use it, by
// faction SQL id (0 = open to anyone). Add an agency's toy type here - one
// line, no gate code to touch.
AttachPoint_RequiredFaction(type) {

	switch ( type ) {

		case ATTACH_TYPE_SAPD: return FACTION_ID_SAPD;
		case ATTACH_TYPE_FDSA: return FACTION_ID_FDSA;
	}

	return 0;
}

// Writes the readable name of a store type into name.
AttachPoint_GetName(type, name[], len = sizeof ( name ) ) {

	switch ( type ) {

		case ATTACH_TYPE_FACE:       format ( name, len, "Clothing Store: Facewear" ) ;
		case ATTACH_TYPE_HEAD:       format ( name, len, "Clothing Store: Headwear" ) ;
		case ATTACH_TYPE_NECK:       format ( name, len, "Clothing Store: Neckwear" ) ;
		case ATTACH_TYPE_MISC:       format ( name, len, "Clothing Store: Miscellaneous" ) ;
		case ATTACH_TYPE_SAPD:       format ( name, len, "Clothing Store: Police Restricted" ) ;
		case ATTACH_TYPE_FDSA:       format ( name, len, "Clothing Store: Fire Restricted" ) ;
		case ATTACH_TYPE_CHAINS:     format ( name, len, "Jewelry Store: Chains" ) ;
		case ATTACH_TYPE_WATCHES:    format ( name, len, "Jewelry Store: Watches" ) ;
		case ATTACH_TYPE_RINGS:      format ( name, len, "Jewelry Store: Rings" ) ;
		case ATTACH_TYPE_JEWEL_MISC: format ( name, len, "Jewelry Store: Miscellaneous" ) ;
		case ATTACH_TYPE_BARBER:     format ( name, len, "Barbershop: Hairstyles" ) ;
		default:                     format ( name, len, "Invalid Point Type" ) ;
	}
}

// Returns the first unused attach point slot, or INVALID_ATTACH_POINT_ID.
AttachPoint_GetFreeID() {

	for ( new i, j = sizeof ( AttachPoint ); i < j ; i ++ ) {

		if ( AttachPoint [ i ] [ E_ATTACH_POINT_ID ] == INVALID_ATTACH_POINT_ID ) {

			return i ;
		}

		else continue ;
	}

	return -1 ;
}

// Loads all attach points from the database at start-up and creates their labels.
AttachPoint_LoadEntities() {
	for ( new i, j = sizeof ( AttachPoint ); i < j ; i ++ ) {

		AttachPoint [ i ] [ E_ATTACH_POINT_ID ] = INVALID_ATTACH_POINT_ID ;
	}

	new string[256], name[64];

    inline AttachPointsLoad() {
		for (new i = 0, r = cache_num_rows(); i < r; ++i) {
			cache_get_value_name_int(i, "attach_point_id", AttachPoint [ i ] [ E_ATTACH_POINT_ID ]);
			cache_get_value_name_int(i, "attach_point_type", AttachPoint [ i ] [ E_ATTACH_POINT_TYPE ]);
			cache_get_value_name_int(i, "attach_point_linkedbiz", AttachPoint [ i ] [ E_ATTACH_POINT_LINKEDBIZ ]);
			
			cache_get_value_name_float(i, "attach_point_pos_x", AttachPoint [ i ] [ E_ATTACH_POINT_POS_X ]);
			cache_get_value_name_float(i, "attach_point_pos_y", AttachPoint [ i ] [ E_ATTACH_POINT_POS_Y ]);
			cache_get_value_name_float(i, "attach_point_pos_z", AttachPoint [ i ] [ E_ATTACH_POINT_POS_Z ]);
			cache_get_value_name_int(i, "attach_point_int", AttachPoint [ i ] [ E_ATTACH_POINT_INT ]);
			cache_get_value_name_int(i, "attach_point_vw", AttachPoint [ i ] [ E_ATTACH_POINT_VW ]);


			AttachPoint_GetName(AttachPoint [ i ] [ E_ATTACH_POINT_TYPE ], name, sizeof ( name ) );
			format ( string, sizeof ( string ), "[%d] [%s] [%d]\n{DEDEDE}Available commands: /buytoys", i, name, AttachPoint [ i ] [ E_ATTACH_POINT_LINKEDBIZ ] );

			AttachPoint [ i ] [ E_ATTACH_POINT_LABEL ] = CreateDynamic3DTextLabel(string, COLOR_ATTACH, 

				AttachPoint [ i ] [ E_ATTACH_POINT_POS_X ], AttachPoint [ i ] [ E_ATTACH_POINT_POS_Y ], AttachPoint [ i ] [ E_ATTACH_POINT_POS_Z ],
				7.5, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, true, 
				AttachPoint [ i ] [ E_ATTACH_POINT_VW ], AttachPoint [ i ] [ E_ATTACH_POINT_INT ]
			);
		}

		printf(" * [ATTACH POINTS] Loaded %d attach points.", cache_num_rows() ) ;
    }

    MySQL_TQueryInline(mysql, using inline AttachPointsLoad, "SELECT * FROM attachpoint");
}
