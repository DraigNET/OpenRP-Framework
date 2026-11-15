// ============================================================================
// File: config/gui/info_box.pwn
// On-screen information boxes: ShowPlayerInfoMessage() for hints and notifications, plus the
// /wristwatch time display that updates every in-game minute.
// Commands: /wristwatch
// ============================================================================

static bool:gWristwatchActive[MAX_PLAYERS] = {false, ...};
static PlayerText:gWristwatchTD[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};
static PlayerText:gplTextDraw[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};
new PlayerText:info_text[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};

forward OnIngameMinuteChange();

// Adds 'st', 'nd', 'rd' or 'th' to a day-of-month number.
stock OrdinalSuffix(day, out[], len)
{
    if(day >= 11 && day <= 13) { strcat(out, "th", len); return; }
    switch(day % 10) { case 1: strcat(out, "st", len); case 2: strcat(out, "nd", len); case 3: strcat(out, "rd", len); default: strcat(out, "th", len); }
}

// Adds AM or PM for an hour.
stock TimeSuffix(hours, out[], len)
{
    strcat(out, (hours >= 12) ? ("PM") : ("AM"), len);
}

// Builds the text shown on the wristwatch.
static BuildWristwatchStr(str[], len)
{
    new suf[4], clock[4];
    OrdinalSuffix(Server[E_SERVER_TIME_DAYS], suf, sizeof(suf));
    TimeSuffix(Server[E_SERVER_TIME_HOURS], clock, sizeof(clock));
    format(str, len, "~y~%02d:%02d %s   ~w~%s~n~~w~%d of %s%s %d", Server[E_SERVER_TIME_HOURS], Server[E_SERVER_TIME_MINUTES], clock, (Server[E_SERVER_TIME_HOURS] >= 6 && Server[E_SERVER_TIME_HOURS] < 20) ? ("DAY") : ("NIGHT"), Server[E_SERVER_TIME_DAYS], monthArray[Server[E_SERVER_TIME_MONTHS]][month_name], suf, Server[E_SERVER_TIME_YEARS]);
}
// Creates a player's wristwatch textdraw.
static CreateWristwatchTD(playerid)
{
    new str[64];
    BuildWristwatchStr(str, sizeof(str));
    if(gWristwatchTD[playerid] != PlayerText:INVALID_TEXT_DRAW) { PlayerTextDrawSetString(playerid, gWristwatchTD[playerid], str); return; }
    gWristwatchTD[playerid] = CreatePlayerTextDraw(playerid, 150.0, 380.0, str);
    PlayerTextDrawFont(playerid, gWristwatchTD[playerid], 1);
    PlayerTextDrawLetterSize(playerid, gWristwatchTD[playerid], 0.28, 1.20);
    PlayerTextDrawAlignment(playerid, gWristwatchTD[playerid], 2);
    PlayerTextDrawColor(playerid, gWristwatchTD[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetOutline(playerid, gWristwatchTD[playerid], 1);
    PlayerTextDrawSetShadow(playerid, gWristwatchTD[playerid], 0);
    PlayerTextDrawSetProportional(playerid, gWristwatchTD[playerid], 1);
    //PlayerTextDrawUseBox(playerid, gWristwatchTD[playerid], 1);
    PlayerTextDrawBoxColor(playerid, gWristwatchTD[playerid], 0x00000066);
    PlayerTextDrawTextSize(playerid, gWristwatchTD[playerid], 0.0, 140.0);
    PlayerTextDrawShow(playerid, gWristwatchTD[playerid]);
}

// Destroys a player's wristwatch textdraw.
static DestroyWristwatchTD(playerid)
{
    if(gWristwatchTD[playerid] == PlayerText:INVALID_TEXT_DRAW) return;
    PlayerTextDrawDestroy(playerid, gWristwatchTD[playerid]);
    gWristwatchTD[playerid] = PlayerText:INVALID_TEXT_DRAW;
}

// /wristwatch - toggles the in-game clock on your screen.
CMD:wristwatch(playerid, params[])
{
    if(!gWristwatchActive[playerid]) { gWristwatchActive[playerid] = true; CreateWristwatchTD(playerid); SendClientMessage(playerid, 0xFFFFFFAA, "» Wristwatch on."); }
    else { gWristwatchActive[playerid] = false; DestroyWristwatchTD(playerid); SendClientMessage(playerid, 0xFFFFFFAA, "» Wristwatch off."); }
    return 1;
}

// called from HandleIngameTime every minute tick
public OnIngameMinuteChange()
{
    new str[64];
    BuildWristwatchStr(str, sizeof(str));
    foreach(new playerid: Player) { if(gWristwatchActive[playerid] && gWristwatchTD[playerid] != PlayerText:INVALID_TEXT_DRAW) PlayerTextDrawSetString(playerid, gWristwatchTD[playerid], str); }
    return 1;
}

// Shows a message box on the left of the screen (hints and notifications) for showtime
// milliseconds.
ShowPlayerInfoMessage(playerid, const message[], showtime = 0, Float:height = 250.0, Float:width = 172.0)
{
    if(gplTextDraw[playerid] != PlayerText:INVALID_TEXT_DRAW) { PlayerTextDrawSetString(playerid, gplTextDraw[playerid], message); return 1; }
    gplTextDraw[playerid] = CreatePlayerTextDraw(playerid, 20.0, height, message);
    PlayerTextDrawBackgroundColor(playerid, gplTextDraw[playerid], -256);
    PlayerTextDrawFont(playerid, gplTextDraw[playerid], 1);
    PlayerTextDrawLetterSize(playerid, gplTextDraw[playerid], 0.38, 1.57);
    PlayerTextDrawColor(playerid, gplTextDraw[playerid], -858993409);
    PlayerTextDrawSetOutline(playerid, gplTextDraw[playerid], 1);
    PlayerTextDrawSetProportional(playerid, gplTextDraw[playerid], 1);
    PlayerTextDrawUseBox(playerid, gplTextDraw[playerid], 1);
    PlayerTextDrawBoxColor(playerid, gplTextDraw[playerid], 0x000000AA);
    PlayerTextDrawTextSize(playerid, gplTextDraw[playerid], width, -3.0);
    PlayerTextDrawShow(playerid, gplTextDraw[playerid]);
    if(showtime > 0) defer HidePlayerInfoMessage[showtime](playerid);
    return 1;
}

// Timer: hides the info message box.
timer HidePlayerInfoMessage[5000](playerid)
{
    if(gplTextDraw[playerid] == PlayerText:INVALID_TEXT_DRAW) return 1;
    PlayerTextDrawDestroy(playerid, gplTextDraw[playerid]);
    gplTextDraw[playerid] = PlayerText:INVALID_TEXT_DRAW;
    return 1;
}

// Shows a big information text on screen for showtime milliseconds.
stock ShowInfoText(playerid, const message[], showtime = 0, Float:height = 320.0, Float:width = 387.0)
{
    if(info_text[playerid] != PlayerText:INVALID_TEXT_DRAW) { PlayerTextDrawDestroy(playerid, info_text[playerid]); info_text[playerid] = PlayerText:INVALID_TEXT_DRAW; }
    info_text[playerid] = CreatePlayerTextDraw(playerid, width, height, message);
    PlayerTextDrawFont(playerid, info_text[playerid], 1);
    PlayerTextDrawLetterSize(playerid, info_text[playerid], 0.35, 1.40);
    PlayerTextDrawAlignment(playerid, info_text[playerid], 2);
    PlayerTextDrawColor(playerid, info_text[playerid], -1);
    PlayerTextDrawSetShadow(playerid, info_text[playerid], 0);
    PlayerTextDrawSetOutline(playerid, info_text[playerid], 1);
    PlayerTextDrawBackgroundColor(playerid, info_text[playerid], 255);
    PlayerTextDrawSetProportional(playerid, info_text[playerid], 1);
    PlayerTextDrawTextSize(playerid, info_text[playerid], 0.0, 500.0);
    PlayerTextDrawShow(playerid, info_text[playerid]);
    if(showtime > 0) defer HideInfoText[showtime](playerid);
    return 1;
}

forward HideInfoBox(playerid);
// Hides the information box immediately.
public HideInfoBox(playerid)
{
    if(info_text[playerid] == PlayerText:INVALID_TEXT_DRAW) return;
    PlayerTextDrawHide(playerid, info_text[playerid]);
    PlayerTextDrawSetString(playerid, info_text[playerid], "_");
}

// Timer: hides the information text.
timer HideInfoText[5000](playerid)
{
    if(info_text[playerid] == PlayerText:INVALID_TEXT_DRAW) return 1;
    PlayerTextDrawDestroy(playerid, info_text[playerid]);
    info_text[playerid] = PlayerText:INVALID_TEXT_DRAW;
    return 1;
}

// On disconnect: clears the info box and wristwatch state.
public OnPlayerDisconnect(playerid, reason)
{
    if(gplTextDraw[playerid] != PlayerText:INVALID_TEXT_DRAW) gplTextDraw[playerid] = PlayerText:INVALID_TEXT_DRAW;
    if(info_text[playerid] != PlayerText:INVALID_TEXT_DRAW) info_text[playerid] = PlayerText:INVALID_TEXT_DRAW;
    gWristwatchActive[playerid] = false;
    DestroyWristwatchTD(playerid);
    #if defined infogui_OnPlayerDisconnect
        return infogui_OnPlayerDisconnect(playerid, reason);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerDisconnect
    #undef OnPlayerDisconnect
#else
    #define _ALS_OnPlayerDisconnect
#endif
#define OnPlayerDisconnect infogui_OnPlayerDisconnect
#if defined infogui_OnPlayerDisconnect
    forward infogui_OnPlayerDisconnect(playerid, reason);
#endif

// On connect: resets the info box and wristwatch state.
public OnPlayerConnect(playerid)
{
    gWristwatchActive[playerid] = false;
    gWristwatchTD[playerid] = PlayerText:INVALID_TEXT_DRAW;
    #if defined infogui_OnPlayerConnect
        return infogui_OnPlayerConnect(playerid);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerConnect
    #undef OnPlayerConnect
#else
    #define _ALS_OnPlayerConnect
#endif
#define OnPlayerConnect infogui_OnPlayerConnect
#if defined infogui_OnPlayerConnect
    forward infogui_OnPlayerConnect(playerid);
#endif
