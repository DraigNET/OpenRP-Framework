// ============================================================================
// File: vehicle/data/vehicle_tickets.pwn
// Vehicle tickets (fines on a vehicle): /vticket issues one, /paytickets pays outstanding ones
// at the Administration Building. Unpaid fines block selling.
// Commands: /vticket /paytickets
// ============================================================================

#include <a_samp>
#include <sscanf2>
#include <a_mysql>

#define COLOR_TICKET            0xF4C542FF
#define TICKET_STATUS_UNPAID    (0)
#define TICKET_STATUS_PAID      (1)
#define TICKET_STATUS_VOID      (2)

#define CITY_HALL_X             (0.0) // TODO: set coordinates for your map
#define CITY_HALL_Y            (0.0) // TODO: set coordinates for your map
#define CITY_HALL_Z             (0.0) // TODO: set coordinates for your map
#define CITY_HALL_RANGE         5.0

static VehicleTicketDlgStr[4096];

#define MAX_VEHICLE_TICKETS 5000
forward bool:VehicleTicket_HasRecent(vehicle_sqlid, &remaining);

enum E_VEHICLE_TICKET_DATA
{
    vt_id,
    vt_vehicle_sqlid,
    vt_plate[32],
    vt_amount,
    vt_reason[128],
    vt_issuer_charid,
    vt_issuer_name[32],
    vt_issuer_faction,
    vt_date_unix,
    vt_due_unix,
    vt_status,
    vt_paid_unix
}

new VehicleTicketData[MAX_VEHICLE_TICKETS][E_VEHICLE_TICKET_DATA];
new VehicleTicketCount;

new VehicleOutstandingFines[MAX_VEHICLES];

// /vticket - law enforcement writes a ticket on a vehicle.
CMD:vticket(playerid, params[])
{
    new vehicleid, amount, reason[128];

    if (sscanf(params, "dds[128]", vehicleid, amount, reason))
    {
        SendClientMessage(playerid, COLOR_ERROR, "Usage: /vticket [vehicleid] [amount] [reason]");
        return 1;
    }

    if (!strlen(reason)) return SendClientMessage(playerid, COLOR_ERROR, "You must provide a reason.");

    if (amount <= 0)
        return SendClientMessage(playerid, COLOR_ERROR, "Invalid fine amount.");

    new factionid = Character[playerid][E_CHARACTER_FACTIONID];
    if (!factionid)
        return SendClientMessage(playerid, COLOR_ERROR, "You must be in a faction.");

    new faction_enum = Faction_GetEnumID(factionid);
    if (faction_enum == INVALID_FACTION_ID)
        return SendClientMessage(playerid, COLOR_ERROR, "Faction error. Contact a developer.");

    if (!Faction_CanID(faction_enum, FAC_CAP_TICKET))
    {
        return SendClientMessage(playerid, COLOR_ERROR, "You are not authorised to issue vehicle tickets.");
    }

    if (!IsValidVehicle(vehicleid)) return SendClientMessage(playerid, COLOR_ERROR, "Invalid vehicle ID.");

    new veh_enum_id = Vehicle_GetEnumID(vehicleid);
    if (veh_enum_id == -1)
        return SendClientMessage(playerid, COLOR_ERROR, "Invalid vehicle.");

    if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] != E_VEHICLE_TYPE_PLAYER && Vehicle[veh_enum_id][E_VEHICLE_TYPE] != E_VEHICLE_TYPE_FACTION )
        return SendClientMessage(playerid, COLOR_ERROR, "You can only ticket player/faction owned vehicles.");

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new Float:vx, Float:vy, Float:vz;
    GetVehiclePos(vehicleid, vx, vy, vz);

    if (GetDistanceBetweenPoints(px, py, pz, vx, vy, vz) > 10.0)
    {
        return SendClientMessage(playerid, COLOR_ERROR, "You must be near the vehicle to issue a ticket.");
    }

    if (IsVehicleOccupied(vehicleid))
    {
        return SendClientMessage(playerid, COLOR_ERROR, "You cannot ticket an occupied vehicle.");
    }

    if (Vehicle[veh_enum_id][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FACTION)
    {
        if (Vehicle[veh_enum_id][E_VEHICLE_OWNER] == factionid)
        {
            return SendClientMessage(playerid, COLOR_ERROR, "You cannot ticket your own faction vehicles.");
        }
    }

    new vehicle_sqlid = Vehicle[veh_enum_id][E_VEHICLE_SQLID];

    new remaining;

    if (VehicleTicket_HasRecent(vehicle_sqlid, remaining))
    {
        new minutes = floatround(remaining / 60.0, floatround_ceil);

        return SendClientMessage(playerid, COLOR_ERROR,
            sprintf("This vehicle was recently ticketed. Try again in %d minute(s).", minutes));
    }

    VehicleOutstandingFines[veh_enum_id] += amount;

    new plate[32];
    format(plate, sizeof(plate), "%s", Vehicle[veh_enum_id][E_VEHICLE_LICENSE]);

    new query[512];

    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO vehicle_tickets \
        (vt_vehicle_sqlid, vt_plate, vt_amount, vt_reason, vt_issuer_charid, vt_issuer_name, vt_issuer_faction, vt_date, vt_due, vt_status) \
        VALUES (%d, '%e', %d, '%e', %d, '%e', %d, NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY), %d)",
        vehicle_sqlid,
        plate,
        amount,
        reason,
        Character[playerid][E_CHARACTER_ID],
        ReturnRPName(playerid),
        factionid,
        TICKET_STATUS_UNPAID
    );

    inline OnVehicleTicketInserted()
    {
        new insertid = cache_insert_id();

        if (!insertid)
        {
            printf("[VTICKET ERROR] Insert failed. MySQL error: %d", mysql_errno(mysql));
            return 1;
        }

        if (veh_enum_id < 0 || veh_enum_id >= MAX_VEHICLES)
            return 1;

        if (VehicleTicketCount >= MAX_VEHICLE_TICKETS)
            return 1;

        new slot = VehicleTicketCount;

        VehicleTicketData[slot][vt_id] = insertid;
        VehicleTicketData[slot][vt_vehicle_sqlid] = Vehicle[veh_enum_id][E_VEHICLE_SQLID];
        VehicleTicketData[slot][vt_amount] = amount;
        VehicleTicketData[slot][vt_status] = TICKET_STATUS_UNPAID;

        VehicleTicketData[slot][vt_date_unix] = gettime();
        VehicleTicketData[slot][vt_due_unix] = gettime() + 259200;

        format(VehicleTicketData[slot][vt_reason], 128, "%s", reason);
        format(VehicleTicketData[slot][vt_issuer_name], 32, "%s", ReturnRPName(playerid));

        VehicleTicketCount++;

        printf("[VTICKET] Ticket inserted successfully. ID: %d", insertid);
    }

    MySQL_TQueryInline(mysql, using inline OnVehicleTicketInserted, query, "");

    SendClientMessage(playerid, COLOR_TICKET, sprintf("You issued a $%s vehicle citation.", IntegerWithDelimiter(amount)));
    ProxDetectorEx(playerid, 20.0, COLOR_ACTION, "**",
            sprintf("writes a ticket and places it onto the %s's windscreen.",
            ReturnVehicleName(vehicleid)), .annonated=true);

    AddLogEntry(playerid, LOG_TYPE_SCRIPT,
        sprintf("Issued vehicle ticket ($%d) to SQL ID %d", amount, vehicle_sqlid));

    return 1;
}

// /paytickets - pays the tickets on your vehicle.
CMD:paytickets(playerid, params[])
{
    if (!IsAtGovFrontDesk(playerid))
    {
        SendClientMessage(playerid, COLOR_ERROR, "You must be at the Administration Building or a police station to pay vehicle citations.");
        return 1;
    }

    VTickets_ShowOwned(playerid);
    return 1;
}

// Returns true if a vehicle was ticketed recently (with the time left).
stock bool:VehicleTicket_HasRecent(vehicle_sqlid, &remaining)
{
    new current = gettime();
    remaining = 0;

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_vehicle_sqlid] != vehicle_sqlid)
            continue;

        if (VehicleTicketData[i][vt_status] != TICKET_STATUS_UNPAID)
            continue;

        new diff = current - VehicleTicketData[i][vt_date_unix];

        if (diff < 3600)
        {
            remaining = 3600 - diff;
            return true;
        }
    }

    return false;
}

// Processes a payment for a vehicle's tickets.
stock VehicleTickets_ProcessPayment(playerid, vehicle_sqlid)
{
    new veh_enum = Vehicle_GetEnumIDFromSQLID(vehicle_sqlid);
    if (veh_enum == -1)
        return 1;

    new total = VehicleOutstandingFines[veh_enum];

    if (total <= 0)
        return SendClientMessage(playerid, COLOR_TICKET, "No outstanding vehicle citations.");

    new type = Vehicle[veh_enum][E_VEHICLE_TYPE];

    if (type == E_VEHICLE_TYPE_PLAYER)
    {
        if (Vehicle[veh_enum][E_VEHICLE_OWNER] != Character[playerid][E_CHARACTER_ID])
            return SendClientMessage(playerid, COLOR_ERROR, "You do not own this vehicle!");
    }
    else if (type == E_VEHICLE_TYPE_FACTION)
    {
        new playerFaction = Character[playerid][E_CHARACTER_FACTIONID];
        new playerTier = Character[playerid][E_CHARACTER_FACTIONTIER];

        if (Vehicle[veh_enum][E_VEHICLE_OWNER] != playerFaction)
            return SendClientMessage(playerid, COLOR_ERROR, "This is not your faction vehicle.");

        if (playerTier > 2)
            return SendClientMessage(playerid, COLOR_ERROR, "Only Tier 1 and Tier 2 may pay faction vehicle tickets.");
    }
    else
    {
        return SendClientMessage(playerid, COLOR_ERROR, "This vehicle cannot have tickets paid.");
    }

    if (GetPlayerCash(playerid) < total)
        return SendClientMessage(playerid, COLOR_ERROR,
            sprintf("You need $%s to clear your citations.", IntegerWithDelimiter(total)));

    TakePlayerCash(playerid, total, "Vehicle citation payment");

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_vehicle_sqlid] == vehicle_sqlid &&
            VehicleTicketData[i][vt_status] == TICKET_STATUS_UNPAID)
        {
            VehicleTicketData[i][vt_status] = TICKET_STATUS_PAID;
        }
    }

    VehicleOutstandingFines[veh_enum] = 0;

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE vehicle_tickets SET vt_status = %d, vt_paid_date = NOW() WHERE vt_vehicle_sqlid = %d AND vt_status = %d",
        TICKET_STATUS_PAID,
        vehicle_sqlid,
        TICKET_STATUS_UNPAID
    );
    mysql_tquery(mysql, query);

    SendClientMessage(playerid, COLOR_TICKET,
        sprintf("You paid $%s in vehicle citations.", IntegerWithDelimiter(total)));

    return 1;
}

// Shows the player's tickets on their vehicles.
static VTickets_ShowOwned(playerid)
{
    new vehmap[256];
    new count = 0;

    new playerFaction = Character[playerid][E_CHARACTER_FACTIONID];
    new playerTier = Character[playerid][E_CHARACTER_FACTIONTIER];

    format(VehicleTicketDlgStr, sizeof(VehicleTicketDlgStr),
        "Plate\tType\tModel\tOutstanding Fines\n");

    for (new i; i < sizeof(Vehicle); i++)
    {
        // -----------------------------
        // Skip invalid vehicles FIRST
        // -----------------------------
        if (Vehicle[i][E_VEHICLE_SQLID] <= 0)
            continue;

        new show = 0;
        new typeStr[12];

        // -----------------------------
        // PLAYER VEHICLES
        // -----------------------------
        if (Vehicle[i][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_PLAYER)
        {
            if (Vehicle[i][E_VEHICLE_OWNER] == Character[playerid][E_CHARACTER_ID])
            {
                show = 1;
                format(typeStr, sizeof(typeStr), "Private");
            }
        }

        // -----------------------------
        // FACTION VEHICLES
        // -----------------------------
        else if (Vehicle[i][E_VEHICLE_TYPE] == E_VEHICLE_TYPE_FACTION)
        {
            if (Vehicle[i][E_VEHICLE_OWNER] == playerFaction && playerTier <= 2)
            {
                show = 1;
                format(typeStr, sizeof(typeStr), "Faction");
            }
        }

        if (!show)
            continue;

        // -----------------------------
        // NOW check fines (after filtering)
        // -----------------------------
        new fines = VehicleOutstandingFines[i];

        if (fines <= 0)
            continue;

        format(VehicleTicketDlgStr, sizeof(VehicleTicketDlgStr),
            "%s%s\t%s\t%s\t{FF0000}$%s\n",
            VehicleTicketDlgStr,
            Vehicle[i][E_VEHICLE_LICENSE],
            typeStr,
            ReturnVehicleModelName(Vehicle[i][E_VEHICLE_MODELID]),
            IntegerWithDelimiter(fines)
        );

        vehmap[count] = i;
        count++;
    }

    if (!count)
    {
        SendClientMessage(playerid, COLOR_VEHICLE, "You have no outstanding vehicle citations.");
        return 1;
    }

    inline VehicleTicketSelect(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, inputtext

        if (!response)
            return 1;

        new veh_enum_id = vehmap[listitem];
        new sqlid = Vehicle[veh_enum_id][E_VEHICLE_SQLID];

        VehicleTickets_ProcessPayment(pid, sqlid);
        return 1;
    }

    Dialog_ShowCallback(playerid, using inline VehicleTicketSelect,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Outstanding Vehicle Citations",
        VehicleTicketDlgStr,
        "Pay",
        "Close");

    return 1;
}

// Returns the total unpaid fines of a vehicle.
stock VehicleTickets_GetTotalFines(vehicle_sqlid)
{
    new veh_enum = Vehicle_GetEnumIDFromSQLID(vehicle_sqlid);
    if (veh_enum == -1)
        return 0;

    return VehicleOutstandingFines[veh_enum];
}

// Loads vehicle tickets from the database.
VehicleTickets_Load()
{
    VehicleTicketCount = 0;

    for (new i; i < MAX_VEHICLE_TICKETS; i++)
    {
        VehicleTicketData[i][vt_id] = 0;
        VehicleTicketData[i][vt_vehicle_sqlid] = 0;
        VehicleTicketData[i][vt_amount] = 0;
        VehicleTicketData[i][vt_status] = 0;
    }

    for (new i; i < MAX_VEHICLES; i++)
        VehicleOutstandingFines[i] = 0;

    inline OnTicketsLoad()
    {
        for (new i = 0, r = cache_num_rows(); i < r && i < MAX_VEHICLE_TICKETS; i++)
        {
            cache_get_value_name_int(i, "vt_id", VehicleTicketData[i][vt_id]);
            cache_get_value_name_int(i, "vt_vehicle_sqlid", VehicleTicketData[i][vt_vehicle_sqlid]);
            cache_get_value_name(i, "vt_plate", VehicleTicketData[i][vt_plate]);
            cache_get_value_name_int(i, "vt_amount", VehicleTicketData[i][vt_amount]);
            cache_get_value_name(i, "vt_reason", VehicleTicketData[i][vt_reason]);
            cache_get_value_name_int(i, "vt_issuer_charid", VehicleTicketData[i][vt_issuer_charid]);
            cache_get_value_name(i, "vt_issuer_name", VehicleTicketData[i][vt_issuer_name]);
            cache_get_value_name_int(i, "vt_issuer_faction", VehicleTicketData[i][vt_issuer_faction]);
            cache_get_value_name_int(i, "vt_date_unix", VehicleTicketData[i][vt_date_unix]);
            cache_get_value_name_int(i, "vt_due_unix", VehicleTicketData[i][vt_due_unix]);
            cache_get_value_name_int(i, "vt_status", VehicleTicketData[i][vt_status]);
            cache_get_value_name_int(i, "vt_paid_unix", VehicleTicketData[i][vt_paid_unix]);

            if (VehicleTicketCount < MAX_VEHICLE_TICKETS)
                VehicleTicketCount++;
        }

        printf("[VEHICLE TICKETS] Loaded %d tickets.", VehicleTicketCount);
        VehicleTickets_RebuildTotals();
    }

    MySQL_TQueryInline(mysql, using inline OnTicketsLoad,
        "SELECT \
            vt_id, \
            vt_vehicle_sqlid, \
            vt_plate, \
            vt_amount, \
            vt_reason, \
            vt_issuer_charid, \
            vt_issuer_name, \
            vt_issuer_faction, \
            UNIX_TIMESTAMP(vt_date) AS vt_date_unix, \
            UNIX_TIMESTAMP(vt_due) AS vt_due_unix, \
            vt_status, \
            UNIX_TIMESTAMP(vt_paid_date) AS vt_paid_unix \
        FROM vehicle_tickets"
    );

    return 1;
}

// Returns true if the vehicle has fines outstanding.
stock VTickets_HasOutstandingFines(veh_enum_id)
{
    if (veh_enum_id < 0 || veh_enum_id >= MAX_VEHICLES)
        return 0;

    return (VehicleOutstandingFines[veh_enum_id] > 0);
}

// Recalculates the fine totals of all vehicles.
stock VehicleTickets_RebuildTotals()
{
    for (new i; i < MAX_VEHICLES; i++)
        VehicleOutstandingFines[i] = 0;

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_status] != TICKET_STATUS_UNPAID)
            continue;

        new veh_enum =
            Vehicle_GetEnumIDFromSQLID(
                VehicleTicketData[i][vt_vehicle_sqlid]
            );

        if (veh_enum != -1)
        {
            VehicleOutstandingFines[veh_enum] +=
                VehicleTicketData[i][vt_amount];
        }
    }

    printf("[VEHICLE TICKETS] Outstanding totals rebuilt.");
    return 1;
}

// Returns true if a ticket has expired.
stock bool:VehicleTicket_IsExpired(index)
{
    if (VehicleTicketData[index][vt_status] != TICKET_STATUS_UNPAID)
        return false;

    if (VehicleTicketData[index][vt_due_unix] <= 0)
        return false;

    return (gettime() > VehicleTicketData[index][vt_due_unix]);
}
