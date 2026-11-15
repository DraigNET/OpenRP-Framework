// ============================================================================
// File: misc/missions.pwn
// Mission framework (by Tramposo): create multi-step missions with checkpoints, timers and
// rewards. /missions, /startmission, /cancelmission, /missioninfo. Build your own missions with
// Mission_AddStep.
// Commands: /startmission /cancelmission /missioninfo /missions
// ============================================================================

// -----------------------------------------------------------------
// Mission Framework - Made by Tramposo on July 2025
// -----------------------------------------------------------------

#define INVALID_MISSION_ID -1
#define MAX_ACTIVE_MISSIONS 200
#define MAX_MISSION_TYPES 50
#define MAX_MISSION_STEPS 10
#define MAX_MISSION_DATA 20
#define MISSION_CHECKPOINT_SIZE 3.0

new Iterator:ActiveMissions<MAX_ACTIVE_MISSIONS>;
new Iterator:MissionTypes<MAX_MISSION_TYPES>;

enum {
    MISSION_STATUS_INACTIVE,
    MISSION_STATUS_ACTIVE,
    MISSION_STATUS_COMPLETED,
    MISSION_STATUS_FAILED
};

enum {
    STEP_TYPE_GOTO,
    STEP_TYPE_INTERACT,
    STEP_TYPE_VEHICLE_ENTER,
    STEP_TYPE_VEHICLE_EXIT,
    STEP_TYPE_PICKUP,
    STEP_TYPE_DELIVERY,
    STEP_TYPE_KILL_TARGET,
    STEP_TYPE_COLLECT_ITEMS,
    STEP_TYPE_WAIT_TIME,
    STEP_TYPE_CUSTOM
};

enum E_MISSION_STEP {
    E_STEP_TYPE,
    Float: E_STEP_POS_X,
    Float: E_STEP_POS_Y,
    Float: E_STEP_POS_Z,
    E_STEP_PARAM1,
    E_STEP_PARAM2,
    E_STEP_PARAM3,
    E_STEP_TEXT[128]
};

enum E_MISSION_TYPE {
    E_TYPE_NAME[64],
    E_TYPE_DESCRIPTION[256],
    E_TYPE_BASE_PAYOUT,
    E_TYPE_BASE_EXP,
    E_TYPE_TIMEOUT,
    E_TYPE_COOLDOWN,
    E_TYPE_REQUIREMENTS,
    E_TYPE_STEP_COUNT,
    E_TYPE_CALLBACK[32]
};

enum E_MISSION_DATA {
    E_MISSION_ID,
    E_MISSION_PLAYER_ID,
    E_MISSION_TYPE_ID,
    E_MISSION_STATUS,
    E_MISSION_CURRENT_STEP,
    E_MISSION_START_TIME,
    E_MISSION_PAYOUT,
    E_MISSION_EXP_REWARD,
    E_MISSION_TIMEOUT_TIMER,
    E_MISSION_STEP_TIMER,
    E_MISSION_VEHICLE_ID,
    E_MISSION_CUSTOM_DATA[MAX_MISSION_DATA]
};

new MissionTypeData[MAX_MISSION_TYPES][E_MISSION_TYPE];
new MissionSteps[MAX_MISSION_TYPES][MAX_MISSION_STEPS][E_MISSION_STEP];
new PlayerMissions[MAX_ACTIVE_MISSIONS][E_MISSION_DATA];
new PlayerMissionCooldown[MAX_PLAYERS];
new PlayerInteractionInProgress[MAX_PLAYERS];
new PlayerText:MissionTimerText[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};
new PlayerText:MissionTimerValueText[MAX_PLAYERS] = {PlayerText:INVALID_TEXT_DRAW, ...};
new MissionTimerActive[MAX_PLAYERS];
new MissionTimerValue[MAX_PLAYERS];
new MissionTimerCountdown[MAX_PLAYERS] = {-1, ...};

// Registers a new mission type (name, description, base pay) and returns its id.
stock Mission_RegisterType(const name[], const description[], base_payout, base_exp, timeout = 0, cooldown = 0, requirements = 0) {
    new type_id = Iter_Free(MissionTypes);
    if(type_id == INVALID_ITERATOR_SLOT) return INVALID_MISSION_ID;
    
    format(MissionTypeData[type_id][E_TYPE_NAME], 64, "%s", name);
    format(MissionTypeData[type_id][E_TYPE_DESCRIPTION], 256, "%s", description);
    MissionTypeData[type_id][E_TYPE_BASE_PAYOUT] = base_payout;
    MissionTypeData[type_id][E_TYPE_BASE_EXP] = base_exp;
    MissionTypeData[type_id][E_TYPE_TIMEOUT] = timeout;
    MissionTypeData[type_id][E_TYPE_COOLDOWN] = cooldown;
    MissionTypeData[type_id][E_TYPE_REQUIREMENTS] = requirements;
    MissionTypeData[type_id][E_TYPE_STEP_COUNT] = 0;
    
    Iter_Add(MissionTypes, type_id);
    return type_id;
}

// Adds a step (go to a place, wait, interact...) to a mission type.
stock Mission_AddStep(type_id, step_type, Float: x = 0.0, Float: y = 0.0, Float: z = 0.0, param1 = 0, param2 = 0, param3 = 0, const text[] = "") {
    if(!Iter_Contains(MissionTypes, type_id)) return 0;
    if(MissionTypeData[type_id][E_TYPE_STEP_COUNT] >= MAX_MISSION_STEPS) return 0;
    
    new step_index = MissionTypeData[type_id][E_TYPE_STEP_COUNT];
    MissionSteps[type_id][step_index][E_STEP_TYPE] = step_type;
    MissionSteps[type_id][step_index][E_STEP_POS_X] = x;
    MissionSteps[type_id][step_index][E_STEP_POS_Y] = y;
    MissionSteps[type_id][step_index][E_STEP_POS_Z] = z;
    MissionSteps[type_id][step_index][E_STEP_PARAM1] = param1;
    MissionSteps[type_id][step_index][E_STEP_PARAM2] = param2;
    MissionSteps[type_id][step_index][E_STEP_PARAM3] = param3;
    format(MissionSteps[type_id][step_index][E_STEP_TEXT], 128, "%s", text);
    
    MissionTypeData[type_id][E_TYPE_STEP_COUNT]++;
    return 1;
}

// Sets the callback function that runs when a mission reaches the 'custom' step.
stock Mission_SetCallback(type_id, const callback_name[]) {
    if(!Iter_Contains(MissionTypes, type_id)) return 0;
    format(MissionTypeData[type_id][E_TYPE_CALLBACK], 32, "%s", callback_name);
    return 1;
}

// Starts a mission of a type for a player, with optional custom data.
stock Mission_Start(playerid, type_id, const custom_data[MAX_MISSION_DATA] = {0, ...}, custom_data_size = 0) {
    if(!Iter_Contains(MissionTypes, type_id)) return INVALID_MISSION_ID;
    
    if(Mission_GetPlayerMission(playerid) != INVALID_MISSION_ID) {
        SendClientMessage(playerid, COLOR_ERROR, "You already have an active mission!");
        return INVALID_MISSION_ID;
    }
    
    if(Mission_IsPlayerOnCooldown(playerid)) {
        new remaining = Mission_GetCooldownRemaining(playerid);
        SendClientMessage(playerid, COLOR_ERROR, sprintf("Mission cooldown: %d minutes and %d seconds remaining", 
            remaining / 60, remaining % 60));
        return INVALID_MISSION_ID;
    }
    
    new mission_id = Iter_Free(ActiveMissions);
    if(mission_id == INVALID_ITERATOR_SLOT) return INVALID_MISSION_ID;
    
    PlayerMissions[mission_id][E_MISSION_ID] = mission_id;
    PlayerMissions[mission_id][E_MISSION_PLAYER_ID] = playerid;
    PlayerMissions[mission_id][E_MISSION_TYPE_ID] = type_id;
    PlayerMissions[mission_id][E_MISSION_STATUS] = MISSION_STATUS_ACTIVE;
    PlayerMissions[mission_id][E_MISSION_CURRENT_STEP] = 0;
    PlayerMissions[mission_id][E_MISSION_START_TIME] = gettime();
    PlayerMissions[mission_id][E_MISSION_PAYOUT] = MissionTypeData[type_id][E_TYPE_BASE_PAYOUT];
    PlayerMissions[mission_id][E_MISSION_EXP_REWARD] = MissionTypeData[type_id][E_TYPE_BASE_EXP];
    PlayerMissions[mission_id][E_MISSION_TIMEOUT_TIMER] = -1;
    PlayerMissions[mission_id][E_MISSION_STEP_TIMER] = -1;
    PlayerMissions[mission_id][E_MISSION_VEHICLE_ID] = GetPlayerVehicleID(playerid);
    
    if(custom_data_size > 0 && custom_data_size <= MAX_MISSION_DATA) {
        for(new i = 0; i < custom_data_size; i++) {
            PlayerMissions[mission_id][E_MISSION_CUSTOM_DATA][i] = custom_data[i];
        }
    }
    
    if(MissionTypeData[type_id][E_TYPE_TIMEOUT] > 0) {
        PlayerMissions[mission_id][E_MISSION_TIMEOUT_TIMER] = SetTimerEx("OnMissionTimeout", 
            MissionTypeData[type_id][E_TYPE_TIMEOUT] * 1000, false, "i", mission_id);
        Mission_StartTimer(playerid, MissionTypeData[type_id][E_TYPE_TIMEOUT]);
    }
    
    Iter_Add(ActiveMissions, mission_id);
    
    /*
    SendClientMessage(playerid, COLOR_GREEN, sprintf("[MISSION] Started: %s", MissionTypeData[type_id][E_TYPE_NAME]));
    SendClientMessage(playerid, COLOR_INFO, sprintf("Reward: $%s | EXP: %d", 
        IntegerWithDelimiter(PlayerMissions[mission_id][E_MISSION_PAYOUT]), 
        PlayerMissions[mission_id][E_MISSION_EXP_REWARD]));
    */

    new callback[64];
    format(callback, sizeof(callback), "%s_OnStart", MissionTypeData[type_id][E_TYPE_CALLBACK]);
    CallRemoteFunction(callback, "ii", playerid, mission_id);
    
    Mission_ProcessCurrentStep(playerid, mission_id);
    return mission_id;
}

// Sets up the current step of a mission (checkpoint, text, timer).
stock Mission_ProcessCurrentStep(playerid, mission_id) {
    if(!Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    new type_id = PlayerMissions[mission_id][E_MISSION_TYPE_ID];
    new current_step = PlayerMissions[mission_id][E_MISSION_CURRENT_STEP];
    
    if(current_step >= MissionTypeData[type_id][E_TYPE_STEP_COUNT]) {
        Mission_Complete(playerid, mission_id);
        return 1;
    }
    
    new step_type = MissionSteps[type_id][current_step][E_STEP_TYPE];
    new Float: x = MissionSteps[type_id][current_step][E_STEP_POS_X];
    new Float: y = MissionSteps[type_id][current_step][E_STEP_POS_Y];
    new Float: z = MissionSteps[type_id][current_step][E_STEP_POS_Z];
    
    switch(step_type) {
        case STEP_TYPE_GOTO: {
            SetPlayerCheckpoint(playerid, x, y, z, MISSION_CHECKPOINT_SIZE);
            ShowPlayerFooter(playerid, MissionSteps[type_id][current_step][E_STEP_TEXT], 7000);
        }
        case STEP_TYPE_INTERACT: {
            SetPlayerCheckpoint(playerid, x, y, z, MISSION_CHECKPOINT_SIZE);
            ShowPlayerFooter(playerid, MissionSteps[type_id][current_step][E_STEP_TEXT], 700);
        }
        case STEP_TYPE_PICKUP: {
            SetPlayerCheckpoint(playerid, x, y, z, MISSION_CHECKPOINT_SIZE);
            ShowPlayerFooter(playerid, MissionSteps[type_id][current_step][E_STEP_TEXT], 7000);
        }
        case STEP_TYPE_DELIVERY: {
            SetPlayerCheckpoint(playerid, x, y, z, MISSION_CHECKPOINT_SIZE);
            ShowPlayerFooter(playerid, MissionSteps[type_id][current_step][E_STEP_TEXT], 7000);
        }
        case STEP_TYPE_WAIT_TIME: {
            new wait_time = MissionSteps[type_id][current_step][E_STEP_PARAM1];
            if(wait_time > 0) {
                ShowPlayerFooter(playerid, sprintf("%s (%d seconds)", 
                    MissionSteps[type_id][current_step][E_STEP_TEXT], wait_time), 0);
                PlayerMissions[mission_id][E_MISSION_STEP_TIMER] = SetTimerEx("OnMissionStepComplete", 
                    wait_time * 1000, false, "ii", playerid, mission_id);
            } else {
                Mission_NextStep(playerid, mission_id);
            }
        }
        case STEP_TYPE_CUSTOM: {
            new callback[64];
            format(callback, sizeof(callback), "%s_ProcessStep", MissionTypeData[type_id][E_TYPE_CALLBACK]);
            CallRemoteFunction(callback, "iii", playerid, mission_id, current_step);
        }
        default: {
            new callback[64];
            format(callback, sizeof(callback), "%s_ProcessStep", MissionTypeData[type_id][E_TYPE_CALLBACK]);
            CallRemoteFunction(callback, "iii", playerid, mission_id, current_step);
        }
    }
    
    return 1;
}

// Moves a mission on to its next step.
stock Mission_NextStep(playerid, mission_id) {
    if(!Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    PlayerMissions[mission_id][E_MISSION_CURRENT_STEP]++;
    DisablePlayerCheckpoint(playerid);
    HidePlayerFooter(playerid);
    
    if(PlayerMissions[mission_id][E_MISSION_STEP_TIMER] != -1) {
        KillTimer(PlayerMissions[mission_id][E_MISSION_STEP_TIMER]);
        PlayerMissions[mission_id][E_MISSION_STEP_TIMER] = -1;
    }
    
    Mission_ProcessCurrentStep(playerid, mission_id);
    return 1;
}

// Completes a mission: pays the reward and starts the cooldown.
stock Mission_Complete(playerid, mission_id) {
    if(!Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    PlayerMissions[mission_id][E_MISSION_STATUS] = MISSION_STATUS_COMPLETED;
    DisablePlayerCheckpoint(playerid);
    HidePlayerFooter(playerid);
    
    new type_id = PlayerMissions[mission_id][E_MISSION_TYPE_ID];
    
    GivePlayerCash(playerid, PlayerMissions[mission_id][E_MISSION_PAYOUT], "Mission Payout");
    //GivePlayerExperience(playerid, PlayerMissions[mission_id][E_MISSION_EXP_REWARD]);
    
    if(MissionTypeData[type_id][E_TYPE_COOLDOWN] > 0) {
        PlayerMissionCooldown[playerid] = gettime() + MissionTypeData[type_id][E_TYPE_COOLDOWN];
    }
    
    SendClientMessage(playerid, COLOR_GREEN, sprintf("[MISSION] Completed: %s", MissionTypeData[type_id][E_TYPE_NAME]));
    SendClientMessage(playerid, COLOR_GREEN, sprintf("Rewards: $%s | EXP: %d", 
        IntegerWithDelimiter(PlayerMissions[mission_id][E_MISSION_PAYOUT]), 
        PlayerMissions[mission_id][E_MISSION_EXP_REWARD]));
    
    if(MissionTypeData[type_id][E_TYPE_COOLDOWN] > 0) {
        SendClientMessage(playerid, COLOR_INFO, sprintf("Mission cooldown: %d minutes", 
            MissionTypeData[type_id][E_TYPE_COOLDOWN] / 60));
    }
    
    GameTextForPlayer(playerid, sprintf("~y~mission passed!~n~~s~+%d", PlayerMissions[mission_id][E_MISSION_PAYOUT]), 7000, 0, 1);
    PlayerPlaySound(playerid, 183 , 0, 0, 0);
    
    new callback[64];
    format(callback, sizeof(callback), "%s_OnComplete", MissionTypeData[type_id][E_TYPE_CALLBACK]);
    CallRemoteFunction(callback, "ii", playerid, mission_id);
    SetTimerEx("ClearPlayerSound", 6000, false, "i", playerid);
    
    Mission_Destroy(mission_id);
    return 1;
}

// Fails a mission with a reason.
stock Mission_Fail(playerid, mission_id, const reason[] = "Mission failed") {
    if(!Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    PlayerMissions[mission_id][E_MISSION_STATUS] = MISSION_STATUS_FAILED;
    DisablePlayerCheckpoint(playerid);
    HidePlayerFooter(playerid);
    
    new type_id = PlayerMissions[mission_id][E_MISSION_TYPE_ID];
    
    //SendClientMessage(playerid, COLOR_ERROR, sprintf("[MISSION] Failed: %s - %s", MissionTypeData[type_id][E_TYPE_NAME], reason));
    
    GameTextForPlayer(playerid, "~r~mission failed", 5000, 6);
    PlayerPlaySound(playerid, 1085, 0, 0, 0);
    GameTextForPlayer(playerid, " ", 5000, 17);
    
    new callback[64];
    format(callback, sizeof(callback), "%s_OnFail", MissionTypeData[type_id][E_TYPE_CALLBACK]);
    CallRemoteFunction(callback, "iis", playerid, mission_id, reason);
    
    Mission_Destroy(mission_id);
    return 1;
}

// Removes a mission and cleans up its checkpoints and timers.
stock Mission_Destroy(mission_id) {
    if(!Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    new playerid = PlayerMissions[mission_id][E_MISSION_PLAYER_ID];
    
    if(IsPlayerConnected(playerid)) {
        Mission_StopTimer(playerid);
        DisablePlayerCheckpoint(playerid);
        HidePlayerFooter(playerid);
        PlayerInteractionInProgress[playerid] = 0;
        //TogglePlayerControllable(playerid, true);
        //ClearAnimations(playerid);
    }
    
    if(PlayerMissions[mission_id][E_MISSION_TIMEOUT_TIMER] != -1) {
        KillTimer(PlayerMissions[mission_id][E_MISSION_TIMEOUT_TIMER]);
        PlayerMissions[mission_id][E_MISSION_TIMEOUT_TIMER] = -1;
    }
    
    if(PlayerMissions[mission_id][E_MISSION_STEP_TIMER] != -1) {
        KillTimer(PlayerMissions[mission_id][E_MISSION_STEP_TIMER]);
        PlayerMissions[mission_id][E_MISSION_STEP_TIMER] = -1;
    }
    
    PlayerMissions[mission_id][E_MISSION_PLAYER_ID] = INVALID_PLAYER_ID;
    PlayerMissions[mission_id][E_MISSION_STATUS] = MISSION_STATUS_INACTIVE;
    
    for(new i = 0; i < MAX_MISSION_DATA; i++) {
        PlayerMissions[mission_id][E_MISSION_CUSTOM_DATA][i] = 0;
    }
    
    Iter_Remove(ActiveMissions, mission_id);
    return 1;
}

// Creates the mission timer textdraws.
stock Mission_CreateTimerTextdraws(playerid) {
    if(MissionTimerText[playerid] != PlayerText:INVALID_TEXT_DRAW) {
        Mission_DestroyTimerTextdraws(playerid);
    }
    
    MissionTimerText[playerid] = CreatePlayerTextDraw(playerid, 499.0000, 151.0000, "Time");
    PlayerTextDrawFont(playerid, MissionTimerText[playerid], 2);
    PlayerTextDrawLetterSize(playerid, MissionTimerText[playerid], 0.3000, 1.0000);
    PlayerTextDrawColor(playerid, MissionTimerText[playerid], -1);
    PlayerTextDrawSetShadow(playerid, MissionTimerText[playerid], 0);
    PlayerTextDrawSetOutline(playerid, MissionTimerText[playerid], 1);
    PlayerTextDrawBackgroundColor(playerid, MissionTimerText[playerid], 255);
    PlayerTextDrawSetProportional(playerid, MissionTimerText[playerid], 1);
    
    MissionTimerValueText[playerid] = CreatePlayerTextDraw(playerid, 602.0000, 151.0000, "00:00");
    PlayerTextDrawFont(playerid, MissionTimerValueText[playerid], 2);
    PlayerTextDrawLetterSize(playerid, MissionTimerValueText[playerid], 0.3000, 1.0000);
    PlayerTextDrawAlignment(playerid, MissionTimerValueText[playerid], 3);
    PlayerTextDrawColor(playerid, MissionTimerValueText[playerid], -1);
    PlayerTextDrawSetShadow(playerid, MissionTimerValueText[playerid], 0);
    PlayerTextDrawSetOutline(playerid, MissionTimerValueText[playerid], 1);
    PlayerTextDrawBackgroundColor(playerid, MissionTimerValueText[playerid], 255);
    PlayerTextDrawSetProportional(playerid, MissionTimerValueText[playerid], 1);
    
    return 1;
}

// Destroys the mission timer textdraws.
stock Mission_DestroyTimerTextdraws(playerid) {
    if(MissionTimerText[playerid] != PlayerText:INVALID_TEXT_DRAW) {
        PlayerTextDrawDestroy(playerid, MissionTimerText[playerid]);
        MissionTimerText[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }
    if(MissionTimerValueText[playerid] != PlayerText:INVALID_TEXT_DRAW) {
        PlayerTextDrawDestroy(playerid, MissionTimerValueText[playerid]);
        MissionTimerValueText[playerid] = PlayerText:INVALID_TEXT_DRAW;
    }
    return 1;
}

// Updates the timer text with the seconds remaining.
stock Mission_UpdateTimer(playerid, seconds) {
    if(MissionTimerValueText[playerid] == PlayerText:INVALID_TEXT_DRAW) return 0;
    
    new minutes = seconds / 60;
    new secs = seconds % 60;
    new timer_string[16];
    
    format(timer_string, sizeof(timer_string), "%02d:%02d", minutes, secs);
    PlayerTextDrawSetString(playerid, MissionTimerValueText[playerid], timer_string);
    PlayerTextDrawShow(playerid, MissionTimerValueText[playerid]);
    
    return 1;
}

// Starts the on-screen mission countdown.
stock Mission_StartTimer(playerid, seconds) {
    if(!MissionTimerActive[playerid]) {
        Mission_CreateTimerTextdraws(playerid);
        PlayerTextDrawShow(playerid, MissionTimerText[playerid]);
        PlayerTextDrawShow(playerid, MissionTimerValueText[playerid]);
        
        MissionTimerActive[playerid] = 1;
        MissionTimerValue[playerid] = seconds;
        
        if(MissionTimerCountdown[playerid] != -1) {
            KillTimer(MissionTimerCountdown[playerid]);
        }
        
        MissionTimerCountdown[playerid] = SetTimerEx("OnMissionTimerUpdate", 1000, true, "i", playerid);
        Mission_UpdateTimer(playerid, seconds);
    }
    return 1;
}

// Stops the on-screen mission countdown.
stock Mission_StopTimer(playerid) {
    if(MissionTimerActive[playerid]) {
        MissionTimerActive[playerid] = 0;
        MissionTimerValue[playerid] = 0;
        
        if(MissionTimerCountdown[playerid] != -1) {
            KillTimer(MissionTimerCountdown[playerid]);
            MissionTimerCountdown[playerid] = -1;
        }
        
        PlayerTextDrawHide(playerid, MissionTimerText[playerid]);
        PlayerTextDrawHide(playerid, MissionTimerValueText[playerid]);
        Mission_DestroyTimerTextdraws(playerid);
    }
    return 1;
}

// Returns the mission id a player is on, or INVALID_MISSION_ID.
stock Mission_GetPlayerMission(playerid) {
    foreach(new i: ActiveMissions) {
        if(PlayerMissions[i][E_MISSION_PLAYER_ID] == playerid) {
            return i;
        }
    }
    return INVALID_MISSION_ID;
}

// Returns true if the player is on a cooldown before the next mission.
stock Mission_IsPlayerOnCooldown(playerid) {
    return (gettime() < PlayerMissionCooldown[playerid]);
}

// Returns the seconds left of the mission cooldown.
stock Mission_GetCooldownRemaining(playerid) {
    new remaining = PlayerMissionCooldown[playerid] - gettime();
    return max(0, remaining);
}

// Writes the name of a mission type into name.
stock Mission_GetTypeName(type_id, name[], len) {
    if(!Iter_Contains(MissionTypes, type_id)) return 0;
    format(name, len, "%s", MissionTypeData[type_id][E_TYPE_NAME]);
    return 1;
}

// Reads a custom data value stored on a mission.
stock Mission_GetCustomData(mission_id, index) {
    if(index < 0 || index >= MAX_MISSION_DATA) return 0;
    
    foreach(new i : ActiveMissions) {
        if(PlayerMissions[i][E_MISSION_ID] == mission_id) {
            return PlayerMissions[i][E_MISSION_CUSTOM_DATA][index];
        }
    }
    
    return 0; // Mission not found
}


// Stores a custom data value on a mission.
stock Mission_SetCustomData(mission_id, index, value) {
    if(index < 0 || index >= MAX_MISSION_DATA) return 0;
    
    // Find the actual array index for this mission_id
    foreach(new i : ActiveMissions) {
        if(PlayerMissions[i][E_MISSION_ID] == mission_id) {
            PlayerMissions[i][E_MISSION_CUSTOM_DATA][index] = value;
            return 1;
        }
    }
    
    return 0; // Mission not found
}

// Returns which step a mission is on.
stock Mission_GetCurrentStep(mission_id) {
    foreach(new i : ActiveMissions) {
        if(PlayerMissions[i][E_MISSION_ID] == mission_id) {
            return PlayerMissions[i][E_MISSION_CURRENT_STEP];
        }
    }
    return -1; // Mission not found
}

// Changes the payout of a mission.
stock Mission_SetPayout(mission_id, amount) {
    foreach(new i : ActiveMissions) {
        if(PlayerMissions[i][E_MISSION_ID] == mission_id) {
            PlayerMissions[i][E_MISSION_PAYOUT] = amount;
            return 1;
        }
    }
    return 0; // Mission not found
}

// Handles a player entering a mission checkpoint.
stock Mission_HandleCheckpoint(playerid) {
    new mission_id = Mission_GetPlayerMission(playerid);
    if(mission_id == INVALID_MISSION_ID) return 0;
    
    new type_id = PlayerMissions[mission_id][E_MISSION_TYPE_ID];
    new current_step = PlayerMissions[mission_id][E_MISSION_CURRENT_STEP];
    
    if(current_step >= MissionTypeData[type_id][E_TYPE_STEP_COUNT]) return 0;
    
    new step_type = MissionSteps[type_id][current_step][E_STEP_TYPE];
    
    switch(step_type) {
        case STEP_TYPE_GOTO: {
            Mission_NextStep(playerid, mission_id);
        }
        case STEP_TYPE_INTERACT, STEP_TYPE_PICKUP, STEP_TYPE_DELIVERY: {
            if(PlayerInteractionInProgress[playerid]) return 0;
            
            if(IsPlayerInAnyVehicle(playerid)) {
                ShowPlayerFooter(playerid, "Get out of the vehicle first", 2000);
                return 0;
            }
            
            PlayerInteractionInProgress[playerid] = 1;
            TogglePlayerControllable(playerid, false);
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0, 1);
            
            new interaction_time = MissionSteps[type_id][current_step][E_STEP_PARAM1];
            if(interaction_time <= 0) interaction_time = 3000;
            
            ShowPlayerFooter(playerid, MissionSteps[type_id][current_step][E_STEP_TEXT], 7000);
            SetTimerEx("OnMissionInteractionComplete", interaction_time, false, "ii", playerid, mission_id);
        }
        default: {
            new callback[64];
            format(callback, sizeof(callback), "%s_OnCheckpoint", MissionTypeData[type_id][E_TYPE_CALLBACK]);
            CallRemoteFunction(callback, "iii", playerid, mission_id, current_step);
        }
    }
    
    return 1;
}

// /startmission [type] - starts a mission.
CMD:startmission(playerid, params[]) {
    new type_name[64];
    if(sscanf(params, "s[64]", type_name)) {
        SendClientMessage(playerid, COLOR_ERROR, "Usage: /startmission [mission_type]");
        SendClientMessage(playerid, COLOR_INFO, "Use /missions to see available mission types");
        return 1;
    }
    
    new type_id = INVALID_MISSION_ID;
    foreach(new i: MissionTypes) {
        if(!strcmp(MissionTypeData[i][E_TYPE_NAME], type_name, true)) {
            type_id = i;
            break;
        }
    }
    
    if(type_id == INVALID_MISSION_ID) {
        SendClientMessage(playerid, COLOR_ERROR, "Invalid mission type! Use /missions to see available types");
        return 1;
    }
    
    Mission_Start(playerid, type_id);
    return 1;
}

// /cancelmission - cancels your active mission.
CMD:cancelmission(playerid, params[]) {
    new mission_id = Mission_GetPlayerMission(playerid);
    if(mission_id == INVALID_MISSION_ID) {
        SendClientMessage(playerid, COLOR_ERROR, "You don't have an active mission!");
        return 1;
    }
    
    Mission_Fail(playerid, mission_id, "Mission cancelled");
    return 1;
}

// /missioninfo - shows your current mission step and time left.
CMD:missioninfo(playerid, params[]) {
    new mission_id = Mission_GetPlayerMission(playerid);
    if(mission_id == INVALID_MISSION_ID) {
        if(Mission_IsPlayerOnCooldown(playerid)) {
            new remaining = Mission_GetCooldownRemaining(playerid);
            SendClientMessage(playerid, COLOR_INFO, sprintf("Mission cooldown: %d minutes and %d seconds remaining", 
                remaining / 60, remaining % 60));
        } else {
            SendClientMessage(playerid, COLOR_ERROR, "You don't have an active mission!");
        }
        return 1;
    }
    
    new type_id = PlayerMissions[mission_id][E_MISSION_TYPE_ID];
    new current_step = PlayerMissions[mission_id][E_MISSION_CURRENT_STEP];
    
    SendClientMessage(playerid, COLOR_INFO, "________ MISSION INFO ________");
    SendClientMessage(playerid, COLOR_INFO, sprintf("Mission: %s", MissionTypeData[type_id][E_TYPE_NAME]));
    SendClientMessage(playerid, COLOR_INFO, sprintf("Step: %d/%d", current_step + 1, MissionTypeData[type_id][E_TYPE_STEP_COUNT]));
    SendClientMessage(playerid, COLOR_INFO, sprintf("Reward: $%s | EXP: %d", 
        IntegerWithDelimiter(PlayerMissions[mission_id][E_MISSION_PAYOUT]),
        PlayerMissions[mission_id][E_MISSION_EXP_REWARD]));
    
    if(MissionTypeData[type_id][E_TYPE_TIMEOUT] > 0) {
        new elapsed = gettime() - PlayerMissions[mission_id][E_MISSION_START_TIME];
        new remaining = MissionTypeData[type_id][E_TYPE_TIMEOUT] - elapsed;
        if(remaining > 0) {
            SendClientMessage(playerid, COLOR_INFO, sprintf("Time remaining: %d minutes", remaining / 60));
        }
    }
    
    return 1;
}

// /missions - lists the available mission types.
CMD:missions(playerid, params[]) {
    SendClientMessage(playerid, COLOR_INFO, "________ AVAILABLE MISSIONS ________");
    
    new count = 0;
    foreach(new i: MissionTypes) {
        SendClientMessage(playerid, COLOR_WHITE, sprintf("%s - %s (Reward: $%s)", 
            MissionTypeData[i][E_TYPE_NAME], 
            MissionTypeData[i][E_TYPE_DESCRIPTION],
            IntegerWithDelimiter(MissionTypeData[i][E_TYPE_BASE_PAYOUT])));
        count++;
    }
    
    if(count == 0) {
        SendClientMessage(playerid, COLOR_ERROR, "No missions are currently available.");
    } else {
        SendClientMessage(playerid, COLOR_INFO, sprintf("Use /startmission [mission_name] to start a mission. Total: %d missions", count));
    }
    
    return 1;
}

forward OnMissionTimeout(mission_id);
// Timer callback: fails a mission that ran out of time.
public OnMissionTimeout(mission_id) {
    if(!Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    new playerid = PlayerMissions[mission_id][E_MISSION_PLAYER_ID];
    if(IsPlayerConnected(playerid)) {
        Mission_Fail(playerid, mission_id, "Mission timed out");
    } else {
        Mission_Destroy(mission_id);
    }
    
    return 1;
}

forward OnMissionStepComplete(playerid, mission_id);
// Timer callback: a mission step finished, go to the next step.
public OnMissionStepComplete(playerid, mission_id) {
    if(!IsPlayerConnected(playerid) || !Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    Mission_NextStep(playerid, mission_id);
    return 1;
}

forward OnMissionInteractionComplete(playerid, mission_id);
// Timer callback: an interaction step finished, unfreeze the player.
public OnMissionInteractionComplete(playerid, mission_id) {
    if(!IsPlayerConnected(playerid) || !Iter_Contains(ActiveMissions, mission_id)) return 0;
    
    PlayerInteractionInProgress[playerid] = 0;
    TogglePlayerControllable(playerid, true);
    ClearAnimations(playerid);
    
    Mission_NextStep(playerid, mission_id);
    return 1;
}

forward OnMissionTimerUpdate(playerid);
// Timer callback: updates the on-screen mission countdown every second.
public OnMissionTimerUpdate(playerid) {
    if(!MissionTimerActive[playerid] || !IsPlayerConnected(playerid)) {
        if(MissionTimerCountdown[playerid] != -1) {
            KillTimer(MissionTimerCountdown[playerid]);
            MissionTimerCountdown[playerid] = -1;
        }
        return 0;
    }
    
    MissionTimerValue[playerid]--;
    
    if(MissionTimerValue[playerid] <= 0) {
        Mission_StopTimer(playerid);
        
        new mission_id = Mission_GetPlayerMission(playerid);
        if(mission_id != INVALID_MISSION_ID) {
            Mission_Fail(playerid, mission_id, "Time ran out");
        }
        return 0;
    }
    
    Mission_UpdateTimer(playerid, MissionTimerValue[playerid]);
    return 1;
}

#include <YSI_Coding\y_hooks>

hook OnGameModeInit() {
    Iter_Init(ActiveMissions);
    Iter_Init(MissionTypes);
    
    for(new i = 0; i < MAX_PLAYERS; i++) {
        PlayerMissionCooldown[i] = 0;
        PlayerInteractionInProgress[i] = 0;
        MissionTimerActive[i] = 0;
        MissionTimerValue[i] = 0;
        MissionTimerCountdown[i] = -1;
        MissionTimerText[i] = PlayerText:INVALID_TEXT_DRAW;
        MissionTimerValueText[i] = PlayerText:INVALID_TEXT_DRAW;
    }
    
    print(" * [MISSIONS] Framework initialized");
    return 1;
}

hook OnPlayerConnect(playerid) {
    PlayerMissionCooldown[playerid] = 0;
    PlayerInteractionInProgress[playerid] = 0;
    MissionTimerActive[playerid] = 0;
    MissionTimerValue[playerid] = 0;
    MissionTimerCountdown[playerid] = -1;
    MissionTimerText[playerid] = PlayerText:INVALID_TEXT_DRAW;
    MissionTimerValueText[playerid] = PlayerText:INVALID_TEXT_DRAW;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason) {
    new mission_id = Mission_GetPlayerMission(playerid);
    if(mission_id != INVALID_MISSION_ID) {
        Mission_Destroy(mission_id);
    }
    
    PlayerInteractionInProgress[playerid] = 0;
    Mission_StopTimer(playerid);
    return 1;
}

hook OnPlayerEnterCheckpoint(playerid) {
    Mission_HandleCheckpoint(playerid);
    return 1;
}

hook OnPlayerDeath(playerid, killerid, reason) {
    new mission_id = Mission_GetPlayerMission(playerid);
    if(mission_id != INVALID_MISSION_ID) {
        Mission_Fail(playerid, mission_id, "You died");
    }
    return 1;
}

// Returns the seconds a mission has left.
stock Mission_GetTimeRemaining(mission_id) {
    if(mission_id < 0 || mission_id >= MAX_ACTIVE_MISSIONS) return 0;
    
    new timeout = MissionTypeData[PlayerMissions[mission_id][E_MISSION_TYPE_ID]][E_TYPE_TIMEOUT];
    new start_time = PlayerMissions[mission_id][E_MISSION_START_TIME];
    new elapsed = gettime() - start_time;
    
    return (timeout - elapsed);
}
