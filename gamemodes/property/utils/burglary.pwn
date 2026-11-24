// ============================================================================
// File: property/utils/burglary.pwn
// Burglary job: break into houses (/burglary), steal valuables, carry them out while a noise
// meter and alarms warn the owner and police, then /sellgoods. Interiors load from
// scriptfiles/burglary.
// Commands: /burglary /sellgoods
// ============================================================================

#include <YSI_Coding/y_hooks>

forward BurglaryAlarm_Fire(propertyid);

#define MAX_BURGLARY_INTERIORS       20
#define MAX_BURGLARY_OBJECTS         82
#define BURGLARY_DURATION            120
#define BURGLARY_COOLDOWN (Runtime_Int(RT_BURGLARY_COOLDOWN_SECONDS)) // Cached database setting; edit through ACP.
#define BURGLARY_EXTERIOR_RANGE      15.0
#define BURGLARY_ATTACH_SLOT         9
#define BURGLARY_NOISE_MAX           100
#define BURGLARY_NOISE_UPDATE_MS     500
#define BURGLARY_NOISE_STEAL         25
#define BURGLARY_NOISE_JUMP          18
#define BURGLARY_NOISE_DROP          8

enum E_BURGLARY_INTERIOR_DATA
{
    e_GtaInteriorId,
    e_FileName[48],

    Float:e_PosX,
    Float:e_PosY,
    Float:e_PosZ,
    Float:e_PosA
};

static const burgInteriors[MAX_BURGLARY_INTERIORS][E_BURGLARY_INTERIOR_DATA] =
{
    { 1,  "burglary/burglaryhouse1.map",   6956.4600, 4258.3657, 704.0956, 3.0988 },
    { 1,  "burglary/burglaryhouse2.map",   6956.4629, 4258.7031, 704.0956, 355.3490 },
    { 1,  "burglary/burglaryhouse3.map",   6956.4966, 4258.8628, 704.0956, 358.7122 },
    { 1,  "burglary/burglaryhouse4.map",   6956.5015, 4258.8862, 704.0956, 349.9412 },
    { 1,  "burglary/burglaryhouse5.map",   6956.3530, 4258.7251, 704.0956, 357.8348 },
    { 1,  "burglary/burglaryhouse6.map",   6956.2212, 4259.0176, 704.0956, 356.6649 },
    { 1,  "burglary/burglaryhouse7.map",   6956.3589, 4258.8081, 704.0956, 356.8137 },
    { 1,  "burglary/burglaryhouse8.map",   6956.3853, 4258.5298, 704.0956, 357.5424 },
    { 1,  "burglary/burglaryhouse9.map",   6956.0840, 4259.3408, 704.0956, 351.8397 },
    { 1,  "burglary/burglaryhouse10.map",  6956.4727, 4259.4092, 704.0878, 357.9810 },

    { 1,  "burglary/burglaryhouse11.map",  6955.6890, 4446.5723, 694.7969, 0.4668 },
    { 1,  "burglary/burglaryhouse12.map",  6955.7788, 4446.8442, 694.7969, 1.7829 },
    { 1,  "burglary/burglaryhouse13.map",  6955.7163, 4446.7017, 694.7969, 359.4433 },
    { 1,  "burglary/burglaryhouse14.map",  6955.6895, 4446.0962, 694.7969, 1.7841 },
    { 1,  "burglary/burglaryhouse15.map",  6955.9512, 4446.2534, 694.7969, 1.4917 },

    { 1,  "burglary/burglaryhouse16.map",  1311.9768, 305.8197,  -30.9391, 353.00 },
    { 1,  "burglary/burglaryhouse17.map",  1242.1321, 374.4886,  -10.9383, 94.4886 },
    { 1,  "burglary/burglaryhouse18.map",  1312.1074, 306.0023,  -30.9391, 4.5623 },
    { 1,  "burglary/burglaryhouse19.map",  1242.4956, 374.5512,  -10.9383, 87.3224 },
    { 1,  "burglary/burglaryhouse20.map",  1316.3806, 303.1292,  -27.6051, 87.6161 }
};

enum E_PROPERTY_BURGLARY
{
    bool:Active,
    VirtualWorld,
    InteriorSlot,
    GtaInteriorId,
    ObjectIds[MAX_BURGLARY_OBJECTS],
    AlarmTimer,
    bool:AlarmFired
};

static PropertyBurglary[MAX_PROPERTIES][E_PROPERTY_BURGLARY];

enum E_PLAYER_BURGLARY_DATA
{
    bool:SessionActive,
    bool:InsideInterior,
    SessionEnd,
    CarryModel,
    CarryValue,
    CarryName[32],
    bool:TimerExpiredShown,
    NoiseLevel,
    NoiseLastUpdate,
    NoiseWarningLevel,
    CooldownUntil,
    ExitGraceUntil
};

static PlayerBurglaryData[MAX_PLAYERS][E_PLAYER_BURGLARY_DATA];
static PlayerText:BurgNoiseText[MAX_PLAYERS] = { PlayerText:INVALID_TEXT_DRAW, ... };
static PlayerBar:BurgNoiseBar[MAX_PLAYERS] = { PlayerBar:INVALID_PLAYER_BAR_ID, ... };

enum E_BURGLARY_MODEL_DATA
{
    m_Model,
    m_Value,
    m_Name[32],
    Float:m_PosX,
    Float:m_PosY,
    Float:m_PosZ,
    Float:m_RotX,
    Float:m_RotY,
    Float:m_RotZ
};

static const BurglaryModelData[][E_BURGLARY_MODEL_DATA] =
{
    { 1210, 250, "Briefcase",             -0.090999, 0.521000, -0.032000, -83.300094, 2.199926, 96.999725 },
    { 1271, 170, "Wooden Box",            0.359999, 0.601000, -0.017000, -94.100120, 89.299903, 96.999725 },
    { 1421, 250, "Stack of Boxes",        0.641999, 0.653999, 0.000000, 0.000000, 90.000000, 0.000000 },
    { 1431, 300, "Big Stack of Boxes",    0.538999, 0.535999, 0.000000, 0.000000, 90.000000, 0.000000 },
    { 1518, 300, "CRT Television",        0.217999, 0.516999, -0.002000, 0.000000, 90.000000, 5.099999 },
    { 1701, 350, "Double Bed",            -0.243000, 1.176999, 2.421000, 0.000000, 90.000000, -79.499938 },
    { 1706, 330, "Double Couch",          -0.243000, 0.778000, 0.438000, 0.000000, 90.000000, -2.499932 },
    { 1711, 310, "Single Couch",          -0.243000, 0.778000, 0.116999, 0.000000, 90.000000, -2.499932 },
    { 1719, 200, "VCR",                   -0.015000, 0.456000, -0.032000, 0.000000, 90.000000, -2.499932 },
    { 1725, 350, "Double Bed",            -0.359000, 1.378000, 2.280999, 0.000000, 90.000000, -84.999961 },
    { 1728, 330, "Double Couch",          -0.259000, 0.877000, 0.956998, 0.000000, 90.000000, -1.199969 },
    { 1730, 250, "Table",                 -1.005000, 0.558000, 0.173998, 0.000000, 90.000000, 0.800016 },
    { 1741, 330, "Big Drawers",           -0.076999, -0.666999, 0.426999, 0.000000, 89.399978, 0.000000 },
    { 1743, 350, "Big TV Deck",           -0.076999, -0.479999, 0.426999, 0.000000, 89.399978, 0.000000 },
    { 1747, 300, "Small TV",              -0.119000, 0.777999, -0.223000, 0.000000, 86.600097, 0.000000 },
    { 1751, 350, "Big TV",                -0.054000, 0.777999, -0.223000, 0.000000, 86.600097, 0.000000 },
    { 1773, 300, "Mini Fridge & Stove",   0.685000, 0.528999, -0.104000, 0.000000, 86.600097, 89.200035 },
    { 1786, 350, "Big TV",                -0.052999, 0.705999, -0.007000, 0.000000, 86.600097, -1.299964 },
    { 1788, 250, "DVD Player",            -0.001999, 0.432999, -0.031000, 0.000000, 86.600097, -1.299964 },
    { 1792, 350, "Luxury TV",             0.019000, 0.689999, 0.003999, 0.000000, 86.600097, -1.299964 },
    { 1794, 350, "Double Bed",            -0.151999, 1.784002, 2.102998, 0.000000, 86.600097, -94.099937 },
    { 1809, 300, "Studio Equipment",      -0.106999, 0.608001, -0.065002, 0.000000, 86.600097, -94.099937 },
    { 1839, 350, "Recording Equipment",   -0.040000, 0.474001, -0.045002, 0.000000, 86.600097, 86.900009 },
    { 19317, 300, "Guitar",               0.066999, 0.383001, -0.195002, -0.499997, 172.000122, -104.200012 },
    { 19609, 330, "Drum Set",             -0.236000, -0.154998, 0.069997, -1.499999, 86.000175, 170.200012 },
    { 19623, 350, "Expensive Camera",     0.040999, 0.498001, 0.103997, -0.499998, 10.800140, 178.900039 },
    { 19624, 250, "Briefcase",            0.040999, 0.498001, 0.183997, -0.499998, 10.800140, 88.700096 },
    { 19893, 350, "Laptop",               0.000000, 0.467999, -0.056999, 0.000000, 88.099990, 0.000000 },
    { 19894, 350, "Laptop",               -0.047000, 0.467999, -0.056999, 0.000000, 88.099990, 0.000000 },
    { 19916, 350, "Fridge",               -0.047000, 0.825999, -0.051000, 0.000000, 88.099990, 0.000000 },
    { 19934, 200, "Wooden Crate",         -0.047000, 0.630999, -0.010000, 0.000000, 88.099990, 0.000000 },
    { 2002, 300, "Water Dispenser",       -0.047000, 0.277000, -0.028000, 0.000000, 88.099990, 0.000000 },
    { 2063, 300, "Iron Shelf",            0.046999, 0.533999, -0.072000, -108.399932, -93.199882, 75.999984 },
    { 2078, 300, "Wooden Shelf",          0.000000, 0.764999, 0.355999, 0.000000, 87.799964, 0.000000 },
    { 2087, 300, "Cabinet",               0.000000, 0.572000, 0.482999, 0.000000, 87.799964, 0.000000 },
    { 2088, 330, "Dresser",               -0.185999, -0.481999, 0.418999, 0.000000, 87.799964, 0.000000 },
    { 2090, 350, "Cozy Bed",              -0.185999, 1.492001, 2.249998, 0.000000, 87.799964, -86.700019 },
    { 2093, 350, "Shelf with TV",         -0.185999, -0.065998, 0.777999, 0.000000, 87.799964, -47.800048 },
    { 2094, 300, "Wooden Cabinet",        -0.185999, -0.732998, 0.477999, 0.000000, 87.799964, -0.500053 },
    { 2099, 350, "DJ Equipment",          -0.427000, 0.791000, 0.059999, 0.000000, 87.799964, -0.500053 },
    { 2104, 350, "Music Rack",            -0.048000, 0.726000, -0.211000, 0.000000, 87.799964, -0.500053 },
    { 2145, 300, "Cabinet",               -0.048000, 0.682000, -0.167000, 0.000000, 87.799964, -0.500053 },
    { 2147, 350, "Fridge",                -0.048000, 0.490001, -0.034000, 0.000000, 87.799964, -0.500053 },
    { 2149, 300, "Microwave Oven",        0.095999, 0.490001, -0.034000, 0.000000, 87.799964, -0.500053 },
    { 2226, 330, "Modern Boombox",        -0.074999, 0.523000, -0.063000, 0.000000, 88.400009, 0.000000 },
    { 2229, 350, "Big Speaker",           -0.074999, 0.780999, -0.307000, 0.000000, 88.400009, 0.000000 },
    { 2297, 300, "TV Set",                -0.071999, 0.776999, 0.676999, -90.100074, 83.800003, 44.400035 },
    { 2307, 300, "Dresser",               -0.071999, -0.715000, 0.338999, -90.100074, 83.800003, 96.500022 },
    { 2313, 300, "TV Table",              -0.002999, 0.664999, 0.470999, -90.100074, 88.599914, 87.899986 },
    { 2360, 300, "Deep Freezer",          -0.076999, 0.712998, 0.145999, -90.100074, 88.599914, 87.899986 },
    { 2481, 350, "RC SWAT Truck",         0.157000, 0.448998, -0.050000, -90.100074, 88.599914, 87.899986 },
    { 2500, 300, "Sprunk Machine",        -0.023999, 0.712998, -0.298000, -90.100074, 88.599914, 87.899986 },
    { 2637, 250, "Table",                 -0.318999, 0.835999, -0.245000, -90.100074, 88.599914, -94.500030 }
};

// Returns true if a property is currently open to burglary.
stock Burglary_IsActive(propertyid)
{
    return PropertyBurglary[propertyid][Active];
}

//forward Burglary_IsPlayerInside(playerid);
stock Burglary_IsPlayerInside(playerid)
{
    return PlayerBurglaryData[playerid][InsideInterior];
}

// Returns true if the player has a burglary session.
stock Burglary_HasSession(playerid)
{
    return PlayerBurglaryData[playerid][SessionActive];
}

// Returns true if the player is carrying stolen goods.
stock Burglary_IsCarrying(playerid)
{
    return PlayerBurglaryData[playerid][CarryModel] != 0;
}

// Returns the model of the item the player is carrying.
stock Burglary_GetCarriedModel(playerid)
{
    return PlayerBurglaryData[playerid][CarryModel];
}

// Returns the value of the item the player is carrying.
stock Burglary_GetCarriedValue(playerid)
{
    return PlayerBurglaryData[playerid][CarryValue];
}

// Writes the name of the item the player is carrying.
stock Burglary_GetCarriedName(playerid, dest[], len)
{
    format(dest, len, "%s", PlayerBurglaryData[playerid][CarryName]);
    return 1;
}

// Returns the seconds left in the player's burglary.
stock Burglary_GetSecondsRemaining(playerid)
{
    new seconds = PlayerBurglaryData[playerid][SessionEnd] - gettime();
    if (seconds < 0)
    {
        seconds = 0;
    }
    return seconds;
}

// Returns true if the player is outside near the property's door.
static stock Burglary_IsPlayerNearExterior(playerid, propertyid)
{
    if (propertyid == INVALID_PROPERTY_ID)
    {
        return false;
    }

    if (GetPlayerInterior(playerid) != Property[propertyid][E_PROPERTY_EXT_INT] ||
        GetPlayerVirtualWorld(playerid) != Property[propertyid][E_PROPERTY_EXT_VW])
    {
        return false;
    }

    return IsPlayerInRangeOfPoint(
        playerid,
        BURGLARY_EXTERIOR_RANGE,
        Property[propertyid][E_PROPERTY_EXT_X],
        Property[propertyid][E_PROPERTY_EXT_Y],
        Property[propertyid][E_PROPERTY_EXT_Z]
    );
}

// Creates the noise meter textdraws.
static stock Burglary_CreateNoiseMeter(playerid)
{
    if (BurgNoiseText[playerid] == PlayerText:INVALID_TEXT_DRAW)
    {
        BurgNoiseText[playerid] = CreatePlayerTextDraw(playerid, 525.0000, 145.0000, "NOISE");
        PlayerTextDrawFont(playerid, BurgNoiseText[playerid], 2);
        PlayerTextDrawLetterSize(playerid, BurgNoiseText[playerid], 0.3000, 1.1000);
        PlayerTextDrawAlignment(playerid, BurgNoiseText[playerid], 1);
        PlayerTextDrawColor(playerid, BurgNoiseText[playerid], 0xDEDEDEFF);
        PlayerTextDrawSetShadow(playerid, BurgNoiseText[playerid], 0);
        PlayerTextDrawSetOutline(playerid, BurgNoiseText[playerid], 1);
        PlayerTextDrawBackgroundColor(playerid, BurgNoiseText[playerid], 255);
        PlayerTextDrawSetProportional(playerid, BurgNoiseText[playerid], 1);
        PlayerTextDrawTextSize(playerid, BurgNoiseText[playerid], 0.0000, 100.0000);
    }

    if (BurgNoiseBar[playerid] == PlayerBar:INVALID_PLAYER_BAR_ID)
    {
        BurgNoiseBar[playerid] = CreatePlayerProgressBar(playerid, 525.0000, 160.0000, 70.0000, 5.2000, 0xCC3333FF, 100.0000);
    }

    return 1;
}

// Shows the noise meter.
static stock Burglary_ShowNoiseMeter(playerid)
{
    Burglary_CreateNoiseMeter(playerid);

    SetPlayerProgressBarValue(playerid, BurgNoiseBar[playerid], float(PlayerBurglaryData[playerid][NoiseLevel]));
    PlayerTextDrawShow(playerid, BurgNoiseText[playerid]);
    ShowPlayerProgressBar(playerid, BurgNoiseBar[playerid]);
    return 1;
}

// Hides the noise meter.
static stock Burglary_HideNoiseMeter(playerid)
{
    if (BurgNoiseText[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawHide(playerid, BurgNoiseText[playerid]);
    }

    if (BurgNoiseBar[playerid] != PlayerBar:INVALID_PLAYER_BAR_ID)
    {
        HidePlayerProgressBar(playerid, BurgNoiseBar[playerid]);
    }

    return 1;
}

// Destroys the noise meter textdraws.
static stock Burglary_DestroyNoiseMeter(playerid)
{
    if (BurgNoiseText[playerid] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, BurgNoiseText[playerid]);
        BurgNoiseText[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }

    if (BurgNoiseBar[playerid] != PlayerBar:INVALID_PLAYER_BAR_ID)
    {
        DestroyPlayerProgressBar(playerid, BurgNoiseBar[playerid]);
        BurgNoiseBar[playerid] = PlayerBar:INVALID_PLAYER_BAR_ID;
    }

    return 1;
}

// Resets the player's noise level.
static stock Burglary_ResetNoise(playerid)
{
    PlayerBurglaryData[playerid][NoiseLevel] = 0;
    PlayerBurglaryData[playerid][NoiseLastUpdate] = 0;
    PlayerBurglaryData[playerid][NoiseWarningLevel] = 0;
    Burglary_HideNoiseMeter(playerid);
    return 1;
}

// Adds noise; too much noise triggers the alarm.
static stock Burglary_AddNoise(playerid, amount)
{
    if (!Burglary_HasSession(playerid) || !Burglary_IsPlayerInside(playerid))
    {
        return 0;
    }

    new propertyid = PlayerBurglaryProperty[playerid];
    if (propertyid == INVALID_PROPERTY_ID || PropertyBurglary[propertyid][AlarmFired])
    {
        return 0;
    }

    PlayerBurglaryData[playerid][NoiseLevel] += amount;
    if (PlayerBurglaryData[playerid][NoiseLevel] < 0)
    {
        PlayerBurglaryData[playerid][NoiseLevel] = 0;
    }
    else if (PlayerBurglaryData[playerid][NoiseLevel] > BURGLARY_NOISE_MAX)
    {
        PlayerBurglaryData[playerid][NoiseLevel] = BURGLARY_NOISE_MAX;
    }

    Burglary_ShowNoiseMeter(playerid);

    if (PlayerBurglaryData[playerid][NoiseLevel] >= 90 && PlayerBurglaryData[playerid][NoiseWarningLevel] < 3)
    {
        PlayerBurglaryData[playerid][NoiseWarningLevel] = 3;
        GameTextForPlayer(playerid, "~r~Too loud!", 1500, 3);
    }
    else if (PlayerBurglaryData[playerid][NoiseLevel] >= 70 && PlayerBurglaryData[playerid][NoiseWarningLevel] < 2)
    {
        PlayerBurglaryData[playerid][NoiseWarningLevel] = 2;
        SendClientMessage(playerid, -1, "You're making too much noise. Slow down before the alarm trips.");
    }
    else if (PlayerBurglaryData[playerid][NoiseLevel] >= 45 && PlayerBurglaryData[playerid][NoiseWarningLevel] < 1)
    {
        PlayerBurglaryData[playerid][NoiseWarningLevel] = 1;
        SendClientMessage(playerid, -1, "The noise meter is rising. Walk or crouch to stay quiet.");
    }

    if (PlayerBurglaryData[playerid][NoiseLevel] >= BURGLARY_NOISE_MAX)
    {
        SendClientMessage(playerid, -1, "You made too much noise and triggered the burglar alarm.");
        BurglaryAlarm_Fire(propertyid);
    }

    return 1;
}

// Updates the noise meter each tick and lowers the noise over time.
static stock Burglary_UpdateNoise(playerid)
{
    if (!Burglary_HasSession(playerid) || !Burglary_IsPlayerInside(playerid))
    {
        return 0;
    }

    new propertyid = PlayerBurglaryProperty[playerid];
    if (propertyid == INVALID_PROPERTY_ID || PropertyBurglary[propertyid][AlarmFired])
    {
        return 0;
    }

    new tick = GetTickCount();
    if (PlayerBurglaryData[playerid][NoiseLastUpdate] && tick - PlayerBurglaryData[playerid][NoiseLastUpdate] < BURGLARY_NOISE_UPDATE_MS)
    {
        return 0;
    }
    PlayerBurglaryData[playerid][NoiseLastUpdate] = tick;

    new keys, ud, lr;
    new amount = -2;
    new Float:vx, Float:vy, Float:vz;
    new Float:speed;

    GetPlayerKeys(playerid, keys, ud, lr);
    GetPlayerVelocity(playerid, vx, vy, vz);
    speed = floatsqroot((vx * vx) + (vy * vy) + (vz * vz));

    if (speed > 0.018)
    {
        if ((keys & KEY_WALK) || GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_DUCK)
        {
            amount = -1;
        }
        else if ((keys & KEY_SPRINT) || speed > 0.115)
        {
            amount = 15;
        }
        else
        {
            amount = 6;
        }

        if (Burglary_IsCarrying(playerid))
        {
            amount += 3;
        }
    }

    return Burglary_AddNoise(playerid, amount);
}

// Finds a stealable model in the loot table.
static stock Burglary_FindModelData(modelid, &dataIndex)
{
    for (new i = 0; i < sizeof(BurglaryModelData); i++)
    {
        if (BurglaryModelData[i][m_Model] == modelid)
        {
            dataIndex = i;
            return 1;
        }
    }

    dataIndex = -1;
    return 0;
}

// Writes the name of a stealable model.
static stock Burglary_GetModelName(modelid, dest[], len)
{
    new idx;
    if (Burglary_FindModelData(modelid, idx))
    {
        format(dest, len, "%s", BurglaryModelData[idx][m_Name]);
        return 1;
    }

    format(dest, len, "Household Item");
    return 0;
}

// Returns the value of a stealable model.
static stock Burglary_GetModelValue(modelid)
{
    new idx;
    if (Burglary_FindModelData(modelid, idx))
    {
        return BurglaryModelData[idx][m_Value];
    }

    return 100;
}

// Attaches the carried loot object to the player.
static stock Burglary_AttachCarriedObject(playerid, modelid)
{
    new idx;
    new Float:px, Float:py, Float:pz, Float:rx, Float:ry, Float:rz;

    if (Burglary_FindModelData(modelid, idx))
    {
        px = BurglaryModelData[idx][m_PosX];
        py = BurglaryModelData[idx][m_PosY];
        pz = BurglaryModelData[idx][m_PosZ];
        rx = BurglaryModelData[idx][m_RotX];
        ry = BurglaryModelData[idx][m_RotY];
        rz = BurglaryModelData[idx][m_RotZ];
    }
    else
    {
        px = 0.000000;
        py = 0.500000;
        pz = -0.050000;
        rx = 0.000000;
        ry = 90.000000;
        rz = 0.000000;
    }

    SetPlayerAttachedObject(playerid, BURGLARY_ATTACH_SLOT, modelid, 1, px, py, pz, rx, ry, rz);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY);

    return 1;
}

// Clears the carried loot.
static stock Burglary_ClearCarry(playerid)
{
    if (IsPlayerAttachedObjectSlotUsed(playerid, BURGLARY_ATTACH_SLOT))
    {
        RemovePlayerAttachedObject(playerid, BURGLARY_ATTACH_SLOT);
    }

    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);

    PlayerBurglaryData[playerid][CarryModel] = 0;
    PlayerBurglaryData[playerid][CarryValue] = 0;
    PlayerBurglaryData[playerid][CarryName][0] = '\0';

    return 1;
}

// Takes the carried loot from the player and returns its model.
stock Burglary_RemoveCarry(playerid, &modelid)
{
    if (!Burglary_IsCarrying(playerid))
    {
        modelid = 0;
        return 0;
    }

    modelid = PlayerBurglaryData[playerid][CarryModel];
    Burglary_ClearCarry(playerid);
    return 1;
}

// Gives the player a piece of loot to carry.
stock Burglary_GiveCarry(playerid, modelid)
{
    if (!modelid || Burglary_IsCarrying(playerid))
    {
        return 0;
    }

    PlayerBurglaryData[playerid][CarryModel] = modelid;
    PlayerBurglaryData[playerid][CarryValue] = Burglary_GetModelValue(modelid);
    Burglary_GetModelName(modelid, PlayerBurglaryData[playerid][CarryName], 32);

    Burglary_AttachCarriedObject(playerid, modelid);
    return 1;
}

// Writes the name of a loot item.
stock Burglary_GetItemName(modelid, dest[], len)
{
    return Burglary_GetModelName(modelid, dest, len);
}

// Returns the value of a loot item.
stock Burglary_GetItemValue(modelid)
{
    return Burglary_GetModelValue(modelid);
}

// Tells the player that time ran out.
static stock Burglary_ShowTimeExpired(playerid)
{
    if (!PlayerBurglaryData[playerid][TimerExpiredShown])
    {
        PlayerBurglaryData[playerid][TimerExpiredShown] = true;
        SendClientMessage(playerid, -1, "Your burglary window has ended. You can still leave, but you cannot steal any more items.");
    }

    return 1;
}

// Returns true if a model can be stolen.
static stock Burglary_IsModelStealable(modelid)
{
    switch (modelid)
    {
        case 14718, 14756, 14709, 14717, 15042, 2670, 2671, 2672, 2673, 2674, 2675, 2676, 2677,
             14720, 15036, 2132, 2157, 2159, 2560, 2561, 16779, 16780, 1731, 19371, 19356, 19355,
             19363, 1491, 1535, 1494, 1497, 1506, 1498, 1505, 2817, 2818, 2815, 1828, 2847, 2842,
             2841, 2836, 2833, 2834, 1493, 1501, 1657, 17969, 2048, 2051, 2064, 2068, 2069, 2076,
             2130, 2133, 2136, 2160, 2170, 2192, 2334, 2336, 2338, 2371, 2372, 2394, 2482, 2558,
             2619, 2691, 2693, 2695, 2697, 2819, 2843, 2844, 2845, 2846, 2867:
        {
            return 0;
        }
    }

    return 1;
}

// Removes the burglary interior objects.
static stock Burglary_DestroyInterior(propertyid)
{
    for (new i = 0; i < MAX_BURGLARY_OBJECTS; i++)
    {
        if (PropertyBurglary[propertyid][ObjectIds][i] != INVALID_STREAMER_ID)
        {
            DestroyDynamicObject(PropertyBurglary[propertyid][ObjectIds][i]);
            PropertyBurglary[propertyid][ObjectIds][i] = INVALID_STREAMER_ID;
        }
    }

    return 1;
}

// Loads a burglary interior (objects) from a file.
static stock Burglary_LoadInteriorFromFile(propertyid, const filename[])
{
    new File:f = fopen(filename, io_read);
    if (!f)
    {
        printf("[BURGLARY] Missing map file: %s", filename);
        return 0;
    }

    new line[256];
    new model;
    new Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;
    new count = 0;

    new vw = PropertyBurglary[propertyid][VirtualWorld];
    new intid = PropertyBurglary[propertyid][GtaInteriorId];

    while (fread(f, line, sizeof(line)) > 0)
    {
        if (count >= MAX_BURGLARY_OBJECTS)
        {
            break;
        }

        if (sscanf(line, "p<,>dffffff", model, x, y, z, rx, ry, rz))
        {
            continue;
        }

        if (model == 0)
        {
            continue;
        }

        PropertyBurglary[propertyid][ObjectIds][count] = CreateDynamicObject(
            model,
            x,
            y,
            z,
            rx,
            ry,
            rz,
            vw,
            intid
        );

        count++;
    }

    fclose(f);
    return 1;
}

// Finds the closest loot object to the player.
static stock Burglary_GetClosestLootObject(playerid, &slot)
{
    slot = -1;

    if (!Burglary_IsPlayerInside(playerid))
    {
        return INVALID_STREAMER_ID;
    }

    new propertyid = PlayerBurglaryProperty[playerid];
    if (propertyid == INVALID_PROPERTY_ID)
    {
        return INVALID_STREAMER_ID;
    }

    new closestObj = INVALID_STREAMER_ID;
    new Float:closestDist = 9999.9;
    new Float:x, Float:y, Float:z;

    for (new i = 0; i < MAX_BURGLARY_OBJECTS; i++)
    {
        new objid = PropertyBurglary[propertyid][ObjectIds][i];
        if (objid == INVALID_STREAMER_ID)
        {
            continue;
        }

        new modelid = GetDynamicObjectModel(objid);
        if (!Burglary_IsModelStealable(modelid))
        {
            continue;
        }

        GetDynamicObjectPos(objid, x, y, z);

        if (!IsPlayerInRangeOfPoint(playerid, 2.3, x, y, z))
        {
            continue;
        }

        new Float:dist = GetPlayerDistanceFromPoint(playerid, x, y, z);
        if (dist < closestDist)
        {
            closestDist = dist;
            closestObj = objid;
            slot = i;
        }
    }

    return closestObj;
}

// Steals the closest object.
static stock Burglary_StealClosestObject(playerid)
{
    if (!Burglary_HasSession(playerid))
    {
        return 1;
    }

    if (!Burglary_IsPlayerInside(playerid))
    {
        SendClientMessage(playerid, -1, "You must be inside the burglarized property to steal items.");
        return 1;
    }

    if (Burglary_IsCarrying(playerid))
    {
        SendClientMessage(playerid, -1, "You are already carrying an item.");
        return 1;
    }

    if (gettime() >= PlayerBurglaryData[playerid][SessionEnd])
    {
        Burglary_ShowTimeExpired(playerid);
        return 1;
    }

    new slot;
    new objid = Burglary_GetClosestLootObject(playerid, slot);

    if (objid == INVALID_STREAMER_ID || slot == -1)
    {
        SendClientMessage(playerid, -1, "There is nothing nearby that you can steal.");
        return 1;
    }

    new modelid = GetDynamicObjectModel(objid);

    PlayerBurglaryData[playerid][CarryModel] = modelid;
    PlayerBurglaryData[playerid][CarryValue] = Burglary_GetModelValue(modelid);
    Burglary_GetModelName(modelid, PlayerBurglaryData[playerid][CarryName], 32);

    Burglary_AttachCarriedObject(playerid, modelid);

    DestroyDynamicObject(objid);
    PropertyBurglary[PlayerBurglaryProperty[playerid]][ObjectIds][slot] = INVALID_STREAMER_ID;

    Burglary_AddNoise(playerid, BURGLARY_NOISE_STEAL);

    SendClientMessage(
        playerid,
        -1,
        sprintf(
            "You steal %s. Get it out to the pawn shop. %d seconds remaining.",
            PlayerBurglaryData[playerid][CarryName],
            Burglary_GetSecondsRemaining(playerid)
        )
    );

    return 1;
}

// Drops the carried object.
static stock Burglary_DropCarriedObject(playerid)
{
    if (!Burglary_HasSession(playerid) || !Burglary_IsCarrying(playerid))
    {
        return 0;
    }

    new propertyid = PlayerBurglaryProperty[playerid];
    if (propertyid == INVALID_PROPERTY_ID || !Burglary_IsActive(propertyid))
    {
        return 1;
    }

    new modelid = PlayerBurglaryData[playerid][CarryModel];
    new itemName[32];
    format(itemName, sizeof(itemName), "%s", PlayerBurglaryData[playerid][CarryName]);

    if (!Burglary_IsPlayerInside(playerid))
    {
        Burglary_ClearCarry(playerid);
        SendClientMessage(playerid, -1, sprintf("You drop %s and leave it behind.", itemName));
        return 1;
    }

    new slot = -1;
    for (new i = 0; i < MAX_BURGLARY_OBJECTS; i++)
    {
        if (PropertyBurglary[propertyid][ObjectIds][i] == INVALID_STREAMER_ID)
        {
            slot = i;
            break;
        }
    }

    if (slot == -1)
    {
        SendClientMessage(playerid, -1, "There is no room to drop that item here.");
        return 1;
    }

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    PropertyBurglary[propertyid][ObjectIds][slot] = CreateDynamicObject(
        modelid,
        x,
        y,
        z - 0.75,
        0.0,
        0.0,
        a,
        PropertyBurglary[propertyid][VirtualWorld],
        PropertyBurglary[propertyid][GtaInteriorId]
    );

    if (PropertyBurglary[propertyid][ObjectIds][slot] == INVALID_STREAMER_ID)
    {
        SendClientMessage(playerid, -1, "You couldn't drop that item here.");
        return 1;
    }

    Burglary_AddNoise(playerid, BURGLARY_NOISE_DROP);
    Burglary_ClearCarry(playerid);

    SendClientMessage(playerid, -1, sprintf("You drop %s.", itemName));
    return 1;
}

// Returns true if entering the property should start a burglary.
stock Burglary_ShouldOverrideEnter(playerid, propertyid)
{
    if (!Burglary_IsActive(propertyid))
    {
        return false;
    }

    if (IsPlayerInLEAFaction(playerid))
    {
        return true;
    }

    if (!Burglary_HasSession(playerid))
    {
        return false;
    }

    return PlayerBurglaryProperty[playerid] == propertyid;
}

// Lets the player into a property as a burglar.
stock Burglary_Enter(playerid, propertyid)
{
    if (propertyid == INVALID_PROPERTY_ID)
    {
        return 0;
    }

    if (!Burglary_IsActive(propertyid))
    {
        return 0;
    }

    if (!IsPlayerInLEAFaction(playerid) && !Burglary_HasSession(playerid))
    {
        return 0;
    }

    if (!IsPlayerInLEAFaction(playerid) && Burglary_IsCarrying(playerid))
    {
        SendClientMessage(playerid, -1, "You cannot re-enter while carrying stolen property.");
        return 1;
    }

    if (!IsPlayerInLEAFaction(playerid) && PlayerBurglaryProperty[playerid] != propertyid)
    {
        return 0;
    }

    new vw = PropertyBurglary[propertyid][VirtualWorld];
    new slot = PropertyBurglary[propertyid][InteriorSlot];
    new gtaInterior = PropertyBurglary[propertyid][GtaInteriorId];

    if (slot < 0 || slot >= MAX_BURGLARY_INTERIORS)
    {
        printf("[BURGLARY] Invalid interior slot for property %d", propertyid);
        return 0;
    }

    PlayerBurglaryProperty[playerid] = propertyid;
    PlayerBurglaryData[playerid][InsideInterior] = true;

    SetPlayerVirtualWorld(playerid, vw);
    SetPlayerInterior(playerid, gtaInterior);

    ORP_SetPosWithFade(
        playerid,
        burgInteriors[slot][e_PosX],
        burgInteriors[slot][e_PosY],
        burgInteriors[slot][e_PosZ] + 0.5,
        FormatPropertyName(propertyid)
    );
    SetPlayerFacingAngle(playerid, burgInteriors[slot][e_PosA]);

    if (!IsPlayerInLEAFaction(playerid))
    {
        Burglary_ShowNoiseMeter(playerid);

        SendClientMessage(
            playerid,
            -1,
            sprintf("You enter the burglarized property. Keep quiet and steal what you can. %d seconds remaining.", Burglary_GetSecondsRemaining(playerid))
        );
    }
    else
    {
        SendClientMessage(playerid, -1, "You enter the active burglary scene.");
    }

    return 1;
}

// Lets the player out of a burglary.
stock Burglary_Exit(playerid)
{
    if (!Burglary_IsPlayerInside(playerid))
    {
        return 1;
    }

    PlayerBurglaryData[playerid][InsideInterior] = false;

    // The teleport to the door is applied server-side at once, but OnPlayerUpdate keeps
    // reporting the old interior position for a moment. Without a grace period the
    // "are you near the door" check ran against that stale position and ended the
    // session the instant you walked out.
    PlayerBurglaryData[playerid][ExitGraceUntil] = gettime() + 5;
    Burglary_HideNoiseMeter(playerid);

    if (!Burglary_HasSession(playerid) && IsPlayerInLEAFaction(playerid))
    {
        PlayerBurglaryProperty[playerid] = INVALID_PROPERTY_ID;
    }

    return 1;
}

// Opens or closes a property to burglary.
stock Burglary_SetActive(propertyid, bool:active)
{
    PropertyBurglary[propertyid][Active] = active;

    if (active)
    {
        PropertyBurglary[propertyid][VirtualWorld] = 10000 + propertyid;

        new slot = random(MAX_BURGLARY_INTERIORS);
        PropertyBurglary[propertyid][InteriorSlot] = slot;
        PropertyBurglary[propertyid][GtaInteriorId] = burgInteriors[slot][e_GtaInteriorId];

        Burglary_DestroyInterior(propertyid);
        Burglary_LoadInteriorFromFile(propertyid, burgInteriors[slot][e_FileName]);
    }
    else
    {
        if (PropertyBurglary[propertyid][AlarmTimer] != -1)
        {
            KillTimer(PropertyBurglary[propertyid][AlarmTimer]);
            PropertyBurglary[propertyid][AlarmTimer] = -1;
        }

        PropertyBurglary[propertyid][AlarmFired] = false;
        Burglary_DestroyInterior(propertyid);
        PropertyBurglary[propertyid][VirtualWorld] = 0;
        PropertyBurglary[propertyid][InteriorSlot] = -1;
        PropertyBurglary[propertyid][GtaInteriorId] = 0;
    }

    return 1;
}

// Alerts police to a burglary in progress.
static stock Burglary_NotifyPolice(propertyid)
{
    new Float:x = Property[propertyid][E_PROPERTY_EXT_X];
    new Float:y = Property[propertyid][E_PROPERTY_EXT_Y];
    new Float:z = Property[propertyid][E_PROPERTY_EXT_Z];

    new address[64], zone[64], area[12], city[64];
    GetPlayerAddress(x, y, address);
    GetCoords2DZone(x, y, zone, sizeof(zone));
    GetPlayerAreaZone(x, y, area);
    GetCoords2DMainZone(x, y, city, sizeof(city));

    Server[E_SERVER_LAST_911_POS_X] = x;
    Server[E_SERVER_LAST_911_POS_Y] = y;
    Server[E_SERVER_LAST_911_POS_Z] = z;
    Server[E_SERVER_LAST_911_TYPE] = 0;

    new disMsg[512];
    format(disMsg, sizeof(disMsg),
        "**[Burglary Alarm]:**\n"\
        "**[Location]:** %s, %s, %s\n"\
        "**[Property ID]:** #%d\n"\
        "**[Description]:** A residential burglar alarm has been triggered.",
        address, zone, city, propertyid
    );

    DCC_SendBurglaryAlertMessage(disMsg);

    new burglarId = INVALID_PLAYER_ID;
    foreach (new i : Player)
    {
        if (PlayerBurglaryProperty[i] == propertyid && Burglary_HasSession(i))
        {
            burglarId = i;
            break;
        }
    }

    if (burglarId != INVALID_PLAYER_ID)
    {
        Log911Call(burglarId, 4, "A residential burglar alarm has been triggered.", x, y, z, address, zone, city);
    }

    foreach (new i : Player)
    {
        if (IsPlayerInRangeOfPoint(i, 30.0, x, y, z))
        {
            SendClientMessage(i, -1, "* You hear a burglar alarm going off nearby.");
        }
    }

    new string[256];
    foreach (new i : Player)
    {
        if (IsPlayerInLEAFaction(i, true))
        {
            format(string, sizeof(string), "[Dispatch]: Burglar alarm activated at a residential property. (Property #%d)", propertyid);
            ZMsg_SendClientMessage(i, COLOR_FACTION, string);

            format(string, sizeof(string), "[Location]: %s, %s, %s, %s", address, zone, area, city);
            ZMsg_SendClientMessage(i, COLOR_FACTION, string);

            ZMsg_SendClientMessage(i, COLOR_FACTION, "[Description]: A residential burglar alarm has been triggered. Units respond code 2.");
            SendClientMessage(i, COLOR_FACTION, "To set a GPS marker, type /lastburglary.");

            SetPlayerCheckpoint(i, x, y, z, 3.0);
        }
    }

    return 1;
}

// Timer: fires the burglary alarm.
public BurglaryAlarm_Fire(propertyid)
{
    PropertyBurglary[propertyid][AlarmTimer] = -1;

    if (!PropertyBurglary[propertyid][Active]) return 0;
    if (PropertyBurglary[propertyid][AlarmFired]) return 0;

    PropertyBurglary[propertyid][AlarmFired] = true;
    Burglary_NotifyPolice(propertyid);
    return 1;
}

// Ends a burglary session.
static stock Burglary_EndSession(playerid, bool:silent = false, bool:clearCarry = true)
{
    new propertyid = PlayerBurglaryProperty[playerid];

    if (clearCarry)
    {
        Burglary_ClearCarry(playerid);
    }

    Burglary_ResetNoise(playerid);

    PlayerBurglaryData[playerid][SessionActive] = false;
    PlayerBurglaryData[playerid][InsideInterior] = false;
    PlayerBurglaryData[playerid][SessionEnd] = 0;
    PlayerBurglaryData[playerid][TimerExpiredShown] = false;
    PlayerBurglaryData[playerid][CooldownUntil] = gettime() + BURGLARY_COOLDOWN;
    PlayerBurglaryProperty[playerid] = INVALID_PROPERTY_ID;

    if (propertyid != INVALID_PROPERTY_ID)
    {
        Burglary_SetActive(propertyid, false);
    }

    if (!silent)
    {
        if (clearCarry)
        {
            SendClientMessage(playerid, -1, "Burglary session has ended.");
        }
        else
        {
            SendClientMessage(playerid, -1, "Burglary session has ended. Store or sell the item you escaped with.");
        }
    }

    return 1;
}

// /burglary - starts or manages a burglary.
CMD:burglary(playerid, params[])
{
    /*if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "Admins only for testing.") ;
	}*/

    if (IsPlayerInLEAFaction(playerid))
    {
        SendClientMessage(playerid, -1, "Police cannot start burglaries.");
        return 1;
    }

    if (Burglary_IsCarrying(playerid))
    {
        SendClientMessage(playerid, -1, "Store or sell the burglary item you are carrying before starting another burglary.");
        return 1;
    }

    if (PlayerBurglaryData[playerid][CooldownUntil] > gettime())
    {
        new remaining = PlayerBurglaryData[playerid][CooldownUntil] - gettime();
        new minutes = floatround(float(remaining) / 60.0, floatround_ceil);
        new cooldownMsg[96];

        if (minutes == 1)
        {
            format(cooldownMsg, sizeof(cooldownMsg), "You need to wait %d minute before starting another burglary.", minutes);
        }
        else
        {
            format(cooldownMsg, sizeof(cooldownMsg), "You need to wait %d minutes before starting another burglary.", minutes);
        }

        SendClientMessage(playerid, -1, cooldownMsg);
        return 1;
    }

    if (Burglary_HasSession(playerid))
    {
        if (Burglary_IsPlayerInside(playerid))
        {
            SendClientMessage(playerid, -1, "Leave the property before ending your burglary session.");
            return 1;
        }

        if (Burglary_IsCarrying(playerid))
        {
            SendClientMessage(playerid, -1, "Sell the item you are carrying before ending your burglary session.");
            return 1;
        }

        return Burglary_EndSession(playerid);
    }

    new propertyid = Property_GetClosestEntity(playerid, PROPERTY_NEAR_ENTER);

    if (propertyid == INVALID_PROPERTY_ID)
    {
        SendClientMessage(playerid, -1, "You are not near a property.");
        return 1;
    }

    if (Burglary_IsActive(propertyid))
    {
        SendClientMessage(playerid, -1, "This property is already being burglarized.");
        return 1;
    }

    PlayerBurglaryData[playerid][SessionActive] = true;
    PlayerBurglaryData[playerid][InsideInterior] = false;
    PlayerBurglaryData[playerid][SessionEnd] = gettime() + BURGLARY_DURATION;
    PlayerBurglaryData[playerid][TimerExpiredShown] = false;
    PlayerBurglaryProperty[playerid] = propertyid;
    Burglary_ClearCarry(playerid);
    Burglary_ResetNoise(playerid);

    Burglary_SetActive(propertyid, true);

    SendClientMessage(playerid, -1, "You break into the property. Keep the noise meter low or the alarm will trigger.");
    return 1;
}

// /sellgoods - sells carried stolen goods at a fence.
CMD:sellgoods(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
    {
        return 1;
    }

    if (!Burglary_IsCarrying(playerid))
    {
        return SendClientMessage(playerid, COLOR_ERROR, "You are not carrying anything to sell.");
    }

    foreach (new i: Properties)
    {
        if (Property[i][E_PROPERTY_ID] == INVALID_PROPERTY_ID)
        {
            continue;
        }

        if (IsPlayerInRangeOfPoint(playerid, 5.0,
            Property[i][E_PROPERTY_BUY_POS_X],
            Property[i][E_PROPERTY_BUY_POS_Y],
            Property[i][E_PROPERTY_BUY_POS_Z]))
        {
            if (GetPlayerVirtualWorld(playerid) == Property[i][E_PROPERTY_BUY_POS_VW] &&
                GetPlayerInterior(playerid) == Property[i][E_PROPERTY_BUY_POS_INT])
            {
                if (Property[i][E_PROPERTY_BUY_TYPE] == E_BUY_TYPE_PAWN)
                {
                    new value = PlayerBurglaryData[playerid][CarryValue];

                    GivePlayerCash(playerid, value, "Pawn shop sale");

                    SendClientMessage(playerid, COLOR_WHITE,
                        sprintf("You sell %s for $%s.",
                            PlayerBurglaryData[playerid][CarryName],
                            IntegerWithDelimiter(value)
                        )
                    );

                    Burglary_ClearCarry(playerid);
                    return 1;
                }
            }
        }
    }

    SendClientMessage(playerid, COLOR_ERROR, "You need to be at a pawn shop to sell goods!");
    return 1;
}

hook OnGameModeInit()
{
    for (new p = 0; p < MAX_PROPERTIES; p++)
    {
        PropertyBurglary[p][Active] = false;
        PropertyBurglary[p][VirtualWorld] = 0;
        PropertyBurglary[p][InteriorSlot] = -1;
        PropertyBurglary[p][GtaInteriorId] = 0;
        PropertyBurglary[p][AlarmTimer] = -1;
        PropertyBurglary[p][AlarmFired] = false;

        for (new i = 0; i < MAX_BURGLARY_OBJECTS; i++)
        {
            PropertyBurglary[p][ObjectIds][i] = INVALID_STREAMER_ID;
        }
    }

    return 1;
}

hook OnPlayerConnect(playerid)
{
    PlayerBurglaryProperty[playerid] = INVALID_PROPERTY_ID;

    PlayerBurglaryData[playerid][SessionActive] = false;
    PlayerBurglaryData[playerid][InsideInterior] = false;
    PlayerBurglaryData[playerid][SessionEnd] = 0;
    PlayerBurglaryData[playerid][CarryModel] = 0;
    PlayerBurglaryData[playerid][CarryValue] = 0;
    PlayerBurglaryData[playerid][CarryName][0] = '\0';
    PlayerBurglaryData[playerid][TimerExpiredShown] = false;
    PlayerBurglaryData[playerid][NoiseLevel] = 0;
    PlayerBurglaryData[playerid][NoiseLastUpdate] = 0;
    PlayerBurglaryData[playerid][NoiseWarningLevel] = 0;
    PlayerBurglaryData[playerid][CooldownUntil] = 0;
    PlayerBurglaryData[playerid][ExitGraceUntil] = 0;
    BurgNoiseText[playerid] = PlayerText:INVALID_TEXT_DRAW;
    BurgNoiseBar[playerid] = PlayerBar:INVALID_PLAYER_BAR_ID;

    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if (Burglary_HasSession(playerid))
    {
        Burglary_EndSession(playerid, true);
    }
    else
    {
        Burglary_ClearCarry(playerid);
        Burglary_ResetNoise(playerid);
        PlayerBurglaryProperty[playerid] = INVALID_PROPERTY_ID;
        PlayerBurglaryData[playerid][InsideInterior] = false;
    }

    Burglary_DestroyNoiseMeter(playerid);
    return 1;
}

hook OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    if (Burglary_HasSession(playerid))
    {
        Burglary_EndSession(playerid, true);
    }

    return 1;
}

hook OnPlayerUpdate(playerid)
{
    if (Burglary_IsPlayerInside(playerid) && PlayerBurglaryProperty[playerid] != INVALID_PROPERTY_ID)
    {
        if (!Burglary_IsActive(PlayerBurglaryProperty[playerid]))
        {
            cmd_exit(playerid);
            return 1;
        }

        if (Burglary_HasSession(playerid) && gettime() >= PlayerBurglaryData[playerid][SessionEnd])
        {
            Burglary_ShowTimeExpired(playerid);
        }

        Burglary_UpdateNoise(playerid);
    }
    else if (Burglary_HasSession(playerid))
    {
        if (gettime() >= PlayerBurglaryData[playerid][ExitGraceUntil] &&
            !Burglary_IsPlayerNearExterior(playerid, PlayerBurglaryProperty[playerid]))
        {
            Burglary_EndSession(playerid, false, !Burglary_IsCarrying(playerid));
            return 1;
        }

        if (gettime() >= PlayerBurglaryData[playerid][SessionEnd])
        {
            Burglary_EndSession(playerid, false, !Burglary_IsCarrying(playerid));
        }
    }

    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if ((newkeys & KEY_YES) && !(oldkeys & KEY_YES))
    {
        if (Burglary_HasSession(playerid))
        {
            if (Burglary_IsCarrying(playerid))
            {
                Burglary_DropCarriedObject(playerid);
            }
            else
            {
                Burglary_StealClosestObject(playerid);
            }
        }
    }

    if ((newkeys & KEY_JUMP) && !(oldkeys & KEY_JUMP))
    {
        if (Burglary_HasSession(playerid) && Burglary_IsPlayerInside(playerid))
        {
            Burglary_AddNoise(playerid, BURGLARY_NOISE_JUMP);
        }
    }

    return 1;
}
