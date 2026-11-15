// ============================================================================
// File: config/gui/minigame_result.pwn
// End-of-minigame result screen (ShowPlayerMinigameResult) showing the placement and any prize.
// ============================================================================

static PlayerText:mgTextDrawRes[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};
static PlayerText:mgTextDrawPrice[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};

forward ORP_ShowPlayerMinigameResult(playerid, text[], price, duration);
// Public wrapper so other scripts can show a minigame result.
public ORP_ShowPlayerMinigameResult(playerid, text[], price, duration)
{
    ShowPlayerMinigameResult(playerid, text, price, duration);
    return 1;
}
// Shows the minigame result screen with a message and a prize amount.
ShowPlayerMinigameResult(playerid, const text[], price, showtime = 0)
{
    new pricemsg[128];
    format(pricemsg, sizeof(pricemsg), "$%d", price);

    if (mgTextDrawRes[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawSetString(playerid, mgTextDrawRes[playerid], text);
        return 1;
    }

    mgTextDrawRes[playerid] = CreatePlayerTextDraw(playerid, 323.0, 165.0, text);
    PlayerTextDrawFont(playerid, mgTextDrawRes[playerid], 3); 
    PlayerTextDrawLetterSize(playerid, mgTextDrawRes[playerid], 1.18, 3.25);
    PlayerTextDrawColor(playerid, mgTextDrawRes[playerid], 0xBEB314FF);
    PlayerTextDrawSetOutline(playerid, mgTextDrawRes[playerid], 1);
    PlayerTextDrawAlignment(playerid, mgTextDrawRes[playerid], 2);
    PlayerTextDrawSetProportional(playerid, mgTextDrawRes[playerid], 1);
    PlayerTextDrawShow(playerid, mgTextDrawRes[playerid]);    

    // ##always create price textdraw, but only set text and show if price > 0
    mgTextDrawPrice[playerid] = CreatePlayerTextDraw(playerid, 323.0, 193.0, pricemsg);
    PlayerTextDrawFont(playerid, mgTextDrawPrice[playerid], 3);
    PlayerTextDrawLetterSize(playerid, mgTextDrawPrice[playerid], 0.87, 3.04);
    PlayerTextDrawColor(playerid, mgTextDrawPrice[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetOutline(playerid, mgTextDrawPrice[playerid], 1);
    PlayerTextDrawAlignment(playerid, mgTextDrawPrice[playerid], 2);
    PlayerTextDrawSetProportional(playerid, mgTextDrawPrice[playerid], 1);

    if (price > 0)
    {
        PlayerTextDrawSetString(playerid, mgTextDrawPrice[playerid], pricemsg);
        PlayerTextDrawShow(playerid, mgTextDrawPrice[playerid]);
    }
    else
    {
        // ##for 0 price, set to an empty string but still create the textdraw
        PlayerTextDrawSetString(playerid, mgTextDrawPrice[playerid], " ");
        PlayerTextDrawShow(playerid, mgTextDrawPrice[playerid]);
    }

    if (showtime > 0)
    {
        defer HidePlayerMinigameResult[showtime](playerid);
    }

    return 1;
}

// Timer: hides the minigame result screen.
timer HidePlayerMinigameResult[5000](playerid)
{
    if(mgTextDrawRes[playerid] == PlayerText:INVALID_TEXT_DRAW)
        return 1;

    if(mgTextDrawPrice[playerid] == PlayerText:INVALID_TEXT_DRAW)
        return 1;

    PlayerTextDrawDestroy(playerid, mgTextDrawRes[playerid]);
    PlayerTextDrawDestroy(playerid, mgTextDrawPrice[playerid]);
    mgTextDrawRes[playerid] = PlayerText:INVALID_TEXT_DRAW;
    mgTextDrawPrice[playerid] = PlayerText:INVALID_TEXT_DRAW;

    return 1;
}

// On disconnect: destroys the result textdraws.
public OnPlayerDisconnect(playerid, reason)
{
    if (mgTextDrawRes[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, mgTextDrawRes[playerid]);
        mgTextDrawRes[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }

    if (mgTextDrawPrice[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, mgTextDrawPrice[playerid]);
        mgTextDrawPrice[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }

    #if defined mgresult_OnPlayerDisconnect
        return mgresult_OnPlayerDisconnect(playerid, reason);
    #else
        return 1;
    #endif
}
#if defined _ALS_OnPlayerDisconnect
    #undef OnPlayerDisconnect
#else
    #define _ALS_OnPlayerDisconnect
#endif

#define OnPlayerDisconnect mgresult_OnPlayerDisconnect
#if defined mgresult_OnPlayerDisconnect
    forward mgresult_OnPlayerDisconnect(playerid, reason);
#endif
