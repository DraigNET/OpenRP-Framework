// Database-to-memory runtime configuration. Each load uses one SQL statement so
// settings, locations, models and squads cannot come from different revisions.
// Invalid snapshots leave the last working cache intact; commands never query SQL.
#define RT_SCHEMA_VERSION (4)
new bool:RuntimeLoadBusy, RuntimePollTimer, RuntimeRequestToken, RuntimeRequestStarted;
static RuntimePendingRevision, RuntimeEntityPhase;
static bool:RuntimeStartupReady, bool:RuntimeBootValidated, bool:RuntimeWorldPending, bool:RuntimeFactionsReady, bool:RuntimePropertiesReady, bool:RuntimeVehiclesReady, bool:RuntimeDealersReady;
static bool:RuntimeATMPending, bool:RuntimeArmoryPending, bool:RuntimeUniformPending, bool:RuntimeRPRFPending, bool:RuntimePropertyPending, bool:RuntimeVehiclePending, bool:RuntimeDealerPending;
static StageIntegers[RT_SETTING_COUNT], Float:StageNumbers[RT_SETTING_COUNT], StageText[RT_SETTING_COUNT][257];
static StageLocations[RT_MAX_LOCATIONS][E_RT_LOCATION], StageLocationCount;
static Float:StageVertices[RT_MAX_LOCATIONS][RT_MAX_VERTICES][2];
static StageCargo[212], StagePrices[212], bool:StageModelsEnabled[212];
static StageSquadFaction[RT_MAX_SQUADS], StageSquadName[RT_MAX_SQUADS][24], StageSquadRoles[RT_MAX_SQUADS], bool:StageSquadsEnabled[RT_MAX_SQUADS];

// Registry keys, rather than array indexes, are the persistent identifiers.
static Runtime_FindSetting(const key[]) {
    for (new i; i < RT_SETTING_COUNT; i++) if (!strcmp(key, RuntimeKeys[i])) return i;
    return -1;
}
stock Runtime_FindLocation(const key[]) {
    for (new i; i < RuntimeLocationCount; i++) if (!strcmp(key, RuntimeLocations[i][RLOC_KEY])) return i;
    return -1;
}
static Runtime_StageLocation(const key[]) {
    for (new i; i < RT_CORE_LOCATION_COUNT; i++) if (!strcmp(key, RuntimeCoreKeys[i])) return i;
    for (new i = RT_CORE_LOCATION_COUNT; i < StageLocationCount; i++) if (!strcmp(key, StageLocations[i][RLOC_KEY])) return i;
    return -1;
}
static Runtime_Category(const name[]) {
    static const names[][] = {"service", "spawn", "prison_cell", "garbage", "fishing", "garage", "gym_machine", "gps"};
    for (new i; i < sizeof(names); i++) if (!strcmp(name, names[i])) return i;
    return -1;
}

// Strict numeric syntax prevents direct SQL edits with invalid strings becoming 0.
static bool:Runtime_NumberText(const value[], bool:integer) {
    new digits, dots;
    for (new i; value[i]; i++) {
        if (value[i] >= '0' && value[i] <= '9') { digits++; continue; }
        if (!i && value[i] == '-') continue;
        if (!integer && value[i] == '.' && !dots++) continue;
        return false;
    }
    return digits > 0;
}

// All UNION branches expose the same fields; ORDER BY loads parents before vertices.
static Runtime_QuerySnapshot(query[], size) {
    format(query, size,
        "SELECT 0 kind,c.setting_key entry_key,'' label,c.value_type category,c.number_value n1,0 n2,0 n3,0 n4,0 n5,0 n6,0 n7,0 n8,0 n9,0 n10,0 n11,0 n12,IF(c.value_type='text',c.text_value,CAST(c.number_value AS CHAR)) value_text,s.revision FROM runtime_config_state s JOIN runtime_config_settings c ON s.id=1 ");
    strcat(query, "UNION ALL SELECT 1,l.location_key,l.label,l.category,l.x,l.y,l.z,l.angle,l.interior,l.virtual_world,l.radius,l.enabled,l.gps_enabled,l.model_id,l.location_id,l.sort_order,'',s.revision FROM runtime_config_state s JOIN runtime_locations l ON s.id=1 ", size);
    strcat(query, "UNION ALL SELECT 2,l.location_key,'','',v.vertex_index,v.x,v.y,0,0,0,0,0,0,0,0,0,'',s.revision FROM runtime_config_state s JOIN runtime_locations l ON s.id=1 JOIN runtime_location_vertices v ON v.location_id=l.location_id ", size);
    strcat(query, "UNION ALL SELECT 3,CAST(m.model_id AS CHAR),'','',m.cargo_slots,0,m.enabled,0,0,0,0,0,0,0,0,0,IFNULL(CAST(m.catalogue_price AS CHAR),'-1'),s.revision FROM runtime_config_state s JOIN runtime_vehicle_models m ON s.id=1 ", size);
    strcat(query, "UNION ALL SELECT 4,CAST(q.squad_id AS CHAR),q.squad_name,'',q.faction_id,q.role_flags,q.enabled,0,0,0,0,0,0,0,0,0,'',s.revision FROM runtime_config_state s JOIN runtime_faction_squads q ON s.id=1 ", size);
    new events[1024];
    format(events,sizeof events,"UNION ALL SELECT 5,e.entity_type,'','',e.entity_id,0,0,0,0,0,0,0,0,0,0,0,'',s.revision FROM runtime_config_state s JOIN runtime_entity_changes e ON s.id=1 AND %d>0 AND e.revision>%d AND e.revision<=s.revision GROUP BY e.entity_type,e.entity_id,s.revision UNION ALL SELECT 6,'state','','',s.schema_version,0,0,0,0,0,0,0,0,0,0,0,'',s.revision FROM runtime_config_state s WHERE s.id=1 ORDER BY kind,n12,entry_key,n1",RuntimeRevision,RuntimeRevision);
    strcat(query,events,size);
}

// A failed load is visible to editors and retried on the next polling cycle.
static Runtime_Fail(const reason[]) {
    Runtime_CancelATMStage(); Runtime_CancelArmoryStage(); Runtime_CancelRPRFStage(); Runtime_CancelPropertyStage(); Runtime_CancelDealerStage();
    new query[768];
    mysql_format(mysql, query, sizeof query, "UPDATE runtime_config_state SET last_error='%e',last_heartbeat=UNIX_TIMESTAMP() WHERE id=1", reason);
    mysql_tquery(mysql, query);
    printf("[Runtime configuration] Rejected snapshot: %s", reason);
    RuntimeLoadBusy = false;
    return 0;
}

// Swapping retains the previous snapshot for rollback if an adapter cannot apply.
static Runtime_SwapSnapshot() {
    new value; new Float:number; new bool:flag;
    new text[257], location[E_RT_LOCATION], squadName[24];
    for (new i; i < RT_SETTING_COUNT; i++) {
        value=RuntimeIntegers[i]; RuntimeIntegers[i]=StageIntegers[i]; StageIntegers[i]=value;
        number=RuntimeNumbers[i]; RuntimeNumbers[i]=StageNumbers[i]; StageNumbers[i]=number;
        text=RuntimeText[i]; RuntimeText[i]=StageText[i]; StageText[i]=text;
    }
    new count=RuntimeLocationCount>StageLocationCount?RuntimeLocationCount:StageLocationCount;
    for (new i; i<count; i++) {
        new vertices=RuntimeLocations[i][RLOC_VERTICES]>StageLocations[i][RLOC_VERTICES]?RuntimeLocations[i][RLOC_VERTICES]:StageLocations[i][RLOC_VERTICES];
        location=RuntimeLocations[i]; RuntimeLocations[i]=StageLocations[i]; StageLocations[i]=location;
        for (new v; v<vertices; v++) for (new axis; axis<2; axis++) { number=RuntimeVertices[i][v][axis]; RuntimeVertices[i][v][axis]=StageVertices[i][v][axis]; StageVertices[i][v][axis]=number; }
    }
    value=RuntimeLocationCount; RuntimeLocationCount=StageLocationCount; StageLocationCount=value;
    for (new i; i<212; i++) {
        value=RuntimeCargoSlots[i]; RuntimeCargoSlots[i]=StageCargo[i]; StageCargo[i]=value;
        value=RuntimeModelPrices[i]; RuntimeModelPrices[i]=StagePrices[i]; StagePrices[i]=value;
        flag=RuntimeModelEnabled[i]; RuntimeModelEnabled[i]=StageModelsEnabled[i]; StageModelsEnabled[i]=flag;
    }
    for (new i; i<RT_MAX_SQUADS; i++) {
        value=RuntimeSquadFaction[i]; RuntimeSquadFaction[i]=StageSquadFaction[i]; StageSquadFaction[i]=value;
        value=RuntimeSquadRoles[i]; RuntimeSquadRoles[i]=StageSquadRoles[i]; StageSquadRoles[i]=value;
        flag=RuntimeSquadEnabled[i]; RuntimeSquadEnabled[i]=StageSquadsEnabled[i]; StageSquadsEnabled[i]=flag;
        squadName=RuntimeSquadName[i]; RuntimeSquadName[i]=StageSquadName[i]; StageSquadName[i]=squadName;
    }
}

// Validate every row into scratch arrays before touching any live configuration.
static Runtime_ApplySnapshot(bool:initial) {
    new count = cache_num_rows(), revision, rowRevision, kind, key[81], category[25], value[257], label[65], index;
    new bool:seen[RT_SETTING_COUNT], bool:coreSeen[RT_CORE_LOCATION_COUNT], bool:schemaSeen;
    if (!count) return Runtime_Fail("Configuration is empty; import the complete database/schema.sql into an empty database.");
    StageLocationCount = RT_CORE_LOCATION_COUNT;
    RuntimeATMPending=!initial && !RuntimeBootValidated; RuntimeArmoryPending=RuntimeATMPending; RuntimeUniformPending=RuntimeATMPending; RuntimeRPRFPending=RuntimeATMPending; RuntimePropertyPending=RuntimeATMPending; RuntimeVehiclePending=RuntimeATMPending; RuntimeDealerPending=RuntimeATMPending;
    new emptyLocation[E_RT_LOCATION];
    for (new i; i < RT_MAX_LOCATIONS; i++) StageLocations[i]=emptyLocation;
    for (new i; i < 212; i++) { StageCargo[i] = 0; StagePrices[i] = -1; StageModelsEnabled[i] = false; }
    for (new i; i < RT_MAX_SQUADS; i++) { StageSquadFaction[i] = 0; StageSquadName[i][0] = EOS; StageSquadRoles[i] = 0; StageSquadsEnabled[i] = false; }
    for (new row; row < count; row++) {
        cache_get_value_name_int(row, "revision", rowRevision);
        if (!revision) revision = rowRevision;
        if (revision != rowRevision || revision < 1) return Runtime_Fail("Mixed or invalid configuration revision.");
        cache_get_value_name_int(row, "kind", kind);
        cache_get_value_name(row, "entry_key", key);
        cache_get_value_name(row, "category", category);
        cache_get_value_name(row, "value_text", value);
        if (kind == 0) {
            index = Runtime_FindSetting(key);
            if (index == -1) return Runtime_Fail("Unknown setting key; update the gamemode catalogue.");
            if (seen[index]) return Runtime_Fail("Duplicate setting key.");
            seen[index] = true;
            if (RuntimeTypes[index] == 2) {
                if (strcmp(category, "text") || strlen(value) < 1 || strlen(value) > floatround(RuntimeMaximum[index]) || strfind(value, "\n") != -1 || strfind(value, "\r") != -1) return Runtime_Fail("Invalid text setting.");
                format(StageText[index], 257, "%s", value);
            } else {
                if (strcmp(category, RuntimeTypes[index] ? "number" : "integer") || !Runtime_NumberText(value, RuntimeTypes[index] == 0)) return Runtime_Fail("Invalid setting type or number.");
                StageNumbers[index] = floatstr(value);
                if (!(StageNumbers[index] >= RuntimeMinimum[index] && StageNumbers[index] <= RuntimeMaximum[index])) return Runtime_Fail("Setting outside the supported range.");
                StageIntegers[index] = RuntimeTypes[index] ? floatround(StageNumbers[index]) : strval(value);
            }
        } else if (kind == 1) {
            index = Runtime_StageLocation(key);
            if (index == -1) { if (StageLocationCount >= RT_MAX_LOCATIONS) return Runtime_Fail("Location capacity exceeded."); index = StageLocationCount++; }
            if (StageLocations[index][RLOC_KEY][0]) return Runtime_Fail("Duplicate location key.");
            if (index < RT_CORE_LOCATION_COUNT) coreSeen[index] = true;
            format(StageLocations[index][RLOC_KEY], 65, "%s", key);
            cache_get_value_name(row, "label", StageLocations[index][RLOC_LABEL], 65);
            StageLocations[index][RLOC_CATEGORY] = Runtime_Category(category);
            if (StageLocations[index][RLOC_CATEGORY] == -1 || !StageLocations[index][RLOC_LABEL][0]) return Runtime_Fail("Invalid location category or label.");
            cache_get_value_name_float(row,"n1",StageLocations[index][RLOC_X]); cache_get_value_name_float(row,"n2",StageLocations[index][RLOC_Y]);
            cache_get_value_name_float(row,"n3",StageLocations[index][RLOC_Z]); cache_get_value_name_float(row,"n4",StageLocations[index][RLOC_ANGLE]);
            cache_get_value_name_int(row,"n5",StageLocations[index][RLOC_INTERIOR]); cache_get_value_name_int(row,"n6",StageLocations[index][RLOC_WORLD]);
            cache_get_value_name_float(row,"n7",StageLocations[index][RLOC_RADIUS]); cache_get_value_name_int(row,"n8",StageLocations[index][RLOC_ENABLED]);
            cache_get_value_name_int(row,"n9",StageLocations[index][RLOC_GPS]); cache_get_value_name_int(row,"n10",StageLocations[index][RLOC_MODEL]);
            cache_get_value_name_int(row,"n11",StageLocations[index][RLOC_SQLID]); cache_get_value_name_int(row,"n12",StageLocations[index][RLOC_SORT]);
            if (!(floatabs(StageLocations[index][RLOC_X]) <= 20000.0 && floatabs(StageLocations[index][RLOC_Y]) <= 20000.0 && floatabs(StageLocations[index][RLOC_Z]) <= 20000.0 && StageLocations[index][RLOC_RADIUS] >= 0.2 && StageLocations[index][RLOC_RADIUS] <= 1000.0)) return Runtime_Fail("Invalid location coordinates or radius.");
            if (!(StageLocations[index][RLOC_ANGLE]>=0.0 && StageLocations[index][RLOC_ANGLE]<=360.0) || StageLocations[index][RLOC_WORLD]>2147483000 || StageLocations[index][RLOC_GPS]<0 || StageLocations[index][RLOC_GPS]>1 || StageLocations[index][RLOC_MODEL]<0 || StageLocations[index][RLOC_MODEL]>19999) return Runtime_Fail("Invalid location facing, visibility or model.");
            if (StageLocations[index][RLOC_INTERIOR] < 0 || StageLocations[index][RLOC_INTERIOR] > 255 || StageLocations[index][RLOC_WORLD] < 0 || StageLocations[index][RLOC_ENABLED] < 0 || StageLocations[index][RLOC_ENABLED] > 1) return Runtime_Fail("Invalid location world or enabled state.");
        } else if (kind == 2) {
            index = Runtime_StageLocation(key);
            new Float:vertexFloat, vertex;
            cache_get_value_name_float(row,"n1",vertexFloat); vertex = floatround(vertexFloat);
            if (index == -1 || vertex < 0 || vertex >= RT_MAX_VERTICES || vertex != StageLocations[index][RLOC_VERTICES]) return Runtime_Fail("Invalid polygon vertices.");
            cache_get_value_name_float(row,"n2",StageVertices[index][vertex][0]); cache_get_value_name_float(row,"n3",StageVertices[index][vertex][1]);
            if (!(floatabs(StageVertices[index][vertex][0]) <= 20000.0 && floatabs(StageVertices[index][vertex][1]) <= 20000.0)) return Runtime_Fail("Invalid polygon coordinates.");
            StageLocations[index][RLOC_VERTICES]++;
        } else if (kind == 3) {
            index = strval(key) - 400;
            if (index < 0 || index >= 212) return Runtime_Fail("Invalid vehicle model.");
            new Float:slots, Float:enabled;
            cache_get_value_name_float(row,"n1",slots); cache_get_value_name_float(row,"n3",enabled);
            if (!(slots >= 0.0 && slots <= 64.0) || slots!=float(floatround(slots)) || (enabled!=0.0 && enabled!=1.0) || !Runtime_NumberText(value, true) || strval(value)<-1 || floatstr(value)>100000000.0) return Runtime_Fail("Invalid cargo capacity or price.");
            StageCargo[index] = floatround(slots); StagePrices[index] = strval(value); StageModelsEnabled[index] = enabled == 1.0;
        } else if (kind == 4) {
            index = strval(key);
            if (index < 1 || index >= RT_MAX_SQUADS) return Runtime_Fail("Invalid squad identifier.");
            new Float:faction, Float:roles, Float:enabled;
            cache_get_value_name_float(row,"n1",faction); cache_get_value_name_float(row,"n2",roles); cache_get_value_name_float(row,"n3",enabled);
            if (!(faction >= 1.0 && faction<=2147483000.0 && roles >= 0.0 && roles <= 3.0) || faction!=float(floatround(faction)) || roles!=float(floatround(roles)) || (enabled!=0.0 && enabled!=1.0)) return Runtime_Fail("Invalid squad faction or roles.");
            StageSquadFaction[index] = floatround(faction); StageSquadRoles[index] = floatround(roles); StageSquadsEnabled[index] = enabled == 1.0;
            cache_get_value_name(row,"label",label);
            if(!label[0] || strlen(label)>23) return Runtime_Fail("Squad name must contain 1-23 characters.");
            format(StageSquadName[index],24,"%s",label);
        } else if(kind==5) {
            if(!strcmp(key,"atm")) RuntimeATMPending=true;
            else if(!strcmp(key,"vehicle_spawn")) RuntimeVehiclePending=true;
            else if(!strcmp(key,"dealership_placement")) RuntimeDealerPending=true;
            else if(!strcmp(key,"property_placement")) RuntimePropertyPending=true;
            else if(!strcmp(key,"repair_refuel")) RuntimeRPRFPending=true;
            else if(!strcmp(key,"faction_skin")) RuntimeUniformPending=true;
            else if(!strcmp(key,"locker") || !strcmp(key,"armory_type") || !strcmp(key,"armory_weapon")) RuntimeArmoryPending=true;
            else return Runtime_Fail("An entity change requires an updated game adapter.");
        } else if(kind==6) {
            new version; cache_get_value_name_int(row,"n1",version);
            if(version!=RT_SCHEMA_VERSION) return Runtime_Fail("Runtime schema mismatch; use the database/schema.sql shipped with this build.");
            schemaSeen=true;
        } else return Runtime_Fail("Unknown configuration record kind.");
    }
    if(!schemaSeen) return Runtime_Fail("Runtime schema version record is missing.");
    for (new i; i < RT_SETTING_COUNT; i++) if (!seen[i]) return Runtime_Fail("Required setting is missing.");
    for (new i; i < RT_CORE_LOCATION_COUNT; i++) if (!coreSeen[i]) return Runtime_Fail("Required service location is missing.");
    for (new i; i < StageLocationCount; i++) if (StageLocations[i][RLOC_CATEGORY] == RT_CATEGORY_FISHING && StageLocations[i][RLOC_VERTICES] < 3) return Runtime_Fail("Fishing polygon has too few vertices.");
    if (StageIntegers[RT_PIZZA_PAY_MIN] > StageIntegers[RT_PIZZA_PAY_MAX] || StageIntegers[RT_PAYCHECK_MINIMUM_MINUTES] > StageIntegers[RT_PAYCHECK_INTERVAL_MINUTES] || StageIntegers[RT_MEDICAL_BILL_MIN] > StageIntegers[RT_MEDICAL_BILL_MAX] || StageNumbers[RT_PIZZA_MIN_X] > StageNumbers[RT_PIZZA_MAX_X] || StageNumbers[RT_PIZZA_MIN_Y] > StageNumbers[RT_PIZZA_MAX_Y]) return Runtime_Fail("Inconsistent setting bounds.");

    for(new i; i<StageLocationCount; i++) if(StageLocations[i][RLOC_CATEGORY]==RT_CATEGORY_PRISON_CELL) {
        new length=strlen(StageLocations[i][RLOC_LABEL]);
        if(length<1 || length>3) return Runtime_Fail("Prison cells need unique 1-3 character codes.");
        for(new c; c<length; c++) {
            new ch=StageLocations[i][RLOC_LABEL][c];
            if(!((ch>='A' && ch<='Z') || (ch>='a' && ch<='z') || (ch>='0' && ch<='9'))) return Runtime_Fail("Invalid prison cell code.");
        }
        for(new j; j<i; j++) if(StageLocations[j][RLOC_CATEGORY]==RT_CATEGORY_PRISON_CELL && !strcmp(StageLocations[i][RLOC_LABEL],StageLocations[j][RLOC_LABEL],true)) return Runtime_Fail("Duplicate prison cell codes.");
    }
    // Bound every family before any adapter allocates handles into fixed arrays.
    new categoryCounts[8], gpsCount;
    for(new i; i<StageLocationCount; i++) {
        categoryCounts[StageLocations[i][RLOC_CATEGORY]]++;
        if(StageLocations[i][RLOC_ENABLED] && StageLocations[i][RLOC_GPS] && !StageLocations[i][RLOC_INTERIOR] && !StageLocations[i][RLOC_WORLD]) gpsCount++;
        if(i<RT_CORE_LOCATION_COUNT && StageLocations[i][RLOC_CATEGORY]!=RuntimeCoreCategories[i]) return Runtime_Fail("A core location cannot change category.");
    }
    if(categoryCounts[RT_CATEGORY_SPAWN]>64 || categoryCounts[RT_CATEGORY_PRISON_CELL]>64 || categoryCounts[RT_CATEGORY_GARBAGE]>256 || categoryCounts[RT_CATEGORY_FISHING]>32 || categoryCounts[RT_CATEGORY_GARAGE]>64 || categoryCounts[RT_CATEGORY_GYM_MACHINE]>128 || categoryCounts[RT_CATEGORY_GPS]>128 || gpsCount>232) return Runtime_Fail("Location family or GPS capacity exceeded.");
    if(StageNumbers[RT_VEH_USED_SALE_MIN_PCT]>StageNumbers[RT_VEH_USED_SALE_MAX_PCT]) return Runtime_Fail("Invalid used vehicle resale bounds.");
    if(!initial) for(new i; i<RT_MAX_SQUADS; i++) {
        if(StageSquadFaction[i]!=RuntimeSquadFaction[i] || StageSquadsEnabled[i]!=RuntimeSquadEnabled[i]) {
            RuntimeArmoryPending=true; RuntimeUniformPending=true; break;
        }
    }
    RuntimeWorldPending=initial || !RuntimeBootValidated || StageLocationCount!=RuntimeLocationCount;
    for(new i; i<StageLocationCount && !RuntimeWorldPending; i++) {
        if(strcmp(StageLocations[i][RLOC_KEY],RuntimeLocations[i][RLOC_KEY]) || strcmp(StageLocations[i][RLOC_LABEL],RuntimeLocations[i][RLOC_LABEL])) RuntimeWorldPending=true;
        for(new c=_:RLOC_CATEGORY; c<E_RT_LOCATION && !RuntimeWorldPending; c++) if(StageLocations[i][E_RT_LOCATION:c]!=RuntimeLocations[i][E_RT_LOCATION:c]) RuntimeWorldPending=true;
        for(new v; v<StageLocations[i][RLOC_VERTICES] && !RuntimeWorldPending; v++) for(new a; a<2; a++) if(StageVertices[i][v][a]!=RuntimeVertices[i][v][a]) RuntimeWorldPending=true;
    }
    if(initial) return Runtime_FinalizeSnapshot(revision,true);
    RuntimePendingRevision=revision; RuntimeEntityPhase=0;
    return Runtime_LoadEntityStages();
}

// All reads finish asynchronously before the game swaps its live caches.
static Runtime_FinalizeSnapshot(revision,bool:initial) {
    if(!initial && RuntimeVehiclePending && !Runtime_ValidateVehicleSpawns()) return Runtime_Fail("Vehicle parking changed during reload; retrying the current saved state.");
    if(!initial && RuntimeATMPending && !Runtime_ActivateATMStage()) return Runtime_Fail("ATM visuals could not be activated; previous ATMs retained.");
    if(!initial && RuntimeArmoryPending && !Runtime_ActivateArmoryStage()) return Runtime_Fail("Locker visuals could not be activated; previous lockers retained.");
    if(!initial && RuntimeRPRFPending && !Runtime_ActivateRPRFStage()) return Runtime_Fail("Repair/refuel visuals could not be activated; previous points retained.");
    if(!initial && RuntimePropertyPending && !Runtime_ActivatePropertyStage()) return Runtime_Fail("Property visuals could not be activated; previous placement retained.");
    if(!initial && RuntimeDealerPending && !Runtime_ActivateDealerStage()) return Runtime_Fail("Dealership visuals could not be activated; previous placement retained.");
    Runtime_SwapSnapshot();
    if (!CallLocalFunction("ORP_OnRuntimeConfigApplied", "ii", revision, initial)) {
        if(!initial && RuntimeATMPending) Runtime_CancelATMStage();
        if(!initial && RuntimeArmoryPending) Runtime_CancelArmoryStage();
        Runtime_SwapSnapshot();
        CallLocalFunction("ORP_OnRuntimeConfigApplied", "ii", RuntimeRevision, false);
        return Runtime_Fail("World adapter could not apply changes; the previous configuration was restored.");
    }
    if(!initial && RuntimeATMPending) Runtime_CommitATMs();
    if(!initial && RuntimeArmoryPending) Runtime_CommitArmories();
    if(!initial && RuntimeUniformPending) Runtime_CommitUniforms();
    if(!initial && RuntimeRPRFPending) Runtime_CommitRPRF();
    if(!initial && RuntimePropertyPending) Runtime_CommitProperties();
    if(!initial && RuntimeVehiclePending) Runtime_CommitVehicleSpawns();
    if(!initial && RuntimeDealerPending) Runtime_CommitDealers();
    RuntimeRevision = revision;
    new query[192];
    if(initial) {
        // Core definitions are needed by startup loaders, but Applied must wait
        // until every connected entity family has passed the same validation.
        mysql_tquery(mysql,"UPDATE runtime_config_state SET applied_revision=0,last_heartbeat=0,last_error='' WHERE id=1");
        RuntimeLoadBusy=false;
        return 1;
    }
    RuntimeBootValidated=true;
    format(query,sizeof query,"UPDATE runtime_config_state SET applied_revision=%d,last_heartbeat=UNIX_TIMESTAMP(),last_error='' WHERE id=1",revision);
    mysql_tquery(mysql,query);
    RuntimeLoadBusy = false;
    printf("[Runtime configuration] Applied revision %d (%d settings, %d locations).",revision,RT_SETTING_COUNT,RuntimeLocationCount);
    return 1;
}

// Faction loading finishes asynchronously; uniforms cannot be validated before it.
static Runtime_UpdateStartupReady() {RuntimeStartupReady=RuntimeFactionsReady && RuntimePropertiesReady && RuntimeVehiclesReady && RuntimeDealersReady;return 1;}
RuntimeConfig_EntitiesReady() {RuntimeFactionsReady=true;return Runtime_UpdateStartupReady();}
RuntimeConfig_PropertiesReady() {RuntimePropertiesReady=true;return Runtime_UpdateStartupReady();}
RuntimeConfig_VehiclesReady() {RuntimeVehiclesReady=true;return Runtime_UpdateStartupReady();}
RuntimeConfig_DealersReady() {RuntimeDealersReady=true;return Runtime_UpdateStartupReady();}
// Adapters query change flags without exposing loader scratch arrays.
stock Runtime_WorldChanged() { return _:RuntimeWorldPending; }
stock Runtime_IntegerChanged(setting) { return RuntimeIntegers[setting]!=StageIntegers[setting]; }
stock Runtime_TextChanged(setting) { return strcmp(RuntimeText[setting],StageText[setting])!=0; }
stock Runtime_EntitiesReady() { return _:RuntimeStartupReady; }
stock Runtime_ConfigurationBusy() { return _:RuntimeLoadBusy; }
static Runtime_LoadEntityStages() {
    new query[3072];
    while(RuntimeEntityPhase<7) {
        new family=RuntimeEntityPhase++;
        switch(family) {
            case 0: { if(!RuntimeATMPending) continue; Runtime_QueryATMs(query,sizeof query); }
            case 1: { if(!RuntimeArmoryPending) continue; Runtime_QueryArmories(query,sizeof query); }
            case 2: { if(!RuntimeUniformPending) continue; Runtime_QueryUniforms(query,sizeof query); }
            case 3: { if(!RuntimeRPRFPending) continue; Runtime_QueryRPRF(query,sizeof query); }
            case 4: { if(!RuntimeVehiclePending) continue; Runtime_PrepareVehicleSpawns(); Runtime_QueryVehicleSpawns(query,sizeof query); }
            case 5: { if(!RuntimeDealerPending) continue; Runtime_QueryDealers(query,sizeof query); }
            case 6: { if(!RuntimePropertyPending) continue; Runtime_QueryProperties(query,sizeof query); }
        }
        RuntimeRequestStarted=gettime();
        mysql_tquery(mysql,query,"RuntimeConfig_OnEntityStage","ii",RuntimeRequestToken,family);
        return 1;
    }
    return Runtime_FinalizeSnapshot(RuntimePendingRevision,false);
}
forward RuntimeConfig_OnEntityStage(token,family);
public RuntimeConfig_OnEntityStage(token,family) {
    if(!RuntimeLoadBusy || token!=RuntimeRequestToken) return 0;
    new valid;
    switch(family) {
        case 0: valid=Runtime_StageATMs(RuntimePendingRevision,true);
        case 1: valid=Runtime_StageArmories(RuntimePendingRevision,true);
        case 2: valid=Runtime_StageUniforms(RuntimePendingRevision,true);
        case 3: valid=Runtime_StageRPRF(RuntimePendingRevision,true);
        case 4: valid=Runtime_StageVehicleSpawns(RuntimePendingRevision);
        case 5: valid=Runtime_StageDealers(RuntimePendingRevision);
        case 6: valid=Runtime_StageProperties(RuntimePendingRevision);
    }
    if(!valid) return Runtime_Fail(family==0?"ATM changes could not be staged; previous ATMs retained.":family==1?"Armory changes could not be staged; existing equipment and lockers retained.":family==2?"Uniform changes could not be staged; previous uniforms retained.":family==3?"Repair/refuel changes could not be staged; previous points retained.":family==4?"Vehicle spawn changes rejected; previous saved spawns retained.":family==5?"Dealership placement rejected; previous dealership retained.":"Property placement rejected. Wait for deliveries/burglary and empty old interiors before moving property destinations.");
    return Runtime_LoadEntityStages();
}

forward RuntimeConfig_OnSnapshot(token);
public RuntimeConfig_OnSnapshot(token) {
    if (!RuntimeLoadBusy || token != RuntimeRequestToken) return 0;
    return Runtime_ApplySnapshot(false);
}
forward RuntimeConfig_CheckRevision(token);
public RuntimeConfig_CheckRevision(token) {
    if (!RuntimeLoadBusy || token != RuntimeRequestToken) return 0;
    new revision;
    if (!cache_num_rows()) return Runtime_Fail("Runtime configuration state is unavailable.");
    cache_get_value_name_int(0,"revision",revision);
    if (revision != RuntimeRevision || !RuntimeBootValidated) {
        new query[4096]; Runtime_QuerySnapshot(query,sizeof query);
        mysql_tquery(mysql,query,"RuntimeConfig_OnSnapshot","i",token);
    } else {
        mysql_tquery(mysql,"UPDATE runtime_config_state SET last_heartbeat=UNIX_TIMESTAMP() WHERE id=1");
        RuntimeLoadBusy = false;
    }
    return 1;
}
forward RuntimeConfig_Poll();
public RuntimeConfig_Poll() {
    if(!RuntimeStartupReady) return 1;
    if (RuntimeLoadBusy) {
        if (gettime() - RuntimeRequestStarted < 15) return 1;
        RuntimeRequestToken++; // Ignore late callbacks from the timed-out request.
        Runtime_Fail("Database request timed out; retaining the previous configuration.");
    }
    RuntimeLoadBusy = true;
    RuntimeRequestStarted = gettime();
    RuntimeRequestToken++;
    mysql_tquery(mysql,"SELECT revision FROM runtime_config_state WHERE id=1","RuntimeConfig_CheckRevision","i",RuntimeRequestToken);
    return 1;
}

// Initial load is synchronous and bounded; normal operation uses async polling.
RuntimeConfig_Init() {
    new query[4096]; Runtime_QuerySnapshot(query,sizeof query);
    new Cache:result = mysql_query(mysql,query);
    new success = Runtime_ApplySnapshot(true);
    cache_delete(result);
    if (success) RuntimePollTimer = SetTimer("RuntimeConfig_Poll",2000,true);
    return success;
}

// Stop polling before closing MySQL; invalidate any outstanding asynchronous load.
RuntimeConfig_Shutdown() {
    if (RuntimePollTimer) KillTimer(RuntimePollTimer);
    RuntimePollTimer=0; RuntimeRequestToken++; RuntimeLoadBusy=false;
    return 1;
}
