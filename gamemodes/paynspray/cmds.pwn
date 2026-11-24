// ============================================================================
// File: paynspray/cmds.pwn
// Pay 'n' Spray garages: /repaircar fixes bodywork and tops up health for a price based on the
// damage, /collectcar and /pickupcar collect the repaired vehicle. Deliberately basic:
// respraying and engine work are mechanic jobs.
// Commands: /collectcar /pickupcar /repaircar
// ============================================================================

// Pay'n'Spray is deliberately basic and expensive: it repairs the bodywork and tops the vehicle health
// back up, nothing else. Respraying, paintjobs, oil changes and anything to do with a seized engine or
// contaminated fuel are a mechanic's job (see firm/jobs/mechanic.pwn). The price scales with what the
// vehicle cost new, and is set high enough that calling a mechanic is the better deal.

#define PNS_BODYWORK_MIN_COST (Runtime_Int(RT_REPAIRS_BODYWORK_MIN)) // Cached database setting; edit through ACP.
#define PNS_BODYWORK_PERCENT (Runtime_Int(RT_REPAIRS_BODYWORK_PERCENT)) // Cached database setting; edit through ACP.
#define PNS_ENGINE_MIN_COST (Runtime_Int(RT_REPAIRS_ENGINE_MIN)) // Cached database setting; edit through ACP.
#define PNS_ENGINE_PERCENT          (8)

// Returns a repair price as a percentage of the vehicle's catalogue price, with a minimum.
static PNS_ScaledCost(vehicleid, minimum, percent)
{
    new price = Vehicle_GetCatalogPrice(GetVehicleModel(vehicleid));
    new cost = price * percent / 100;

    return (cost < minimum) ? minimum : cost;
}

// Returns the price of repairing a vehicle's bodywork.
PNS_GetBodyworkCost(vehicleid)
{
    return PNS_ScaledCost(vehicleid, PNS_BODYWORK_MIN_COST, PNS_BODYWORK_PERCENT);
}

// Returns the price of repairing a vehicle's engine.
PNS_GetEngineCost(vehicleid)
{
    return PNS_ScaledCost(vehicleid, PNS_ENGINE_MIN_COST, PNS_ENGINE_PERCENT);
}

// Whoever owns a vehicle, holds a spare key to it or belongs to the firm that owns it can leave it at the
// workshop and collect it again.
static bool: PNS_CanHandleVehicle(playerid, veh_enum_id)
{
    switch (Vehicle[veh_enum_id][E_VEHICLE_TYPE])
    {
        case E_VEHICLE_TYPE_PLAYER:
            return Vehicle[veh_enum_id][E_VEHICLE_OWNER] == Character[playerid][E_CHARACTER_ID] || HasCarDuplicateKey(playerid, veh_enum_id);

        case E_VEHICLE_TYPE_FIRM:
            return IsPlayerInFirm(playerid, Vehicle[veh_enum_id][E_VEHICLE_OWNER]);
    }

    return false;
}

#define PNS_JOB_BODYWORK    (0)
#define PNS_JOB_HEALTH      (1)

// The repair is done to the vehicle's saved record and then the vehicle leaves the game for
// PNS_REPAIR_SECONDS. Everyone in it is put out first.
static PNS_TakeIntoWorkshop(playerid, vehicleid, veh_enum_id, job)
{
    new Float:x, Float:y, Float:z, Float:a, Float:health;

    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, a);
    GetVehicleHealth(vehicleid, health);

    Vehicle[veh_enum_id][E_VEHICLE_POS_X] = x;
    Vehicle[veh_enum_id][E_VEHICLE_POS_Y] = y;
    Vehicle[veh_enum_id][E_VEHICLE_POS_Z] = z;
    Vehicle[veh_enum_id][E_VEHICLE_POS_A] = a;
    Vehicle[veh_enum_id][E_VEHICLE_VW]    = GetVehicleVirtualWorld(vehicleid);
    Vehicle[veh_enum_id][E_VEHICLE_INT]   = GetPlayerInterior(playerid);

    if (job == PNS_JOB_BODYWORK)
    {
        // Body panels, doors, lights and tyres are fixed, health stays as it is.
        Vehicle[veh_enum_id][E_VEHICLE_DMG_PANELS] = 0;
        Vehicle[veh_enum_id][E_VEHICLE_DMG_DOORS]  = 0;
        Vehicle[veh_enum_id][E_VEHICLE_DMG_LIGHTS] = 0;
        Vehicle[veh_enum_id][E_VEHICLE_DMG_TIRES]  = 0;
        Vehicle[veh_enum_id][E_VEHICLE_HEALTH]     = health;
    }
    else
    {
        Vehicle[veh_enum_id][E_VEHICLE_HEALTH] = 999.0;
    }

    Vehicle[veh_enum_id][E_VEHICLE_REPAIR_READY] = gettime() + PNS_REPAIR_SECONDS;

    foreach (new i : Player)
    {
        if (IsPlayerInVehicle(i, vehicleid))
            JT_RemovePlayerFromVehicle(i);
    }

    Vehicle_DespawnRecord(veh_enum_id);

    PlayerPlaySound(playerid, 1134, 0,0,0);
    GameTextForPlayer(playerid, "~g~Vehicle taken in!", 2000, 3);
    SendClientMessage(playerid, COLOR_VEHICLE, sprintf("The workshop has taken your %s in. It will be ready in %d seconds, come back and use /collectcar (Pay'n'Spray) to get it.",
        ReturnVehicleModelName(Vehicle[veh_enum_id][E_VEHICLE_MODELID]), PNS_REPAIR_SECONDS));

    return 1;
}

// Brings a repaired vehicle back to the spot it was left at.
CMD:collectcar(playerid, params[])
{
    if (!IsPlayerNearPayNSpray(playerid))
        return GameTextForPlayer(playerid, "~n~~n~~n~~w~You must be at the Pay'n'Spray you left it at.", 2000, 4);

    if (IsPlayerInAnyVehicle(playerid))
        return SendClientMessage(playerid, COLOR_ERROR, "Get out of your vehicle first.");

    new sqlid, count, only = -1;

    for (new i, j = sizeof(Vehicle); i < j; i++)
    {
        if (!Vehicle_IsInWorkshop(i) || !PNS_CanHandleVehicle(playerid, i))
            continue;

        count++;
        only = i;
    }

    if (!count)
        return SendClientMessage(playerid, COLOR_ERROR, "You don't have any vehicles in the workshop.");

    if (sscanf(params, "i", sqlid))
    {
        if (count == 1)
        {
            sqlid = Vehicle[only][E_VEHICLE_SQLID];
        }
        else
        {
            SendClientMessage(playerid, COLOR_GRAD0, "/collectcar [vehicle id]");

            for (new i, j = sizeof(Vehicle); i < j; i++)
            {
                if (!Vehicle_IsInWorkshop(i) || !PNS_CanHandleVehicle(playerid, i))
                    continue;

                new left = Vehicle_RepairSecondsLeft(i);

                if (left > 0)
                    SendClientMessage(playerid, COLOR_GRAD0, sprintf("  ID %d: %s - ready in %d seconds", Vehicle[i][E_VEHICLE_SQLID], ReturnVehicleModelName(Vehicle[i][E_VEHICLE_MODELID]), left));
                else
                    SendClientMessage(playerid, COLOR_GRAD0, sprintf("  ID %d: %s - ready", Vehicle[i][E_VEHICLE_SQLID], ReturnVehicleModelName(Vehicle[i][E_VEHICLE_MODELID])));
            }

            return 1;
        }
    }

    new veh_enum_id = Vehicle_GetEnumIDFromSQLID(sqlid);

    if (veh_enum_id == -1 || !Vehicle_IsInWorkshop(veh_enum_id) || !PNS_CanHandleVehicle(playerid, veh_enum_id))
        return SendClientMessage(playerid, COLOR_ERROR, "That vehicle isn't in the workshop.");

    new left = Vehicle_RepairSecondsLeft(veh_enum_id);

    if (left > 0)
        return SendClientMessage(playerid, COLOR_ERROR, sprintf("Your %s isn't ready yet, it needs another %d seconds.", ReturnVehicleModelName(Vehicle[veh_enum_id][E_VEHICLE_MODELID]), left));

    if (!IsPlayerInRangeOfPoint(playerid, 80.0, Vehicle[veh_enum_id][E_VEHICLE_POS_X], Vehicle[veh_enum_id][E_VEHICLE_POS_Y], Vehicle[veh_enum_id][E_VEHICLE_POS_Z]))
        return SendClientMessage(playerid, COLOR_ERROR, "That vehicle is waiting at a different Pay'n'Spray.");

    if (IsValidVehicle(Vehicle[veh_enum_id][E_VEHICLE_ID]))
        return SendClientMessage(playerid, COLOR_ERROR, "That vehicle is already out.");

    new new_id = Vehicle_SpawnRecord(veh_enum_id, Vehicle[veh_enum_id][E_VEHICLE_POS_X], Vehicle[veh_enum_id][E_VEHICLE_POS_Y], Vehicle[veh_enum_id][E_VEHICLE_POS_Z],
        Vehicle[veh_enum_id][E_VEHICLE_POS_A], Vehicle[veh_enum_id][E_VEHICLE_VW], Vehicle[veh_enum_id][E_VEHICLE_INT], -1);

    if (!IsValidVehicle(new_id))
        return SendClientMessage(playerid, COLOR_ERROR, "The vehicle couldn't be brought out right now, try again in a moment.");

    Vehicle_ClearRepair(veh_enum_id);

    PlayerPlaySound(playerid, 1134, 0,0,0);
    SendClientMessage(playerid, COLOR_VEHICLE, sprintf("Your %s is ready and waiting where you left it.", ReturnVehicleModelName(Vehicle[veh_enum_id][E_VEHICLE_MODELID])));

    return 1;
}

CMD:pickupcar(playerid, params[]) return cmd_collectcar(playerid, params);

// /repaircar - at a Pay 'n' Spray, pays to have the vehicle repaired; it goes into the workshop
// for a while.
CMD:repaircar(playerid, params[])
{
    if (!IsPlayerNearPayNSpray(playerid))
        return GameTextForPlayer(playerid, "~n~~n~~n~~w~You must be at a Pay'n'Spray.", 2000, 4);

    if (!IsPlayerInAnyVehicle(playerid))
        return GameTextForPlayer(playerid, "~n~~n~~n~~w~You must be in a vehicle!", 2000, 4);

    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        return GameTextForPlayer(playerid, "~n~~n~~n~~w~You must be the driver!", 2000, 4);

    new vehicleid = GetPlayerVehicleID(playerid);
    new list[160];

    if (IsPlayerInAnyGovFaction(playerid, true))
    {
        format(list, sizeof(list), "Repair Bodywork (free)\nRepair Vehicle Health (free)");
    }
    else
    {
        format(list, sizeof(list), "Repair Bodywork ($%s)\nRepair Vehicle Health ($%s)",
            IntegerWithDelimiter(PNS_GetBodyworkCost(vehicleid)), IntegerWithDelimiter(PNS_GetEngineCost(vehicleid)));
    }

    ShowPlayerDialog(playerid, DIALOG_PNS_MAIN, DIALOG_STYLE_LIST,
        "Pay'n'Spray - bodywork and health only",
        list,
        "Select",
        "Close"
    );

    SendClientMessage(playerid, COLOR_GRAD0, sprintf("Your vehicle is taken in and can be collected with /collectcar after %d seconds.", PNS_REPAIR_SECONDS));
    SendClientMessage(playerid, COLOR_GRAD0, "Painting, oil changes and engine rebuilds are a mechanic's job.");

    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (!response) return 1;

    new query[512];

    if (dialogid == DIALOG_PNS_MAIN)
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        new veh_enum_id = Vehicle_GetEnumID(vehicleid);

        if (veh_enum_id == -1) return 1;

        if (!IsPlayerNearPayNSpray(playerid) || GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
            return GameTextForPlayer(playerid, "~n~~n~~n~~w~You must stay at the Pay'n'Spray.", 2000, 4);

        // Your own cars (and your firm's) are left at the workshop and collected later. Other vehicles,
        // such as faction cars, are still repaired on the spot.
        new bool:workshop = (Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_PLAYER || Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FIRM);

        if (workshop && !PNS_CanHandleVehicle(playerid, veh_enum_id))
            return SendClientMessage(playerid, COLOR_ERROR, "You can only leave your own vehicle, or your firm's, at the workshop.");

        switch (listitem)
        {
            // ==========================================
            // BODYWORK REPAIR
            // ==========================================
            case 0:
            {
                new cost = PNS_GetBodyworkCost(vehicleid);
                if (IsPlayerInAnyGovFaction(playerid, true)) cost = 0;

                if (GetPlayerCash(playerid) < cost)
                    return GameTextForPlayer(playerid, "~r~You don't have enough money!", 2000, 4);

                TakePlayerCash(playerid, cost, "Pay N Spray bodywork");

                if (workshop)
                {
                    SendClientMessage(playerid, COLOR_VEHICLE, sprintf("Bodywork repair: $%s.", IntegerWithDelimiter(cost)));
                    return PNS_TakeIntoWorkshop(playerid, vehicleid, veh_enum_id, PNS_JOB_BODYWORK);
                }

                new Float:health;
                GetVehicleHealth(vehicleid, health);

                ORP_RepairVehicle(vehicleid);

                new panels, doors, lights, tires;
                GetVehicleDamageStatus(vehicleid, panels, doors, lights, tires);

                Vehicle[veh_enum_id][E_VEHICLE_DMG_PANELS] = panels;
                Vehicle[veh_enum_id][E_VEHICLE_DMG_DOORS]  = doors;
                Vehicle[veh_enum_id][E_VEHICLE_DMG_LIGHTS] = lights;
                Vehicle[veh_enum_id][E_VEHICLE_DMG_TIRES]  = tires;

                ORP_SetVehicleHealth(vehicleid, health);
                Vehicle[veh_enum_id][E_VEHICLE_HEALTH] = health;

                mysql_format(mysql, query, sizeof(query),
                    "UPDATE vehicles SET vehicle_dmg_panels=%d, vehicle_dmg_doors=%d, vehicle_dmg_lights=%d, vehicle_dmg_tires=%d, vehicle_health='%f' WHERE vehicle_sqlid=%d",
                    panels, doors, lights, tires, health,
                    Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
                mysql_tquery(mysql, query);

                PlayerPlaySound(playerid, 1134, 0,0,0);
                GameTextForPlayer(playerid, "~g~Bodywork Repaired!", 2000, 3);
                SendClientMessage(playerid, COLOR_VEHICLE, sprintf("Bodywork repaired for $%s.", IntegerWithDelimiter(cost)));
            }

            // ==========================================
            // VEHICLE HEALTH
            // ==========================================
            case 1:
            {
                // A seized engine or contaminated fuel can't be sorted out here: those need a mechanic.
                if (Oil_IsSeized(veh_enum_id))
                    return SendClientMessage(playerid, COLOR_ERROR, "The engine has seized from worn-out oil. The Pay'n'Spray can't fix that, you need a mechanic.");

                if (VehicleVar[veh_enum_id][E_VEHICLE_WRONG_FUEL_AMOUNT] > 0)
                    return SendClientMessage(playerid, COLOR_ERROR, "The tank is contaminated with the wrong fuel. The Pay'n'Spray can't fix that, you need a mechanic to drain it.");

                new cost = PNS_GetEngineCost(vehicleid);
                if (IsPlayerInAnyGovFaction(playerid, true)) cost = 0;

                if (GetPlayerCash(playerid) < cost)
                    return GameTextForPlayer(playerid, "~r~You don't have enough money!", 2000, 4);

                TakePlayerCash(playerid, cost, "Pay N Spray vehicle health");

                if (workshop)
                {
                    SendClientMessage(playerid, COLOR_VEHICLE, sprintf("Vehicle health repair: $%s.", IntegerWithDelimiter(cost)));
                    return PNS_TakeIntoWorkshop(playerid, vehicleid, veh_enum_id, PNS_JOB_HEALTH);
                }

                Vehicle[veh_enum_id][E_VEHICLE_HEALTH] = 999.0;
                ORP_SetVehicleHealth(vehicleid, 999.0);

                mysql_format(mysql, query, sizeof(query),
                    "UPDATE vehicles SET vehicle_health='%f' WHERE vehicle_sqlid=%d",
                    1000.0,
                    Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
                mysql_tquery(mysql, query);

                PlayerPlaySound(playerid, 1134, 0,0,0);
                GameTextForPlayer(playerid, "~g~Vehicle Health Restored!", 2000, 3);
                SendClientMessage(playerid, COLOR_VEHICLE, sprintf("Vehicle health restored for $%s.", IntegerWithDelimiter(cost)));
            }
        }
    }

    if (dialogid == DIALOG_MECHANIC_COLOR_EXT || dialogid == DIALOG_MECHANIC_COLOR_INT)
    {
        if (!response)
        {
            PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET] = INVALID_VEHICLE_ID;
            return 1;
        }

        if (!IsNumeric(inputtext)) return 1;

        new color = strval(inputtext);
        if (color < 0 || color > 255)
            return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "Invalid color. Use 0-255."), 1;

        new vehicleid = PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET];
        if (!IsValidVehicle(vehicleid)) return 1;

        new timer = Mechanic_GetTimer(playerid);
        new jobtype = (dialogid == DIALOG_MECHANIC_COLOR_EXT) ? MECH_JOB_RESPRAY_EXT : MECH_JOB_RESPRAY_INT;

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = jobtype;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM]   = color;

        Mechanic_BeginWork(playerid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Respraying vehicle %d - estimated time: %ds.", vehicleid, timer));

        return 1;
    }

    if (dialogid == DIALOG_MECHANIC_PAINTJOB)
    {
        if (!response)
        {
            PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET] = INVALID_VEHICLE_ID;
            return 1;
        }

        new vehicleid = PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET];
        if (!IsValidVehicle(vehicleid)) return 1;

        new timer = Mechanic_GetTimer(playerid);

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_PAINTJOB;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM]   = listitem;

        Mechanic_BeginWork(playerid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Applying paintjob %d to vehicle %d - estimated time: %ds.", listitem, vehicleid, timer));

        return 1;
    }

    return 1;
}
