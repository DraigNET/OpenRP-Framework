// ============================================================================
// File: gangzones/drugnpc/commands.pwn
// Commands for the street-dealer NPC system (junkies and dealers): /addjunkie, /createnpc,
// /makedealer, /dealers, /removedealer and related staff tools. Part of FEATURE_GANGZONES.
// Commands: /addjunkie /setjunkieskin /gotojunkie /removejunkie /junkietest /junkiestatus
// /createstreetboss /createnpc /manageboss /makedealer /removedealer /dealers /dealerstats
// /removestreetboss /seizedealer
// ============================================================================


// /addjunkie - (admin) places a junkie spawn point at your position.
CMD:addjunkie(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    new skin = -1;
    if(strlen(params) > 0) {
        if(sscanf(params, "d", skin) || skin < 0 || skin > 311)
            return SendClientMessage(playerid, COLOR_RED, "* Invalid skin ID. Use a value between 0-311, or omit for a random skin.");
    }

    new Float: x, Float: y, Float: z, Float: a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new vw  = GetPlayerVirtualWorld(playerid);
    new int = GetPlayerInterior(playerid);

    new zone_id    = GetPlayerGangZone(playerid);
    new faction_id = (zone_id != INVALID_GANGZONE_ID) ? GangZone[zone_id][E_GANGZONE_FACTION] : -1;

    new slot = AddJunkieLocation(x, y, z, a, zone_id, faction_id, skin, vw, int);

    if(slot == INVALID_JUNKIE_LOC) {
        SendClientMessage(playerid, COLOR_RED, "* Failed - maximum junkie locations reached.");
        return 1;
    }

    new skin_str[32];
    if(skin == -1) format(skin_str, sizeof(skin_str), "random");
    else           format(skin_str, sizeof(skin_str), "%d", skin);

    SendClientMessage(playerid, 0xC8A45AFF,
        sprintf("{C8A45A}* {D0D5DA}Junkie loc added - {87CEEB}Slot {7EC8A4}%d {AAAAAA}(skin: %s | VW: %d | INT: %d){D0D5DA}.", slot, skin_str, vw, int));

    AddLogEntry(playerid, LOG_TYPE_ADMIN,
        sprintf("Added junkie spawn loc slot:%d skin:%s vw:%d int:%d zone:%d (%.2f, %.2f, %.2f)", slot, skin_str, vw, int, zone_id, x, y, z));

    return 1;
}

// /setjunkieskin [skin] - (admin) changes the skin used at the nearest junkie spawn.
CMD:setjunkieskin(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    new skin;
    if(sscanf(params, "d", skin))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /setjunkieskin [skin 0-311 | -1 for random]");

    if(skin < -1 || skin > 311)
        return SendClientMessage(playerid, COLOR_RED, "* Skin must be between 0–311, or -1 to reset to random.");

    new Float: x, Float: y, Float: z;
    GetPlayerPos(playerid, x, y, z);

    new slot = GetNearestJunkieLocation(x, y, 10.0);
    if(slot == INVALID_JUNKIE_LOC)
        return SendClientMessage(playerid, COLOR_RED, "* No junkie spawn location found within 10 m.");

    JunkieLocation[slot][E_JLOC_SKIN] = skin;

    new query[128];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE `junkie_spawn_locations` SET `skin` = %d WHERE `id` = %d",
        skin, JunkieLocation[slot][E_JLOC_SQLID]);
    mysql_tquery(mysql, query);

    new junkie_slot = JunkieLocation[slot][E_JLOC_ACTIVE_JUNKIE];
    if(junkie_slot != INVALID_JUNKIE_SLOT) {
        DespawnJunkie(junkie_slot, false);
        JunkieLocation[slot][E_JLOC_COOLDOWN_UNTIL] = 0;
        SpawnJunkieAtLocation(slot);
    }

    new skin_str[32];
    if(skin == -1) format(skin_str, sizeof(skin_str), "random (pool)");
    else           format(skin_str, sizeof(skin_str), "%d", skin);

    SendClientMessage(playerid, 0xC8A45AFF,
        sprintf("{C8A45A}* {D0D5DA}Loc {7EC8A4}%d {D0D5DA}skin updated to {7EC8A4}%s{D0D5DA}.", slot, skin_str));

    AddLogEntry(playerid, LOG_TYPE_ADMIN,
        sprintf("Set junkie spawn loc %d skin to %s", slot, skin_str));

    return 1;
}

// /gotojunkie [slot] - (admin) teleports to a junkie spawn.
CMD:gotojunkie(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    new slot;
    if(sscanf(params, "d", slot))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /gotojunkie [location slot]");

    if(slot < 0 || slot >= MAX_JUNKIE_LOCATIONS || !JunkieLocation[slot][E_JLOC_CREATED])
        return SendClientMessage(playerid, COLOR_RED, "* Invalid or non-existent junkie location slot.");

    SetPlayerPos(playerid, JunkieLocation[slot][E_JLOC_X], JunkieLocation[slot][E_JLOC_Y], JunkieLocation[slot][E_JLOC_Z]);
    SetPlayerFacingAngle(playerid, JunkieLocation[slot][E_JLOC_A]);

    SendClientMessage(playerid, 0x87CEEBFF, sprintf("{87CEEB}[ Loc %d ] {D0D5DA}Zone: {7EC8A4}%d {D0D5DA}| Skin: {7EC8A4}%s {D0D5DA}| {AAAAAA}(%.2f, %.2f, %.2f)", slot, JunkieLocation[slot][E_JLOC_ZONE], (JunkieLocation[slot][E_JLOC_SKIN] == -1) ? "random" : sprintf("%d", JunkieLocation[slot][E_JLOC_SKIN]), JunkieLocation[slot][E_JLOC_X], JunkieLocation[slot][E_JLOC_Y], JunkieLocation[slot][E_JLOC_Z]));

    new current_time = gettime();
    new junkie_slot  = JunkieLocation[slot][E_JLOC_ACTIVE_JUNKIE];

    if(junkie_slot != INVALID_JUNKIE_SLOT && JunkieActor[junkie_slot][E_JUNKIE_CREATED]) {
        new age      = current_time - JunkieActor[junkie_slot][E_JUNKIE_SPAWN_TIME];
        new age_mins = age / 60;
        new age_secs = age % 60;
        new expires  = JUNKIE_DESPAWN_TIME - age;

        SendClientMessage(playerid, 0xD0D5DAFF, sprintf("{D0D5DA}Status: {7EC8A4}ACTIVE {D0D5DA}| Slot {7EC8A4}%d {D0D5DA}| Age {7EC8A4}%dm%ds", junkie_slot, age_mins, age_secs));
        SendClientMessage(playerid, 0xD0D5DAFF, sprintf("{D0D5DA}Expires {7EC8A4}%ds {D0D5DA}| Sale: {7EC8A4}%s", (expires > 0) ? expires : 0, JunkieActor[junkie_slot][E_JUNKIE_HAD_SALE] ? "YES" : "no"));

        SendClientMessage(playerid, 0xD0D5DAFF, sprintf("{D0D5DA}Weed: {6BBF8E}%dg @ $%d/g {D0D5DA}| Crack: {7A9FBB}%dg @ $%d/g {D0D5DA}| Coke: {A9B4BE}%dg @ $%d/g", JunkieActor[junkie_slot][E_JUNKIE_WEED_DEMAND], JunkieActor[junkie_slot][E_JUNKIE_WEED_PRICE], JunkieActor[junkie_slot][E_JUNKIE_CRACK_DEMAND], JunkieActor[junkie_slot][E_JUNKIE_CRACK_PRICE], JunkieActor[junkie_slot][E_JUNKIE_COCAINE_DEMAND], JunkieActor[junkie_slot][E_JUNKIE_COCAINE_PRICE]));

    } else if(JunkieLocation[slot][E_JLOC_COOLDOWN_UNTIL] > current_time) {
        new remaining = JunkieLocation[slot][E_JLOC_COOLDOWN_UNTIL] - current_time;
        new mins      = remaining / 60;
        new secs      = remaining % 60;

        SendClientMessage(playerid, 0xD0D5DAFF, sprintf("{D0D5DA}Status: {C47070}COOLDOWN {D0D5DA}| Spawns in {C47070}%dm %ds{D0D5DA}.", mins, secs));

    } else {
        SendClientMessage(playerid, 0xD0D5DAFF,
            "{D0D5DA}Status: {7EC8A4}AVAILABLE {D0D5DA}| Ready on next tick.");
    }

    AddLogEntry(playerid, LOG_TYPE_ADMIN,
        sprintf("Teleported to junkie loc slot:%d", slot));

    return 1;
}

// /removejunkie - (admin) removes the nearest junkie spawn.
CMD:removejunkie(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    new Float: x, Float: y, Float: z;
    GetPlayerPos(playerid, x, y, z);

    new slot = GetNearestJunkieLocation(x, y, 10.0);
    if(slot == INVALID_JUNKIE_LOC)
        return SendClientMessage(playerid, COLOR_RED, "* No junkie spawn location found within 10 m.");

    RemoveJunkieLocation(slot);

    SendClientMessage(playerid, COLOR_GREEN,
        sprintf("* Junkie spawn location (slot %d) permanently removed.", slot));

    AddLogEntry(playerid, LOG_TYPE_ADMIN,
        sprintf("Removed junkie spawn loc slot:%d", slot));

    return 1;
}

// /junkietest - (admin) spawns a junkie right now for testing.
CMD:junkietest(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    if(!strlen(params))
        return SendClientMessage(playerid, COLOR_WHITE,
            "USAGE: /junkietest [tick | expire | cooldown | clearcd | info]");

    if(!strcmp(params, "tick", true)) {
        JunkieSystemTick();
        SendClientMessage(playerid, 0xC8A45AFF, "{C8A45A}* {D0D5DA}System tick forced.");
        return 1;
    }

    if(!strcmp(params, "expire", true)) {
        new count = 0;
        for(new i = 0; i < MAX_ACTIVE_JUNKIES; i++) {
            if(!JunkieActor[i][E_JUNKIE_CREATED]) continue;
            JunkieActor[i][E_JUNKIE_SPAWN_TIME] = 0; // ensures age > JUNKIE_DESPAWN_TIME on next tick
            count++;
        }
        SendClientMessage(playerid, 0xC8A45AFF, sprintf("{C8A45A}* {D0D5DA}Marked {7EC8A4}%d {D0D5DA}junkie(s) for despawn - run {87CEEB}tick {D0D5DA}to process.", count));
        return 1;
    }

    if(!strcmp(params, "cooldown", true)) {
        new current_time = gettime();
        new found = 0;

        for(new i = 0; i < MAX_JUNKIE_LOCATIONS; i++) {
            if(!JunkieLocation[i][E_JLOC_CREATED]) continue;
            if(JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] <= current_time) continue;

            new remaining = JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] - current_time;
            new mins = remaining / 60;
            new secs = remaining % 60;
            SendClientMessage(playerid, 0xD0D5DAFF, sprintf("{D0D5DA}Loc {7EC8A4}%d {D0D5DA}- {C8A45A}%dm %ds {D0D5DA}remaining {AAAAAA}(%.1f, %.1f)",
                i, mins, secs,
                JunkieLocation[i][E_JLOC_X], JunkieLocation[i][E_JLOC_Y])
            );
            found++;
        }

        if(!found)
            SendClientMessage(playerid, 0xC8A45AFF, "{C8A45A}* {D0D5DA}No locations currently on cooldown.");
        else
            SendClientMessage(playerid, 0x87CEEBFF, sprintf("{87CEEB}* {D0D5DA}%d location(s) currently on cooldown.", found));

        return 1;
    }

    if(!strcmp(params, "clearcd", true)) {
        new count = 0;
        for(new i = 0; i < MAX_JUNKIE_LOCATIONS; i++) {
            if(!JunkieLocation[i][E_JLOC_CREATED]) continue;
            if(JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] <= gettime()) continue;
            JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] = 0;
            count++;
        }
        SendClientMessage(playerid, 0xC8A45AFF, sprintf("{C8A45A}* {D0D5DA}Cleared cooldown on {7EC8A4}%d {D0D5DA}location(s) - run {87CEEB}tick {D0D5DA}to spawn.", count));
        return 1;
    }

    if(!strcmp(params, "info", true)) {
        new current_time = gettime();
        new found = 0;

        for(new i = 0; i < MAX_ACTIVE_JUNKIES; i++) {
            if(!JunkieActor[i][E_JUNKIE_CREATED]) continue;

            new age        = current_time - JunkieActor[i][E_JUNKIE_SPAWN_TIME];
            new age_mins   = age / 60;
            new age_secs   = age % 60;
            new expires_in = JUNKIE_DESPAWN_TIME - age;

            SendClientMessage(playerid, 0xD0D5DAFF, sprintf(
                "{D0D5DA}Slot {7EC8A4}%d {D0D5DA}| Loc {7EC8A4}%d {D0D5DA}| {7EC8A4}%dm%ds {D0D5DA}| Exp {C8A45A}%ds {D0D5DA}| Sale: {7EC8A4}%s {D0D5DA}| W:{6BBF8E}%d {D0D5DA}C:{7A9FBB}%d {D0D5DA}K:{A9B4BE}%d",
                i,
                JunkieActor[i][E_JUNKIE_LOC_SLOT],
                age_mins, age_secs,
                (expires_in > 0) ? expires_in : 0,
                JunkieActor[i][E_JUNKIE_HAD_SALE] ? "YES" : "no",
                JunkieActor[i][E_JUNKIE_WEED_DEMAND],
                JunkieActor[i][E_JUNKIE_CRACK_DEMAND],
                JunkieActor[i][E_JUNKIE_COCAINE_DEMAND]
            ));
            found++;
        }

        if(!found)
            SendClientMessage(playerid, 0xC47070FF, "{C47070}* {D0D5DA}No active junkies.");
        else
            SendClientMessage(playerid, 0x87CEEBFF, sprintf("{87CEEB}* {D0D5DA}%d active junkie(s) listed above.", found));

        return 1;
    }

    SendClientMessage(playerid, COLOR_RED, "* Unknown option. Use: tick | expire | cooldown | clearcd | info");
    return 1;
}


// /junkiestatus - (admin) shows how many junkie NPCs exist and how many are on cooldown.
CMD:junkiestatus(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    new total = 0, active = 0, on_cooldown = 0, available = 0;
    new current_time = gettime();

    for(new i = 0; i < MAX_JUNKIE_LOCATIONS; i++) {
        if(!JunkieLocation[i][E_JLOC_CREATED]) continue;
        total++;

        if(JunkieLocation[i][E_JLOC_ACTIVE_JUNKIE] != INVALID_JUNKIE_SLOT)
            active++;
        else if(JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] > current_time)
            on_cooldown++;
        else
            available++;
    }

    SendClientMessage(playerid, 0x87CEEBFF,
        sprintf("{87CEEB}[ Junkie Locations ] {D0D5DA}Total: {7EC8A4}%d {D0D5DA}| Active: {7EC8A4}%d {D0D5DA}| Cooldown: {C8A45A}%d {D0D5DA}| Available: {7EC8A4}%d",
        total, active, on_cooldown, available));

    return 1;
}

// /createstreetboss - (admin) creates a street boss NPC dealer.
CMD:createstreetboss(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_DEVELOPER)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    new skin = -1;
    if(strlen(params) > 0 && !sscanf(params, "d", skin)) {
        if(skin < 0 || skin > 311)
            return SendClientMessage(playerid, COLOR_RED, "* Invalid skin ID (0–311).");
    } else {
        skin = -1;
    }

    new vw, int, Float: x, Float: y, Float: z, Float: a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    vw = GetPlayerVirtualWorld(playerid);
    int = GetPlayerInterior(playerid);

    new npc_slot = CreateStreetBossNPC(playerid, x, y, z, a, true, skin, vw, int);
    if(npc_slot != INVALID_DRUG_DEALER_ID) {
        new skin_used = StreetBossNPC[npc_slot][E_STREET_NPC_SKIN];
        SendClientMessage(playerid, 0xC8A45AFF, sprintf("{C8A45A}* {D0D5DA}NPC created - {87CEEB}Slot {7EC8A4}%d {AAAAAA}(skin %d) [Admin Override]", npc_slot, skin_used));
        AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Created street boss NPC skin:%d (%.2f, %.2f, %.2f)", skin_used, x, y, z));
    } else {
        SendClientMessage(playerid, COLOR_RED, "* Failed to create street boss NPC.");
    }
    return 1;
}

// /createnpc - lets a street boss place a dealer NPC they manage.
CMD:createnpc(playerid, params[]) {
    if(!PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER])
        return SendClientMessage(playerid, COLOR_RED, "* You are not a drug dealer.");

    if(PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] < DEALER_RANK_STREET_BOSS)
        return SendClientMessage(playerid, COLOR_RED, "* You must be a Street Boss rank to place a dealer NPC.");

    new slot1 = PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT];
    new slot2 = PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2];
    new max_slots = (PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] >= DEALER_RANK_SUPPLIER) ? 2 : 1;

    if(slot1 != INVALID_DRUG_DEALER_ID && !StreetBossNPC[slot1][E_STREET_NPC_CREATED]) {
        PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT] = INVALID_DRUG_DEALER_ID;
        slot1 = INVALID_DRUG_DEALER_ID;
        SavePlayerDrugDealerData(playerid);
    }
    if(slot2 != INVALID_DRUG_DEALER_ID && !StreetBossNPC[slot2][E_STREET_NPC_CREATED]) {
        PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2] = INVALID_DRUG_DEALER_ID;
        slot2 = INVALID_DRUG_DEALER_ID;
        SavePlayerDrugDealerData(playerid);
    }

    new active_count = (slot1 != INVALID_DRUG_DEALER_ID ? 1 : 0) + (slot2 != INVALID_DRUG_DEALER_ID ? 1 : 0);
    if(active_count >= max_slots) {
        if(max_slots == 1)
            return SendClientMessage(playerid, COLOR_RED, "* You already have a dealer NPC. Use /manageboss to dismiss it first.");
        else
            return SendClientMessage(playerid, COLOR_RED, "* You already have 2 dealer NPCs active. Dismiss one with /manageboss first.");
    }

    new vw, int, Float: x, Float: y, Float: z, Float: a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    vw = GetPlayerVirtualWorld(playerid);
    int = GetPlayerInterior(playerid);

    new npc_slot = CreateStreetBossNPC(playerid, x, y, z, a, false, -1, vw, int);
    if(npc_slot != INVALID_DRUG_DEALER_ID) {
        PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT] = npc_slot;
        SavePlayerDrugDealerData(playerid);
        SendClientMessage(playerid, 0xC8A45AFF, "{C8A45A}* {D0D5DA}Dealer placed. Use {87CEEB}/manageboss {D0D5DA}to manage them.");
    } else {
        SendClientMessage(playerid, COLOR_RED, "* Failed to place your dealer. The area may be full.");
    }
    return 1;
}

// /manageboss - opens the management menu for a street boss NPC.
CMD:manageboss(playerid, params[]) {
    if(!PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER])
        return SendClientMessage(playerid, COLOR_RED, "* You are not a drug dealer.");
    if(PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] < DEALER_RANK_STREET_BOSS)
        return SendClientMessage(playerid, COLOR_RED, "* You must be at least Street Boss rank to manage dealer NPCs.");

    new slot1 = PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT];
    new slot2 = PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2];
    new bool: s1_valid = (slot1 != INVALID_DRUG_DEALER_ID && StreetBossNPC[slot1][E_STREET_NPC_CREATED]);
    new bool: s2_valid = (slot2 != INVALID_DRUG_DEALER_ID && StreetBossNPC[slot2][E_STREET_NPC_CREATED]);

    if(!s1_valid && !s2_valid) {
        if(slot1 != INVALID_DRUG_DEALER_ID) { PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT]  = INVALID_DRUG_DEALER_ID; SavePlayerDrugDealerData(playerid); }
        if(slot2 != INVALID_DRUG_DEALER_ID) { PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2] = INVALID_DRUG_DEALER_ID; SavePlayerDrugDealerData(playerid); }
        return SendClientMessage(playerid, COLOR_RED, "* You don't have any dealer NPCs. Use /createnpc.");
    }

    if(s1_valid && !s2_valid) return ShowStreetBossManagementDialog(playerid, slot1), 1;
    if(s2_valid && !s1_valid) return ShowStreetBossManagementDialog(playerid, slot2), 1;

    new dialog_str[256];
    format(dialog_str, sizeof(dialog_str),
        "Dealer 1\t%s\nDealer 2\t%s",
        StreetBossNPC[slot1][E_STREET_NPC_OWNER_NAME],
        StreetBossNPC[slot2][E_STREET_NPC_OWNER_NAME]
    );
    inline OnSelectDealer(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext
        if(!response) return 1;
        ShowStreetBossManagementDialog(playerid, (listitem == 0) ? slot1 : slot2);
        return 1;
    }
    Dialog_ShowCallback(playerid, using inline OnSelectDealer,
        DIALOG_STYLE_TABLIST_HEADERS, "Select Dealer", dialog_str, "Manage", "Cancel");
    return 1;
}

// /makedealer [player] - makes a faction member a drug dealer.
CMD:makedealer(playerid, params[]) {
    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /makedealer [playerid]");

    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

    new player_faction = Character[playerid][E_CHARACTER_FACTIONID];
    new target_faction = Character[targetid][E_CHARACTER_FACTIONID];

    if(player_faction == INVALID_FACTION_ID || target_faction == INVALID_FACTION_ID)
        return SendClientMessage(playerid, COLOR_RED, "* Both players must be in a faction.");

    if(player_faction != target_faction)
        return SendClientMessage(playerid, COLOR_RED, "* Target must be in your faction.");
        
    new faction_enum = Faction_GetEnumID(player_faction);
    if(faction_enum == INVALID_FACTION_ID)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Error fetching faction enumerator ID! Contact a DEV.");

    if( Faction[faction_enum][E_FACTION_TYPE] == FACTION_TYPE_GOV   ||
        Faction[faction_enum][E_FACTION_TYPE] == FACTION_TYPE_LEO   ||
        Faction[faction_enum][E_FACTION_TYPE] == FACTION_TYPE_EMS       ||
        Faction[faction_enum][E_FACTION_TYPE] == FACTION_TYPE_FEDERAL   ||
        Faction[faction_enum][E_FACTION_TYPE] == FACTION_TYPE_SECURITY)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Government factions cannot have drug dealers.");

    if(Character[playerid][E_CHARACTER_FACTIONTIER] > 1)
        return SendClientMessage(playerid, COLOR_RED, "* You must be a faction leader to make drug dealers.");

    if(PlayerDrugDealer[targetid][E_PLAYER_IS_DRUG_DEALER])
        return SendClientMessage(playerid, COLOR_RED, "* This player is already a drug dealer.");

    if(!CanPlayerBeDrugDealer(targetid, target_faction)) {
        new max_dealers = GetMaxFactionDrugDealers(target_faction);
        return SendClientMessage(playerid, COLOR_RED, sprintf("* Faction has reached maximum drug dealers (%d).", max_dealers));
    }

    PlayerDrugDealer[targetid][E_PLAYER_IS_DRUG_DEALER]   = true;
    PlayerDrugDealer[targetid][E_PLAYER_DRUG_DEALER_RANK] = 0;
    SavePlayerDrugDealerData(targetid);

    SendClientMessage(playerid, 0xC8A45AFF,
        sprintf("{C8A45A}* {D0D5DA}%s {D0D5DA}is now a dealer for {7EC8A4}%s{D0D5DA}.",
        ReturnRPName(targetid), Faction[faction_enum][E_FACTION_NAME]));
    SendClientMessage(targetid, 0xC8A45AFF,
        sprintf("{C8A45A}* {D0D5DA}%s {D0D5DA}put you on. You can now sell to junkies.", ReturnRPName(playerid)));

    return 1;
}

// /removedealer [player] - removes a member's dealer status.
CMD:removedealer(playerid, params[]) {
    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /removedealer [playerid]");

    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

    if(Character[playerid][E_CHARACTER_FACTIONID] != Character[targetid][E_CHARACTER_FACTIONID])
        return SendClientMessage(playerid, COLOR_RED, "* Target must be in your faction.");

    if(Character[playerid][E_CHARACTER_FACTIONTIER] > 1)
        return SendClientMessage(playerid, COLOR_RED, "* You must be a faction leader to remove drug dealers.");

    if(!PlayerDrugDealer[targetid][E_PLAYER_IS_DRUG_DEALER])
        return SendClientMessage(playerid, COLOR_RED, "* This player is not a drug dealer.");

    PlayerDrugDealer[targetid][E_PLAYER_IS_DRUG_DEALER] = false;
    SavePlayerDrugDealerData(targetid);

    SendClientMessage(playerid, 0xC8A45AFF,
        sprintf("{C8A45A}* {D0D5DA}%s {D0D5DA}has been pulled off dealing duties.", ReturnRPName(targetid)));
    SendClientMessage(targetid, 0xC47070FF,
        sprintf("{C47070}* {D0D5DA}You have been removed from dealing by {C47070}%s{D0D5DA}.", ReturnRPName(playerid)));

    return 1;
}

// /dealers - lists the drug dealers in your faction.
CMD:dealers(playerid, params[]) {
    new player_faction = Character[playerid][E_CHARACTER_FACTIONID];
    if(player_faction == INVALID_FACTION_ID)
        return SendClientMessage(playerid, COLOR_RED, "* You must be in a faction.");

    if(Character[playerid][E_CHARACTER_FACTIONTIER] > 3)
        return SendClientMessage(playerid, COLOR_RED, "* You need rank 3+ to view the dealer list.");

    new faction_enum  = Faction_GetEnumID(player_faction);
    new max_dealers   = GetMaxFactionDrugDealers(player_faction);
    new count         = 0;

    SendClientMessage(playerid, 0xC8A45AFF,
        sprintf("{C8A45A}Dealers - {D0D5DA}%s {AAAAAA}(cap: %d)",
        Faction[faction_enum][E_FACTION_NAME], max_dealers));

    foreach(new i : Player) {
        if(Character[i][E_CHARACTER_FACTIONID] == player_faction &&
           PlayerDrugDealer[i][E_PLAYER_IS_DRUG_DEALER]) {
            count++;
            new rank_names[][16] = { "Street", "Corner", "Street Boss", "Supplier" };
            new rank_name[16];
            format(rank_name, sizeof(rank_name), "%s",
                rank_names[clamp(PlayerDrugDealer[i][E_PLAYER_DRUG_DEALER_RANK], 0, 3)]);
            SendClientMessage(playerid, 0x87CEEBFF, sprintf("{87CEEB}» {D0D5DA}%s {AAAAAA}[ID:%d] {D0D5DA}- {7EC8A4}%s {AAAAAA}(%d sales)",
                ReturnRPName(i), i, rank_name, PlayerDrugDealer[i][E_PLAYER_DRUG_TOTAL_SALES]));
        }
    }

    if(count == 0)
        SendClientMessage(playerid, COLOR_RED, "* No active drug dealers online.");

    return 1;
}

// /dealerstats - shows a dealer's rank, sales and cooldowns.
CMD:dealerstats(playerid, params[]) {
    new targetid = playerid;

    if(strlen(params) > 0) {
        if(sscanf(params, "u", targetid))
            return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /dealerstats [optional: playerid]");
        if(!IsPlayerConnected(targetid))
            return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");
        if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_JUNIOR && targetid != playerid)
            return SendClientMessage(playerid, COLOR_RED, "* You can only view your own stats.");
    }

    if(!PlayerDrugDealer[targetid][E_PLAYER_IS_DRUG_DEALER])
        return SendClientMessage(playerid, COLOR_RED, sprintf("* %s not a drug dealer.",
            (targetid == playerid) ? "You are" : ReturnRPName(targetid)));

    new rank       = PlayerDrugDealer[targetid][E_PLAYER_DRUG_DEALER_RANK];
    new total_sales = PlayerDrugDealer[targetid][E_PLAYER_DRUG_TOTAL_SALES];

    new rank_names[][16]      = { "Street Dealer", "Corner Boss", "Street Boss", "Supplier" };
    new rank_thresholds[]     = { 0, SALES_REQUIRED_CORNER_BOSS, SALES_REQUIRED_STREET_BOSS, SALES_REQUIRED_SUPPLIER };
    new rank_name[16];
    format(rank_name, sizeof(rank_name), "%s", rank_names[clamp(rank, 0, 3)]);

    new last_sale_str[32] = "Never";
    if(PlayerDrugDealer[targetid][E_PLAYER_LAST_SALE_TIME] > 0) {
        new elapsed = gettime() - PlayerDrugDealer[targetid][E_PLAYER_LAST_SALE_TIME];
        if(elapsed < 60)        format(last_sale_str, sizeof(last_sale_str), "%d second(s) ago", elapsed);
        else if(elapsed < 3600) format(last_sale_str, sizeof(last_sale_str), "%d minute(s) ago", elapsed / 60);
        else                    format(last_sale_str, sizeof(last_sale_str), "%d hour(s) ago",   elapsed / 3600);
    }

    new next_rank_str[48] = "MAX RANK";
    if(rank < 3) {
        new needed = rank_thresholds[rank + 1];
        format(next_rank_str, sizeof(next_rank_str), "%s (%d / %d sales)",
            rank_names[rank + 1], clamp(total_sales, 0, needed), needed);
    }

    new dialog_str[1024];
    format(dialog_str, sizeof(dialog_str),
        "{FFD700}________________ Drug Dealer Statistics ________________\n\n{87CEEB}Name: {FFFFFF}%s\n{87CEEB}Rank: {FFD700}%s\n{87CEEB}Next Rank: {AAAAAA}%s\n\n{87CEEB}Sales Today: {00FF00}%d\n{87CEEB}Total Sales: {00FF00}%d\n{87CEEB}Last Sale: {FFFFFF}%s\n",
        ReturnRPName(targetid), rank_name, next_rank_str,
        PlayerDrugDealer[targetid][E_PLAYER_DRUG_SALES_TODAY],
        total_sales, last_sale_str
    );

    new slots[2];
    slots[0] = PlayerDrugDealer[targetid][E_PLAYER_STREET_NPC_SLOT];
    slots[1] = PlayerDrugDealer[targetid][E_PLAYER_STREET_NPC_SLOT2];

    if(rank >= DEALER_RANK_STREET_BOSS) {
        strcat(dialog_str, "\n{FFD700}---- Dealer NPCs ----\n");
        new shown = 0;
        for(new s = 0; s < 2; s++) {
            new npc_slot = slots[s];
            if(npc_slot == INVALID_DRUG_DEALER_ID || !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED]) continue;
            shown++;
            new Float: wt  = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_WEED);
            new Float: ct  = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_CRACK);
            new Float: cot = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_COKE);
            new Float: gt  = wt + ct + cot;
            new entry_count = 0;
            for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
                if(NPCStock[npc_slot][i][E_STOCK_AMOUNT] > 0.0) entry_count++;
            }
            new temp[280];
            format(temp, sizeof(temp),
                "{FFD700}Dealer %d:\n{87CEEB}Status: {00FF00}Active\n{87CEEB}NPC Total Sales: {00FF00}%d transactions\n{87CEEB}Pending Earnings: {00FF00}$%s\n\n{87CEEB}Stock Summary:\n{90EE90}Weed: {FFFFFF}%.1fg at {00FF00}$%d{FFFFFF}/g\n{F0E68C}Crack: {FFFFFF}%.1fg at {00FF00}$%d{FFFFFF}/g\n{FFFFFF}Cocaine: {FFFFFF}%.1fg at {00FF00}$%d{FFFFFF}/g\n{87CEEB}Total Stock: {FFFFFF}%.1fg across %d tier entr%s\n",
                shown,
                StreetBossNPC[npc_slot][E_STREET_NPC_TOTAL_SALES],
                IntegerWithDelimiter(StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS]),
                wt,  StreetBossNPC[npc_slot][E_STREET_NPC_WEED_PRICE],
                ct,  StreetBossNPC[npc_slot][E_STREET_NPC_CRACK_PRICE],
                cot, StreetBossNPC[npc_slot][E_STREET_NPC_COCAINE_PRICE],
                gt, entry_count, (entry_count == 1) ? "y" : "ies"
            );
            strcat(dialog_str, temp);
        }
        if(!shown)
            strcat(dialog_str, "{FF6B6B}Status: {AAAAAA}No dealer NPC placed. Use /createnpc.");
    }

    inline DlgDealerStats(pid, dialogid, response, listitem, string:inputtext[]) {
        #pragma unused pid, dialogid, inputtext, listitem, response
    }
    Dialog_ShowCallback(playerid, using inline DlgDealerStats,
        DIALOG_STYLE_MSGBOX, "Dealer Statistics", dialog_str, "Close", "");

    return 1;
}

// /removestreetboss [player] - (admin) removes a player's street boss NPC.
CMD:removestreetboss(playerid, params[]) {
    if(GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return SendClientMessage(playerid, COLOR_RED, "* Insufficient admin level.");

    new targetid;
    if(sscanf(params, "u", targetid))
        return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /removestreetboss [playerid]");

    if(!IsPlayerConnected(targetid))
        return SendClientMessage(playerid, COLOR_RED, "* Player not connected.");

    new npc_slot = INVALID_DRUG_DEALER_ID;
    for(new i = 0; i < MAX_STREET_BOSS_NPCS; i++) {
        if(!StreetBossNPC[i][E_STREET_NPC_CREATED]) continue;
        if(StreetBossNPC[i][E_STREET_NPC_OWNER] == Character[targetid][E_CHARACTER_ID]) {
            npc_slot = i;
            break;
        }
    }

    if(npc_slot == INVALID_DRUG_DEALER_ID)
        return SendClientMessage(playerid, COLOR_RED,
            sprintf("{C47070}* {D0D5DA}%s does not have an active dealer NPC.", ReturnRPName(targetid)));

    new Float: wt = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_WEED);
    new Float: ct = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_CRACK);
    new Float: kt = GetNPCTotalStock(npc_slot, E_DRUG_TYPE_COKE);
    new bool: had_stock = (wt > 0.0 || ct > 0.0 || kt > 0.0);

    if(had_stock)
        ReturnAllNPCStockToPlayer(npc_slot, targetid);

    new earnings = StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS];
    if(earnings > 0) {
        GivePlayerCash(targetid, earnings, "Admin NPC removal - earnings returned");
        StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS] = 0;
    }

    new owner_name[MAX_PLAYER_NAME];
    format(owner_name, sizeof(owner_name), "%s", ReturnRPName(targetid));

    DestroyStreetBossNPC(npc_slot);

    PlayerDrugDealer[targetid][E_PLAYER_STREET_NPC_SLOT] = INVALID_DRUG_DEALER_ID;
    SavePlayerDrugDealerData(targetid);

    SendClientMessage(playerid, 0xC8A45AFF,
        sprintf("{C8A45A}* {D0D5DA}Removed dealer NPC belonging to {7EC8A4}%s{D0D5DA}.", owner_name));

    if(had_stock)
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Stock ({6BBF8E}%.1fg W {D0D5DA}/ {7A9FBB}%.1fg C {D0D5DA}/ {A9B4BE}%.1fg K{D0D5DA}) returned to them.", wt, ct, kt));

    if(earnings > 0)
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Pending earnings of {7EC8A4}$%s {D0D5DA}transferred to them.", IntegerWithDelimiter(earnings)));

    SendClientMessage(targetid, 0xC47070FF,
        sprintf("{C47070}* {D0D5DA}Your street dealer NPC has been removed by {C47070}%s{D0D5DA}.", ReturnRPName(playerid)));

    if(had_stock)
        SendClientMessage(targetid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Your stock ({6BBF8E}%.1fg W {D0D5DA}/ {7A9FBB}%.1fg C {D0D5DA}/ {A9B4BE}%.1fg K{D0D5DA}) was returned to you.", wt, ct, kt));

    if(earnings > 0)
        SendClientMessage(targetid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Pending earnings of {7EC8A4}$%s {D0D5DA}were transferred to you.", IntegerWithDelimiter(earnings)));

    AddLogEntry(playerid, LOG_TYPE_ADMIN,
        sprintf("Force-removed street boss NPC (slot:%d) belonging to %s", npc_slot, owner_name));

    return 1;
}

// /seizedealer - law enforcement can seize a dealer NPC's stock.
CMD:seizedealer(playerid, params[]) {
    #pragma unused params

    if(!IsPlayerInLEAFaction(playerid, true))
        return SendClientMessage(playerid, COLOR_RED, "* You must be a law enforcement officer to use this command.");

    if(Character[playerid][E_CHARACTER_FACTIONTIER] > 2)
        return SendClientMessage(playerid, COLOR_RED, "* You must be at least Tier 2 to seize drug dealers.");

    new Float: px, Float: py, Float: pz;
    GetPlayerPos(playerid, px, py, pz);

    new best_slot = INVALID_DRUG_DEALER_ID;
    new Float: best_dist = 5.0;
    new cop_vw  = GetPlayerVirtualWorld(playerid);
    new cop_int = GetPlayerInterior(playerid);

    for(new i = 0; i < MAX_STREET_BOSS_NPCS; i++) {
        if(!StreetBossNPC[i][E_STREET_NPC_CREATED])   continue;
        if(StreetBossNPC[i][E_STREET_NPC_SEIZED])      continue;
        if(StreetBossNPC[i][E_STREET_NPC_VIRTUALWORLD] != cop_vw)  continue;
        if(StreetBossNPC[i][E_STREET_NPC_INTERIOR]     != cop_int) continue;

        new Float: d = GetDistanceBetweenPoints(px, py, pz, StreetBossNPC[i][E_STREET_NPC_X], StreetBossNPC[i][E_STREET_NPC_Y], StreetBossNPC[i][E_STREET_NPC_Z]);
        if(d < best_dist) {
            best_dist = d;
            best_slot = i;
        }
    }

    if(best_slot == INVALID_DRUG_DEALER_ID)
        return SendClientMessage(playerid, COLOR_RED, "* No drug dealer NPC found within 5 meters.");

    new owner_char_id  = StreetBossNPC[best_slot][E_STREET_NPC_OWNER];
    new owner_rank     = -1;

    foreach(new i : Player) {
        if(Character[i][E_CHARACTER_ID] == owner_char_id) {
            owner_rank = PlayerDrugDealer[i][E_PLAYER_DRUG_DEALER_RANK];
            break;
        }
    }

    // if owner is offline we conservatively treat them as Street Boss to prevent cops from farming the command while the dealer is offline to learn identities, online lower rank owners are revealed normally
    new bool: reveal_name = (owner_rank != -1 && owner_rank < DEALER_RANK_STREET_BOSS);

    new owner_name[MAX_PLAYER_NAME];
    if(reveal_name)
        format(owner_name, sizeof(owner_name), "%s", StreetBossNPC[best_slot][E_STREET_NPC_OWNER_NAME]);
    else
        format(owner_name, sizeof(owner_name), "an unknown individual");

    new earnings = StreetBossNPC[best_slot][E_STREET_NPC_EARNINGS];

    new Float: wt  = GetNPCTotalStock(best_slot, E_DRUG_TYPE_WEED);
    new Float: ct  = GetNPCTotalStock(best_slot, E_DRUG_TYPE_CRACK);
    new Float: kot = GetNPCTotalStock(best_slot, E_DRUG_TYPE_COKE);

    if(!SeizeStreetBossNPC(playerid, best_slot))
        return SendClientMessage(playerid, COLOR_RED, "* Failed to seize the dealer.");

    SendClientMessage(playerid, 0x87CEEBFF,
        sprintf("{87CEEB}[SEIZE] {D0D5DA}Dealer belonging to {C47070}%s {D0D5DA}has been seized and concealed.", owner_name));

    if(earnings > 0)
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {7EC8A4}$%s {D0D5DA}in earnings deposited to faction bank.", IntegerWithDelimiter(earnings)));
    else
        SendClientMessage(playerid, 0xAAAAAAAA,
            "{AAAAAA}* Dealer had no pending earnings.");

    if(wt > 0.0 || ct > 0.0 || kot > 0.0)
        SendClientMessage(playerid, 0xC8A45AFF,
            sprintf("{C8A45A}* {D0D5DA}Confiscated stock: {6BBF8E}%.1fg Weed {D0D5DA}/ {7A9FBB}%.1fg Crack {D0D5DA}/ {A9B4BE}%.1fg Cocaine{D0D5DA}.", wt, ct, kot));

    AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Seized drug dealer NPC (slot:%d owner:%s earnings:%d wt:%.1f ct:%.1f ko:%.1f)", best_slot, owner_name, earnings, wt, ct, kot));

    return 1;
}
