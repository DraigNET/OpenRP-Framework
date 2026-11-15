// ============================================================================
// File: police/systems/soundproof.pwn
// Soundproofed rooms (interrogation rooms and similar): audio and weather ambience are blocked
// inside the defined areas. Written by Sporky.
// ============================================================================

//------------------------------------------------------------------------------
// Basic "soundproofed" rooms
// Written by Sporky (www.github.com/sporkyspork)

#include <YSI_Coding\y_hooks>
// #include <streamer>

static enum E_SOUNDROOM_INFO
{
    E_SOUNDROOM_NAME[32],
    Float:E_SOUNDROOM_MIN_POS[3],
    Float:E_SOUNDROOM_MAX_POS[3],
    E_SOUNDROOM_WORLD,
    E_SOUNDROOM_INT,
    bool:E_SOUNDROOM_BLOCK_AMBIENCE,
    bool:E_SOUNDROOM_BLOCK_WEATHER,
    E_SOUNDROOM_AREA
}

static const SoundRooms[][E_SOUNDROOM_INFO] = 
{
    { "BCSD Interview A",   {-25.8552, -98.2604, 898.0},        {-22.1471, -94.8114, 901.0},        -1, 6 },
    { "BCSD Interview B",   {-25.8519, -102.9057, 898.0},       {-22.1482, -99.4122, 901.0},        -1, 6 }
    //{ "Fire Station 2",     {1814.5760,-1450.2264,13.1646},     {1836.1934,-1423.2555,20.3968},     -1, -1, false, true},
};

static enum E_SOUNDROOM_PVARS
{
    E_PLAYER_SOUNDROOM_CURRENT,
    E_PLAYER_SOUNDROOM_WEATHER,
    bool:E_PLAYER_SOUDNROOM_AMBIENCE
}

new SoundRoomPlayer [ MAX_PLAYERS ] [ E_SOUNDROOM_PVARS ] ;

hook OnPlayerConnect(playerid)
{
 	new var_clear[E_SOUNDROOM_PVARS];
	SoundRoomPlayer[playerid] = var_clear;
}

hook OnGameModeInit()
{
    for (new i = 0; i < sizeof(SoundRooms); i ++)
    {
        SoundRooms[i][E_SOUNDROOM_AREA] = CreateDynamicCuboid
        (
            SoundRooms[i][E_SOUNDROOM_MIN_POS][0], SoundRooms[i][E_SOUNDROOM_MIN_POS][1], SoundRooms[i][E_SOUNDROOM_MIN_POS][2], 
            SoundRooms[i][E_SOUNDROOM_MAX_POS][0], SoundRooms[i][E_SOUNDROOM_MAX_POS][1], SoundRooms[i][E_SOUNDROOM_MAX_POS][2], 
            SoundRooms[i][E_SOUNDROOM_WORLD], SoundRooms[i][E_SOUNDROOM_INT]
        );

        // printf("Created DynamicArea \"%s\" with ID %d", SoundRooms[i][E_SOUNDROOM_NAME], SoundRooms[i][E_SOUNDROOM_AREA]);
    }

    return 1;
}

hook OnPlayerEnterDynArea(playerid, STREAMER_TAG_AREA:areaid)
{
    CallLocalFunction("OnPlayerSoundRoomUpdate", "d", playerid);

    return 1;
}

hook OnPlayerLeaveDynArea(playerid, STREAMER_TAG_AREA:areaid)
{
    CallLocalFunction("OnPlayerSoundRoomUpdate", "d", playerid);

    return 1;
}

// Defined in config/time_weather.pwn, which is included after the police system.
forward Player_RefreshWeather(playerid);

// Sets weather for a player inside a soundproofed room.
SoundRoom_UpdateWeather(playerid, room = -1)
{
    if (room == -1) room = GetPlayerSoundRoom(playerid);
    if (room >= 0 && SoundRooms[room][E_SOUNDROOM_BLOCK_WEATHER] && (Server[E_SERVER_WEATHER] == 8 || Server[E_SERVER_WEATHER] == 16))
    {
        // Override to dull, cloudy weather without rain
        SetPlayerWeather(playerid, 7);
        SoundRoomPlayer[playerid][E_PLAYER_SOUNDROOM_WEATHER] = true;
    }
}

forward OnPlayerSoundRoomUpdate(playerid);
// Updates a player's sound-proofing when they enter or leave a room (mutes ambience).
public OnPlayerSoundRoomUpdate(playerid)
{
    new room = GetPlayerSoundRoom(playerid);
    SoundRoomPlayer[playerid][E_PLAYER_SOUNDROOM_CURRENT] = room;
    
    if (room == -1)
    {
        if (SoundRoomPlayer[playerid][E_PLAYER_SOUDNROOM_AMBIENCE])
        {
            // Sound ID 0 can be used additionally to return the game's normal outdoor ambience track.
            PlayerPlaySound(playerid, 0, 0.0, 0.0, 0.0);
            SoundRoomPlayer[playerid][E_PLAYER_SOUDNROOM_AMBIENCE] = false;
        }

        if (SoundRoomPlayer[playerid][E_PLAYER_SOUNDROOM_WEATHER])
        {
            // Change back to the weather that applies here (a property's own weather, or the server's)
            Player_RefreshWeather(playerid);
            SoundRoomPlayer[playerid][E_PLAYER_SOUNDROOM_WEATHER] = false;
        }

        return 0;
    } 

    if (SoundRooms[room][E_SOUNDROOM_BLOCK_AMBIENCE] && !SoundRoomPlayer[playerid][E_PLAYER_SOUDNROOM_AMBIENCE])
    {
        // Sound ID 1 can be used to disable the interior 0 (default) ambience track (wind noise).
        // Hint: it can help to create more realistically fake interiors.
        PlayerPlaySound(playerid, 1, 0.0, 0.0, 0.0);
        SoundRoomPlayer[playerid][E_PLAYER_SOUDNROOM_AMBIENCE] = true;
    }

    SoundRoom_UpdateWeather(playerid, room);
    return 1;
}

hook ORP_OnWeatherChanged(old_weather, new_weather)
{
    if (new_weather == 16 || new_weather == 8)
    {
        foreach(new playerid: Player)
        {
            if (!IsPlayerConnected(playerid)) continue;
            SoundRoom_UpdateWeather(playerid);
        }
    }

    return 1;
}

forward GetPlayerSoundRoomArea(playerid);
// Returns the streamer area of the soundproof room the player is in.
public GetPlayerSoundRoomArea(playerid)
{
    for (new i = 0; i < sizeof(SoundRooms); i ++)
    {
        if (IsPlayerInDynamicArea(playerid, SoundRooms[i][E_SOUNDROOM_AREA]))
        {
            return SoundRooms[i][E_SOUNDROOM_AREA];
        }   
    }

    return 0;
}

forward GetPlayerSoundRoom(playerid);
// Returns the soundproof room index the player is in, or -1.
public GetPlayerSoundRoom(playerid)
{
    for (new i = 0; i < sizeof(SoundRooms); i ++)
    {
        if (IsPlayerInDynamicArea(playerid, SoundRooms[i][E_SOUNDROOM_AREA]))
        {
            return i;
        }   
    }

    return -1;
}
