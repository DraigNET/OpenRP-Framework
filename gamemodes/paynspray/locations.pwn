// ============================================================================
// File: paynspray/locations.pwn
// Garage positions for Pay 'n' Spray (E_PNS_LOCATIONS). Rows at 0,0 are ignored until you set
// coordinates for your map.
// ============================================================================

enum E_PNS_DATA
{
    Float:E_PNS_POS_X,
    Float:E_PNS_POS_Y,
    Float:E_PNS_POS_Z,
    E_PNS_NAME[32]      // shown in /gps
};

new E_PNS_LOCATIONS[][E_PNS_DATA] =
{
    // Garages: { X, Y, Z, "Name" }. A row at 0,0 is ignored everywhere.
    // TODO: set coordinates for your map
    { 0.0, 0.0, 0.0, "Garage 1" },
    { 0.0, 0.0, 0.0, "Garage 2" },
    { 0.0, 0.0, 0.0, "Garage 3" }
};

new DynamicText3D:E_PNS_LABEL[sizeof(E_PNS_LOCATIONS)];

#include <YSI_Coding\y_hooks>

forward LoadPayNSpray();
// Creates the labels and map icons for each Pay 'n' Spray garage and fills in the /gps rows.
public LoadPayNSpray()
{
    new string[128];

    for (new i, j = sizeof(E_PNS_LOCATIONS); i < j; i++)
    {
        if (E_PNS_LOCATIONS[i][E_PNS_POS_X] == 0.0 && E_PNS_LOCATIONS[i][E_PNS_POS_Y] == 0.0) continue;

        format(string, sizeof(string),
			"{2172ff}Pay'n'Spray\n" \
			"{DEDEDE}Use {ffde21}/repaircar\n" \
			"{DEDEDE}Use {ffde21}/carcolorlist {DEDEDE}for colour codes\n");

        E_PNS_LABEL[i] = CreateDynamic3DTextLabel(
            string,
            0xFFFFFFFF,
            E_PNS_LOCATIONS[i][E_PNS_POS_X],
            E_PNS_LOCATIONS[i][E_PNS_POS_Y],
            E_PNS_LOCATIONS[i][E_PNS_POS_Z] + 0.5,
            12.0,
            INVALID_PLAYER_ID,
            INVALID_VEHICLE_ID,
            true,
            0,
            0
        );

        CreateDynamicMapIcon(
            E_PNS_LOCATIONS[i][E_PNS_POS_X],
            E_PNS_LOCATIONS[i][E_PNS_POS_Y],
            E_PNS_LOCATIONS[i][E_PNS_POS_Z],
            63,
            -1
        );
        printf("Creating PNS label %d", i);
    }

    // The /gps list has spare "Pay 'N' Spray" rows (gps/data.pwn). Fill them from the real locations, in order.
    new row = 0;

    for (new g = 0, j = sizeof(GPS); g < j && row < sizeof(E_PNS_LOCATIONS); g ++)
    {
        if (strcmp(GPS[g][E_GPS_DESC], "Pay 'N' Spray", false, 13) != 0) continue;

        while (row < sizeof(E_PNS_LOCATIONS) && E_PNS_LOCATIONS[row][E_PNS_POS_X] == 0.0 && E_PNS_LOCATIONS[row][E_PNS_POS_Y] == 0.0) row ++;
        if (row >= sizeof(E_PNS_LOCATIONS)) break;

        format(GPS[g][E_GPS_DESC], 64, "Pay 'N' Spray: %s", E_PNS_LOCATIONS[row][E_PNS_NAME]);
        GPS[g][E_GPS_POS_X] = E_PNS_LOCATIONS[row][E_PNS_POS_X];
        GPS[g][E_GPS_POS_Y] = E_PNS_LOCATIONS[row][E_PNS_POS_Y];
        GPS[g][E_GPS_POS_Z] = E_PNS_LOCATIONS[row][E_PNS_POS_Z];
        row ++;
    }

    printf("[+] %i Pay'n'Spray locations loaded.", sizeof(E_PNS_LOCATIONS));
    return 1;
}

// Returns true if the player is at a Pay 'n' Spray garage.
IsPlayerNearPayNSpray(playerid)
{
    for (new i = sizeof(E_PNS_LOCATIONS) - 1; i != -1; --i)
    {
        if (E_PNS_LOCATIONS[i][E_PNS_POS_X] == 0.0 && E_PNS_LOCATIONS[i][E_PNS_POS_Y] == 0.0) continue;

        if (IsPlayerInRangeOfPoint(playerid, 15.0,
            E_PNS_LOCATIONS[i][E_PNS_POS_X],
            E_PNS_LOCATIONS[i][E_PNS_POS_Y],
            E_PNS_LOCATIONS[i][E_PNS_POS_Z]))
        {
            return true;
        }
    }
    return false;
}
