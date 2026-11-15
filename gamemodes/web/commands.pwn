// ============================================================================
// File: web/commands.pwn
// Polls the `web_commands` table every 2 seconds and runs commands issued from a website/ACP
// (for example scheduling maintenance). Add new handlers in WebCommand_Execute.
// ============================================================================

// web/commands.pwn
// Polls the web_commands table every 2 seconds and executes pending commands
// issued from the ACP. Add new command handlers inside WebCommand_Execute.

forward WebCommands_Poll();
// Polls the database for commands sent from a web panel.
public WebCommands_Poll()
{
    mysql_tquery(mysql,
        "SELECT id, `command`, params FROM web_commands WHERE `status` = 'pending' ORDER BY id ASC LIMIT 5",
        "WebCommands_OnLoad", "");
    return 1;
}

forward WebCommands_OnLoad();
// MySQL callback: reads the pending web commands and runs them.
public WebCommands_OnLoad()
{
    new rows = cache_num_rows();
    if (!rows) return 1;

    for (new i = 0; i < rows; i++)
    {
        new id;
        new command[64];
        new params[512];
        cache_get_value_int(i, "id", id);
        cache_get_value(i, "command", command, sizeof(command));
        cache_get_value(i, "params", params, sizeof(params));
        WebCommand_Execute(id, command, params);
    }
    return 1;
}

// Runs one web command (for example a kick, ban or message) as if it came from staff.
WebCommand_Execute(id, const command[], const params[])
{
    new result[255];
    new bool:success = true;

    // ── maintenance [seconds] ─────────────────────────────────
    if (strcmp(command, "maintenance", true) == 0)
    {
        new seconds = strval(params);

        if (seconds < 30 || seconds > 21600)
        {
            format(result, sizeof(result), "Invalid: seconds must be 30-21600 (got %d)", seconds);
            success = false;
        }
        else
        {
            new string[256];

            if (SystemUpdate == 0)
            {
                SendClientMessageToAll(-1, "");
                SendClientMessageToAll(-1, "");
                SendClientMessageToAll(COLOR_BLUE,   "* The server will be going down for Scheduled Maintenance. (See bottom right screen)");
                SendClientMessageToAll(COLOR_YELLOW, "! End your scenes A.S.A.P. and don't engage in new activities until after the restart !");
                SendClientMessageToAll(-1, "");
                SendClientMessageToAll(-1, "");
                GameTextForAll("~n~~n~~n~~n~~y~] Scheduled Maintenance Alert ]", 5000, 3);
            }

            SystemUpdate = seconds;
            format(string, sizeof(string), "%s", STimeConvert(SystemUpdate));
            TextDrawShowForAll(UpdateIn[0]);
            TextDrawSetString(UpdateIn[1], string);
            TextDrawShowForAll(UpdateIn[1]);
            if (SystemUpdate != 0) KillTimer(SystemTimer);
            SystemTimer = SetTimer("MaintenanceTimer", 1000, true);

            format(result, sizeof(result), "Maintenance scheduled in %d seconds", seconds);
        }
    }

    // ── unknown ───────────────────────────────────────────────
    else
    {
        format(result, sizeof(result), "Unknown command: %s", command);
        success = false;
    }

    // Mark the command as done or error
    new query[512];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE web_commands SET `status` = '%s', result = '%e', processed_at = NOW() WHERE id = %d",
        success ? "done" : "error",
        result, id);
    mysql_tquery(mysql, query);
}
