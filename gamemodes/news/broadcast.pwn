// ============================================================================
// File: news/broadcast.pwn
// Live news broadcasts: reporters go live (/broadcast), listeners tune in (/tunein, /tuneout),
// co-anchors (/coanchor), history and leaderboards.
// Commands: /broadcast /coanchor /broadcasts /broadcasthistory /reporterleaderboard
// /outletleaderboard /mybroadcaststats /tunein /tuneout /live /newsroom /weeklyactivity
// ============================================================================

#include <YSI_Coding\y_hooks>

enum {
    BROADCAST_STATE_NONE    = 0,
    BROADCAST_STATE_LIVE    = 1,
    BROADCAST_STATE_PAUSED  = 2
};

#define MAX_BROADCAST_TITLE     64
#define MAX_BROADCAST_HISTORY   50      // How many past broadcasts to keep in le db
#define INVALID_COANCHOR        INVALID_PLAYER_ID


#define MAX_BROADCAST_OUTLET 16

static enum E_PLAYER_NEWS_DATA {
    E_PLAYER_NEWS_BROADCASTING,
    E_PLAYER_NEWS_BROADCAST_TITLE[MAX_BROADCAST_TITLE],
    bool:E_PLAYER_NEWS_LISTENING,
    E_PLAYER_NEWS_LISTENING_TO,

    E_PLAYER_NEWS_COANCHOR,             // playerid of this broadcasters co-anchor
    bool:E_PLAYER_NEWS_IS_COANCHOR,     // true when this player IS a co-anchor for someone else
    E_PLAYER_NEWS_COANCHOR_OF,          // who this player is a co-anchor for

    // Stats tracked while broadcast is live (used for history log)
    E_PLAYER_NEWS_START_TIME,           // gettime() when broadcast started
    E_PLAYER_NEWS_PEAK_LISTENERS,       // highest listener count seen during broadcast

    // Captured once at /broadcast start (GetPlayerOutletName) rather than
    // re-resolved later - keeps history/leaderboards accurate even if the
    // reporter leaves their firm before the broadcast (or the server) ends.
    E_PLAYER_NEWS_OUTLET[MAX_BROADCAST_OUTLET]
}
static PlayerNewsVar[MAX_PLAYERS][E_PLAYER_NEWS_DATA];

hook OnPlayerConnect(playerid)
{
    PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING]       = BROADCAST_STATE_NONE;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCAST_TITLE][0] = EOS;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING]          = false;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO]       = INVALID_PLAYER_ID;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR]           = INVALID_COANCHOR;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR]        = false;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF]        = INVALID_PLAYER_ID;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_START_TIME]         = 0;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS]     = 0;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_OUTLET][0]          = EOS;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    new coanchor = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR];
    if (IsPlayerConnected(coanchor))
    {
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_IS_COANCHOR] = false;
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_COANCHOR_OF] = INVALID_PLAYER_ID;
        SendClientMessage(coanchor, 0xA15B26FF, "[NEWS] The main broadcaster disconnected. Your co-anchor role has ended.");
    }

    if (PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR])
    {
        new broadcasterid = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF];
        if (IsPlayerConnected(broadcasterid))
        {
            PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_COANCHOR] = INVALID_COANCHOR;
            SendClientMessage(broadcasterid, 0xA15B26FF, "[NEWS] Your co-anchor disconnected.");
        }
    }
    return 1;
}

// Counts how many players are listening to a broadcast.
static CountListeners(broadcasterid)
{
    new count = 0;
    foreach (new i: Player)
    {
        if (PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING] &&
            PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO] == broadcasterid)
            count++;
    }
    return count;
}

// Saves a finished broadcast to the history table.
static SaveBroadcastHistory(broadcasterid, endtime)
{
    new query[512];
    new broadcastername[MAX_PLAYER_NAME];
    GetPlayerName(broadcasterid, broadcastername, sizeof(broadcastername));

    new duration = endtime - PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_START_TIME];

    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO `broadcast_history` \
         (`broadcaster_name`, `broadcast_title`, `broadcaster_outlet`, `start_time`, `end_time`, `duration_seconds`, `peak_listeners`) \
         VALUES ('%e', '%e', '%e', '%d', '%d', '%d', '%d')",
        broadcastername,
        PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_BROADCAST_TITLE],
        PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_OUTLET],
        PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_START_TIME],
        endtime,
        duration,
        PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_PEAK_LISTENERS]
    );
    mysql_tquery(mysql, query);
}

// Resets a player's broadcaster state (and their co-anchor's).
static ResetBroadcasterState(playerid)
{
    new coanchor = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR];
    if (IsPlayerConnected(coanchor))
    {
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_IS_COANCHOR]  = false;
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_COANCHOR_OF]  = INVALID_PLAYER_ID;
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_LISTENING]    = false;
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_LISTENING_TO] = INVALID_PLAYER_ID;
    }

    PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING]   = BROADCAST_STATE_NONE;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR]       = INVALID_COANCHOR;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_START_TIME]     = 0;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS] = 0;
}

//  /broadcast  [start/mute/unmute/end]
CMD:broadcast(playerid, params[])
{
    new option[7], title[128], str[200];
    sscanf(params, "s[7] ", option);

    if (!IsPlayerInNewsFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not on duty in a news faction.");

    if (strlen(option) > 1)
    {
        if (!strcmp(option, "start", true))
        {
            if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING])
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're already doing a live broadcast.");

            if (PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR])
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're currently a co-anchor. Use /coanchor leave first.");

            if (sscanf(params, "s[7] s[128]", option, title))
                return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/broadcast [start] [broadcast title]");

            if (strlen(title) <= 0 || strlen(title) >= MAX_BROADCAST_TITLE)
                return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/broadcast [start] [broadcast title]");

            PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING]     = BROADCAST_STATE_LIVE;
            PlayerNewsVar[playerid][E_PLAYER_NEWS_START_TIME]       = gettime();
            PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS]   = 0;
            PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR]         = INVALID_COANCHOR;
            format(PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCAST_TITLE], MAX_BROADCAST_TITLE, "%s", title);
            GetPlayerOutletName(playerid, PlayerNewsVar[playerid][E_PLAYER_NEWS_OUTLET], MAX_BROADCAST_OUTLET);

            new outlettag[MAX_BROADCAST_OUTLET + 4];
            if (PlayerNewsVar[playerid][E_PLAYER_NEWS_OUTLET][0] != EOS)
                format(outlettag, sizeof(outlettag), " (%s)", PlayerNewsVar[playerid][E_PLAYER_NEWS_OUTLET]);
            else
                outlettag[0] = EOS;

            ProxDetectorEx(playerid, 30.0, COLOR_PURPLE, "**", sprintf("starts a live broadcast of \"%s\".", title), .annonated=true);

            format(str, sizeof(str), "[TIP] {36D191}%s%s went live with {36906b}\"%s\"{36D191} Type {36906b}/broadcasts{36D191} to listen.", ReturnRPName(playerid), outlettag, title);
            foreach (new targetid: Player)
            {
                if (IsPlayerPlaying(targetid))
                    ZMsg_SendClientMessage(targetid, COLOR_SERVER, str);
            }

            PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING]    = true;
            PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO] = playerid;
        }
        else if (!strcmp(option, "end", true))
        {
            if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_NONE)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You've not started a live broadcast.");

            new endtime = gettime();
            new currentListeners = CountListeners(playerid);
            if (currentListeners > PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS])
                PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS] = currentListeners;

            SaveBroadcastHistory(playerid, endtime);

            ProxDetectorEx(playerid, 30.0, COLOR_PURPLE, "**", sprintf("ends the live broadcast of \"%s\".", PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCAST_TITLE]), .annonated=true);

            new coanchor = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR];
            if (IsPlayerConnected(coanchor))
                SendClientMessage(coanchor, 0xA15B26FF, "[NEWS] The broadcast has ended. Your co-anchor role has been removed.");

            ResetBroadcasterState(playerid);
        }
        else if (!strcmp(option, "mute", true))
        {
            if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] != BROADCAST_STATE_LIVE)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have a live broadcast to mute.");

            ProxDetectorEx(playerid, 30.0, COLOR_PURPLE, "**", "mutes the microphone, pausing the live broadcast.", .annonated=true);
            PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] = BROADCAST_STATE_PAUSED;
        }
        else if (!strcmp(option, "unmute", true))
        {
            if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] != BROADCAST_STATE_PAUSED)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have a muted broadcast to resume.");

            ProxDetectorEx(playerid, 30.0, COLOR_PURPLE, "**", "unmutes the microphone, resuming the live broadcast.", .annonated=true);
            PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] = BROADCAST_STATE_LIVE;
        }
        else
        {
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/broadcast [start/mute/unmute/end]");
        }

        foreach (new i: Player)
        {
            if (PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING] &&
                PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO] != INVALID_PLAYER_ID)
            {
                if (!PlayerNewsVar[PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO]][E_PLAYER_NEWS_BROADCASTING])
                {
                    format(str, sizeof(str), "[LIVE]{36D191} The live broadcast of {e24f80}\"%s\"{36D191} has finished.", PlayerNewsVar[PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO]][E_PLAYER_NEWS_BROADCAST_TITLE]);
                    ZMsg_SendClientMessage(i, COLOR_SERVER, str);
                    PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO] = INVALID_PLAYER_ID;
                    PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING]    = false;
                }
            }
        }

        return true;
    }

    return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/broadcast [start/mute/unmute/end]");
}

//  /coanchor  [invite/accept/leave/remove]
CMD:coanchor(playerid, params[])
{
    new option[10];
    if (sscanf(params, "s[10] ", option))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/coanchor [invite/accept/leave/remove]");

    if (!IsPlayerInNewsFaction(playerid, true))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not on duty in a news faction.");

    if (!strcmp(option, "invite", true))
    {
        new targetid;
        if (sscanf(params, "s[10] k<player>", option, targetid))
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/coanchor invite [player]");

        if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_NONE)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be broadcasting to invite a co-anchor.");

        if (targetid == playerid)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't invite yourself.");

        if (!IsPlayerInNewsFaction(targetid, true))
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player is not on duty in a news faction.");

        if (PlayerNewsVar[targetid][E_PLAYER_NEWS_BROADCASTING])
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player is already broadcasting.");

        if (PlayerNewsVar[targetid][E_PLAYER_NEWS_IS_COANCHOR])
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That player is already a co-anchor on another broadcast.");

        if (PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR] != INVALID_COANCHOR)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You already have a co-anchor. Use /coanchor remove first.");

        PlayerNewsVar[targetid][E_PLAYER_NEWS_COANCHOR_OF] = playerid;    // pending invite

        new str[200];
        format(str, sizeof(str), "[NEWS] %s has invited you to co-anchor their broadcast \"%s\". Type /coanchor accept to join.",
            ReturnRPName(playerid), PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCAST_TITLE]);
        SendClientMessage(targetid, COLOR_SERVER, str);

        format(str, sizeof(str), "[NEWS] Co-anchor invite sent to %s.", ReturnRPName(targetid));
        SendClientMessage(playerid, COLOR_SERVER, str);
        return true;
    }

    if (!strcmp(option, "accept", true))
    {
        if (PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR])
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're already a co-anchor.");

        new broadcasterid = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF];

        if (broadcasterid == INVALID_PLAYER_ID || !IsPlayerConnected(broadcasterid))
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You have no pending co-anchor invite.");

        if (PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_NONE)
        {
            PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF] = INVALID_PLAYER_ID;
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That broadcast has already ended.");
        }

        PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR]      = true;
        PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF]      = broadcasterid;
        PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_COANCHOR]    = playerid;

        PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING]        = true;
        PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO]     = broadcasterid;

        new str[200];
        format(str, sizeof(str), "[NEWS] You are now co-anchoring \"%s\" with %s. Use /live to speak on air from anywhere.",
            PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_BROADCAST_TITLE], ReturnRPName(broadcasterid));
        SendClientMessage(playerid, COLOR_SERVER, str);

        format(str, sizeof(str), "[NEWS] %s has accepted your co-anchor invite and joined the broadcast.", ReturnRPName(playerid));
        SendClientMessage(broadcasterid, COLOR_SERVER, str);
        return true;
    }

    if (!strcmp(option, "leave", true))
    {
        if (!PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR])
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not currently a co-anchor.");

        new broadcasterid = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF];

        PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR]      = false;
        PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF]      = INVALID_PLAYER_ID;
        PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING]        = false;
        PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO]     = INVALID_PLAYER_ID;

        if (IsPlayerConnected(broadcasterid))
        {
            PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_COANCHOR] = INVALID_COANCHOR;
            new str[128];
            format(str, sizeof(str), "[NEWS] %s has left as your co-anchor.", ReturnRPName(playerid));
            SendClientMessage(broadcasterid, COLOR_SERVER, str);
        }

        SendClientMessage(playerid, COLOR_SERVER, "[NEWS] You have stepped down as co-anchor.");
        return true;
    }

    if (!strcmp(option, "remove", true))
    {
        if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_NONE)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not broadcasting.");

        new coanchor = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR];
        if (coanchor == INVALID_COANCHOR || !IsPlayerConnected(coanchor))
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have an active co-anchor.");

        PlayerNewsVar[coanchor][E_PLAYER_NEWS_IS_COANCHOR]  = false;
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_COANCHOR_OF]  = INVALID_PLAYER_ID;
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_LISTENING]    = false;
        PlayerNewsVar[coanchor][E_PLAYER_NEWS_LISTENING_TO] = INVALID_PLAYER_ID;

        PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR]     = INVALID_COANCHOR;

        new str[128];
        format(str, sizeof(str), "[NEWS] %s removed you as co-anchor.", ReturnRPName(playerid));
        SendClientMessage(coanchor, COLOR_SERVER, str);

        format(str, sizeof(str), "[NEWS] You have removed %s as your co-anchor.", ReturnRPName(coanchor));
        SendClientMessage(playerid, COLOR_SERVER, str);
        return true;
    }

    return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/coanchor [invite/accept/leave/remove]");
}

static BroadcastsDlgStr[1024];

// /broadcasts - lists the live broadcasts.
CMD:broadcasts(playerid, params[])
{
    format(BroadcastsDlgStr, sizeof(BroadcastsDlgStr), "Title\tBroadcaster\tOutlet\tCo-Anchor\tStatus\tListeners\n");

    new listeners[MAX_PLAYERS], broadcasts = 0;
    new map[MAX_PLAYERS];

    foreach (new i: Player)
    {
        if (PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING] && IsPlayerConnected(PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO]))
            listeners[PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO]]++;
    }

    foreach (new i: Player)
    {
        if (PlayerNewsVar[i][E_PLAYER_NEWS_BROADCASTING])
        {
            new coanchorname[MAX_PLAYER_NAME + 4];
            new coanchor = PlayerNewsVar[i][E_PLAYER_NEWS_COANCHOR];
            if (IsPlayerConnected(coanchor))
                format(coanchorname, sizeof(coanchorname), "%s", ReturnRPName(coanchor));
            else
                format(coanchorname, sizeof(coanchorname), "None");

            new outletname[MAX_BROADCAST_OUTLET];
            if (PlayerNewsVar[i][E_PLAYER_NEWS_OUTLET][0] != EOS)
                format(outletname, sizeof(outletname), "%s", PlayerNewsVar[i][E_PLAYER_NEWS_OUTLET]);
            else
                format(outletname, sizeof(outletname), "Independent");

            format(BroadcastsDlgStr, sizeof(BroadcastsDlgStr), "%s%s\t%s\t%s\t%s\t%s\t%d\n",
                BroadcastsDlgStr,
                PlayerNewsVar[i][E_PLAYER_NEWS_BROADCAST_TITLE],
                ReturnRPName(i),
                outletname,
                coanchorname,
                GetBroadcastState(PlayerNewsVar[i][E_PLAYER_NEWS_BROADCASTING]),
                listeners[i]);
            map[broadcasts] = i;
            broadcasts++;
        }
    }

    if (!broadcasts)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "There are currently no broadcasts.");

    inline BroadcastsDlg(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, inputtext, listitem
        if (response)
        {
            if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING])
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must stop broadcasting first.");

            new broadcasterid = map[listitem];
            if (IsPlayerConnected(broadcasterid) && PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_BROADCASTING])
            {
                PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING]    = true;
                PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO] = broadcasterid;

                new listen_outlet[MAX_BROADCAST_OUTLET];
                if (PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_OUTLET][0] != EOS)
                    format(listen_outlet, sizeof(listen_outlet), "%s", PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_OUTLET]);
                else
                    format(listen_outlet, sizeof(listen_outlet), "Independent");

                SendClientMessage(playerid, -1, sprintf("You're now listening to \"%s\" by %s (%s).  Type /tuneout to stop.",
                    PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_BROADCAST_TITLE], ReturnSettingsName(broadcasterid, playerid),
                    listen_outlet));
            }
        }
    }

    Dialog_ShowCallback(playerid, using inline BroadcastsDlg, DIALOG_STYLE_TABLIST_HEADERS, "Live Broadcasts", BroadcastsDlgStr, "Listen", "Back");
    return true;
}


// /broadcasthistory - shows past broadcasts.
CMD:broadcasthistory(playerid, params[])
{
    if (!IsPlayerInNewsFaction(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a news faction to view broadcast history.");

    new page = 0;
    sscanf(params, "i", page);
    if (page < 0) page = 0;

    new offset = page * 15;

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "SELECT `broadcaster_name`, `broadcast_title`, `broadcaster_outlet`, `start_time`, `duration_seconds`, `peak_listeners` \
         FROM `broadcast_history` \
         ORDER BY `start_time` DESC \
         LIMIT 15 OFFSET %d",
        offset);

    inline BroadcastHistoryQuery()
    {
        new rows = cache_num_rows();

        if (!rows)
        {
            if (page == 0)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No broadcast history found.");
            else
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No more broadcast history entries.");
        }

        new dialogstr[1280];
        format(dialogstr, sizeof(dialogstr), "Broadcaster\tOutlet\tTitle\tDate\tDuration\tPeak\n");

        new broadcastername[MAX_PLAYER_NAME];
        new broadcasttitle[MAX_BROADCAST_TITLE];
        new broadcastoutlet[MAX_BROADCAST_OUTLET];
        new starttimeraw, duration, peak;
        new datetimestr[12];
        new durationstr[10];

        for (new i = 0; i < rows; i++)
        {
            cache_get_value_name(i,     "broadcaster_name",   broadcastername);
            cache_get_value_name(i,     "broadcast_title",    broadcasttitle);
            cache_get_value_name(i,     "broadcaster_outlet", broadcastoutlet);
            cache_get_value_name_int(i, "start_time",         starttimeraw);
            cache_get_value_name_int(i, "duration_seconds",   duration);
            cache_get_value_name_int(i, "peak_listeners",     peak);

            if (broadcastoutlet[0] == EOS) format(broadcastoutlet, sizeof(broadcastoutlet), "Independent");

            UnixToDateStr(starttimeraw, datetimestr, sizeof(datetimestr));
            format(durationstr, sizeof(durationstr), "%02d:%02d", duration / 60, duration % 60);

            format(dialogstr, sizeof(dialogstr), "%s%s\t%s\t%s\t%s\t%s\t%d\n",
                dialogstr, broadcastername, broadcastoutlet, broadcasttitle, datetimestr, durationstr, peak);
        }

        new title[64];
        format(title, sizeof(title), "Broadcast History (Page %d)", page + 1);

        inline HistoryNav(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused pid, dialogid, listitem, inputtext
            if (response)  // Next Page
            {
                new nextcmd[12];
                format(nextcmd, sizeof(nextcmd), "%d", page + 1);
                cmd_broadcasthistory(playerid, nextcmd);
            }
        }

        Dialog_ShowCallback(playerid, using inline HistoryNav, DIALOG_STYLE_TABLIST_HEADERS, title, dialogstr, "Next Page", "Close");
    }

    MySQL_TQueryInline(mysql, using inline BroadcastHistoryQuery, query, "");
    return true;
}

//  /reporterleaderboard  [page]
//  Rank | Reporter | Broadcasts | Air Time | Avg Peak
CMD:reporterleaderboard(playerid, params[])
{
    if (!IsPlayerInNewsFaction(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a news faction to view the leaderboard.");

    new page = 0;
    sscanf(params, "i", page);
    if (page < 0) page = 0;

    new offset = page * 20;
    new query[512];

    mysql_format(mysql, query, sizeof(query),
        "SELECT \
            `broadcaster_name`, \
            `broadcaster_outlet`, \
            COUNT(*)                        AS `total_broadcasts`, \
            SUM(`duration_seconds`)         AS `total_airtime`, \
            ROUND(AVG(`peak_listeners`), 0) AS `avg_peak` \
         FROM `broadcast_history` \
         GROUP BY `broadcaster_name`, `broadcaster_outlet` \
         ORDER BY `total_airtime` DESC \
         LIMIT 20 OFFSET %d",
        offset);

    inline LeaderboardQuery()
    {
        new rows = cache_num_rows();

        if (!rows)
        {
            if (page == 0)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No reporter data found yet.");
            else
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No more reporters on the leaderboard.");
        }

        new dialogstr[2560];
        format(dialogstr, sizeof(dialogstr), "Rank\tReporter\tOutlet\tBroadcasts\tAir Time\tAvg Peak\n");

        new reportername[MAX_PLAYER_NAME];
        new reporteroutlet[MAX_BROADCAST_OUTLET];
        new totalbroadcasts, totalairtime, avgpeak;
        new airtimestr[12];

        for (new i = 0; i < rows; i++)
        {
            cache_get_value_name(i,     "broadcaster_name",   reportername);
            cache_get_value_name(i,     "broadcaster_outlet", reporteroutlet);
            cache_get_value_name_int(i, "total_broadcasts",   totalbroadcasts);
            cache_get_value_name_int(i, "total_airtime",      totalairtime);
            cache_get_value_name_int(i, "avg_peak",           avgpeak);

            if (reporteroutlet[0] == EOS) format(reporteroutlet, sizeof(reporteroutlet), "Independent");

            FormatAirTime(totalairtime, airtimestr, sizeof(airtimestr));

            format(dialogstr, sizeof(dialogstr), "%s#%d\t%s\t%s\t%d\t%s\t%d\n",
                dialogstr,
                offset + i + 1,
                reportername,
                reporteroutlet,
                totalbroadcasts,
                airtimestr,
                avgpeak);
        }

        new title[64];
        format(title, sizeof(title), "Reporter Leaderboard (Page %d)", page + 1);

        inline LeaderboardNav(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused pid, dialogid, listitem, inputtext
            if (response)
            {
                new nextcmd[12];
                format(nextcmd, sizeof(nextcmd), "%d", page + 1);
                cmd_reporterleaderboard(playerid, nextcmd);
            }
        }

        Dialog_ShowCallback(playerid, using inline LeaderboardNav, DIALOG_STYLE_TABLIST_HEADERS, title, dialogstr, "Next Page", "Close");
    }

    MySQL_TQueryInline(mysql, using inline LeaderboardQuery, query, "");
    return true;
}

//  /outletleaderboard  [page]
//  Ranks outlets (Media firms) themselves, not individual reporters -
//  Rank | Outlet | Reporters | Broadcasts | Air Time | Avg Peak
CMD:outletleaderboard(playerid, params[])
{
    if (!IsPlayerInNewsFaction(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a news faction to view the leaderboard.");

    new page = 0;
    sscanf(params, "i", page);
    if (page < 0) page = 0;

    new offset = page * 20;
    new query[512];

    mysql_format(mysql, query, sizeof(query),
        "SELECT \
            `broadcaster_outlet`, \
            COUNT(DISTINCT `broadcaster_name`) AS `reporter_count`, \
            COUNT(*)                           AS `total_broadcasts`, \
            SUM(`duration_seconds`)            AS `total_airtime`, \
            ROUND(AVG(`peak_listeners`), 0)    AS `avg_peak` \
         FROM `broadcast_history` \
         WHERE `broadcaster_outlet` != '' \
         GROUP BY `broadcaster_outlet` \
         ORDER BY `total_airtime` DESC \
         LIMIT 20 OFFSET %d",
        offset);

    inline OutletLeaderboardQuery()
    {
        new rows = cache_num_rows();

        if (!rows)
        {
            if (page == 0)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No outlet data found yet.");
            else
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No more outlets on the leaderboard.");
        }

        new dialogstr[2048];
        format(dialogstr, sizeof(dialogstr), "Rank\tOutlet\tReporters\tBroadcasts\tAir Time\tAvg Peak\n");

        new outletname[MAX_BROADCAST_OUTLET];
        new reportercount, totalbroadcasts, totalairtime, avgpeak;
        new airtimestr[12];

        for (new i = 0; i < rows; i++)
        {
            cache_get_value_name(i,     "broadcaster_outlet", outletname);
            cache_get_value_name_int(i, "reporter_count",     reportercount);
            cache_get_value_name_int(i, "total_broadcasts",   totalbroadcasts);
            cache_get_value_name_int(i, "total_airtime",      totalairtime);
            cache_get_value_name_int(i, "avg_peak",           avgpeak);

            FormatAirTime(totalairtime, airtimestr, sizeof(airtimestr));

            format(dialogstr, sizeof(dialogstr), "%s#%d\t%s\t%d\t%d\t%s\t%d\n",
                dialogstr,
                offset + i + 1,
                outletname,
                reportercount,
                totalbroadcasts,
                airtimestr,
                avgpeak);
        }

        new title[64];
        format(title, sizeof(title), "Outlet Leaderboard (Page %d)", page + 1);

        inline OutletLeaderboardNav(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused pid, dialogid, listitem, inputtext
            if (response)
            {
                new nextcmd[12];
                format(nextcmd, sizeof(nextcmd), "%d", page + 1);
                cmd_outletleaderboard(playerid, nextcmd);
            }
        }

        Dialog_ShowCallback(playerid, using inline OutletLeaderboardNav, DIALOG_STYLE_TABLIST_HEADERS, title, dialogstr, "Next Page", "Close");
    }

    MySQL_TQueryInline(mysql, using inline OutletLeaderboardQuery, query, "");
    return true;
}

// /mybroadcaststats - shows your broadcast statistics.
CMD:mybroadcaststats(playerid, params[])
{
    if (!IsPlayerInNewsFaction(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a news faction to view your stats.");

    new query[512];
    new playername[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playername, sizeof(playername));

    mysql_format(mysql, query, sizeof(query),
        "SELECT \
            COUNT(*)                        AS `total_broadcasts`, \
            SUM(`duration_seconds`)         AS `total_airtime`, \
            MAX(`peak_listeners`)           AS `best_peak`, \
            ROUND(AVG(`peak_listeners`), 0) AS `avg_peak`, \
            MAX(`duration_seconds`)         AS `longest_broadcast` \
         FROM `broadcast_history` \
         WHERE `broadcaster_name` = '%e'",
        playername);

    inline MyStatsQuery()
    {
        new rows = cache_num_rows();
        if (!rows)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No broadcast data found for your account.");

        new totalbroadcasts, totalairtime, bestpeak, avgpeak, longest;
        cache_get_value_name_int(0, "total_broadcasts",  totalbroadcasts);
        cache_get_value_name_int(0, "total_airtime",     totalairtime);
        cache_get_value_name_int(0, "best_peak",         bestpeak);
        cache_get_value_name_int(0, "avg_peak",          avgpeak);
        cache_get_value_name_int(0, "longest_broadcast", longest);

        new airtimestr[12], longeststr[12], str[128];
        FormatAirTime(totalairtime, airtimestr, sizeof(airtimestr));
        FormatAirTime(longest,      longeststr, sizeof(longeststr));

        SendClientMessage(playerid, 0x297183FF, "[ __________ Your Broadcast Stats __________ ]");

        format(str, sizeof(str), "Total Broadcasts: %d  |  Total Air Time: %s", totalbroadcasts, airtimestr);
        SendClientMessage(playerid, 0x58DD85FF, str);

        format(str, sizeof(str), "Best Peak Listeners: %d  |  Avg Peak: %d", bestpeak, avgpeak);
        SendClientMessage(playerid, 0x58DD85FF, str);

        format(str, sizeof(str), "Longest Single Broadcast: %s", longeststr);
        SendClientMessage(playerid, 0x58DD85FF, str);
    }

    MySQL_TQueryInline(mysql, using inline MyStatsQuery, query, "");
    return true;
}

// /tunein [player] - listen to a player's live broadcast.
CMD:tunein(playerid, params[])
{
    new targetid;
    if (sscanf(params, "k<player>", targetid))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/tunein [player]");

    if (!PlayerNewsVar[targetid][E_PLAYER_NEWS_BROADCASTING])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "This player isn't broadcasting.");

    if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must stop broadcasting first.");

    PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING]    = true;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO] = targetid;

    new tunein_outlet[MAX_BROADCAST_OUTLET];
    if (PlayerNewsVar[targetid][E_PLAYER_NEWS_OUTLET][0] != EOS)
        format(tunein_outlet, sizeof(tunein_outlet), "%s", PlayerNewsVar[targetid][E_PLAYER_NEWS_OUTLET]);
    else
        format(tunein_outlet, sizeof(tunein_outlet), "Independent");

    SendClientMessage(playerid, -1, sprintf("You're now listening to \"%s\" by %s (%s).",
        PlayerNewsVar[targetid][E_PLAYER_NEWS_BROADCAST_TITLE], ReturnSettingsName(targetid, playerid),
        tunein_outlet));
    return true;
}

// /tuneout - stop listening to a broadcast.
CMD:tuneout(playerid)
{
    if (!PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You aren't listening to a broadcast.");

    if (PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Co-anchors cannot tune out. Use /coanchor leave instead.");

    if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING])
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must stop broadcasting first.");

    PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING]    = false;
    PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO] = INVALID_PLAYER_ID;
    return true;
}

// /live [text] - speaks into a live broadcast so every listener hears it.
CMD:live(playerid, params[])
{
    new text[144], color = COLOR_ADV;

    if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_LIVE)
    {
        if (sscanf(params, "s[144]", text))
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/live [text]");
        if (strlen(text) < 3)
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/live [text]");

        ProxDetectorLive(playerid, playerid, 15.0, -1, COLOR_ADV, text);

        new currentListeners = CountListeners(playerid);
        if (currentListeners > PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS])
            PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS] = currentListeners;
    }
    else if (PlayerNewsVar[playerid][E_PLAYER_NEWS_IS_COANCHOR])
    {
        new broadcasterid = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR_OF];

        if (!IsPlayerConnected(broadcasterid) || PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_BROADCASTING] != BROADCAST_STATE_LIVE)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "The broadcast is not currently live.");

        if (sscanf(params, "s[144]", text))
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/live [text]");
        if (strlen(text) < 3)
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/live [text]");

        ProxDetectorLive(playerid, broadcasterid, 15.0, -1, COLOR_ADV, text);

        new currentListeners = CountListeners(broadcasterid);
        if (currentListeners > PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_PEAK_LISTENERS])
            PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_PEAK_LISTENERS] = currentListeners;
    }
    else
    {
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        new world   = GetPlayerVirtualWorld(playerid);
        new closest = INVALID_PLAYER_ID;
        new Float:current;
        new Float:last = 5.0;

        foreach (new i: Player)
        {
            if (i == playerid) continue;
            if (GetPlayerVirtualWorld(i) != world) continue;
            if (PlayerNewsVar[i][E_PLAYER_NEWS_BROADCASTING] != BROADCAST_STATE_LIVE) continue;

            current = GetPlayerDistanceFromPoint(i, x, y, z);
            if (current < last) { closest = i; last = current; }
        }

        if (!IsPlayerConnected(closest))
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You're not near any live broadcasters.");

        if (!PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING] || PlayerNewsVar[playerid][E_PLAYER_NEWS_LISTENING_TO] != closest)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be tuned in to this player's broadcast to speak on it.");

        if (sscanf(params, "s[128]", text))
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/live [text]");
        if (strlen(text) < 3)
            return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/live [text]");

        ProxDetectorLive(playerid, closest, 15.0, -1, COLOR_ADV, text);
    }

    if (strlen(text))
        SetPlayerChatBubble(playerid, sprintf("(live) %s", text), color, 15.0, (strlen(text) * 50) + 2500);

    return true;
}

// /newsroom - shows the outlet's reporters and their status.
CMD:newsroom(playerid, params[])
{
    if (!IsPlayerInNewsFaction(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a news faction to use this.");

    new dialogstr[2048];
    format(dialogstr, sizeof(dialogstr), "Reporter\tOutlet\tStatus\tBroadcast Title\tListeners\n");

    new onduty = 0;

    foreach (new i: Player)
    {
        if (!IsPlayerPlaying(i)) continue;
        if (!IsPlayerInNewsFaction(i, true)) continue;

        new statusstr[16];
        new titlestr[MAX_BROADCAST_TITLE];
        new listenerstr[8];

        if (PlayerNewsVar[i][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_LIVE)
        {
            format(statusstr, sizeof(statusstr), "LIVE");
            format(titlestr,  sizeof(titlestr),  "%s", PlayerNewsVar[i][E_PLAYER_NEWS_BROADCAST_TITLE]);
            format(listenerstr, sizeof(listenerstr), "%d", CountListeners(i));
        }
        else if (PlayerNewsVar[i][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_PAUSED)
        {
            format(statusstr, sizeof(statusstr), "Paused");
            format(titlestr,  sizeof(titlestr),  "%s", PlayerNewsVar[i][E_PLAYER_NEWS_BROADCAST_TITLE]);
            format(listenerstr, sizeof(listenerstr), "%d", CountListeners(i));
        }
        else if (PlayerNewsVar[i][E_PLAYER_NEWS_IS_COANCHOR])
        {
            new broadcasterid = PlayerNewsVar[i][E_PLAYER_NEWS_COANCHOR_OF];
            format(statusstr, sizeof(statusstr), "Co-Anchor");
            if (IsPlayerConnected(broadcasterid))
                format(titlestr, sizeof(titlestr), "%s", PlayerNewsVar[broadcasterid][E_PLAYER_NEWS_BROADCAST_TITLE]);
            else
                format(titlestr, sizeof(titlestr), "-");
            format(listenerstr, sizeof(listenerstr), "-");
        }
        else
        {
            format(statusstr,   sizeof(statusstr),   "Idle");
            format(titlestr,    sizeof(titlestr),     "-");
            format(listenerstr, sizeof(listenerstr), "-");
        }

        new outletname[MAX_BROADCAST_OUTLET];
        GetPlayerOutletName(i, outletname, sizeof(outletname));
        if (outletname[0] == EOS) format(outletname, sizeof(outletname), "Independent");

        format(dialogstr, sizeof(dialogstr), "%s%s\t%s\t%s\t%s\t%s\n",
            dialogstr, ReturnRPName(i), outletname, statusstr, titlestr, listenerstr);

        onduty++;
    }

    if (!onduty)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No news reporters are currently on duty.");

    new title[64];
    format(title, sizeof(title), "Newsroom | %d Reporter%s On Duty", onduty, (onduty == 1) ? "" : "s");

    inline NewsroomClose(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, response, listitem, inputtext
    }

    Dialog_ShowCallback(playerid, using inline NewsroomClose, DIALOG_STYLE_TABLIST_HEADERS, title, dialogstr, "Close", "");
    return true;
}

// /weeklyactivity - shows the news faction's weekly activity leaderboard.
CMD:weeklyactivity(playerid, params[])
{
    if (!IsPlayerInNewsFaction(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be in a news faction to view this.");

    new page = 0;
    sscanf(params, "i", page);
    if (page < 0) page = 0;

    new offset  = page * 20;
    new weekago = gettime() - 604800;
    new query[512];

    mysql_format(mysql, query, sizeof(query),
        "SELECT \
            `broadcaster_name`, \
            `broadcaster_outlet`, \
            COUNT(*)                        AS `total_broadcasts`, \
            SUM(`duration_seconds`)         AS `total_airtime`, \
            ROUND(AVG(`peak_listeners`), 0) AS `avg_peak`, \
            MAX(`end_time`)                 AS `last_active` \
         FROM `broadcast_history` \
         WHERE `start_time` >= %d \
         GROUP BY `broadcaster_name`, `broadcaster_outlet` \
         ORDER BY `total_airtime` DESC \
         LIMIT 20 OFFSET %d",
        weekago, offset);

    inline WeeklyActivityQuery()
    {
        new rows = cache_num_rows();

        if (!rows)
        {
            if (page == 0)
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No broadcast activity in the past 7 days.");
            else
                return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "No more entries.");
        }

        new dialogstr[2560];
        format(dialogstr, sizeof(dialogstr), "Reporter\tOutlet\tBroadcasts\tAir Time\tAvg Peak\tLast Active\n");

        new reportername[MAX_PLAYER_NAME];
        new reporteroutlet[MAX_BROADCAST_OUTLET];
        new totalbroadcasts, totalairtime, avgpeak, lastactive;
        new airtimestr[12], lastactivestr[12];

        for (new i = 0; i < rows; i++)
        {
            cache_get_value_name(i,     "broadcaster_name",   reportername);
            cache_get_value_name(i,     "broadcaster_outlet", reporteroutlet);
            cache_get_value_name_int(i, "total_broadcasts",   totalbroadcasts);
            cache_get_value_name_int(i, "total_airtime",      totalairtime);
            cache_get_value_name_int(i, "avg_peak",           avgpeak);
            cache_get_value_name_int(i, "last_active",        lastactive);

            if (reporteroutlet[0] == EOS) format(reporteroutlet, sizeof(reporteroutlet), "Independent");

            FormatAirTime(totalairtime, airtimestr,    sizeof(airtimestr));
            UnixToDateStr(lastactive,   lastactivestr, sizeof(lastactivestr));

            format(dialogstr, sizeof(dialogstr), "%s%s\t%s\t%d\t%s\t%d\t%s\n",
                dialogstr, reportername, reporteroutlet, totalbroadcasts, airtimestr, avgpeak, lastactivestr);
        }

        new title[80];
        format(title, sizeof(title), "Weekly Activity (Page %d)", page + 1);

        inline WeeklyNav(pid, dialogid, response, listitem, string:inputtext[])
        {
            #pragma unused pid, dialogid, listitem, inputtext
            if (response)
            {
                new nextcmd[12];
                format(nextcmd, sizeof(nextcmd), "%d", page + 1);
                cmd_weeklyactivity(playerid, nextcmd);
            }
        }

        Dialog_ShowCallback(playerid, using inline WeeklyNav, DIALOG_STYLE_TABLIST_HEADERS, title, dialogstr, "Next Page", "Close");
    }

    MySQL_TQueryInline(mysql, using inline WeeklyActivityQuery, query, "");
    return true;
}

hook OnPlayerUpdate(playerid)
{
    if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] != BROADCAST_STATE_NONE)
    {
        if (IsPlayerIncapacitated(playerid, false))
        {
            SaveBroadcastHistory(playerid, gettime());

            new coanchor = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR];
            if (IsPlayerConnected(coanchor))
                SendClientMessage(coanchor, COLOR_SERVER, "[NEWS] The broadcaster was incapacitated. Your co-anchor role has ended.");

            ResetBroadcasterState(playerid);
            SendClientMessage(playerid, -1, "Your news broadcast was interrupted.");
        }

        if (PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCASTING] == BROADCAST_STATE_LIVE)
        {
            new currentListeners = CountListeners(playerid);
            if (currentListeners > PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS])
                PlayerNewsVar[playerid][E_PLAYER_NEWS_PEAK_LISTENERS] = currentListeners;

            new coanchor = PlayerNewsVar[playerid][E_PLAYER_NEWS_COANCHOR];
            new coanchorstr[48];
            if (IsPlayerConnected(coanchor))
                format(coanchorstr, sizeof(coanchorstr), " | Co-Anchor: %s", ReturnRPName(coanchor));

            SetPlayerChatBubble(playerid,
                sprintf("(( Broadcasting \"%s\"%s [ /live to speak | /broadcasts to listen ] ))",
                    PlayerNewsVar[playerid][E_PLAYER_NEWS_BROADCAST_TITLE],
                    coanchorstr),
                COLOR_SERVER, 7.5, 7500);
        }
    }
    return 1;
}

// Sends a broadcast line to everyone near the broadcaster and to every listener.
static ProxDetectorLive(playerid, broadcasterid, Float:range, local_color, remote_color, text[])
{
    new Float:distance;
    new color;
    new Float:senderpos[3];
    new Float:broadcastpos[3];
    new Float:distancescaled;
    new str[512];
    new colorvalue;

    GetPlayerPos(playerid,      senderpos[0],    senderpos[1],    senderpos[2]);
    GetPlayerPos(broadcasterid, broadcastpos[0], broadcastpos[1], broadcastpos[2]);

    foreach (new i: Player)
    {
        if (PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING] && PlayerNewsVar[i][E_PLAYER_NEWS_LISTENING_TO] == broadcasterid)
        {
            // tuned in listeners listen with no distance check
            color = remote_color;
            format(str, sizeof(str), "[LIVE] %s says: %s", ReturnSettingsName(playerid, i), text);
            ZMsg_SendClientMessage(i, color, str);
        }
        else
        {
            //not tuned in yet close, check proximity to sender AND broadcaster, take closest
            new Float:distFromSender      = GetPlayerDistanceFromPoint(i, senderpos[0],    senderpos[1],    senderpos[2]);
            new Float:distFromBroadcaster = GetPlayerDistanceFromPoint(i, broadcastpos[0], broadcastpos[1], broadcastpos[2]);
            distance = (distFromSender < distFromBroadcaster) ? distFromSender : distFromBroadcaster;

            color = local_color;
            format(str, sizeof(str), "%s says [live]: %s", ReturnSettingsName(playerid, i), text);

            if (distance <= range)
            {
                distancescaled = (distance / range);
                new colormod = floatround(distancescaled * 128.0);

                new r = ((color >> 24) & 0xFF);
                new g = ((color >> 16) & 0xFF);
                new b = ((color >> 8)  & 0xFF);

                new cr = r - colormod;
                new cg = g - colormod;
                new cb = b - colormod;

                if (cr < 0) cr = 0;
                if (cg < 0) cg = 0;
                if (cb < 0) cb = 0;

                colorvalue = ((cr & 0xFF) << 24) + ((cg & 0xFF) << 16) + ((cb & 0xFF) << 8);
                ZMsg_SendClientMessage(i, colorvalue, str);
            }
        }
    }
}

// Writes the text for a broadcast state (None, Live...).
GetBroadcastState(broadcastState)
{
    new output[10];
    switch (broadcastState)
    {
        case BROADCAST_STATE_NONE:   format(output, sizeof(output), "None");
        case BROADCAST_STATE_LIVE:   format(output, sizeof(output), "Live");
        case BROADCAST_STATE_PAUSED: format(output, sizeof(output), "Paused");
    }
    return output;
}

/*
CREATE TABLE IF NOT EXISTS `broadcast_history` (
    `id`                  INT          NOT NULL AUTO_INCREMENT,
    `broadcaster_name`    VARCHAR(24)  NOT NULL,
    `broadcast_title`     VARCHAR(64)  NOT NULL,
    `broadcaster_outlet`  VARCHAR(16)  NOT NULL DEFAULT '',  -- Media firm/News faction abbrev at broadcast time, '' = independent
    `start_time`          INT UNSIGNED NOT NULL,
    `end_time`            INT UNSIGNED NOT NULL,
    `duration_seconds`    INT UNSIGNED NOT NULL DEFAULT 0,
    `peak_listeners`      INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    INDEX `idx_broadcaster` (`broadcaster_name`),    -- leaderboard GROUP BY
    INDEX `idx_outlet`      (`broadcaster_outlet`),  -- outlet leaderboard GROUP BY
    INDEX `idx_start_time`  (`start_time`)           -- history ORDER BY
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Migration for an existing broadcast_history table:
ALTER TABLE `broadcast_history`
  ADD COLUMN `broadcaster_outlet` VARCHAR(16) NOT NULL DEFAULT '' AFTER `broadcast_title`,
  ADD INDEX `idx_outlet` (`broadcaster_outlet`);
*/
