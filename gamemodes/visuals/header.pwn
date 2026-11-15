// ============================================================================
// File: visuals/header.pwn
// Visuals entry point: includes models, objects, building removal and maps, and holds the
// OnPlayerFinishedDownloading callback for custom model downloads.
// Commands: /drawdistance
// ============================================================================

// Add these to PLAYER_VARS enum
#include "visuals/models.pwn"
#include "visuals/objects.pwn"
#include "visuals/remove.pwn"
#include "visuals/commands.pwn"

#include "visuals/maps/header.pwn"
//#include "visuals/projectprops.pwn"



//#include "visuals/snow.pwn"
//#include "visuals/interiors/cagefight.pwn"

#include <YSI_Coding\y_hooks>

new bool: IsPlayerFinishedDownloading [ MAX_PLAYERS ] ;

/*

	Player skins use ranges: 20000 to 30000 (10000 slots)
	Objects use negative IDs: -1000 to -25000 (29000 slots)

	native AddCharModel(baseid, newid, dffname[], txdname[]);
	native AddSimpleModel(virtualworld, baseid, newid, dffname[], txdname[]);
*/

hook OnGameModeInit()
{
    // orp_redirect (RedirectDownload to the external CDN) is no longer loaded:
    // open.mp serves artwork natively through its built-in web server, and an
    // external mirror is configured via the artwork.cdn config option instead.
    return 1;
}

// Called when a player finishes downloading custom models (none in this framework).
public OnPlayerFinishedDownloading(playerid, virtualworld) {

    IsPlayerFinishedDownloading [ playerid ] = true ;

    return 1;
}

// Disabled: ApplyPlayerDrawDistance() in player/auth/spawn.pwn is a no-op, so this
// only saved a setting to the account and changed nothing. Re-enabling it means
// restoring that function with a floor high enough to render the city -- its old
// LOW tier capped players at 500 visible objects against a client pool of 1000.
/*
// /drawdistance [distance] - sets your view distance.
CMD:drawdistance(playerid, params[]) {
    if (strmatch(params, "info")) {
        new Float:mult, string[128];
        Streamer_GetRadiusMultiplier(STREAMER_TYPE_OBJECT, mult, playerid);
        format(string, sizeof(string), "Objects: %d | Multiplier: %.2fx | Setting: %d/4",
            Streamer_GetVisibleItems(STREAMER_TYPE_OBJECT, playerid),
            mult,
            Account[playerid][E_PLAYER_ACCOUNT_DDSETTING]
        );
        SendClientMessage(playerid, 0x84aa63ff, string);
        return 1;
    }

    new setting;
    if      (strmatch(params, "low"))    setting = 1;
    else if (strmatch(params, "medium")) setting = 2;
    else if (strmatch(params, "high"))   setting = 3;
    else if (strmatch(params, "ultra"))  setting = 4;
    else if (strmatch(params, "dev"))    setting = 5;
    else {
        SendClientMessage(playerid, 0xa9c4e4ff, "-> /drawdistance [LOW / MEDIUM / HIGH / ULTRA / INFO]");
        return 1;
    }

    Account[playerid][E_PLAYER_ACCOUNT_DDSETTING] = setting;
    Account[playerid][E_PLAYER_ACCOUNT_DDMESSAGE] = 1;
    SavePlayerDrawDistanceSetting(playerid);
    ApplyPlayerDrawDistance(playerid);

    new names[][] = { "", "LOW", "MEDIUM", "HIGH", "ULTRA", "DEV" };
    SendClientMessage(playerid, 0x84aa63ff, sprintf("-> Draw distance set to %s and saved to your account.", names[setting]));
    return 1;
}
*/
