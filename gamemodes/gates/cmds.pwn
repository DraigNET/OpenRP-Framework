// ============================================================================
// File: gates/cmds.pwn
// Admin and owner commands for gates and doors: /gatecreate, /gatemove, /gateopen, /gatestyle,
// /gatetoll, /gateautoclose, /gateradius, /gatetexture and more.
// Commands: /gatecreate /gatestyle /gatetoll /gateautoclose /gateautoopen /gateradius /gateopen
// /gatemove /gatetome /gatenear /gatetexture /gateworld /gateint /gatetype /gatefaction
// /copygate /gateclone /gategoto
// ============================================================================

// /gatecreate [modelid] - (admin) creates a gate with the given object model at your position.
CMD:gatecreate(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	

	new gate_enum_id = Gate_GetFreeID() ;

	if (  gate_enum_id == -1 ) {

		return print("* [GATE] No free enum IDs left - [Gate_CreateEntity] failed!!");
	}

	new modelid ;

	if ( sscanf ( params, "i", modelid ) ) {

		return SendClientMessage(playerid, -1, "/gatecreate [modelid]" ) ;
	}

	new Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;

	GetXYInFrontOfPlayer(playerid, x, y, 2.5 );

	// We set a new gate ID so that multiple gates don't overlap creation.
	Gate [ gate_enum_id ] [ E_GATE_SQLID ] = GATE_SETUP_ID ;
	Gate [ gate_enum_id ] [ E_GATE_MODELID ] = modelid ;

	Gate [ gate_enum_id ] [ E_GATE_TYPE ] = E_GATE_TYPE_INVALID ;
	Gate [ gate_enum_id ] [ E_GATE_OWNER ] = -1 ;

	Gate [ gate_enum_id ] [ E_GATE_SETUP ] = 0 ;
	Gate [ gate_enum_id ] [ E_GATE_RADIUS ] = 2.5 ;

	Gate [ gate_enum_id ] [ E_GATE_INTERIOR ] = GetPlayerInterior(playerid) ;
	Gate [ gate_enum_id ] [ E_GATE_VIRTUALWORLD ] = GetPlayerVirtualWorld(playerid) ;

	Gate [ gate_enum_id ] [ E_GATE_OBJECTID ] = CreateDynamicObject(modelid, 
		x, y, z, 0.0, 0.0, 0.0, Gate [ gate_enum_id ] [ E_GATE_VIRTUALWORLD ], Gate [ gate_enum_id ] [ E_GATE_INTERIOR ] );

	PlayerVar [ playerid ] [ E_PLAYER_IS_MOVING_GATE ] = true ;

	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], E_STREAMER_STREAM_DISTANCE, 500 );
	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], E_STREAMER_DRAW_DISTANCE, 500 );
	EditDynamicObject(playerid, Gate [ gate_enum_id ] [ E_GATE_OBJECTID ] ) ;


	return true ;
}

// Temp command for nich's sd gates
CMD:gatestyle(playerid, params[])
{
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new gateid, style;

	if ( sscanf ( params, "ii", gateid, style ) ) {

		return SendClientMessage(playerid, -1, "/gatestyle [gateid] [1: nich sd gate]");
	}

	if (style == 1)
	{
		new tmpobjid = Gate[gateid][E_GATE_OBJECTID];
		SetDynamicObjectMaterial(tmpobjid, 0, 1419, "break_fence3", "CJ_FRAME_Glass", 0x00000000);
		SetDynamicObjectMaterial(tmpobjid, 1, 17588, "lae2coast_alpha", "plainglass", 0x00000000);
		SetDynamicObjectMaterial(tmpobjid, 2, 14577, "casinovault01", "cof_wood1", 0x00000000);
	}

	return true;
}

// /gatetoll [gate] [0/1] - (admin) marks a gate as a toll gate.
CMD:gatetoll(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new gateid, status ;

	if ( sscanf ( params, "ii", gateid, status ) ) {

		return SendClientMessage(playerid, -1, "/gatetoll [gateid] [0: no, 1: yes]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_TOLL] = status ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE gates SET gate_toll = %d WHERE gate_sqlid = %d",

		status, Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query );

	SendClientMessage(playerid, -1, sprintf("Updated gate ID %d's toll status to %d.", gateid, Gate [ gateid ] [ E_GATE_TOLL ] ) ) ;

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Updated gate ID %d's toll status to %d.", gateid, Gate [ gateid ] [ E_GATE_TOLL ] ));

	return true ;
}

// /gateautoclose [gate] [0/1] - (admin) makes a gate close itself again.
CMD:gateautoclose(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new gateid, status ;

	if ( sscanf ( params, "ii", gateid, status ) ) {

		return SendClientMessage(playerid, -1, "/gateautoclose [gateid] [0: no, 1: yes]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_AUTOCLOSE] = status ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE gates SET gate_autoclose = %d WHERE gate_sqlid = %d",

		status, Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query );

	SendClientMessage(playerid, -1, sprintf("Updated gate ID %d's autoclose status to %d.", gateid, Gate [ gateid ] [ E_GATE_AUTOCLOSE ] ) ) ;
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Changed gate %d autoclose status to %d", gateid, Gate [ gateid ] [ E_GATE_AUTOCLOSE ] ));

	return true ;
}

// /gateautoopen [gate] [0/1] - (admin) makes a gate open automatically for allowed vehicles.
CMD:gateautoopen(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new gateid, status ;

	if ( sscanf ( params, "ii", gateid, status ) ) {

		return SendClientMessage(playerid, -1, "/gateautoopen [gateid] [0: no, 1: yes]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_AUTOOPEN] = status ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE gates SET gate_autoopen = %d WHERE gate_sqlid = %d",

		status, Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query );

	SendClientMessage(playerid, -1, sprintf("Updated gate ID %d's autoopen status to %d.", gateid, Gate [ gateid ] [ E_GATE_AUTOOPEN ] ) ) ;
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Changed gate %d autoopen status to %d", gateid, Gate [ gateid ] [ E_GATE_AUTOOPEN ] ));

	return true ;
}

// /gateradius [gate] [radius] - (admin) sets how close you need to be to use a gate.
CMD:gateradius(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new gateid,Float: radius ;

	if ( sscanf ( params, "if", gateid, radius ) ) {

		return SendClientMessage(playerid, -1, "/gateradius [gateid] [radius]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_RADIUS ] = radius ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE gates SET gate_radius = '%f' WHERE gate_sqlid = %d",

		radius, Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query );

	SendClientMessage(playerid, -1, sprintf("Updated gate ID %d's radius to %.3f.", gateid, Gate [ gateid ] [ E_GATE_RADIUS ] ) ) ;

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Updated gate ID %d's radius to %.3f.", gateid, Gate [ gateid ] [ E_GATE_RADIUS ] ));

	return true ;
}

// /gateopen [gate] - (admin) opens or closes a gate for testing.
CMD:gateopen(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new gateid ;

	if ( sscanf ( params, "i", gateid ) ) {

		return SendClientMessage(playerid, -1, "/gateopen [gateid]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_SETUP ] = 1 ;
	PlayerVar [ playerid ] [ E_PLAYER_IS_MOVING_GATE ] = true ;

	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gateid ] [ E_GATE_OBJECTID ], E_STREAMER_STREAM_DISTANCE, 500 );
	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gateid ] [ E_GATE_OBJECTID ], E_STREAMER_DRAW_DISTANCE, 500 );
	EditDynamicObject(playerid, Gate [ gateid ] [ E_GATE_OBJECTID ] ) ;


	return true ;
}

// /gatemove [gate] - (admin) moves the gate's closed or open position with the object editor.
CMD:gatemove(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new gateid ;

	if ( sscanf ( params, "i", gateid ) ) {

		return SendClientMessage(playerid, -1, "/gatemove [gateid]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}


	new Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;

	//GetXYInFrontOfPlayer(playerid, x, y, 2.5 );
	//SetDynamicObjectPos(Gate [ gateid ] [ E_GATE_OBJECTID ], x, y, z);

	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gateid ] [ E_GATE_OBJECTID ], E_STREAMER_STREAM_DISTANCE, 500 );

	Gate [ gateid ] [ E_GATE_SETUP ] = 0 ;
	PlayerVar [ playerid ] [ E_PLAYER_IS_MOVING_GATE ] = true ;

	EditDynamicObject(playerid, Gate [ gateid ] [ E_GATE_OBJECTID ] ) ;


	return true ;
}

// /gatetome [gate] - (admin) moves a gate to your position.
CMD:gatetome(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new gateid ;

	if ( sscanf ( params, "i", gateid ) ) {

		return SendClientMessage(playerid, -1, "/gatetome [gateid]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}


	new Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z ) ;

	GetXYInFrontOfPlayer(playerid, x, y, 2.5 );
	//SetDynamicObjectPos(Gate [ gateid ] [ E_GATE_OBJECTID ], x, y, z);

	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gateid ] [ E_GATE_OBJECTID ], E_STREAMER_STREAM_DISTANCE, 500 );

	Gate [ gateid ] [ E_GATE_SETUP ] = 0 ;
	PlayerVar [ playerid ] [ E_PLAYER_IS_MOVING_GATE ] = true ;

	EditDynamicObject(playerid, Gate [ gateid ] [ E_GATE_OBJECTID ] ) ;


	return true ;
}

// /gatenear - (admin) lists gates near you.
CMD:gatenear(playerid, params[])
{
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new gate_enum_id = Gate_GetClosestEntity(playerid) ;

	if ( gate_enum_id == INVALID_GATE_ID ) {

		return true ;
	}

	if ( GetPlayerAdminLevel ( playerid ) >= ADMIN_LVL_GENERAL) {

		SendClientMessage(playerid, COLOR_YELLOW, sprintf("[GATE] Gate ID %d (SQL: %d). Type: %s. Owned by ID %d.",
			gate_enum_id,Gate [ gate_enum_id ] [ E_GATE_SQLID ], Gate_GetType(gate_enum_id), Gate [ gate_enum_id ] [ E_GATE_OWNER ] )) ;
	}

	if (Gate[gate_enum_id][E_GATE_TYPE] == E_GATE_TYPE_FACTION)
	{
		for (new i = 0; i < MAX_GATE_FACTIONS; i++)
		{
			if (GateFactionAccess[gate_enum_id][i] != -1)
			{
				SendClientMessage(playerid, COLOR_GREY,
					sprintf("  + Extra faction access: %d", GateFactionAccess[gate_enum_id][i]));
			}
		}
	}

	return 1;
}

// /gatetexture [gate] [slot] [model] [txd] [texture] - (admin) retextures a gate.
CMD:gatetexture(playerid, params[]) {
	// support 16 indexes, use same method as kiosk for saving
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_SENIOR ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	

	new gateid, texture_slot, textureid, texturetxd[256], texturename[256] ;

	if ( sscanf ( params, "iiis[256]s[256]", gateid, texture_slot, textureid, texturetxd, texturename )) {

		return SendClientMessage(playerid, -1, "/gatetex(ture) [gateid] [index] [txd-model] [txd-txd] [txd-name]" ) ;
	}

	if ( texture_slot < 0 || texture_slot > 15 ) {

		return SendClientMessage(playerid, -1, "Texture slot can't be less than 0 or more than 15.");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_TEXTUREID ] [ texture_slot ] = textureid ;

	Gate_Texture_TXD [ gateid ] [ texture_slot ] [ 0 ] = EOS ;
	Gate_Texture_Name [ gateid ] [ texture_slot ]  [ 0 ] = EOS ;

	strcat(Gate_Texture_TXD [ gateid ] [ texture_slot ] , texturetxd );
	strcat(Gate_Texture_Name [ gateid ] [ texture_slot ] , texturename );

	// re-using string to save memory
	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE gates SET gate_textureid%d = %d, gate_texturetxd%d = '%e', gate_texturename%d = '%e' WHERE gate_sqlid = %d",
		texture_slot, Gate [ gateid ] [ E_GATE_TEXTUREID ] [ texture_slot ], 
		texture_slot, Gate_Texture_TXD [ gateid ] [ texture_slot ], 
		texture_slot, Gate_Texture_Name [ gateid ] [ texture_slot ],
	 	Gate [ gateid ] [ E_GATE_SQLID]
	) ; 

	mysql_tquery(mysql, query );

	SetDynamicObjectMaterial(Gate [ gateid ] [ E_GATE_OBJECTID ], texture_slot, Gate [ gateid ] [ E_GATE_TEXTUREID ] [ texture_slot ], Gate_Texture_TXD [ gateid ] [ texture_slot ], Gate_Texture_Name [ gateid ] [ texture_slot ], 0xFFFFFFFF );


	SendClientMessage(playerid, -1, sprintf("Set gate ID %d's texture on slot %d to id %d, txd %s and name %s.",
		gateid, texture_slot, textureid, texturetxd, texturename ) ) ;

	AddLogEntry(playerid, LOG_TYPE_SCRIPT,  sprintf("Set gate ID %d's texture on slot %d to id %d, txd %s and name %s.",
		gateid, texture_slot, textureid, texturetxd, texturename ));

	return true ;
}

// /gateworld [gate] [world] - (admin) sets a gate's virtual world.
CMD:gateworld(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new gateid, virtualworld ;

	if ( sscanf ( params, "ii", gateid, virtualworld ) ) {


		return SendClientMessage(playerid, -1, "/gatevw [gateid] [virtualworld]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_VIRTUALWORLD ] = virtualworld ;

	Streamer_SetIntData(STREAMER_TYPE_OBJECT, Gate [gateid ] [ E_GATE_OBJECTID ], E_STREAMER_WORLD_ID, virtualworld ) ;

	Streamer_Update(playerid);

	SendClientMessage(playerid, -1, sprintf("Gate ID %d's virtual world set to %d.", gateid, virtualworld ) ) ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE gates SET gate_virtualworld = %d WHERE gate_sqlid = %d",
		Gate [ gateid ] [ E_GATE_VIRTUALWORLD ], Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query);
	
	AddLogEntry(playerid, LOG_TYPE_SCRIPT,  sprintf("Gate ID %d's virtual world set to %d.", gateid, virtualworld ));


	return true ;
}

// /gateint [gate] [interior] - (admin) sets a gate's interior.
CMD:gateint(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	

	new gateid, interior ;

	if ( sscanf ( params, "ii", gateid, interior ) ) {


		return SendClientMessage(playerid, -1, "/gateint [gateid] [interior]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_INTERIOR ] = interior ;

	Streamer_SetIntData(STREAMER_TYPE_OBJECT, Gate [gateid ] [ E_GATE_OBJECTID ], E_STREAMER_INTERIOR_ID, interior ) ;

	Streamer_Update(playerid);

	SendClientMessage(playerid, -1, sprintf("Gate ID %d's interior set to %d.", gateid, interior ) ) ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE gates SET gate_interior = %d WHERE gate_sqlid = %d",
		Gate [ gateid ] [ E_GATE_INTERIOR ], Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query);

	AddLogEntry(playerid, LOG_TYPE_SCRIPT,  sprintf("Gate ID %d's interior set to %d.", gateid, interior ));

	return true ;
}

// /gatetype [gate] [type] [owner] - (admin) sets who can use a gate (public, player, faction...).
CMD:gatetype(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new gateid, ownerid, typeid ;

	if ( sscanf ( params, "iii", gateid, typeid, ownerid ) ) {

		SendClientMessage(playerid, COLOR_ERROR, "/gatetype [gateid] [type] [owner] ");
		return SendClientMessage(playerid, -1, "0: Invalid | 1: Public | 2: Player-owned | 3: Property-linked | 4: Faction-owned");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_TYPE ] = typeid ;
	Gate [ gateid ] [ E_GATE_OWNER ] = ownerid ;

	SendClientMessage(playerid, -1, sprintf("Set gate ID %d's type to %d and owner to %d.", gateid, typeid, ownerid ) ) ;
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Set gate ID %d's type to %d and owner to %d.", gateid, typeid, ownerid ));


	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof ( query ), "UPDATE gates SET gate_type = %d, gate_owner = %d WHERE gate_sqlid = %d",
		Gate [ gateid ] [ E_GATE_TYPE ], Gate [ gateid ] [ E_GATE_OWNER ], Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query);

	return true ;
}

// /gatefaction [add/remove] [gate] [faction] - (admin) allows or removes a faction's access to a
// gate.
CMD:gatefaction(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access.");

    new action[8], gateid, faction_sqlid;

    if (sscanf(params, "s[8]ii", action, gateid, faction_sqlid))
        return SendClientMessage(playerid, -1, "/gatefaction [add/remove] [gateid] [faction SQL id]");

    if (gateid < 0 || gateid >= MAX_GATES || Gate[gateid][E_GATE_SQLID] == INVALID_GATE_ID)
        return SendClientMessage(playerid, -1, "Invalid gate ID.");

    if (Gate[gateid][E_GATE_TYPE] != E_GATE_TYPE_FACTION)
        return SendClientMessage(playerid, -1,
            "This gate is not faction-owned. Extra faction access is only valid for faction gates.");

    new faction_enum = Faction_GetEnumID(faction_sqlid);
    if (faction_enum == INVALID_FACTION_ID)
        return SendClientMessage(playerid, -1, "Invalid faction ID.");

    // =======================
    // ADD FACTION ACCESS
    // =======================
    if (!strcmp(action, "add", true))
    {
        // Duplicate check
        for (new i = 0; i < MAX_GATE_FACTIONS; i++)
        {
            if (GateFactionAccess[gateid][i] == faction_sqlid)
            {
                return SendClientMessage(playerid, -1,
                    sprintf("Faction \"%s\" already has access to this gate.",
                        Faction[faction_enum][E_FACTION_NAME]));
            }
        }

        // Find free slot
        for (new i = 0; i < MAX_GATE_FACTIONS; i++)
        {
            if (GateFactionAccess[gateid][i] == -1)
            {
                GateFactionAccess[gateid][i] = faction_sqlid;

                new query[256];
                mysql_format(mysql, query, sizeof query,
                    "INSERT IGNORE INTO gate_factions (gate_sqlid, faction_id) VALUES (%d, %d)",
                    Gate[gateid][E_GATE_SQLID],
                    faction_sqlid
                );
                mysql_tquery(mysql, query);

                SendClientMessage(playerid, -1,
                    sprintf("Faction \"%s\" has been granted access to this gate.",
                        Faction[faction_enum][E_FACTION_NAME]));

                return 1;
            }
        }

        return SendClientMessage(playerid, -1,
            "This gate already has the maximum number of extra factions.");
    }

    // =======================
    // REMOVE FACTION ACCESS
    // =======================
    if (!strcmp(action, "remove", true))
    {
        for (new i = 0; i < MAX_GATE_FACTIONS; i++)
        {
            if (GateFactionAccess[gateid][i] == faction_sqlid)
            {
                GateFactionAccess[gateid][i] = -1;

                new query[256];
                mysql_format(mysql, query, sizeof query,
                    "DELETE FROM gate_factions WHERE gate_sqlid = %d AND faction_id = %d",
                    Gate[gateid][E_GATE_SQLID],
                    faction_sqlid
                );
                mysql_tquery(mysql, query);

                SendClientMessage(playerid, -1,
                    sprintf("Faction \"%s\" has been removed from this gate.",
                        Faction[faction_enum][E_FACTION_NAME]));

                return 1;
            }
        }

        return SendClientMessage(playerid, -1,
            sprintf("Faction \"%s\" does not have access to this gate.",
                Faction[faction_enum][E_FACTION_NAME]));
    }

    return SendClientMessage(playerid, -1, "Use add or remove.");
}

// /copygate [gate] - (admin) duplicates a gate with all its settings.
CMD:copygate(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new src_gateid ;

	if ( sscanf ( params, "i", src_gateid ) ) {

		return SendClientMessage(playerid, -1, "/copygate [gateid]") ;
	}

	if ( src_gateid < 0 || src_gateid >= MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid.") ;
	}

	if ( Gate [ src_gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid.") ;
	}

	new gate_enum_id = Gate_GetFreeID() ;

	if ( gate_enum_id == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "* [GATE] No free enum IDs left - /copygate failed.") ;
	}

	new Float: x, Float: y, Float: z ;
	GetPlayerPos(playerid, x, y, z) ;
	GetXYInFrontOfPlayer(playerid, x, y, 2.5) ;

	Gate [ gate_enum_id ] [ E_GATE_SQLID ]        = GATE_SETUP_ID ;
	Gate [ gate_enum_id ] [ E_GATE_MODELID ]       = Gate [ src_gateid ] [ E_GATE_MODELID ] ;

	Gate [ gate_enum_id ] [ E_GATE_TYPE ]          = Gate [ src_gateid ] [ E_GATE_TYPE ] ;
	Gate [ gate_enum_id ] [ E_GATE_OWNER ]         = Gate [ src_gateid ] [ E_GATE_OWNER ] ;

	Gate [ gate_enum_id ] [ E_GATE_SPEED ]         = Gate [ src_gateid ] [ E_GATE_SPEED ] ;
	Gate [ gate_enum_id ] [ E_GATE_RADIUS ]        = Gate [ src_gateid ] [ E_GATE_RADIUS ] ;
	Gate [ gate_enum_id ] [ E_GATE_TOLL ]          = Gate [ src_gateid ] [ E_GATE_TOLL ] ;
	Gate [ gate_enum_id ] [ E_GATE_AUTOCLOSE ]     = Gate [ src_gateid ] [ E_GATE_AUTOCLOSE ] ;
	Gate [ gate_enum_id ] [ E_GATE_AUTOOPEN ]      = Gate [ src_gateid ] [ E_GATE_AUTOOPEN ] ;

	Gate [ gate_enum_id ] [ E_GATE_INTERIOR ]      = GetPlayerInterior(playerid) ;
	Gate [ gate_enum_id ] [ E_GATE_VIRTUALWORLD ]  = GetPlayerVirtualWorld(playerid) ;

	Gate [ gate_enum_id ] [ E_GATE_SETUP ]         = 0 ;

	for ( new t = 0; t < 16; t++ ) {

		Gate [ gate_enum_id ] [ E_GATE_TEXTUREID ] [ t ] = Gate [ src_gateid ] [ E_GATE_TEXTUREID ] [ t ] ;

		Gate_Texture_TXD  [ gate_enum_id ] [ t ] [ 0 ] = EOS ;
		Gate_Texture_Name [ gate_enum_id ] [ t ] [ 0 ] = EOS ;

		strcat(Gate_Texture_TXD  [ gate_enum_id ] [ t ], Gate_Texture_TXD  [ src_gateid ] [ t ]) ;
		strcat(Gate_Texture_Name [ gate_enum_id ] [ t ], Gate_Texture_Name [ src_gateid ] [ t ]) ;
	}

	PlayerVar [ playerid ] [ E_PLAYER_COPYING_GATE ] = src_gateid ;

	Gate [ gate_enum_id ] [ E_GATE_OBJECTID ] = CreateDynamicObject(Gate [ gate_enum_id ] [ E_GATE_MODELID ],
		x, y, z, 0.0, 0.0, 0.0,
		Gate [ gate_enum_id ] [ E_GATE_VIRTUALWORLD ], Gate [ gate_enum_id ] [ E_GATE_INTERIOR ]) ;

	PlayerVar [ playerid ] [ E_PLAYER_IS_MOVING_GATE ] = true ;

	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], E_STREAMER_STREAM_DISTANCE, 500) ;
	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], E_STREAMER_DRAW_DISTANCE, 500) ;
	EditDynamicObject(playerid, Gate [ gate_enum_id ] [ E_GATE_OBJECTID ]) ;

	SendClientMessage(playerid, COLOR_YELLOW, sprintf("[GATE] Copying gate %d (SQL: %d) - model %d. Position the new gate and press Save.",
		src_gateid, Gate [ src_gateid ] [ E_GATE_SQLID ], Gate [ src_gateid ] [ E_GATE_MODELID ])) ;

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Started copying gate %d (SQL %d)", src_gateid, Gate [ src_gateid ] [ E_GATE_SQLID ])) ;

	return true ;
}

// Instant duplicate of a gate (all settings, textures, extra faction access) at the
// same position. Adjust the new gate afterwards with /gatemove and /gateopen.
CMD:gateclone(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new src ;

	if ( sscanf ( params, "i", src ) ) {

		return SendClientMessage(playerid, -1, "/gateclone [gateid]") ;
	}

	if ( src < 0 || src >= MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid.") ;
	}

	if ( Gate [ src ] [ E_GATE_SQLID ] == INVALID_GATE_ID || Gate [ src ] [ E_GATE_SQLID ] == GATE_SETUP_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid.") ;
	}

	new new_id = Gate_GetFreeID() ;

	if ( new_id == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "No free gate slots left.") ;
	}

	// Reserve the slot until the insert returns, so nothing else can claim it.
	Gate [ new_id ] [ E_GATE_SQLID ]   = GATE_SETUP_ID ;
	Gate [ new_id ] [ E_GATE_STATE ]   = false ;
	Gate [ new_id ] [ E_GATE_SETUP ]   = 0 ;

	Gate [ new_id ] [ E_GATE_MODELID ] = Gate [ src ] [ E_GATE_MODELID ] ;
	Gate [ new_id ] [ E_GATE_TYPE ]    = Gate [ src ] [ E_GATE_TYPE ] ;
	Gate [ new_id ] [ E_GATE_OWNER ]   = Gate [ src ] [ E_GATE_OWNER ] ;

	Gate [ new_id ] [ E_GATE_SPEED ]     = Gate [ src ] [ E_GATE_SPEED ] ;
	Gate [ new_id ] [ E_GATE_RADIUS ]    = Gate [ src ] [ E_GATE_RADIUS ] ;
	Gate [ new_id ] [ E_GATE_TOLL ]      = Gate [ src ] [ E_GATE_TOLL ] ;
	Gate [ new_id ] [ E_GATE_AUTOCLOSE ] = Gate [ src ] [ E_GATE_AUTOCLOSE ] ;
	Gate [ new_id ] [ E_GATE_AUTOOPEN ]  = Gate [ src ] [ E_GATE_AUTOOPEN ] ;

	Gate [ new_id ] [ E_GATE_INTERIOR ]     = Gate [ src ] [ E_GATE_INTERIOR ] ;
	Gate [ new_id ] [ E_GATE_VIRTUALWORLD ] = Gate [ src ] [ E_GATE_VIRTUALWORLD ] ;

	Gate [ new_id ] [ E_GATE_CLOSED_POS_X ] = Gate [ src ] [ E_GATE_CLOSED_POS_X ] ;
	Gate [ new_id ] [ E_GATE_CLOSED_POS_Y ] = Gate [ src ] [ E_GATE_CLOSED_POS_Y ] ;
	Gate [ new_id ] [ E_GATE_CLOSED_POS_Z ] = Gate [ src ] [ E_GATE_CLOSED_POS_Z ] ;
	Gate [ new_id ] [ E_GATE_CLOSED_ROT_X ] = Gate [ src ] [ E_GATE_CLOSED_ROT_X ] ;
	Gate [ new_id ] [ E_GATE_CLOSED_ROT_Y ] = Gate [ src ] [ E_GATE_CLOSED_ROT_Y ] ;
	Gate [ new_id ] [ E_GATE_CLOSED_ROT_Z ] = Gate [ src ] [ E_GATE_CLOSED_ROT_Z ] ;

	Gate [ new_id ] [ E_GATE_OPEN_POS_X ] = Gate [ src ] [ E_GATE_OPEN_POS_X ] ;
	Gate [ new_id ] [ E_GATE_OPEN_POS_Y ] = Gate [ src ] [ E_GATE_OPEN_POS_Y ] ;
	Gate [ new_id ] [ E_GATE_OPEN_POS_Z ] = Gate [ src ] [ E_GATE_OPEN_POS_Z ] ;
	Gate [ new_id ] [ E_GATE_OPEN_ROT_X ] = Gate [ src ] [ E_GATE_OPEN_ROT_X ] ;
	Gate [ new_id ] [ E_GATE_OPEN_ROT_Y ] = Gate [ src ] [ E_GATE_OPEN_ROT_Y ] ;
	Gate [ new_id ] [ E_GATE_OPEN_ROT_Z ] = Gate [ src ] [ E_GATE_OPEN_ROT_Z ] ;

	for ( new i = 0; i < MAX_GATE_FACTIONS; i++ ) {

		GateFactionAccess [ new_id ] [ i ] = GateFactionAccess [ src ] [ i ] ;
	}

	Gate [ new_id ] [ E_GATE_OBJECTID ] = CreateDynamicObject(Gate [ new_id ] [ E_GATE_MODELID ],
		Gate [ new_id ] [ E_GATE_CLOSED_POS_X ], Gate [ new_id ] [ E_GATE_CLOSED_POS_Y ], Gate [ new_id ] [ E_GATE_CLOSED_POS_Z ],
		Gate [ new_id ] [ E_GATE_CLOSED_ROT_X ], Gate [ new_id ] [ E_GATE_CLOSED_ROT_Y ], Gate [ new_id ] [ E_GATE_CLOSED_ROT_Z ],
		Gate [ new_id ] [ E_GATE_VIRTUALWORLD ], Gate [ new_id ] [ E_GATE_INTERIOR ],
		.priority = STREAM_PRIORITY_INTERACTABLE ) ;

	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ new_id ] [ E_GATE_OBJECTID ], E_STREAMER_STREAM_DISTANCE, 500 ) ;
	Streamer_SetFloatData(STREAMER_TYPE_OBJECT, Gate [ new_id ] [ E_GATE_OBJECTID ], E_STREAMER_DRAW_DISTANCE, 500 ) ;

	for ( new t = 0; t < 16; t++ ) {

		Gate [ new_id ] [ E_GATE_TEXTUREID ] [ t ] = Gate [ src ] [ E_GATE_TEXTUREID ] [ t ] ;

		Gate_Texture_TXD  [ new_id ] [ t ] [ 0 ] = EOS ;
		Gate_Texture_Name [ new_id ] [ t ] [ 0 ] = EOS ;

		strcat(Gate_Texture_TXD  [ new_id ] [ t ], Gate_Texture_TXD  [ src ] [ t ]) ;
		strcat(Gate_Texture_Name [ new_id ] [ t ], Gate_Texture_Name [ src ] [ t ]) ;

		if ( Gate [ new_id ] [ E_GATE_TEXTUREID ] [ t ] ) {

			SetDynamicObjectMaterial(Gate [ new_id ] [ E_GATE_OBJECTID ], t,
				Gate [ new_id ] [ E_GATE_TEXTUREID ] [ t ],
				Gate_Texture_TXD  [ new_id ] [ t ],
				Gate_Texture_Name [ new_id ] [ t ]
			) ;
		}
	}

	new query [ 1024 ] ;

	mysql_format ( mysql, query, sizeof ( query ),
		"INSERT INTO gates (gate_modelid, gate_type, gate_owner, gate_interior, gate_virtualworld, gate_speed, gate_radius, gate_toll, gate_autoclose, gate_autoopen, gate_closed_pos_x, gate_closed_pos_y, gate_closed_pos_z, gate_closed_rot_x, gate_closed_rot_y, gate_closed_rot_z, gate_open_pos_x, gate_open_pos_y, gate_open_pos_z, gate_open_rot_x, gate_open_rot_y, gate_open_rot_z) VALUES (%d, %d, %d, %d, %d, '%f', '%f', %d, %d, %d, '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f')",
		Gate [ new_id ] [ E_GATE_MODELID ], Gate [ new_id ] [ E_GATE_TYPE ], Gate [ new_id ] [ E_GATE_OWNER ],
		Gate [ new_id ] [ E_GATE_INTERIOR ], Gate [ new_id ] [ E_GATE_VIRTUALWORLD ],
		Gate [ new_id ] [ E_GATE_SPEED ], Gate [ new_id ] [ E_GATE_RADIUS ],
		Gate [ new_id ] [ E_GATE_TOLL ], Gate [ new_id ] [ E_GATE_AUTOCLOSE ], Gate [ new_id ] [ E_GATE_AUTOOPEN ],
		Gate [ new_id ] [ E_GATE_CLOSED_POS_X ], Gate [ new_id ] [ E_GATE_CLOSED_POS_Y ], Gate [ new_id ] [ E_GATE_CLOSED_POS_Z ],
		Gate [ new_id ] [ E_GATE_CLOSED_ROT_X ], Gate [ new_id ] [ E_GATE_CLOSED_ROT_Y ], Gate [ new_id ] [ E_GATE_CLOSED_ROT_Z ],
		Gate [ new_id ] [ E_GATE_OPEN_POS_X ], Gate [ new_id ] [ E_GATE_OPEN_POS_Y ], Gate [ new_id ] [ E_GATE_OPEN_POS_Z ],
		Gate [ new_id ] [ E_GATE_OPEN_ROT_X ], Gate [ new_id ] [ E_GATE_OPEN_ROT_Y ], Gate [ new_id ] [ E_GATE_OPEN_ROT_Z ]
	) ;

	new src_sqlid = Gate [ src ] [ E_GATE_SQLID ] ;

	inline Gate_OnCloneInsert() {

		new new_sqlid = cache_insert_id () ;

		if ( new_sqlid <= 0 ) {

			// Insert failed - roll the slot back so it isn't left half-created.
			if ( IsValidDynamicObject ( Gate [ new_id ] [ E_GATE_OBJECTID ] ) ) {

				ORP_DestroyObject(Gate [ new_id ] [ E_GATE_OBJECTID ], "Gate/CMD_GateClone", true ) ;
			}

			Gate [ new_id ] [ E_GATE_OBJECTID ] = INVALID_OBJECT_ID ;
			Gate [ new_id ] [ E_GATE_SQLID ]    = INVALID_GATE_ID ;

			for ( new i = 0; i < MAX_GATE_FACTIONS; i++ ) {

				GateFactionAccess [ new_id ] [ i ] = -1 ;
			}

			SendClientMessage(playerid, COLOR_RED, sprintf("[GATE] Failed to clone gate %d (SQL: %d) - database insert failed.", src, src_sqlid)) ;
		}

		else {

			Gate [ new_id ] [ E_GATE_SQLID ] = new_sqlid ;

			// Textures (the insert above only carries the core columns).
			for ( new t = 0; t < 16; t++ ) {

				if ( ! Gate [ new_id ] [ E_GATE_TEXTUREID ] [ t ] ) continue ;

				new tq [ 512 ] ;

				mysql_format(mysql, tq, sizeof(tq),
					"UPDATE gates SET gate_textureid%d = %d, gate_texturetxd%d = '%e', gate_texturename%d = '%e' WHERE gate_sqlid = %d",
					t, Gate [ new_id ] [ E_GATE_TEXTUREID ] [ t ],
					t, Gate_Texture_TXD  [ new_id ] [ t ],
					t, Gate_Texture_Name [ new_id ] [ t ],
					new_sqlid
				) ;

				mysql_tquery(mysql, tq) ;
			}

			// Extra faction access.
			for ( new i = 0; i < MAX_GATE_FACTIONS; i++ ) {

				if ( GateFactionAccess [ new_id ] [ i ] == -1 ) continue ;

				new fq [ 128 ] ;

				mysql_format(mysql, fq, sizeof(fq),
					"INSERT IGNORE INTO gate_factions (gate_sqlid, faction_id) VALUES (%d, %d)",
					new_sqlid, GateFactionAccess [ new_id ] [ i ]
				) ;

				mysql_tquery(mysql, fq) ;
			}

			SendClientMessage(playerid, COLOR_YELLOW, sprintf("[GATE] Cloned gate %d (SQL: %d) -> new gate ID %d (SQL: %d). It sits on top of the original: use /gatemove %d then /gateopen %d.",
				src, src_sqlid, new_id, new_sqlid, new_id, new_id)) ;

			AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Cloned gate %d (SQL %d) to gate %d (SQL %d)",
				src, src_sqlid, new_id, new_sqlid)) ;
		}
	}

	MySQL_TQueryInline(mysql, using inline Gate_OnCloneInsert, query, "") ;

	return true ;
}

// /gategoto [gate] - (admin) teleports to a gate.
CMD:gategoto(playerid, params[]) {
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}
	
	new gateid ;

	if ( sscanf ( params, "i", gateid ) ) {

		return SendClientMessage(playerid, -1, "/gategoto [gateid]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}


	PauseAC(playerid, 3);
 	SetPlayerPos ( playerid, Gate [ gateid ] [ E_GATE_CLOSED_POS_X ], Gate [ gateid ] [ E_GATE_CLOSED_POS_Y ], Gate [ gateid ] [ E_GATE_CLOSED_POS_Z ] );

 	SetPlayerInterior ( playerid, Gate [ gateid ] [ E_GATE_INTERIOR ]) ;
 	SetPlayerVirtualWorld ( playerid, Gate [ gateid ] [ E_GATE_VIRTUALWORLD ]) ;

	SendClientMessage(playerid, -1, sprintf("Teleported to gate ID %d.", gateid  ) ) ;
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Teleported to gate ID %d.", gateid  ));


	return true ;
}

