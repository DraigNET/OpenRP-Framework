// Fishing polygons are loaded from runtime_locations and their ordered vertices.
// Replacing an area does not remove caught fish or change inventory.
new FishArea[32], FishAreaCount;
new FishNames[13][11] =
{
	"Carp", "Cat Fish", "Cod", "Conger Eel", "Dog Fish", "Herring",
	"Pollack", "Salmon", "Sardine", "Shark", "Swordfish", "Trout", "Turtle"
};


// Stage every polygon before releasing old handles; close the boundary explicitly.
Runtime_RebuildFishing() {
    new areas[32], count;
    for(new i; i<RuntimeLocationCount; i++) {
        if(RuntimeLocations[i][RLOC_CATEGORY]!=RT_CATEGORY_FISHING || !RuntimeLocations[i][RLOC_ENABLED]) continue;
        if(count>=32) return 0;
        new Float:points[(RT_MAX_VERTICES+1)*2], vertices=RuntimeLocations[i][RLOC_VERTICES];
        for(new v; v<vertices; v++) { points[v*2]=RuntimeVertices[i][v][0]; points[v*2+1]=RuntimeVertices[i][v][1]; }
        points[vertices*2]=points[0]; points[vertices*2+1]=points[1];
        areas[count]=CreateDynamicPolygon(points,-20000.0,20000.0,(vertices+1)*2,RuntimeLocations[i][RLOC_WORLD],RuntimeLocations[i][RLOC_INTERIOR],-1);
        count++;
        if(!IsValidDynamicArea(areas[count-1])) {
            for(new n; n<count; n++) if(IsValidDynamicArea(areas[n])) DestroyDynamicArea(areas[n]);
            return 0;
        }
    }
    for(new i; i<FishAreaCount; i++) if(IsValidDynamicArea(FishArea[i])) DestroyDynamicArea(FishArea[i]);
    FishAreaCount=count;
    for(new i; i<count; i++) FishArea[i]=areas[i];
    return 1;
}
