// ============================================================================
// File: adminobjects/data.pwn
// Data for admin-placed objects: the object table, loading from the database
// (AdminObject_LoadEntities) and the per-player edit session.
// ============================================================================

enum E_ADMINOBJ_DATA {

    E_OBJ_SQLID,

    E_OBJ_MODELID,

    Float:E_OBJ_X,
    Float:E_OBJ_Y,
    Float:E_OBJ_Z,

    Float:E_OBJ_RX,
    Float:E_OBJ_RY,
    Float:E_OBJ_RZ,

    E_OBJ_OBJECTID,
    E_OBJ_INTERIOR,
    E_OBJ_VW
};

#if !defined MAX_ADMIN_OBJECTS
    #define MAX_ADMIN_OBJECTS 500
#endif

#if !defined INVALID_ADMINOBJ_ID
    #define INVALID_ADMINOBJ_ID -1
#endif

#if !defined ADMINOBJ_SETUP_ID
    #define ADMINOBJ_SETUP_ID MAX_ADMIN_OBJECTS + 1
#endif

new AdminObject[MAX_ADMIN_OBJECTS][E_ADMINOBJ_DATA];

// Per-player editor session: which admin object is being edited and the
// working (unsaved) values. Index 0-2 = x/y/z, 3-5 = rx/ry/rz.
#define ADMINOBJ_EDIT_FIELDS 6

new AdminObjEdit_Obj[MAX_PLAYERS] = {INVALID_ADMINOBJ_ID, ...};
new Float:AdminObjEdit_Val[MAX_PLAYERS][ADMINOBJ_EDIT_FIELDS];

// Returns the first unused admin object slot, or INVALID_ADMINOBJ_ID if full.
AdminObject_GetFreeID()
{
    for (new i; i < MAX_ADMIN_OBJECTS; i++)
    {
        if (AdminObject[i][E_OBJ_SQLID] == INVALID_ADMINOBJ_ID)
            return i;
    }
    return INVALID_ADMINOBJ_ID;
}

// Returns the id of the admin object closest to the player.
AdminObject_GetClosest(playerid)
{
    for (new i; i < MAX_ADMIN_OBJECTS; i++)
    {
        if (AdminObject[i][E_OBJ_SQLID] == INVALID_ADMINOBJ_ID)
            continue;

        if (IsPlayerInRangeOfPoint(playerid, 5.0,
            AdminObject[i][E_OBJ_X],
            AdminObject[i][E_OBJ_Y],
            AdminObject[i][E_OBJ_Z]))
        {
            return i;
        }
    }
    return INVALID_ADMINOBJ_ID;
}

// Loads all admin objects from the database and creates them in the world.
AdminObject_LoadEntities()
{
    for (new i; i < MAX_ADMIN_OBJECTS; i++)
    {
        AdminObject[i][E_OBJ_SQLID] = INVALID_ADMINOBJ_ID;
    }

    print("* [ADMIN OBJECTS] Loading...");

    inline OnLoad()
    {
        for (new i = 0, r = cache_num_rows(); i < r; i++)
        {
            cache_get_value_int(i, "object_id", AdminObject[i][E_OBJ_SQLID]);
            cache_get_value_int(i, "model_id", AdminObject[i][E_OBJ_MODELID]);

            cache_get_value_float(i, "pos_x", AdminObject[i][E_OBJ_X]);
            cache_get_value_float(i, "pos_y", AdminObject[i][E_OBJ_Y]);
            cache_get_value_float(i, "pos_z", AdminObject[i][E_OBJ_Z]);

            cache_get_value_float(i, "rot_x", AdminObject[i][E_OBJ_RX]);
            cache_get_value_float(i, "rot_y", AdminObject[i][E_OBJ_RY]);
            cache_get_value_float(i, "rot_z", AdminObject[i][E_OBJ_RZ]);

            cache_get_value_int(i, "interior", AdminObject[i][E_OBJ_INTERIOR]);
            cache_get_value_int(i, "virtual_world", AdminObject[i][E_OBJ_VW]);

            AdminObject[i][E_OBJ_OBJECTID] = CreateDynamicObject(
                AdminObject[i][E_OBJ_MODELID],
                AdminObject[i][E_OBJ_X],
                AdminObject[i][E_OBJ_Y],
                AdminObject[i][E_OBJ_Z],
                AdminObject[i][E_OBJ_RX],
                AdminObject[i][E_OBJ_RY],
                AdminObject[i][E_OBJ_RZ],
                AdminObject[i][E_OBJ_VW],
                AdminObject[i][E_OBJ_INTERIOR],
                .priority = STREAM_PRIORITY_INTERACTABLE
            );

            Streamer_SetFloatData(STREAMER_TYPE_OBJECT, AdminObject[i][E_OBJ_OBJECTID], E_STREAMER_STREAM_DISTANCE, 500);
            Streamer_SetFloatData(STREAMER_TYPE_OBJECT, AdminObject[i][E_OBJ_OBJECTID], E_STREAMER_DRAW_DISTANCE, 500);
        }

        printf("* [ADMIN OBJECTS] Loaded %d objects.", cache_num_rows());
    }

    MySQL_TQueryInline(mysql, using inline OnLoad, "SELECT * FROM admin_objects", "");

    return 1;
}
