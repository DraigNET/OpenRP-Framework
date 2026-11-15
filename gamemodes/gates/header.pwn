// ============================================================================
// File: gates/header.pwn
// Gate module entry point. /gate and /door open and close gates, access checks
// (Gate_PlayerHasAccess), auto-open for vehicles, and the toll fee calculation
// (Gate_GetTollFee) based on vehicle cargo capacity.
// Commands: /gatedelete /gatespeed /door /toll /gate
// ============================================================================

#include <YSI_Coding\y_hooks>

#if !defined GATE_RESET_TIME
	#define GATE_RESET_TIME 15000 // ms
#endif

// Transportation tax on the toll gates: $10 per slot of cargo space, so a van pays little and a big rig a lot.
// A tractor unit (Linerunner, Tanker, Roadtrain) carries nothing itself, so it pays for the trailer it is pulling;
// with no trailer it pays for a flat 10 slots so a bobtail isn't a free pass.
forward bool: IsTractorUnit(modelid) ; // jobs/trucker/commodity.pwn, included after this file

#define TOLL_FEE_PER_SLOT   ( 10 )
#define TOLL_BOBTAIL_SLOTS  ( 10 )

// Returns the toll price for a vehicle, based on its cargo capacity (tractor units pay for the
// trailer they pull).
Gate_GetTollFee(vehicleid) {

	new model = GetVehicleModel ( vehicleid ) ;
	new slots = GetMaxStorageModel ( model ) ;

	if ( IsTractorUnit ( model ) ) {

		new trailerid = GetVehicleTrailer ( vehicleid ) ;

		slots = ( trailerid ) ? Trucker_GetVehicleCapacity ( GetVehicleModel ( trailerid ) ) : 0 ;

		if ( slots < 1 ) {

			slots = TOLL_BOBTAIL_SLOTS ;
		}
	}

	return slots * TOLL_FEE_PER_SLOT ;
}

#if !defined SERVER_TOLL_FEE 
	#define SERVER_TOLL_FEE	( 150 )
#endif

#include "gates/data.pwn"
#include "gates/func.pwn"
#include "gates/cmds.pwn"
#include "gates/tolls.pwn"


// ############################################################# //

stock bool:Gate_PlayerHasAccess(playerid, gateid);

// /gatedelete [gate] - (admin) deletes a gate.
CMD:gatedelete(playerid, params[]) {

	new gateid ;

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	if ( sscanf ( params, "i", gateid ) ) {

		return SendClientMessage(playerid, -1, "/gatedelete [gateid]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	new query [ 256 ], deleted_sqlid = Gate [ gateid ] [ E_GATE_SQLID ] ;

	mysql_format(mysql, query, sizeof(query), "DELETE FROM gates WHERE gate_sqlid = %d", Gate [ gateid ] [ E_GATE_SQLID ] ) ;
	mysql_tquery(mysql, query );

	// Extra faction access rows would otherwise be orphaned (and could attach to a reused SQL id).
	mysql_format(mysql, query, sizeof(query), "DELETE FROM gate_factions WHERE gate_sqlid = %d", Gate [ gateid ] [ E_GATE_SQLID ] ) ;
	mysql_tquery(mysql, query );

	if ( IsValidDynamicObject( Gate [ gateid ] [ E_GATE_OBJECTID ] ) ) {

		ORP_DestroyObject(Gate [ gateid ] [ E_GATE_OBJECTID ], "Gate/CMD_GateDelete", true ) ;
	}

	Gate [ gateid ] [ E_GATE_OBJECTID ] = INVALID_OBJECT_ID ;
	Gate [ gateid ] [ E_GATE_STATE ] = false ;

	// Clear per-slot data so the next gate created in this slot doesn't inherit it.
	for ( new i = 0; i < MAX_GATE_FACTIONS; i++ ) {

		GateFactionAccess [ gateid ] [ i ] = -1 ;
	}

	for ( new t = 0; t < 16; t++ ) {

		Gate [ gateid ] [ E_GATE_TEXTUREID ] [ t ] = 0 ;
		Gate_Texture_TXD [ gateid ] [ t ] [ 0 ] = EOS ;
		Gate_Texture_Name [ gateid ] [ t ] [ 0 ] = EOS ;
	}

	SendClientMessage(playerid, -1, sprintf("You've deleted gate SQL ID %d.", Gate [ gateid ] [ E_GATE_SQLID ] ) ) ;
	
	Gate [ gateid ] [ E_GATE_SQLID ] = INVALID_GATE_ID ;

	Gate [ gateid ] [ E_GATE_CLOSED_POS_X ] = 0.0 ;
	Gate [ gateid ] [ E_GATE_CLOSED_POS_Y ] = 0.0 ;  
	Gate [ gateid ] [ E_GATE_CLOSED_POS_Z ] = 0.0 ;

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Deleted gate SQL ID %d.", deleted_sqlid));

	return true ;
}

// /gatespeed [gate] [speed] - (admin) sets how fast a gate moves.
CMD:gatespeed(playerid, params[]) 
{
	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.") ;
	}

	new gateid,Float: speed ;

	if ( sscanf ( params, "if", gateid, speed ) ) {

		return SendClientMessage(playerid, -1, "/gatespeed [gateid] [speed (in miliseconds, i.e. \"0.75\")]");
	}

	if ( gateid > MAX_GATES ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}	

	if ( Gate [ gateid ] [ E_GATE_SQLID ] == INVALID_GATE_ID ) {

		return SendClientMessage(playerid, -1, "Gate ID you entered is invalid." ) ;
	}

	Gate [ gateid ] [ E_GATE_SPEED ] = speed ;

	new query [ 256 ] ;

	mysql_format(mysql, query, sizeof(query), "UPDATE gates SET gate_speed = '%f' WHERE gate_sqlid = %d",

		speed, Gate [ gateid ] [ E_GATE_SQLID ] ) ;

	mysql_tquery(mysql, query );

	SendClientMessage(playerid, -1, sprintf("Updated gate ID %d's speed to %.3f.", gateid, Gate [ gateid ] [ E_GATE_SPEED ] ) ) ;
	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Updated gate %d's speed to  %.3f.", gateid, Gate [ gateid ] [ E_GATE_SPEED ] ));
	return true ;
}


// ############################################################# //

CMD:door(playerid, params[]) {

	return cmd_gate(playerid, params);
}

CMD:toll(playerid, params[]) {

	return cmd_gate(playerid, params);
}


// /gate - opens or closes the nearest gate if you have access (also takes toll fees).
CMD:gate(playerid, params[]) {
	
	if ( IsPlayerIncapacitated(playerid, false) ) {
    
        return SendServerMessage ( playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this." ) ;
    }

	new gate_enum_id = Gate_GetClosestEntity(playerid) ;

	if ( gate_enum_id == INVALID_GATE_ID ) {

		return true ;
	}

	if ( GetPlayerAdminLevel ( playerid ) >= ADMIN_LVL_GENERAL && PlayerVar[playerid][E_PLAYER_ADMIN_DUTY] ) {

		SendClientMessage(playerid, COLOR_YELLOW, sprintf("[GATE] Gate ID %d (SQL: %d). Type: %s. Owned by ID %d.",
			gate_enum_id,Gate [ gate_enum_id ] [ E_GATE_SQLID ], Gate_GetType(gate_enum_id), Gate [ gate_enum_id ] [ E_GATE_OWNER ] )) ;
	}

	if ( ! IsValidDynamicObject( Gate [ gate_enum_id ] [ E_GATE_OBJECTID] )) {

		return SendClientMessage(playerid, -1, "This gate isn't set up properly (no object)");
	}

	if (IsDynamicObjectMoving(Gate [ gate_enum_id ] [ E_GATE_OBJECTID ]))
	{
		return SendClientMessage(playerid, -1, "Wait for the gate to finish moving first.");
	}

	// New gate access code by Torque, supports multiple faction access.
	if (!Gate_PlayerHasAccess(playerid, gate_enum_id))
	{
		if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR && PlayerVar[playerid][E_PLAYER_ADMIN_DUTY])
		{
			SendClientMessage(playerid, COLOR_YELLOW,
				"You're using your admin powers to open this gate.");
		}
		else if (GetPlayerAdminLevel(playerid) > ADMIN_LVL_JUNIOR)
		{
			return SendClientMessage(playerid, -1,
				"You don't have normal access to this gate, but can go on admin duty to open it.");
		}
		else
		{
			return SendClientMessage(playerid, -1,
				"You don't have access to this gate.");
		}
	}

	if ( Gate [ gate_enum_id ] [ E_GATE_TOLL ]) 
	{

		if ( ! IsPlayerInAnyVehicle(playerid)) {
			return SendClientMessage(playerid, COLOR_RED, "Trying to avoid the toll tax? Nice try! This command only works INSIDE a car!" ) ;
		}

		new toll_fee = Gate_GetTollFee ( GetPlayerVehicleID(playerid) ) ;
		new toll_needed = ( toll_fee > SERVER_TOLL_FEE ) ? toll_fee : SERVER_TOLL_FEE ;

		if ( GetPlayerCash ( playerid) < toll_needed ) {

			SendClientMessage(playerid, COLOR_RED, sprintf("You need at least $%s to operate the tolls.", IntegerWithDelimiter(toll_needed ) ) ) ;
			return true ;
		}

		if ( Server [ E_SERVER_TOLLS_LOCKED ] ) {

			return SendClientMessage(playerid, -1, "The tolls are currently closed by the police. If they remain closed after extended duration, call 311 or an admin.");
		}

		if  (  Gate [ gate_enum_id ] [ E_GATE_STATE ] ) {

			return SendClientMessage(playerid, COLOR_RED, "This toll gate is already opened!" ) ;
		}

		TakePlayerCash ( playerid, toll_fee, "Toll fee payment" ) ;

		if  ( ! Gate [ gate_enum_id ] [ E_GATE_STATE ] ) {
			SendClientMessage(playerid, COLOR_INFO, sprintf("The toll gate will shut automatically after 15 seconds. You've been charged $%s transportation tax.", IntegerWithDelimiter(toll_fee )));
			defer Gate_ResetState(gate_enum_id);
		}
	}

	else if ( ! Gate [ gate_enum_id ] [ E_GATE_TOLL ]) {

		if ( Gate [ gate_enum_id ] [ E_GATE_AUTOCLOSE] ) {

			if  ( ! Gate [ gate_enum_id ] [ E_GATE_STATE ] ) {
				SendClientMessage(playerid, COLOR_INFO, "The gate will shut automatically after 15 seconds. Don't get stuck!");
				defer Gate_ResetState(gate_enum_id);
			}
		}
	}


	new movetime ;

	if ( Gate [ gate_enum_id ] [ E_GATE_STATE ] ) {

		movetime = MoveDynamicObject(Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_X ] + 0.001, Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_Y ] + 0.001, 
			Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_Z ], Gate [ gate_enum_id ] [ E_GATE_SPEED ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_X ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_Y ], 
			Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_Z ] ) ;

		if ( PlayerVar[playerid][E_PLAYER_ADMIN_DUTY] ) {

			SendClientMessage(playerid, COLOR_YELLOW, sprintf("[GATE] Gate ID %d (SQL: %d) closed in %d milliseconds.", gate_enum_id,Gate [ gate_enum_id ] [ E_GATE_SQLID ],  movetime )) ;
		}

		Gate [ gate_enum_id ] [ E_GATE_STATE ] = false ;
		AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Has closed gate %d", gate_enum_id));
						
	}
	else if ( ! Gate [ gate_enum_id ] [ E_GATE_STATE ] ) {

		if ( Gate [ gate_enum_id ] [ E_GATE_OPEN_POS_X ] == 0.0 || Gate [ gate_enum_id ] [ E_GATE_OPEN_POS_Y ] == 0.0 || Gate [ gate_enum_id ] [ E_GATE_OPEN_POS_Z ] == 0.0 ) {

			return SendClientMessage(playerid, -1, "Gate open positions aren't set up. Get an admin to set them up before doing this command.");
		}
		
		movetime = MoveDynamicObject(Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], Gate [ gate_enum_id ] [ E_GATE_OPEN_POS_X ] + 0.001, Gate [ gate_enum_id ] [ E_GATE_OPEN_POS_Y ] + 0.001, 
			Gate [ gate_enum_id ] [ E_GATE_OPEN_POS_Z ], Gate [ gate_enum_id ] [ E_GATE_SPEED ], Gate [ gate_enum_id ] [ E_GATE_OPEN_ROT_X ], Gate [ gate_enum_id ] [ E_GATE_OPEN_ROT_Y ], 
			Gate [ gate_enum_id ] [ E_GATE_OPEN_ROT_Z ] ) ;


		if ( PlayerVar[playerid][E_PLAYER_ADMIN_DUTY] ) {

			SendClientMessage(playerid, COLOR_YELLOW, sprintf("[GATE] Gate ID %d (SQL: %d) opened in %d milliseconds.", gate_enum_id,Gate [ gate_enum_id ] [ E_GATE_SQLID ],  movetime )) ;
		}

		Gate [ gate_enum_id ] [ E_GATE_STATE ] = true ;
		AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Has opened gate %d", gate_enum_id));
	}

	return true ;
}

// Returns true if the player may use the gate (public, owner, faction member, key holder...).
stock bool:Gate_PlayerHasAccess(playerid, gateid)
{
    switch (Gate[gateid][E_GATE_TYPE])
    {
        case E_GATE_TYPE_PUBLIC:
            return true;

        case E_GATE_TYPE_PLAYER:
            return (Character[playerid][E_CHARACTER_ID] == Gate[gateid][E_GATE_OWNER]);

        case E_GATE_TYPE_PROPERTY:
            return (Character[playerid][E_CHARACTER_RENTEDHOUSE] == Gate[gateid][E_GATE_OWNER]);

        case E_GATE_TYPE_FACTION:
		{
			new playerFaction = Character[playerid][E_CHARACTER_FACTIONID];

			if (GetPlayerFactionSuspension(playerid) != 0)
				return false;

			// Primary faction owner
			if (playerFaction == Gate[gateid][E_GATE_OWNER])
				return true;

			// Extra allowed factions
			for (new i = 0; i < MAX_GATE_FACTIONS; i++)
			{
				if (GateFactionAccess[gateid][i] == playerFaction)
					return true;
			}

			return false;
		}
    }
    return false;
}

// Opens a gate automatically as a vehicle approaches.
stock AutoOpenGate(gateid)
{
    // Prevent spam if multiple players in radius
    Gate[gateid][E_GATE_STATE] = true;

    MoveDynamicObject(
        Gate[gateid][E_GATE_OBJECTID],
        Gate[gateid][E_GATE_OPEN_POS_X] + 0.001,
        Gate[gateid][E_GATE_OPEN_POS_Y] + 0.001,
        Gate[gateid][E_GATE_OPEN_POS_Z],
        Gate[gateid][E_GATE_SPEED],
        Gate[gateid][E_GATE_OPEN_ROT_X],
        Gate[gateid][E_GATE_OPEN_ROT_Y],
        Gate[gateid][E_GATE_OPEN_ROT_Z]
    );

    if (Gate[gateid][E_GATE_AUTOCLOSE])
    {
        defer Gate_ResetState(gateid);
    }

    return 1;
}

hook OnPlayerUpdate(playerid)
{
    // Loop gates
    for (new i = 0; i < MAX_GATES; i++)
    {
        if (Gate[i][E_GATE_SQLID] == INVALID_GATE_ID) continue;

        // Conditions for auto-open
        if (Gate[i][E_GATE_AUTOOPEN] == 1 &&
            Gate[i][E_GATE_STATE] == 0 && // closed
            !IsDynamicObjectMoving(Gate[i][E_GATE_OBJECTID]) &&
            IsPlayerInRangeOfPoint(playerid, Gate[i][E_GATE_RADIUS],
                Gate[i][E_GATE_CLOSED_POS_X],
                Gate[i][E_GATE_CLOSED_POS_Y],
                Gate[i][E_GATE_CLOSED_POS_Z]))
        {
            // Access check
            if (!Gate_PlayerHasAccess(playerid, i)) continue;

            // ============================
            // 🔹 SQL Pair Auto-Open Support
            // ============================
            for (new p = 0; p < MAX_GATE_PAIRS; p++)
            {
                new sql_a = GateSQLPairs[p][0];
                new sql_b = GateSQLPairs[p][1];

                if (sql_a == -1 || sql_b == -1) continue;

                new mySQL = Gate[i][E_GATE_SQLID];

                if (mySQL == sql_a || mySQL == sql_b)
                {
                    new otherSQL = (mySQL == sql_a) ? sql_b : sql_a;
                    new otherGate = Gate_FindBySQL(otherSQL);

                    if (otherGate != INVALID_GATE_ID &&
                        Gate[otherGate][E_GATE_AUTOOPEN] == 1 &&
                        Gate[otherGate][E_GATE_STATE] == 0 &&
                        !IsDynamicObjectMoving(Gate[otherGate][E_GATE_OBJECTID]) &&
                        Gate_PlayerHasAccess(playerid, otherGate))
                    {
                        AutoOpenGate(otherGate);
                    }
                }
            }

            // Open the original gate
            AutoOpenGate(i);
        }
    }

    return 1;
}

// Timer: closes an open gate again after the reset time.
timer Gate_ResetState[GATE_RESET_TIME](gate_enum_id) {

	if ( Gate [ gate_enum_id ] [ E_GATE_STATE ] ) {

		//SetDynamicObjectPos( Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_X ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_Y ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_Z ] );
		//ORP_SetObjectRot ( Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_X ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_Y ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_Z ], "Gate/ResetState", true) ; 
	
		MoveDynamicObject(Gate [ gate_enum_id ] [ E_GATE_OBJECTID ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_X ] + 0.001, Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_Y ] + 0.001, 
		Gate [ gate_enum_id ] [ E_GATE_CLOSED_POS_Z ], Gate [ gate_enum_id ] [ E_GATE_SPEED ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_X ], Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_Y ], 
		Gate [ gate_enum_id ] [ E_GATE_CLOSED_ROT_Z ] ) ;

		Gate [ gate_enum_id ] [ E_GATE_STATE ] = false ; // 14.2585
	}

	return true ;
}
