// ============================================================================
// File: property/runtime.pwn
// Live placement editor adapter for existing properties.
// ============================================================================
// Property placement reloads preserve the original slots and all economic,
// inventory and furniture data. New visuals stay hidden until the whole revision
// succeeds. Interior moves require an empty old world/interior.
#define RT_PROPERTY_FIELDS (20)
static const RuntimePropertyColumns[RT_PROPERTY_FIELDS][]={"property_ext_x","property_ext_y","property_ext_z","property_ext_int","property_ext_vw","property_int_x","property_int_y","property_int_z","property_int_int","property_int_vw","property_buy_pos_x","property_buy_pos_y","property_buy_pos_z","property_buy_pos_int","property_buy_pos_vw","property_extra_pos_x","property_extra_pos_y","property_extra_pos_z","property_extra_pos_int","property_extra_pos_vw"};
static const E_PROPERTY_DATA:RuntimePropertyFields[RT_PROPERTY_FIELDS]={E_PROPERTY_EXT_X,E_PROPERTY_EXT_Y,E_PROPERTY_EXT_Z,E_PROPERTY_EXT_INT,E_PROPERTY_EXT_VW,E_PROPERTY_INT_X,E_PROPERTY_INT_Y,E_PROPERTY_INT_Z,E_PROPERTY_INT_INT,E_PROPERTY_INT_VW,E_PROPERTY_BUY_POS_X,E_PROPERTY_BUY_POS_Y,E_PROPERTY_BUY_POS_Z,E_PROPERTY_BUY_POS_INT,E_PROPERTY_BUY_POS_VW,E_PROPERTY_EXTRA_POS_X,E_PROPERTY_EXTRA_POS_Y,E_PROPERTY_EXTRA_POS_Z,E_PROPERTY_EXTRA_POS_INT,E_PROPERTY_EXTRA_POS_VW};
static RuntimePropertyStage[MAX_PROPERTIES][RT_PROPERTY_FIELDS],RuntimePropertyIndex[MAX_PROPERTIES],RuntimePropertyCount;
static RuntimePropertyVisuals[MAX_PROPERTIES][7]; // circle, three pickups, map icon, label, changed
static bool:RuntimePropertyInteriorChanged[MAX_PROPERTIES];

// Read property placement and saved offline occupancy in one revision snapshot.
Runtime_QueryProperties(query[],size) {
    format(query,size,"SELECT -1 kind,0 id,0 property_ext_x,0 property_ext_y,0 property_ext_z,0 property_ext_int,0 property_ext_vw,0 property_int_x,0 property_int_y,0 property_int_z,0 property_int_int,0 property_int_vw,0 property_buy_pos_x,0 property_buy_pos_y,0 property_buy_pos_z,0 property_buy_pos_int,0 property_buy_pos_vw,0 property_extra_pos_x,0 property_extra_pos_y,0 property_extra_pos_z,0 property_extra_pos_int,0 property_extra_pos_vw,s.revision FROM runtime_config_state s WHERE s.id=1 ");
    strcat(query,"UNION ALL SELECT 0,property_id,p.property_ext_x,p.property_ext_y,p.property_ext_z,p.property_ext_int,p.property_ext_vw,p.property_int_x,p.property_int_y,p.property_int_z,p.property_int_int,p.property_int_vw,p.property_buy_pos_x,p.property_buy_pos_y,p.property_buy_pos_z,p.property_buy_pos_int,p.property_buy_pos_vw,p.property_extra_pos_x,p.property_extra_pos_y,p.property_extra_pos_z,p.property_extra_pos_int,p.property_extra_pos_vw,s.revision FROM properties p JOIN runtime_config_state s ON s.id=1 ",size);
    strcat(query,"UNION ALL SELECT 1,COUNT(*),0,0,0,0,0,0,0,0,player_last_pos_int,player_last_pos_vw,0,0,0,0,0,0,0,0,0,0,s.revision FROM characters JOIN runtime_config_state s ON s.id=1 WHERE player_online=0 GROUP BY player_last_pos_int,player_last_pos_vw,s.revision ORDER BY kind,id",size);
    return 1;
}

// Only staged handles are destroyed; the currently active property stays intact.
Runtime_CancelPropertyStage() {
    for(new row; row<RuntimePropertyCount; row++) if(RuntimePropertyVisuals[row][6]) {
        if(IsValidDynamicArea(RuntimePropertyVisuals[row][0])) DestroyDynamicArea(RuntimePropertyVisuals[row][0]);
        for(new c=1;c<=3;c++) if(IsValidDynamicPickup(RuntimePropertyVisuals[row][c])) DestroyDynamicPickup(RuntimePropertyVisuals[row][c]);
        if(IsValidDynamicMapIcon(RuntimePropertyVisuals[row][4])) DestroyDynamicMapIcon(RuntimePropertyVisuals[row][4]);
        if(IsValidDynamic3DTextLabel(DynamicText3D:RuntimePropertyVisuals[row][5])) DestroyDynamic3DTextLabel(DynamicText3D:RuntimePropertyVisuals[row][5]);
        RuntimePropertyVisuals[row][6]=0;
    }
    return 1;
}

// Online players and an in-progress enter/exit fade keep the old destination.
stock Runtime_PropertyInteriorInUse(index) {
    foreach(new player:Player) {
        if(GetPlayerInterior(player)==Property[index][E_PROPERTY_INT_INT] && GetPlayerVirtualWorld(player)==Property[index][E_PROPERTY_INT_VW]) return 1;
        if(IsPlayerFading(player) && PlayerVar[player][E_PLAYER_LAST_PROPERTY_ENTERED]==index) return 1;
    }
    return 0;
}

// Accepted deliveries and burglary sessions keep their existing entrance.
stock Runtime_PropertyEntranceInUse(index) {
    if(Trucker_PropertyInUse(Property[index][E_PROPERTY_ID]) || Pizza_PropertyInUse(index)) return 1;
    foreach(new player:Player) if(PlayerBurglaryProperty[player]==index) return 1;
    return 0;
}

// Construct labels from existing business metadata, without changing gameplay data.
static Runtime_PropertyBuildVisuals(row,index) {
    new data[E_PROPERTY_DATA]; data=Property[index];
    for(new c;c<RT_PROPERTY_FIELDS;c++) data[RuntimePropertyFields[c]]=RuntimePropertyStage[row][c];
    new pickup=1239,icon;
    switch(data[E_PROPERTY_TYPE]) {
        case E_PROPERTY_TYPE_HOUSE: pickup=(data[E_PROPERTY_OWNER]!=INVALID_PROPERTY_OWNER && data[E_PROPERTY_FIRM_PRICE]<=0)?1273:1272;
        case E_PROPERTY_TYPE_BIZ: { pickup=PropertyType_GetPickup(data[E_PROPERTY_BUY_TYPE]); icon=PropertyType_GetMapIcon(data[E_PROPERTY_BUY_TYPE]); }
    }
    RuntimePropertyVisuals[row][6]=1;
    RuntimePropertyVisuals[row][0]=CreateDynamicCircle(data[E_PROPERTY_EXT_X],data[E_PROPERTY_EXT_Y],PROPERTY_AREA_CIRCLE,RT_STAGING_WORLD,data[E_PROPERTY_EXT_INT]);
    RuntimePropertyVisuals[row][1]=CreateDynamicPickup(pickup,1,data[E_PROPERTY_EXT_X],data[E_PROPERTY_EXT_Y],data[E_PROPERTY_EXT_Z],RT_STAGING_WORLD,data[E_PROPERTY_EXT_INT],-1,PROPERTY_PICKUP_DRAW_DIST);
    RuntimePropertyVisuals[row][2]=CreateDynamicPickup(19902,1,data[E_PROPERTY_INT_X],data[E_PROPERTY_INT_Y],data[E_PROPERTY_INT_Z],RT_STAGING_WORLD,data[E_PROPERTY_INT_INT],-1,PROPERTY_PICKUP_DRAW_DIST);
    RuntimePropertyVisuals[row][3]=CreateDynamicPickup(pickup,1,data[E_PROPERTY_BUY_POS_X],data[E_PROPERTY_BUY_POS_Y],data[E_PROPERTY_BUY_POS_Z],RT_STAGING_WORLD,data[E_PROPERTY_BUY_POS_INT],-1,PROPERTY_PICKUP_DRAW_DIST);
    if(icon) RuntimePropertyVisuals[row][4]=CreateDynamicMapIcon(data[E_PROPERTY_EXT_X],data[E_PROPERTY_EXT_Y],data[E_PROPERTY_EXT_Z],icon,0xFFFFFFFF,RT_STAGING_WORLD,data[E_PROPERTY_EXT_INT],-1,PROPERTY_PICKUP_DRAW_DIST);
    if(data[E_PROPERTY_BUY_TYPE]!=E_BUY_TYPE_NONE) {
        new name[32],commands[128],extra[32],label[256],bool:outside;
        PropertyType_GetName(data[E_PROPERTY_BUY_TYPE],name,sizeof name); PropertyType_GetCommand(data[E_PROPERTY_BUY_TYPE],commands,sizeof commands);
        switch(data[E_PROPERTY_BUY_TYPE]) {
            case E_BUY_TYPE_DEALERSHIP: {
                outside=true;
                switch(data[E_PROPERTY_EXTRA_TYPE]) { case 0: extra=" Budget "; case 1: extra=" Muscle "; case 2: extra=" Sports "; case 3: extra=" Utility "; case 4: extra=" Aircraft "; case 5: extra=" Bike "; case 6: extra=" Boat "; }
            }
            case E_BUY_TYPE_GASSTATION,E_BUY_TYPE_MODSHOP: outside=true;
        }
        format(label,sizeof label,"[%d] [%s%s]\n{DEDEDE}Available Commands: %s",index,extra,name,commands);
        RuntimePropertyVisuals[row][5]=_:CreateDynamic3DTextLabel(label,COLOR_PROPERTY,outside?data[E_PROPERTY_EXT_X]:data[E_PROPERTY_BUY_POS_X],outside?data[E_PROPERTY_EXT_Y]:data[E_PROPERTY_BUY_POS_Y],outside?data[E_PROPERTY_EXT_Z]:data[E_PROPERTY_BUY_POS_Z],15.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,true,RT_STAGING_WORLD,outside?data[E_PROPERTY_EXT_INT]:data[E_PROPERTY_BUY_POS_INT]);
        if(!IsValidDynamic3DTextLabel(DynamicText3D:RuntimePropertyVisuals[row][5])) return 0;
    }
    if(!IsValidDynamicArea(RuntimePropertyVisuals[row][0]) || (icon && !IsValidDynamicMapIcon(RuntimePropertyVisuals[row][4]))) return 0;
    for(new c=1;c<=3;c++) if(!IsValidDynamicPickup(RuntimePropertyVisuals[row][c])) return 0;
    return 1;
}

// Validate every coordinate before allocating; old interior occupancy is checked
// against both the live player list and the saved offline world/interior groups.
Runtime_StageProperties(expectedRevision) {
    Runtime_CancelPropertyStage(); RuntimePropertyCount=0;
    new rows=cache_num_rows(),revision;
    if(!rows) return 0;
    cache_get_value_name_int(0,"revision",revision);
    if(revision!=expectedRevision) return 0;
    for(new row;row<rows;row++) {
        new kind,id;cache_get_value_name_int(row,"kind",kind);cache_get_value_name_int(row,"id",id);
        if(kind!=0) continue;
        if(RuntimePropertyCount>=MAX_PROPERTIES || id<1) return 0;
        new index=Property_LinkSQLToEnum(id);
        if(index<0 || index>=MAX_PROPERTIES) return 0; // New entities need the existing creation path.
        new slot=RuntimePropertyCount++;RuntimePropertyIndex[slot]=index;RuntimePropertyInteriorChanged[slot]=false;
        for(new c;c<7;c++) RuntimePropertyVisuals[slot][c]=0;
        for(new c;c<RT_PROPERTY_FIELDS;c++) {
            if(c%5<3) {
                new Float:value;cache_get_value_name_float(row,RuntimePropertyColumns[c],value);
                if(!(floatabs(value)<=20000.0)) return 0;
                RuntimePropertyStage[slot][c]=_:value;
            }else {
                new value;cache_get_value_name_int(row,RuntimePropertyColumns[c],value);
                if(value<0 || (c%5==3 && value>255) || value>2147483000) return 0;
                RuntimePropertyStage[slot][c]=value;
            }
            if(c>=5 && c<10 && RuntimePropertyStage[slot][c]!=Property[index][RuntimePropertyFields[c]]) RuntimePropertyInteriorChanged[slot]=true;
        }
        if(RuntimePropertyInteriorChanged[slot] && Runtime_PropertyInteriorInUse(index)) return 0;
        new bool:entranceChanged;
        for(new c;c<5;c++) if(RuntimePropertyStage[slot][c]!=Property[index][RuntimePropertyFields[c]]) entranceChanged=true;
        if(entranceChanged && Runtime_PropertyEntranceInUse(index)) return 0;
    }
    if(RuntimePropertyCount!=Iter_Count(Properties)) return 0; // Do not silently discard deleted live properties.
    for(new row;row<rows;row++) {
        new kind;cache_get_value_name_int(row,"kind",kind);if(kind!=1) continue;
        new interior,world;cache_get_value_name_int(row,"property_int_int",interior);cache_get_value_name_int(row,"property_int_vw",world);
        for(new slot;slot<RuntimePropertyCount;slot++) if(RuntimePropertyInteriorChanged[slot]) {
            new index=RuntimePropertyIndex[slot];
            if(Property[index][E_PROPERTY_INT_INT]==interior && Property[index][E_PROPERTY_INT_VW]==world) return 0;
        }
    }
    for(new slot;slot<RuntimePropertyCount;slot++) {
        new index=RuntimePropertyIndex[slot],bool:changed;
        for(new c;c<RT_PROPERTY_FIELDS;c++) if(RuntimePropertyStage[slot][c]!=Property[index][RuntimePropertyFields[c]]) {changed=true;break;}
        if(changed && !Runtime_PropertyBuildVisuals(slot,index)) {Runtime_CancelPropertyStage();return 0;}
    }
    return 1;
}

// Reveal the new handles inside the final callback, preserving all target worlds.
Runtime_ActivatePropertyStage() {
    new worlds[1];
    for(new row;row<RuntimePropertyCount;row++) if(RuntimePropertyVisuals[row][6]) {
        for(new c;c<6;c++) if(RuntimePropertyVisuals[row][c]) {
            new type=STREAMER_TYPE_PICKUP;
            if(c==0) type=STREAMER_TYPE_AREA;else if(c==4) type=STREAMER_TYPE_MAP_ICON;else if(c==5) type=STREAMER_TYPE_3D_TEXT_LABEL;
            new worldField=4;if(c==2) worldField=9;else if(c==3) worldField=14;
            if(c==5) {
                new index=RuntimePropertyIndex[row];
                switch(Property[index][E_PROPERTY_BUY_TYPE]) {case E_BUY_TYPE_DEALERSHIP,E_BUY_TYPE_GASSTATION,E_BUY_TYPE_MODSHOP: {} default: worldField=14;}
            }
            worlds[0]=RuntimePropertyStage[row][worldField];
            if(!Streamer_SetArrayData(type,RuntimePropertyVisuals[row][c],E_STREAMER_WORLD_ID,worlds)) return 0;
        }
    }
    return 1;
}

// Replace placement and visual handles only. Do not copy cached owner, stock,
// money, weapon/drug storage, furniture or character state from the SQL snapshot.
Runtime_CommitProperties() {
    for(new row;row<RuntimePropertyCount;row++) if(RuntimePropertyVisuals[row][6]) {
        new index=RuntimePropertyIndex[row];
        if(IsValidDynamicArea(Property[index][E_PROPERTY_AREA])) DestroyDynamicArea(Property[index][E_PROPERTY_AREA]);
        for(new c;c<3;c++) if(IsValidDynamicPickup(Property[index][E_PROPERTY_PICKUP][c])) DestroyDynamicPickup(Property[index][E_PROPERTY_PICKUP][c]);
        if(IsValidDynamicMapIcon(Property[index][E_PROPERTY_MAPICON])) DestroyDynamicMapIcon(Property[index][E_PROPERTY_MAPICON]);
        if(IsValidDynamic3DTextLabel(Property[index][E_PROPERTY_BUY_LABEL])) DestroyDynamic3DTextLabel(Property[index][E_PROPERTY_BUY_LABEL]);
        for(new c;c<RT_PROPERTY_FIELDS;c++) Property[index][RuntimePropertyFields[c]]=RuntimePropertyStage[row][c];
        Property[index][E_PROPERTY_AREA]=RuntimePropertyVisuals[row][0];
        for(new c;c<3;c++) Property[index][E_PROPERTY_PICKUP][c]=RuntimePropertyVisuals[row][c+1];
        Property[index][E_PROPERTY_MAPICON]=RuntimePropertyVisuals[row][4];Property[index][E_PROPERTY_BUY_LABEL]=DynamicText3D:RuntimePropertyVisuals[row][5];
        RuntimePropertyVisuals[row][6]=0;
        foreach(new player:Player) {
            if(PlayerVar[player][E_PLAYER_AT_PROPERTY_ENTER] && PlayerVar[player][E_PLAYER_PROPERTY_ENTER_IDX]==index) {
                PlayerTextDrawHide(player,house_info_box[player]);PlayerVar[player][E_PLAYER_AT_PROPERTY_ENTER]=false;
            }
            if(PlayerVar[player][E_PLAYER_BIZ_MENU]==index || PlayerVar[player][E_PLAYER_BIZ_MENU]==Property[index][E_PROPERTY_ID]) {
                PlayerVar[player][E_PLAYER_BIZ_MENU]=INVALID_PROPERTY_ID;
                Dialog_Hide(player);ModelBrowser_HideTiles(player);
                SendClientMessage(player,COLOR_INFO,"This property's placement changed. Reopen its interaction menu at the current location.");
            }
        }
    }
    return 1;
}
