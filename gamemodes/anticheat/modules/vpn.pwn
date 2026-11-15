// ============================================================================
// File: anticheat/modules/vpn.pwn
// VPN/proxy detection with a database whitelist (`vpn_whitelist` table, managed with /addvpn,
// /removevpn, /listvpn). Checks new connections against an external proxy-check service.
// Commands: /addvpn /removevpn /listvpn
// ============================================================================

// VPN / proxy detection with a database-backed whitelist.
//
// The whitelist lives in the `vpn_whitelist` table (see database/schema.sql) and is keyed
// on account_id, so it can be managed from the ACP as well as in-game via /addvpn,
// /removevpn and /listvpn.
//
// Keyed on ID rather than name on purpose: a player can change their account name, and
// a name-keyed entry would silently stop matching. Everything that needs a name joins
// back to `accounts` to pull the CURRENT one from the ID, so renames just work.
//
// The VPN check runs on connect, before login, when the server only knows the player's
// name -- so the lookup joins `accounts` on account_name to find the row by ID. The table
// is read live rather than cached, so a change made in the ACP applies on the very next
// login: no reload command, no restart, no cache to go stale. That costs one indexed
// lookup per connection, and the VPN lookup itself was already asynchronous.

#include <YSI_Coding\y_hooks>

// Fire the actual proxy/hosting lookup for a player who isn't whitelisted.
static VPN_StartProxyCheck(playerid)
{
    new ip[16], url[128];

    GetPlayerIp(playerid, ip, sizeof(ip));
    format(url, sizeof(url), "www.ip-api.com/json/%s?fields=proxy,hosting", ip);

    HTTP(playerid, HTTP_GET, url, "", "MyHttpResponse");
}

// Called from gamemode.pwn on startup. Nothing to load any more -- the table is read
// live -- so this just reports the current count.
LoadVPNWhitelist()
{
    inline OnWhitelistCounted()
    {
        new count;

        if (cache_num_rows())
        {
            cache_get_value_name_int(0, "total", count);
        }

        printf("[VPN Whitelist] %d whitelisted account(s) in database", count);
    }

    MySQL_TQueryInline(mysql, using inline OnWhitelistCounted,
        "SELECT COUNT(*) AS `total` FROM `vpn_whitelist`");

    return 1;
}

hook OnPlayerConnect(playerid)
{
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, sizeof(playerName));

    // Connect fires before login, so we only have the name -- resolve it to the
    // whitelisted account_id through `accounts`.
    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT 1 FROM `vpn_whitelist` `w` \
         INNER JOIN `accounts` `a` ON `a`.`account_id` = `w`.`account_id` \
         WHERE `a`.`account_name` = '%e' LIMIT 1", playerName);

    inline OnWhitelistChecked()
    {
        // They may have dropped while the query was in flight.
        if (IsPlayerConnected(playerid))
        {
            if (cache_num_rows() > 0)
            {
                new name[MAX_PLAYER_NAME];
                GetPlayerName(playerid, name, sizeof(name));

                printf("[VPN Whitelist] %s connected (whitelisted - skipping VPN check)", name);
            }
            else
            {
                VPN_StartProxyCheck(playerid);
            }
        }
    }

    MySQL_TQueryInline(mysql, using inline OnWhitelistChecked, query);
    return 1;
}

forward MyHttpResponse(playerid, response_code, data[]);
// HTTP callback: reads the proxy-check service reply and kicks (or allows, if whitelisted) a
// player on a VPN.
public MyHttpResponse(playerid, response_code, data[])
{
    #pragma unused response_code

    if (strfind(data, "true", true) != -1)
    {
        new playerName[MAX_PLAYER_NAME];
        GetPlayerName(playerid, playerName, sizeof(playerName));

        SendAdminMessage(sprintf("[VPN AC]: Kicking %s for using a VPN.", playerName));
        SendClientMessage(playerid, 0xFF0000FF, "[!!!] Server has detected you are using a VPN. Disable it and rejoin.");
        SendClientMessage(playerid, 0xC58536FF, ">> In case of country restrictions, create a ticket in the server support Discord ("" SERVER_DISCORD "").");

        SetTimerEx("DelayedKick", 100, false, "i", playerid);
    }

    return 1;
}

forward DelayedKick(playerid);
// Timer helper: kicks a player after a short delay so the message can be read.
public DelayedKick(playerid)
{
    Kick(playerid);
    return 1;
}

// /addvpn [account] - whitelists an account so it may connect through a VPN.
CMD:addvpn(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
    {
        return SendClientMessage(playerid, 0xFF0000FF, "You don't have permission to use this command.");
    }

    new targetName[MAX_PLAYER_NAME];
    if (sscanf(params, "s[24]", targetName))
    {
        return SendClientMessage(playerid, 0xFFFFFFFF, "Usage: /addvpn <account name>");
    }

    // Resolve the name to an account_id and store the ID, in one statement.
    new query[300];
    mysql_format(mysql, query, sizeof(query),
        "INSERT IGNORE INTO `vpn_whitelist` (`account_id`, `created_by`, `created_at`) \
         SELECT `account_id`, %d, %d FROM `accounts` WHERE `account_name` = '%e'",
        Account[playerid][E_PLAYER_ACCOUNT_ID], gettime(), targetName);

    inline OnWhitelistAdded()
    {
        if (IsPlayerConnected(playerid))
        {
            // 0 rows = no such account, or they're already whitelisted.
            if (cache_affected_rows() == 0)
            {
                SendClientMessage(playerid, 0xFF0000FF, sprintf("No account named \"%s\", or they're already whitelisted.", targetName));
            }
            else
            {
                SendAdminMessage(sprintf("[AdmCmd]: %s was added to the VPN whitelist by %s.", targetName, Account[playerid][E_PLAYER_ACCOUNT_NAME]));
                SendClientMessage(playerid, 0x00FF00FF, sprintf("Added %s to the VPN whitelist.", targetName));
            }
        }
    }

    MySQL_TQueryInline(mysql, using inline OnWhitelistAdded, query);
    return 1;
}

// /removevpn [account] - removes an account from the VPN whitelist.
CMD:removevpn(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
    {
        return SendClientMessage(playerid, 0xFF0000FF, "You don't have permission to use this command.");
    }

    new targetName[MAX_PLAYER_NAME];
    if (sscanf(params, "s[24]", targetName))
    {
        return SendClientMessage(playerid, 0xFFFFFFFF, "Usage: /removevpn <account name>");
    }

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "DELETE `w` FROM `vpn_whitelist` `w` \
         INNER JOIN `accounts` `a` ON `a`.`account_id` = `w`.`account_id` \
         WHERE `a`.`account_name` = '%e'", targetName);

    inline OnWhitelistRemoved()
    {
        if (IsPlayerConnected(playerid))
        {
            if (cache_affected_rows() == 0)
            {
                SendClientMessage(playerid, 0xFF0000FF, sprintf("\"%s\" isn't on the VPN whitelist.", targetName));
            }
            else
            {
                SendAdminMessage(sprintf("[AdmCmd]: %s was removed from the VPN whitelist by %s.", targetName, Account[playerid][E_PLAYER_ACCOUNT_NAME]));
                SendClientMessage(playerid, 0x00FF00FF, sprintf("Removed %s from the VPN whitelist.", targetName));
            }
        }
    }

    MySQL_TQueryInline(mysql, using inline OnWhitelistRemoved, query);
    return 1;
}

// /listvpn - shows every whitelisted account.
CMD:listvpn(playerid, params[])
{
    #pragma unused params

    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
    {
        return SendClientMessage(playerid, 0xFF0000FF, "You don't have permission to use this command.");
    }

    inline OnWhitelistListed()
    {
        if (IsPlayerConnected(playerid))
        {
            new rows = cache_num_rows();

            if (!rows)
            {
                SendClientMessage(playerid, 0xFFFFFFFF, "The VPN whitelist is empty.");
            }
            else
            {
                SendClientMessage(playerid, COLOR_ORANGE, sprintf("_____________ VPN Whitelist (%d entries) _____________", rows));

                for (new i = 0; i < rows; i++)
                {
                    new name[MAX_PLAYER_NAME], added_by[MAX_PLAYER_NAME];

                    cache_get_value_name(i, "account_name", name, sizeof(name));
                    cache_get_value_name(i, "added_by", added_by, sizeof(added_by));

                    SendClientMessage(playerid, 0xFFFFFFFF, sprintf("%d. %s {AAAAAA}(added by %s)", i + 1, name, added_by));
                }
            }
        }
    }

    // Names are pulled live from the account IDs, so renames show correctly.
    MySQL_TQueryInline(mysql, using inline OnWhitelistListed,
        "SELECT `a`.`account_name`, COALESCE(`b`.`account_name`, 'unknown') AS `added_by` \
         FROM `vpn_whitelist` `w` \
         INNER JOIN `accounts` `a` ON `a`.`account_id` = `w`.`account_id` \
         LEFT  JOIN `accounts` `b` ON `b`.`account_id` = `w`.`created_by` \
         ORDER BY `a`.`account_name` ASC");

    return 1;
}
