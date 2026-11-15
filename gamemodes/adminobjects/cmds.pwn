// ============================================================================
// File: adminobjects/cmds.pwn
// Admin commands for placing persistent world objects (/objcreate, /objedit, /objclone,
// /objdelete, /objnear, /objgoto). This is how staff add small decorations without editing code.
// Commands: /objcreate /objpos /objnear /objgoto /objedit /objclone /objdelete
// ============================================================================

// /objcreate [modelid] - creates a new persistent object at your position and opens the editor.
CMD:objcreate(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "No access.");

    new modelid;
    if (sscanf(params, "i", modelid))
        return SendClientMessage(playerid, -1, "/objcreate [modelid]");

    new objid = AdminObject_GetFreeID();
    if (objid == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "No free slots.");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    GetXYInFrontOfPlayer(playerid, x, y, 2.5);

    AdminObject[objid][E_OBJ_SQLID] = ADMINOBJ_SETUP_ID;
    AdminObject[objid][E_OBJ_MODELID] = modelid;

    AdminObject[objid][E_OBJ_INTERIOR] = GetPlayerInterior(playerid);
    AdminObject[objid][E_OBJ_VW] = GetPlayerVirtualWorld(playerid);

    AdminObject[objid][E_OBJ_OBJECTID] = CreateDynamicObject(
        modelid, x, y, z,
        0.0, 0.0, 0.0,
        AdminObject[objid][E_OBJ_VW],
        AdminObject[objid][E_OBJ_INTERIOR],
        .priority = STREAM_PRIORITY_INTERACTABLE
    );

    AdminObject_BeginEdit(playerid, objid);

    return 1;
}

// /objpos - opens the position editor menu for the object you are editing.
CMD:objpos(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "No access.");

    if (AdminObjEdit_Obj[playerid] == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "You are not editing an object. Use /objedit [object id] or /objcreate [modelid].");

    AdminObject_ShowEditMenu(playerid);

    return 1;
}

// /objnear - lists admin objects close to you.
CMD:objnear(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "No access.");

    new objid = AdminObject_GetClosest(playerid);

    if (objid == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "No nearby objects.");

    SendClientMessage(playerid, COLOR_YELLOW,
        sprintf("[OBJ] ID %d (SQL: %d) Model: %d",
            objid,
            AdminObject[objid][E_OBJ_SQLID],
            AdminObject[objid][E_OBJ_MODELID]));

    return 1;
}

// /objgoto [id] - teleports you to an admin object.
CMD:objgoto(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "No access.");

    new objid;

    if (sscanf(params, "i", objid))
        return SendClientMessage(playerid, -1, "/objgoto [id]");

    if (AdminObject[objid][E_OBJ_SQLID] == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "Invalid object.");

    SetPlayerPos(playerid,
        AdminObject[objid][E_OBJ_X],
        AdminObject[objid][E_OBJ_Y],
        AdminObject[objid][E_OBJ_Z]);

    SetPlayerInterior(playerid, AdminObject[objid][E_OBJ_INTERIOR]);
    SetPlayerVirtualWorld(playerid, AdminObject[objid][E_OBJ_VW]);

    return 1;
}

// /objedit [object id] - starts editing an existing object.
CMD:objedit(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "No access.");

    new objid;

    if (sscanf(params, "i", objid))
        return SendClientMessage(playerid, -1, "/objedit [object id]");

    if (objid < 0 || objid >= MAX_ADMIN_OBJECTS)
        return SendClientMessage(playerid, -1, "Invalid object ID.");

    if (AdminObject[objid][E_OBJ_SQLID] == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "Object does not exist.");

    if (!IsValidDynamicObject(AdminObject[objid][E_OBJ_OBJECTID]))
        return SendClientMessage(playerid, -1, "Object is not valid.");

    SendClientMessage(playerid, -1,
        sprintf("[OBJ] Editing object ID %d", objid));

    AdminObject_BeginEdit(playerid, objid);

    return 1;
}

// /objclone [object id] - duplicates an object at your position.
CMD:objclone(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "No access.");

    new source_id;

    if (sscanf(params, "i", source_id))
        return SendClientMessage(playerid, -1, "/objclone [object id]");

    if (source_id < 0 || source_id >= MAX_ADMIN_OBJECTS)
        return SendClientMessage(playerid, -1, "Invalid object ID.");

    if (AdminObject[source_id][E_OBJ_SQLID] == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "That object does not exist.");

    new new_id = AdminObject_GetFreeID();
    if (new_id == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "No free object slots.");

    // ============================
    // COPY DATA
    // ============================
    AdminObject[new_id][E_OBJ_SQLID]   = ADMINOBJ_SETUP_ID;
    AdminObject[new_id][E_OBJ_MODELID] = AdminObject[source_id][E_OBJ_MODELID];

    AdminObject[new_id][E_OBJ_X]  = AdminObject[source_id][E_OBJ_X];
    AdminObject[new_id][E_OBJ_Y]  = AdminObject[source_id][E_OBJ_Y];
    AdminObject[new_id][E_OBJ_Z]  = AdminObject[source_id][E_OBJ_Z];

    AdminObject[new_id][E_OBJ_RX] = AdminObject[source_id][E_OBJ_RX];
    AdminObject[new_id][E_OBJ_RY] = AdminObject[source_id][E_OBJ_RY];
    AdminObject[new_id][E_OBJ_RZ] = AdminObject[source_id][E_OBJ_RZ];

    AdminObject[new_id][E_OBJ_INTERIOR] = AdminObject[source_id][E_OBJ_INTERIOR];
    AdminObject[new_id][E_OBJ_VW]       = AdminObject[source_id][E_OBJ_VW];

    // ============================
    // CREATE OBJECT
    // ============================
    AdminObject[new_id][E_OBJ_OBJECTID] = CreateDynamicObject(
        AdminObject[new_id][E_OBJ_MODELID],
        AdminObject[new_id][E_OBJ_X],
        AdminObject[new_id][E_OBJ_Y],
        AdminObject[new_id][E_OBJ_Z],
        AdminObject[new_id][E_OBJ_RX],
        AdminObject[new_id][E_OBJ_RY],
        AdminObject[new_id][E_OBJ_RZ],
        AdminObject[new_id][E_OBJ_VW],
        AdminObject[new_id][E_OBJ_INTERIOR],
        .priority = STREAM_PRIORITY_INTERACTABLE
    );

    Streamer_SetFloatData(STREAMER_TYPE_OBJECT, AdminObject[new_id][E_OBJ_OBJECTID], E_STREAMER_STREAM_DISTANCE, 500);
    Streamer_SetFloatData(STREAMER_TYPE_OBJECT, AdminObject[new_id][E_OBJ_OBJECTID], E_STREAMER_DRAW_DISTANCE, 500);

    SendClientMessage(playerid, -1,
        sprintf("[OBJ] Cloned object %d -> new ID %d", source_id, new_id));

    AdminObject_BeginEdit(playerid, new_id);

    return 1;
}

// /objdelete [object id] - removes an object from the world and the database.
CMD:objdelete(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "No access.");

    new objid;

    if (sscanf(params, "i", objid))
        return SendClientMessage(playerid, -1, "/objdelete [object id]");

    if (objid < 0 || objid >= MAX_ADMIN_OBJECTS)
        return SendClientMessage(playerid, -1, "Invalid object ID.");

    if (AdminObject[objid][E_OBJ_SQLID] == INVALID_ADMINOBJ_ID)
        return SendClientMessage(playerid, -1, "Object does not exist.");

    new query[256];

    // Delete from database
    mysql_format(mysql, query, sizeof(query),
        "DELETE FROM admin_objects WHERE object_id = %d",
        AdminObject[objid][E_OBJ_SQLID]);

    mysql_tquery(mysql, query);

    // Destroy object in-game
    if (IsValidDynamicObject(AdminObject[objid][E_OBJ_OBJECTID]))
    {
        ORP_DestroyObject(
            AdminObject[objid][E_OBJ_OBJECTID],
            "AdminObject/Delete",
            true
        );
    }

    SendClientMessage(playerid, -1,
        sprintf("[OBJ] Deleted object ID %d (SQL %d)",
            objid,
            AdminObject[objid][E_OBJ_SQLID]));

    // Reset data
    AdminObject[objid][E_OBJ_SQLID] = INVALID_ADMINOBJ_ID;

    AdminObject[objid][E_OBJ_X] = 0.0;
    AdminObject[objid][E_OBJ_Y] = 0.0;
    AdminObject[objid][E_OBJ_Z] = 0.0;

    AdminObject[objid][E_OBJ_RX] = 0.0;
    AdminObject[objid][E_OBJ_RY] = 0.0;
    AdminObject[objid][E_OBJ_RZ] = 0.0;

    return 1;
}
