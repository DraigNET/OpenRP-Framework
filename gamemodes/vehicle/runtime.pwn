// ============================================================================
// File: vehicle/runtime.pwn
// Apply saved fleet placement without recreating live vehicles or their cargo.
// ============================================================================
static const RuntimeVehicleColumns[][]={"vehicle_pos_x","vehicle_pos_y","vehicle_pos_z","vehicle_pos_a","vehicle_int","vehicle_vw"};
static const VehicleData:RuntimeVehicleFields[]={E_VEHICLE_POS_X,E_VEHICLE_POS_Y,E_VEHICLE_POS_Z,E_VEHICLE_POS_A,E_VEHICLE_INT,E_VEHICLE_VW};
static RuntimeVehicleStage[MAX_VEHICLES][6],RuntimeVehicleIndex[MAX_VEHICLES],RuntimeVehicleSqlId[MAX_VEHICLES],RuntimeVehicleCount;
static RuntimeVehicleBaseline[MAX_VEHICLES][7];

// Capture before the asynchronous query. Parking, sales or deletion may change
// the live slot while other families are still reading; such snapshots retry.
Runtime_PrepareVehicleSpawns() {
    for(new index;index<sizeof Vehicle;index++) {
        RuntimeVehicleBaseline[index][0]=Vehicle[index][E_VEHICLE_SQLID];
        for(new c;c<6;c++)RuntimeVehicleBaseline[index][c+1]=Vehicle[index][RuntimeVehicleFields[c]];
    }
    return 1;
}

// Read only the parking/spawn columns; ownership and inventory never enter staging.
Runtime_QueryVehicleSpawns(query[],size) {
    format(query,size,"SELECT -1 vehicle_sqlid,0 vehicle_pos_x,0 vehicle_pos_y,0 vehicle_pos_z,0 vehicle_pos_a,0 vehicle_int,0 vehicle_vw,s.revision FROM runtime_config_state s WHERE s.id=1 UNION ALL SELECT v.vehicle_sqlid,v.vehicle_pos_x,v.vehicle_pos_y,v.vehicle_pos_z,v.vehicle_pos_a,v.vehicle_int,v.vehicle_vw,s.revision FROM vehicles v JOIN runtime_config_state s ON s.id=1 ORDER BY vehicle_sqlid");return 1;
}

// Match persistent IDs to their current slots, including dormant personal cars.
Runtime_StageVehicleSpawns(expectedRevision) {
    RuntimeVehicleCount=0;new rows=cache_num_rows(),revision;if(!rows)return 0;
    cache_get_value_name_int(0,"revision",revision);if(revision!=expectedRevision || rows-1>MAX_VEHICLES)return 0;
    for(new row=1;row<rows;row++) {
        new id,index=-1;cache_get_value_name_int(row,"vehicle_sqlid",id);
        for(new i;i<sizeof Vehicle;i++) if(Vehicle[i][E_VEHICLE_SQLID]==id && id>0){index=i;break;}
        if(index==-1)return 0;
        new slot=RuntimeVehicleCount++;RuntimeVehicleIndex[slot]=index;RuntimeVehicleSqlId[slot]=id;
        for(new c;c<6;c++) {
            if(c<4) {new Float:value;cache_get_value_name_float(row,RuntimeVehicleColumns[c],value);if((c<3 && !(floatabs(value)<=20000.0)) || (c==3 && !(value>=0.0 && value<=360.0)))return 0;RuntimeVehicleStage[slot][c]=_:value;}
            else {new value;cache_get_value_name_int(row,RuntimeVehicleColumns[c],value);if(value<0 || value>2147483000 || (c==4 && value>255))return 0;RuntimeVehicleStage[slot][c]=value;}
        }
    }
    new loaded;for(new i;i<sizeof Vehicle;i++)if(Vehicle[i][E_VEHICLE_SQLID]>0)loaded++;
    return loaded==RuntimeVehicleCount;
}

// Validate again immediately before any family commits. Engine IDs may change
// through normal spawning, but persistent IDs and saved-home values must agree.
Runtime_ValidateVehicleSpawns() {
    for(new row;row<RuntimeVehicleCount;row++) {
        new index=RuntimeVehicleIndex[row];
        if(Vehicle[index][E_VEHICLE_SQLID]!=RuntimeVehicleSqlId[row] || RuntimeVehicleBaseline[index][0]!=RuntimeVehicleSqlId[row])return 0;
        for(new c;c<6;c++)if(Vehicle[index][RuntimeVehicleFields[c]]!=RuntimeVehicleBaseline[index][c+1])return 0;
    }
    return 1;
}

// Updating the home cache does not teleport, respawn, repair, empty or despawn
// any live vehicle. Normal parking and respawn actions retain their own lifecycle.
Runtime_CommitVehicleSpawns() {
    for(new row;row<RuntimeVehicleCount;row++)for(new c;c<6;c++)Vehicle[RuntimeVehicleIndex[row]][RuntimeVehicleFields[c]]=RuntimeVehicleStage[row][c];return 1;
}

static const RuntimeDealerColumns[][]={"dealer_pos_x","dealer_pos_y","dealer_pos_z","dealer_interior","dealer_world","dealer_spawn_x","dealer_spawn_y","dealer_spawn_z","dealer_spawn_a","dealer_spawn_interior","dealer_spawn_world"};
static const DealershipData:RuntimeDealerFields[]={dealership_pos_x,dealership_pos_y,dealership_pos_z,dealership_interior,dealership_world,dealership_spawn_x,dealership_spawn_y,dealership_spawn_z,dealership_spawn_a,dealership_spawn_interior,dealership_spawn_world};
static RuntimeDealerStage[MAX_DEALERSHIPS][DealershipData],RuntimeDealerIndex[MAX_DEALERSHIPS],RuntimeDealerCount;
static bool:RuntimeDealerChanged[MAX_DEALERSHIPS];

// Metadata and placement use one snapshot; bank and stock are deliberately omitted.
Runtime_QueryDealers(query[],size) {
    format(query,size,"SELECT -1 dealer_id,'' dealer_name,0 dealer_pos_x,0 dealer_pos_y,0 dealer_pos_z,0 dealer_interior,0 dealer_world,0 dealer_spawn_x,0 dealer_spawn_y,0 dealer_spawn_z,0 dealer_spawn_a,0 dealer_spawn_interior,0 dealer_spawn_world,s.revision FROM runtime_config_state s WHERE s.id=1 UNION ALL SELECT d.dealer_id,d.dealer_name,d.dealer_pos_x,d.dealer_pos_y,d.dealer_pos_z,d.dealer_interior,d.dealer_world,d.dealer_spawn_x,d.dealer_spawn_y,d.dealer_spawn_z,d.dealer_spawn_a,d.dealer_spawn_interior,d.dealer_spawn_world,s.revision FROM dealerships d JOIN runtime_config_state s ON s.id=1 ORDER BY dealer_id");return 1;
}

// Rollback destroys only hidden replacement visuals.
Runtime_CancelDealerStage() {
    for(new row;row<RuntimeDealerCount;row++)if(RuntimeDealerChanged[row]) {
        if(IsValidDynamicPickup(RuntimeDealerStage[row][dealership_pickup]))DestroyDynamicPickup(RuntimeDealerStage[row][dealership_pickup]);
        if(IsValidDynamicMapIcon(RuntimeDealerStage[row][dealership_icon]))DestroyDynamicMapIcon(RuntimeDealerStage[row][dealership_icon]);
        if(IsValidDynamic3DTextLabel(RuntimeDealerStage[row][dealership_label]))DestroyDynamic3DTextLabel(RuntimeDealerStage[row][dealership_label]);
        RuntimeDealerChanged[row]=false;
    }return 1;
}

// Ownership may change while other families read. Labels always use the latest
// owner cache, while the proposed public name comes from this placement snapshot.
static Runtime_DealerLabel(row,text[],size) {
    new index=RuntimeDealerIndex[row];
    if(Dealership_IsOwned(index))format(text,size,"%s\n{A3A3A3}Owner: {DEDEDE}%s\n{DEDEDE}Commands: /dealership",RuntimeDealerStage[row][dealership_name],Dealerships[index][dealership_owner_name]);
    else format(text,size,"%s\n{DEDEDE}Commands: /dealership",RuntimeDealerStage[row][dealership_name]);return 1;
}

// Existing dealership IDs keep their slots; only changed placement allocates.
Runtime_StageDealers(expectedRevision) {
    Runtime_CancelDealerStage();RuntimeDealerCount=0;new rows=cache_num_rows(),revision;
    if(!rows || rows-1>MAX_DEALERSHIPS)return 0;cache_get_value_name_int(0,"revision",revision);if(revision!=expectedRevision)return 0;
    for(new row=1;row<rows;row++) {
        new id;cache_get_value_name_int(row,"dealer_id",id);new index=Dealership_GetBySqlId(id);
        if(index<0 || index>=MAX_DEALERSHIPS)return 0;
        new slot=RuntimeDealerCount++;RuntimeDealerIndex[slot]=index;RuntimeDealerStage[slot]=Dealerships[index];
        new name[128];cache_get_value_name(row,"dealer_name",name,sizeof name);
        if(!name[0] || strlen(name)>63 || strfind(name,"\n")!=-1 || strfind(name,"\r")!=-1 || strfind(name,"<")!=-1 || strfind(name,">")!=-1)return 0;
        new bool:changed=strcmp(name,Dealerships[index][dealership_name])!=0;format(RuntimeDealerStage[slot][dealership_name],64,"%s",name);
        for(new c;c<sizeof RuntimeDealerFields;c++) {
            if(c<=2 || (c>=5 && c<=8)) {
                new Float:value;cache_get_value_name_float(row,RuntimeDealerColumns[c],value);
                if((c==8 && !(value>=0.0 && value<=360.0)) || (c!=8 && !(floatabs(value)<=20000.0)))return 0;
                RuntimeDealerStage[slot][RuntimeDealerFields[c]]=_:value;
            }else {
                new value;cache_get_value_name_int(row,RuntimeDealerColumns[c],value);
                if(value<0 || value>2147483000 || ((c==3 || c==9) && value>255))return 0;
                RuntimeDealerStage[slot][RuntimeDealerFields[c]]=value;
            }
            if(RuntimeDealerStage[slot][RuntimeDealerFields[c]]!=Dealerships[index][RuntimeDealerFields[c]])changed=true;
        }
        if(!changed)continue;
        RuntimeDealerChanged[slot]=true;
        RuntimeDealerStage[slot][dealership_pickup]=0;RuntimeDealerStage[slot][dealership_icon]=0;RuntimeDealerStage[slot][dealership_label]=DynamicText3D:0;
        new label[192];Runtime_DealerLabel(slot,label,sizeof label);
        RuntimeDealerStage[slot][dealership_label]=CreateDynamic3DTextLabel(label,Dealerships[index][dealership_color],RuntimeDealerStage[slot][dealership_pos_x],RuntimeDealerStage[slot][dealership_pos_y],RuntimeDealerStage[slot][dealership_pos_z],15.0,INVALID_PLAYER_ID,INVALID_VEHICLE_ID,true,RT_STAGING_WORLD,RuntimeDealerStage[slot][dealership_interior]);
        RuntimeDealerStage[slot][dealership_pickup]=CreateDynamicPickup(1581,1,RuntimeDealerStage[slot][dealership_pos_x],RuntimeDealerStage[slot][dealership_pos_y],RuntimeDealerStage[slot][dealership_pos_z],RT_STAGING_WORLD,RuntimeDealerStage[slot][dealership_interior]);
        RuntimeDealerStage[slot][dealership_icon]=CreateDynamicMapIcon(RuntimeDealerStage[slot][dealership_pos_x],RuntimeDealerStage[slot][dealership_pos_y],RuntimeDealerStage[slot][dealership_pos_z],55,0,RT_STAGING_WORLD,RuntimeDealerStage[slot][dealership_interior],-1,STREAMER_MAP_ICON_SD,MAPICON_GLOBAL);
        if(!IsValidDynamic3DTextLabel(RuntimeDealerStage[slot][dealership_label]) || !IsValidDynamicPickup(RuntimeDealerStage[slot][dealership_pickup]) || !IsValidDynamicMapIcon(RuntimeDealerStage[slot][dealership_icon]))return 0;
    }
    new loaded;for(new i;i<MAX_DEALERSHIPS;i++)if(Dealership_IsValid(i))loaded++;return loaded==RuntimeDealerCount;
}

// Reveal only in the final callback after all other reads have finished.
Runtime_ActivateDealerStage() {
    new worlds[1];for(new row;row<RuntimeDealerCount;row++)if(RuntimeDealerChanged[row]) {
        new label[192];Runtime_DealerLabel(row,label,sizeof label);
        if(!UpdateDynamic3DTextLabelText(RuntimeDealerStage[row][dealership_label],Dealerships[RuntimeDealerIndex[row]][dealership_color],label))return 0;
        worlds[0]=RuntimeDealerStage[row][dealership_world];
        if(!Streamer_SetArrayData(STREAMER_TYPE_PICKUP,RuntimeDealerStage[row][dealership_pickup],E_STREAMER_WORLD_ID,worlds) || !Streamer_SetArrayData(STREAMER_TYPE_MAP_ICON,RuntimeDealerStage[row][dealership_icon],E_STREAMER_WORLD_ID,worlds) || !Streamer_SetArrayData(STREAMER_TYPE_3D_TEXT_LABEL,RuntimeDealerStage[row][dealership_label],E_STREAMER_WORLD_ID,worlds))return 0;
    }return 1;
}

// Commit only placement/name/handles. Ownership, bank and stock keep their live
// values, even when they changed after the snapshot query was submitted.
Runtime_CommitDealers() {
    for(new row;row<RuntimeDealerCount;row++)if(RuntimeDealerChanged[row]) {
        new index=RuntimeDealerIndex[row];Dealership_DestroyVisuals(index);
        for(new c;c<sizeof RuntimeDealerFields;c++)Dealerships[index][RuntimeDealerFields[c]]=RuntimeDealerStage[row][RuntimeDealerFields[c]];
        format(Dealerships[index][dealership_name],64,"%s",RuntimeDealerStage[row][dealership_name]);
        Dealerships[index][dealership_label]=RuntimeDealerStage[row][dealership_label];Dealerships[index][dealership_pickup]=RuntimeDealerStage[row][dealership_pickup];Dealerships[index][dealership_icon]=RuntimeDealerStage[row][dealership_icon];RuntimeDealerChanged[row]=false;
        Dealer_PlacementChanged(index);
    }
    return GPS_SyncDealerships();
}
