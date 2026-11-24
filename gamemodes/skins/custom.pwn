// Optional model loading for ACP uploads. No custom skins are shipped or loaded by default.
// Enable FEATURE_CUSTOM_SKINS and CUSTOM_SKINS_ENABLED in the web environment together.
// Uploads become available after a full server restart; existing registrations cannot be unloaded.
#if FEATURE_CUSTOM_SKINS
#define ORP_MAX_CUSTOM_SKINS (1000)
enum E_ORP_CUSTOM_SKIN {
    E_ORP_SKIN_MODEL,
    E_ORP_SKIN_BASE,
    E_ORP_SKIN_CHARACTER,
    E_ORP_SKIN_FACTION
}
new CustomSkinModels[ORP_MAX_CUSTOM_SKINS][E_ORP_CUSTOM_SKIN], CustomSkinCount;

// Registers one model and records its owner so arbitrary custom IDs cannot be equipped.
static bool:CustomSkins_Register(base, model, characterid, factionid, const dff[], const txd[]) {
    if (CustomSkinCount >= ORP_MAX_CUSTOM_SKINS || base < 0 || base > 311 || base == 74 || model < 20000 || model > 29999) return false;
    if (!strlen(dff) || !strlen(txd) || strfind(dff, "..") != -1 || strfind(txd, "..") != -1 || dff[0] == '/' || txd[0] == '/' || strfind(dff, ":") != -1 || strfind(txd, ":") != -1) return false;
    for (new i; i < CustomSkinCount; i++) if (CustomSkinModels[i][E_ORP_SKIN_MODEL] == model) return false;
    if (!AddCharModel(base, model, dff, txd)) return false;
    CustomSkinModels[CustomSkinCount][E_ORP_SKIN_MODEL] = model;
    CustomSkinModels[CustomSkinCount][E_ORP_SKIN_BASE] = base;
    CustomSkinModels[CustomSkinCount][E_ORP_SKIN_CHARACTER] = characterid;
    CustomSkinModels[CustomSkinCount++][E_ORP_SKIN_FACTION] = factionid;
    return true;
}

// Uniform reloads may reference only already registered faction-owned models.
stock bool:CustomSkins_FactionModelLoaded(model,factionid) {
    for(new i; i<CustomSkinCount; i++) if(CustomSkinModels[i][E_ORP_SKIN_MODEL]==model && CustomSkinModels[i][E_ORP_SKIN_FACTION]==factionid && !CustomSkinModels[i][E_ORP_SKIN_CHARACTER]) return true;
    return false;
}

// Returns the stock base for a loaded model the character is allowed to wear, or -1.
CustomSkins_AllowedBase(playerid, model) {
    for (new i; i < CustomSkinCount; i++) {
        if (CustomSkinModels[i][E_ORP_SKIN_MODEL] != model) continue;
        if ((CustomSkinModels[i][E_ORP_SKIN_CHARACTER] > 0 && CustomSkinModels[i][E_ORP_SKIN_CHARACTER] == Character[playerid][E_CHARACTER_ID])
            || (CustomSkinModels[i][E_ORP_SKIN_FACTION] > 0 && CustomSkinModels[i][E_ORP_SKIN_FACTION] == Character[playerid][E_CHARACTER_FACTIONID])) return CustomSkinModels[i][E_ORP_SKIN_BASE];
    }
    return -1;
}

// Loads empty-by-default metadata after MySQL connects and before any players join.
CustomSkins_LoadModels() {
    new Cache:result = mysql_query(mysql, "SELECT faction_model_baseid, faction_model_skinid, faction_model_factionid, faction_model_dff, faction_model_txd FROM faction_custom_models WHERE faction_model_enabled = 1 ORDER BY faction_model_id LIMIT 500");
    new base, model, owner, dff[64], txd[64];
    for (new i; i < cache_num_rows(); i++) {
        cache_get_value_name_int(i, "faction_model_baseid", base);
        cache_get_value_name_int(i, "faction_model_skinid", model);
        cache_get_value_name_int(i, "faction_model_factionid", owner);
        cache_get_value_name(i, "faction_model_dff", dff);
        cache_get_value_name(i, "faction_model_txd", txd);
        if (model < 25000 && !CustomSkins_Register(base, model, 0, owner, dff, txd)) printf("[Custom skins] Could not register faction model %d", model);
    }
    cache_delete(result);
    result = mysql_query(mysql, "SELECT player_skin_id, player_skin_charid, player_skin_baseid, player_skin_dff, player_skin_txd FROM player_skins WHERE player_skin_disabled = 0 AND player_skin_id BETWEEN 1 AND 4999 ORDER BY player_skin_id LIMIT 500");
    new filename[64], skinid;
    for (new i; i < cache_num_rows(); i++) {
        cache_get_value_name_int(i, "player_skin_id", skinid);
        cache_get_value_name_int(i, "player_skin_charid", owner);
        cache_get_value_name_int(i, "player_skin_baseid", base);
        cache_get_value_name(i, "player_skin_dff", filename);
        format(dff, sizeof dff, "customskins/%d/%s", owner, filename);
        cache_get_value_name(i, "player_skin_txd", filename);
        format(txd, sizeof txd, "customskins/%d/%s", owner, filename);
        if (!CustomSkins_Register(base, 25000 + skinid, owner, 0, dff, txd)) printf("[Custom skins] Could not register personal skin %d", skinid);
    }
    cache_delete(result);
    printf("[Custom skins] Registered %d models. Restart after changing ACP uploads.", CustomSkinCount);
    return 1;
}

// /customskin [record id] equips one of the character's uploaded personal skins; 0 restores skin 0.
CMD:customskin(playerid, params[]) {
    new id;
    if (sscanf(params, "d", id)) return SendClientMessage(playerid, COLOR_ERROR, "Usage: /customskin [record id, or 0 for stock skin]");
    if (id < 0 || id > 4999 || (id && CustomSkins_AllowedBase(playerid, 25000 + id) == -1)) return SendClientMessage(playerid, COLOR_ERROR, "That personal skin is unavailable or does not belong to your character.");
    SetPlayerSkinEx(playerid, id ? 25000 + id : 0);
    return 1;
}
#endif
