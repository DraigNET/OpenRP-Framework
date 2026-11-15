// ============================================================================
// File: police/systems/mdc.pwn
// Mobile Data Computer (/mdc): look up people and vehicles by name or plate, criminal records,
// warrants, BOLOs, tickets and units. The largest police file. /mdcpager sends a pager message
// (and posts to Discord if enabled).
// Commands: /mdc /mdcpager /pmc
// ============================================================================

// =======================
// MDC CORE DEFINITIONS
// =======================

#define MDC_ERROR   (21001)
#define MDC_SELECT  (21000)
#define MDC_OPEN    (45400)
#define MDC_MAX_VEHICLES (10)

#define MDC_MAX_TICKETS (100)


//static MDC_TicketCount[MAX_PLAYERS];

forward MDC_ShowCrimes(playerid);
forward MDC_ShowCrimeView(playerid, recordid);
forward MDC_ShowTickets(playerid);
forward MDC_ShowTicketView(playerid, ticketid);

static CrimeDlgStr[4096];

enum E_MDC_SESSION
{
    bool:MDC_Active,

    MDC_TargetCharID,
    MDC_TargetName[MAX_PLAYER_NAME],

    MDC_VehicleIDs[MDC_MAX_VEHICLES],
    MDC_VehicleCount,

    // ---- crimes ----
    MDC_CrimeIDs[100],
    MDC_CrimeCount,

    // ---- character tickets ----
    MDC_TicketIDs[50],
    MDC_TicketCount,

    // ---- vehicle tickets ----
    MDC_VehicleTicketIDs[MDC_MAX_TICKETS],
    MDC_VehicleTicketCount,

    // ---- BOLOS ----
    MDC_BoloIDs[50],
    MDC_BoloCount
};

enum E_PMC_SESSION
{
    bool:PMC_Active,

    PMC_VehicleTicketIDs[MDC_MAX_TICKETS],
    PMC_VehicleTicketCount
};

static PMCSession[MAX_PLAYERS][E_PMC_SESSION];

static MDCSession[MAX_PLAYERS][E_MDC_SESSION];

// Clears a player's MDC session.
static MDC_Reset(playerid)
{
    MDCSession[playerid][MDC_Active] = false;
    MDCSession[playerid][MDC_TargetCharID] = 0;
    MDCSession[playerid][MDC_TargetName][0] = EOS;

    MDCSession[playerid][MDC_VehicleCount] = 0;

    MDCSession[playerid][MDC_CrimeCount] = 0;
    MDCSession[playerid][MDC_TicketCount] = 0;
    MDCSession[playerid][MDC_VehicleTicketCount] = 0;
    MDCSession[playerid][MDC_BoloCount] = 0;
}

// Returns true if the player may use the MDC (law enforcement or government records on duty).
static bool:MDC_CanUse(playerid)
{
    return IsPlayerInLEAFaction(playerid, true)
        || IsPlayerGovRecords(playerid, true);
}

// /mdc - opens the Mobile Data Computer main menu.
CMD:mdc(playerid)
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3",
            "You're currently incapacitated and can't do this.");

    if (!MDC_CanUse(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Abuse", "A3A3A3",
            "You're not on duty as law enforcement.");

    if (Character[ playerid ] [ E_CHARACTER_FACTIONTIER ] > 3)
	{
        return SendServerMessage ( playerid, COLOR_ERROR, "Abuse", "A3A3A3", "You are unable to use this command." ) ;
	}

    if (!IsPlayerInAnyVehicle(playerid) && !IsPlayerAtMugshotPos(playerid))
        return SendClientMessage(playerid, COLOR_ERROR,
            "You must be in a vehicle or at a mugshot area to use the MDC.");

    MDC_Reset(playerid);
    MDCSession[playerid][MDC_Active] = true;

    MDC_ShowMainMenu(playerid);
    return 1;
}

// /mdcpager [message] - sends a pager message to the department's Discord channel.
CMD:mdcpager(playerid, params[])
{
    if (IsPlayerIncapacitated(playerid, false))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3",
            "You're currently incapacitated and can't do this.");
    }

    if (!IsPlayerInLEAFaction(playerid))
    {
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3",
            "You must be in a law enforcement faction to use the MDC pager.");
    }

    new msg[256];

    if (sscanf(params, "s[256]", msg))
    {
        SendClientMessage(playerid, COLOR_YELLOW, "/mdcpager [message]");
        return 1;
    }

    if(IsPlayerInPoliceFaction(playerid))
    {
        new disMsg[512];
        format(disMsg, sizeof(disMsg),
            "**[MDC PAGER]** From %s %s:\n%s",
            Character[playerid][E_CHARACTER_FACTIONRANK],
            ReturnRPName(playerid),
            msg
        );

        DCC_SendPoliceMDCMessage(
            disMsg,
            DISCORD_ROLE_LINE_STAFF,
            DISCORD_ROLE_SUPERVISORY,
            DISCORD_ROLE_COMMAND
        );
    }

    SendServerMessage(playerid, COLOR_LIGHTBLUE, "Pager Sent", "A3A3A3",
        "Your MDC pager message has been sent to Discord staff.");

    return 1;
}

// Shows the MDC main menu (people, vehicles, BOLOs...).
static MDC_ShowMainMenu(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    PlayerPlaySound(playerid, MDC_OPEN, x, y, z);

    inline DlgMDCMain(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, inputtext

        if (!response)
        {
            PlayerPlaySound(pid, MDC_ERROR, x, y, z);
            MDC_Reset(pid);
            return 1;
        }

        switch (listitem)
        {
            case 0: MDC_ShowNameSearch(pid);
            case 1: MDC_ShowPlateSearch(pid);
            case 2: MDC_LoadBolos(pid);
            case 3: SendServerMessage(pid, COLOR_INFO, "MDC", "DEDEDE",
                        "911 call system not yet implemented.");
        }
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgMDCMain,
        DIALOG_STYLE_LIST,
        "MDC - Dashboard",
        "{FFFFFF}Name Search\n" \
        "{FFFFFF}Plate Search\n" \
        "{FFFFFF}All Points Bulletin\n" \
        "{BDBDBD}Recent 911 Calls",
        "Select",
        "Close"
    );

    return 1;
}

// Asks for a person's name to search the MDC.
static MDC_ShowNameSearch(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    inline DlgNameSearch(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, listitem

        if (!response)
        {
            PlayerPlaySound(pid, MDC_ERROR, x, y, z);
            MDC_ShowMainMenu(pid);
            return 1;
        }

        strtrim(inputtext);

        if (strlen(inputtext) < 3 || strfind(inputtext, "_", true) == -1)
        {
            PlayerPlaySound(pid, MDC_ERROR, x, y, z);
            MDC_ShowNameSearch(pid);
            return 1;
        }
        MDC_LoadCharacterByName(pid, inputtext);
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgNameSearch,
        DIALOG_STYLE_INPUT,
        "MDC - Name Search",
        "{a9c4e4}Enter full legal name\n\n" \
        "{FFFFFF}Format: firstname_lastname\n" \
        "{BDBDBD}Example: John_Doe",
        "Search",
        "Back"
    );

    return 1;
}

// Loads a character from the database by name for the MDC.
static MDC_LoadCharacterByName(playerid, const rpname[])
{
    new query[256];

    mysql_format(
        mysql,
        query,
        sizeof(query),
        "SELECT player_id, player_name FROM characters WHERE player_name = '%e' LIMIT 1",
        rpname
    );

    inline OnCharacterLoaded()
    {
        if (!MDCSession[playerid][MDC_Active])
            return 1;

        if (!cache_num_rows())
        {
            SendServerMessage(playerid, COLOR_ERROR, "MDC", "A3A3A3",
                "No matching character found.");
            MDC_ShowNameSearch(playerid);
            return 1;
        }

        new char_id, actual_name[MAX_PLAYER_NAME];
        cache_get_value_name_int(0, "player_id", char_id);
        cache_get_value_name(0, "player_name", actual_name);

        MDCSession[playerid][MDC_TargetCharID] = char_id;
        format(MDCSession[playerid][MDC_TargetName], MAX_PLAYER_NAME, "%s", actual_name);

        MDC_ShowDataDashboard(playerid);
        return 1;
    }

    MySQL_TQueryInline(mysql, using inline OnCharacterLoaded, query, "");
    return 1;
}

// Shows the data dashboard for the searched person.
static MDC_ShowDataDashboard(playerid)
{
    if (!MDCSession[playerid][MDC_Active])
        return 0;

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new display_name[MAX_PLAYER_NAME];
    format(display_name, sizeof display_name, "%s", MDCSession[playerid][MDC_TargetName]);
    CapitalizeName(display_name);
    strreplace(display_name, "_", " ");

    new title[96];
    format(title, sizeof title, "%s - MDC Dashboard", display_name);

    inline DlgDashboard(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, inputtext

        if (!response)
        {
            PlayerPlaySound(pid, MDC_ERROR, x, y, z);
            MDC_ShowNameSearch(pid);
            return 1;
        }

        switch (listitem)
        {
            case 0: MDC_LoadPersonal(pid);
            case 1: MDC_LoadVehicles(pid);
            case 2: MDC_ShowCrimes(pid);
            case 3: MDC_ShowTickets(pid);
            case 4: MDC_ShowNameSearch(pid);
        }
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgDashboard,
        DIALOG_STYLE_LIST,
        title,
        "{FFFFFF}Personal Information\n" \
        "{FFFFFF}Vehicular Information\n\n" \
        "{FFFFFF}Criminal Record\n" \
        "{FFFFFF}Tickets\n\n" \
        "{BDBDBD}New Search",
        "Select",
        "Back"
    );

    return 1;
}

// Loads and shows the person's personal data (age, address, licences...).
static MDC_LoadPersonal(playerid)
{
    if (!MDCSession[playerid][MDC_Active])
        return 0;

    new query[512];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    mysql_format(
        mysql,
        query,
        sizeof(query),
        "SELECT player_attribute_age, player_factionid, player_phnumber, player_driverslicense, player_gunlicense FROM characters WHERE player_id = %d LIMIT 1",
        MDCSession[playerid][MDC_TargetCharID]
    );

    inline OnPersonalLoaded()
    {
        if (!cache_num_rows())
        {
            SendServerMessage(playerid, COLOR_ERROR, "MDC", "A3A3A3",
                "No personal information found.");
            MDC_ShowDataDashboard(playerid);
            return 1;
        }

        new age, factionid, phone, dlic, glic;
        cache_get_value_name_int(0, "player_attribute_age", age);
        cache_get_value_name_int(0, "player_factionid", factionid);
        cache_get_value_name_int(0, "player_phnumber", phone);
        cache_get_value_name_int(0, "player_driverslicense", dlic);
        cache_get_value_name_int(0, "player_gunlicense", glic);

        // Employer
        new employer[MAX_FACTION_NAME] = "None";
        new fenum = Faction_GetEnumID(factionid);
        if (fenum != INVALID_FACTION_ID)
            format(employer, sizeof employer, "%s", Faction[fenum][E_FACTION_NAME]);

        // License strings
        new dlic_str[32], glic_str[64];

        format(dlic_str, sizeof dlic_str,
            dlic ? "{A5D6A7}Valid" : "{EF9A9A}None");

        if (glic > 0)
        {
            if (glic < gettime())
                format(glic_str, sizeof glic_str, "{FFCC80}Expired");
            else
                format(glic_str, sizeof glic_str, "{A5D6A7}Valid");
        }
        else format(glic_str, sizeof glic_str, "{EF9A9A}None");

        // Display name
        new display[MAX_PLAYER_NAME];
        format(display, sizeof display, "%s", MDCSession[playerid][MDC_TargetName]);
        CapitalizeName(display);
        strreplace(display, "_", " ");

        new body[512];
        format(body, sizeof body,
            "{a9c4e4}___________________________________________\n" \
            "{a9c4e4}PERSONAL INFORMATION\n" \
            "{a9c4e4}___________________________________________\n\n" \
            "{a9c4e4}Full Name:{FFFFFF}\t%s\n" \
            "{a9c4e4}Age:{FFFFFF}\t\t%d\n" \
            "{a9c4e4}Employer:{FFFFFF}\t%s\n\n" \
            "{a9c4e4}Contact\n" \
            "{a9c4e4}Phone:{FFFFFF}\t\t%d\n\n" \
            "{a9c4e4}Licensing\n" \
            "{a9c4e4}Driver License:{FFFFFF}\t\t%s\n" \
            "{a9c4e4}Firearms License:{FFFFFF}\t%s\n\n" \
            "{a9c4e4}___________________________________________",
            display,
            age,
            employer,
            phone,
            dlic_str,
            glic_str
        );

        inline DlgPersonalBack(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused dialogid, response, listitem, inputtext
            PlayerPlaySound(pid, MDC_ERROR, x, y, z);
            MDC_ShowDataDashboard(pid);
            return 1;
        }

        Dialog_ShowCallback(
            playerid,
            using inline DlgPersonalBack,
            DIALOG_STYLE_MSGBOX,
            "Personal Information",
            body,
            "Back"
        );

        return 1;
    }

    MySQL_TQueryInline(mysql, using inline OnPersonalLoaded, query, "");
    return 1;
}

// Loads and shows the vehicles the person owns.
static MDC_LoadVehicles(playerid)
{
    if (!MDCSession[playerid][MDC_Active])
        return 0;

    MDCSession[playerid][MDC_VehicleCount] = 0;

    new query[512];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    mysql_format(
        mysql,
        query,
        sizeof(query),
        "SELECT vehicle_sqlid, vehicle_modelid, vehicle_license, vehicle_color_a, vehicle_color_b " \
        "FROM vehicles " \
        "WHERE vehicle_type = %d AND vehicle_owner = %d " \
        "ORDER BY vehicle_sqlid DESC LIMIT %d",
        E_VEHICLE_TYPE_PLAYER,
        MDCSession[playerid][MDC_TargetCharID],
        MDC_MAX_VEHICLES
    );

    inline OnVehiclesLoaded()
    {
        new rows = cache_num_rows();

        if (!rows)
        {

            inline DlgVehiclesNone(pid, dialogid, response, listitem, string:inputtext[])
            {
                #pragma unused dialogid, response, listitem, inputtext
                PlayerPlaySound(pid, MDC_ERROR, x, y, z);
                MDC_ShowDataDashboard(pid);
                return 1;
            }

            Dialog_ShowCallback(
                playerid,
                using inline DlgVehiclesNone,
                DIALOG_STYLE_MSGBOX,
                "Vehicular Information",
                "No vehicles on record.",
                "Back"
            );
            return 1;
        }

        if (rows > MDC_MAX_VEHICLES)
            rows = MDC_MAX_VEHICLES;

        MDCSession[playerid][MDC_VehicleCount] = rows;

        new list[2048];
        list[0] = EOS;

        // Header row for TABLIST_HEADERS
        strcat(list,
            "{a9c4e4}Plate\tModel\n"
        );

        new vehid, model, ca, cb;
        new plate[32];

        for (new i = 0; i < rows; i++)
        {
            cache_get_value_name_int(i, "vehicle_sqlid", vehid);
            cache_get_value_name_int(i, "vehicle_modelid", model);
            cache_get_value_name_int(i, "vehicle_color_a", ca);
            cache_get_value_name_int(i, "vehicle_color_b", cb);
            cache_get_value_name(i, "vehicle_license", plate);

            MDCSession[playerid][MDC_VehicleIDs][i] = vehid;

            // Plate might be empty for some faction/government vehicles, so make it readable.
            if (!strlen(plate))
                format(plate, sizeof plate, "N/A");

            format(list, sizeof list, "%s%s\t%s\n",
                list,
                plate,
                ReturnVehicleModelName(model)
            );
        }

        // For now: any selection just returns to dashboard.
        // (Next section can add a vehicle detail view using MDCSession[playerid][MDC_VehicleIDs][listitem])
        inline DlgVehicles(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused dialogid, inputtext

            if (!response)
            {
                MDC_ShowDataDashboard(pid);
                return 1;
            }

            if (listitem < MDCSession[pid][MDC_VehicleCount])
            {
                new veh_sqlid = MDCSession[pid][MDC_VehicleIDs][listitem];

                new vehIndex = -1;
                for (new i = 0; i < sizeof(Vehicle); i++)
                {
                    if (Vehicle[i][E_VEHICLE_SQLID] == veh_sqlid)
                    {
                        vehIndex = i;
                        break;
                    }
                }

                if (vehIndex == -1)
                {
                    SendServerMessage(pid, COLOR_ERROR, "MDC", "A3A3A3",
                        "Vehicle not currently loaded.");
                    return 1;
                }

                new owner[64] = "Unknown";

                // Same owner logic used in plate search
                switch (Vehicle[vehIndex][E_VEHICLE_TYPE])
                {
                    case -1, 0: format(owner, sizeof owner, "Admin");
                    case 1: format(owner, sizeof owner, "Rental");
                    case 2: format(owner, sizeof owner, "DMV");

                    case E_VEHICLE_TYPE_JOB:
                    {
                        switch (Vehicle[vehIndex][E_VEHICLE_JOBID])
                        {
                            case 1: format(owner, sizeof owner, "Ocean Docks");
                            case 2: format(owner, sizeof owner, "Sanitary Andreas");
                            default: format(owner, sizeof owner, "Job Vehicle");
                        }
                    }

                    case E_VEHICLE_TYPE_FACTION:
                    {
                        new fenum = Faction_GetEnumID(Vehicle[vehIndex][E_VEHICLE_OWNER]);
                        if (fenum != INVALID_FACTION_ID)
                            format(owner, sizeof owner, "%s", Faction[fenum][E_FACTION_NAME]);
                    }

                    case E_VEHICLE_TYPE_PLAYER:
                    {
                        MDC_LoadPlatePlayerOwner(pid, vehIndex);
                        return 1;
                    }
                }

                MDC_ShowPlateResult(pid, vehIndex, owner, true);
            }

            return 1;
        }

        Dialog_ShowCallback(
            playerid,
            using inline DlgVehicles,
            DIALOG_STYLE_TABLIST_HEADERS,
            "Vehicular Information",
            list,
            "Select",
            "Back"
        );
        return 1;
    }

    MySQL_TQueryInline(mysql, using inline OnVehiclesLoaded, query, "");
    return 1;
}

// Asks for a licence plate to search.
static MDC_ShowPlateSearch(playerid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    inline DlgPlateSearch(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, listitem

        if (!response)
        {
            PlayerPlaySound(pid, MDC_ERROR, x, y, z);
            MDC_ShowMainMenu(pid);

            return 1;
        }

        strtrim(inputtext);

        if (strlen(inputtext) < 3)
        {
            SendClientMessage(pid, COLOR_ERROR, "Plate too short.");
            PlayerPlaySound(pid, MDC_ERROR, x, y, z);
            MDC_ShowPlateSearch(pid);
            return 1;
        }

        MDC_LoadPlate(pid, inputtext);
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPlateSearch,
        DIALOG_STYLE_INPUT,
        "MDC - Plate Search",
        "Enter the full vehicle plate:",
        "Search",
        "Back"
    );
    return 1;
}

// Looks up a vehicle by plate.
static MDC_LoadPlate(playerid, const plate[])
{
    new vehIndex = -1;
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    for (new i = 0; i < sizeof(Vehicle); i++)
    {
        if (Vehicle[i][E_VEHICLE_SQLID] == -1)
            continue;

        if (!strcmp(Vehicle[i][E_VEHICLE_LICENSE], plate, true))
        {
            vehIndex = i;
            break;
        }
    }

    if (vehIndex == -1)
    {
        SendServerMessage(playerid, COLOR_ERROR, "MDC", "A3A3A3",
            "No vehicle found for that plate.");
        MDC_ShowPlateSearch(playerid);
        return 1;
    }

    new owner[64] = "Unknown";
    switch (Vehicle[vehIndex][E_VEHICLE_TYPE])
    {
        case -1, 0:
            format(owner, sizeof owner, "Admin");

        case 1:
            format(owner, sizeof owner, "Rental");

        case 2:
            format(owner, sizeof owner, "DMV");

        case E_VEHICLE_TYPE_JOB:
        {
            switch (Vehicle[vehIndex][E_VEHICLE_JOBID])
            {
                case 1: format(owner, sizeof owner, "Ocean Docks");
                case 2: format(owner, sizeof owner, "Sanitary Andreas");
                default: format(owner, sizeof owner, "Job Vehicle");
            }
        }

        case E_VEHICLE_TYPE_FACTION:
        {
            new fenum = Faction_GetEnumID(Vehicle[vehIndex][E_VEHICLE_OWNER]);
            if (fenum != INVALID_FACTION_ID)
                format(owner, sizeof owner, "%s", Faction[fenum][E_FACTION_NAME]);
            else
                format(owner, sizeof owner, "Unknown Faction");
        }

        case E_VEHICLE_TYPE_PLAYER:
        {
            MDC_LoadPlatePlayerOwner(playerid, vehIndex);
            return 1; // async path
        }
    }

    MDC_ShowPlateResult(playerid, vehIndex, owner, false);
    return 1;
}

// Looks up the character who owns a vehicle.
static MDC_LoadPlatePlayerOwner(playerid, vehIndex)
{
    new query[128];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    mysql_format(
        mysql,
        query,
        sizeof(query),
        "SELECT player_name FROM characters WHERE player_id = %d LIMIT 1",
        Vehicle[vehIndex][E_VEHICLE_OWNER]
    );

    inline OnOwnerLoaded()
    {
        new owner[64] = "Unknown Player";

        if (cache_num_rows())
        {
            cache_get_value_name(0, "player_name", owner);
            strreplace(owner, "_", " ");
        }
        MDC_ShowPlateResult(playerid, vehIndex, owner, true);
        return 1;
    }

    MySQL_TQueryInline(mysql, using inline OnOwnerLoaded, query, "");
    return 1;
}

// Shows the result of a plate search (owner, fines, status).
static MDC_ShowPlateResult(playerid, vehIndex, const owner[], bool:fromNameSearch = false)
{
    new body[768];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new fines = VehicleOutstandingFines[vehIndex];

    format(body, sizeof body,
        "{a9c4e4}___________________________________________\n" \
        "{a9c4e4}DETAILS FOR:{FFFFFF} %s\n" \
        "{a9c4e4}___________________________________________\n\n" \
        "{a9c4e4}Model:{FFFFFF}\t%s\n" \
        "{a9c4e4}Plate:{FFFFFF}\t%s\n" \
        "{a9c4e4}Color:{FFFFFF}\t{%s}%s {a9c4e4}/ {%s}%s\n\n" \
        "{a9c4e4}Outstanding Vehicle Fines:{FFFFFF}\t$%s\n\n" \
        "{a9c4e4}Registered Owner:{FFFFFF}\n" \
        "%s\n" \
        "{a9c4e4}___________________________________________",
        Vehicle[vehIndex][E_VEHICLE_LICENSE],
        ReturnVehicleModelName(Vehicle[vehIndex][E_VEHICLE_MODELID]),
        Vehicle[vehIndex][E_VEHICLE_LICENSE],
        VehicleColoursTableRGBA[Vehicle[vehIndex][E_VEHICLE_COLOR_A]],
        vehicleColorNames[Vehicle[vehIndex][E_VEHICLE_COLOR_A]],
        VehicleColoursTableRGBA[Vehicle[vehIndex][E_VEHICLE_COLOR_B]],
        vehicleColorNames[Vehicle[vehIndex][E_VEHICLE_COLOR_B]],
        IntegerWithDelimiter(fines),
        owner
    );

    inline DlgPlateResult(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, listitem, inputtext

        if (response) // View Tickets
        {
            MDC_ShowPlateTickets(pid, Vehicle[vehIndex][E_VEHICLE_SQLID]);
        }
        else
        {
            if (fromNameSearch)
                MDC_LoadVehicles(pid);
            else
            {
                MDC_ShowMainMenu(pid);
            }
        }
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPlateResult,
        DIALOG_STYLE_MSGBOX,
        "Plate Search Result",
        body,
        "View Tickets",
        "Back"
    );

    return 1;
}

// Shows the searched person's criminal record list.
MDC_ShowCrimes(playerid)
{
	new query[512], player_name[MAX_PLAYER_NAME], player_name_display[MAX_PLAYER_NAME];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

	format(player_name, sizeof(player_name), "%s", MDCSession[playerid][MDC_TargetName]);
	mysql_format(mysql, query, sizeof(query), "SELECT `record_id`, DATE(FROM_UNIXTIME(record_date)) AS 'date', `record_holder`, `record_desc`, `record_crime_type`, `record_status` FROM `criminalrecords` WHERE `record_holder` = '%e' ORDER BY `record_status`, `record_date` DESC LIMIT 100", MDCSession[playerid][MDC_TargetName]);


	inline Records_OnList() 
	{
		if (!cache_num_rows())
		{
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("No criminal record was found on file for \"%s\"", player_name)) ;
		}

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "Date\tCrime");

		MDCSession[playerid][MDC_CrimeCount] = 0;

        new recordid, record_desc[128], crime_type, status, date[16];
		for (new i = 0, r = cache_num_rows(); i < r; ++i)
		{
			cache_get_value_name(i, "date", date);
			cache_get_value_name_int(i, "record_crime_type", crime_type);
			cache_get_value_name_int(i, "record_id", recordid);
			cache_get_value_name_int(i, "record_status", status);
			cache_get_value_name(i, "record_desc", record_desc);
			
			new idx = MDCSession[playerid][MDC_CrimeCount];
            MDCSession[playerid][MDC_CrimeIDs][idx] = recordid;
            MDCSession[playerid][MDC_CrimeCount]++;

			new crime = -1;
			if (crime_type != -1) crime = GetCrimeByTypeEnum(crime_type);

			if (status == 2) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n%s\t{9E9E9E}%s", CrimeDlgStr, date, record_desc);
			else if (crime != -1) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n%s\t%s", CrimeDlgStr, date, GetCrimeFullName(crime, true, true));
			else format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n%s\t%s", CrimeDlgStr, date, record_desc);
		}

		cache_get_value_name(0, "record_holder", player_name_display);
		strreplace(player_name_display, "_", " ");

		inline DlgRecordList(pid, dialogid, response, listitem, string:inputtext[]) 
    	{
			#pragma unused pid, dialogid, inputtext, listitem
			
			if (!response)
            {
                PlayerPlaySound(pid, MDC_ERROR, x, y, z);
                MDC_ShowDataDashboard(pid);
                return 1;
            }

            if (listitem < MDCSession[pid][MDC_CrimeCount])
            {
                recordid = MDCSession[pid][MDC_CrimeIDs][listitem];
                MDC_ShowCrime(pid, recordid);
            }
            return 1;
		}

		Dialog_ShowCallback(playerid, using inline DlgRecordList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Criminal Record of %s", player_name_display), CrimeDlgStr, "View", "Back");
	}

	MySQL_TQueryInline(mysql, using inline Records_OnList, query, "");
	return 1;
}

// Shows one criminal record entry.
MDC_ShowCrime(playerid, recordid)
{
	new query[256];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

	mysql_format(mysql, query, sizeof(query), "SELECT *, FROM_UNIXTIME(record_date) AS 'date' FROM `criminalrecords` WHERE `record_id` = %d", recordid);

	inline Record_OnView() 
	{
		new record_desc[128], crime_type, status, date[32], giver_name[32], revoker_name[32], giver_rank[32], player_name[MAX_PLAYER_NAME], player_display_name[MAX_PLAYER_NAME];
		if (!cache_num_rows())
		{
			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid ticket ID." ) ;
		}

		cache_get_value_name(0, "date", date);
		cache_get_value_name_int(0, "record_crime_type", crime_type);
		cache_get_value_name_int(0, "record_status", status);
		cache_get_value_name(0, "record_desc", record_desc);
		cache_get_value_name(0, "record_officer", giver_name);
		cache_get_value_name(0, "record_officer_rank", giver_rank);
		cache_get_value_name(0, "record_holder", player_name);
		cache_get_value_name(0, "record_holder", player_display_name);
		cache_get_value_name(0, "record_revoker", revoker_name);

		strreplace(giver_name, "_", " ");
		strreplace(player_display_name, "_", " ");
		strreplace(revoker_name, "_", " ");

		new crime = -1;
        if (crime_type != -1)
            crime = GetCrimeByTypeEnum(crime_type);

		if (strlen(giver_rank)) format(CrimeDlgStr, sizeof(CrimeDlgStr), "{FFFFFF}%s was charged by {ADBEE6}%s %s {FFFFFF}for:", player_display_name, giver_rank, giver_name);
		else format(CrimeDlgStr, sizeof(CrimeDlgStr), "{FFFFFF}%s was charged by {ADBEE6} %s {FFFFFF}for:", player_display_name, giver_name);
	

		if (crime != -1)
		{
			format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{ADBEE6}- %s", CrimeDlgStr, GetCrimeFullName(crime, true, true));
		}
		else
		{
			format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{ADBEE6}- {FFFFFF}%s", CrimeDlgStr, record_desc);
		}


		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{0099FF}Record Number: {ADBEE6}#%05d", CrimeDlgStr, recordid);
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Record Date: {ADBEE6}%s", CrimeDlgStr, date);
		if (crime != -1) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Record Type: {ADBEE6}%s", CrimeDlgStr, GetCrimeClass(crime));
		
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Issued By (Name): {ADBEE6}%s", CrimeDlgStr, giver_name);
		if (strlen(giver_rank)) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Issued By (Title): {ADBEE6}%s", CrimeDlgStr, giver_rank);

		if (status == 2) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}This charge was revoked by {ADBEE6}%s.", CrimeDlgStr, revoker_name);
		
		inline DlgRecordView(pid, dialogid, response, listitem, string:inputtext[]) 
    	{
			#pragma unused pid, dialogid, inputtext, listitem

			if (response && status != 2)
			{
				// Revoke the charge
				MDC_RevokeCrime(pid, recordid);
			}
			else
			{
				// go back
				MDC_ShowCrimes(pid);
			}
		}

		if (status != 2) Dialog_ShowCallback ( playerid, using inline DlgRecordView, DIALOG_STYLE_MSGBOX, sprintf("Viewing Charge #%05d", recordid), CrimeDlgStr, "Revoke", "Back" );
		else Dialog_ShowCallback ( playerid, using inline DlgRecordView, DIALOG_STYLE_MSGBOX, sprintf("Viewing Charge #%05d", recordid), CrimeDlgStr, "Back", "" );
	}

	MySQL_TQueryInline(mysql, using inline Record_OnView, query, "");
	return 1;
}

// Revokes a criminal record entry (MDC).
MDC_RevokeCrime(playerid, recordid)
{
	if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerGovJudge(playerid, true) && !IsPlayerGovCop(playerid, true)) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be on duty as law enforcement to do this.");
	else if (Character[playerid][E_CHARACTER_FACTIONTIER] >= 3) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Ask a supervisor (Tier 2) to revoke the charge instead.");

	new query[256];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

	mysql_format(mysql, query, sizeof(query), "SELECT *, FROM_UNIXTIME(record_date) AS 'date' FROM `criminalrecords` WHERE `record_id` = %d", recordid);

	inline Crime_OnRevokeGet() 
	{
		if (!cache_num_rows())
		{
			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid criminal charge ID." ) ;
		}

		new status, crime_desc[128], crime_type, date[32], giver_name[32], giver_rank[32], player_name[MAX_PLAYER_NAME], player_display_name[MAX_PLAYER_NAME];
		cache_get_value_name(0, "date", date);
		cache_get_value_name_int(0, "record_crime_type", crime_type);
		cache_get_value_name_int(0, "record_status", status);
		cache_get_value_name(0, "record_desc", crime_desc);
		cache_get_value_name(0, "record_officer", giver_name);
		cache_get_value_name(0, "record_officer_rank", giver_rank);
		cache_get_value_name(0, "record_holder", player_name);
		cache_get_value_name(0, "record_holder", player_display_name);

		if (status) return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "This charge has already been revoked." );
		strreplace(giver_name, "_", " ");
		strreplace(player_display_name, "_", " ");

		new crime = -1;
		if (crime_type != -1) crime = GetCrimeByTypeEnum(crime_type);
		
		if (crime != -1) format(CrimeDlgStr, sizeof(CrimeDlgStr), "{FFFFFF}You are about to revoke %s{FFFFFF} charge against {ADBEE6}%s{FFFFFF} for:", GetCrimeClass(crime, true, true), player_display_name);
		else format(CrimeDlgStr, sizeof(CrimeDlgStr), "{FFFFFF}You are about to revoke a charge against {ADBEE6}%s{FFFFFF} for:", player_display_name);

		if (crime != -1) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{ADBEE6}- {FFFFFF}%s", CrimeDlgStr, GetCrimeFullName(crime, true, true));
		else format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{ADBEE6}- {FFFFFF}%s", CrimeDlgStr, crime_desc);	

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{0099FF}Record Number: {ADBEE6}#%05d", CrimeDlgStr, recordid);
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Record Date: {ADBEE6}%s", CrimeDlgStr, date);
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Issued By (Name): {ADBEE6}%s", CrimeDlgStr, giver_name);
		if (strlen(giver_rank)) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Issued By (Title): {ADBEE6}%s", CrimeDlgStr, giver_rank);

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}Press {AA3333}OK{FFFFFF} to revoke the charge.", CrimeDlgStr);
		
		inline DlgCrimeRevoke(pid, dialogid, response, listitem, string:inputtext[]) 
    	{
			#pragma unused pid, dialogid, inputtext, listitem

			if (response)
			{
				// Do the revokation
                PlayerPlaySound(pid, MDC_SELECT, x, y, z);
				mysql_format(mysql, query, sizeof(query), "UPDATE `criminalrecords` SET `record_status` = 2, `record_revoker` = '%e' WHERE `record_id` = %d", Character[pid][E_CHARACTER_NAME], recordid);

				inline Crime_OnRevoke() 
				{
					if (!cache_affected_rows()) return SendServerMessage(pid, COLOR_ERROR, "Error", "A3A3A3", "There was an error revoking this charge (it might already be revoked)");

					new factionid = Character [ pid ] [ E_CHARACTER_FACTIONID ] ;
					new faction_enum_id = Faction_GetEnumID( factionid ); 

					if (crime != -1)
					{
						Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s has revoked Charge #%05d (%s) given to %s by %s. }", 
							Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], pid, ReturnRPName ( pid ), recordid, GetCrimeCode(crime), player_display_name, giver_name
						), faction_enum_id, false ) ;
					}
					else
					{
						Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s has revoked Charge #%05d given to %s by %s. }", 
							Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], pid, ReturnRPName ( pid ), recordid, player_display_name, giver_name
						), faction_enum_id, false ) ;
					}
				}

				MySQL_TQueryInline(mysql, using inline Crime_OnRevoke, query, "");
			}
			else
			{
				// go back
                PlayerPlaySound(pid, MDC_ERROR, x, y, z);
				MDC_ShowCrime(pid, recordid);
			}
		}

		Dialog_ShowCallback ( playerid, using inline DlgCrimeRevoke, DIALOG_STYLE_MSGBOX, sprintf("Revoking Charge #%05d", recordid), CrimeDlgStr, "OK", "Back" );
	}

	MySQL_TQueryInline(mysql, using inline Crime_OnRevokeGet, query, "");
	return 1;	
}

// Shows the searched person's tickets.
MDC_ShowTickets(playerid)
{
	new query[512], player_name[MAX_PLAYER_NAME], player_name_display[MAX_PLAYER_NAME];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

	format(player_name, sizeof(player_name), "%s", MDCSession[playerid][MDC_TargetName]);
	mysql_format(mysql, query, sizeof(query), "SELECT `fine_id`, DATE(fine_date) AS 'date', UNIX_TIMESTAMP(`fine_date`) AS `timestamp`, `fine_player_name`, `fine_amount`, `fine_reason`, `fine_status` FROM `criminalfines` WHERE `fine_player_name` = '%e' ORDER BY `fine_status`, `fine_date` DESC LIMIT 50", MDCSession[playerid][MDC_TargetName]);

	new days = 259200; // 3 days to seconds // if you change this, change it in arrest/searchdata too

	inline Tickets_OnList() 
	{
		if (!cache_num_rows())
		{
			return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", sprintf("No tickets were found on file for \"%s\"", player_name)) ;
		}

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "Date\tCost\tStatus\tTicket");
		new now = gettime(); // current time

		new ticketid, ticket_reason[128], ticket_amount, status, date[16], timestamp;
        MDCSession[playerid][MDC_TicketCount] = 0;
		for (new i = 0, r = cache_num_rows(); i < r; ++i)
		{
			cache_get_value_name(i, "date", date);
			cache_get_value_name_int(i, "fine_amount", ticket_amount);
			cache_get_value_name_int(i, "fine_id", ticketid);
			cache_get_value_name_int(i, "fine_status", status);
			cache_get_value_name_int(i, "timestamp", timestamp);
			cache_get_value_name(i, "fine_reason", ticket_reason);
			new due = days - (now - timestamp);

			new fee = (due > 0) ? 0 : ticket_amount * 2;
			new actual_cost = ticket_amount + fee;
			
			new idx = MDCSession[playerid][MDC_TicketCount];
            MDCSession[playerid][MDC_TicketIDs][idx] = ticketid;
            MDCSession[playerid][MDC_TicketCount]++;

			//cache_get_field_content(i, "fine_giver_name", ticket_giver_name);
			//cache_get_field_content(i, "fine_giver_rank", ticket_giver_name);
			//ticket_giver = cache_get_field_content_int(i, "fine_giver_id");
			//crime_type = cache_get_field_content_int(i, "fine_reason_id");

			if (status == 2) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n%s\t$%s\t{BDBDBD}%s\t%s", CrimeDlgStr, date, IntegerWithDelimiter(actual_cost), "Revoked", ticket_reason);
			else if (status == 1) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n%s\t$%s\t{C5E1A5}%s\t%s", CrimeDlgStr, date, IntegerWithDelimiter(actual_cost), "Paid", ticket_reason);
			else if (due > 0) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n%s\t$%s\t{FFD54F}%s\t%s", CrimeDlgStr, date, IntegerWithDelimiter(actual_cost), "Unpaid", ticket_reason);
			else format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n%s\t$%s\t{EF5350}%s\t%s", CrimeDlgStr, date, IntegerWithDelimiter(actual_cost), "Expired", ticket_reason);
		}

		cache_get_value_name(0, "fine_player_name", player_name_display);
		strreplace(player_name_display, "_", " ");

		inline DlgTicketList(pid, dialogid, response, listitem, string:inputtext[]) 
        {
            #pragma unused dialogid, inputtext

            if (!response)
            {
                PlayerPlaySound(pid, MDC_ERROR, x, y, z);
                MDC_ShowDataDashboard(pid);
                return 1;
            }

            if (listitem < MDCSession[pid][MDC_TicketCount])
            {
                ticketid = MDCSession[pid][MDC_TicketIDs][listitem];
                MDC_ShowTicket(pid, ticketid);
            }
            return 1;
        }

		Dialog_ShowCallback(playerid, using inline DlgTicketList, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Tickets given to %s", player_name_display), CrimeDlgStr, "View", "Back");
	}

	MySQL_TQueryInline(mysql, using inline Tickets_OnList, query, "");
	return 1;
}

// Shows one ticket.
MDC_ShowTicket(playerid, ticketid, bool:viewing=false)
{
	new query[512];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

	new days = 259200; // 3 days to seconds // if you change this, change it in arrest/searchdata too

	mysql_format(mysql, query, sizeof(query), "SELECT *, UNIX_TIMESTAMP(`fine_date`) AS `timestamp`, DATE_ADD(`fine_date`, INTERVAL %d second) AS `due_by` FROM `criminalfines` WHERE `fine_id` = %d", days, ticketid);

	inline Ticket_OnView() 
	{
		if (!cache_num_rows())
		{
			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid ticket ID." ) ;
		}

		new ticket_reason[128], ticket_amount, status, timestamp, date[32], ticket_due[32], giver_name[32], revoker_name[32], giver_rank[32], player_name[MAX_PLAYER_NAME], player_display_name[MAX_PLAYER_NAME];
		cache_get_value_name(0, "fine_date", date);
		cache_get_value_name_int(0, "fine_amount", ticket_amount);
		cache_get_value_name_int(0, "fine_status", status);
		cache_get_value_name_int(0, "timestamp", timestamp);
		cache_get_value_name(0, "fine_reason", ticket_reason);
		cache_get_value_name(0, "fine_giver_name", giver_name);
		cache_get_value_name(0, "fine_giver_rank", giver_rank);
		cache_get_value_name(0, "fine_player_name", player_name);
		cache_get_value_name(0, "fine_player_name", player_display_name);
		cache_get_value_name(0, "fine_revoker", revoker_name);
		cache_get_value_name(0, "due_by", ticket_due);

		strreplace(giver_name, "_", " ");
		strreplace(player_display_name, "_", " ");
		strreplace(revoker_name, "_", " ");

		new now = gettime(); // current time
		new due = days - (now - timestamp);
		new fee = (due > 0) ? 0 : ticket_amount * 2;
		new actual_cost = ticket_amount + fee;

		if (viewing) format(CrimeDlgStr, sizeof(CrimeDlgStr), "{FFFFFF}%s was given a ticket by {ADBEE6}%s %s {FFFFFF}for:", player_display_name, giver_rank, giver_name);
		else format(CrimeDlgStr, sizeof(CrimeDlgStr), "{FFFFFF}You were given a ticket by {ADBEE6}%s %s {FFFFFF}for:", giver_rank, giver_name);
		
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{ADBEE6}- {E6EE9C}%s", CrimeDlgStr, ticket_reason);

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{0099FF}Ticket Number: {ADBEE6}#%03d", CrimeDlgStr, ticketid);
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Ticket Date: {ADBEE6}%s", CrimeDlgStr, date);
		if (due > 0) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Ticket Cost: {ADBEE6}$%s", CrimeDlgStr, IntegerWithDelimiter(actual_cost));
		else format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Ticket Cost: {ADBEE6}$%s (Ticket: $%s, Late Fee: $%s)", CrimeDlgStr, IntegerWithDelimiter(actual_cost), IntegerWithDelimiter(ticket_amount), IntegerWithDelimiter(fee));
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Payment Due By: {ADBEE6}%s", CrimeDlgStr, ticket_due);
		
		if (viewing)
		{
			if (status == 2) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}This ticket was revoked by {ADBEE6}%s.", CrimeDlgStr, revoker_name);
			else if (status == 1) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}They have already paid this ticket.", CrimeDlgStr);
			else if (due > 3600) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}They have %d hours left to pay this ticket.", CrimeDlgStr, due / 3600);
			else if (due > 60) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFF00}They have %d minutes left to pay this ticket.", CrimeDlgStr, due / 60);
			else if (due > 0) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFF00}They have %d seconds left to pay this ticket.", CrimeDlgStr, due);
			else 
			{
				format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFF00}This ticket was not paid on time, they can still pay it but will be charged extra.", CrimeDlgStr);
				format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{FF0000}Note that they can be arrested instead for failing to pay the ticket on time.", CrimeDlgStr);
				format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}Any unpaid tickets will be automatically cancelled if they are arrested.", CrimeDlgStr);
			}
		}
		else
		{
			if (status == 2) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}This ticket was revoked by {ADBEE6}%s.", CrimeDlgStr, revoker_name);
			else if (status == 1) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}You have already paid this ticket.", CrimeDlgStr);
			else if (due > 3600) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}You have %d hours left to pay this ticket or you may be arrested.", CrimeDlgStr, due / 3600);
			else if (due > 60) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFF00}You have %d minutes left to pay this ticket or you may be arrested.", CrimeDlgStr, due / 60);
			else if (due > 0) format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFF00}You have %d seconds left to pay this ticket or you may be arrested.", CrimeDlgStr, due);
			else 
			{
				format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFF00}This ticket was not paid on time, you can still pay it but you will be charged extra.", CrimeDlgStr);
				format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{FF0000}Note that you can be arrested if the police catch you with an unpaid ticket.", CrimeDlgStr);
				format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}Any unpaid tickets will be automatically cancelled if you are arrested.", CrimeDlgStr);
			}
		}
		
		inline DlgTicketView(pid, dialogid, response, listitem, string:inputtext[]) 
    	{
			#pragma unused pid, dialogid, inputtext, listitem

			if (response && !status)
			{
				// Revoke or pay the ticket
				MDC_RevokeTicket(pid, ticketid);
			}
			else
			{
				// go back
                PlayerPlaySound(pid, MDC_ERROR, x, y, z);
				MDC_ShowTickets(pid);
			}
		}
		Dialog_ShowCallback ( playerid, using inline DlgTicketView, DIALOG_STYLE_MSGBOX, sprintf("Viewing Ticket #%03d", ticketid), CrimeDlgStr, "Revoke", "Back" );
	}

	MySQL_TQueryInline(mysql, using inline Ticket_OnView, query, "");
	return 1;
}

// Revokes a ticket (MDC).
MDC_RevokeTicket(playerid, ticketid)
{
	if (!IsPlayerInLEAFaction(playerid, true) && !IsPlayerGovRecords(playerid, true)) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be on duty as law enforcement to do this.");
	else if (Character[playerid][E_CHARACTER_FACTIONTIER] >= 3) return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Ask a supervisor (Tier 2) to revoke the ticket instead.");

	new query[512];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

	mysql_format(mysql, query, sizeof(query), "SELECT * FROM `criminalfines` WHERE `fine_id` = %d", ticketid);

	inline Ticket_OnRevokeGet() 
	{
		if (!cache_num_rows())
		{
			return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid ticket ID." ) ;
		}

		new status, ticket_reason[128], ticket_amount, date[32], giver_name[32], giver_rank[32], player_name[MAX_PLAYER_NAME], player_display_name[MAX_PLAYER_NAME];
		cache_get_value_name(0, "fine_date", date);
		cache_get_value_name_int(0, "fine_amount", ticket_amount);
		cache_get_value_name_int(0, "fine_status", status);
		cache_get_value_name(0, "fine_reason", ticket_reason);
		cache_get_value_name(0, "fine_giver_name", giver_name);
		cache_get_value_name(0, "fine_giver_rank", giver_rank);
		cache_get_value_name(0, "fine_player_name", player_name);
		cache_get_value_name(0, "fine_player_name", player_display_name);

		if (status) return SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't revoke this ticket as it has already been paid or revoked." );

		strreplace(giver_name, "_", " ");
		strreplace(player_display_name, "_", " ");

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "{FFFFFF}You are about to revoke a {ADBEE6}$%s{FFFFFF} ticket given to {ADBEE6}%s{FFFFFF} for:", IntegerWithDelimiter(ticket_amount), player_display_name);
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{ADBEE6}- {E6EE9C}%s", CrimeDlgStr, ticket_reason);

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{0099FF}Ticket Number: {ADBEE6}#%03d", CrimeDlgStr, ticketid);
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Ticket Date: {ADBEE6}%s", CrimeDlgStr, date);
		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n{0099FF}Ticket Issued By: {ADBEE6}%s %s", CrimeDlgStr, giver_rank, giver_name);

		format(CrimeDlgStr, sizeof(CrimeDlgStr), "%s\n\n{FFFFFF}Press {AA3333}OK{FFFFFF} to revoke the ticket.", CrimeDlgStr);
		
		inline DlgTicketRevoke(pid, dialogid, response, listitem, string:inputtext[]) 
    	{
			#pragma unused pid, dialogid, inputtext, listitem

			if (response)
			{
				// Do the revokation
				mysql_format(mysql, query, sizeof(query), "UPDATE `criminalfines` SET `fine_status` = 2, `fine_revoker` = '%e' WHERE `fine_id` = %d", Character[pid][E_CHARACTER_NAME], ticketid);

				inline Ticket_OnRevoke() 
				{
					if (!cache_affected_rows()) return SendServerMessage(pid, COLOR_ERROR, "Error", "A3A3A3", "There was an error revoking this ticket (it might already be paid)");

					new factionid = Character [ pid ] [ E_CHARACTER_FACTIONID ] ;
					new faction_enum_id = Faction_GetEnumID( factionid ); 

					Faction_SendMessage(factionid, sprintf("{ [%s] (%d) %s has revoked Ticket #%03d given to %s by %s. }", 
						Faction [ faction_enum_id ] [ E_FACTION_ABBREV ], pid, ReturnRPName ( pid ), ticketid, player_display_name, giver_name
					), faction_enum_id, false ) ;
				}

				MySQL_TQueryInline(mysql, using inline Ticket_OnRevoke, query, "");
			}
			else
			{
				// go back
                PlayerPlaySound(pid, MDC_ERROR, x, y, z);
				MDC_ShowTickets(pid);
			}
		}

		Dialog_ShowCallback ( playerid, using inline DlgTicketRevoke, DIALOG_STYLE_MSGBOX, sprintf("Revoking Ticket #%03d", ticketid), CrimeDlgStr, "OK", "Back" );
	}

	MySQL_TQueryInline(mysql, using inline Ticket_OnRevokeGet, query, "");
	return 1;	
}

// Shows the tickets on a vehicle.
static MDC_ShowPlateTickets(playerid, veh_sqlid)
{
    new list[2048];
    list[0] = EOS;

    strcat(list, "ID\tAmount\n");

    MDCSession[playerid][MDC_VehicleTicketCount] = 0;

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_vehicle_sqlid] != veh_sqlid)
            continue;

        // 🚫 Skip paid tickets
        if (VehicleTicketData[i][vt_status] == TICKET_STATUS_PAID)
            continue;

        new idx = MDCSession[playerid][MDC_VehicleTicketCount];
        if (idx >= MDC_MAX_TICKETS)
            break;

        MDCSession[playerid][MDC_VehicleTicketIDs][idx] =
            VehicleTicketData[i][vt_id];

        MDCSession[playerid][MDC_VehicleTicketCount]++;

        format(list, sizeof list,
            "%s#%04d\t$%s\n",
            list,
            VehicleTicketData[i][vt_id],
            IntegerWithDelimiter(VehicleTicketData[i][vt_amount])
        );
    }

    if (!MDCSession[playerid][MDC_VehicleTicketCount])
    {
        SendClientMessage(playerid, COLOR_INFO, "No vehicle tickets found.");
        return 1; // JUST RETURN. Do not redirect anywhere.
    }

    inline DlgPlateTicketList(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, inputtext

        if (!response)
        {
            return 1; // just close
        }

        if (listitem < MDCSession[pid][MDC_VehicleTicketCount])
        {
            new ticketid =
                MDCSession[pid][MDC_VehicleTicketIDs][listitem];

            MDC_ShowVehicleTicketDetail(pid, ticketid);
        }

        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPlateTicketList,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Vehicle Tickets",
        list,
        "View",
        "Back"
    );

    return 1;
}

// Loads the active BOLOs (be-on-the-lookout notices).
static MDC_LoadBolos(playerid)
{
    new query[1024];

    mysql_format(mysql, query, sizeof(query),
        "SELECT bolo_id, bolo_type, title, risk_level, created_at \
        FROM bolos \
        WHERE status = 'active' \
        ORDER BY created_at DESC \
        LIMIT 50"
    );

    inline OnBolosLoaded()
    {
        if (!MDCSession[playerid][MDC_Active])
            return 1;
        if (!cache_num_rows())
        {
            SendServerMessage(playerid, COLOR_INFO, "MDC", "DEDEDE",
                "No active BOLOs found.");
            MDC_ShowMainMenu(playerid);
            return 1;
        }

        new list[2048];
        list[0] = EOS;

        strcat(list, "ID\tType\tRisk\tTitle\n");

        MDCSession[playerid][MDC_BoloCount] = 0;

        new id, type[16], title[64], risk[16], created[32];

        for (new i = 0; i < cache_num_rows(); i++)
        {
            cache_get_value_name_int(i, "bolo_id", id);
            cache_get_value_name(i, "bolo_type", type);
            cache_get_value_name(i, "title", title);
            cache_get_value_name(i, "risk_level", risk);
            cache_get_value_name(i, "created_at", created);

            new idx = MDCSession[playerid][MDC_BoloCount];
            MDCSession[playerid][MDC_BoloIDs][idx] = id;
            MDCSession[playerid][MDC_BoloCount]++;

            format(list, sizeof list,
                "%s#%d\t%s\t%s\t%s\n",
                list,
                id,
                type,
                risk,
                title
            );
        }

        inline DlgBoloList(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused dialogid, inputtext

            if (!response)
            {
                MDC_ShowMainMenu(pid);
                return 1;
            }

            if (listitem < MDCSession[pid][MDC_BoloCount])
            {
                new boloid = MDCSession[pid][MDC_BoloIDs][listitem];
                MDC_ViewBolo(pid, boloid);
            }

            return 1;
        }

        Dialog_ShowCallback(
            playerid,
            using inline DlgBoloList,
            DIALOG_STYLE_TABLIST_HEADERS,
            "Active BOLOs",
            list,
            "View",
            "Back"
        );

        return 1;
    }

    MySQL_TQueryInline(mysql, using inline OnBolosLoaded, query, "");
    return 1;
}

// Shows one BOLO in detail.
static MDC_ViewBolo(playerid, boloid)
{
    new query[512];

    mysql_format(mysql, query, sizeof(query),
        "SELECT b.*, c.player_name, f.faction_name \
         FROM bolos b \
         LEFT JOIN characters c ON c.player_id = b.issued_by_character \
         LEFT JOIN factions f ON f.faction_id = b.faction_id \
         WHERE b.bolo_id = %d LIMIT 1",
        boloid
    );

    inline OnBoloView()
    {
        if (!cache_num_rows())
        {
            SendServerMessage(playerid, COLOR_ERROR, "MDC", "A3A3A3",
                "BOLO not found.");
            return 1;
        }

        new type[32], title[128], desc_raw[512], risk[16], created[32];
        new issuer[32], faction[32];

        cache_get_value_name(0, "bolo_type", type);
        cache_get_value_name(0, "title", title);
        new desc_temp[512];
        cache_get_value_name(0, "description", desc_temp);
        ConvertNewlines(desc_raw, sizeof(desc_raw), desc_temp);
        
        cache_get_value_name(0, "risk_level", risk);
        cache_get_value_name(0, "created_at", created);
        if (!cache_get_value_name(0, "player_name", issuer))
            format(issuer, sizeof issuer, "Unknown");

        if (!cache_get_value_name(0, "faction_name", faction))
            format(faction, sizeof faction, "Unknown");

        strreplace(issuer, "_", " ");

        new body[2048];

        // clamp description
        if (strlen(desc_raw) >= sizeof(desc_raw) - 4)
        {
            desc_raw[sizeof(desc_raw) - 4] = EOS;
            strcat(desc_raw, "...");
        }

        format(body, sizeof body,
            "{a9c4e4}--- BOLO NOTICE ---\n\n" \
            "{a9c4e4}Title:{FFFFFF} %s\n" \
            "{a9c4e4}Type:{FFFFFF} %s\n" \
            "{a9c4e4}Risk:{FFFFFF} %s\n\n" \
            "{a9c4e4}Issued By:{FFFFFF} %s (%s)\n\n" \
            "{a9c4e4}Description:\n{FFFFFF}%s",
            title,
            type,
            risk,
            issuer,
            faction,
            desc_raw
        );

        inline DlgBoloView(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused dialogid, response, listitem, inputtext
            MDC_LoadBolos(pid);
            return 1;
        }

        Dialog_ShowCallback(
            playerid,
            using inline DlgBoloView,
            DIALOG_STYLE_MSGBOX,
            "BOLO Details",
            body,
            "Back"
        );

        return 1;
    }

    MySQL_TQueryInline(mysql, using inline OnBoloView, query, "");
    return 1;
}

// Shows the detail of one vehicle ticket.
static MDC_ShowVehicleTicketDetail(playerid, ticketid)
{
    new body[1024];
    new now = gettime();
    new veh_sqlid = 0;

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_id] != ticketid)
            continue;

        veh_sqlid = VehicleTicketData[i][vt_vehicle_sqlid];

        new statusStr[16];

        if (VehicleTicketData[i][vt_status] == TICKET_STATUS_PAID)
            format(statusStr, sizeof statusStr, "Paid");
        else if (VehicleTicketData[i][vt_status] == TICKET_STATUS_VOID)
            format(statusStr, sizeof statusStr, "Revoked");
        else if (VehicleTicketData[i][vt_due_unix] > 0 && now > VehicleTicketData[i][vt_due_unix])
            format(statusStr, sizeof statusStr, "Expired");
        else
            format(statusStr, sizeof statusStr, "Unpaid");

        new issueDate[16], dueDate[16];

        UnixToDateStr(VehicleTicketData[i][vt_date_unix], issueDate, sizeof issueDate);

        if (VehicleTicketData[i][vt_due_unix] > 0)
            UnixToDateStr(VehicleTicketData[i][vt_due_unix], dueDate, sizeof dueDate);
        else
            format(dueDate, sizeof dueDate, "N/A");

        format(body, sizeof body,
            "{a9c4e4}___________________________________________\n" \
            "{a9c4e4}VEHICLE TICKET DETAIL\n" \
            "{a9c4e4}___________________________________________\n\n" \
            "{a9c4e4}Ticket ID:{FFFFFF} #%04d\n" \
            "{a9c4e4}Amount:{FFFFFF} $%s\n" \
            "{a9c4e4}Status:{FFFFFF} %s\n" \
            "{a9c4e4}Issued:{FFFFFF} %s\n" \
            "{a9c4e4}Due:{FFFFFF} %s\n\n" \
            "{a9c4e4}Reason:{FFFFFF}\n%s\n\n" \
            "{a9c4e4}Issued By:{FFFFFF} %s\n" \
            "{a9c4e4}___________________________________________",
            ticketid,
            IntegerWithDelimiter(VehicleTicketData[i][vt_amount]),
            statusStr,
            issueDate,
            dueDate,
            VehicleTicketData[i][vt_reason],
            VehicleTicketData[i][vt_issuer_name]
        );

        break;
    }

    inline DlgVehTicketDetail(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, response, listitem, inputtext

        MDC_ShowPlateTickets(pid, veh_sqlid);
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgVehTicketDetail,
        DIALOG_STYLE_MSGBOX,
        "Vehicle Ticket",
        body,
        "Back"
    );

    return 1;
}

// PARKING ENFORCEMENT

// =======================
// PARKING MANAGEMENT CONSOLE (SEPARATE SYSTEM)
// =======================

// Returns true if the player may use the public works computer (PMC).
static bool:PMC_CanUse(playerid)
{
    return IsPlayerInGovFaction(playerid, true);
}

// /pmc - opens the public works computer.
CMD:pmc(playerid)
{
    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Incapacitated", "A3A3A3",
            "You're currently incapacitated and can't do this.");

    if (!PMC_CanUse(playerid))
        return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3",
            "You must be on duty as Parking Enforcement to use this system.");

    if (!IsPlayerInAnyVehicle(playerid))
        return SendClientMessage(playerid, COLOR_ERROR,
            "You must be in a City Services vehicle to access the PMC.");

    PMCSession[playerid][PMC_Active] = true;
    PMC_ShowMainMenu(playerid);
    return 1;
}

// Shows the public works computer main menu.
static PMC_ShowMainMenu(playerid)
{
    inline DlgPMCMain(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, inputtext

        if (!response)
        {
            PMCSession[pid][PMC_Active] = false;
            return 1;
        }

        switch (listitem)
        {
            case 0: PMC_ShowPlateSearch(pid);
        }
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPMCMain,
        DIALOG_STYLE_LIST,
        "Parking Management Console",
        "{FFFFFF}Plate Search",
        "Select",
        "Close"
    );

    return 1;
}

// Asks for a plate in the public works computer.
static PMC_ShowPlateSearch(playerid)
{
    inline DlgPMCPlate(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, listitem

        if (!response)
        {
            PMC_ShowMainMenu(pid);
            return 1;
        }

        strtrim(inputtext);

        if (strlen(inputtext) < 3)
        {
            SendClientMessage(pid, COLOR_ERROR, "Plate too short.");
            PMC_ShowPlateSearch(pid);
            return 1;
        }

        PMC_LoadPlate(pid, inputtext);
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPMCPlate,
        DIALOG_STYLE_INPUT,
        "PMC - Plate Search",
        "Enter vehicle plate:",
        "Search",
        "Back"
    );

    return 1;
}

// Looks up a vehicle by plate for public works.
static PMC_LoadPlate(playerid, const plate[])
{
    new vehIndex = -1;

    for (new i = 0; i < sizeof(Vehicle); i++)
    {
        if (Vehicle[i][E_VEHICLE_SQLID] == -1)
            continue;

        if (!strcmp(Vehicle[i][E_VEHICLE_LICENSE], plate, true))
        {
            vehIndex = i;
            break;
        }
    }

    if (vehIndex == -1)
    {
        SendServerMessage(playerid, COLOR_ERROR, "PMC", "A3A3A3",
            "No vehicle found for that plate.");
        PMC_ShowPlateSearch(playerid);
        return 1;
    }

    new owner[64] = "Unknown";

    switch (Vehicle[vehIndex][E_VEHICLE_TYPE])
    {
        case -1, 0:
            format(owner, sizeof owner, "Admin");

        case 1:
            format(owner, sizeof owner, "Rental");

        case 2:
            format(owner, sizeof owner, "DMV");

        case E_VEHICLE_TYPE_JOB:
        {
            switch (Vehicle[vehIndex][E_VEHICLE_JOBID])
            {
                case 1: format(owner, sizeof owner, "Ocean Docks");
                case 2: format(owner, sizeof owner, "Sanitary Andreas");
                default: format(owner, sizeof owner, "Job Vehicle");
            }
        }

        case E_VEHICLE_TYPE_FACTION:
        {
            new fenum = Faction_GetEnumID(Vehicle[vehIndex][E_VEHICLE_OWNER]);
            if (fenum != INVALID_FACTION_ID)
                format(owner, sizeof owner, "%s", Faction[fenum][E_FACTION_NAME]);
            else
                format(owner, sizeof owner, "Unknown Faction");
        }

        case E_VEHICLE_TYPE_PLAYER:
        {
            PMC_LoadPlatePlayerOwner(playerid, vehIndex);
            return 1; // async owner load
        }
    }

    PMC_ShowPlateResult(playerid, vehIndex, owner);
    return 1;
}

// Shows the plate result for public works.
static PMC_ShowPlateResult(playerid, vehIndex, const owner[])
{
    new body[768];
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new fines = VehicleOutstandingFines[vehIndex];

    format(body, sizeof body,
        "{a9c4e4}___________________________________________\n" \
        "{a9c4e4}DETAILS FOR:{FFFFFF} %s\n" \
        "{a9c4e4}___________________________________________\n\n" \
        "{a9c4e4}Model:{FFFFFF}\t%s\n" \
        "{a9c4e4}Plate:{FFFFFF}\t%s\n" \
        "{a9c4e4}Color:{FFFFFF}\t{%s}%s {a9c4e4}/ {%s}%s\n\n" \
        "{a9c4e4}Outstanding Vehicle Fines:{FFFFFF}\t$%s\n\n" \
        "{a9c4e4}Registered Owner:{FFFFFF}\n" \
        "%s\n" \
        "{a9c4e4}___________________________________________",
        Vehicle[vehIndex][E_VEHICLE_LICENSE],
        ReturnVehicleModelName(Vehicle[vehIndex][E_VEHICLE_MODELID]),
        Vehicle[vehIndex][E_VEHICLE_LICENSE],
        VehicleColoursTableRGBA[Vehicle[vehIndex][E_VEHICLE_COLOR_A]],
        vehicleColorNames[Vehicle[vehIndex][E_VEHICLE_COLOR_A]],
        VehicleColoursTableRGBA[Vehicle[vehIndex][E_VEHICLE_COLOR_B]],
        vehicleColorNames[Vehicle[vehIndex][E_VEHICLE_COLOR_B]],
        IntegerWithDelimiter(fines),
        owner
    );

    inline DlgPMCPlateResult(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, listitem, inputtext

        if (response) // View Tickets
        {
            PMC_ShowVehicleTickets(pid, Vehicle[vehIndex][E_VEHICLE_SQLID]);
        }
        else
        {
            PMC_ShowPlateSearch(pid);
        }

        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPMCPlateResult,
        DIALOG_STYLE_MSGBOX,
        "PMC - Plate Search Result",
        body,
        "View Tickets",
        "Back"
    );

    return 1;
}

// Shows the tickets on a vehicle for public works.
static PMC_ShowVehicleTickets(playerid, veh_sqlid)
{
    new list[2048];
    list[0] = EOS;

    strcat(list, "ID\tAmount\n");

    PMCSession[playerid][PMC_VehicleTicketCount] = 0;

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_vehicle_sqlid] != veh_sqlid)
            continue;

        // Skip paid tickets
        if (VehicleTicketData[i][vt_status] == TICKET_STATUS_PAID)
            continue;

        new idx = PMCSession[playerid][PMC_VehicleTicketCount];
        if (idx >= MDC_MAX_TICKETS)
            break;

        PMCSession[playerid][PMC_VehicleTicketIDs][idx] =
            VehicleTicketData[i][vt_id];

        PMCSession[playerid][PMC_VehicleTicketCount]++;

        format(list, sizeof list,
            "%s#%04d\t$%s\n",
            list,
            VehicleTicketData[i][vt_id],
            IntegerWithDelimiter(VehicleTicketData[i][vt_amount])
        );
    }

    if (!PMCSession[playerid][PMC_VehicleTicketCount])
    {
        SendClientMessage(playerid, COLOR_INFO, "No vehicle tickets found.");
        return 1;
    }

    inline DlgPMCVehicleTicketList(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, inputtext

        if (!response)
        {
            PMC_ShowMainMenu(pid);
            return 1;
        }

        if (listitem < PMCSession[pid][PMC_VehicleTicketCount])
        {
            new ticketid =
                PMCSession[pid][PMC_VehicleTicketIDs][listitem];

            PMC_ShowVehicleTicketDetail(pid, ticketid);
        }

        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPMCVehicleTicketList,
        DIALOG_STYLE_TABLIST_HEADERS,
        "PMC Vehicle Tickets",
        list,
        "View",
        "Back"
    );

    return 1;
}

// Looks up the owner of a vehicle for public works.
static PMC_LoadPlatePlayerOwner(playerid, vehIndex)
{
    new query[128];

    mysql_format(
        mysql,
        query,
        sizeof(query),
        "SELECT player_name FROM characters WHERE player_id = %d LIMIT 1",
        Vehicle[vehIndex][E_VEHICLE_OWNER]
    );

    inline OnPMCPlateOwnerLoaded()
    {
        new owner[64] = "Unknown Player";

        if (cache_num_rows())
        {
            cache_get_value_name(0, "player_name", owner);
            strreplace(owner, "_", " ");
        }

        PMC_ShowPlateResult(playerid, vehIndex, owner);
        return 1;
    }

    MySQL_TQueryInline(mysql, using inline OnPMCPlateOwnerLoaded, query, "");
    return 1;
}

// Shows one vehicle ticket for public works.
static PMC_ShowVehicleTicketDetail(playerid, ticketid)
{
    new body[1024];
    new now = gettime();
    new veh_sqlid = 0;

    for (new i; i < VehicleTicketCount; i++)
    {
        if (VehicleTicketData[i][vt_id] != ticketid)
            continue;

        veh_sqlid = VehicleTicketData[i][vt_vehicle_sqlid];

        new statusStr[16];

        if (VehicleTicketData[i][vt_status] == TICKET_STATUS_PAID)
            format(statusStr, sizeof statusStr, "Paid");
        else if (VehicleTicketData[i][vt_status] == TICKET_STATUS_VOID)
            format(statusStr, sizeof statusStr, "Revoked");
        else if (VehicleTicketData[i][vt_due_unix] > 0 && now > VehicleTicketData[i][vt_due_unix])
            format(statusStr, sizeof statusStr, "Expired");
        else
            format(statusStr, sizeof statusStr, "Unpaid");

        new issueDate[16], dueDate[16];

        UnixToDateStr(VehicleTicketData[i][vt_date_unix], issueDate, sizeof issueDate);

        if (VehicleTicketData[i][vt_due_unix] > 0)
            UnixToDateStr(VehicleTicketData[i][vt_due_unix], dueDate, sizeof dueDate);
        else
            format(dueDate, sizeof dueDate, "N/A");

        format(body, sizeof body,
            "{a9c4e4}___________________________________________\n" \
            "{a9c4e4}VEHICLE TICKET DETAIL\n" \
            "{a9c4e4}___________________________________________\n\n" \
            "{a9c4e4}Ticket ID:{FFFFFF} #%04d\n" \
            "{a9c4e4}Amount:{FFFFFF} $%s\n" \
            "{a9c4e4}Status:{FFFFFF} %s\n" \
            "{a9c4e4}Issued:{FFFFFF} %s\n" \
            "{a9c4e4}Due:{FFFFFF} %s\n\n" \
            "{a9c4e4}Reason:{FFFFFF}\n%s\n\n" \
            "{a9c4e4}Issued By:{FFFFFF} %s\n" \
            "{a9c4e4}___________________________________________",
            ticketid,
            IntegerWithDelimiter(VehicleTicketData[i][vt_amount]),
            statusStr,
            issueDate,
            dueDate,
            VehicleTicketData[i][vt_reason],
            VehicleTicketData[i][vt_issuer_name]
        );

        break;
    }

    inline DlgPMCTicketDetail(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused dialogid, response, listitem, inputtext

        PMC_ShowVehicleTickets(pid, veh_sqlid);
        return 1;
    }

    Dialog_ShowCallback(
        playerid,
        using inline DlgPMCTicketDetail,
        DIALOG_STYLE_MSGBOX,
        "PMC Vehicle Ticket",
        body,
        "Back"
    );

    return 1;
}

// Converts '\n' text typed in the database into real new lines.
stock ConvertNewlines(dest[], size, const src[])
{
    new j = 0;

    for (new i = 0; src[i] != EOS && j < size - 1; i++)
    {
        // Detect \n (backslash + n)
        if (src[i] == '\\' && src[i + 1] == 'n')
        {
            dest[j++] = '\n';
            i++; // skip the 'n'
        }
        else if (src[i] == '\r')
        {
            continue; // ignore carriage returns
        }
        else
        {
            dest[j++] = src[i];
        }
    }

    dest[j] = EOS;
}
