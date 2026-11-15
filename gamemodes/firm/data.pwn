// ============================================================================
// File: firm/data.pwn
// Firm data helpers: clearing a firm slot and a player's firm membership when they log out or
// the firm closes.
// ============================================================================

enum E_FIRM_DATA
{
    E_FIRM_ID,
    E_FIRM_NAME[MAX_FIRM_NAME],
    E_FIRM_ABBREV[MAX_FIRM_ABBREV],
    E_FIRM_FIELD,
    E_FIRM_STATUS,
    E_FIRM_OWNER_CHAR_ID,
    E_FIRM_BANK,
    E_FIRM_CREATED_AT,
    E_FIRM_UPDATED_AT,
    E_FIRM_MEMBER_SLOTS,
    E_FIRM_VEHICLE_SLOTS,
    E_FIRM_HEXCOLOR
}

new Firm[MAX_FIRMS][E_FIRM_DATA];

enum E_PLAYER_FIRM_DATA
{
    E_PLAYER_FIRM_ID,
    E_PLAYER_FIRM_RANK,
    E_PLAYER_FIRM_PERMS,
    bool:E_PLAYER_FIRM_DUTY
}

new PlayerFirm[MAX_PLAYERS][E_PLAYER_FIRM_DATA];

Firm_ClearEntity(firm_enum_id)
{
    Firm[firm_enum_id][E_FIRM_ID] = INVALID_FIRM_ID;
    Firm[firm_enum_id][E_FIRM_NAME][0] = EOS;
    Firm[firm_enum_id][E_FIRM_ABBREV][0] = EOS;
    Firm[firm_enum_id][E_FIRM_FIELD] = FIRM_FIELD_NONE;
    Firm[firm_enum_id][E_FIRM_STATUS] = FIRM_STATUS_CLOSED;
    Firm[firm_enum_id][E_FIRM_OWNER_CHAR_ID] = 0;
    Firm[firm_enum_id][E_FIRM_BANK] = 0;
    Firm[firm_enum_id][E_FIRM_CREATED_AT] = 0;
    Firm[firm_enum_id][E_FIRM_UPDATED_AT] = 0;
    Firm[firm_enum_id][E_FIRM_MEMBER_SLOTS] = 10;
    Firm[firm_enum_id][E_FIRM_VEHICLE_SLOTS] = 0;
    Firm[firm_enum_id][E_FIRM_HEXCOLOR] = 0x5FB9D1FF;
    return true;
}

Firm_ClearPlayer(playerid)
{
    PlayerFirm[playerid][E_PLAYER_FIRM_ID] = 0;
    PlayerFirm[playerid][E_PLAYER_FIRM_RANK] = 0;
    PlayerFirm[playerid][E_PLAYER_FIRM_PERMS] = 0;
    PlayerFirm[playerid][E_PLAYER_FIRM_DUTY] = false;
    return true;
}
