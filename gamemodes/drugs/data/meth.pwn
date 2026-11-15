// ============================================================================
// File: drugs/data/meth.pwn
// Methamphetamine data (currently minimal).
// ============================================================================

enum E_METH_DATA {
    E_METH_TYPE,
    E_METH_NAME[32],
    E_METH_MAX_BAGS,
    Float:E_METH_DAMAGE_REDUCTION, // fraction of incoming damage blocked (0.0-1.0)
    E_METH_REGEN_INTERVAL,         // ticks between each 1 HP heal
    E_METH_CRASH_DURATION,         // seconds HP is capped after effect ends

    Float:E_METH_MIN_HAUL,
    Float:E_METH_MAX_HAUL,

    E_METH_TICKS,
    E_METH_HEX
}

enum {
    E_METH_TYPE_NONE = 0,
    E_METH_TYPE_SHAKE,
    E_METH_TYPE_CLEAR_ICE,
    E_METH_TYPE_BLUE_SKY,
    E_METH_TYPE_GLASS_CANDY
}

new Meth[][E_METH_DATA] = {
    { E_METH_TYPE_NONE,        "None",          -1, 0.0,   0,   0, 2.5, 15.0,  600, 0xFFFFFFFF },
    { E_METH_TYPE_SHAKE,       "Shake",          8, 0.15, 30, 180, 2.0, 12.5,  600, 0xB8C4AFFF },
    { E_METH_TYPE_CLEAR_ICE,   "Clear Ice",      6, 0.18, 25, 240, 1.5, 10.0, 1200, 0xBBD9E5FF },
    { E_METH_TYPE_BLUE_SKY,    "Blue Sky",       4, 0.22, 20, 300, 1.0,  7.5, 1800, 0x7EB9D4FF },
    { E_METH_TYPE_GLASS_CANDY, "Glass Candy",    2, 0.25, 15, 360, 0.5,  5.0, 2400, 0xC8E8F0FF }
} ;

#define E_METH_CRASH_HP_CAP     (70.0)
#define E_DRUG_METH_MODELID     (19590)
