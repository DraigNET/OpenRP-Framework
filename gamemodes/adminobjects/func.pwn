// ============================================================================
// File: adminobjects/func.pwn
// The logic behind admin objects: starting an edit, applying and saving moved values, the
// mouse-based editor and the edit menu.
// ============================================================================

forward AdminObject_ShowEditMenu(playerid);

// Pushes the session's working values onto the live object.
AdminObject_ApplyEditValues(playerid)
{
    new objid = AdminObjEdit_Obj[playerid];

    if (objid == INVALID_ADMINOBJ_ID)
        return 0;

    SetDynamicObjectPos(
        AdminObject[objid][E_OBJ_OBJECTID],
        AdminObjEdit_Val[playerid][0],
        AdminObjEdit_Val[playerid][1],
        AdminObjEdit_Val[playerid][2]
    );

    ORP_SetObjectRot(
        AdminObject[objid][E_OBJ_OBJECTID],
        AdminObjEdit_Val[playerid][3],
        AdminObjEdit_Val[playerid][4],
        AdminObjEdit_Val[playerid][5],
        "AdminObject/Edit APPLY",
        true
    );

    return 1;
}

// Throws away unsaved changes: new objects are destroyed, existing ones
// snap back to their last saved position.
AdminObject_DiscardEdit(playerid)
{
    new objid = AdminObjEdit_Obj[playerid];

    AdminObjEdit_Obj[playerid] = INVALID_ADMINOBJ_ID;
    PlayerVar[playerid][E_PLAYER_IS_MOVING_GATE] = false;

    if (objid == INVALID_ADMINOBJ_ID)
        return 0;

    if (AdminObject[objid][E_OBJ_SQLID] == ADMINOBJ_SETUP_ID)
    {
        AdminObject[objid][E_OBJ_SQLID] = INVALID_ADMINOBJ_ID;

        if (IsValidDynamicObject(AdminObject[objid][E_OBJ_OBJECTID]))
        {
            ORP_DestroyObject(
                AdminObject[objid][E_OBJ_OBJECTID],
                "AdminObject/Edit CANCEL",
                true
            );
        }

        AdminObject[objid][E_OBJ_OBJECTID] = INVALID_OBJECT_ID;
    }
    else if (IsValidDynamicObject(AdminObject[objid][E_OBJ_OBJECTID]))
    {
        SetDynamicObjectPos(
            AdminObject[objid][E_OBJ_OBJECTID],
            AdminObject[objid][E_OBJ_X],
            AdminObject[objid][E_OBJ_Y],
            AdminObject[objid][E_OBJ_Z]
        );

        ORP_SetObjectRot(
            AdminObject[objid][E_OBJ_OBJECTID],
            AdminObject[objid][E_OBJ_RX],
            AdminObject[objid][E_OBJ_RY],
            AdminObject[objid][E_OBJ_RZ],
            "AdminObject/Edit CANCEL",
            true
        );
    }

    return 1;
}

// Writes the working values to the object and the database.
AdminObject_SaveEdit(playerid)
{
    new objid = AdminObjEdit_Obj[playerid];

    if (objid == INVALID_ADMINOBJ_ID)
        return 0;

    new Float:x  = AdminObjEdit_Val[playerid][0],
        Float:y  = AdminObjEdit_Val[playerid][1],
        Float:z  = AdminObjEdit_Val[playerid][2],
        Float:rx = AdminObjEdit_Val[playerid][3],
        Float:ry = AdminObjEdit_Val[playerid][4],
        Float:rz = AdminObjEdit_Val[playerid][5],
        query[512];

    AdminObjEdit_Obj[playerid] = INVALID_ADMINOBJ_ID;
    PlayerVar[playerid][E_PLAYER_IS_MOVING_GATE] = false;

    AdminObject[objid][E_OBJ_X] = x;
    AdminObject[objid][E_OBJ_Y] = y;
    AdminObject[objid][E_OBJ_Z] = z;

    AdminObject[objid][E_OBJ_RX] = rx;
    AdminObject[objid][E_OBJ_RY] = ry;
    AdminObject[objid][E_OBJ_RZ] = rz;

    SetDynamicObjectPos(AdminObject[objid][E_OBJ_OBJECTID], x, y, z);

    ORP_SetObjectRot(
        AdminObject[objid][E_OBJ_OBJECTID],
        rx, ry, rz,
        "AdminObject/Edit FINAL",
        true
    );

    if (AdminObject[objid][E_OBJ_SQLID] == ADMINOBJ_SETUP_ID)
    {
        mysql_format(mysql, query, sizeof(query),
            "INSERT INTO admin_objects (model_id,pos_x,pos_y,pos_z,rot_x,rot_y,rot_z,interior,virtual_world) VALUES (%d,'%f','%f','%f','%f','%f','%f',%d,%d)",
            AdminObject[objid][E_OBJ_MODELID],
            x, y, z,
            rx, ry, rz,
            AdminObject[objid][E_OBJ_INTERIOR],
            AdminObject[objid][E_OBJ_VW]
        );

        inline AdminObj_OnInsert()
        {
            AdminObject[objid][E_OBJ_SQLID] = cache_insert_id();

            SendClientMessage(playerid, -1,
                sprintf("[OBJ] Created ID %d (SQL %d)",
                    objid,
                    AdminObject[objid][E_OBJ_SQLID])
            );
        }

        MySQL_TQueryInline(mysql, using inline AdminObj_OnInsert, query, "");
    }
    else
    {
        mysql_format(mysql, query, sizeof(query),
            "UPDATE admin_objects SET pos_x='%f',pos_y='%f',pos_z='%f',rot_x='%f',rot_y='%f',rot_z='%f' WHERE object_id=%d",
            x, y, z,
            rx, ry, rz,
            AdminObject[objid][E_OBJ_SQLID]
        );

        mysql_tquery(mysql, query);

        SendClientMessage(playerid, -1,
            sprintf("[OBJ] Updated ID %d", objid));
    }

    return 1;
}

// Hands the object to the client's mouse editor, starting from the working values.
AdminObject_StartMouseEdit(playerid)
{
    new objid = AdminObjEdit_Obj[playerid];

    if (objid == INVALID_ADMINOBJ_ID)
        return 0;

    AdminObject_ApplyEditValues(playerid);

    PlayerVar[playerid][E_PLAYER_IS_MOVING_GATE] = true;

    EditDynamicObject(playerid, AdminObject[objid][E_OBJ_OBJECTID]);

    SendClientMessage(playerid, COLOR_YELLOW,
        "[OBJ] Mouse edit: click the arrows to move/rotate, then click the save icon (ESC to go back to the menu).");

    return 1;
}

// Prompts for one field. Prefix the number with ~ to add to the current value.
AdminObject_ShowValueInput(playerid, field)
{
    new objid = AdminObjEdit_Obj[playerid];

    if (objid == INVALID_ADMINOBJ_ID || field < 0 || field >= ADMINOBJ_EDIT_FIELDS)
        return 0;

    static const field_names[ADMINOBJ_EDIT_FIELDS][] =
        {"X", "Y", "Z", "Rotation X", "Rotation Y", "Rotation Z"};

    inline OnValue(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, listitem

        if (AdminObjEdit_Obj[playerid] != objid)
            return 1;

        if (response)
        {
            new Float:value;
            new bool:relative = (inputtext[0] == '~');

            if (sscanf(inputtext[relative ? 1 : 0], "f", value))
                SendClientMessage(playerid, COLOR_ERROR, "[OBJ] That is not a valid number.");
            else
            {
                if (relative)
                    AdminObjEdit_Val[playerid][field] += value;
                else
                    AdminObjEdit_Val[playerid][field] = value;

                AdminObject_ApplyEditValues(playerid);
            }
        }

        AdminObject_ShowEditMenu(playerid);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnValue, DIALOG_STYLE_INPUT,
        sprintf("Object Editor - %s", field_names[field]),
        sprintf("Current %s: %.4f\n\nEnter an exact value, or ~value to add to the current one (e.g. ~0.25 or ~-1).",
            field_names[field], AdminObjEdit_Val[playerid][field]),
        "Set", "Back");

    return 1;
}

// Shows the dialog menu for editing the object a player is editing (position and rotation values,
// save, discard).
public AdminObject_ShowEditMenu(playerid)
{
    new objid = AdminObjEdit_Obj[playerid];

    if (objid == INVALID_ADMINOBJ_ID)
        return 0;

    new string[384];

    format(string, sizeof(string),
        "Move with mouse\t \nX\t%.4f\nY\t%.4f\nZ\t%.4f\nRotation X\t%.4f\nRotation Y\t%.4f\nRotation Z\t%.4f\n{00FF00}Save\t \n{FF6347}Cancel (discard changes)\t ",
        AdminObjEdit_Val[playerid][0],
        AdminObjEdit_Val[playerid][1],
        AdminObjEdit_Val[playerid][2],
        AdminObjEdit_Val[playerid][3],
        AdminObjEdit_Val[playerid][4],
        AdminObjEdit_Val[playerid][5]
    );

    inline OnMenu(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, inputtext

        if (AdminObjEdit_Obj[playerid] != objid)
            return 1;

        if (!response)
        {
            SendClientMessage(playerid, COLOR_YELLOW,
                "[OBJ] Editor closed, changes not saved yet. Use /objpos to reopen it.");
            return 1;
        }

        switch (listitem)
        {
            case 0: AdminObject_StartMouseEdit(playerid);
            case 1 .. 6: AdminObject_ShowValueInput(playerid, listitem - 1);
            case 7: AdminObject_SaveEdit(playerid);
            case 8:
            {
                AdminObject_DiscardEdit(playerid);
                SendClientMessage(playerid, -1, "[OBJ] Changes discarded.");
            }
        }

        return 1;
    }

    Dialog_ShowCallback(playerid, using inline OnMenu, DIALOG_STYLE_TABLIST,
        sprintf("Object Editor - ID %d (model %d)", objid, AdminObject[objid][E_OBJ_MODELID]),
        string, "Select", "Close");

    return 1;
}

// Starts an editor session on an admin object and opens the menu.
AdminObject_BeginEdit(playerid, objid)
{
    // Don't leave a previous session half-finished.
    if (AdminObjEdit_Obj[playerid] != INVALID_ADMINOBJ_ID)
        AdminObject_DiscardEdit(playerid);

    new Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz;

    GetDynamicObjectPos(AdminObject[objid][E_OBJ_OBJECTID], x, y, z);
    GetDynamicObjectRot(AdminObject[objid][E_OBJ_OBJECTID], rx, ry, rz);

    AdminObjEdit_Obj[playerid] = objid;

    AdminObjEdit_Val[playerid][0] = x;
    AdminObjEdit_Val[playerid][1] = y;
    AdminObjEdit_Val[playerid][2] = z;
    AdminObjEdit_Val[playerid][3] = rx;
    AdminObjEdit_Val[playerid][4] = ry;
    AdminObjEdit_Val[playerid][5] = rz;

    Streamer_SetFloatData(STREAMER_TYPE_OBJECT,
        AdminObject[objid][E_OBJ_OBJECTID], E_STREAMER_STREAM_DISTANCE, 500.0);

    Streamer_SetFloatData(STREAMER_TYPE_OBJECT,
        AdminObject[objid][E_OBJ_OBJECTID], E_STREAMER_DRAW_DISTANCE, 0.0);

    AdminObject_ShowEditMenu(playerid);

    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    if (AdminObjEdit_Obj[playerid] != INVALID_ADMINOBJ_ID)
        AdminObject_DiscardEdit(playerid);

    return 1;
}

public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response,
    Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    new objid = AdminObjEdit_Obj[playerid];

    if (PlayerVar[playerid][E_PLAYER_IS_MOVING_GATE] && objid != INVALID_ADMINOBJ_ID)
    {
        if (AdminObject[objid][E_OBJ_OBJECTID] == objectid)
        {
            switch (response)
            {
                case EDIT_RESPONSE_CANCEL:
                {
                    // Back to the menu with the values from before the mouse edit.
                    PlayerVar[playerid][E_PLAYER_IS_MOVING_GATE] = false;

                    AdminObject_ApplyEditValues(playerid);
                    AdminObject_ShowEditMenu(playerid);
                }

                case EDIT_RESPONSE_FINAL:
                {
                    PlayerVar[playerid][E_PLAYER_IS_MOVING_GATE] = false;

                    AdminObjEdit_Val[playerid][0] = x;
                    AdminObjEdit_Val[playerid][1] = y;
                    AdminObjEdit_Val[playerid][2] = z;
                    AdminObjEdit_Val[playerid][3] = rx;
                    AdminObjEdit_Val[playerid][4] = ry;
                    AdminObjEdit_Val[playerid][5] = rz;

                    AdminObject_ApplyEditValues(playerid);
                    AdminObject_ShowEditMenu(playerid);
                }
            }
        }
    }

    #if defined aobj_OnPlayerEditDynObj
        return aobj_OnPlayerEditDynObj(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz);
    #else
        return 1;
    #endif
}

#if defined _ALS_OnPlayerEditDynamicObject
    #undef OnPlayerEditDynamicObject
#else
    #define _ALS_OnPlayerEditDynamicObject
#endif

#define OnPlayerEditDynamicObject aobj_OnPlayerEditDynObj

#if defined aobj_OnPlayerEditDynObj
    forward aobj_OnPlayerEditDynObj(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz);
#endif
