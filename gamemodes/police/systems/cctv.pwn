// ============================================================================
// File: police/systems/cctv.pwn
// CCTV viewing (/cctv, /exitcctv): lets officers in a CCTV room cycle through cameras. The CCTV
// room list is a table at the top of the file.
// Commands: /cctv /exitcctv
// ============================================================================

#include <YSI_Coding\y_hooks>

// -----------------------------------------------------------------------
// CCTV rooms - players must be inside one to use /cctv.
// Format: {X, Y, Z, radius}
// -----------------------------------------------------------------------
enum E_CCTV_ROOM { Float:E_CCTV_ROOM_X, Float:E_CCTV_ROOM_Y, Float:E_CCTV_ROOM_Z, Float:E_CCTV_ROOM_RADIUS }

static const CCTVRooms[][E_CCTV_ROOM] =
{
    {216.7004, 168.5833, 1003.0234, 10.0}   // GSPD HQ CCTV room
};

// Returns true if the player is inside a room where CCTV may be used.
static bool:IsPlayerInAnyCCTVRoom(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for (new i, j = sizeof(CCTVRooms); i < j; i++)
    {
        new Float:dx = px - CCTVRooms[i][E_CCTV_ROOM_X];
        new Float:dy = py - CCTVRooms[i][E_CCTV_ROOM_Y];
        new Float:dz = pz - CCTVRooms[i][E_CCTV_ROOM_Z];
        if (floatsqroot(dx*dx + dy*dy + dz*dz) <= CCTVRooms[i][E_CCTV_ROOM_RADIUS])
            return true;
    }
    return false;
}

#define CCTV_KEY_INTERVAL   (100)       // ms between rotation steps
#define CCTV_RADIUS_MIN     (1.0)
#define CCTV_RADIUS_MAX     (25.0)
#define CCTV_SPEED_NORMAL   (0.5)
#define CCTV_SPEED_SPRINT   (2.0)
#define CCTV_ZOOM_NORMAL    (0.1)
#define CCTV_ZOOM_SPRINT    (0.5)

enum E_CCTV_CAMERA
{
    E_CCTV_NAME[32],
    Float: E_CCTV_POS_X,
    Float: E_CCTV_POS_Y,
    Float: E_CCTV_POS_Z,
    Float: E_CCTV_LOOK_X,
    Float: E_CCTV_LOOK_Y,
    Float: E_CCTV_LOOK_Z,
    E_CCTV_INTERIOR,
    E_CCTV_WORLD
}

// -----------------------------------------------------------------------
// Add camera entries below. Copy SetPlayerCameraPos / SetPlayerCameraLookAt
// coords directly - degree and radius are derived automatically.
// Format: {"Name", posX, posY, posZ, lookX, lookY, lookZ, interior, world}
// -----------------------------------------------------------------------
static const CCTVCameras[][E_CCTV_CAMERA] =
{
    {"City Hall Entrance", 1441.9768, -1737.8817, 18.7326,
                        1442.9108, -1738.2671, 18.7026, 0, 0}
};
#define MAX_CCTV_CAMERAS (sizeof(CCTVCameras))

// -----------------------------------------------------------------------
// Per-player state
// -----------------------------------------------------------------------
static CurrentCCTV[MAX_PLAYERS]         = { -1, ... };
static Float:CCTVDegree[MAX_PLAYERS];
static Float:CCTVRadius[MAX_PLAYERS];
static Float:CCTVLookZ[MAX_PLAYERS];
static CCTVPrevWorld[MAX_PLAYERS];
static CCTVPrevInterior[MAX_PLAYERS];
static Float:CCTVPrevX[MAX_PLAYERS];
static Float:CCTVPrevY[MAX_PLAYERS];
static Float:CCTVPrevZ[MAX_PLAYERS];
static bool:CCTVNeedsRestore[MAX_PLAYERS];
static CCTVLastKeyTick[MAX_PLAYERS];

// -----------------------------------------------------------------------
// Internal helpers
// -----------------------------------------------------------------------
static CCTV_UpdateCamera(playerid)
{
    new cam = CurrentCCTV[playerid];
    new Float:lx = CCTVCameras[cam][E_CCTV_POS_X] + CCTVRadius[playerid] * floatsin(-CCTVDegree[playerid], degrees);
    new Float:ly = CCTVCameras[cam][E_CCTV_POS_Y] + CCTVRadius[playerid] * floatcos(-CCTVDegree[playerid], degrees);
    SetPlayerCameraLookAt(playerid, lx, ly, CCTVLookZ[playerid], CAMERA_CUT);
}

// Starts viewing a CCTV camera.
static CCTV_Enter(playerid, camidx)
{
    new Float:dx = CCTVCameras[camidx][E_CCTV_LOOK_X] - CCTVCameras[camidx][E_CCTV_POS_X];
    new Float:dy = CCTVCameras[camidx][E_CCTV_LOOK_Y] - CCTVCameras[camidx][E_CCTV_POS_Y];

    CCTVRadius[playerid] = floatsqroot(dx * dx + dy * dy);
    CCTVDegree[playerid] = -(atan2(dx, dy) * (180.0 / 3.14159265));
    if (CCTVDegree[playerid] < 0.0)    CCTVDegree[playerid] += 360.0;
    if (CCTVDegree[playerid] >= 360.0) CCTVDegree[playerid] -= 360.0;

    CCTVLookZ[playerid]        = CCTVCameras[camidx][E_CCTV_LOOK_Z];
    CurrentCCTV[playerid]      = camidx;
    CCTVLastKeyTick[playerid]  = GetTickCount();
    CCTVPrevWorld[playerid]    = GetPlayerVirtualWorld(playerid);
    CCTVPrevInterior[playerid] = GetPlayerInterior(playerid);
    GetPlayerPos(playerid, CCTVPrevX[playerid], CCTVPrevY[playerid], CCTVPrevZ[playerid]);

    SetPlayerVirtualWorld(playerid, CCTVCameras[camidx][E_CCTV_WORLD]);
    SetPlayerInterior(playerid, CCTVCameras[camidx][E_CCTV_INTERIOR]);

    // Spectating mode streams objects based on camera location, not player body.
    TogglePlayerSpectating(playerid, true);

    SetPlayerCameraPos(playerid,
        CCTVCameras[camidx][E_CCTV_POS_X],
        CCTVCameras[camidx][E_CCTV_POS_Y],
        CCTVCameras[camidx][E_CCTV_POS_Z]);
    CCTV_UpdateCamera(playerid);

    new msg[64];
    format(msg, sizeof(msg), "~w~CCTV: ~g~%s ~w~| ~y~[C] ~w~to exit", CCTVCameras[camidx][E_CCTV_NAME]);
    GameTextForPlayer(playerid, msg, 3000, 3);
}

// Stops viewing CCTV and restores the player's camera.
CCTV_Exit(playerid)
{
    if (CurrentCCTV[playerid] == -1) return;

    CurrentCCTV[playerid]      = -1;
    CCTVNeedsRestore[playerid] = true;
    TogglePlayerSpectating(playerid, false);
    GameTextForPlayer(playerid, "~w~CCTV ~r~offline", 2000, 3);
}

// -----------------------------------------------------------------------
// OnPlayerUpdate - re-asserts camera every tick (fights spectating system)
// and handles key input at CCTV_KEY_INTERVAL throttle.
// -----------------------------------------------------------------------
hook OnPlayerUpdate(playerid)
{
    if (CCTVNeedsRestore[playerid])
    {
        CCTVNeedsRestore[playerid] = false;
        SetPlayerVirtualWorld(playerid, CCTVPrevWorld[playerid]);
        SetPlayerInterior(playerid, CCTVPrevInterior[playerid]);
        SetPlayerPos(playerid, CCTVPrevX[playerid], CCTVPrevY[playerid], CCTVPrevZ[playerid]);
        SetCameraBehindPlayer(playerid);
        TogglePlayerControllable(playerid, true);
        return 1;
    }

    if (CurrentCCTV[playerid] == -1) return 1;

    new cam = CurrentCCTV[playerid];

    // Always re-assert camera position so spectating can't override it.
    SetPlayerCameraPos(playerid,
        CCTVCameras[cam][E_CCTV_POS_X],
        CCTVCameras[cam][E_CCTV_POS_Y],
        CCTVCameras[cam][E_CCTV_POS_Z]);
    CCTV_UpdateCamera(playerid);

    // Throttle key handling.
    new tick = GetTickCount();
    if (tick - CCTVLastKeyTick[playerid] < CCTV_KEY_INTERVAL) return 0;
    CCTVLastKeyTick[playerid] = tick;

    new keys, ud, lr;
    GetPlayerKeys(playerid, keys, ud, lr);

    if ((keys & KEY_CROUCH) == KEY_CROUCH)
    {
        CCTV_Exit(playerid);
        return 0;
    }

    new bool:sprint = ((keys & KEY_SPRINT) == KEY_SPRINT);

    if (lr > 0)
    {
        CCTVDegree[playerid] -= sprint ? CCTV_SPEED_SPRINT : CCTV_SPEED_NORMAL;
        if (CCTVDegree[playerid] < 0.0) CCTVDegree[playerid] += 360.0;
    }
    else if (lr < 0)
    {
        CCTVDegree[playerid] += sprint ? CCTV_SPEED_SPRINT : CCTV_SPEED_NORMAL;
        if (CCTVDegree[playerid] >= 360.0) CCTVDegree[playerid] -= 360.0;
    }

    if (ud < 0)
    {
        new Float:step = sprint ? CCTV_ZOOM_SPRINT : CCTV_ZOOM_NORMAL;
        if (CCTVRadius[playerid] + step <= CCTV_RADIUS_MAX)
            CCTVRadius[playerid] += step;
    }
    else if (ud > 0)
    {
        new Float:step = sprint ? CCTV_ZOOM_SPRINT : CCTV_ZOOM_NORMAL;
        if (CCTVRadius[playerid] - step >= CCTV_RADIUS_MIN)
            CCTVRadius[playerid] -= step;
    }

    return 0;
}

// -----------------------------------------------------------------------
// Commands
// -----------------------------------------------------------------------
CMD:cctv(playerid, params[])
{
    if (!IsPlayerInLEAFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "CCTV", "A3A3A3", "You must be on duty as law enforcement to use CCTV.");

    if (!IsPlayerInAnyCCTVRoom(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "CCTV", "A3A3A3", "You must be inside the CCTV room to access this.");

    if (CurrentCCTV[playerid] != -1)
        return SendServerMessage(playerid, COLOR_ERROR, "CCTV", "A3A3A3", "You are already viewing a CCTV camera. Use /exitcctv first.");

    new list[MAX_CCTV_CAMERAS * 36], entry[36];
    for (new i; i < MAX_CCTV_CAMERAS; i++)
    {
        format(entry, sizeof(entry), "%s\n", CCTVCameras[i][E_CCTV_NAME]);
        strcat(list, entry, sizeof(list));
    }

    inline OnCCTVSelect(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, inputtext
        if (!response) return 1;
        CCTV_Enter(playerid, listitem);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnCCTVSelect, DIALOG_STYLE_LIST,
        "CCTV Cameras", list, "View", "Cancel");
    return 1;
}

// /exitcctv - leaves the CCTV view.
CMD:exitcctv(playerid, params[])
{
    #pragma unused params
    if (CurrentCCTV[playerid] == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "CCTV", "A3A3A3", "You are not currently viewing any CCTV camera.");

    CCTV_Exit(playerid);
    return 1;
}

// -----------------------------------------------------------------------
// Cleanup on disconnect
// -----------------------------------------------------------------------
hook OnPlayerDisconnect(playerid, reason)
{
    if (CurrentCCTV[playerid] != -1) CCTV_Exit(playerid);
    return 1;
}
