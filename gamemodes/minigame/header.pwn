// ============================================================================
// File: minigame/header.pwn
// Minigame entry point: includes pool, basketball and the shared pieces, starts them
// (Minigames_LoadEntities), resets state when a player leaves (Minigame_ResetVariables) and
// defines /coin and /dice.
// Commands: /coin /dice
// ============================================================================

#define ITER_NONE (cellmin)  // Temporary fix for https://github.com/Misiur/YSI-Includes/issues/109 

// Returns one of its arguments at random.
stock randarg( ... )
	return getarg( random( numargs( ) ) );


#include "minigame/helpbox.pwn"
#include "minigame/shakehands.pwn"

// sf-cnr
#include "minigame/pool/header.pwn"


// matz
#include "minigame/basketball/header.pwn"


// Starts all minigames at server start-up.
Minigames_LoadEntities() {

	Basketball_Init();
	Pool_OnModeInit();

}

// Removes a player from every minigame and cancels jobs. Call this from your system when it needs
// to reset on death/logout.
Minigame_ResetVariables(playerid) {
	RemovePlayerFromBasketball(playerid);
	Pool_RemovePlayer( playerid );

	GarbageJob_CancelData(playerid);
	Hotwire_CloseMenu(playerid);
	Picklock_CloseGUI(playerid);
	Spawnables_OnPlayerDeath(playerid);
	Gym_ExitMachine(playerid, PlayerGym [ playerid ] [ E_PLAYER_GYM_MACHINE_TYPE ], 0, .anim=false); // reset variables!

	// Reset CP data
	cmd_nocp(playerid);

	// Chopshop (make this in a function & universalise it)
 	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_PAYOUT ] = 0 ;
	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_CARID ] = INVALID_VEHICLE_ID ;
	PlayerVar [ playerid ] [ E_PLAYER_CHOPSHOP_DROPPOINT ] = -1 ;	
}

// Returns true if the player is currently in a minigame (basketball, gym, pool).
IsPlayerInMinigame(playerid) {

	// Basketball
	if ( BasketPlayerVars[playerid][PlayerCourtID] != -1 ) {

		return true ;
	}

	if ( PlayerGym [ playerid ] [ E_PLAYER_USING_GYM ] ) {

		return true ;
	}

	// Pool
	if ( IsPlayerPlayingPool( playerid ) ) {

		return true ;
	}

    return false ;
}

// Sends a formatted client message to one player or everyone.
stock SendClientMessageFormatted( playerid, colour, const format[ ], va_args<> ) {
    static out[ 144 ];

    va_format( out, sizeof( out ), format, va_start<3> );

    if ( playerid == INVALID_PLAYER_ID ) {
        return SendClientMessageToAll( colour, out );
    } 

    else {
        return SendClientMessage( playerid, colour, out );
    }
}

// Make a minigame textdraw:
// szBigString = "~y~~k~~PED_SPRINT~~w~ - Begin game/Stand~n~~y~~k~~GROUP_CONTROL_BWD~~w~ - Hit~n~~y~~k~~VEHICLE_ENTER_EXIT~~w~ - Exit";
// ShowPlayerHelpDialog( playerid, 0, szBigString );

// /coin - flips a coin in character.
CMD:coin(playerid, params[]) {

	new string[256];
	switch (random(100)) {
		case 0 .. 48: 	format(string, sizeof(string), "flips a coin and it lands on \"tails\".") ;
		case 49 .. 98: 	format(string, sizeof(string), "flips a coin and it lands on \"heads\".") ;
		default: 		format(string, sizeof(string), "flips a coin, it falls on the ground and is nowhere to be found!") ;
	}
	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "**", string, .annonated=true);
	return true ;
}

// /dice [1-3] - rolls one, two or three dice in character.
CMD:dice(playerid, params[]) {

	new string[256], amount ;
	sscanf(params, "I(0)", amount);

	new margin = 1 + random(6), margin2 = 1 + random(6), margin3 = 1 + random(6);

	switch(amount) {
		case 2:		format ( string, sizeof ( string ), "rolls two dice. They land on %d and %d.", margin, margin2) ;
		case 3:		format(string, sizeof ( string ), "rolls three dice. They land on %d, %d and %d.", margin, margin2, margin3) ;
		default: 	format(string, sizeof ( string ), "rolls a dice and it lands on %d.", margin) ;
	}

	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "**", string, .annonated=true);

	return true ;
}

// Gets a point to the right of a position and heading.
stock GetXYRightOfPoint(&Float:a, &Float:X, &Float:Y, Float:distance)
{
    a -= 90.0;
    X += floatmul(floatsin(-a, degrees), distance);
    Y += floatmul(floatcos(-a, degrees), distance);
}

// Gets a point to the left of a position and heading.
stock GetXYLeftOfPoint(&Float:a, &Float:X, &Float:Y, Float:distance)
{
    a -= 270.0;
    X += floatmul(floatsin(-a, degrees), distance);
    Y += floatmul(floatcos(-a, degrees), distance);
}

// Gets a point behind a position and heading.
stock GetXYBackOfPoint(&Float:a, &Float:x, &Float:y, const Float:distance)
{
    x -= (distance * floatsin(-a, degrees));
    y -= (distance * floatcos(-a, degrees));
}


// Gets a point in front of a position and heading.
stock GetXYInFrontOfPoint(&Float:a, &Float:x2, &Float:y2, Float:distance)
{
    x2 += (distance * floatsin(-a, degrees));
    y2 += (distance * floatcos(-a, degrees));
}
