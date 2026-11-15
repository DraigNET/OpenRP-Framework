#if !defined MAX_REMOVED_BUILDINGS
    #define MAX_REMOVED_BUILDINGS 2000
#endif

#if !defined DEBUG_REMOVED_BUILDINGS
    #define DEBUG_REMOVED_BUILDINGS false
#endif


enum E_REMOVED_BUILDING {
    e_ModelID,
    Float:e_PosX,
    Float:e_PosY,
    Float:e_PosZ,
    Float:e_Radius
}

static RemovedBuildings[MAX_REMOVED_BUILDINGS][E_REMOVED_BUILDING];
static RemovedBuildingCount  = 0;
static RemovedDuplicateCount = 0;


stock RemoveBuilding(modelid, Float:fX, Float:fY, Float:fZ, Float:fRadius = 0.25)
{   
    /*
    if(modelid < -1 || modelid > 20000) {
        printf("[RemoveBuilding] Error: Invalid model ID %d", modelid);
        return -1;
    }
    */
    if(fRadius < 0.0 || fRadius > 10000.0) {
        printf("[RemoveBuilding] Error: Invalid radius %.2f (must be 0.0-10000.0)", fRadius);
        return -1;
    }
    
    if(RemovedBuildingCount >= MAX_REMOVED_BUILDINGS) {
        printf("[RemoveBuilding] Error: Cannot remove more buildings. Limit: %d", MAX_REMOVED_BUILDINGS);
        return -1;
    }
    
    for(new i = 0; i < RemovedBuildingCount; i++) {
        if(RemovedBuildings[i][e_ModelID] == modelid &&
           RemovedBuildings[i][e_PosX]    == fX &&
           RemovedBuildings[i][e_PosY]    == fY &&
           RemovedBuildings[i][e_PosZ]    == fZ)
        {
            RemovedDuplicateCount++;
            return i;
        }
    }
    
    new slot = RemovedBuildingCount;
    RemovedBuildings[slot][e_ModelID] = modelid;
    RemovedBuildings[slot][e_PosX]    = fX;
    RemovedBuildings[slot][e_PosY]    = fY;
    RemovedBuildings[slot][e_PosZ]    = fZ;
    RemovedBuildings[slot][e_Radius]  = fRadius;
    
    RemovedBuildingCount++;

    #if DEBUG_REMOVED_BUILDINGS true
        printf("[RemoveBuilding] Added slot %d — Model: %d | Pos: (%.2f, %.2f, %.2f) | Radius: %.2f",
            slot, modelid, fX, fY, fZ, fRadius);
    #endif
    
    for(new i = 0, maxplayers = GetMaxPlayers(); i < maxplayers; i++) {
        if(IsPlayerConnected(i)) {
            RemoveBuildingForPlayer(i, modelid, fX, fY, fZ, fRadius);
        }
    }
    
    return slot;
}

stock RemoveBuildingsForPlayer(playerid)
{
    if(!IsPlayerConnected(playerid)) {
        return 0;
    }
    
    for(new i = 0; i < RemovedBuildingCount; i++) {
        RemoveBuildingForPlayer(
            playerid,
            RemovedBuildings[i][e_ModelID],
            RemovedBuildings[i][e_PosX],
            RemovedBuildings[i][e_PosY],
            RemovedBuildings[i][e_PosZ],
            RemovedBuildings[i][e_Radius]
        );
    }
    
    return RemovedBuildingCount;
}

stock GetRemovedBuildingCount()
{
    return RemovedBuildingCount;
}

stock GetRemovedDuplicateCount()
{
    return RemovedDuplicateCount;
}

stock PrintRemovedBuildings()
{
    printf("[RemoveBuilding] Removed %d objects globally (%d duplicates skipped)", RemovedBuildingCount, RemovedDuplicateCount);
    for(new i = 0; i < RemovedBuildingCount; i++) {
        printf("[RemoveBuilding] [%04d] Model: %d | Pos: (%.2f, %.2f, %.2f) | Radius: %.2f",i, RemovedBuildings[i][e_ModelID], RemovedBuildings[i][e_PosX], RemovedBuildings[i][e_PosY], RemovedBuildings[i][e_PosZ], RemovedBuildings[i][e_Radius]);
    }
    printf("[RemoveBuilding] End of List");
    return RemovedBuildingCount;
}

/*
stock ClearRemovedBuildings()
{
    for(new i = 0; i < RemovedBuildingCount; i++) {
        RemovedBuildings[i][e_ModelID] = 0;
        RemovedBuildings[i][e_PosX] = 0.0;
        RemovedBuildings[i][e_PosY] = 0.0;
        RemovedBuildings[i][e_PosZ] = 0.0;
        RemovedBuildings[i][e_Radius] = 0.0;
    }
    RemovedBuildingCount = 0;
}
*/