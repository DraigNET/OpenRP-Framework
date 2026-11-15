// ============================================================================
// File: player/auth/auth.pwn
// Login flow: loads the account when a player connects, asks for the password (bcrypt check in
// OnPlayerAttemptLogin), handles shared-IP warnings and continues to character select.
// ============================================================================


// Shows the login screen: sets the camera, music, and asks for the password (or shows a message
// for an error).
timer LoginWindow[1000](playerid, error_type)
{
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);

    SetPlayerCameraPos(playerid, 1249.8152, 245.8091, 51.6187); // Red County (stock map)
    SetPlayerCameraLookAt(playerid, 1250.7855, 246.0839, 51.2888);

    PlayerVar[playerid][E_PLAYER_CREATING_CHAR] = false;
    PlayerVar[playerid][E_PLAYER_FIRST_SPAWN] = true;

    inline LoginForm(pid, dialogid, response, listitem, string:inputtext[])
    {
		#pragma unused pid, dialogid, response, listitem, inputtext

        new query[512];

        if (! response)
        {

            Kick(playerid) ;
        }

        else if (response)
        {

            if (strlen(inputtext) <= 5)
            {
                LoginWindow(playerid, AUTH_MSG_WRONG_LENGTH);
                SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "Your password may not be less than 5 characters.");
                return true;
            }
            print("Response");
            mysql_format(mysql, query, sizeof(query), "SELECT * FROM accounts WHERE account_name = '%e'", TEMP_ReturnPlayerName(playerid));
            print("SELECT FROM accounts");
            inline AccountCheck()
            {
                print("AccountCheck");
                if (cache_num_rows())
                {
                    cache_get_value_name_int(0, "account_id", Account [ playerid ] [ E_PLAYER_ACCOUNT_ID ]);

                    cache_get_value_name_int(0, "account_namestyle", Account [ playerid ] [ E_PLAYER_ACCOUNT_NAMESTYLE ]);

                    cache_get_value_name(0, "account_name", Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ]);
                    cache_get_value_name(0, "account_password", Account [ playerid ] [ E_PLAYER_ACCOUNT_PASSWORD ]);
                    //cache_get_value_name( 0, "account_salt", Account [ playerid ] [ E_PLAYER_ACCOUNT_PASSSALT ]);

                    cache_get_value_name_int(0, "account_supporter", Account [ playerid ] [ E_PLAYER_ACCOUNT_SUPPORTER ]);
                    cache_get_value_name_int(0, "account_stafflevel", Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ]);
                    cache_get_value_name_int(0, "account_contributor", Account [ playerid ] [ E_PLAYER_ACCOUNT_CONTRIBUTOR ]);
                    cache_get_value_name_int(0, "account_premiumlevel", Account [ playerid ] [ E_PLAYER_ACCOUNT_PREMIUMLEVEL]);

                    cache_get_value_name_int(0, "password_reset_version", Account[playerid][E_PLAYER_ACCOUNT_PWRESET_VER]);

                    cache_get_value_name_int(0, "account_reports_done", Account [ playerid ] [ E_PLAYER_ACCOUNT_REPORTS_DONE ]);
                    cache_get_value_name_int(0, "account_questions_done", Account [ playerid ] [ E_PLAYER_ACCOUNT_QUESTIONS_DONE ]);

                    cache_get_value_name_int(0, "account_gunaccess", Account [ playerid ] [ E_PLAYER_ACCOUNT_GUNACCESS ]);
                    cache_get_value_name_int(0, "account_gunban", Account [ playerid ] [ E_PLAYER_ACCOUNT_GUNBAN ]);

                    cache_get_value_name_int(0, "account_facban", Account [ playerid ] [ E_PLAYER_ACCOUNT_FACBAN ]);

                    cache_get_value_name_int(0, "account_sprintban", Account [ playerid ] [ E_PLAYER_ACCOUNT_SPRINTBAN ]);

                    cache_get_value_name(0, "account_forumname", Account [ playerid ] [ E_PLAYER_ACCOUNT_FORUMNAME ]);
                    cache_get_value_name(0, "account_discordname", Account [ playerid ] [ E_PLAYER_ACCOUNT_DISCORDNAME ]);
                    cache_get_value_name_int(0, "discord_verified", Account [ playerid ] [ E_PLAYER_DISCORD_VERIFIED ]);
                    cache_get_value_name_int(0, "account_quiz_passed", Account [ playerid ] [ E_PLAYER_ACCOUNT_QUIZ_PASSED ]);
                    cache_get_value_name(0, "account_email", Account [ playerid ] [ E_PLAYER_ACCOUNT_EMAIL ]);

                    cache_get_value_name_int(0, "account_setting_tips", Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_TIPS ]);
                    cache_get_value_name_int(0, "account_setting_gangzones", Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_GZES ]);
                    cache_get_value_name_int(0, "account_setting_blinkers", Account [ playerid ] [ E_PLAYER_ACCOUNT_SETTINGS_BLNK ]);

                    cache_get_value_name_int(0, "account_reward_amount", Account [ playerid ] [ E_PLAYER_ACCOUNT_REWARD_AMOUNT]);
                    cache_get_value_name_int(0, "account_reward_claimed", Account [ playerid ] [ E_PLAYER_ACCOUNT_REWARD_CLAIMED]);

                    cache_get_value_name(0, "account_reward_ipaddress", Account [ playerid ] [ E_PLAYER_ACCOUNT_REWARD_IP ]);
                    cache_get_value_name_int(0, "account_rppoints", Account[playerid][E_PLAYER_ACCOUNT_RPPOINTS]);

                    // STREAMER SETTINGS
                    cache_get_value_name_int(0, "account_ddsetting", Account[playerid][E_PLAYER_ACCOUNT_DDSETTING]);
                    cache_get_value_name_int(0, "account_ddmessage", Account[playerid][E_PLAYER_ACCOUNT_DDMESSAGE]);

                    cache_get_value_name(0, "admin_message", Account[playerid][E_PLAYER_ACCOUNT_ADMIN_MESSAGE]);
                    if (!strcmp(Account[playerid][E_PLAYER_ACCOUNT_ADMIN_MESSAGE], "NULL"))
                        Account[playerid][E_PLAYER_ACCOUNT_ADMIN_MESSAGE][0] = EOS;
 
                    cache_get_value_name(0, "admin_motd_1",         Server[E_SERVER_ADMIN_MOTD_STRING_1]);
                    cache_get_value_name(0, "admin_motd_2",         Server[E_SERVER_ADMIN_MOTD_STRING_2]);
                    cache_get_value_name(0, "admin_motd_3",         Server[E_SERVER_ADMIN_MOTD_STRING_3]);
                    cache_get_value_name(0, "admin_motd_editor",    Server[E_SERVER_ADMIN_MOTD_EDITOR]);
                    cache_get_value_name_int(0, "admin_motd_time",  Server[E_SERVER_ADMIN_MOTD_EDIT_TIME]);

#if defined FEATURE_EMMET
                    print("Loading Emmet cooldowns...");
                    // Load emmet cooldowns (per account)
                    Emmet_LoadPlayerEntities(playerid);
#endif

                    print("Set used logout");
                    SetPVarInt(playerid, "Used_logout", false);
#if defined FEATURE_GANGZONES
                    GangZone_ShowForPlayer(playerid);
                    print("Shown gangzones for player");
#endif

                    // Adding a fix for spec!
                    Character [ playerid ] [ E_CHARACTER_MOLE ] = INVALID_PLAYER_ID ;
                    PlayerVar [ playerid ] [ E_PLAYER_IS_SPECTATING ] = INVALID_PLAYER_ID ;
                    PlayerVar [ playerid ] [ E_PLAYER_LISTEN ] = INVALID_PLAYER_ID ;
                    PlayerVar [ playerid ] [ E_PLAYER_CHOSE_CHARACTER ] = false ;
                    Character [ playerid ] [ E_CHARACTER_ID ] = -1 ;
                    print("Adding fixes for spec");

                    // Do passwords match?
                    print("OnPlayerAttemptLogin");
                    bcrypt_verify(playerid, "OnPlayerAttemptLogin", inputtext, Account[playerid][E_PLAYER_ACCOUNT_PASSWORD]);
                }
                else
                {
                    print("OnPlayerAttemptRegister");
                    //if (Server[E_SERVER_ACCS_DISABLED_UNTIL] && gettime() < Server[E_SERVER_ACCS_DISABLED_UNTIL])
                    //{
                    SendClientMessage(playerid, COLOR_ERROR, "New accounts must be registered on the UCP.");
                    SendClientMessage(playerid, COLOR_GRAD1, "visit " SERVER_WEBSITE " to register!");
                    KickPlayer(playerid);
                    return 1;
                    //}
                    //bcrypt_hash(playerid, "OnPlayerAttemptRegister", inputtext, BCRYPT_COST);
                }
            }

            MySQL_TQueryInline(mysql, using inline AccountCheck, query, "") ;
        }
        return true ;
    }

    new string [ 768 ] ; // 576A8F  9CC6DB 70B2B2

    format(string, sizeof(string), "{FFFFFF}Welcome to {E8C96A}" SERVER_NAME "{DEDEDE}, %s!\n\n{FFFFFF}In order to proceed, enter a {DAB785}password{DEDEDE} below to authenticate. \nYou can create a new character directly on the {70A288}UCP @ " SERVER_WEBSITE "\n\n",
           TEMP_ReturnPlayerName(playerid)) ;

    switch (error_type)
    {

        case AUTH_MSG_DEFAULT: strcat(string, "{FFFFFF}Adherence to the server {C49F25}/rules {FFFFFF}is essential for smooth gameplay.");   // please enter your password below
        case AUTH_MSG_WRONG_PASS: strcat(string, "{FFFFFF}The password you have entered is {E03232}incorrect{DEDEDE}. Please try again.");   // the password you entered is incorrect
        case AUTH_MSG_WRONG_LENGTH: strcat(string, "{FFFFFF}The password you have entered is {E03232}too short{DEDEDE}. It must be longer than 5 characters.");   // the password you entered is incorrect
    }

    // if login attempts != 0, show login attempts
    // add timer here to kick player if no log in after x amount of time

    Dialog_ShowCallback(playerid, using inline LoginForm, DIALOG_STYLE_PASSWORD, SERVER_NAME " - (Login)", string, "Proceed", "Cancel") ;

    return true ;
}


// Pure-Pawn equivalent of ^[A-Z][a-z]+_[A-Z][a-z]{0,2}[A-Z]{0,1}[a-z]*$
// (was Regex_New/Regex_Check -- pawnregex.so crashes the server on some input).
// Adjacent classes are disjoint (upper/lower/underscore) so greedy matching
// needs no backtracking and this is an exact translation.
IsRPNameRegex(const propname[])
{
    new i = 0;

    // [A-Z]
    if (!(propname[i] >= 'A' && propname[i] <= 'Z')) return false;
    i++;

    // [a-z]+
    if (!(propname[i] >= 'a' && propname[i] <= 'z')) return false;
    while (propname[i] >= 'a' && propname[i] <= 'z') i++;

    // _
    if (propname[i] != '_') return false;
    i++;

    // [A-Z]
    if (!(propname[i] >= 'A' && propname[i] <= 'Z')) return false;
    i++;

    // [a-z]{0,2}
    for (new n = 0; n < 2 && propname[i] >= 'a' && propname[i] <= 'z'; n++) i++;

    // [A-Z]{0,1}
    if (propname[i] >= 'A' && propname[i] <= 'Z') i++;

    // [a-z]*
    while (propname[i] >= 'a' && propname[i] <= 'z') i++;

    // $
    return propname[i] == '\0';
}



// if(response[E_DIALOG_RESPONSE_Response]) bcrypt_verify(playerid, "OnPlayerAttemptLogin", response[E_DIALOG_RESPONSE_InputText], Account[playerid][PLAYER_ACCOUNT_PASSWORD]);


forward OnPlayerAttemptLogin(playerid, bool:success);
// bcrypt callback: the password check finished - continues the login or shows 'wrong password'.
public OnPlayerAttemptLogin(playerid, bool:success)
{
    if (!success)
    {

        LoginWindow(playerid, AUTH_MSG_WRONG_PASS);
        PlayerVar [ playerid ] [ player_islogged ] = false ;
        SendClientMessage(playerid, -1, "You have entered the INCORRECT password.");
    }

    else if (success)
    {
        // -------------------------------------------------
        // FORCE PASSWORD RESET CHECK
        // -------------------------------------------------
        if (Account[playerid][E_PLAYER_ACCOUNT_PWRESET_VER] < PASSWORD_RESET_REQUIRED_VERSION)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Security update required.");
            SendClientMessage(playerid, COLOR_GRAD1, "You must reset your password on the UCP before logging in.");
            SendClientMessage(playerid, COLOR_GRAD1, "Visit: " SERVER_WEBSITE "/ucp");

            PlayerVar[playerid][player_islogged] = false;
            PlayerVar[playerid][player_isregistered] = false;

            return KickPlayer(playerid);
        }

        // -------------------------------------------------
        // DISCORD VERIFIED CHECK
        // -------------------------------------------------
        #if FEATURE_REQUIRE_DISCORD_VERIFIED
        if (Account[playerid][E_PLAYER_DISCORD_VERIFIED] == 0)
        {
            SendClientMessage(playerid, COLOR_ERROR, "Discord verification required.");
            SendClientMessage(playerid, COLOR_GRAD1, "You must link your Discord account on the UCP before playing.");
            SendClientMessage(playerid, COLOR_GRAD1, "Visit: " SERVER_WEBSITE "/ucp");

            PlayerVar[playerid][player_islogged] = false;
            PlayerVar[playerid][player_isregistered] = false;

            return KickPlayer(playerid);
        }
        #endif

        // -------------------------------------------------
        // ACCOUNT QUIZ CHECK
        // -------------------------------------------------
        if (Account[playerid][E_PLAYER_ACCOUNT_QUIZ_PASSED] == 0)
        {
            SendClientMessage(playerid, COLOR_ERROR, "UCP quiz required.");
            SendClientMessage(playerid, COLOR_GRAD1, "You must pass the UCP quiz before logging in.");
            SendClientMessage(playerid, COLOR_GRAD1, "Visit: " SERVER_WEBSITE "/ucp");

            PlayerVar[playerid][player_islogged] = false;
            PlayerVar[playerid][player_isregistered] = false;

            return KickPlayer(playerid);
        }

        Account_CheckSharedIPLogin(playerid);
    }
    return 1;
}

// Checks whether another account is already logged in from the same IP and warns or blocks.
Account_CheckSharedIPLogin(playerid)
{
    new query[1536];

    mysql_format(mysql, query, sizeof(query),
        "SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM multiaccount_ip_whitelist w WHERE w.ip_address = '%e' AND (w.expires_at IS NULL OR w.expires_at = 0 OR w.expires_at > UNIX_TIMESTAMP())) AND NOT EXISTS (SELECT 1 FROM multiaccount_account_whitelist aw WHERE aw.account_id = %d AND (aw.expires_at IS NULL OR aw.expires_at = 0 OR aw.expires_at > UNIX_TIMESTAMP())) AND EXISTS (SELECT 1 FROM account_ip_history h INNER JOIN accounts ah ON ah.account_id = h.account_id WHERE h.ip_address = '%e' AND h.account_id != %d UNION SELECT 1 FROM accounts a WHERE a.account_id != %d AND TRIM(a.account_lastip) = '%e') LIMIT 1",
        ReturnIP(playerid),
        Account[playerid][E_PLAYER_ACCOUNT_ID],
        ReturnIP(playerid),
        Account[playerid][E_PLAYER_ACCOUNT_ID],
        Account[playerid][E_PLAYER_ACCOUNT_ID],
        ReturnIP(playerid)
    );

    inline SharedIPLoginCheck()
    {
        if (!IsPlayerConnected(playerid)) {
            return true;
        }

        if (cache_num_rows()) {
            mysql_format(mysql, query, sizeof(query),
                         "INSERT INTO account_ip_history (account_id, ip_address, first_seen, last_seen, access_count) VALUES (%d, '%e', %d, %d, 1) ON DUPLICATE KEY UPDATE last_seen = VALUES(last_seen), access_count = access_count + 1",
                         Account[playerid][E_PLAYER_ACCOUNT_ID],
                         ReturnIP(playerid),
                         gettime(),
                         gettime()
                        );
            mysql_tquery(mysql, query);

            SendClientMessage(playerid, COLOR_ERROR, "Login blocked. Please contact an admin in relation to multi-accounting.");
            SendClientMessage(playerid, COLOR_GRAD1, "Your connection matches another account on record.");

            SendAdminMessage(sprintf("[MULTI-ACCOUNT] %s (%s) was blocked from logging in due to a shared IP match.",
                Account[playerid][E_PLAYER_ACCOUNT_NAME],
                ReturnIP(playerid)
            ));

            PlayerVar[playerid][player_islogged] = false;
            PlayerVar[playerid][player_isregistered] = false;

            return KickPlayer(playerid);
        }

        return Account_ContinueLogin(playerid);
    }

    MySQL_TQueryInline(mysql, using inline SharedIPLoginCheck, query, "");
    return true;
}

// Marks the account online and continues to character selection.
Account_ContinueLogin(playerid)
{
    // -------------------------------------------------
    // NORMAL LOGIN CONTINUES
    // -------------------------------------------------
    new query[768];

    mysql_format(mysql, query, sizeof(query),
                 "UPDATE accounts SET account_lastip='%e', account_online = 1 WHERE account_id = %d",
                 ReturnIP(playerid),
                 Account[playerid][E_PLAYER_ACCOUNT_ID]
                );
    mysql_tquery(mysql, query);

    mysql_format(mysql, query, sizeof(query),
                 "INSERT INTO account_ip_history (account_id, ip_address, first_seen, last_seen, access_count) VALUES (%d, '%e', %d, %d, 1) ON DUPLICATE KEY UPDATE last_seen = VALUES(last_seen), access_count = access_count + 1",
                 Account[playerid][E_PLAYER_ACCOUNT_ID],
                 ReturnIP(playerid),
                 gettime(),
                 gettime()
                );
    mysql_tquery(mysql, query);

    PlayerVar[playerid][player_islogged] = true;
    PlayerVar[playerid][player_isregistered] = true;

    AC_RunScan(playerid);
    printf("Called AC_RunScan for (%d) %s", playerid, ReturnRPName(playerid));
    SetTimerEx("AC_OnFinishDetection", 5000, false, "i", playerid);
    LoadPlayerBlockedPMs(playerid);

    BanChecker(playerid);
    return true;
}

// Shows the welcome message with rank, staff status, MOTD and unread notices.
Player_SendLoginMessage(playerid)
{
    new str[256], rank[24], staff[32];

    GetPremiumRank (Account[playerid][E_PLAYER_ACCOUNT_PREMIUMLEVEL], rank, 24);
    GetAdminRankName(Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL],  staff, 32);

    SendClientMessage(playerid, -1, " ");

    format(str, sizeof(str),
        "{E3E3E3}Hey {00A6ED}%s{E3E3E3}. Welcome back to {E8C96A}" SERVER_NAME "{E3E3E3}!",
        Account[playerid][E_PLAYER_ACCOUNT_NAME]);
    SendClientMessage(playerid, -1, str);

    format(str, sizeof(str),
        "{E3E3E3}Playing as {129E87}%s | %s",
        ReturnRPName(playerid), rank);
    SendClientMessage(playerid, -1, str);

    if (Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL])
    {
        format(str, sizeof(str), "{BB691D}Staff Rank: %s", staff);
        SendClientMessage(playerid, -1, str);
    }   

    if (Server[E_SERVER_MOTD_EDIT_TIME])
    {
        
        if (strlen(Server[E_SERVER_MOTD_STRING_1]) > 1)
            SendClientMessage(playerid, 0xD38A2BFF, sprintf("[MOTD]: {FFFFFF}%s", Server[E_SERVER_MOTD_STRING_1]));
        if (strlen(Server[E_SERVER_MOTD_STRING_2]) > 1)
            SendClientMessage(playerid, 0xD38A2BFF, sprintf("[MOTD]: {FFFFFF}%s", Server[E_SERVER_MOTD_STRING_2]));
        if (strlen(Server[E_SERVER_MOTD_STRING_3]) > 1)
            SendClientMessage(playerid, 0xD38A2BFF, sprintf("[MOTD]: {FFFFFF}%s", Server[E_SERVER_MOTD_STRING_3]));

        // new year, month, day, hour, minute, second;
        // stamp2datetime(Server[E_SERVER_MOTD_EDIT_TIME], year, month, day, hour, minute, second, 1);
        // format(str, sizeof(str), "Last updated %s %d, %d", date_getMonth(month), day, year);
        // SendClientMessage(playerid, 0xFAF5DAFF, str);
        
    }

    if (GetPlayerAdminLevel(playerid) >= 1 && Server[E_SERVER_ADMIN_MOTD_EDIT_TIME])
    {
        if (strlen(Server[E_SERVER_ADMIN_MOTD_STRING_1]) > 1)
            SendClientMessage(playerid, 0xFA7C59FF, sprintf("[Admin MOTD]: {FFFFFF}%s", Server[E_SERVER_ADMIN_MOTD_STRING_1]));
        if (strlen(Server[E_SERVER_ADMIN_MOTD_STRING_2]) > 1)
            SendClientMessage(playerid, 0xFA7C59FF, sprintf("[Admin MOTD]: {FFFFFF}%s", Server[E_SERVER_ADMIN_MOTD_STRING_2]));
        if (strlen(Server[E_SERVER_ADMIN_MOTD_STRING_3]) > 1)
            SendClientMessage(playerid, 0xFA7C59FF, sprintf("[Admin MOTD]: {FFFFFF}%s", Server[E_SERVER_ADMIN_MOTD_STRING_3]));

        // format(str, sizeof(str), "Set by %s", Server[E_SERVER_ADMIN_MOTD_EDITOR]);
        // SendClientMessage(playerid, 0xF7C483FF, str);

    }

    if (strlen(Account[playerid][E_PLAYER_ACCOUNT_ADMIN_MESSAGE]) > 1)
    {
        SendClientMessage(playerid, 0x750404FF, sprintf("[Admin Message]: %s", Account[playerid][E_PLAYER_ACCOUNT_ADMIN_MESSAGE]));
        GameTextForPlayer(playerid, "~n~~n~~w~YOU HAVE A PENDING ~r~ADMIN MESSAGE~w~ TO READ", 5000, 3);
        PlayerPlaySound(playerid, 1085, 0.0, 0.0, 0.0);
    }

    if (GetPlayerAdminLevel(playerid) >= 1)
    {
        new report_count = 0, questions_count = 0;

        foreach (new i : Player)
        {
            if (PlayerVar[i][E_PLAYER_REPORT_PENDING])   report_count++;
            if (PlayerVar[i][E_PLAYER_QUESTION_PENDING]) questions_count++;
        }

        new string[144];

        if (report_count && questions_count)
            format(string, sizeof(string), "{F6511D}%d report(s){DEDEDE} and {7FB800}%d question(s){DEDEDE} pending.", report_count, questions_count);
        else if (report_count)
            format(string, sizeof(string), "{F6511D}%d report(s){DEDEDE} pending.", report_count);
        else if (questions_count)
            format(string, sizeof(string), "{7FB800}%d question(s){DEDEDE} pending.", questions_count);
        else
            format(string, sizeof(string), "No reports or questions pending.");

        if (IsPlayerHelper(playerid, .allow_admin = false) && questions_count)
        {
            string[0] = EOS;
            format(string, sizeof(string), "{7FB800}%d question(s){DEDEDE} pending.", questions_count);
        }

        SendServerMessage(playerid, 0xED801AFF, "Staff", "DEDEDE", string);
    }

    return true;
}



