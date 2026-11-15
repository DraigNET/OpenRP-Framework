// ============================================================================
// File: police/systems/data.pwn
// Records searches (/searchplate, /searchaddress) plus small items officers hand out: stamps,
// cigarettes, and the prison megaphone (/megaphoneprison).
// Commands: /searchplate /searchaddress /addressearch /passstamp /givestamp /passcigarette
// /megaphoneprison /mp
// ============================================================================

// /searchplate [plate] - looks up a vehicle plate.
CMD:searchplate(playerid, params[])
{

    new licenseplate [ 32 ] ;
    // New: automatically check for nearby car (that the player isn't in) and use it if no plate is specified
    new Float:x, Float:y, Float:z, playerveh = GetPlayerVehicleID(playerid), world = GetPlayerVirtualWorld(playerid);
    new closest = INVALID_VEHICLE_ID, Float:current, Float:last = 10.0; // 10.0 radius for /searchplate

    GetPlayerPos(playerid, x, y, z);
    GetXYInFrontOfPlayer(playerid, x, y, 2.0);

    for (new i = 1, j = GetVehiclePoolSize(); i <= j; i++)
    {
        if (!IsValidVehicle(i)) continue;
        if (playerveh == i) continue;
        if (GetVehicleVirtualWorld(i) != world) continue;

        current = GetVehicleDistanceFromPoint(i, x, y, z);

        if (current < last)
        {
            closest = i;
            last = current;
        }
    }

    if (closest == INVALID_VEHICLE_ID) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You need to be near a vehicle to search the plate.") ;

    new veh_enum_id = Vehicle_GetEnumID(closest);
    format(licenseplate, sizeof(licenseplate), "License Plate: %s", Vehicle[veh_enum_id][E_VEHICLE_LICENSE]);
    SendServerMessage(playerid, COLOR_INFO, "Vehicle", "DEDEDE", licenseplate);

    return true ;
}

// ---------------------------------------------------------------------------------------

// /searchaddress [address] - looks up who lives at an address.
CMD:searchaddress(playerid, params[])
{

    if (IsPlayerIncapacitated(playerid, false))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.") ;
    }

    if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInMedicFaction(playerid, true))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You're not on duty as law enforcement.") ;
    }

    new input[64] ;

    if (sscanf(params, "s[64]", input))
    {
        SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/searchaddress [address]") ;
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "If you know the address number, put it FIRST!") ;
    }

    new id = strval(input);

    if (id < 0 || id > MAX_PROPERTIES)
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "Invalid ID found.") ;
    }

    if (id > 0 && id < MAX_PROPERTIES)
    {
        if (Property [ id ] [ E_PROPERTY_ID ] != INVALID_PROPERTY_ID)
        {
            new zone[64], area[64];
            GetPlayerAddress(Property[id][E_PROPERTY_EXT_X], Property[id][E_PROPERTY_EXT_Y], zone);
            GetCoords2DZone(Property[id][E_PROPERTY_EXT_X], Property[id][E_PROPERTY_EXT_Y], area, sizeof(area));

            SendServerMessage(playerid, COLOR_REALTY, "Address", "DEDEDE", sprintf("%s, %s {A3A3A3}(ID: %d)", zone, area, id)) ;
            SendServerMessage(playerid, COLOR_REALTY, "Address", "DEDEDE",  sprintf("Use {A3A3A3}/propertyfind [%d]{DEDEDE} to get a route to this location.", id)) ;

            return true;
        }
        else
        {
            SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", sprintf("Found Property ID %d, but property was invalid. Please try again.", id)) ;
            return true;
        }
    }
    else
    {

        new count = 0;

        foreach (new i: Properties)
        {

            new zone[64], area[64];
            GetPlayerAddress(Property[i][E_PROPERTY_EXT_X], Property[i][E_PROPERTY_EXT_Y], zone);
            GetCoords2DZone(Property[id][E_PROPERTY_EXT_X], Property[id][E_PROPERTY_EXT_Y], area, sizeof(area));

            if (strfind(zone, input, true) != -1)
            {
                count++;

                if (count <= 20)
                    SendServerMessage(playerid, COLOR_REALTY, "Address", "DEDEDE", sprintf("%s, %s {A3A3A3}(ID: %d)", zone, area, i)) ;

            }
            else continue;

        }

        if (!count)
        {
            SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3",  "No properties match your search. Please try again.") ;
        }
        else
        {
            SendServerMessage(playerid, COLOR_REALTY, "Address", "DEDEDE",  sprintf("Found {A3A3A3}%d{A3A3A3} properties.", count)) ;
            SendServerMessage(playerid, COLOR_REALTY, "Address", "DEDEDE",  "Use {A3A3A3}/propertyfind [ID]{DEDEDE} to get a route to a property.") ;
        }
        return true;
    }
}

CMD:addressearch(playerid, params[])
{
    return cmd_searchaddress(playerid, params);
}

// /passstamp [player] [amount] - gives prison stamps to another prisoner.
CMD:passstamp(playerid, params[])
{
    new targetid, amount;

    if (sscanf(params, "k<player>i", targetid, amount))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/passstamp [playerid] [amount]");

    if (!IsPlayerConnected(targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player isn't connected.");

    if (targetid == playerid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't pass stamps to yourself.");

    if (!IsPlayerNearPlayer(playerid, targetid, 5.0))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near that player.");

    if (amount <= 0)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Amount must be at least 1.");

    if (Character[playerid][E_CHARACTER_PRISON_STAMPS] < amount)
    {
        new errMsg[96];
        format(errMsg, sizeof(errMsg), "You only have %d stamp(s) to pass.", Character[playerid][E_CHARACTER_PRISON_STAMPS]);
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", errMsg);
    }

    Character[playerid][E_CHARACTER_PRISON_STAMPS] -= amount;
    Character[targetid][E_CHARACTER_PRISON_STAMPS] += amount;

    new query1[256], query2[256];

    mysql_format(mysql, query1, sizeof(query1),
        "UPDATE characters SET player_prison_stamps = %d WHERE player_id = %d",
        Character[playerid][E_CHARACTER_PRISON_STAMPS], Character[playerid][E_CHARACTER_ID]);

    mysql_format(mysql, query2, sizeof(query2),
        "UPDATE characters SET player_prison_stamps = %d WHERE player_id = %d",
        Character[targetid][E_CHARACTER_PRISON_STAMPS], Character[targetid][E_CHARACTER_ID]);

    mysql_tquery(mysql, query1);
    mysql_tquery(mysql, query2);

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    
    new actionMsg[128];
    format(actionMsg, sizeof(actionMsg), "* %s hands %s a work stamp.", ReturnRPName(playerid), ReturnRPName(targetid));
    ProxDetectorXYZ(px, py, pz, GetPlayerInterior(playerid), GetPlayerVirtualWorld(playerid), 5.0, 0xA3A3A3FF, actionMsg);

    new senderMsg[128], receiverMsg[128];
    format(senderMsg,   sizeof(senderMsg),   "[Prison Stamps] You passed %d stamps to %s. You now have %d.", amount, ReturnRPName(targetid), Character[playerid][E_CHARACTER_PRISON_STAMPS]);
    format(receiverMsg, sizeof(receiverMsg),  "[Prison Stamps] %s passed you %d stamps. You now have %d.", ReturnRPName(playerid), amount, Character[targetid][E_CHARACTER_PRISON_STAMPS]);

    SendClientMessage(playerid, COLOR_BLUE, senderMsg);
    SendClientMessage(targetid, COLOR_BLUE, receiverMsg);

    return true;
}

CMD:givestamp(playerid, params[]) return cmd_passstamp(playerid, params);

// /passcigarette [player] [amount] - offers cigarettes to another player.
CMD:passcigarette(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.");

    new targetid, amount;

    if (sscanf(params, "k<player>i", targetid, amount))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/passcigarette [playerid] [amount]");

    if (!IsPlayerConnected(targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player isn't connected.");

    if (targetid == playerid)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't pass cigarettes to yourself.");

    if (!IsPlayerNearPlayer(playerid, targetid, 5.0))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near that player.");

    if (IsPlayerIncapacitated(targetid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "Your target is incapacitated and can't accept this.");

    if (amount <= 0)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Amount must be at least 1.");

    if (PlayerVar[playerid][E_PLAYER_COMMISSARY_CIGS] < amount)
    {
        new errMsg[96];
        format(errMsg, sizeof(errMsg), "You only have %d cigarette(s) to pass.", PlayerVar[playerid][E_PLAYER_COMMISSARY_CIGS]);
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", errMsg);
    }

    if (GetPVarInt(targetid, "CIGARETTEREQUEST") != 0)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player already has a pending request. Wait for it to expire.");

    SetPVarInt(targetid, "CIGARETTEREQUEST", 1);
    SetPVarInt(targetid, "CIGARETTEREQUEST_FROM", playerid);
    SetPVarInt(targetid, "CIGARETTEREQUEST_AMOUNT", amount);

    new string[144];
    format(string, sizeof(string), "[Info] {777777}You have offered {DE9B1F}%dx cigarette(s){777777} to %s. (30 seconds to respond)",
           amount, ReturnSettingsName(targetid, playerid));
    SendClientMessage(playerid, 0xAAFF00FF, string);

    format(string, sizeof(string), "[Info] {777777}%s (%d) has offered you {DE9B1F}%dx cigarette(s){777777}.",
           ReturnSettingsName(playerid, targetid), playerid, amount);
    SendClientMessage(targetid, 0xAAFF00FF, string);
    SendClientMessage(targetid, 0xAAFF00FF, "Type \"/accept cigarette\" to accept. (30 seconds to respond)");

    defer CigaretteRequestExpire(targetid, playerid);

    return true;
}

// Timer: cancels a cigarette offer after 30 seconds.
timer CigaretteRequestExpire[30000](targetid, playerid)
{
    if (GetPVarInt(targetid, "CIGARETTEREQUEST") == 1)
    {
        SendClientMessage(targetid, -1, "{AAFF00}[Info] {777777}The cigarette pass request has expired.");
        SendClientMessage(playerid, -1, "{AAFF00}[Info] {777777}Your cigarette pass request has expired.");
        SetPVarInt(targetid, "CIGARETTEREQUEST", 0);
        SetPVarInt(targetid, "CIGARETTEREQUEST_FROM", INVALID_PLAYER_ID);
        SetPVarInt(targetid, "CIGARETTEREQUEST_AMOUNT", 0);
    }
}

CMD:megaphoneprison(playerid, params[]) return cmd_mp(playerid, params);
// /mp [text] - speak through the megaphone (alias /megaphoneprison).
CMD:mp(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3", "You're currently incapacitated and can't do this.") ;

    if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerInMedicFaction(playerid, true) && !IsPlayerInSecurityFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not on duty in a government faction.");

    if (!IsInPrison(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only use this in prison.");

    new text [ 144 ] ;

    if (sscanf(params, "s[144]", text))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/mp [text]") ;

    new string [ 256 ] ;

    format(string, sizeof(string), ":o< %s ]",  text) ;
    ProxDetectorEx(playerid, 100.0, 0x7880B8FF, "[ ", string);

    // NEW LOGGING: Log this as a LOG_TYPE_CHAT for sender (playerid)
    AddLogEntry(playerid, LOG_TYPE_CHAT, sprintf("[Megaphone]: %s", text));

    return true ;
}
