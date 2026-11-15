// ============================================================================
// File: visuals/maps/template.pwn
// A TEMPLATE map file: copy it, add CreateDynamicObject calls in the OnGameModeInit hook and
// RemoveBuilding calls in the OnRemoveBuilding hook, then include it from
// visuals/maps/header.pwn.
// ============================================================================

#include <YSI_Coding\y_hooks>
hook OnRemoveBuilding() {
    //RemoveBuilding(5523, 2021.6563, -1810.7266, 18.6016, 0.25);
}

#include <YSI_Coding\y_hooks>
hook OnGameModeInit() {
    LoadTemplateMap();
    return 1;
}

LoadTemplateMap() {
    // Create objects
    //CreateDynamicObject(-1240,2015.993408,-1822.312378,12.523300 , 0.000000,0.000000,0.000000 ,-1,-1,-1, 820.0, 800.0, -1, 0);
}