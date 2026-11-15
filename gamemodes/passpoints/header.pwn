// ============================================================================
// File: passpoints/header.pwn
// Using passpoints: /pass walks through the nearest passpoint (with ownership and faction
// checks) and /passpointlock locks or unlocks it.
// Commands: /pass /passpointlock
// ============================================================================

#define MAX_PASSPOINTS			( 150 )
#define INVALID_PASSPOINT_ID	(-1)

#include "passpoints/data.pwn"
#include "passpoints/admin.pwn"

// /pass - walks through the nearest passpoint to its other end, if the player has access.
CMD:pass(playerid, params[]) 
{
	if ( IsPlayerIncapacitated(playerid, true) ) {
    
        return true ;
    }

	if (IsPlayerFading(playerid)) return true; // Make them wait first

	new closest_point = GetClosestPasspoint(playerid, true);

	if ( PlayerVar[playerid][E_PLAYER_ADMIN_DUTY] ) {
		SendClientMessage(playerid, -1, sprintf("Closest point (enum ID): %d", closest_point ) ) ;
	}

	return true ;
}

// /passpointlock - locks or unlocks the nearest passpoint (owner or faction).
CMD:passpointlock(playerid, params[])
{
    new point = GetClosestPasspoint(playerid, false);

    if (point == INVALID_PASSPOINT_ID) {
        return SendServerMessage(playerid, COLOR_ERROR, "Passpoint", "A3A3A3", "You are not near a passpoint.");
    }

    // Must have an owner
    if (Passpoint[point][E_PASSPOINT_OWNER] == 0) {
        return SendServerMessage(playerid, COLOR_ERROR, "Passpoint", "A3A3A3", "This passpoint has no owner.");
    }

    // Ownership check
    if (Passpoint[point][E_PASSPOINT_OWNER] != Character[playerid][E_CHARACTER_ID]) {
        return SendServerMessage(playerid, COLOR_ERROR, "Passpoint", "A3A3A3", "You are not the owner of this passpoint.");
    }

    // Toggle
    Passpoint[point][E_PASSPOINT_LOCKED] = !Passpoint[point][E_PASSPOINT_LOCKED];

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE passpoints SET passpoint_locked = %d WHERE passpoint_sqlid = %d",
        Passpoint[point][E_PASSPOINT_LOCKED],
        Passpoint[point][E_PASSPOINT_SQLID]
    );
    mysql_tquery(mysql, query);

    if (Passpoint[point][E_PASSPOINT_LOCKED]) {
        SendServerMessage(playerid, COLOR_BLUE, "Passpoint", "A3A3A3", "Passpoint locked.");
    } else {
        SendServerMessage(playerid, COLOR_BLUE, "Passpoint", "A3A3A3", "Passpoint unlocked.");
    }

	PassPoint_SetupLabel(point);

    return true;
}
