// ============================================================================
// File: config/time_weather.pwn
// Server clock and weather. Advances in-game time, picks weather by season, and gives each
// player the time/weather of the property interior they are inside. Provides /settime,
// /setweather and /timeinfo for admins.
// Commands: /settime /setweather /timeinfo
// ============================================================================

#include <YSI_Coding\y_hooks>

#define TIME_UPDATE_INTERVAL    8000    // 4.5 seconds
#define WEATHER_CHANGE_CHANCE   5      // 15% chance per hour
#define MAX_WEATHER_ID          20      
#define HEADLIGHT_REMINDER_HOUR 20      // Hour to remind about headlights

enum WEATHER_IDS {
    EXTRASUNNY_LA = 0,
    SUNNY_LA,
    EXTRASUNNY_SMOG_LA,
    SUNNY_SMOG_LA,
    CLOUDY_LA,
    SUNNY_SF,
    EXTRASUNNY_SF,
    CLOUDY_SF,
    RAINY_SF,
    FOGGY_SF,
    SUNNY_VEGAS,
    EXTRASUNNY_VEGAS,
    CLOUDY_VEGAS,
    EXTRASUNNY_COUNTRYSIDE,
    SUNNY_COUNTRYSIDE,
    CLOUDY_COUNTRYSIDE,
    RAINY_COUNTRYSIDE,
    EXTRASUNNY_DESERT,
    SUNNY_DESERT,
    SANDSTORM_DESERT,
    UNDERWATER
}

static const WEATHER_IDS:SunsetWeather[] = {
    SUNNY_LA, SUNNY_LA, SUNNY_LA, 
    SUNNY_COUNTRYSIDE, SUNNY_COUNTRYSIDE, 
    EXTRASUNNY_LA, EXTRASUNNY_COUNTRYSIDE,
    EXTRASUNNY_SF, SUNNY_VEGAS,
    CLOUDY_LA, SUNNY_SMOG_LA,
    CLOUDY_COUNTRYSIDE, CLOUDY_SF
};

/* COMMENTED OUT - OLD IRL RELIANCE ONE
static const WEATHER_IDS:SummerWeather[] = {
    SUNNY_LA, SUNNY_LA, SUNNY_LA, 
    SUNNY_COUNTRYSIDE, SUNNY_COUNTRYSIDE, 
    EXTRASUNNY_LA, EXTRASUNNY_COUNTRYSIDE,
    EXTRASUNNY_SF, SUNNY_VEGAS
};

static const WEATHER_IDS:SpringWeather[] = {
    SUNNY_LA, SUNNY_LA, CLOUDY_LA, 
    SUNNY_COUNTRYSIDE, CLOUDY_COUNTRYSIDE, 
    EXTRASUNNY_LA, CLOUDY_SF
};

static const WEATHER_IDS:AutumnWeather[] = {
    CLOUDY_LA, SUNNY_LA, SUNNY_SMOG_LA, 
    CLOUDY_COUNTRYSIDE, FOGGY_SF, 
    SUNNY_COUNTRYSIDE, RAINY_SF
};

static const WEATHER_IDS:WinterWeather[] = {
    CLOUDY_LA, CLOUDY_LA, FOGGY_SF, 
    CLOUDY_COUNTRYSIDE, SUNNY_LA,
    RAINY_SF, RAINY_COUNTRYSIDE
};
*/

enum MONTH_DATA {
    month_days,
    month_name[12]
}

static const monthArray[][MONTH_DATA] = {
    {31, "January"},   {28, "February"},  {31, "March"},
    {30, "April"},     {31, "May"},       {30, "June"},
    {31, "July"},      {31, "August"},    {30, "September"},
    {31, "October"},   {30, "November"},  {31, "December"}
};

// Returns true if the weather id is valid.
stock bool:IsValidWeatherID(weatherid) {
    return (0 <= weatherid <= MAX_WEATHER_ID);
}

// Returns true if the hour is 0-23.
stock bool:IsValidHour(hour) {
    return (0 <= hour <= 23);
}

// Returns true if the minute is 0-59.
stock bool:IsValidMinute(minute) {
    return (0 <= minute <= 59);
}

// Picks a random weather type appropriate for the time of year.
stock GetSeasonalWeather() {
    return _:SunsetWeather[random(sizeof(SunsetWeather))];
    
    /*
    new month = Server[E_SERVER_TIME_MONTHS];
    new weather;
    
    switch(month) {
        case 0, 1, 2: { 
            weather = _:SpringWeather[random(sizeof(SpringWeather))];
        }
        case 3, 4, 5: { 
            weather = _:SummerWeather[random(sizeof(SummerWeather))];
        }
        case 6, 7, 8: { 
            weather = _:AutumnWeather[random(sizeof(AutumnWeather))];
        }
        case 9, 10, 11: { 
            weather = _:WinterWeather[random(sizeof(WinterWeather))];
        }
        default: { // Fallback to spring
            weather = _:SpringWeather[random(sizeof(SpringWeather))];
        }
    }
    return weather;
    */
}

// Rebuilds the HH:MM text from the server clock.
stock UpdateTimeString() {
    new string[16];
    format(string, sizeof(string), "%02d:%02d", 
           Server[E_SERVER_TIME_HOURS], 
           Server[E_SERVER_TIME_MINUTES]);
    
    // Update global HUD
    TextDrawSetString(hud_time, string);
    
    foreach(new playerid: Player) {
        if(!IsPlayerLogged(playerid) || !IsPlayerSpawned(playerid)) continue;
        
        PlayerTextDrawSetString(playerid, ptd_ph_design[playerid][10], string);
        
        if(Character[playerid][E_CHARACTER_HUD_CLOCK]) {
            TextDrawShowForPlayer(playerid, hud_time);
        } else {
            TextDrawHideForPlayer(playerid, hud_time);
        }
    }
}

// Advances the in-game date by a day, rolling over months and years.
stock HandleDayChange() {
    new currentMonth = Server[E_SERVER_TIME_MONTHS];
    new maxDays = monthArray[currentMonth][month_days];
    
    if(currentMonth == 1) {
        new year = Server[E_SERVER_TIME_YEARS];
        if(((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) {
            maxDays = 29;
        }
    }
    
    if(++Server[E_SERVER_TIME_DAYS] > maxDays) {
        Server[E_SERVER_TIME_DAYS] = 1;
        
        if(++Server[E_SERVER_TIME_MONTHS] > 11) {
            Server[E_SERVER_TIME_MONTHS] = 0;
            //Server[E_SERVER_TIME_YEARS]++;
        }
    }
}

// The property whose interior the player is standing in, or INVALID_PROPERTY_ID. A property has its own time
// and weather (/propertytime, /propertyweather) that has to win over the server's while they are inside,
// otherwise the next clock tick or weather change would hand them the server's again.
Player_GetInteriorProperty(playerid) {

    new vw = GetPlayerVirtualWorld(playerid), interior = GetPlayerInterior(playerid);
    new index = PlayerVar[playerid][E_PLAYER_LAST_PROPERTY_ENTERED];

    if(index >= 0 && index < MAX_PROPERTIES && Iter_Contains(Properties, index)
        && Property[index][E_PROPERTY_INT_VW] == vw && Property[index][E_PROPERTY_INT_INT] == interior) {
        return index;
    }

    // Spawning inside a property doesn't set the line above, so look the interior up by its world.
    if(vw == 0) return INVALID_PROPERTY_ID;

    foreach(new i: Properties) {
        if(Property[i][E_PROPERTY_INT_VW] == vw && Property[i][E_PROPERTY_INT_INT] == interior) {
            return i;
        }
    }

    return INVALID_PROPERTY_ID;
}

// Sets the player's clock: a fixed property time if they're in a property that has one, the server time
// otherwise (the server clock keeps ticking either way). A property time of -1 means follow the server.
Player_RefreshTime(playerid) {
    if (IsPlayerInAdminDungeon(playerid)) return SetPlayerTime(playerid, 23, 0);

    new index = Player_GetInteriorProperty(playerid);

    if(index != INVALID_PROPERTY_ID && Property[index][E_PROPERTY_INT_HOURS] != -1) {
        SetPlayerTime(playerid, Property[index][E_PROPERTY_INT_HOURS], Property[index][E_PROPERTY_INT_MINS]);
    }
    else {
        SetPlayerTime(playerid, Server[E_SERVER_TIME_HOURS], Server[E_SERVER_TIME_MINUTES]);
    }

    return 1;
}

// Gives a player the weather of the property interior they are in (or the server weather
// outdoors).
Player_RefreshWeather(playerid) {
    if (IsPlayerInAdminDungeon(playerid)) return SetPlayerWeather(playerid, 10);

    new index = Player_GetInteriorProperty(playerid);

    if(index != INVALID_PROPERTY_ID) {
        SetPlayerWeather(playerid, Property[index][E_PROPERTY_INT_WEATHER]);
    }
    else {
        SetPlayerWeather(playerid, Server[E_SERVER_WEATHER]);
    }

    return 1;
}

// Repeating task that advances the in-game clock, changes weather and updates every player's HUD.
task HandleIngameTime[TIME_UPDATE_INTERVAL]() {
    if(Server[E_SERVER_TIME_DAYS] <= 0) {
        Server[E_SERVER_TIME_DAYS] = 1;
    }
    
    if(Server[E_SERVER_TIME_MONTHS] < 0 || Server[E_SERVER_TIME_MONTHS] > 11) {
        Server[E_SERVER_TIME_MONTHS] = 0;
    }
    
    // Increment minutes
    if(++Server[E_SERVER_TIME_MINUTES] >= 60) {
        Server[E_SERVER_TIME_MINUTES] = 0;
        Server[E_SERVER_WEATHER_TICK]++;
        
        if(Runtime_Int(RT_WEATHER_AUTOMATIC) && Server[E_SERVER_WEATHER_TICK] >= 1 && random(100) < WEATHER_CHANGE_CHANCE) {
            Server[E_SERVER_WEATHER_TICK] = 0;
            
            new weather = GetSeasonalWeather();
            if(weather != Server[E_SERVER_WEATHER]) {
                ORP_SetWeather(weather);
                SendClientMessageToAll(0xA3A3A3FF, "» The weather gradually changes...");
            }
        }
        
        // Increment hours
        if(++Server[E_SERVER_TIME_HOURS] > 23) {
            Server[E_SERVER_TIME_HOURS] = 0;
            HandleDayChange();
        }
        
        if(Server[E_SERVER_TIME_HOURS] == HEADLIGHT_REMINDER_HOUR) {
            SendClientMessageToAll(COLOR_POLICE, 
                "» It's now 20:00 - Remember to turn on your headlights until 7:00 AM! (( /lights ))");
        }
        
        SetWorldTime(Server[E_SERVER_TIME_HOURS]);
    }
    
    // Update time displays
    UpdateTimeString();
    CallLocalFunction("OnIngameMinuteChange", ""); // lil hook to use on each minute change
    
    UpdateGymStatsDay();
    //CheckHookerSpawnTime();
    
    foreach(new playerid: Player) {
        if(IsPlayerLogged(playerid) && IsPlayerSpawned(playerid) && 
           PlayerVar[playerid][E_PLAYER_CHOSE_CHARACTER]) {
            Player_RefreshTime(playerid);
        }
    }
}

// /settime [hour] [minute] - (admin) sets the server clock.
CMD:settime(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "Insufficient admin level.");
    }
    
    new hour, minute;
    if(sscanf(params, "ii", hour, minute)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/settime [hour 0-23] [minutes 0-59]");
    }
    
    if(!IsValidHour(hour) || !IsValidMinute(minute)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", 
"A3A3A3", "Invalid time format. Hour: 0-23, Minutes: 0-59");
    }
    
    new query[256];
    format(query, sizeof(query), "[AdminLog] %s changed time to %02d:%02d", Account[playerid][E_PLAYER_ACCOUNT_NAME], hour, minute);
    SendAdminMessage(query);
    
    ORP_SetTime(hour, minute);
    
    new msg[128];
    format(msg, sizeof(msg), "» Time set to %02d:%02d by %s", hour, minute, GetPlayerNameEx(playerid));
    SendClientMessageToAll(COLOR_ORANGE, msg);
    
    return 1;
}

// /setweather [id] - (admin) sets the server weather.
CMD:setweather(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "Insufficient admin level.");
    }
    
    new weather;
    if(sscanf(params, "i", weather)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Usage", "A3A3A3", "/setweather [weather ID 0-20]");
    }
    
    if(!IsValidWeatherID(weather)) {
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid weather ID. Valid range: 0-20");
    }
    
    new query[256];
    format(query, sizeof(query), "[AdminLog] %s changed weather to ID %d", Account[playerid][E_PLAYER_ACCOUNT_NAME], weather);
    SendAdminMessage(query);
    
    ORP_SetWeather(weather);
    
    new msg[128];
    format(msg, sizeof(msg), "» Weather changed to ID %d by %s", weather, GetPlayerNameEx(playerid));
    SendClientMessageToAll(COLOR_ORANGE, msg);
    
    return 1;
}

forward ORP_OnWeatherChanged(old_weather, new_weather);
// Hook point that runs after the server weather changes.
public ORP_OnWeatherChanged(old_weather, new_weather) {
    // Hook for other scripts to use
    return 1;
}

// Sets the server weather safely and updates players.
stock ORP_SetWeather(weatherid) {
    if(!IsValidWeatherID(weatherid)) {
        printf("[ERROR] Invalid weather ID: %d", weatherid);
        return 0;
    }
    
    new oldweatherid = Server[E_SERVER_WEATHER];
    Server[E_SERVER_WEATHER] = weatherid;
    
    SetWeather(weatherid);
    
    foreach(new i: Player) {
        if(IsPlayerConnected(i)) {
            Player_RefreshWeather(i);
        }
    }
    
    // Call hook
    CallLocalFunction("ORP_OnWeatherChanged", "dd", oldweatherid, weatherid);
    return 1;
}

// Sets the server time of day safely and updates players.
stock ORP_SetTime(hour, minute) {
    if(!IsValidHour(hour) || !IsValidMinute(minute)) {
        printf("[ERROR] Invalid time: %d:%d", hour, minute);
        return 0;
    }
    
    Server[E_SERVER_TIME_HOURS] = hour;
    Server[E_SERVER_TIME_MINUTES] = minute;
    
    // Set global time
    SetWorldTime(hour);
    
    // Set for all players
    foreach(new i: Player) {
        if(IsPlayerConnected(i)) {
            Player_RefreshTime(i);
        }
    }
    
    return 1;
}

hook OnGameModeInit() {
    Server[E_SERVER_TIME_HOURS] = 6;
    Server[E_SERVER_TIME_MINUTES] = 0;
    Server[E_SERVER_TIME_DAYS] = 1 + random(28); // Safe range for all months
    Server[E_SERVER_TIME_MONTHS] = random(12);
    Server[E_SERVER_TIME_YEARS] = 2005;
    
    Server[E_SERVER_WEATHER_TICK] = 0;
    new initialWeather = GetSeasonalWeather();
    Server[E_SERVER_WEATHER] = initialWeather;
    
    SetWorldTime(Server[E_SERVER_TIME_HOURS]);
    SetWeather(initialWeather);
    
    printf("[TimeWeather] System initialized - Time: %02d:%02d, Weather: %d", Server[E_SERVER_TIME_HOURS], Server[E_SERVER_TIME_MINUTES], initialWeather);
    
    return 1;
}

hook OnPlayerConnect(playerid) {
    if(IsValidWeatherID(Server[E_SERVER_WEATHER])) {
        SetPlayerWeather(playerid, Server[E_SERVER_WEATHER]);
    }
    
    SetPlayerTime(playerid, Server[E_SERVER_TIME_HOURS], Server[E_SERVER_TIME_MINUTES]);
    return 1;
}

#if defined _DEBUG
// /timeinfo - shows the current server time, date, weather and tick.
CMD:timeinfo(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL) return 0;
    
    new info[256];
    format(info, sizeof(info), 
           "Time: %02d:%02d | Date: %d/%s | Weather: %d | Tick: %d", 
           Server[E_SERVER_TIME_HOURS], Server[E_SERVER_TIME_MINUTES],
           Server[E_SERVER_TIME_DAYS], monthArray[Server[E_SERVER_TIME_MONTHS]][month_name],
           Server[E_SERVER_WEATHER], Server[E_SERVER_WEATHER_TICK]);
    
    SendClientMessage(playerid, COLOR_WHITE, info);
    return 1;
}
#endif
