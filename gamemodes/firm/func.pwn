// ============================================================================
// File: firm/func.pwn
// Firm logic: creating and closing firms, adding members, the firm bank, creation fee per
// field, auto-granting the professional licence for a field, and the CanUse...Tools()
// permission checks.
// ============================================================================

// Returns the first free firm slot.
Firm_GetFreeID()
{
    for (new i; i < MAX_FIRMS; i++)
    {
        if (Firm[i][E_FIRM_ID] == INVALID_FIRM_ID)
        {
            return i;
        }
    }

    return INVALID_FIRM_ID;
}

// Converts a firm's SQL id to its array index.
Firm_GetEnumID(firm_sql_id)
{
    if (firm_sql_id <= 0)
    {
        return INVALID_FIRM_ID;
    }

    for (new i; i < MAX_FIRMS; i++)
    {
        if (Firm[i][E_FIRM_ID] == firm_sql_id)
        {
            return i;
        }
    }

    return INVALID_FIRM_ID;
}

// Returns true if the index refers to a loaded firm.
bool:Firm_IsValid(firm_enum_id)
{
    return firm_enum_id >= 0 && firm_enum_id < MAX_FIRMS && Firm[firm_enum_id][E_FIRM_ID] > 0;
}

// Returns true if the firm is loaded and active.
bool:Firm_IsActive(firm_enum_id)
{
    return Firm_IsValid(firm_enum_id) && !FirmClosing[firm_enum_id] && Firm[firm_enum_id][E_FIRM_STATUS] == FIRM_STATUS_ACTIVE;
}

// Writes a firm's name into name.
Firm_GetName(firm_sql_id, name[], len = sizeof(name))
{
    new firm_enum_id = Firm_GetEnumID(firm_sql_id);

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        format(name, len, "None");
        return false;
    }

    format(name, len, "%s", Firm[firm_enum_id][E_FIRM_NAME]);
    return true;
}

// Returns the field (mechanic, lawyer...) of a firm.
Firm_GetField(firm_sql_id)
{
    new firm_enum_id = Firm_GetEnumID(firm_sql_id);

    if (firm_enum_id == INVALID_FIRM_ID)
    {
        return FIRM_FIELD_NONE;
    }

    return Firm[firm_enum_id][E_FIRM_FIELD];
}

// Writes the name of a firm field into name.
Firm_GetFieldName(field, name[], len = sizeof(name))
{
    switch (field)
    {
        case FIRM_FIELD_MECHANIC:  format(name, len, "Mechanic");
        case FIRM_FIELD_SECURITY:  format(name, len, "Security Guard");
        case FIRM_FIELD_LAWYER:    format(name, len, "Lawyer");
        case FIRM_FIELD_TRANSIT:   format(name, len, "Transit Operator");
        case FIRM_FIELD_LOGISTICS: format(name, len, "Logistics");
        case FIRM_FIELD_MEDIA:     format(name, len, "Media");
        case FIRM_FIELD_USEDCARS:  format(name, len, "Used Car Dealer");
        case FIRM_FIELD_REALESTATE: format(name, len, "Real Estate");
        default:                   format(name, len, "None");
    }

    return true;
}

// Writes the name of a firm rank (Owner, Manager...) into name.
Firm_GetRankName(rank, name[], len = sizeof(name))
{
    switch (rank)
    {
        case 1: format(name, len, "Owner");
        case 2: format(name, len, "Manager");
        case 3: format(name, len, "Employee");
        default: format(name, len, "Trainee");
    }

    return true;
}

// Returns true if the player is logged in with a character and may use firm commands.
bool:Firm_PlayerCanAccess(playerid)
{
    return IsPlayerLogged(playerid) && Character[playerid][E_CHARACTER_ID] > 0 && !FirmMembershipLoading[playerid];
}

// Tells the player they can't use firm commands yet.
Firm_SendAccessDenied(playerid)
{
    return SendServerMessage(playerid, COLOR_ERROR, "Firm", "A3A3A3", "You don't have access to firm systems.");
}

// Returns the default permissions for a firm rank.
Firm_GetDefaultRankPerms(rank)
{
    switch (rank)
    {
        case 1: return FIRM_PERM_ALL;
        case 2: return FIRM_PERM_INVITE | FIRM_PERM_KICK | FIRM_PERM_RANKS | FIRM_PERM_BANK | FIRM_PERM_FIELD_TOOLS | FIRM_PERM_VEHICLES | FIRM_PERM_PROPERTIES;
        case 3: return FIRM_PERM_FIELD_TOOLS;
    }

    return 0;
}

// Returns true if the rank is between 1 and 4.
bool:Firm_IsValidRank(rank)
{
    return rank >= 1 && rank <= 4;
}

// Returns the cost of creating a firm of a given field.
Firm_GetCreateFee(field)
{
    new fee = FIRM_CREATE_BASE_FEE;

    switch (field)
    {
        case FIRM_FIELD_MECHANIC: fee += Runtime_Int(RT_FIRMS_MECHANIC_FEE);
        case FIRM_FIELD_SECURITY: fee += Runtime_Int(RT_FIRMS_SECURITY_FEE);
        case FIRM_FIELD_LAWYER: fee += Runtime_Int(RT_FIRMS_LAWYER_FEE);
        case FIRM_FIELD_TRANSIT: fee += Runtime_Int(RT_FIRMS_TRANSIT_FEE);
        case FIRM_FIELD_LOGISTICS: fee += Runtime_Int(RT_FIRMS_LOGISTICS_FEE);
        case FIRM_FIELD_USEDCARS: fee += Runtime_Int(RT_FIRMS_USEDCARS_FEE);
        case FIRM_FIELD_REALESTATE: fee += Runtime_Int(RT_FIRMS_REALESTATE_FEE);
        case FIRM_FIELD_MEDIA: fee += Runtime_Int(RT_FIRMS_MEDIA_FEE);
    }

    return fee;
}

// Converts a field name typed by a player into a firm field constant.
Firm_ParseField(const field_name[])
{
    if (!strcmp(field_name, "mechanic", true)) return FIRM_FIELD_MECHANIC;
    if (!strcmp(field_name, "security", true)) return FIRM_FIELD_SECURITY;
    if (!strcmp(field_name, "security_guard", true)) return FIRM_FIELD_SECURITY;
    if (!strcmp(field_name, "lawyer", true)) return FIRM_FIELD_LAWYER;
    if (!strcmp(field_name, "transit", true)) return FIRM_FIELD_TRANSIT;
    if (!strcmp(field_name, "logistics", true)) return FIRM_FIELD_LOGISTICS;
    if (!strcmp(field_name, "media", true)) return FIRM_FIELD_MEDIA;
    if (!strcmp(field_name, "realestate", true) || !strcmp(field_name, "realty", true) || !strcmp(field_name, "real_estate", true) || !strcmp(field_name, "estate", true)) return FIRM_FIELD_REALESTATE;
    if (!strcmp(field_name, "usedcars", true) || !strcmp(field_name, "used", true) || !strcmp(field_name, "usedcar", true) || !strcmp(field_name, "dealer", true)) return FIRM_FIELD_USEDCARS;

    return FIRM_FIELD_NONE;
}

// Returns true if the field constant is valid.
bool:Firm_IsValidField(field)
{
    switch (field)
    {
        case FIRM_FIELD_MECHANIC,
             FIRM_FIELD_SECURITY,
             FIRM_FIELD_LAWYER,
             FIRM_FIELD_TRANSIT,
             FIRM_FIELD_LOGISTICS,
             FIRM_FIELD_MEDIA,
             FIRM_FIELD_USEDCARS,
             FIRM_FIELD_REALESTATE:
        {
            return true;
        }
    }

    return false;
}

// Writes the professional licence a field requires into name.
Firm_GetRequiredLicenseName(field, name[], len = sizeof(name))
{
    switch (field)
    {
        case FIRM_FIELD_MECHANIC: format(name, len, "Mechanic");
        case FIRM_FIELD_SECURITY: format(name, len, "Security Guard");
        case FIRM_FIELD_LAWYER:   format(name, len, "Lawyer");
        case FIRM_FIELD_TRANSIT:  format(name, len, "Transit Operator");
        case FIRM_FIELD_LOGISTICS: format(name, len, "Logistics Coordinator");
        case FIRM_FIELD_MEDIA:    format(name, len, "Media Correspondent");
        case FIRM_FIELD_USEDCARS: format(name, len, "Used Car Dealer");
        case FIRM_FIELD_REALESTATE: format(name, len, "Real Estate Agent");
        default:                  format(name, len, "Professional");
    }

    return true;
}

// Returns true if a firm name is valid (length, no colour codes).
bool:Firm_IsValidName(const name[])
{
    new len = strlen(name);

    for(new i;i<len;i++)if(name[i]<32 || name[i]==127 || name[i]=='<' || name[i]=='>')return false;
    if (len < 3 || len >= MAX_FIRM_NAME)
    {
        return false;
    }

    if (strfind(name, "{", true) != -1 || strfind(name, "}", true) != -1)
    {
        return false;
    }

    return true;
}

// Returns true if a firm abbreviation is valid.
bool:Firm_IsValidAbbrev(const abbrev[])
{
    new len = strlen(abbrev);

    for(new i;i<len;i++)if(!((abbrev[i]>='A' && abbrev[i]<='Z') || (abbrev[i]>='a' && abbrev[i]<='z') || (abbrev[i]>='0' && abbrev[i]<='9')))return false;
    if (len < 2 || len >= MAX_FIRM_ABBREV)
    {
        return false;
    }

    if (strfind(abbrev, "{", true) != -1 || strfind(abbrev, "}", true) != -1)
    {
        return false;
    }

    return true;
}

// Sends a message to every online member of a firm.
Firm_SendMessage(firm_sql_id, const message[])
{
    new firm_enum_id = Firm_GetEnumID(firm_sql_id);
    new color = 0x5FB9D1FF;

    if (firm_enum_id != INVALID_FIRM_ID && Firm[firm_enum_id][E_FIRM_HEXCOLOR])
    {
        color = Firm[firm_enum_id][E_FIRM_HEXCOLOR];
    }

    foreach (new playerid: Player)
    {
        if (!IsPlayerLogged(playerid) || Character[playerid][E_CHARACTER_ID] == -1)
        {
            continue;
        }

        if (!Firm_PlayerCanAccess(playerid))
        {
            continue;
        }

        if (PlayerFirm[playerid][E_PLAYER_FIRM_ID] == firm_sql_id)
        {
            SendClientMessage(playerid, color, message);
        }
    }

    return true;
}

// Returns true if the player is in a firm (or in a specific one).
bool:IsPlayerInFirm(playerid, firm_sql_id = 0)
{
    if (!IsPlayerLogged(playerid) || Character[playerid][E_CHARACTER_ID] <= 0)
    {
        return false;
    }

    if (!Firm_PlayerCanAccess(playerid))
    {
        return false;
    }

    if (PlayerFirm[playerid][E_PLAYER_FIRM_ID] <= 0)
    {
        return false;
    }

    return !firm_sql_id || PlayerFirm[playerid][E_PLAYER_FIRM_ID] == firm_sql_id;
}

// Returns true if the player is on duty in their firm.
bool:IsPlayerOnFirmDuty(playerid)
{
    return IsPlayerInFirm(playerid) && PlayerFirm[playerid][E_PLAYER_FIRM_DUTY];
}

// Returns true if the player is in a firm of a given field (and on duty when requested).
bool:IsPlayerInFirmField(playerid, field, bool:onduty = false)
{
    if (!IsPlayerInFirm(playerid))
    {
        return false;
    }

    new firm_enum_id = Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID]);

    if (!Firm_IsActive(firm_enum_id))
    {
        return false;
    }

    return Firm[firm_enum_id][E_FIRM_FIELD] == field && (!onduty || PlayerFirm[playerid][E_PLAYER_FIRM_DUTY]);
}

// Returns true if the player's firm rank has a given permission.
bool:Firm_PlayerHasPerm(playerid, permission)
{
    if (!IsPlayerInFirm(playerid))
    {
        return false;
    }

    if(!Firm_IsActive(Firm_GetEnumID(PlayerFirm[playerid][E_PLAYER_FIRM_ID])))return false;
    if (PlayerFirm[playerid][E_PLAYER_FIRM_RANK] == 1)
    {
        return true;
    }

    return (PlayerFirm[playerid][E_PLAYER_FIRM_PERMS] & permission) == permission;
}

// Returns true if the player may manage a member of a given rank.
bool:Firm_PlayerCanManageRank(playerid, target_rank)
{
    if (!IsPlayerInFirm(playerid))
    {
        return false;
    }

    if (PlayerFirm[playerid][E_PLAYER_FIRM_RANK] == 1)
    {
        return true;
    }

    return PlayerFirm[playerid][E_PLAYER_FIRM_RANK] < target_rank;
}

// Returns true if the player is on duty with permission to use their firm field's tools.
bool:Firm_PlayerCanUseFieldTool(playerid, field)
{
    return IsPlayerInFirmField(playerid, field, true) && Firm_PlayerHasPerm(playerid, FIRM_PERM_FIELD_TOOLS);
}

// Returns true if the player may use mechanic tools.
bool:CanUseMechanicTools(playerid)
{
    return Firm_PlayerCanUseFieldTool(playerid, FIRM_FIELD_MECHANIC);
}

// Returns true if the player may use transit (taxi) tools.
bool:CanUseTransitTools(playerid)
{
    return Firm_PlayerCanUseFieldTool(playerid, FIRM_FIELD_TRANSIT);
}

// Returns true if the player may use security guard tools.
bool:CanUseSecurityTools(playerid)
{
    return Firm_PlayerCanUseFieldTool(playerid, FIRM_FIELD_SECURITY);
}

// Returns true if the player may use logistics tools.
bool:CanUseLogisticsTools(playerid)
{
    return Firm_PlayerCanUseFieldTool(playerid, FIRM_FIELD_LOGISTICS);
}

// Writes a firm log entry to the database.
Firm_Log(firm_sql_id, actor_character_id, log_type, const text[])
{
    new query[384];

    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO firm_logs (firm_id, actor_character_id, log_type, log_text, created_at) VALUES (%d, %d, %d, '%e', %d)",
        firm_sql_id, actor_character_id, log_type, text, gettime());
    mysql_tquery(mysql, query);

    return true;
}

// Adds money to a firm's bank and logs it.
Firm_AddBankMoney(firm_enum_id, amount, const reason[])
{
    if (!Firm_IsActive(firm_enum_id) || amount <= 0)
    {
        return false;
    }

    if(Firm[firm_enum_id][E_FIRM_BANK]>2000000000-amount)return false;
    Firm[firm_enum_id][E_FIRM_BANK] += amount;

    new query[256];
    mysql_format(mysql, query, sizeof(query), "UPDATE firms SET firm_bank = %d, firm_updated_at = %d WHERE firm_id = %d",
        Firm[firm_enum_id][E_FIRM_BANK], gettime(), Firm[firm_enum_id][E_FIRM_ID]);
    mysql_tquery(mysql, query);

    Firm_Log(Firm[firm_enum_id][E_FIRM_ID], 0, 1, reason);
    return true;
}

// Takes money from a firm's bank. Returns false if the firm can't afford it.
Firm_TakeBankMoney(firm_enum_id, amount, const reason[])
{
    if (!Firm_IsValid(firm_enum_id) || amount <= 0)
    {
        return false;
    }

    if (Firm[firm_enum_id][E_FIRM_BANK] < amount)
    {
        return false;
    }

    Firm[firm_enum_id][E_FIRM_BANK] -= amount;

    new query[256];
    mysql_format(mysql, query, sizeof(query), "UPDATE firms SET firm_bank = %d, firm_updated_at = %d WHERE firm_id = %d",
        Firm[firm_enum_id][E_FIRM_BANK], gettime(), Firm[firm_enum_id][E_FIRM_ID]);
    mysql_tquery(mysql, query);

    Firm_Log(Firm[firm_enum_id][E_FIRM_ID], 0, 2, reason);
    return true;
}

// Removes a character from a firm.
Firm_RemoveMember(firm_sql_id, character_id)
{
    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "DELETE FROM firm_members WHERE firm_id = %d AND character_id = %d",
        firm_sql_id, character_id);
    mysql_tquery(mysql, query);

    foreach (new playerid: Player)
    {
        if (Character[playerid][E_CHARACTER_ID] == character_id && PlayerFirm[playerid][E_PLAYER_FIRM_ID] == firm_sql_id)
        {
            Firm_ClearPlayer(playerid);
            break;
        }
    }

    return true;
}

// Changes a member's rank and permissions.
Firm_UpdateMemberRank(firm_sql_id, character_id, rank)
{
    new rank_name[MAX_FIRM_RANK_NAME], permissions = Firm_GetDefaultRankPerms(rank);
    Firm_GetRankName(rank, rank_name, sizeof(rank_name));

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE firm_members SET firm_rank = %d, firm_rank_name = '%e', firm_permissions = %d WHERE firm_id = %d AND character_id = %d",
        rank, rank_name, permissions, firm_sql_id, character_id);
    mysql_tquery(mysql, query);

    foreach (new playerid: Player)
    {
        if (Character[playerid][E_CHARACTER_ID] == character_id && PlayerFirm[playerid][E_PLAYER_FIRM_ID] == firm_sql_id)
        {
            PlayerFirm[playerid][E_PLAYER_FIRM_RANK] = rank;
            PlayerFirm[playerid][E_PLAYER_FIRM_PERMS] = permissions;
            PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] = false;
            break;
        }
    }

    return true;
}

// Defined in firm/jobs/usedcars.pwn and property/utils/realestate.pwn.
forward UsedCars_OnFirmClosed(firm_sql_id);
forward Property_OnFirmClosed(firm_sql_id);

// Closes a firm: removes members and vehicles and marks it closed.
Firm_Close(firm_enum_id)
{
    if (!Firm_IsValid(firm_enum_id))
    {
        return false;
    }

    new firm_sql_id = Firm[firm_enum_id][E_FIRM_ID];

    if (Firm[firm_enum_id][E_FIRM_FIELD] == FIRM_FIELD_USEDCARS)
    {
        UsedCars_OnFirmClosed(firm_sql_id);
    }

    if (Firm[firm_enum_id][E_FIRM_FIELD] == FIRM_FIELD_REALESTATE)
    {
        Property_OnFirmClosed(firm_sql_id);
    }

    Firm[firm_enum_id][E_FIRM_STATUS] = FIRM_STATUS_CLOSED;
    Firm[firm_enum_id][E_FIRM_UPDATED_AT] = gettime();

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE firms SET firm_status = %d, firm_updated_at = %d WHERE firm_id = %d",
        FIRM_STATUS_CLOSED, Firm[firm_enum_id][E_FIRM_UPDATED_AT], firm_sql_id);
    mysql_tquery(mysql, query);

    foreach (new playerid: Player)
    {
        if (PlayerFirm[playerid][E_PLAYER_FIRM_ID] == firm_sql_id)
        {
            Firm_ClearPlayer(playerid);
        }
    }

    mysql_format(mysql,query,sizeof query,"DELETE FROM firm_members WHERE firm_id=%d",firm_sql_id);mysql_tquery(mysql,query);
    Firm_ClearEntity(firm_enum_id);
    return true;
}

// Loads all firms from the database at start-up.
Firm_LoadEntities()
{
    for (new i; i < MAX_FIRMS; i++)
    {
        Firm_ClearEntity(i);
    }

    print(" * [FIRM] Loading all firms...");

    inline Firm_OnDataLoad()
    {
        new loaded;

        for (new i = 0, r = cache_num_rows(); i < r && i < MAX_FIRMS; i++)
        {
            cache_get_value_name_int(i, "firm_id", Firm[i][E_FIRM_ID]);
            cache_get_value_name(i, "firm_name", Firm[i][E_FIRM_NAME]);
            cache_get_value_name(i, "firm_abbrev", Firm[i][E_FIRM_ABBREV]);
            cache_get_value_name_int(i, "firm_field", Firm[i][E_FIRM_FIELD]);
            cache_get_value_name_int(i, "firm_status", Firm[i][E_FIRM_STATUS]);
            cache_get_value_name_int(i, "firm_owner_char_id", Firm[i][E_FIRM_OWNER_CHAR_ID]);
            cache_get_value_name_int(i, "firm_bank", Firm[i][E_FIRM_BANK]);
            cache_get_value_name_int(i, "firm_created_at", Firm[i][E_FIRM_CREATED_AT]);
            cache_get_value_name_int(i, "firm_updated_at", Firm[i][E_FIRM_UPDATED_AT]);
            cache_get_value_name_int(i, "firm_member_slots", Firm[i][E_FIRM_MEMBER_SLOTS]);
            cache_get_value_name_int(i, "firm_vehicle_slots", Firm[i][E_FIRM_VEHICLE_SLOTS]);
            cache_get_value_name_int(i, "firm_hex", Firm[i][E_FIRM_HEXCOLOR]);

            if (!Firm[i][E_FIRM_HEXCOLOR])
            {
                Firm[i][E_FIRM_HEXCOLOR] = 0x5FB9D1FF;
            }

            loaded++;
        }

        printf(" * [FIRM] Loaded %d firms.", loaded);
    }

    MySQL_TQueryInline(mysql, using inline Firm_OnDataLoad, "SELECT * FROM firms WHERE firm_status != 3 ORDER BY firm_id ASC", "");
    return true;
}

// Loads the logged-in character's firm membership.
Firm_LoadPlayer(playerid)
{
    Firm_ClearPlayer(playerid);

    if (!IsPlayerLogged(playerid) || Character[playerid][E_CHARACTER_ID] <= 0)
    {
        return false;
    }

    if (!Firm_PlayerCanAccess(playerid))
    {
        return false;
    }

    new character_id=Character[playerid][E_CHARACTER_ID],session=FirmSession[playerid];
    FirmMembershipLoading[playerid]=true;
    new query[384];
    mysql_format(mysql, query, sizeof(query),
        "SELECT fm.firm_id, fm.firm_rank, fm.firm_permissions FROM firm_members fm INNER JOIN firms f ON f.firm_id = fm.firm_id WHERE fm.character_id = %d AND f.firm_status != %d ORDER BY fm.firm_member_id DESC LIMIT 1",
        Character[playerid][E_CHARACTER_ID], FIRM_STATUS_CLOSED);

    inline Firm_OnPlayerLoad()
    {
        if(!IsPlayerConnected(playerid) || Character[playerid][E_CHARACTER_ID]!=character_id || FirmSession[playerid]!=session)return true;
        FirmMembershipLoading[playerid]=false;
        if (!cache_num_rows())
        {
            return true;
        }

        cache_get_value_name_int(0, "firm_id", PlayerFirm[playerid][E_PLAYER_FIRM_ID]);
        cache_get_value_name_int(0, "firm_rank", PlayerFirm[playerid][E_PLAYER_FIRM_RANK]);
        cache_get_value_name_int(0, "firm_permissions", PlayerFirm[playerid][E_PLAYER_FIRM_PERMS]);
        PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] = false;
        return true;
    }

    MySQL_TQueryInline(mysql, using inline Firm_OnPlayerLoad, query, "");
    return true;
}

// When a player leaves: saves their last active time in the firm.
Firm_OnPlayerClose(playerid)
{
    if (PlayerFirm[playerid][E_PLAYER_FIRM_ID] && Character[playerid][E_CHARACTER_ID] > 0)
    {
        new query[256];
        mysql_format(mysql, query, sizeof(query), "UPDATE firm_members SET firm_last_active = %d WHERE firm_id = %d AND character_id = %d",
            gettime(), PlayerFirm[playerid][E_PLAYER_FIRM_ID], Character[playerid][E_CHARACTER_ID]);
        mysql_tquery(mysql, query);
    }

    Firm_ClearPlayer(playerid);
    return true;
}

// A firm vehicle's owning firm SQL id (0 if none). Mirrors GetVehicleFactionID
// (faction/header.pwn) for E_VEHICLE_TYPE_FIRM instead of E_VEHICLE_TYPE_FACTION.
stock GetVehicleFirmID(vehicleid)
{
    if (vehicleid == INVALID_VEHICLE_ID || !vehicleid)
    {
        return 0;
    }

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);

    if (veh_enum_id == -1 || Vehicle[veh_enum_id][E_VEHICLE_TYPE] != E_VEHICLE_TYPE_FIRM)
    {
        return 0;
    }

    return Vehicle[veh_enum_id][E_VEHICLE_OWNER];
}

// The FIRM_FIELD_* of a firm vehicle's owning firm (FIRM_FIELD_NONE if none).
// Mirrors GetVehicleFactionType for firm-owned vehicles.
stock GetVehicleFirmField(vehicleid)
{
    new firm_sql_id = GetVehicleFirmID(vehicleid);

    if (!firm_sql_id)
    {
        return FIRM_FIELD_NONE;
    }

    new firm_enum_id = Firm_GetEnumID(firm_sql_id);

    if (!Firm_IsValid(firm_enum_id))
    {
        return FIRM_FIELD_NONE;
    }

    return Firm[firm_enum_id][E_FIRM_FIELD];
}

// Returns true if a vehicle is owned by a firm (or a specific firm).
bool:IsFirmVehicle(vehicleid, firm_sql_id = 0)
{
    new owner = GetVehicleFirmID(vehicleid);

    if (!owner)
    {
        return false;
    }

    return !firm_sql_id || owner == firm_sql_id;
}

#include <YSI_Coding\y_hooks>

hook ORP_OnLoadCharacter(playerid, character_id)
{
    #pragma unused character_id
    Firm_LoadPlayer(playerid);
    return 1;
}

hook ORP_OnCloseConnection(playerid, reason)
{
    #pragma unused reason
    Firm_OnPlayerClose(playerid);
    return 1;
}
