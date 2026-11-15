// ============================================================================
// File: tags/scoreboard.pwn
// Name tags and the player list (tab list): UpdateNametagsTick, per-viewer colours
// (SetPlayerColorForPlayer) and renaming players for specific viewers using Pawn.RakNet.
// Commands /syncnames, /synctablist, /synccarsigns repair desyncs.
// Commands: /syncnames /synccarsigns /synctablist
// ============================================================================

#if !defined PAWNRAKNET_INC_
    #include <Pawn.RakNet>
#endif

#if !defined INVALID_FACTION_ID
    #define INVALID_FACTION_ID	( -1 )
#endif 

// Sets the name another player sees for a player in the scoreboard.
SetPlayerNameForPlayer(playerid, forplayerid, const name[]) {

    new BitStream:bs = BS_New(), size = strlen(name);

    BS_WriteValue(
        bs, 
        PR_UINT16, playerid, 
        PR_UINT8, size, 
        PR_STRING, name, 
        PR_UINT8, 1
    );

    PR_SendRPC(bs, forplayerid, 11);
    // PR_SendRPC(bs, forplayerid, 11);
    BS_Delete(bs);
    return 1;
}

// Use .force_color=true if you want to ignore checks for specific player states like aduty
// Set to true as default as it's best the function does it what you want it without any custom parameters
SetPlayerColorForPlayer(playerid, toplayerid, color, bool:force_color=true) {
    new BitStream:bs = BS_New();

    if(!force_color) {
        if(PlayerVar [playerid] [E_PLAYER_ADMIN_DUTY]) {
            color = 0xD5A04EFF;
        } else if(PlayerVar[playerid][E_PLAYER_HELPER_DUTY]) {
            color = 0x38C751FF;
        } else if(IsPlayerMasked(playerid)) {
            color = 0xDEDEDEFF;
        }
    }

    BS_WriteValue(
        bs,
        PR_UINT16, playerid,
        PR_UINT32, color
    );

    PR_SendRPC(bs, toplayerid, 72);
    // PR_SendRPC(bs, toplayerid, 72);
    BS_Delete(bs);
    return 1;
}


// Refreshes a player's tab list entry for everyone else.
UpdateTabListForOthers(playerid) {
    for(new targetid=GetMaxPlayers()-1; targetid != -1; targetid--) {

        if (!IsPlayerConnected(targetid) || !IsPlayerPlaying(targetid)) continue;
        UpdateTabList(playerid, targetid);
    }
    return true;
}


// Refreshes every other player's tab list entry for one player.
UpdateTabListForPlayer(playerid) {
    for(new targetid=GetMaxPlayers()-1; targetid != -1; targetid--) {

        if (!IsPlayerConnected(targetid)  || !IsPlayerPlaying(targetid)) continue;
        UpdateTabList(targetid, playerid);
    }

    return true ;
}

// Works out the tab list name that one player sees for another.
UpdateTabList(playerid, forplayerid)
{
    new color = 0xDEDEDEFF;

    if (!IsPlayerConnected(forplayerid) || !IsPlayerPlaying(forplayerid)) {
        return true;
    }

    new title[64];

    // Priority: Admin > Helper > RAG > Default
    if (PlayerVar[playerid][E_PLAYER_ADMIN_DUTY])
    {
        format(title, sizeof(title), "[Admin] %s", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
    }
    else if (PlayerVar[playerid][E_PLAYER_HELPER_DUTY])
    {
        format(title, sizeof(title), "[Helper] %s", Account[playerid][E_PLAYER_ACCOUNT_NAME]);
    }
    else if (Character[playerid][E_CHARACTER_RAG_ON] && GetPlayerFactionType(playerid) == FACTION_TYPE_ILLEGAL)
    {
        // IMPORTANT: use accessor, not Faction[]
        color = Faction_GetHex(Character[playerid][E_CHARACTER_FACTIONID]);
        // No title change - colour only
    }

    // Set name (title if present, otherwise normal RP name)
    SetPlayerNameForPlayer(
        playerid,
        forplayerid,
        (strlen(title) > 0)
            ? title
            : ReturnSettingsName(playerid, forplayerid, .color=false, .masked=false)
    );

    // Apply colour (admin/helper/mask precedence handled internally)
    SetPlayerColorForPlayer(playerid, forplayerid, color, .force_color=false);

    return true;
}

// Hooks
#include <YSI_Coding\y_hooks>
hook OnPlayerStreamIn(playerid, forplayerid) { 
    UpdateTabList(playerid, forplayerid);
    return 1;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid) { 
    UpdateTabListForPlayer(playerid) ;
    return 1;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerSpawn(playerid) { 
    
    SetPlayerColor(playerid, 0xDEDEDEFF);
    UpdateTabListForPlayer(playerid) ;
    UpdateTabListForOthers(playerid);
    return 1;
}

#include <YSI_Coding\y_hooks>
hook OnPlayerConnect(playerid) {
    SetPlayerColor(playerid, 0x000000FF);

    return 1;
}

// /syncnames - resyncs the names in your tab list.
CMD:syncnames(playerid) {
    if (!IsPlayerConnected(playerid) || !IsPlayerPlaying(playerid)) return false;
    UpdateTabListForPlayer(playerid);
    SendClientMessage(playerid, COLOR_YELLOW, "Your tablist has been updated.");
    printf("%d %s updated their tablist.", playerid, Account[playerid][E_PLAYER_ACCOUNT_NAME]);
    return 1;
}

// /synccarsigns - resyncs the unit car signs.
CMD:synccarsigns(playerid) {
    // Stream car signs
    if (!IsPlayerConnected(playerid) || !IsPlayerPlaying(playerid)) return false;
	Streamer_Update(playerid, STREAMER_TYPE_3D_TEXT_LABEL);
    SendClientMessage(playerid, COLOR_YELLOW, "Car signs have been updated.");
    return 1;
}

CMD:synctablist(playerid) {
    return cmd_syncnames(playerid);
}


timer UpdateTablist[120000]() { // force update every 120s

    foreach(new playerid: Player) {
        UpdateNametagsTick(playerid);
    }
    return true;

}
// Tick that updates the nametags of a player.
UpdateNametagsTick(playerid) {
    for(new targetid=GetMaxPlayers()-1; targetid != -1; targetid--) {
        if (!IsPlayerConnected(targetid) || !IsPlayerPlaying(targetid)) continue;
        UpdateTabList(playerid, targetid);
    }
    return true;
}
