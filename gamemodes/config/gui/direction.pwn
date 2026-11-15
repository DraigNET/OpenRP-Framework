// ============================================================================
// File: config/gui/direction.pwn
// HUD compass: shows the direction a player is facing and their current address, updated while
// they walk or drive.
// ============================================================================

new PlayerText:gui_direction[MAX_PLAYERS][2] = {PlayerText:INVALID_TEXT_DRAW, ...};

// On connect: creates the compass textdraws for the player.
public OnPlayerConnect(playerid) {

    // [0] compass letter
    gui_direction[playerid][0] = CreatePlayerTextDraw(playerid, 33.0, 421.0, "~y~NE");
    PlayerTextDrawFont(playerid, gui_direction[playerid][0], 1);
    PlayerTextDrawLetterSize(playerid, gui_direction[playerid][0], 0.4, 1.0);
    PlayerTextDrawAlignment(playerid, gui_direction[playerid][0], 1);
    PlayerTextDrawColor(playerid, gui_direction[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, gui_direction[playerid][0], 0);
    PlayerTextDrawSetOutline(playerid, gui_direction[playerid][0], 1);
    PlayerTextDrawBackgroundColor(playerid, gui_direction[playerid][0], 255);
    PlayerTextDrawSetProportional(playerid, gui_direction[playerid][0], 1);
    PlayerTextDrawTextSize(playerid, gui_direction[playerid][0], 0.0, 640.0);

    // [1] Address
    gui_direction[playerid][1] = CreatePlayerTextDraw(playerid, 66.0, 424.0, "Main Street, 306");
    PlayerTextDrawFont(playerid, gui_direction[playerid][1], 2);
    PlayerTextDrawLetterSize(playerid, gui_direction[playerid][1], 0.20, 0.9);
    PlayerTextDrawAlignment(playerid, gui_direction[playerid][1], 1);
    PlayerTextDrawColor(playerid, gui_direction[playerid][1], -1378294017);
    PlayerTextDrawSetShadow(playerid, gui_direction[playerid][1], 0);
    PlayerTextDrawSetOutline(playerid, gui_direction[playerid][1], 1);
    PlayerTextDrawBackgroundColor(playerid, gui_direction[playerid][1], 255);
    PlayerTextDrawSetProportional(playerid, gui_direction[playerid][1], 1);
    PlayerTextDrawTextSize(playerid, gui_direction[playerid][1], 0.0, 640.0);

    #if defined direction_OnPlayerConnect
        return direction_OnPlayerConnect(playerid);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerConnect
    #undef OnPlayerConnect
#else
    #define _ALS_OnPlayerConnect
#endif
#define OnPlayerConnect direction_OnPlayerConnect
#if defined direction_OnPlayerConnect
    forward direction_OnPlayerConnect(playerid);
#endif

// Shows or hides the compass when the player enters or leaves a vehicle.
public OnPlayerStateChange(playerid, newstate, oldstate) {

    if(Settings_GetDirectionValue(playerid)) {
        if(newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) {
            PlayerTextDrawShow(playerid, gui_direction[playerid][0]);
            PlayerTextDrawShow(playerid, gui_direction[playerid][1]);
        }
        else if(newstate == PLAYER_STATE_ONFOOT) {
            PlayerTextDrawHide(playerid, gui_direction[playerid][0]);
            PlayerTextDrawHide(playerid, gui_direction[playerid][1]);
        }
    }

    #if defined dirct_OnPlayerStateChange
        return dirct_OnPlayerStateChange(playerid, newstate, oldstate);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerStateChange
    #undef OnPlayerStateChange
#else
    #define _ALS_OnPlayerStateChange
#endif
#define OnPlayerStateChange dirct_OnPlayerStateChange
#if defined dirct_OnPlayerStateChange
    forward dirct_OnPlayerStateChange(playerid, newstate, oldstate);
#endif

// On disconnect: destroys the compass textdraws.
public OnPlayerDisconnect(playerid, reason) {

    PlayerTextDrawDestroy(playerid, gui_direction[playerid][0]);
    PlayerTextDrawDestroy(playerid, gui_direction[playerid][1]);

    #if defined direction_OnPlayerDisconnect
        return direction_OnPlayerDisconnect(playerid, reason);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerDisconnect
    #undef OnPlayerDisconnect
#else
    #define _ALS_OnPlayerDisconnect
#endif
#define OnPlayerDisconnect direction_OnPlayerDisconnect
#if defined direction_OnPlayerDisconnect
    forward direction_OnPlayerDisconnect(playerid, reason);
#endif

// Updates the compass letters and address text from the player's position and heading.
GUI_UpdateDirectionLabels(playerid) {

    new direction_state = GetPlayerState(playerid);
    if((direction_state == PLAYER_STATE_DRIVER || direction_state == PLAYER_STATE_PASSENGER) && Settings_GetDirectionValue(playerid)) {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        new address[64];
        GetPlayerAddress(x, y, address);
        PlayerTextDrawSetString(playerid, gui_direction[playerid][1], address);

        new Float:angle;
        GetVehicleZAngle(GetPlayerVehicleID(playerid), angle);
        new result = floatround(angle);

        new index;
        switch(result) {
            case 0   .. 25:  index = 0;
            case 26  .. 65:  index = 7;
            case 66  .. 134: index = 6;
            case 135 .. 160: index = 5;
            case 161 .. 214: index = 4;
            case 215 .. 250: index = 3;
            case 251 .. 290: index = 2;
            case 291 .. 340: index = 1;
            case 341 .. 360: index = 0;
        }

        new const compass_direction[][3] = {
            "N", "NE", "E", "SE", "S", "SW", "W", "NW"
        };

        new bool:is_two_letters = (strlen(compass_direction[index]) == 2);
        new Float:td_x = is_two_letters ? 19.0 : 33.0;

        PlayerTextDrawDestroy(playerid, gui_direction[playerid][0]);
        gui_direction[playerid][0] = CreatePlayerTextDraw(playerid, td_x, 421.0, sprintf("~y~%s", compass_direction[index]));
        PlayerTextDrawFont(playerid, gui_direction[playerid][0], 1);
        PlayerTextDrawLetterSize(playerid, gui_direction[playerid][0], 0.6, 2.5);
        PlayerTextDrawAlignment(playerid, gui_direction[playerid][0], 1);
        PlayerTextDrawColor(playerid, gui_direction[playerid][0], -1);
        PlayerTextDrawSetShadow(playerid, gui_direction[playerid][0], 0);
        PlayerTextDrawSetOutline(playerid, gui_direction[playerid][0], 1);
        PlayerTextDrawBackgroundColor(playerid, gui_direction[playerid][0], 255);
        PlayerTextDrawSetProportional(playerid, gui_direction[playerid][0], 1);
        PlayerTextDrawTextSize(playerid, gui_direction[playerid][0], 0.0, 640.0);
        PlayerTextDrawShow(playerid, gui_direction[playerid][0]);
    }
    return true;
}
