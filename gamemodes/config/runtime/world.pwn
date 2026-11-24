// Simple services and custom points share tracked markers. Service commands,
// enabled state and GPS read the same source records, including at 0,0,0.
new DynamicText3D:RuntimeServiceLabels[RT_MAX_LOCATIONS], RuntimeServicePickups[RT_MAX_LOCATIONS], RuntimeServiceIcons[RT_MAX_LOCATIONS];
Runtime_RebuildServices() {
    new DynamicText3D:labels[RT_MAX_LOCATIONS], pickups[RT_MAX_LOCATIONS], icons[RT_MAX_LOCATIONS];
    for(new source; source<RuntimeLocationCount; source++) {
        if(RuntimeLocations[source][RLOC_CATEGORY]!=RT_CATEGORY_SERVICE || !RuntimeLocations[source][RLOC_ENABLED]) continue;
        // These systems own specialised objects or deliberately have no public marker.
        if(source==RT_LOC_DMV || source==RT_LOC_ADMIN_JAIL || source==RT_LOC_STAFF_ROOM || source==RT_LOC_PRISON_RELEASE || source==RT_LOC_TRUCKER_DEPOT || source==RT_LOC_SAPD_DESK || source==RT_LOC_ADMINISTRATION_DESK) continue;
        new commands[64], icon=37;
        switch(source) {
            case RT_LOC_SCRAPYARD_LAND,RT_LOC_SCRAPYARD_BOAT,RT_LOC_SCRAPYARD_AIR: format(commands,sizeof commands,"/carscrap");
            case RT_LOC_CHOPSHOP: format(commands,sizeof commands,"/chopcar, /buylockpick");
            case RT_LOC_ADVERT_AGENCY: { format(commands,sizeof commands,"/advert, /rumour"); icon=6; }
            case RT_LOC_IMPOUND: format(commands,sizeof commands,"/impound, /unimpound");
            case RT_LOC_GARBAGE_DEPOT: format(commands,sizeof commands,"/garbagejob");
            case RT_LOC_HOSPITAL: { format(commands,sizeof commands,"Medical recovery"); icon=22; }
            case RT_LOC_GYM_LS,RT_LOC_GYM_SF,RT_LOC_GYM_LV,RT_LOC_GYM_GANTON,RT_LOC_GYM_BEACH: { format(commands,sizeof commands,"Gym"); icon=54; }
            default: format(commands,sizeof commands,"Point of interest");
        }
        labels[source]=CreateDynamic3DTextLabel(sprintf("[%s]\n{DEDEDE}%s",RuntimeLocations[source][RLOC_LABEL],commands),0x3479E3FF,
            RuntimeLocations[source][RLOC_X],RuntimeLocations[source][RLOC_Y],RuntimeLocations[source][RLOC_Z],15.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,true,RuntimeLocations[source][RLOC_WORLD],RuntimeLocations[source][RLOC_INTERIOR]);
        if(RuntimeLocations[source][RLOC_MODEL]) pickups[source]=CreateDynamicPickup(RuntimeLocations[source][RLOC_MODEL],1,RuntimeLocations[source][RLOC_X],RuntimeLocations[source][RLOC_Y],RuntimeLocations[source][RLOC_Z],RuntimeLocations[source][RLOC_WORLD],RuntimeLocations[source][RLOC_INTERIOR]);
        icons[source]=CreateDynamicMapIcon(RuntimeLocations[source][RLOC_X],RuntimeLocations[source][RLOC_Y],RuntimeLocations[source][RLOC_Z],icon,-1,RuntimeLocations[source][RLOC_WORLD],RuntimeLocations[source][RLOC_INTERIOR]);
        if(!IsValidDynamic3DTextLabel(labels[source]) || !IsValidDynamicMapIcon(icons[source]) || (RuntimeLocations[source][RLOC_MODEL] && !IsValidDynamicPickup(pickups[source]))) {
            for(new n; n<RT_MAX_LOCATIONS; n++) { if(IsValidDynamic3DTextLabel(labels[n])) DestroyDynamic3DTextLabel(labels[n]); if(IsValidDynamicPickup(pickups[n])) DestroyDynamicPickup(pickups[n]); if(IsValidDynamicMapIcon(icons[n])) DestroyDynamicMapIcon(icons[n]); }
            return 0;
        }
    }
    for(new i; i<RT_MAX_LOCATIONS; i++) {
        if(IsValidDynamic3DTextLabel(RuntimeServiceLabels[i])) DestroyDynamic3DTextLabel(RuntimeServiceLabels[i]);
        if(IsValidDynamicPickup(RuntimeServicePickups[i])) DestroyDynamicPickup(RuntimeServicePickups[i]);
        if(IsValidDynamicMapIcon(RuntimeServiceIcons[i])) DestroyDynamicMapIcon(RuntimeServiceIcons[i]);
        RuntimeServiceLabels[i]=labels[i]; RuntimeServicePickups[i]=pickups[i]; RuntimeServiceIcons[i]=icons[i];
    }
    Server[E_SERVER_CHOPSHOP_LABEL]=labels[RT_LOC_CHOPSHOP];
    return 1;
}

// Runtime adapters are registered here after all modules have been included.
// Each adapter owns the handles/state it replaces; startup loaders are not a
// substitute for an entity-safe hot reload.
forward ORP_OnRuntimeConfigApplied(revision, initial);
public ORP_OnRuntimeConfigApplied(revision, initial) {
    #pragma unused revision
    // Entity-only and scalar-only saves do not recreate unrelated map markers.
    if(Runtime_WorldChanged()) {
        if (!Runtime_RebuildPrisonCells()) { print("[Runtime adapter] Move prisoners out of affected cells first."); return 0; }
        if (!Runtime_RebuildServices()) return 0;
        if (!AdminJail_Rebuild()) return 0;
        if (!DMV_Init()) { print("[Runtime adapter] DMV failed."); return 0; }
        if (!LoadPayNSpray()) { print("[Runtime adapter] Garages failed."); return 0; }
        if (!Runtime_RebuildFishing()) { print("[Runtime adapter] Fishing failed."); return 0; }
        if (!Trucker_LoadEntities()) { print("[Runtime adapter] Trucker depot failed."); return 0; }
        if (!GarbageJob_LoadEntities()) { print("[Runtime adapter] Garbage points failed."); return 0; }
        if (!Fine_LoadLabel()) { print("[Runtime adapter] Help desks failed."); return 0; }
        Runtime_RebuildSpawns();
        if(!Runtime_RebuildGPS()) return 0;
    }
    if(initial || Runtime_IntegerChanged(RT_PAYCHECK_INTERVAL_MINUTES)) Paycheck_Reschedule();
    if (!Runtime_Int(RT_WEATHER_AUTOMATIC) && (initial || Runtime_IntegerChanged(RT_WEATHER_AUTOMATIC) || Runtime_IntegerChanged(RT_WEATHER_FIXED_ID))) ORP_SetWeather(Runtime_Int(RT_WEATHER_FIXED_ID));
    if(initial || Runtime_TextChanged(RT_IDENTITY_MODE)) SetGameModeText(RuntimeText[RT_IDENTITY_MODE]);
    new command[300];
    if(initial || Runtime_TextChanged(RT_IDENTITY_NAME)) { format(command,sizeof command,"hostname %s",RuntimeText[RT_IDENTITY_NAME]); SendRconCommand(command); }
    if(initial || Runtime_TextChanged(RT_IDENTITY_MAP)) { format(command,sizeof command,"mapname %s",RuntimeText[RT_IDENTITY_MAP]); SendRconCommand(command); }
    if(initial || Runtime_TextChanged(RT_IDENTITY_WEBSITE)) { format(command,sizeof command,"weburl %s",RuntimeText[RT_IDENTITY_WEBSITE]); SendRconCommand(command); }
    return 1;
}
