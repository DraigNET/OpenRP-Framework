// ============================================================================
// File: config/data/header.pwn
// Includes the static data tables (skins, streets, zones, areas) and holds the gym entrance
// coordinates. The gym coordinates are 0,0,-30 until you place gyms on your map.
// ============================================================================

// Fixing reparse warnings
forward bool:GetMapZoneName(MapZone:id, name[], size = sizeof(name)) ;
forward MapZone:GetMapZoneAtPoint2D(Float:x, Float:y) ;
forward Float:GetPointDistanceToPoint(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2 = FLOAT_NAN, Float:z2 = FLOAT_NAN);

#include "config/data/skins.pwn"
#include "config/data/streets.pwn"
#include "config/data/zones.pwn"
#include "config/data/area.pwn"
#include "config/data/calendar.pwn"


forward Float: frandom(Float:min, Float:max, dp = 4)  ;

enum {

    NAME_FULLNAME,
    NAME_FIRSTNAME,
    NAME_LASTNAME
} ;


// ELS
#define LS_GYM_EXT_X (RuntimeLocations[RT_LOC_GYM_LS][RLOC_X]) // Cached database setting; edit through ACP.
#define LS_GYM_EXT_Y (RuntimeLocations[RT_LOC_GYM_LS][RLOC_Y]) // Cached database setting; edit through ACP.
#define LS_GYM_EXT_Z (RuntimeLocations[RT_LOC_GYM_LS][RLOC_Z]) // Cached database setting; edit through ACP.

// Little Mexico
#define SF_GYM_EXT_X (RuntimeLocations[RT_LOC_GYM_SF][RLOC_X]) // Cached database setting; edit through ACP.
#define SF_GYM_EXT_Y (RuntimeLocations[RT_LOC_GYM_SF][RLOC_Y]) // Cached database setting; edit through ACP.
#define SF_GYM_EXT_Z (RuntimeLocations[RT_LOC_GYM_SF][RLOC_Z]) // Cached database setting; edit through ACP.

// EC Gym
#define LV_GYM_EXT_X (RuntimeLocations[RT_LOC_GYM_LV][RLOC_X]) // Cached database setting; edit through ACP.
#define LV_GYM_EXT_Y (RuntimeLocations[RT_LOC_GYM_LV][RLOC_Y]) // Cached database setting; edit through ACP.
#define LV_GYM_EXT_Z (RuntimeLocations[RT_LOC_GYM_LV][RLOC_Z]) // Cached database setting; edit through ACP.

// Non enterable

#define GANTON_GYM_EXT_X (RuntimeLocations[RT_LOC_GYM_GANTON][RLOC_X]) // Cached database setting; edit through ACP.
#define GANTON_GYM_EXT_Y (RuntimeLocations[RT_LOC_GYM_GANTON][RLOC_Y]) // Cached database setting; edit through ACP.
#define GANTON_GYM_EXT_Z (RuntimeLocations[RT_LOC_GYM_GANTON][RLOC_Z]) // Cached database setting; edit through ACP.

#define BEACH_GYM_EXT_X (RuntimeLocations[RT_LOC_GYM_BEACH][RLOC_X]) // Cached database setting; edit through ACP.
#define BEACH_GYM_EXT_Y (RuntimeLocations[RT_LOC_GYM_BEACH][RLOC_Y]) // Cached database setting; edit through ACP.
#define BEACH_GYM_EXT_Z (RuntimeLocations[RT_LOC_GYM_BEACH][RLOC_Z]) // Cached database setting; edit through ACP.
