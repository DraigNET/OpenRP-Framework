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
#define LS_GYM_EXT_X (0.0)
#define LS_GYM_EXT_Y (0.0)
#define LS_GYM_EXT_Z (-30.0)

// Little Mexico
#define SF_GYM_EXT_X (0.0)
#define SF_GYM_EXT_Y (0.0)
#define SF_GYM_EXT_Z (-30.0)

// EC Gym
#define LV_GYM_EXT_X (0.0)
#define LV_GYM_EXT_Y (0.0)
#define LV_GYM_EXT_Z (-30.0)

// Non enterable

#define GANTON_GYM_EXT_X (0.0)
#define GANTON_GYM_EXT_Y (0.0)
#define GANTON_GYM_EXT_Z (-30.0)

#define BEACH_GYM_EXT_X (0.0)
#define BEACH_GYM_EXT_Y (0.0)
#define BEACH_GYM_EXT_Z (-30.0)
