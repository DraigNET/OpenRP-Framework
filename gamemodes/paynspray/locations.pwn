// Garages use stable runtime location records. Handles are staged before replacement,
// so a failed streamer allocation leaves the previous world intact.
new DynamicText3D:GarageLabels[64], GarageIcons[64], GarageCount;

forward LoadPayNSpray();
public LoadPayNSpray() {
    new DynamicText3D:labels[64], icons[64], count;
    for (new i; i<RuntimeLocationCount; i++) {
        if (RuntimeLocations[i][RLOC_CATEGORY]!=RT_CATEGORY_GARAGE || !RuntimeLocations[i][RLOC_ENABLED]) continue;
        if (count>=64) return 0;
        labels[count]=CreateDynamic3DTextLabel("{2172ff}Pay'n'Spray\n{DEDEDE}Use /repaircar or /carcolorlist",0xFFFFFFFF,
            RuntimeLocations[i][RLOC_X],RuntimeLocations[i][RLOC_Y],RuntimeLocations[i][RLOC_Z]+0.5,12.0,
            INVALID_PLAYER_ID,INVALID_VEHICLE_ID,true,RuntimeLocations[i][RLOC_WORLD],RuntimeLocations[i][RLOC_INTERIOR]);
        icons[count]=CreateDynamicMapIcon(RuntimeLocations[i][RLOC_X],RuntimeLocations[i][RLOC_Y],RuntimeLocations[i][RLOC_Z],63,-1,
            RuntimeLocations[i][RLOC_WORLD],RuntimeLocations[i][RLOC_INTERIOR]);
        count++;
        if (!IsValidDynamic3DTextLabel(labels[count-1]) || !IsValidDynamicMapIcon(icons[count-1])) {
            for (new n; n<count; n++) { if(IsValidDynamic3DTextLabel(labels[n])) DestroyDynamic3DTextLabel(labels[n]); if(IsValidDynamicMapIcon(icons[n])) DestroyDynamicMapIcon(icons[n]); }
            return 0;
        }
    }
    for (new i; i<GarageCount; i++) { if(IsValidDynamic3DTextLabel(GarageLabels[i])) DestroyDynamic3DTextLabel(GarageLabels[i]); if(IsValidDynamicMapIcon(GarageIcons[i])) DestroyDynamicMapIcon(GarageIcons[i]); }
    GarageCount=count;
    for (new i; i<count; i++) { GarageLabels[i]=labels[i]; GarageIcons[i]=icons[i]; }
    return 1;
}

// Both world and interior must match; enabled coordinates at zero are valid.
IsPlayerNearPayNSpray(playerid) {
    for (new i; i<RuntimeLocationCount; i++)
        if (RuntimeLocations[i][RLOC_CATEGORY]==RT_CATEGORY_GARAGE && Runtime_AtLocation(playerid,i)) return true;
    return false;
}
