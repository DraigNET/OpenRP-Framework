// ============================================================================
// File: config/utils/funcs.pwn
// General helper functions used everywhere: SendServerMessage() (the standard prefixed
// message), ClearChat, position helpers (GetXYInFrontOfPlayer), MakePlayerFacePoint, IsNumeric,
// player proximity checks and vehicle state names.
// ============================================================================


// Returns a player's name (before they are logged in).
TEMP_ReturnPlayerName(playerid) {
	// Find a way to get rid of this redundant function A.S.A.P.

	new name [ MAX_PLAYER_NAME ] ;

	GetPlayerName ( playerid, name, sizeof ( name ) ) ;

	return name ;
}

// Clears the player's animations and puts them back where they stood so they don't stay stuck.
TRP_ClearAnimations(playerid) {

	ClearAnimations(playerid);
	SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);

	new Float: x, Float: y, Float: z ;
	GetPlayerPos ( playerid, x, y, z ) ;
	
	PauseAC(playerid, 3);
	SetPlayerPos ( playerid, x, y, z + 0.25 ) ;

	return true ;
}

stock SendServerMessage ( playerid, color, const prefix[], const hexcolor [], const text[] ) {
// Usage: SendServerMessage(playerid, COLOR_BLUE, "Uh Oh!", "{DEDEDE}, "Your engine has broken down!");
// Returns: {blue}[Uh Oh!]{DEDEDE} Your engine has broken down!

	new string [ 512 ] ;

	format ( string, sizeof ( string ), "[%s]{%s} %s", prefix, hexcolor, text  ) ;

    return SendClientMessage(playerid, color, string ) ;
}

stock SendServerMessageToAll ( color, prefix[], hexcolor[], text[] ) {

	return SendClientMessageToAll(color, sprintf("[%s]{%s} %s", prefix, hexcolor, text ) ) ;
}

// Returns the player's IP address.
stock ReturnIP(playerid) {
	static ip[16];
	GetPlayerIp(playerid, ip, sizeof(ip));

	return ip;
}

// Clears the player's chat window by sending blank lines.
stock ClearChat(playerid) {

	for ( new i; i < 20; i ++ ) {

		SendClientMessage(playerid, 0xA3A3A3FF, " ");
	}
}


stock KickPlayer ( playerid, time = 1000 ) {

    defer DisconnectUser[time](playerid);
    
    return true;
}

// Timer: kicks a player after one second (lets a message appear first).
timer DisconnectUser[1000](playerid) {

    //print("DisconnectUser timer called (main.pwn)");

    return Kick ( playerid ) ;
}


// Returns 1 if the string only contains digits.
stock IsNumeric(const string[])
{
	for (new i = 0, j = strlen(string); i < j; i++)
	{
		if (string[i] > '9' || string[i] < '0') return 0;
	}
	return 1;
}


// Returns true if two players are within `radius` of each other (same world and interior).
IsPlayerNearPlayer(playerid, targetid, Float:radius) {
	static
		Float:fX,
		Float:fY,
		Float:fZ;

	GetPlayerPos(targetid, fX, fY, fZ);

	return GetPlayerState(targetid) != PLAYER_STATE_SPECTATING && (GetPlayerInterior(playerid) == GetPlayerInterior(targetid) && GetPlayerVirtualWorld(playerid) == GetPlayerVirtualWorld(targetid)) && IsPlayerInRangeOfPoint(playerid, radius, fX, fY, fZ);
}

// Turns a player to face another player.
stock SetPlayerToFacePlayer(playerid, targetid)
{
	new
	    Float:x[2],
	    Float:y[2],
	    Float:z[2],
	    Float:angle;

	GetPlayerPos(targetid, x[0], y[0], z[0]);
	GetPlayerPos(playerid, x[1], y[1], z[1]);

	angle = (180.0 - atan2(x[1] - x[0], y[1] - y[0]));
	SetPlayerFacingAngle(playerid, angle + (5.0 * -1));
}


ReturnDateTime ( ) {
	new date[36];

	getdate(date[2], date[1], date[0]);
	gettime(date[3], date[4], date[5]);

	format(date, sizeof(date), "%02d/%02d/%d, %02d:%02d",
	date[0], date[1], date[2], date[3], date[4]);

	return date;
}


// Writes the text name of a player state (ON FOOT, DRIVER, SPECTATING...) into status.
GetStateName(stateId, status[], len=sizeof(status)) {

	switch(stateId)
    {
        case PLAYER_STATE_ONFOOT: {
        	format ( status, len, "ON FOOT" ) ;
        }

        case PLAYER_STATE_DRIVER: {
        	format ( status, len, "DRIVER" ) ;
		}

		case PLAYER_STATE_PASSENGER: {
			format ( status, len, "PASSENGER" ) ;
		}

		case PLAYER_STATE_EXIT_VEHICLE: {
			format ( status, len, "EXIT VEHICLE" ) ;
		}

		case PLAYER_STATE_ENTER_VEHICLE_DRIVER: {
			format ( status, len, "ENTER VEHICLE DRIVER" ) ;
		}

		case PLAYER_STATE_ENTER_VEHICLE_PASSENGER: {
			format ( status, len, "ENTER VEHICLE PASSENGER" ) ;
		}

		case PLAYER_STATE_WASTED: {
			format ( status, len, "WASTED" ) ;
		}

		case PLAYER_STATE_SPAWNED: {
			format ( status, len, "SPAWNED" ) ;
		}

		case PLAYER_STATE_SPECTATING: {
			format ( status, len, "SPECTATING" ) ;
        }

        default: {
        	format ( status, len, "NONE" ) ;
 		}
    }
}

// Returns true if one player is within range of another (same interior and world).
stock IsPlayerCloseToPlayer(player_to_check, player_to_compare, Float:range)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(player_to_compare, x, y, z);

    if(IsPlayerInRangeOfPoint(player_to_check, range, x, y, z) && GetPlayerInterior(player_to_check) == GetPlayerInterior(player_to_compare) && GetPlayerVirtualWorld(player_to_check) == GetPlayerVirtualWorld(player_to_compare) && GetPlayerState(player_to_check) != PLAYER_STATE_SPECTATING && GetPlayerState(player_to_compare) != PLAYER_STATE_SPECTATING)
    {
        return 1;
    }
    return 0;
}



// Turns a player to face a point.
stock MakePlayerFacePoint(playerid, Float: fpX, Float: fpY, Float: fpZ ) {
    new Float:Px, Float:Py, Float: Pa;
    GetPlayerPos(playerid, Px, Py, Pa);
  
    Pa = floatabs(atan((fpY-Py)/(fpX-Px)));
    if(fpX <= Px && fpY >= Py) Pa = floatsub(180, Pa);
    else if(fpX < Px && fpY < Py) Pa = floatadd(Pa, 180);
    else if(fpX >= Px && fpY <= Py) Pa = floatsub(360.0, Pa);
    Pa = floatsub(Pa, 90.0);
    if(Pa >= 360.0) Pa = floatsub(Pa, 360.0);

    SetPlayerFacingAngle(playerid, Pa);
}

// Turns a player to face a vehicle.
stock MakePlayerFaceVehicle(playerid, facevehicleid ) {
    new Float:Px, Float:Py, Float: Pa;
    GetPlayerPos(playerid, Px, Py, Pa);
    new Float:fpX, Float:fpY, Float: fpZ;
    GetVehiclePos(facevehicleid, fpX, fpY, fpZ );

    Pa = floatabs(atan((fpY-Py)/(fpX-Px)));
    if(fpX <= Px && fpY >= Py) Pa = floatsub(180, Pa);
    else if(fpX < Px && fpY < Py) Pa = floatadd(Pa, 180);
    else if(fpX >= Px && fpY <= Py) Pa = floatsub(360.0, Pa);
    Pa = floatsub(Pa, 90.0);
    if(Pa >= 360.0) Pa = floatsub(Pa, 360.0);

    SetPlayerFacingAngle(playerid, Pa);
}

// Gets the position `distance` metres in front of a player (or their vehicle).
stock GetXYInFrontOfPlayer(playerid, &Float:x, &Float:y, Float:distance)
{
    new Float:a;
    GetPlayerPos(playerid, x, y, a);
    GetPlayerFacingAngle(playerid, a);
    if (GetPlayerVehicleID(playerid))
    {
      GetVehicleZAngle(GetPlayerVehicleID(playerid), a);
    }
    x += (distance * floatsin(-a, degrees));
    y += (distance * floatcos(-a, degrees));
}

// Gets the position `distance` metres to the left of a player.
GetXYLeftOfPlayer(playerid, &Float:X, &Float:Y, Float:distance) {
    new Float:Angle;
    GetPlayerFacingAngle(playerid, Angle); Angle += 90.0;
    X += floatmul(floatsin(-Angle, degrees), distance);
    Y += floatmul(floatcos(-Angle, degrees), distance);
}

// Returns true if the player is inside a rectangle (min/max X and Y).
stock bool:IsPlayerInSquare( playerid, Float:MIN_X , Float:MAX_X , Float:MIN_Y , Float:MAX_Y ) 

	// https://sa-mp-fr.com/tutorials/article/26-tutoriel-isplayerinsquare-une-d%C3%A9riv%C3%A9e-de-isplayerinarea/
{

	if( !IsPlayerConnected( playerid ) ) return false ;

	static
		Float:P_POS[ 3 ]
		;

	GetPlayerPos( playerid , P_POS[ 0 ] , P_POS[ 1 ] , P_POS[ 2 ] ) ;

	if( ( MIN_X <= P_POS[ 0 ] <= MAX_X  ) &&  ( MIN_Y <= P_POS[ 1 ] <= MAX_Y )  ) return true ;

	return false ;
}
