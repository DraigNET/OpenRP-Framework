// ============================================================================
// File: vehicle/slots.pwn
// Player_GetMaxOwnedVehicles(): how many vehicles a player may own (raised by licences and
// premium level).
// ============================================================================


Player_GetOwnedVehicles ( playerid ) {

	new count = 0 ;

	for ( new i, j = sizeof ( Vehicle ); i < j ; i ++ ) {

		if ( Vehicle [ i ] [ E_VEHICLE_TYPE ] == E_VEHICLE_TYPE_PLAYER ) {
			if ( Vehicle [ i ] [ E_VEHICLE_OWNER ] == Character [ playerid ] [ E_CHARACTER_ID ] ) {

				count ++ ;
			}

			else continue ;
		}
	}

	return count ;
}

Player_GetMaxOwnedVehicles(playerid)
{
    new hours = Character[playerid][E_CHARACTER_HOURS];
    new max_vehicles = 2;

    if (hours >= 160) max_vehicles = 5;
    else if (hours >= 100) max_vehicles = 4;
    else if (hours >= 50)  max_vehicles = 3;

    return max_vehicles;
}