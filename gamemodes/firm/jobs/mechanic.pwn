// ============================================================================
// File: firm/jobs/mechanic.pwn
// Mechanic firm field: repair and tuning jobs (/mechanic, /mtunestart, /mcancel, /mstats),
// levelling that shortens job times, and the work progress bar.
// Commands: /mechanic /mtunestart /mcancel /mstats
// ============================================================================


// The floor must stay BELOW the base minus the max possible reduction, or
// every level clamps to the same time and levelling stops meaning anything
// (that was the bug here: base 30 - reduction was already under the old
// floor of 60 at every level, so the timer never actually changed).
#define MECHANIC_BASE_TIMER         60     // seconds at level 1
#define MECHANIC_TIMER_REDUCTION    10      // seconds reduced per level
#define MECHANIC_MIN_TIMER          15      // floor (seconds) - reached at level 5 (60 - 4*10 = 20, above the floor; floor just protects against MAX_LEVEL increasing later)
#define MECHANIC_MAX_LEVEL          5


stock MECHANIC_LEVEL_THRESHOLDS[MECHANIC_MAX_LEVEL + 1] = { 0, 0, 10, 25, 50, 100 };

#define MECH_JOB_NONE               0
#define MECH_JOB_BODYWORK           1
#define MECH_JOB_ENGINE             2
#define MECH_JOB_TUNE_COMPONENT     3
#define MECH_JOB_RESPRAY_EXT        4
#define MECH_JOB_RESPRAY_INT        5
#define MECH_JOB_PAINTJOB           6
#define MECH_JOB_REMOVE_PAINTJOB    7
#define MECH_JOB_DRAIN_FUEL         8
#define MECH_JOB_OIL_CHANGE         9

// Draining a contaminated tank always takes a full minute, whatever the mechanic's level, with a progress bar.
#define MECH_DRAIN_SECONDS          60

#define MAX_VEHICLES_COMPONENTS (194)
#define MAX_VEHICLE_COMPONENT_NAME (64)
#define MAX_COMPONENT_TYPES	(14)
#define MAX_VEHICLES_MODELS (212)
#define MAX_VEHICLE_COMPONENTS (48)
#define INVALID_VEHICLE_COMPONENT_ID (-1)

// Returns how long a repair takes for the mechanic's level (higher levels are faster).
stock Mechanic_GetTimer(playerid)
{
    new level = Character[playerid][E_CHARACTER_MECHANIC_LEVEL];
    if (level < 1) level = 1;
    if (level > MECHANIC_MAX_LEVEL) level = MECHANIC_MAX_LEVEL;

    new timer = MECHANIC_BASE_TIMER - ((level - 1) * MECHANIC_TIMER_REDUCTION);
    if (timer < MECHANIC_MIN_TIMER) timer = MECHANIC_MIN_TIMER;

    return timer;
}

// Returns true if the mechanic is currently working on a job.
stock bool:MechanicIsBusy(playerid)
{
    return (PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE] != MECH_JOB_NONE);
}

new PlayerBar: Mechanic_DrainBar[MAX_PLAYERS] = PlayerBar: INVALID_PLAYER_BAR_ID;

// Removes the mechanic's job progress bar.
Mechanic_HideDrainBar(playerid)
{
    if (Mechanic_DrainBar[playerid] != PlayerBar: INVALID_PLAYER_BAR_ID)
    {
        DestroyPlayerProgressBar(playerid, Mechanic_DrainBar[playerid]);
        Mechanic_DrainBar[playerid] = PlayerBar: INVALID_PLAYER_BAR_ID;
    }
}

// Shows the mechanic's job progress bar.
Mechanic_ShowDrainBar(playerid)
{
    Mechanic_HideDrainBar(playerid);

    Mechanic_DrainBar[playerid] = CreatePlayerProgressBar(playerid, 245.0, 395.0, 150.0, 8.0, 0xE67E22FF, float(MECH_DRAIN_SECONDS));
    SetPlayerProgressBarValue(playerid, Mechanic_DrainBar[playerid], 0.0);
    ShowPlayerProgressBar(playerid, Mechanic_DrainBar[playerid]);
}

// Credits a finished job: adds XP and levels the mechanic up at thresholds.
stock Mechanic_AwardJob(playerid)
{
    Character[playerid][E_CHARACTER_MECHANIC_JOBS_DONE]++;
    Character[playerid][E_CHARACTER_MECHANIC_XP]++;  // 1 XP per job for now

    new jobs = Character[playerid][E_CHARACTER_MECHANIC_JOBS_DONE];
    new level = Character[playerid][E_CHARACTER_MECHANIC_LEVEL];

    if (level < MECHANIC_MAX_LEVEL)
    {
        if (jobs >= MECHANIC_LEVEL_THRESHOLDS[level + 1])
        {
            Character[playerid][E_CHARACTER_MECHANIC_LEVEL]++;
            new newlevel = Character[playerid][E_CHARACTER_MECHANIC_LEVEL];
            new newtimer = Mechanic_GetTimer(playerid);

            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
                sprintf("You've levelled up! You are now Mechanic Level %d. Your job timer is now %ds.", newlevel, newtimer));
        }
    }

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE characters SET character_mechanic_xp=%d, character_mechanic_level=%d, character_mechanic_jobs_done=%d WHERE player_id=%d",
        Character[playerid][E_CHARACTER_MECHANIC_XP],
        Character[playerid][E_CHARACTER_MECHANIC_LEVEL],
        Character[playerid][E_CHARACTER_MECHANIC_JOBS_DONE],
        Character[playerid][E_CHARACTER_ID]);
    mysql_tquery(mysql, query);
}

// Freeze the mechanic in a looping under-the-hood animation while a job runs.
Mechanic_BeginWork(playerid)
{
    // Working from inside a vehicle (passenger): skip the on-foot anim/freeze.
    if (IsPlayerInAnyVehicle(playerid)) return;

    TogglePlayerControllable(playerid, false);
    ApplyAnimation(playerid, "CAR", "FIXN_CAR_LOOP", 4.1, 1, 0, 0, 0, 0, 1);
    PlayerVar[playerid][E_PLAYER_LOOPING_ANIM] = 1;
}

// Release the mechanic once a job finishes or is cancelled.
Mechanic_EndWork(playerid)
{
    Mechanic_HideDrainBar(playerid);

    PlayerVar[playerid][E_PLAYER_LOOPING_ANIM] = 0;

    if (!IsPlayerInAnyVehicle(playerid))
        ClearAnimations(playerid, 1);

    TogglePlayerControllable(playerid, true);
}

// Cancels the mechanic's current job and clears their state.
Mechanic_CancelJob(playerid)
{
    if (!MechanicIsBusy(playerid)) return;

    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_NONE;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = INVALID_VEHICLE_ID;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = 0;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM]   = 0;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM2]  = 0;

    Mechanic_EndWork(playerid);

    SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "Your current job has been cancelled.");
}

//ptask player_constant_tick
Mechanic_Tick(playerid)
{
    if (!MechanicIsBusy(playerid)) return;

    // Lost mechanic access mid-job (went off duty, firm closed, etc.) - release them.
    if (!CanUseMechanicTools(playerid))
    {
        Mechanic_CancelJob(playerid);
        return;
    }

    new jobtype   = PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE];
    new vehicleid = PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET];

    if (!IsValidVehicle(vehicleid))
    {
        Mechanic_CancelJob(playerid);
        return;
    }

    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]--;

    new ticks_left = PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS];

    new hintstr[64];

    if (jobtype == MECH_JOB_DRAIN_FUEL)
    {
        if (Mechanic_DrainBar[playerid] != PlayerBar: INVALID_PLAYER_BAR_ID)
            SetPlayerProgressBarValue(playerid, Mechanic_DrainBar[playerid], float(MECH_DRAIN_SECONDS - ticks_left));

        format(hintstr, sizeof(hintstr), "~w~Draining the tank... ~r~%ds", ticks_left);
    }
    else
    {
        format(hintstr, sizeof(hintstr), "~w~Working... ~r~%ds", ticks_left);
    }

    GameTextForPlayer(playerid, hintstr, 1100, 17);

    if (ticks_left > 0) return;

    // JOB COMPLETE

    Mechanic_EndWork(playerid);

    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_NONE;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]  = 0;

    new param  = PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM];

    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = INVALID_VEHICLE_ID;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM]   = 0;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM2]  = 0;

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);
    new query[512];

    switch (jobtype)
    {
        case MECH_JOB_BODYWORK:
        {
            if (veh_enum_id == -1) return;

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

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "Bodywork repaired successfully.");
        }
        case MECH_JOB_ENGINE:
        {
            if (veh_enum_id == -1) return;

            Vehicle[veh_enum_id][E_VEHICLE_HEALTH] = 999.0;
            ORP_SetVehicleHealth(vehicleid, 999.0);

            mysql_format(mysql, query, sizeof(query),
                "UPDATE vehicles SET vehicle_health='%f' WHERE vehicle_sqlid=%d",
                1000.0,
                Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
            mysql_tquery(mysql, query);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);

            if (VehicleVar[veh_enum_id][E_VEHICLE_WRONG_FUEL_AMOUNT] > 0)
                SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "The tank is still contaminated with the wrong fuel, so it will blow again. Drain it first with /mechanic drainfuel.");

            // A worn or seized engine (from overdue oil) is rebuilt as part of the same job.
            if (Vehicle[veh_enum_id][E_VEHICLE_ENGINE_WEAR] > 0)
            {
                new bool:was_seized = Oil_IsSeized(veh_enum_id);

                Oil_RebuildEngine(veh_enum_id);

                SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", was_seized
                    ? "Engine rebuilt and repaired successfully, it turns over again."
                    : "Engine repaired and the wear on it has been rebuilt.");

                if (Oil_GetOverdue(veh_enum_id) > 0)
                    SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "The oil is still past due - change it with /mechanic oilchange or the engine will wear out again.");
            }
            else
            {
                SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "Engine repaired successfully.");
            }
        }
        case MECH_JOB_OIL_CHANGE:
        {
            if (veh_enum_id == -1) return;

            Oil_ChangeOil(veh_enum_id);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
                sprintf("Oil changed. The next oil change is due in %d miles.", OIL_SERVICE_INTERVAL));
        }
        case MECH_JOB_TUNE_COMPONENT:
        {
            new componentid = param;
            new component_name[MAX_VEHICLE_COMPONENT_NAME];
            GetVehicleComponentName(componentid, component_name, sizeof(component_name));

            Tune_AddVehicleComponent(playerid, vehicleid, componentid);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
                sprintf("Installed \"%s\" on the vehicle.", component_name));
        }
        case MECH_JOB_RESPRAY_EXT:
        {
            if (veh_enum_id == -1) return;

            Vehicle[veh_enum_id][E_VEHICLE_COLOR_A] = param;

            ChangeVehicleColorEx(vehicleid,
                Vehicle[veh_enum_id][E_VEHICLE_COLOR_A],
                Vehicle[veh_enum_id][E_VEHICLE_COLOR_B]);

            mysql_format(mysql, query, sizeof(query),
                "UPDATE vehicles SET vehicle_color_a=%d WHERE vehicle_sqlid=%d",
                param,
                Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
            mysql_tquery(mysql, query);

            format(query, sizeof(query),
                "[MECHANIC] %s (%d) resprayed vehicle %d exterior to color %d",
                Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid,
                Vehicle[veh_enum_id][E_VEHICLE_SQLID], param);
            SendAdminMessage(query);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "Exterior respray complete.");
        }
        case MECH_JOB_RESPRAY_INT:
        {
            if (veh_enum_id == -1) return;

            Vehicle[veh_enum_id][E_VEHICLE_COLOR_B] = param;

            ChangeVehicleColorEx(vehicleid,
                Vehicle[veh_enum_id][E_VEHICLE_COLOR_A],
                Vehicle[veh_enum_id][E_VEHICLE_COLOR_B]);

            mysql_format(mysql, query, sizeof(query),
                "UPDATE vehicles SET vehicle_color_b=%d WHERE vehicle_sqlid=%d",
                param,
                Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
            mysql_tquery(mysql, query);

            format(query, sizeof(query),
                "[MECHANIC] %s (%d) resprayed vehicle %d interior to color %d",
                Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid,
                Vehicle[veh_enum_id][E_VEHICLE_SQLID], param);
            SendAdminMessage(query);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "Interior respray complete.");
        }
        case MECH_JOB_PAINTJOB:
        {
            if (veh_enum_id == -1) return;

            ChangeVehiclePaintjob(vehicleid, param);
            Vehicle[veh_enum_id][E_VEHICLE_PAINTJOB] = param;

            mysql_format(mysql, query, sizeof(query),
                "UPDATE vehicles SET vehicle_paintjob=%d WHERE vehicle_sqlid=%d",
                param,
                Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
            mysql_tquery(mysql, query);

            format(query, sizeof(query),
                "[MECHANIC] %s (%d) applied paintjob %d to vehicle %d",
                Account[playerid][E_PLAYER_ACCOUNT_NAME], playerid,
                param, Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
            SendAdminMessage(query);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "Paintjob applied.");
        }
        case MECH_JOB_REMOVE_PAINTJOB:
        {
            if (veh_enum_id == -1) return;

            ChangeVehiclePaintjob(vehicleid, 3);
            Vehicle[veh_enum_id][E_VEHICLE_PAINTJOB] = 3;

            mysql_format(mysql, query, sizeof(query),
                "UPDATE vehicles SET vehicle_paintjob=%d WHERE vehicle_sqlid=%d",
                3,
                Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
            mysql_tquery(mysql, query);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "Paintjob removed.");
        }
        case MECH_JOB_DRAIN_FUEL:
        {
            if (veh_enum_id == -1) return;

            Vehicle[veh_enum_id][E_VEHICLE_FUEL] = 0;
            VehicleVar[veh_enum_id][E_VEHICLE_WRONG_FUEL_AMOUNT] = 0;

            mysql_format(mysql, query, sizeof(query),
                "UPDATE vehicles SET vehicle_fuel=0, vehicle_wrong_fuel_amount=0 WHERE vehicle_sqlid=%d",
                Vehicle[veh_enum_id][E_VEHICLE_SQLID]);
            mysql_tquery(mysql, query);

            PlayerPlaySound(playerid, 1134, 0.0, 0.0, 0.0);
            SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE", "Fuel tank drained. The owner can now refill it with fresh fuel of the right type.");
        }
    }

    Mechanic_AwardJob(playerid);
}

/*Mechanic_LoadCharacter(playerid)
{
    cache_get_value_name_int(0, "character_mechanic_xp",        Character[playerid][E_CHARACTER_MECHANIC_XP]);
    cache_get_value_name_int(0, "character_mechanic_level",     Character[playerid][E_CHARACTER_MECHANIC_LEVEL]);
    cache_get_value_name_int(0, "character_mechanic_jobs_done", Character[playerid][E_CHARACTER_MECHANIC_JOBS_DONE]);

    if (Character[playerid][E_CHARACTER_MECHANIC_LEVEL] < 1)
        Character[playerid][E_CHARACTER_MECHANIC_LEVEL] = 1;
}*/

// /mechanic - mechanic menu: repair, refuel, tow and other services on the vehicle next to you.
CMD:mechanic(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
        return Firm_SendAccessDenied(playerid);

    if (!CanUseMechanicTools(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Firm", "A3A3A3", "You must be on duty with a mechanic firm to use this command.");

    if (MechanicIsBusy(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3",
            sprintf("You're already working on a job (%ds remaining). Use /mcancel to abort.", PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]));

    new action[32];
    if (sscanf(params, "s[32]", action))
    {
        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            "Usage: /mechanic [bodywork|engine|oilchange|inspect|respray|interior|paintjob|removepaintjob|drainfuel|tune]");
        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Level: %d | Jobs Done: %d | Timer: %ds",
                Character[playerid][E_CHARACTER_MECHANIC_LEVEL],
                Character[playerid][E_CHARACTER_MECHANIC_JOBS_DONE],
                Mechanic_GetTimer(playerid)));
        return true;
    }

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new closest_vehicle = INVALID_VEHICLE_ID;
    new Float:closest_dist = 5.0;

    for (new v = 1; v < MAX_VEHICLES; v++)
    {
        if (!IsValidVehicle(v)) continue;
        if (GetPlayerVehicleID(playerid) == v) continue;

        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(v, vx, vy, vz);

        new Float:dist = Distance3D(px, py, pz, vx, vy, vz);
        if (dist < closest_dist)
        {
            closest_dist   = dist;
            closest_vehicle = v;
        }
    }

    new invehicle = GetPlayerVehicleID(playerid);
    if (invehicle && invehicle != INVALID_VEHICLE_ID && GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
        closest_vehicle = invehicle;

    if (closest_vehicle == INVALID_VEHICLE_ID)
        return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "No vehicle nearby to work on. Get within 5 metres.");

    new factiontype = GetVehicleFactionType(closest_vehicle);
    if (factiontype == FACTION_TYPE_LEO || factiontype == FACTION_TYPE_FEDERAL ||
            factiontype == FACTION_TYPE_EMS || factiontype == FACTION_TYPE_NEWS)
        return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "You cannot work on faction vehicles.");

    new vehicleid  = closest_vehicle;
    new timer      = Mechanic_GetTimer(playerid);

    if (!strcmp(action, "bodywork", true))
    {
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_BODYWORK;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;

        Mechanic_BeginWork(playerid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Started bodywork repair on vehicle %d. Estimated time: %ds.", vehicleid, timer));
    }

    else if (!strcmp(action, "engine", true))
    {
        new engine_enum_id = Vehicle_GetEnumID(vehicleid);

        // Rebuilding a seized engine takes twice as long as a normal repair.
        if (engine_enum_id != -1 && Oil_IsSeized(engine_enum_id))
            timer *= 2;

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_ENGINE;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;

        Mechanic_BeginWork(playerid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Started engine repair on vehicle %d. Estimated time: %ds.", vehicleid, timer));
    }

    else if (!strcmp(action, "oilchange", true))
    {
        new oil_enum_id = Vehicle_GetEnumID(vehicleid);

        if (oil_enum_id == -1 || !Oil_IsTracked(oil_enum_id))
            return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "This vehicle doesn't need an oil change.");

        if (GetEngineStatus(vehicleid))
            return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "The engine has to be off before you change the oil.");

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_OIL_CHANGE;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;

        Mechanic_BeginWork(playerid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Started an oil change on vehicle %d. Estimated time: %ds.", vehicleid, timer));
    }

    else if (!strcmp(action, "inspect", true))
    {
        new inspect_enum_id = Vehicle_GetEnumID(vehicleid);

        if (inspect_enum_id == -1)
            return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "That isn't a proper vehicle.");

        new Float:inspect_health = ReturnVehicleHealth(vehicleid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("%s: engine health %.0f%%, %d miles on the odometer.", ReturnVehicleName(vehicleid), (inspect_health - 250.0) / 7.49, Vehicle[inspect_enum_id][E_VEHICLE_MILEAGE]));

        if (Oil_IsTracked(inspect_enum_id))
        {
            new condition[32];
            Oil_GetConditionName(inspect_enum_id, condition, sizeof(condition));

            new since = Oil_GetMilesSinceService(inspect_enum_id);

            if (since >= OIL_SERVICE_INTERVAL)
                SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
                    sprintf("Oil: %d miles since the last change - {FFCC44}past due by %d miles{DEDEDE}. Engine wear: %s.", since, since - OIL_SERVICE_INTERVAL, condition));
            else
                SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
                    sprintf("Oil: %d miles since the last change, due in %d miles. Engine wear: %s.", since, OIL_SERVICE_INTERVAL - since, condition));
        }
    }

    else if (!strcmp(action, "respray", true))
    {
        ShowPlayerDialog(playerid, DIALOG_MECHANIC_COLOR_EXT, DIALOG_STYLE_INPUT,
            "Respray Exterior",
            "Enter exterior color ID (0-255):",
            "Start Job",
            "Cancel");

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET] = vehicleid; // hold target during dialog
    }

    else if (!strcmp(action, "interior", true))
    {
        ShowPlayerDialog(playerid, DIALOG_MECHANIC_COLOR_INT, DIALOG_STYLE_INPUT,
            "Respray Interior",
            "Enter interior color ID (0-255):",
            "Start Job",
            "Cancel");

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET] = vehicleid;
    }

    else if (!strcmp(action, "paintjob", true))
    {
        ShowPlayerDialog(playerid, DIALOG_MECHANIC_PAINTJOB, DIALOG_STYLE_LIST,
            "Apply Paintjob",
            "Paintjob 0\nPaintjob 1\nPaintjob 2",
            "Start Job",
            "Cancel");

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET] = vehicleid;
    }

    else if (!strcmp(action, "removepaintjob", true))
    {
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_REMOVE_PAINTJOB;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;

        Mechanic_BeginWork(playerid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Removing paintjob from vehicle %d. Estimated time: %ds.", vehicleid, timer));
    }

    else if (!strcmp(action, "tune", true))
    {
        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            "Use /mtunestart to open the tune menu for the nearby vehicle.");
    }

    else if (!strcmp(action, "drainfuel", true))
    {
        new veh_enum_id = Vehicle_GetEnumID(vehicleid);
        if (veh_enum_id == -1 || VehicleVar[veh_enum_id][E_VEHICLE_WRONG_FUEL_AMOUNT] == 0)
            return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "This vehicle's tank isn't contaminated.");

        // Always a full minute, whatever the mechanic's level.
        timer = MECH_DRAIN_SECONDS;

        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_DRAIN_FUEL;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
        PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;

        Mechanic_BeginWork(playerid);
        Mechanic_ShowDrainBar(playerid);

        SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
            sprintf("Draining the contaminated fuel from vehicle %d. This takes %d seconds.", vehicleid, timer));
    }

    else
    {
        SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3",
            "Invalid action. Usage: /mechanic [bodywork|engine|oilchange|inspect|respray|interior|paintjob|removepaintjob|drainfuel|tune]");
    }

    return true;
}

// /mtunestart - starts a tuning job on the vehicle next to you.
CMD:mtunestart(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
        return Firm_SendAccessDenied(playerid);

    if (!CanUseMechanicTools(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Firm", "A3A3A3", "You must be on duty with a mechanic firm to use this command.");

    if (MechanicIsBusy(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3",
            sprintf("You're already working on a job (%ds remaining).", PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]));

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new closest_vehicle = INVALID_VEHICLE_ID;
    new Float:closest_dist = 5.0;

    for (new v = 1; v < MAX_VEHICLES; v++)
    {
        if (!IsValidVehicle(v)) continue;

        new Float:vx, Float:vy, Float:vz;
        GetVehiclePos(v, vx, vy, vz);

        new Float:dist = Distance3D(px, py, pz, vx, vy, vz);
        if (dist < closest_dist)
        {
            closest_dist    = dist;
            closest_vehicle = v;
        }
    }

    if (closest_vehicle == INVALID_VEHICLE_ID)
        return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "No vehicle nearby.");

    new factiontype = GetVehicleFactionType(closest_vehicle);
    if (factiontype == FACTION_TYPE_LEO || factiontype == FACTION_TYPE_FEDERAL ||
            factiontype == FACTION_TYPE_EMS || factiontype == FACTION_TYPE_NEWS)
        return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "You cannot tune faction vehicles.");

    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET] = closest_vehicle;
    PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_TUNE_COMPONENT;

    DisplayMechanicTuneMenu(playerid, closest_vehicle);

    return true;
}

// Shows the list of components the mechanic can install on a vehicle.
DisplayMechanicTuneMenu(playerid, vehicleid)
{
    new
        modelid = GetVehicleModel(vehicleid),
        componentid,
        component_type_id,
        component_name[MAX_VEHICLE_COMPONENT_NAME],
        dialog_info_string[1024];

    new
        component_array[MAX_VEHICLE_COMPONENTS],
        bool:component_type_used[MAX_COMPONENT_TYPES],
        component_type_array[MAX_COMPONENT_TYPES],
        component_index_array[MAX_VEHICLE_COMPONENTS],
        component_index_count,
        component_count;

    if (DoesVehicleHaveUpgrades(modelid))
        GetVehicleCompatibleUpgrades(modelid, component_array, sizeof(component_array), component_count);

    for (new j; j < component_count; j++)
    {
        componentid = component_array[j];
        if (IsVehicleUpgradeCompatible(modelid, componentid))
        {
            component_type_id = ORP_GetComponentType(componentid);
            component_type_used[component_type_id] = true;
        }
    }

    for (new i, j = MAX_COMPONENT_TYPES; i < j; i++)
    {
        if (component_type_used[i])
        {
            ORP_GetComponentTypeName(i, component_name);
            format(dialog_info_string, sizeof(dialog_info_string), "%s\n%s", dialog_info_string, component_name);
            component_type_array[component_index_count++] = i;
        }
    }

    component_index_count = 0;

    inline ComponentMenuList(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, inputtext

        if (!response)
        {
            PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_NONE;
            PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = INVALID_VEHICLE_ID;
            return true;
        }

        dialog_info_string[0] = EOS;

        inline ComponentMenu(pidx, dialogidx, responsex, listitemx, string:inputtextx[])
        {
            #pragma unused pidx, dialogidx, inputtextx

            if (!responsex)
                return DisplayMechanicTuneMenu(playerid, vehicleid);

            if (responsex)
            {
                new chosen_component = component_index_array[listitemx];
                new timer            = Mechanic_GetTimer(playerid);
                GetVehicleComponentName(chosen_component, component_name, sizeof(component_name));

                PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TYPE]   = MECH_JOB_TUNE_COMPONENT;
                PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TARGET]  = vehicleid;
                PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_TICKS]   = timer;
                PlayerVar[playerid][E_PLAYER_MECHANIC_JOB_PARAM]   = chosen_component;

                Mechanic_BeginWork(playerid);

                SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic", "DEDEDE",
                    sprintf("Installing \"%s\" - estimated time: %ds. Stand by.", component_name, timer));
            }
            return true;
        }

        for (new j; j < component_count; j++)
        {
            componentid = component_array[j];
            if (IsVehicleUpgradeCompatible(modelid, componentid))
            {
                component_type_id = ORP_GetComponentType(componentid);
                if (component_type_id == component_type_array[listitem])
                {
                    GetVehicleComponentName(componentid, component_name, sizeof(component_name));
                    format(dialog_info_string, sizeof(dialog_info_string), "%s\n%s", dialog_info_string, component_name);
                    component_index_array[component_index_count++] = componentid;
                }
            }
        }

        Dialog_ShowCallback(playerid, using inline ComponentMenu, DIALOG_STYLE_LIST, "Select Component", dialog_info_string, "Install", "Back");
        return true;
    }

    Dialog_ShowCallback(playerid, using inline ComponentMenuList, DIALOG_STYLE_LIST, "Component Type", dialog_info_string, "Select", "Cancel");

    return true;
}

// /mcancel - cancels your current mechanic job.
CMD:mcancel(playerid, params[])
{
    #pragma unused params

    if (!Firm_PlayerCanAccess(playerid))
        return Firm_SendAccessDenied(playerid);

    if (!CanUseMechanicTools(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Firm", "A3A3A3", "You must be on duty with a mechanic firm to use this command.");

    if (!MechanicIsBusy(playerid))
        return SendServerMessage(playerid, COLOR_RED, "Mechanic", "A3A3A3", "You don't have an active job to cancel.");

    Mechanic_CancelJob(playerid);
    return true;
}

// /mstats - shows your mechanic level, XP and jobs done.
CMD:mstats(playerid, params[])
{
    if (!Firm_PlayerCanAccess(playerid))
        return Firm_SendAccessDenied(playerid);

    if (!CanUseMechanicTools(playerid) && GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendServerMessage(playerid, COLOR_RED, "Firm", "A3A3A3", "You must be on duty with a mechanic firm to use this command.");

    new targetid = playerid;
    if (!isnull(params))
    {
        targetid = strval(params);
        if (!IsPlayerConnected(targetid))
            return SendServerMessage(playerid, COLOR_RED, "Error", "A3A3A3", "That player is not connected.");
    }

    new next_threshold_str[32];
    new level = Character[targetid][E_CHARACTER_MECHANIC_LEVEL];
    if (level < MECHANIC_MAX_LEVEL)
        format(next_threshold_str, sizeof(next_threshold_str), "%d jobs", MECHANIC_LEVEL_THRESHOLDS[level + 1]);
    else
        format(next_threshold_str, sizeof(next_threshold_str), "MAX LEVEL");

    SendServerMessage(playerid, COLOR_VEHICLE, "Mechanic Stats", "DEDEDE",
        sprintf("%s | Level: %d/%d | Jobs Done: %d | Timer: %ds | Next Level At: %s",
            ReturnRPName(targetid),
            Character[targetid][E_CHARACTER_MECHANIC_LEVEL],
            MECHANIC_MAX_LEVEL,
            Character[targetid][E_CHARACTER_MECHANIC_JOBS_DONE],
            Mechanic_GetTimer(targetid),
            next_threshold_str));

    return true;
}

hook OnPlayerConnect(playerid)
{
    Mechanic_DrainBar[playerid] = PlayerBar: INVALID_PLAYER_BAR_ID;
    return 1;
}
