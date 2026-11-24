// ============================================================================
// File: config/header.pwn
// Core configuration included by the gamemode. Defines the server name/website/discord
// defaults, feature flags (FEATURE_* switches for optional systems), streamer priorities and
// shared helper functions (cooldown formatting, unix date strings, GetTickDiff). Includes the
// other config modules in order.
// ============================================================================

#include "config/includes.pwn"

new TEST_SERVER = 0;

// Keep stock graffiti unless your own map or tagging system replaces it.
#define FEATURE_REMOVE_STOCK_GRAFFITI (0)

// Linking Discord is optional; never block a fresh installation on an unconfigured integration.
#define FEATURE_REQUIRE_DISCORD_VERIFIED (0)

// Optional ACP uploads. Keep disabled for a stock-only blank framework.
#if !defined FEATURE_CUSTOM_SKINS
    #define FEATURE_CUSTOM_SKINS (0)
#endif

// Streamer priorities. Higher survives eviction when the object budget is full.
// filterscripts/vice_city.pwn maps the world at 1..6 (2dfx 1 -> landmasses 6), so
// anything a player interacts with must outrank the map or it silently vanishes in
// dense areas. Plain decoration stays at the default 0 and is culled first.
#define STREAM_PRIORITY_INTERACTABLE  (100)

// Optional systems. Uncomment a define to compile that system back in; left commented
// it is excluded entirely (no commands, no DB loads, no timers, no paycheck lines).
// FEATURE_FNR keeps stub functions so callers (jobs, robbery etc.) still compile, they just do nothing.
//#define FEATURE_EMMET        // Emmet gun dealers (gamemodes/emmet)
//#define FEATURE_FNR          // Fear & Respect points/levels, /giverespect, /fnrstats...
//#define FEATURE_GANGZONES    // Turf zones + drug NPCs (gamemodes/gangzones)
//#define FEATURE_GANGTAGS     // Gang spray tags: static world tags + custom-model "Dynamic Tags" + static tag models (custom-text tags stay on)

#if !defined SERVER_MODE
	#define SERVER_MODE       		"OpenRP Framework v0.1.0"
#endif

#if !defined SERVER_MAP
	#define SERVER_MAP		    	"San Andreas"
#endif

#if !defined SERVER_NAME 
	#define SERVER_NAME 			"OpenRP Framework"
#endif

#if !defined SERVER_WEBSITE
	#define SERVER_WEBSITE	    	"example.com"
#endif

#if !defined SERVER_DISCORD
	#define SERVER_DISCORD	    	"discord.gg/your-invite"
#endif

#if !defined SERVER_VEH_RENT_FEE
	#define SERVER_VEH_RENT_FEE (Runtime_Int(RT_VEHICLES_RENTAL_FEE)) // Cached database setting; edit through ACP.
#endif 

#if !defined SERVER_DMV_FEE
	#define SERVER_DMV_FEE (Runtime_Int(RT_DMV_FEE)) // Cached database setting; edit through ACP.
#endif

#if !defined SERVER_MAX_NAME_UNDERSCORES
	#define SERVER_MAX_NAME_UNDERSCORES	(2)
#endif

#define Distance3D(%1,%2,%3,%4,%5,%6) (floatsqroot(floatpower(%4-(%1),2)+floatpower(%5-(%2),2)+floatpower(%6-(%3),2)))

#include "config/data/header.pwn"
#include "config/utils/header.pwn"
#include "config/gui/header.pwn"


#include "config/fader.pwn"
#include "config/commands.pwn"
#include "config/main.pwn"

#include "config/modelconstants.pwn"
#include "config/colors.pwn"
#include "misc/missions.pwn"

// Returns the player's SA-MP name.
stock GetPlayerNameEx(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, MAX_PLAYER_NAME);
    return name;
}

// Returns the difference between two GetTickCount values, handling the counter wrapping around.
stock GetTickDiff(newtick, oldtick)
{
	if (oldtick < 0 && newtick >= 0) {
		return newtick - oldtick;
	} else if (oldtick >= 0 && newtick < 0 || oldtick > newtick) {
		return (cellmax - oldtick + 1) - (cellmin - newtick);
	}
	return newtick - oldtick;
}

// Turns seconds into readable text such as '1h 5m 3s'.
stock FormatCooldownTime(seconds, output[], maxlen) {
    new hours = seconds / 3600;
    new minutes = (seconds % 3600) / 60;
    new secs = seconds % 60;
    
    if (hours > 0) {
        format(output, maxlen, "%dh %dm %ds", hours, minutes, secs);
    } else if (minutes > 0) {
        format(output, maxlen, "%dm %ds", minutes, secs);
    } else {
        format(output, maxlen, "%ds", secs);
    }
}

// convert a Unix timestamp to dd/mm/yyyy string to replace getdate
stock UnixToDateStr(timestamp, output[], maxlen)
{
    new days  = timestamp / 86400;
    new year  = 1970;
    new month, day;

    while (days >= 365)
    {
        new yd = ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) ? 366 : 365;
        if (days < yd) break;
        days -= yd;
        year++;
    }

    new mdays[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0)
        mdays[1] = 29;

    for (month = 0; month < 12; month++)
    {
        if (days < mdays[month]) break;
        days -= mdays[month];
    }

    day = days + 1;
    month++;

    format(output, maxlen, "%02d/%02d/%04d", day, month, year);
}
