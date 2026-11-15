// ============================================================================
// File: gangzones/drugnpc/core.pwn
// Core of the drug NPC system: junkie NPCs that buy drugs and dealer NPCs players run, with
// stock, prices, ranks and the buy/sell animations.
// ============================================================================


// Rolls how much of each drug a junkie will buy.
GenerateJunkieDemands(slot) {
    JunkieActor[slot][E_JUNKIE_WEED_DEMAND]    = 0;
    JunkieActor[slot][E_JUNKIE_CRACK_DEMAND]   = 0;
    JunkieActor[slot][E_JUNKIE_COCAINE_DEMAND] = 0;

    new drug_types[3] = { 0, 1, 2 };
    for(new i = 0; i < 3; i++) {
        new j = random(3);
        new tmp      = drug_types[i];
        drug_types[i] = drug_types[j];
        drug_types[j] = tmp;
    }

    new num_drugs = 1 + random(2);
    for(new i = 0; i < num_drugs; i++) {
        switch(drug_types[i]) {
            case 0: JunkieActor[slot][E_JUNKIE_WEED_DEMAND]    = 1 + random(4);
            case 1: JunkieActor[slot][E_JUNKIE_CRACK_DEMAND]   = 1 + random(3);
            case 2: JunkieActor[slot][E_JUNKIE_COCAINE_DEMAND] = 1 + random(3);
        }
    }

    /* INITIAL VERSION */
    // JunkieActor[slot][E_JUNKIE_WEED_PRICE]    = 700  + random(426); // $700  – $1,125 /g
    // JunkieActor[slot][E_JUNKIE_CRACK_PRICE]   = 1250 + random(876); // $1,250 – $2,125 /g
    // JunkieActor[slot][E_JUNKIE_COCAINE_PRICE] = 1050 + random(701); // $1,050 – $1,750 /g
    
    /* PRICES V2 */
    JunkieActor[slot][E_JUNKIE_WEED_PRICE]    = 400 + random(245); // $400 – $644 /g
    JunkieActor[slot][E_JUNKIE_CRACK_PRICE]   = 715 + random(502); // $715 – $1216 /g
    JunkieActor[slot][E_JUNKIE_COCAINE_PRICE] = 601 + random(401); // $601 – $1001 /g

}

forward DelayedJunkieSetup(slot);
// Timer callback: finishes setting up a junkie actor after it has been created.
public DelayedJunkieSetup(slot) {
    if(slot < 0 || slot >= MAX_ACTIVE_JUNKIES || !JunkieActor[slot][E_JUNKIE_CREATED])
        return 0;

    new actor_id = JunkieActor[slot][E_JUNKIE_ACTOR_ID];
    if(!IsValidDynamicActor(actor_id)) return 0;

    new loc = JunkieActor[slot][E_JUNKIE_LOC_SLOT];
    new Float: x = JunkieLocation[loc][E_JLOC_X];
    new Float: y = JunkieLocation[loc][E_JLOC_Y];
    new Float: z = JunkieLocation[loc][E_JLOC_Z];
    new vw  = JunkieLocation[loc][E_JLOC_VIRTUALWORLD];
    new int = JunkieLocation[loc][E_JLOC_INTERIOR];

    if(!IsValidDynamicArea(JunkieActor[slot][E_JUNKIE_AREA_ID])) {
        JunkieActor[slot][E_JUNKIE_AREA_ID] = CreateDynamicSphere(x, y, z, 3.0, vw, int);
    }

    ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_IDLE", 4.1, 1, 1, 1, 1, 0);
    return 1;
}

forward DelayedDespawnJunkie(slot, set_cooldown);
// Timer callback: removes a junkie actor and starts its cooldown.
public DelayedDespawnJunkie(slot, set_cooldown) {
    DespawnJunkie(slot, bool: set_cooldown);
    return 1;
}

// Spawns a junkie at one of the junkie spawn locations.
SpawnJunkieAtLocation(loc_slot) {
    if(loc_slot < 0 || loc_slot >= MAX_JUNKIE_LOCATIONS)   return INVALID_JUNKIE_SLOT;
    if(!JunkieLocation[loc_slot][E_JLOC_CREATED])          return INVALID_JUNKIE_SLOT;
    if(JunkieLocation[loc_slot][E_JLOC_ACTIVE_JUNKIE] != INVALID_JUNKIE_SLOT) return INVALID_JUNKIE_SLOT;
    if(JunkieLocation[loc_slot][E_JLOC_COOLDOWN_UNTIL] > gettime())           return INVALID_JUNKIE_SLOT;

    new slot = INVALID_JUNKIE_SLOT;
    for(new i = 0; i < MAX_ACTIVE_JUNKIES; i++) {
        if(!JunkieActor[i][E_JUNKIE_CREATED]) { slot = i; break; }
    }
    if(slot == INVALID_JUNKIE_SLOT) return INVALID_JUNKIE_SLOT;

    new Float: x = JunkieLocation[loc_slot][E_JLOC_X];
    new Float: y = JunkieLocation[loc_slot][E_JLOC_Y];
    new Float: z = JunkieLocation[loc_slot][E_JLOC_Z];
    new Float: a = JunkieLocation[loc_slot][E_JLOC_A];
    new vw  = JunkieLocation[loc_slot][E_JLOC_VIRTUALWORLD];
    new int = JunkieLocation[loc_slot][E_JLOC_INTERIOR];

    new forced_skin = JunkieLocation[loc_slot][E_JLOC_SKIN];
    JunkieActor[slot][E_JUNKIE_SKIN]       = (forced_skin >= 0 && forced_skin <= 311) ? forced_skin : JunkieSkinPool[random(sizeof(JunkieSkinPool))];
    JunkieActor[slot][E_JUNKIE_ACTOR_ID]   = CreateDynamicActor(JunkieActor[slot][E_JUNKIE_SKIN], x, y, z, a, true, 100.0, vw, int);
    JunkieActor[slot][E_JUNKIE_AREA_ID]    = INVALID_AREA_ID; // created after 5 s delay
    JunkieActor[slot][E_JUNKIE_LOC_SLOT]   = loc_slot;
    JunkieActor[slot][E_JUNKIE_SPAWN_TIME] = gettime();
    JunkieActor[slot][E_JUNKIE_HAD_SALE]   = false;
    JunkieActor[slot][E_JUNKIE_CREATED]    = true;

    GenerateJunkieDemands(slot);

    JunkieLocation[loc_slot][E_JLOC_ACTIVE_JUNKIE] = slot;

    SetTimerEx("DelayedJunkieSetup", 5000, false, "i", slot);

    return slot;
}

// set_cooldown = true  /- location enters 45-min cooldown (sale happened)
// set_cooldown = false /- location becomes immediately available again
DespawnJunkie(slot, bool: set_cooldown = false) {
    if(slot < 0 || slot >= MAX_ACTIVE_JUNKIES || !JunkieActor[slot][E_JUNKIE_CREATED])
        return 0;

    new loc_slot = JunkieActor[slot][E_JUNKIE_LOC_SLOT];

    if(IsValidDynamicActor(JunkieActor[slot][E_JUNKIE_ACTOR_ID]))
        DestroyDynamicActor(JunkieActor[slot][E_JUNKIE_ACTOR_ID]);

    if(IsValidDynamicArea(JunkieActor[slot][E_JUNKIE_AREA_ID]))
        DestroyDynamicArea(JunkieActor[slot][E_JUNKIE_AREA_ID]);

    if(loc_slot >= 0 && loc_slot < MAX_JUNKIE_LOCATIONS && JunkieLocation[loc_slot][E_JLOC_CREATED]) {
        JunkieLocation[loc_slot][E_JLOC_ACTIVE_JUNKIE] = INVALID_JUNKIE_SLOT;
        // Sale happened -> 45-min cooldown; no sale -> 30-min cooldown before respawn
        JunkieLocation[loc_slot][E_JLOC_COOLDOWN_UNTIL] = gettime() + (set_cooldown ? JUNKIE_COOLDOWN_TIME : JUNKIE_NO_SALE_COOLDOWN);
    }

    JunkieActor[slot][E_JUNKIE_ACTOR_ID]       = INVALID_ACTOR_ID;
    JunkieActor[slot][E_JUNKIE_AREA_ID]        = INVALID_AREA_ID;
    JunkieActor[slot][E_JUNKIE_LOC_SLOT]       = INVALID_JUNKIE_SLOT;
    JunkieActor[slot][E_JUNKIE_SKIN]           = 0;
    JunkieActor[slot][E_JUNKIE_SPAWN_TIME]     = 0;
    JunkieActor[slot][E_JUNKIE_HAD_SALE]       = false;
    JunkieActor[slot][E_JUNKIE_WEED_DEMAND]    = 0;
    JunkieActor[slot][E_JUNKIE_CRACK_DEMAND]   = 0;
    JunkieActor[slot][E_JUNKIE_COCAINE_DEMAND] = 0;
    JunkieActor[slot][E_JUNKIE_WEED_PRICE]     = 0;
    JunkieActor[slot][E_JUNKIE_CRACK_PRICE]    = 0;
    JunkieActor[slot][E_JUNKIE_COCAINE_PRICE]  = 0;
    JunkieActor[slot][E_JUNKIE_CREATED]        = false;

    return 1;
}

//  Fires every JUNKIE_CHECK_INTERVAL (30 s).
//  Pass 1 - expire any junkie that has been alive for JUNKIE_DESPAWN_TIME (30 min):
//      ## Had a sale  /- despawn + put the location on a 45-min cooldown.
//      ## No sale     /- despawn + put the location on a 30-min cooldown.
//
//  Pass 2 - spawn a new junkie at every location that has no active junkie
//            and whose cooldown has expired.

forward JunkieSystemTick();
// Repeating tick: spawns and despawns junkies around the map.
public JunkieSystemTick() {
    new current_time = gettime();

    // Pass 1: expire timed out junkies
    for(new i = 0; i < MAX_ACTIVE_JUNKIES; i++) {
        if(!JunkieActor[i][E_JUNKIE_CREATED]) continue;
        if(current_time - JunkieActor[i][E_JUNKIE_SPAWN_TIME] < JUNKIE_DESPAWN_TIME) continue;

        DespawnJunkie(i, JunkieActor[i][E_JUNKIE_HAD_SALE]);
    }

    // Pass 2: respawn at ready locations
    for(new i = 0; i < MAX_JUNKIE_LOCATIONS; i++) {
        if(!JunkieLocation[i][E_JLOC_CREATED]) continue;
        if(JunkieLocation[i][E_JLOC_ACTIVE_JUNKIE] != INVALID_JUNKIE_SLOT) continue;
        if(JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] > current_time) continue;

        SpawnJunkieAtLocation(i);
    }

    return 1;
}

// Loads the junkie spawn locations from the database.
LoadJunkieLocations() {
    new query[] = "SELECT * FROM `junkie_spawn_locations`";

    inline OnLoadLocations() {
        new count = cache_num_rows();

        for(new i = 0; i < count && i < MAX_JUNKIE_LOCATIONS; i++) {
            cache_get_value_name_int  (i, "id",           JunkieLocation[i][E_JLOC_SQLID]);
            cache_get_value_name_float(i, "pos_x",        JunkieLocation[i][E_JLOC_X]);
            cache_get_value_name_float(i, "pos_y",        JunkieLocation[i][E_JLOC_Y]);
            cache_get_value_name_float(i, "pos_z",        JunkieLocation[i][E_JLOC_Z]);
            cache_get_value_name_float(i, "pos_a",        JunkieLocation[i][E_JLOC_A]);
            cache_get_value_name_int  (i, "zone_id",      JunkieLocation[i][E_JLOC_ZONE]);
            cache_get_value_name_int  (i, "faction_id",   JunkieLocation[i][E_JLOC_FACTION]);
            cache_get_value_name_int  (i, "skin",         JunkieLocation[i][E_JLOC_SKIN]);
            cache_get_value_name_int  (i, "virtualworld", JunkieLocation[i][E_JLOC_VIRTUALWORLD]);
            cache_get_value_name_int  (i, "interior",     JunkieLocation[i][E_JLOC_INTERIOR]);

            JunkieLocation[i][E_JLOC_ACTIVE_JUNKIE]  = INVALID_JUNKIE_SLOT;
            JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] = 0;
            JunkieLocation[i][E_JLOC_CREATED]        = true;

            SpawnJunkieAtLocation(i);
        }

        printf(" * [JUNKIES] Loaded %d spawn locations.", count);

        // Start the global maintenance timer ONLY ONCE
        if(JunkieCheckTimer == -1)
            JunkieCheckTimer = SetTimer("JunkieSystemTick", JUNKIE_CHECK_INTERVAL, true);
    }

    MySQL_TQueryInline(mysql, using inline OnLoadLocations, query, "");
}

// returns the location slot on success, INVALID_JUNKIE_LOC on failure.
AddJunkieLocation(Float: x, Float: y, Float: z, Float: a, zone_id, faction_id, skin = -1, virtualworld = 0, interior = 0) {
    new slot = INVALID_JUNKIE_LOC;
    for(new i = 0; i < MAX_JUNKIE_LOCATIONS; i++) {
        if(!JunkieLocation[i][E_JLOC_CREATED]) { slot = i; break; }
    }
    if(slot == INVALID_JUNKIE_LOC) return INVALID_JUNKIE_LOC;

    JunkieLocation[slot][E_JLOC_X]              = x;
    JunkieLocation[slot][E_JLOC_Y]              = y;
    JunkieLocation[slot][E_JLOC_Z]              = z;
    JunkieLocation[slot][E_JLOC_A]              = a;
    JunkieLocation[slot][E_JLOC_ZONE]           = zone_id;
    JunkieLocation[slot][E_JLOC_FACTION]        = faction_id;
    JunkieLocation[slot][E_JLOC_SKIN]           = skin;
    JunkieLocation[slot][E_JLOC_VIRTUALWORLD]   = virtualworld;
    JunkieLocation[slot][E_JLOC_INTERIOR]       = interior;
    JunkieLocation[slot][E_JLOC_ACTIVE_JUNKIE]  = INVALID_JUNKIE_SLOT;
    JunkieLocation[slot][E_JLOC_COOLDOWN_UNTIL] = 0;
    JunkieLocation[slot][E_JLOC_CREATED]        = true;

    new query[320];
    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO `junkie_spawn_locations` (`pos_x`, `pos_y`, `pos_z`, `pos_a`, `zone_id`, `faction_id`, `skin`, `virtualworld`, `interior`) VALUES (%.2f, %.2f, %.2f, %.2f, %d, %d, %d, %d, %d)",
        x, y, z, a, zone_id, faction_id, skin, virtualworld, interior);

    inline OnLocationInsert() {
        JunkieLocation[slot][E_JLOC_SQLID] = cache_insert_id();
    }
    MySQL_TQueryInline(mysql, using inline OnLocationInsert, query, "");

    SpawnJunkieAtLocation(slot);

    return slot;
}

// Removes a junkie spawn location and its junkie.
RemoveJunkieLocation(slot) {
    if(slot < 0 || slot >= MAX_JUNKIE_LOCATIONS || !JunkieLocation[slot][E_JLOC_CREATED])
        return 0;

    new junkie_slot = JunkieLocation[slot][E_JLOC_ACTIVE_JUNKIE];
    if(junkie_slot != INVALID_JUNKIE_SLOT)
        DespawnJunkie(junkie_slot, false);

    if(JunkieLocation[slot][E_JLOC_SQLID] > 0) {
        new query[128];
        mysql_format(mysql, query, sizeof(query),
            "DELETE FROM `junkie_spawn_locations` WHERE `id` = %d",
            JunkieLocation[slot][E_JLOC_SQLID]
        );
        mysql_tquery(mysql, query);
    }

    JunkieLocation[slot][E_JLOC_SQLID]          = 0;
    JunkieLocation[slot][E_JLOC_X]              = 0.0;
    JunkieLocation[slot][E_JLOC_Y]              = 0.0;
    JunkieLocation[slot][E_JLOC_Z]              = 0.0;
    JunkieLocation[slot][E_JLOC_A]              = 0.0;
    JunkieLocation[slot][E_JLOC_ZONE]           = -1;
    JunkieLocation[slot][E_JLOC_FACTION]        = -1;
    JunkieLocation[slot][E_JLOC_SKIN]           = -1;
    JunkieLocation[slot][E_JLOC_VIRTUALWORLD]   = 0;
    JunkieLocation[slot][E_JLOC_INTERIOR]       = 0;
    JunkieLocation[slot][E_JLOC_ACTIVE_JUNKIE]  = INVALID_JUNKIE_SLOT;
    JunkieLocation[slot][E_JLOC_COOLDOWN_UNTIL] = 0;
    JunkieLocation[slot][E_JLOC_CREATED]        = false;

    return 1;
}

// Returns the nearest junkie spawn location to a position.
GetNearestJunkieLocation(Float: x, Float: y, Float: max_dist = 10.0) {
    new closest      = INVALID_JUNKIE_LOC;
    new Float: best  = max_dist;

    for(new i = 0; i < MAX_JUNKIE_LOCATIONS; i++) {
        if(!JunkieLocation[i][E_JLOC_CREATED]) continue;
        new Float: d = GetDistanceFromPointToPoint(x, y,
            JunkieLocation[i][E_JLOC_X], JunkieLocation[i][E_JLOC_Y]);
        if(d < best) { best = d; closest = i; }
    }
    return closest;
}

// Returns how many dealers a faction is allowed (based on its member count).
GetMaxFactionDrugDealers(faction_sqlid) {
    new total_members = 0;

    foreach(new playerid : Player) {
        if(Character[playerid][E_CHARACTER_FACTIONID] == faction_sqlid)
            total_members++;
    }

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT COUNT(*) as total FROM `characters` WHERE `player_factionid` = %d",
        faction_sqlid
    );

    new Cache: result = mysql_query(mysql, query);
    new offline_members = 0;
    if(cache_num_rows() > 0)
        cache_get_value_name_int(0, "total", offline_members);
    cache_delete(result);

    total_members += offline_members;
    return floatround(float(total_members) / 3.0, floatround_ceil);
}

// Returns true if the faction has room for another dealer.
bool: CanPlayerBeDrugDealer(playerid, faction_sqlid) {
    #pragma unused playerid
    new current_dealers = 0;
    new max_dealers     = GetMaxFactionDrugDealers(faction_sqlid);

    foreach(new i : Player) {
        if(Character[i][E_CHARACTER_FACTIONID] == faction_sqlid &&
           PlayerDrugDealer[i][E_PLAYER_IS_DRUG_DEALER])
            current_dealers++;
    }

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT COUNT(*) as dealers FROM `character_drug_dealers` cd INNER JOIN `characters` c ON cd.character_id = c.player_id WHERE c.player_factionid = %d AND cd.is_dealer = 1", faction_sqlid);

    new Cache: result = mysql_query(mysql, query);
    new offline_dealers = 0;
    if(cache_num_rows() > 0)
        cache_get_value_name_int(0, "dealers", offline_dealers);
    cache_delete(result);

    current_dealers += offline_dealers;
    return (current_dealers < max_dealers);
}

// Returns true if a dealer has made enough sales to rank up.
bool: CanPlayerRankUp(playerid) {
    new rank  = PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK];
    new sales = PlayerDrugDealer[playerid][E_PLAYER_DRUG_TOTAL_SALES];

    switch(rank) {
        case DEALER_RANK_STREET:      return (sales >= SALES_REQUIRED_CORNER_BOSS);
        case DEALER_RANK_CORNER_BOSS: return (sales >= SALES_REQUIRED_STREET_BOSS);
        case DEALER_RANK_STREET_BOSS: return (sales >= SALES_REQUIRED_SUPPLIER);
    }
    return false;
}

// Returns the name of a dealer rank.
GetRankName(rank) {
    new name[32];
    switch(rank) {
        case DEALER_RANK_STREET:      format(name, sizeof(name), "Street Dealer");
        case DEALER_RANK_CORNER_BOSS: format(name, sizeof(name), "Corner Boss");
        case DEALER_RANK_STREET_BOSS: format(name, sizeof(name), "Street Boss");
        case DEALER_RANK_SUPPLIER:    format(name, sizeof(name), "Supplier");
        default:                      format(name, sizeof(name), "Unknown");
    }
    return name;
}

// Plays a trade animation on the player and the NPC.
ApplyDealTransactionAnimations(playerid, actor_id, anim_pick = -1) {
    new pick = (anim_pick == -1) ? random(3) : anim_pick;
    switch(pick) {
        case 0: ApplyAnimation(playerid, "DEALER", "DEALER_DEAL", 4.1, 0, 0, 0, 0, 0, 1);
        case 1: ApplyAnimation(playerid, "DEALER", "DRUGS_BUY",   4.1, 0, 0, 0, 0, 0, 1);
        case 2: ApplyAnimation(playerid, "DEALER", "shop_pay",    4.1, 0, 0, 0, 0, 0, 1);
    }
    if(IsValidDynamicActor(actor_id))
        ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_DEAL", 4.1, 0, 1, 1, 1, 0);
}

// Loads a player's dealer data (rank, sales) from the database.
LoadPlayerDrugDealerData(playerid) {
    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT * FROM `character_drug_dealers` WHERE `character_id` = %d",
        Character[playerid][E_CHARACTER_ID]
    );

    inline OnLoadDrugDealerData() {
        if(cache_num_rows() > 0) {
            cache_get_value_name_int(0, "is_dealer",       PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER]);
            cache_get_value_name_int(0, "dealer_rank",     PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK]);
            cache_get_value_name_int(0, "sales_today",     PlayerDrugDealer[playerid][E_PLAYER_DRUG_SALES_TODAY]);
            cache_get_value_name_int(0, "total_sales",     PlayerDrugDealer[playerid][E_PLAYER_DRUG_TOTAL_SALES]);
            cache_get_value_name_int(0, "last_sale_time",  PlayerDrugDealer[playerid][E_PLAYER_LAST_SALE_TIME]);
            cache_get_value_name_int(0, "junkie_cooldown_until", PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL]);
            cache_get_value_name_int(0, "junkie_pending_sale",   PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE]);
            cache_get_value_name_int(0, "street_npc_slot", PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT]);
            cache_get_value_name_int(0, "street_npc_slot2", PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2]);

        } else {
            PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER]   = false;
            PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] = 0;
            PlayerDrugDealer[playerid][E_PLAYER_DRUG_SALES_TODAY] = 0;
            PlayerDrugDealer[playerid][E_PLAYER_DRUG_TOTAL_SALES] = 0;
            PlayerDrugDealer[playerid][E_PLAYER_LAST_SALE_TIME]   = 0;
            PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL] = 0;
            PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE]   = false;
            PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT]  = INVALID_DRUG_DEALER_ID;
            PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2] = INVALID_DRUG_DEALER_ID;

        }
    }
    MySQL_TQueryInline(mysql, using inline OnLoadDrugDealerData, query, "");
}

// Saves a player's dealer data.
SavePlayerDrugDealerData(playerid) {
    new query[640];
    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO `character_drug_dealers` \
        (`character_id`, `is_dealer`, `dealer_rank`, `sales_today`, `total_sales`, `last_sale_time`, `street_npc_slot`, `street_npc_slot2`, `junkie_cooldown_until`, `junkie_pending_sale`) \
        VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d) \
        ON DUPLICATE KEY UPDATE \
        `is_dealer` = VALUES(`is_dealer`), \
        `dealer_rank` = VALUES(`dealer_rank`), \
        `sales_today` = VALUES(`sales_today`), \
        `total_sales` = VALUES(`total_sales`), \
        `last_sale_time` = VALUES(`last_sale_time`), \
        `street_npc_slot` = VALUES(`street_npc_slot`), \
        `street_npc_slot2` = VALUES(`street_npc_slot2`), \
        `junkie_cooldown_until` = VALUES(`junkie_cooldown_until`), \
        `junkie_pending_sale` = VALUES(`junkie_pending_sale`)",
        Character[playerid][E_CHARACTER_ID],
        PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER],
        PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK],
        PlayerDrugDealer[playerid][E_PLAYER_DRUG_SALES_TODAY],
        PlayerDrugDealer[playerid][E_PLAYER_DRUG_TOTAL_SALES],
        PlayerDrugDealer[playerid][E_PLAYER_LAST_SALE_TIME],
        PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT],
        PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2],
        PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL],
        PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE]
    );
    mysql_tquery(mysql, query);
}

forward DelayedApplyAnimation(npc_slot, anim_type);
// Timer callback: plays a dealer animation on a street boss NPC.
public DelayedApplyAnimation(npc_slot, anim_type) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED])
        return 0;
    new actor_id = StreetBossNPC[npc_slot][E_STREET_NPC_ID];
    if(!IsValidDynamicActor(actor_id)) return 0;
    switch(anim_type) {
        case 0: ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_IDLE",    4.1, 1, 1, 1, 1, 0);
        case 1: ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_IDLE_01", 4.1, 1, 1, 1, 1, 0);
        case 2: ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_IDLE_02", 4.1, 1, 1, 1, 1, 0);
        case 3: ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_IDLE_03", 4.1, 1, 1, 1, 1, 0);
    }
    return 1;
}

// Plays a random animation on a street boss NPC.
stock ApplyRandomDealerAnimation(npc_slot) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED]) return 0;
    if(!IsValidDynamicActor(StreetBossNPC[npc_slot][E_STREET_NPC_ID])) return 0;
    SetTimerEx("DelayedApplyAnimation", 1000, false, "ii", npc_slot, random(4));
    return 1;
}

forward DelayedApplyIdleAnimation(npc_slot);
// Timer callback: plays an idle animation on a street boss NPC.
public DelayedApplyIdleAnimation(npc_slot) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED]) return 0;
    new actor_id = StreetBossNPC[npc_slot][E_STREET_NPC_ID];
    if(!IsValidDynamicActor(actor_id)) return 0;
    ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_IDLE", 4.1, 1, 1, 1, 1, 0);
    return 1;
}

// Plays an idle animation on a street boss NPC after a delay.
stock ApplyDealerIdleAnimation(npc_slot) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED]) return 0;
    SetTimerEx("DelayedApplyIdleAnimation", 5000, false, "i", npc_slot);
    return 1;
}

forward DelayedStreetNPCSetup(slot);
// Timer callback: finishes setting up a street boss NPC actor.
public DelayedStreetNPCSetup(slot) {
    if(slot < 0 || slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[slot][E_STREET_NPC_CREATED]) return 0;
    new actor_id = StreetBossNPC[slot][E_STREET_NPC_ID];
    if(!IsValidDynamicActor(actor_id)) return 0;
    new Float: x = StreetBossNPC[slot][E_STREET_NPC_X];
    new Float: y = StreetBossNPC[slot][E_STREET_NPC_Y];
    new Float: z = StreetBossNPC[slot][E_STREET_NPC_Z];
    new vw  = StreetBossNPC[slot][E_STREET_NPC_VIRTUALWORLD];
    new int = StreetBossNPC[slot][E_STREET_NPC_INTERIOR];
    if(!IsValidDynamicArea(StreetBossNPC[slot][E_STREET_NPC_AREA]))
        StreetBossNPC[slot][E_STREET_NPC_AREA] = CreateDynamicSphere(x, y, z, 3.0, vw, int);
    ApplyDynamicActorAnimation(actor_id, "DEALER", "DEALER_IDLE", 4.1, 1, 1, 1, 1, 0);
    return 1;
}

// Creates a street boss NPC dealer at a position for a player.
stock CreateStreetBossNPC(playerid, Float: x, Float: y, Float: z, Float: a = 0.0, bool: admin_override = false, skin_override = -1, virtualworld = 0, interior = 0) {
    if(!admin_override && PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] != DEALER_RANK_STREET_BOSS)
        return INVALID_DRUG_DEALER_ID;
        
    new free_slot_index = INVALID_DRUG_DEALER_ID;
    if(!admin_override) {
        new max_slots = (PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] >= DEALER_RANK_SUPPLIER) ? 2 : 1;
        if(PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT] == INVALID_DRUG_DEALER_ID)
            free_slot_index = 0;
        else if(max_slots >= 2 && PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2] == INVALID_DRUG_DEALER_ID)
            free_slot_index = 1;
        else
            return INVALID_DRUG_DEALER_ID;
    }

    new slot = INVALID_DRUG_DEALER_ID;
    for(new i = 0; i < MAX_STREET_BOSS_NPCS; i++) {
        if(StreetBossNPC[i][E_STREET_NPC_CREATED] == 0) { slot = i; break; }
    }
    if(slot == INVALID_DRUG_DEALER_ID) return INVALID_DRUG_DEALER_ID;

    StreetBossNPC[slot][E_STREET_NPC_OWNER] = Character[playerid][E_CHARACTER_ID];
    format(StreetBossNPC[slot][E_STREET_NPC_OWNER_NAME], MAX_PLAYER_NAME, ReturnMixedName(playerid));
    StreetBossNPC[slot][E_STREET_NPC_X]            = x;
    StreetBossNPC[slot][E_STREET_NPC_Y]            = y;
    StreetBossNPC[slot][E_STREET_NPC_Z]            = z;
    StreetBossNPC[slot][E_STREET_NPC_A]            = a;
    StreetBossNPC[slot][E_STREET_NPC_SKIN]         = (skin_override != -1) ? skin_override : (28 + random(3));
    StreetBossNPC[slot][E_STREET_NPC_AREA]         = INVALID_AREA_ID;
    StreetBossNPC[slot][E_STREET_NPC_VIRTUALWORLD] = virtualworld;
    StreetBossNPC[slot][E_STREET_NPC_INTERIOR]     = interior;
    StreetBossNPC[slot][E_STREET_NPC_WEED_PRICE]   = 0;
    StreetBossNPC[slot][E_STREET_NPC_CRACK_PRICE]  = 0;
    StreetBossNPC[slot][E_STREET_NPC_COCAINE_PRICE]= 0;
    StreetBossNPC[slot][E_STREET_NPC_EARNINGS]     = 0;
    StreetBossNPC[slot][E_STREET_NPC_TOTAL_SALES]  = 0;
    StreetBossNPC[slot][E_STREET_NPC_SEIZED]       = false;
    StreetBossNPC[slot][E_STREET_NPC_SEIZED_BY]    = 0;

    StreetBossNPC[slot][E_STREET_NPC_ID] = CreateDynamicActor(
        StreetBossNPC[slot][E_STREET_NPC_SKIN], x, y, z, a, true, 100.0, virtualworld, interior);

    new owner_rank = PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK];
    if(owner_rank < DEALER_RANK_STREET_BOSS) {
        new label_text[64];
        format(label_text, sizeof(label_text), "Drug Dealer");
        StreetBossNPC[slot][E_STREET_NPC_LABEL] = CreateDynamic3DTextLabel(
            label_text, 0xDEDEDEFF, x, y, z + 1.0, 8.0,
            INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, virtualworld, interior);
    } else {
        StreetBossNPC[slot][E_STREET_NPC_LABEL] = DynamicText3D:INVALID_3DTEXT_ID;
    }

    StreetBossNPC[slot][E_STREET_NPC_CREATED] = 1;

    if(!admin_override) {
        if(free_slot_index == 0) PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT]  = slot;
        else PlayerDrugDealer[playerid][E_PLAYER_STREET_NPC_SLOT2] = slot;
    }

    SetTimerEx("DelayedStreetNPCSetup", 5000, false, "i", slot);

    new query[600];
    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO `street_boss_npcs`(`owner_id`, `owner_name`, `pos_x`, `pos_y`, `pos_z`, `pos_a`, `skin`, `weed_price`, `crack_price`, `cocaine_price`, `virtualworld`, `interior`) VALUES (%d, '%e', %.2f, %.2f, %.2f, %.2f, %d, %d, %d, %d, %d, %d)",
        Character[playerid][E_CHARACTER_ID], ReturnMixedName(playerid),
        x, y, z, a, StreetBossNPC[slot][E_STREET_NPC_SKIN],
        StreetBossNPC[slot][E_STREET_NPC_WEED_PRICE],
        StreetBossNPC[slot][E_STREET_NPC_CRACK_PRICE],
        StreetBossNPC[slot][E_STREET_NPC_COCAINE_PRICE],
        virtualworld, interior
    );
    inline OnStreetNPCInsert() {
        StreetBossNPC[slot][E_STREET_NPC_SQLID] = cache_insert_id();
    }
    MySQL_TQueryInline(mysql, using inline OnStreetNPCInsert, query, "");

    return slot;
}

// Destroys a street boss NPC and returns its stock to the owner.
DestroyStreetBossNPC(slot) {
    if(slot < 0 || slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[slot][E_STREET_NPC_CREATED])
        return 0;

    new owner = StreetBossNPC[slot][E_STREET_NPC_OWNER];
    foreach(new i : Player) {
        if(Character[i][E_CHARACTER_ID] == owner) {
            if(PlayerDrugDealer[i][E_PLAYER_STREET_NPC_SLOT] == slot)
                PlayerDrugDealer[i][E_PLAYER_STREET_NPC_SLOT]  = INVALID_DRUG_DEALER_ID;
            else if(PlayerDrugDealer[i][E_PLAYER_STREET_NPC_SLOT2] == slot)
                PlayerDrugDealer[i][E_PLAYER_STREET_NPC_SLOT2] = INVALID_DRUG_DEALER_ID;
            SavePlayerDrugDealerData(i);
            break;
        }
    }

    if(IsValidDynamicActor(StreetBossNPC[slot][E_STREET_NPC_ID]))
        DestroyDynamicActor(StreetBossNPC[slot][E_STREET_NPC_ID]);
    if(IsValidDynamicArea(StreetBossNPC[slot][E_STREET_NPC_AREA]))
        DestroyDynamicArea(StreetBossNPC[slot][E_STREET_NPC_AREA]);
    if(IsValidDynamic3DTextLabel(StreetBossNPC[slot][E_STREET_NPC_LABEL]))
        DestroyDynamic3DTextLabel(StreetBossNPC[slot][E_STREET_NPC_LABEL]);

    if(StreetBossNPC[slot][E_STREET_NPC_SQLID] > 0) {
        new query[256];
        mysql_format(mysql, query, sizeof(query),
            "DELETE FROM `street_boss_npcs` WHERE `id` = %d", StreetBossNPC[slot][E_STREET_NPC_SQLID]);
        mysql_tquery(mysql, query);
        mysql_format(mysql, query, sizeof(query),
            "DELETE FROM `street_boss_npc_stock` WHERE `npc_id` = %d", StreetBossNPC[slot][E_STREET_NPC_SQLID]);
        mysql_tquery(mysql, query);
    }

    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        NPCStock[slot][i][E_STOCK_DRUG_TYPE] = 0;
        NPCStock[slot][i][E_STOCK_TIER]      = 0;
        NPCStock[slot][i][E_STOCK_AMOUNT]    = 0.0;
        NPCStock[slot][i][E_STOCK_PRICE]     = 0;
        NPCStock[slot][i][E_STOCK_SQLID]     = 0;
    }

    StreetBossNPC[slot][E_STREET_NPC_ID]            = INVALID_ACTOR_ID;
    StreetBossNPC[slot][E_STREET_NPC_SQLID]         = 0;
    StreetBossNPC[slot][E_STREET_NPC_CREATED]       = 0;
    StreetBossNPC[slot][E_STREET_NPC_OWNER]         = INVALID_PLAYER_ID;
    StreetBossNPC[slot][E_STREET_NPC_AREA]          = INVALID_AREA_ID;
    StreetBossNPC[slot][E_STREET_NPC_LABEL]         = DynamicText3D:INVALID_3DTEXT_ID;
    StreetBossNPC[slot][E_STREET_NPC_X]             = 0.0;
    StreetBossNPC[slot][E_STREET_NPC_Y]             = 0.0;
    StreetBossNPC[slot][E_STREET_NPC_Z]             = 0.0;
    StreetBossNPC[slot][E_STREET_NPC_A]             = 0.0;
    StreetBossNPC[slot][E_STREET_NPC_SKIN]          = 0;
    StreetBossNPC[slot][E_STREET_NPC_CREATION_TIME] = 0;
    StreetBossNPC[slot][E_STREET_NPC_WEED_PRICE]    = 0;
    StreetBossNPC[slot][E_STREET_NPC_CRACK_PRICE]   = 0;
    StreetBossNPC[slot][E_STREET_NPC_COCAINE_PRICE] = 0;
    StreetBossNPC[slot][E_STREET_NPC_EARNINGS]      = 0;
    StreetBossNPC[slot][E_STREET_NPC_TOTAL_SALES]   = 0;
    StreetBossNPC[slot][E_STREET_NPC_VIRTUALWORLD]  = 0;
    StreetBossNPC[slot][E_STREET_NPC_INTERIOR]      = 0;
    StreetBossNPC[slot][E_STREET_NPC_SEIZED]        = false;
    StreetBossNPC[slot][E_STREET_NPC_SEIZED_BY]     = 0;
    format(StreetBossNPC[slot][E_STREET_NPC_OWNER_NAME], MAX_PLAYER_NAME, "");

    return 1;
}

// Finds the stock entry of a drug type and tier on an NPC.
GetNPCStockEntry(npc_slot, drug_type, tier) {
    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_DRUG_TYPE] == drug_type &&
           NPCStock[npc_slot][i][E_STOCK_TIER]      == tier      &&
           NPCStock[npc_slot][i][E_STOCK_AMOUNT]    >  0.0)
            return i;
    }
    return -1;
}

// Returns the total amount of a drug an NPC has in stock.
Float: GetNPCTotalStock(npc_slot, drug_type) {
    new Float: total = 0.0;
    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_DRUG_TYPE] == drug_type &&
           NPCStock[npc_slot][i][E_STOCK_AMOUNT]    >  0.0)
            total += NPCStock[npc_slot][i][E_STOCK_AMOUNT];
    }
    return total;
}

// Saves one NPC stock entry (amount and price).
SaveNPCStockEntry(npc_slot, entry_idx) {
    if(NPCStock[npc_slot][entry_idx][E_STOCK_SQLID] <= 0) return;
    new query[128];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE `street_boss_npc_stock` SET `amount` = %.2f, `price` = %d WHERE `id` = %d",
        NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT],
        NPCStock[npc_slot][entry_idx][E_STOCK_PRICE],
        NPCStock[npc_slot][entry_idx][E_STOCK_SQLID]
    );
    mysql_tquery(mysql, query);
}

// Deletes one NPC stock entry.
DeleteNPCStockEntry(npc_slot, entry_idx) {
    if(NPCStock[npc_slot][entry_idx][E_STOCK_SQLID] > 0) {
        new query[128];
        mysql_format(mysql, query, sizeof(query),
            "DELETE FROM `street_boss_npc_stock` WHERE `id` = %d",
            NPCStock[npc_slot][entry_idx][E_STOCK_SQLID]
        );
        mysql_tquery(mysql, query);
    }
    NPCStock[npc_slot][entry_idx][E_STOCK_DRUG_TYPE] = 0;
    NPCStock[npc_slot][entry_idx][E_STOCK_TIER]      = 0;
    NPCStock[npc_slot][entry_idx][E_STOCK_AMOUNT]    = 0.0;
    NPCStock[npc_slot][entry_idx][E_STOCK_PRICE]     = 0;
    NPCStock[npc_slot][entry_idx][E_STOCK_SQLID]     = 0;
}

// Adds stock to a street boss NPC at a given price.
AddNPCStock(npc_slot, drug_type, tier, Float: amount, price) {
    if(amount <= 0.0) return 0;

    new existing = GetNPCStockEntry(npc_slot, drug_type, tier);
    if(existing != -1) {
        NPCStock[npc_slot][existing][E_STOCK_AMOUNT] += amount;
        SaveNPCStockEntry(npc_slot, existing);
        return 1;
    }

    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_AMOUNT] <= 0.0) {
            NPCStock[npc_slot][i][E_STOCK_DRUG_TYPE] = drug_type;
            NPCStock[npc_slot][i][E_STOCK_TIER]      = tier;
            NPCStock[npc_slot][i][E_STOCK_AMOUNT]    = amount;
            NPCStock[npc_slot][i][E_STOCK_PRICE]     = price;
            NPCStock[npc_slot][i][E_STOCK_SQLID]     = 0;

            new query[256];
            mysql_format(mysql, query, sizeof(query),
                "INSERT INTO `street_boss_npc_stock` (`npc_id`, `drug_type`, `tier`, `amount`, `price`) VALUES (%d, %d, %d, %.2f, %d)",
                StreetBossNPC[npc_slot][E_STREET_NPC_SQLID], drug_type, tier, amount, price
            );
            inline OnStockInsert() {
                NPCStock[npc_slot][i][E_STOCK_SQLID] = cache_insert_id();
            }
            MySQL_TQueryInline(mysql, using inline OnStockInsert, query, "");
            return 1;
        }
    }
    return 0;
}

// Gives an NPC's stock of one drug type back to a player.
stock ReturnNPCDrugStockToPlayer(npc_slot, playerid, drug_type) {
    new Float: total = 0.0;
    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_DRUG_TYPE] == drug_type &&
           NPCStock[npc_slot][i][E_STOCK_AMOUNT]    >  0.0) {
            PlayerDrugs_AddSimple(playerid, drug_type,
                NPCStock[npc_slot][i][E_STOCK_AMOUNT],
                NPCStock[npc_slot][i][E_STOCK_TIER]);
            total += NPCStock[npc_slot][i][E_STOCK_AMOUNT];
            DeleteNPCStockEntry(npc_slot, i);
        }
    }
    if(total > 0.0) PlayerDrugs_Save(playerid);
    return Float: total;
}

// Gives all of an NPC's stock back to a player.
ReturnAllNPCStockToPlayer(npc_slot, playerid) {
    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_AMOUNT] > 0.0) {
            PlayerDrugs_AddSimple(playerid,
                NPCStock[npc_slot][i][E_STOCK_DRUG_TYPE],
                NPCStock[npc_slot][i][E_STOCK_AMOUNT],
                NPCStock[npc_slot][i][E_STOCK_TIER]);
            DeleteNPCStockEntry(npc_slot, i);
        }
    }
    PlayerDrugs_Save(playerid);
}

// Loads all street boss NPCs from the database.
LoadStreetBossNPCs() {
    new query[] = "SELECT n.*, COALESCE(d.dealer_rank, 2) AS owner_dealer_rank FROM `street_boss_npcs` n LEFT JOIN `character_drug_dealers` d ON d.character_id = n.owner_id";

    inline OnLoadStreetBossNPCs() {
        for(new i = 0, r = cache_num_rows(); i < r && i < MAX_STREET_BOSS_NPCS; i++) {
            new Float: x, Float: y, Float: z, Float: a;
            new owner_id, skin, vw, int, owner_dealer_rank;

            cache_get_value_name_int  (i, "id",                StreetBossNPC[i][E_STREET_NPC_SQLID]);
            cache_get_value_name_int  (i, "owner_id",          owner_id);
            cache_get_value_name_float(i, "pos_x", x);
            cache_get_value_name_float(i, "pos_y", y);
            cache_get_value_name_float(i, "pos_z", z);
            cache_get_value_name_float(i, "pos_a", a);
            cache_get_value_name_int  (i, "skin",  skin);
            cache_get_value_name_int  (i, "weed_price",        StreetBossNPC[i][E_STREET_NPC_WEED_PRICE]);
            cache_get_value_name_int  (i, "crack_price",       StreetBossNPC[i][E_STREET_NPC_CRACK_PRICE]);
            cache_get_value_name_int  (i, "cocaine_price",     StreetBossNPC[i][E_STREET_NPC_COCAINE_PRICE]);
            cache_get_value_name_int  (i, "earnings",          StreetBossNPC[i][E_STREET_NPC_EARNINGS]);
            cache_get_value_name_int  (i, "total_sales",       StreetBossNPC[i][E_STREET_NPC_TOTAL_SALES]);
            cache_get_value_name      (i, "owner_name",        StreetBossNPC[i][E_STREET_NPC_OWNER_NAME]);
            cache_get_value_name_int  (i, "virtualworld",      vw);
            cache_get_value_name_int  (i, "interior",          int);
            cache_get_value_name_int  (i, "owner_dealer_rank", owner_dealer_rank);

            StreetBossNPC[i][E_STREET_NPC_OWNER]        = owner_id;
            StreetBossNPC[i][E_STREET_NPC_X]            = x;
            StreetBossNPC[i][E_STREET_NPC_Y]            = y;
            StreetBossNPC[i][E_STREET_NPC_Z]            = z;
            StreetBossNPC[i][E_STREET_NPC_A]            = a;
            StreetBossNPC[i][E_STREET_NPC_SKIN]         = skin;
            StreetBossNPC[i][E_STREET_NPC_AREA]         = INVALID_AREA_ID;
            StreetBossNPC[i][E_STREET_NPC_VIRTUALWORLD] = vw;
            StreetBossNPC[i][E_STREET_NPC_INTERIOR]     = int;
            StreetBossNPC[i][E_STREET_NPC_SEIZED]       = false;
            StreetBossNPC[i][E_STREET_NPC_SEIZED_BY]    = 0;

            StreetBossNPC[i][E_STREET_NPC_ID] = CreateDynamicActor(skin, x, y, z, a, true, 100.0, vw, int);

            if(owner_dealer_rank < DEALER_RANK_STREET_BOSS) {
                new label_text[64];
                format(label_text, sizeof(label_text), "Drug Dealer");
                StreetBossNPC[i][E_STREET_NPC_LABEL] = CreateDynamic3DTextLabel(
                    label_text, 0xDEDEDEFF, x, y, z + 1.0, 8.0,
                    INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, vw, int);
            } else {
                StreetBossNPC[i][E_STREET_NPC_LABEL] = DynamicText3D:INVALID_3DTEXT_ID;
            }

            StreetBossNPC[i][E_STREET_NPC_CREATED] = 1;
            SetTimerEx("DelayedStreetNPCSetup", 5000, false, "i", i);
        }
        printf(" * [STREET BOSS NPCS] Loaded %d street boss NPCs.", cache_num_rows());
        LoadAllNPCStock();
    }
    MySQL_TQueryInline(mysql, using inline OnLoadStreetBossNPCs, query, "");
}

// Loads the stock of every street boss NPC.
LoadAllNPCStock() {
    new query[] = "SELECT * FROM `street_boss_npc_stock`";

    inline OnLoadAllNPCStock() {
        for(new i = 0, r = cache_num_rows(); i < r; i++) {
            new npc_sqlid, drug_type, tier, entry_sqlid;
            new Float: amount;

            cache_get_value_name_int  (i, "id",        entry_sqlid);
            cache_get_value_name_int  (i, "npc_id",    npc_sqlid);
            cache_get_value_name_int  (i, "drug_type", drug_type);
            cache_get_value_name_int  (i, "tier",      tier);
            cache_get_value_name_float(i, "amount",    amount);

            if(amount <= 0.0) continue;

            for(new s = 0; s < MAX_STREET_BOSS_NPCS; s++) {
                if(!StreetBossNPC[s][E_STREET_NPC_CREATED]) continue;
                if(StreetBossNPC[s][E_STREET_NPC_SQLID] != npc_sqlid) continue;

                for(new j = 0; j < MAX_NPC_STOCK_ENTRIES; j++) {
                    if(NPCStock[s][j][E_STOCK_AMOUNT] <= 0.0) {
                        NPCStock[s][j][E_STOCK_DRUG_TYPE] = drug_type;
                        NPCStock[s][j][E_STOCK_TIER]      = tier;
                        NPCStock[s][j][E_STOCK_AMOUNT]    = amount;
                        NPCStock[s][j][E_STOCK_SQLID]     = entry_sqlid;
                        cache_get_value_name_int(i, "price", NPCStock[s][j][E_STOCK_PRICE]);
                        break;
                    }
                }
                break;
            }
        }
        printf(" * [NPC STOCK] Loaded %d stock entries.", cache_num_rows());
    }
    MySQL_TQueryInline(mysql, using inline OnLoadAllNPCStock, query, "");
}

// Adds a quantity of a drug directly into the player's drug inventory.
PlayerDrugs_AddSimple(playerid, drug_type, Float: amount, tier = 1) {
    if(drug_type < E_DRUG_TYPE_WEED || drug_type > E_DRUG_TYPE_CRACK) return 0;

    amount = float(floatround(amount, floatround_floor));
    if(amount < 1.0) return 0;

    new player_enum_id = PlayerDrugs_GetFreeID(playerid);
    if(player_enum_id == INVALID_DRUG_ID) return 0;

    PlayerDrugs[playerid][player_enum_id][E_PLAYER_DRUG_TYPE]      = drug_type;
    PlayerDrugs[playerid][player_enum_id][E_PLAYER_DRUG_PARAM]     = tier;
    PlayerDrugs[playerid][player_enum_id][E_PLAYER_DRUG_CONTAINER] = 0;
    PlayerDrugs[playerid][player_enum_id][E_PLAYER_DRUG_AMOUNT]    = amount;

    PlayerDrugs_Save(playerid);
    return 1;
}


// Updates the label above a dealer NPC when its owner's rank changes.
stock UpdateDrugDealerLabel(npc_slot, new_rank) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED])
        return;

    new bool: should_have_label = (new_rank < DEALER_RANK_STREET_BOSS);
    new has_label         = IsValidDynamic3DTextLabel(StreetBossNPC[npc_slot][E_STREET_NPC_LABEL]);

    if(should_have_label && !has_label) {
        new Float: x = StreetBossNPC[npc_slot][E_STREET_NPC_X];
        new Float: y = StreetBossNPC[npc_slot][E_STREET_NPC_Y];
        new Float: z = StreetBossNPC[npc_slot][E_STREET_NPC_Z];
        new vw  = StreetBossNPC[npc_slot][E_STREET_NPC_VIRTUALWORLD];
        new int = StreetBossNPC[npc_slot][E_STREET_NPC_INTERIOR];
        new label_text[64];
        format(label_text, sizeof(label_text), "Drug Dealer");
        StreetBossNPC[npc_slot][E_STREET_NPC_LABEL] = CreateDynamic3DTextLabel(
            label_text, 0xDEDEDEFF, x, y, z + 1.0, 8.0,
            INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, vw, int);
    } else if(!should_have_label && has_label) {
        DestroyDynamic3DTextLabel(StreetBossNPC[npc_slot][E_STREET_NPC_LABEL]);
        StreetBossNPC[npc_slot][E_STREET_NPC_LABEL] = DynamicText3D:INVALID_3DTEXT_ID;
    }
}

// - despawns it and records who seized it
// - earnings go to the seizing officer's faction bank
// - all drug stock is confiscated (deleted from both memory and DB)
SeizeStreetBossNPC(cop_playerid, npc_slot) {
    if(npc_slot < 0 || npc_slot >= MAX_STREET_BOSS_NPCS || !StreetBossNPC[npc_slot][E_STREET_NPC_CREATED])
        return 0;

    if(IsValidDynamicActor(StreetBossNPC[npc_slot][E_STREET_NPC_ID]))
        DestroyDynamicActor(StreetBossNPC[npc_slot][E_STREET_NPC_ID]);
    if(IsValidDynamicArea(StreetBossNPC[npc_slot][E_STREET_NPC_AREA]))
        DestroyDynamicArea(StreetBossNPC[npc_slot][E_STREET_NPC_AREA]);
    if(IsValidDynamic3DTextLabel(StreetBossNPC[npc_slot][E_STREET_NPC_LABEL]))
        DestroyDynamic3DTextLabel(StreetBossNPC[npc_slot][E_STREET_NPC_LABEL]);

    StreetBossNPC[npc_slot][E_STREET_NPC_ID]    = INVALID_ACTOR_ID;
    StreetBossNPC[npc_slot][E_STREET_NPC_AREA]  = INVALID_AREA_ID;
    StreetBossNPC[npc_slot][E_STREET_NPC_LABEL] = DynamicText3D:INVALID_3DTEXT_ID;

    new earnings = StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS];
    if(earnings > 0) {
        new factionid       = Character[cop_playerid][E_CHARACTER_FACTIONID];
        new faction_enum_id = Faction_GetEnumID(factionid);
        if(faction_enum_id != -1)
            Faction_AddBankMoney(faction_enum_id, earnings, "Drug Dealer Arrested");
        StreetBossNPC[npc_slot][E_STREET_NPC_EARNINGS] = 0;
    }

    for(new i = 0; i < MAX_NPC_STOCK_ENTRIES; i++) {
        if(NPCStock[npc_slot][i][E_STOCK_AMOUNT] > 0.0)
            DeleteNPCStockEntry(npc_slot, i);
    }

    StreetBossNPC[npc_slot][E_STREET_NPC_SEIZED]    = true;
    StreetBossNPC[npc_slot][E_STREET_NPC_SEIZED_BY] = Character[cop_playerid][E_CHARACTER_ID];

    if(StreetBossNPC[npc_slot][E_STREET_NPC_SQLID] > 0) {
        new query[192];
        mysql_format(mysql, query, sizeof(query),
            "UPDATE `street_boss_npcs` SET `seized` = 1, `seized_by` = %d, `earnings` = 0 WHERE `id` = %d",
            Character[cop_playerid][E_CHARACTER_ID],
            StreetBossNPC[npc_slot][E_STREET_NPC_SQLID]
        );
        mysql_tquery(mysql, query);
    }

    foreach(new i : Player) {
        if(Character[i][E_CHARACTER_ID] == StreetBossNPC[npc_slot][E_STREET_NPC_OWNER]) {
            PlayerDrugDealer[i][E_PLAYER_STREET_NPC_SLOT] = INVALID_DRUG_DEALER_ID;
            SavePlayerDrugDealerData(i);
            SendClientMessage(i, 0xC47070FF, "{C47070}* {D0D5DA}Your street dealer has been seized by cops. His earnings have been confiscated.");
            break;
        }
    }

    StreetBossNPC[npc_slot][E_STREET_NPC_CREATED] = 0;

    return 1;
}

// Initialises all drug NPC data and loads junkies, street bosses and stock.
DrugDealer_Initialize() {

    for(new i = 0; i < MAX_JUNKIE_LOCATIONS; i++) {
        JunkieLocation[i][E_JLOC_SQLID]          = 0;
        JunkieLocation[i][E_JLOC_X]              = 0.0;
        JunkieLocation[i][E_JLOC_Y]              = 0.0;
        JunkieLocation[i][E_JLOC_Z]              = 0.0;
        JunkieLocation[i][E_JLOC_A]              = 0.0;
        JunkieLocation[i][E_JLOC_ZONE]           = -1;
        JunkieLocation[i][E_JLOC_FACTION]        = -1;
        JunkieLocation[i][E_JLOC_SKIN]           = -1;
        JunkieLocation[i][E_JLOC_VIRTUALWORLD]   = 0;
        JunkieLocation[i][E_JLOC_INTERIOR]       = 0;
        JunkieLocation[i][E_JLOC_ACTIVE_JUNKIE]  = INVALID_JUNKIE_SLOT;
        JunkieLocation[i][E_JLOC_COOLDOWN_UNTIL] = 0;
        JunkieLocation[i][E_JLOC_CREATED]        = false;
    }

    for(new i = 0; i < MAX_ACTIVE_JUNKIES; i++) {
        JunkieActor[i][E_JUNKIE_ACTOR_ID]       = INVALID_ACTOR_ID;
        JunkieActor[i][E_JUNKIE_AREA_ID]        = INVALID_AREA_ID;
        JunkieActor[i][E_JUNKIE_LOC_SLOT]       = INVALID_JUNKIE_SLOT;
        JunkieActor[i][E_JUNKIE_SKIN]           = 0;
        JunkieActor[i][E_JUNKIE_SPAWN_TIME]     = 0;
        JunkieActor[i][E_JUNKIE_HAD_SALE]       = false;
        JunkieActor[i][E_JUNKIE_WEED_DEMAND]    = 0;
        JunkieActor[i][E_JUNKIE_CRACK_DEMAND]   = 0;
        JunkieActor[i][E_JUNKIE_COCAINE_DEMAND] = 0;
        JunkieActor[i][E_JUNKIE_WEED_PRICE]     = 0;
        JunkieActor[i][E_JUNKIE_CRACK_PRICE]    = 0;
        JunkieActor[i][E_JUNKIE_COCAINE_PRICE]  = 0;
        JunkieActor[i][E_JUNKIE_CREATED]        = false;
    }

    // Street boss NPC slots
    for(new i = 0; i < MAX_STREET_BOSS_NPCS; i++) {
        StreetBossNPC[i][E_STREET_NPC_ID]            = INVALID_ACTOR_ID;
        StreetBossNPC[i][E_STREET_NPC_SQLID]         = 0;
        StreetBossNPC[i][E_STREET_NPC_CREATED]       = 0;
        StreetBossNPC[i][E_STREET_NPC_OWNER]         = INVALID_PLAYER_ID;
        StreetBossNPC[i][E_STREET_NPC_AREA]          = INVALID_AREA_ID;
        format(StreetBossNPC[i][E_STREET_NPC_OWNER_NAME], MAX_PLAYER_NAME, "");
        StreetBossNPC[i][E_STREET_NPC_X]             = 0.0;
        StreetBossNPC[i][E_STREET_NPC_Y]             = 0.0;
        StreetBossNPC[i][E_STREET_NPC_Z]             = 0.0;
        StreetBossNPC[i][E_STREET_NPC_A]             = 0.0;
        StreetBossNPC[i][E_STREET_NPC_SKIN]          = 0;
        StreetBossNPC[i][E_STREET_NPC_CREATION_TIME] = 0;
        StreetBossNPC[i][E_STREET_NPC_WEED_PRICE]    = 0;
        StreetBossNPC[i][E_STREET_NPC_CRACK_PRICE]   = 0;
        StreetBossNPC[i][E_STREET_NPC_COCAINE_PRICE] = 0;
        StreetBossNPC[i][E_STREET_NPC_EARNINGS]      = 0;
        StreetBossNPC[i][E_STREET_NPC_TOTAL_SALES]   = 0;
        StreetBossNPC[i][E_STREET_NPC_VIRTUALWORLD]  = 0;
        StreetBossNPC[i][E_STREET_NPC_INTERIOR]      = 0;
        StreetBossNPC[i][E_STREET_NPC_SEIZED]        = false;
        StreetBossNPC[i][E_STREET_NPC_SEIZED_BY]     = 0;
    }

    for(new i = 0; i < MAX_STREET_BOSS_NPCS; i++) {
        for(new j = 0; j < MAX_NPC_STOCK_ENTRIES; j++) {
            NPCStock[i][j][E_STOCK_DRUG_TYPE] = 0;
            NPCStock[i][j][E_STOCK_TIER]      = 0;
            NPCStock[i][j][E_STOCK_AMOUNT]    = 0.0;
            NPCStock[i][j][E_STOCK_PRICE]     = 0;
            NPCStock[i][j][E_STOCK_SQLID]     = 0;
        }
    }

    LoadJunkieLocations();
    LoadStreetBossNPCs();

    print(" * [DRUG DEALER] System initialized.");
}

hook OnPlayerConnect(playerid) {
    PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER]   = false;
    PlayerDrugDealer[playerid][E_PLAYER_DRUG_DEALER_RANK] = 0;
    PlayerDrugDealer[playerid][E_PLAYER_DRUG_SALES_TODAY] = 0;
    PlayerDrugDealer[playerid][E_PLAYER_DRUG_TOTAL_SALES] = 0;
    PlayerDrugDealer[playerid][E_PLAYER_LAST_SALE_TIME]   = 0;
    PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_COOLDOWN_UNTIL] = 0;
    PlayerDrugDealer[playerid][E_PLAYER_JUNKIE_PENDING_SALE]   = false;
    PlayerLastJunkieMsg[playerid]                         = 0;
    return 1;
}

hook OnPlayerSpawn(playerid) {
    if(IsPlayerLogged(playerid) && Character[playerid][E_CHARACTER_ID] != -1) LoadPlayerDrugDealerData(playerid);
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    if(!(newkeys & JUNKIE_INTERACT_KEY)) return 1;

    if(PlayerDrugDealer[playerid][E_PLAYER_IS_DRUG_DEALER]) {
        for(new i = 0; i < MAX_ACTIVE_JUNKIES; i++) {
            if(!JunkieActor[i][E_JUNKIE_CREATED]) continue;
            if(!IsValidDynamicArea(JunkieActor[i][E_JUNKIE_AREA_ID])) continue;
            if(!IsPlayerInDynamicArea(playerid, JunkieActor[i][E_JUNKIE_AREA_ID])) continue;

            ShowJunkieDialog(playerid, i);
            return 1;
        }
    }

    for(new i = 0; i < MAX_STREET_BOSS_NPCS; i++) {
        if(!StreetBossNPC[i][E_STREET_NPC_CREATED]) continue;
        if(!IsValidDynamicArea(StreetBossNPC[i][E_STREET_NPC_AREA])) continue;
        if(!IsPlayerInDynamicArea(playerid, StreetBossNPC[i][E_STREET_NPC_AREA])) continue;

        if(StreetBossNPC[i][E_STREET_NPC_OWNER] == Character[playerid][E_CHARACTER_ID])
            ShowStreetBossManagementDialog(playerid, i);
        else
            ShowStreetBossNPCDialog(playerid, i);
        return 1;
    }

    return 1;
}

#include <YSI_Coding\y_hooks>
hook OnStartSQL() {
    DrugDealer_Initialize();
}
