// ============================================================================
// File: phone/func/texting.pwn
// SMS: sending texts (/sms), inbox and sentbox (/inbox, /sentbox), notifications and message
// dialogs.
// Commands: /inbox /sentbox
// ============================================================================

#define SMS_MAX_LENGTH      ( 128 )
#define MAX_SENT_SMS        ( 128 )
#define MAX_INBOX_SMS       ( 128 )
#define MAX_STORED_SMS      ( MAX_SENT_SMS + MAX_INBOX_SMS )

enum E_PLAYER_SMS_DATA {
    E_SMS_SQLID,
    E_SMS_CHAR_ID,
    E_SMS_RECEIVER,
    E_SMS_SENDER,
    E_SMS_DATA_TYPE,
    E_SMS_TEXT [ SMS_MAX_LENGTH ],
    E_SMS_DATE,
    E_SMS_READ
} ;

new PhoneSMS [ MAX_PLAYERS ] [ MAX_STORED_SMS ] [ E_PLAYER_SMS_DATA ] ;
new PhoneSentSMS [ MAX_PLAYERS ] [ MAX_SENT_SMS ] [ E_PLAYER_SMS_DATA ] ;

new player_sms_count [ MAX_PLAYERS ] ;
new player_sent_sms_count [ MAX_PLAYERS ] ;

enum {
    SMS_DATA_TYPE_INBOX,
    SMS_DATA_TYPE_SENT
} ;

// /inbox - opens the SMS inbox.
CMD:inbox(playerid, params[]) {
    #pragma unused params
    if (!Character[playerid][E_CHARACTER_PHONE_NUMBER])
        return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "You don't have a phone!") ;
    if (!PlayerVar[playerid][E_PLAYER_PHONE_STATUS])
        return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Your phone is turned off!") ;
    SMS_DisplayInbox_SQL(playerid) ;
    return true ;
}

// /sentbox - opens the sent messages.
CMD:sentbox(playerid, params[]) {
    #pragma unused params
    if (!Character[playerid][E_CHARACTER_PHONE_NUMBER])
        return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "You don't have a phone!") ;
    if (!PlayerVar[playerid][E_PLAYER_PHONE_STATUS])
        return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Your phone is turned off!") ;
    SMS_DisplaySentbox_SQL(playerid) ;
    return true ;
}

// Loads the player's received texts from the database.
SMS_DisplayInbox_SQL(playerid) {

    for (new i ; i < MAX_STORED_SMS ; i++)
        PhoneSMS[playerid][i][E_SMS_SQLID] = 0 ;
    player_sms_count[playerid] = 0 ;

    new query[256 + SMS_MAX_LENGTH] ;
    mysql_format(mysql, query, sizeof(query),
        "SELECT * FROM sms WHERE sms_character_id = %d AND sms_data_type = %d ORDER BY sms_date DESC",
        Character[playerid][E_CHARACTER_ID], SMS_DATA_TYPE_INBOX) ;

    inline phone_inbox_sql() {
        new r = cache_num_rows() ;
        if (r) {
            for (new i = 0 ; i < r ; i++) {
                if (i >= MAX_INBOX_SMS) {
                    SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                        "Your inbox is full (128 messages). Delete old texts to make space.") ;
                    break ;
                }
                cache_get_value_name_int(i, "sms_id",              PhoneSMS[playerid][i][E_SMS_SQLID]) ;
                cache_get_value_name_int(i, "sms_character_id",    PhoneSMS[playerid][i][E_SMS_CHAR_ID]) ;
                cache_get_value_name_int(i, "sms_sender",          PhoneSMS[playerid][i][E_SMS_SENDER]) ;
                cache_get_value_name_int(i, "sms_receiver_charid", PhoneSMS[playerid][i][E_SMS_RECEIVER]) ;
                cache_get_value_name_int(i, "sms_data_type",       PhoneSMS[playerid][i][E_SMS_DATA_TYPE]) ;
                cache_get_value_name_int(i, "sms_date",            PhoneSMS[playerid][i][E_SMS_DATE]) ;
                cache_get_value_name_int(i, "sms_read",            PhoneSMS[playerid][i][E_SMS_READ]) ;
                cache_get_value_name    (i, "sms_text",            PhoneSMS[playerid][i][E_SMS_TEXT]) ;
                player_sms_count[playerid]++ ;
            }
            SMS_DisplayInbox(playerid) ;
        }
        else {
            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Your inbox is empty.") ;
        }
    }

    MySQL_TQueryInline(mysql, using inline phone_inbox_sql, query, "") ;
    return true ;
}

// Loads the player's sent texts from the database.
SMS_DisplaySentbox_SQL(playerid) {

    for (new i ; i < MAX_SENT_SMS ; i++)
        PhoneSentSMS[playerid][i][E_SMS_SQLID] = 0 ;
    player_sent_sms_count[playerid] = 0 ;

    new query[256 + SMS_MAX_LENGTH] ;
    mysql_format(mysql, query, sizeof(query),
        "SELECT * FROM sms WHERE sms_character_id = %d AND sms_data_type = %d ORDER BY sms_date DESC",
        Character[playerid][E_CHARACTER_ID], SMS_DATA_TYPE_SENT) ;

    inline phone_sentbox_sql() {
        new r = cache_num_rows() ;
        if (r) {
            for (new i = 0 ; i < r ; i++) {
                if (i >= MAX_SENT_SMS) {
                    SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                        "Your sent box is full (128 messages). Delete old texts to make space.") ;
                    break ;
                }
                cache_get_value_name_int(i, "sms_id",              PhoneSentSMS[playerid][i][E_SMS_SQLID]) ;
                cache_get_value_name_int(i, "sms_character_id",    PhoneSentSMS[playerid][i][E_SMS_CHAR_ID]) ;
                cache_get_value_name_int(i, "sms_sender",          PhoneSentSMS[playerid][i][E_SMS_SENDER]) ;
                cache_get_value_name_int(i, "sms_receiver_charid", PhoneSentSMS[playerid][i][E_SMS_RECEIVER]) ;
                cache_get_value_name_int(i, "sms_data_type",       PhoneSentSMS[playerid][i][E_SMS_DATA_TYPE]) ;
                cache_get_value_name_int(i, "sms_date",            PhoneSentSMS[playerid][i][E_SMS_DATE]) ;
                cache_get_value_name_int(i, "sms_read",            PhoneSentSMS[playerid][i][E_SMS_READ]) ;
                cache_get_value_name    (i, "sms_text",            PhoneSentSMS[playerid][i][E_SMS_TEXT]) ;
                player_sent_sms_count[playerid]++ ;
            }
            SMS_DisplaySentbox(playerid) ;
        }
        else {
            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Your sent box is empty.") ;
        }
    }

    MySQL_TQueryInline(mysql, using inline phone_sentbox_sql, query, "") ;
    return true ;
}

// Shows the inbox page.
SMS_DisplayInbox(playerid) {

    if (PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE] == 0)
        PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE] = 1 ;

    if (PlayerVar[playerid][E_PLAYER_PHONE_ALERT_TICKS] > 0)
        PlayerVar[playerid][E_PLAYER_PHONE_CHECKED_INBOX] = true ;

    PlayerTextDrawHide (playerid, ptd_ph_design[playerid][8]) ;
    PlayerTextDrawColor(playerid, ptd_ph_design[playerid][8], 0xDEDEDEFF) ;
    PlayerTextDrawShow (playerid, ptd_ph_design[playerid][8]) ;

    for (new i = 0, j = 3 ; i < j ; i++)
        PlayerTextDrawHide(playerid, ptd_ph_popup[playerid][i]) ;

    new const MAX_ITEMS_ON_PAGE = 10 ;
    new string[1536], bool:nextpage, bool:unread_msg ;

    new start_index = (PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE] - 1) * MAX_ITEMS_ON_PAGE ;
    new items_shown = 0 ;
    new date_str[64], year, month, day, hour, minute, second ;
    new total_inbox = player_sms_count[playerid] ;

    strcat(string, "From\tDate\tMessage\n") ;

    for (new i = start_index ; i < total_inbox ; i++) {

        if (PhoneSMS[playerid][i][E_SMS_SQLID] == 0) continue ;
        if (items_shown >= MAX_ITEMS_ON_PAGE) { nextpage = true ; break ; }

        stamp2datetime(PhoneSMS[playerid][i][E_SMS_DATE],
            year, month, day, hour, minute, second, 1) ;
        format(date_str, sizeof(date_str), "%02d/%02d/%d %02d:%02d",
            day, month, year, hour, minute) ;

        new sender_label[MAX_PHONEBOOK_DESC + 16] ;
        new resolved = false ;
        for (new c ; c < MAX_SAVED_NUMBERS ; c++) {
            if (Phonebook[playerid][c][E_PHBOOK_NR] == PhoneSMS[playerid][i][E_SMS_SENDER]) {
                format(sender_label, sizeof(sender_label), "%s (%d)",
                    Phonebook[playerid][c][E_PHBOOK_DESC],
                    PhoneSMS[playerid][i][E_SMS_SENDER]) ;
                resolved = true ;
                break ;
            }
        }
        if (!resolved)
            format(sender_label, sizeof(sender_label), "%d", PhoneSMS[playerid][i][E_SMS_SENDER]) ;

        if (!PhoneSMS[playerid][i][E_SMS_READ]) {
            unread_msg = true ;
            format(string, sizeof(string), "%s{1F85DE}[NEW] %s\t{1F85DE}%s\t%.28s\n",
                string, sender_label, date_str, PhoneSMS[playerid][i][E_SMS_TEXT]) ;
        }
        else {
            format(string, sizeof(string), "%s%s\t%s\t%.28s\n",
                string, sender_label, date_str, PhoneSMS[playerid][i][E_SMS_TEXT]) ;
        }
        items_shown++ ;
    }

    if (unread_msg) SendServerMessage(playerid, 0x1F85DEFF, "Phone", "A3A3A3", "You have unread messages.") ;
    if (nextpage)   strcat(string, "Next Page >>") ;

    new total_pages = max(1, (total_inbox + MAX_ITEMS_ON_PAGE - 1) / MAX_ITEMS_ON_PAGE) ;

    inline phone_view_inbox(pid, dialogid, response, listitem, string: inputtext[]) {
        #pragma unused pid, dialogid, inputtext

        new page_offset = (PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE] - 1) * MAX_ITEMS_ON_PAGE ;
        new selection   = page_offset + listitem ;

        if (!response) {
            if (PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE] > 1) {
                PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE]-- ;
                return SMS_DisplayInbox(playerid) ;
            }
            return true ;
        }

        if (listitem >= MAX_ITEMS_ON_PAGE) {
            PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE]++ ;
            return SMS_DisplayInbox(playerid) ;
        }

        if (selection >= MAX_STORED_SMS ||
            PhoneSMS[playerid][selection][E_SMS_SQLID] == 0) return true ;

        inline phone_inbox_options(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
            #pragma unused pidx, dialogidx, inputtextx

            if (!responsex) { SMS_DisplayInbox(playerid) ; return true ; }

            switch (listitemx) {
                case 0: SMS_DisplayMessage(playerid, selection, SMS_DATA_TYPE_INBOX) ;
                case 1: {
                    SendClientMessage(playerid, PHONE_COLOUR_MED,
                        sprintf("[SMS from %d]", PhoneSMS[playerid][selection][E_SMS_SENDER])) ;
                    SendClientMessage(playerid, 0xDEDEDEFF,
                        sprintf("\"%s\"", PhoneSMS[playerid][selection][E_SMS_TEXT])) ;
                }
                case 2: SMS_QuickReply(playerid, PhoneSMS[playerid][selection][E_SMS_SENDER]) ;
                case 3: {
                    new query[128] ;
                    mysql_format(mysql, query, sizeof(query),
                        "DELETE FROM sms WHERE sms_id = %d",
                        PhoneSMS[playerid][selection][E_SMS_SQLID]) ;
                    mysql_tquery(mysql, query) ;
                    SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                        "Message deleted.") ;
                    SMS_DisplayInbox_SQL(playerid) ;
                }
            }
        }

        Dialog_ShowCallback(playerid, using inline phone_inbox_options,
            DIALOG_STYLE_LIST,
            sprintf("Message from %d", PhoneSMS[playerid][selection][E_SMS_SENDER]),
            "Read\nPrint to Chat\nQuick Reply\nDelete", "Select", "Back") ;

        return true ;
    }

    new title[64] ;
    format(title, sizeof(title), "Inbox: Page %d of %d",
        PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE], total_pages) ;

    if (PlayerVar[playerid][E_PLAYER_PHONE_INBOX_PAGE] > 1) {
        Dialog_ShowCallback(playerid, using inline phone_view_inbox,
            DIALOG_STYLE_TABLIST_HEADERS, title, string, "Select", "Previous") ;
    }
    else {
        Dialog_ShowCallback(playerid, using inline phone_view_inbox,
            DIALOG_STYLE_TABLIST_HEADERS, title, string, "Select", "Close") ;
    }

    return true ;
}

// Shows the sentbox page.
SMS_DisplaySentbox(playerid) {

    if (PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE] == 0)
        PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE] = 1 ;

    new const MAX_ITEMS_ON_PAGE = 10 ;
    new string[1536], bool:nextpage ;

    new start_index = (PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE] - 1) * MAX_ITEMS_ON_PAGE ;
    new items_shown = 0 ;
    new date_str[64], year, month, day, hour, minute, second ;
    new total_sent = player_sent_sms_count[playerid] ;

    strcat(string, "To\tDate\tMessage\n") ;

    for (new i = start_index ; i < total_sent ; i++) {

        if (PhoneSentSMS[playerid][i][E_SMS_SQLID] == 0) continue ;
        if (items_shown >= MAX_ITEMS_ON_PAGE) { nextpage = true ; break ; }

        stamp2datetime(PhoneSentSMS[playerid][i][E_SMS_DATE],
            year, month, day, hour, minute, second, 1) ;
        format(date_str, sizeof(date_str), "%02d/%02d/%d %02d:%02d",
            day, month, year, hour, minute) ;

        // try to resolve receiver char id to a phone number via online players
        new to_label[MAX_PHONEBOOK_DESC + 16] = "[offline]" ;
        new receiver_charid = PhoneSentSMS[playerid][i][E_SMS_RECEIVER] ;

        foreach (new t: Player) {
            if (Character[t][E_CHARACTER_ID] == receiver_charid) {
                new to_nr = Character[t][E_CHARACTER_PHONE_NUMBER] ;
                new resolved = false ;
                for (new c ; c < MAX_SAVED_NUMBERS ; c++) {
                    if (Phonebook[playerid][c][E_PHBOOK_NR] == to_nr) {
                        format(to_label, sizeof(to_label), "%s (%d)",
                            Phonebook[playerid][c][E_PHBOOK_DESC], to_nr) ;
                        resolved = true ;
                        break ;
                    }
                }
                if (!resolved)
                    format(to_label, sizeof(to_label), "%d", to_nr) ;
                break ;
            }
        }

        format(string, sizeof(string), "%s%s\t%s\t%.28s\n",
            string, to_label, date_str, PhoneSentSMS[playerid][i][E_SMS_TEXT]) ;

        items_shown++ ;
    }

    if (nextpage) strcat(string, "Next Page >>") ;

    new total_pages = max(1, (total_sent + MAX_ITEMS_ON_PAGE - 1) / MAX_ITEMS_ON_PAGE) ;

    inline phone_view_sentbox(pid, dialogid, response, listitem, string: inputtext[]) {
        #pragma unused pid, dialogid, inputtext

        new page_offset = (PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE] - 1) * MAX_ITEMS_ON_PAGE ;
        new selection   = page_offset + listitem ;

        if (!response) {
            if (PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE] > 1) {
                PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE]-- ;
                return SMS_DisplaySentbox(playerid) ;
            }
            return true ;
        }

        if (listitem >= MAX_ITEMS_ON_PAGE) {
            PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE]++ ;
            return SMS_DisplaySentbox(playerid) ;
        }

        if (selection >= MAX_SENT_SMS ||
            PhoneSentSMS[playerid][selection][E_SMS_SQLID] == 0) return true ;

        inline phone_sentbox_options(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
            #pragma unused pidx, dialogidx, inputtextx

            if (!responsex) { SMS_DisplaySentbox(playerid) ; return true ; }

            switch (listitemx) {
                case 0: SMS_DisplayMessage(playerid, selection, SMS_DATA_TYPE_SENT) ;
                case 1: {
                    SendClientMessage(playerid, PHONE_COLOUR_MED, "[Sent SMS]") ;
                    SendClientMessage(playerid, 0xDEDEDEFF,
                        sprintf("\"%s\"", PhoneSentSMS[playerid][selection][E_SMS_TEXT])) ;
                }
                case 2: {
                    new query[128] ;
                    mysql_format(mysql, query, sizeof(query),
                        "DELETE FROM sms WHERE sms_id = %d",
                        PhoneSentSMS[playerid][selection][E_SMS_SQLID]) ;
                    mysql_tquery(mysql, query) ;
                    SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                        "Message deleted.") ;
                    SMS_DisplaySentbox_SQL(playerid) ;
                }
            }
        }

        Dialog_ShowCallback(playerid, using inline phone_sentbox_options,
            DIALOG_STYLE_LIST,
            sprintf("Sent Message #%d", selection + 1),
            "Read\nPrint to Chat\nDelete", "Select", "Back") ;

        return true ;
    }

    new title[64] ;
    format(title, sizeof(title), "Sent: Page %d of %d",
        PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE], total_pages) ;

    if (PlayerVar[playerid][E_PLAYER_PHONE_SENTBOX_PAGE] > 1) {
        Dialog_ShowCallback(playerid, using inline phone_view_sentbox,
            DIALOG_STYLE_TABLIST_HEADERS, title, string, "Select", "Previous") ;
    }
    else {
        Dialog_ShowCallback(playerid, using inline phone_view_sentbox,
            DIALOG_STYLE_TABLIST_HEADERS, title, string, "Select", "Close") ;
    }

    return true ;
}

// Shows the text message menu (new message, inbox, sentbox).
SMS_DisplayMenu(playerid) {

    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING) {
        return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "You can't send messages while spectating.") ;
    }

    inline phone_send_sms(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
        #pragma unused pidx, dialogidx, listitemx

        if (!responsex) { Phone_ViewDialMenu(playerid) ; return true ; }
        if (!CheckInputtextCrash(playerid, inputtextx)) return true ;

        if (strlen(inputtextx) == 0) {
            return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                "You've entered an empty value!") ;
        }

        new target_nr = 0 ;

        if (IsNumeric(inputtextx)) {
            // number
            target_nr = strval(inputtextx) ;
            if (target_nr <= 0) {
                return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                    "You've entered an invalid number!") ;
            }
        }
        else {
            // Contact name
            new best_len = 0 ;
            for (new i ; i < MAX_SAVED_NUMBERS ; i++) {
                if (Phonebook[playerid][i][E_PHBOOK_NR] == 0) continue ;
                if (strfind(Phonebook[playerid][i][E_PHBOOK_DESC], inputtextx, true) != -1) {
                    new clen = strlen(Phonebook[playerid][i][E_PHBOOK_DESC]) ;
                    if (clen > best_len) {
                        best_len  = clen ;
                        target_nr = Phonebook[playerid][i][E_PHBOOK_NR] ;
                    }
                }
            }
            if (target_nr == 0) {
                return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                    sprintf("No contact found matching \"%s\".", inputtextx)) ;
            }
        }

        if (target_nr == Character[playerid][E_CHARACTER_PHONE_NUMBER]) {
            return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                "You can't SMS yourself.") ;
        }

        new final_nr = target_nr ; // capture for inline

        inline phone_send_smstext(pidj, dialogidj, responsej, listitemj, string: inputtextj[]) {
            #pragma unused pidj, dialogidj, listitemj

            if (!responsej) { SMS_DisplayMenu(playerid) ; return true ; }
            if (!CheckInputtextCrash(playerid, inputtextj)) return true ;

            if (strlen(inputtextj) < 1) {
                return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                    "Message cannot be empty.") ;
            }

            if (strlen(inputtextj) > SMS_MAX_LENGTH) {
                return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                    sprintf("Message is too long (max %d characters).", SMS_MAX_LENGTH)) ;
            }

            new count ;
            foreach (new target: Player) {
                if (Character[target][E_CHARACTER_PHONE_NUMBER] == final_nr) {
                    SMS_SendMessage(target, playerid, inputtextj) ;
                    Phone_OnPlayerReceiveAlert(target, playerid, PHONE_ALERT_SMS) ;
                    count++ ;
                    break ;
                }
            }

            if (!count) {
                return SMS_SendOffline(playerid, final_nr, inputtextj) ;
            }

            return true ;
        }

        Dialog_ShowCallback(playerid, using inline phone_send_smstext,
            DIALOG_STYLE_INPUT,
            sprintf("{DEDEDE}SMS to {5CC44F}%d", target_nr),
            sprintf("Enter your message (max %d chars).", SMS_MAX_LENGTH),
            "Send", "Back") ;

        return true ;
    }

    Dialog_ShowCallback(playerid, using inline phone_send_sms,
        DIALOG_STYLE_INPUT,
        sprintf("{DEDEDE}Send SMS [{5CC44F}Credit: %d{DEDEDE}]",
            Character[playerid][E_CHARACTER_PHONE_CREDIT]),
        "Enter the phone number or contact name you wish to text.",
        "Next", "Back") ;

    return true ;
}

// Shows the quick-reply dialog for a received text.
SMS_QuickReply(playerid, target_nr) {

    inline phone_quick_reply(pid, dialogid, response, listitem, string: inputtext[]) {
        #pragma unused pid, dialogid, listitem

        if (!response) { SMS_DisplayInbox_SQL(playerid) ; return true ; }
        if (!CheckInputtextCrash(playerid, inputtext)) return true ;

        if (strlen(inputtext) < 1) {
            return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                "Message cannot be empty.") ;
        }

        if (strlen(inputtext) > SMS_MAX_LENGTH) {
            return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                sprintf("Message is too long (max %d characters).", SMS_MAX_LENGTH)) ;
        }

        new count ;
        foreach (new target: Player) {
            if (Character[target][E_CHARACTER_PHONE_NUMBER] == target_nr) {
                SMS_SendMessage(target, playerid, inputtext) ;
                Phone_OnPlayerReceiveAlert(target, playerid, PHONE_ALERT_SMS) ;
                count++ ;
                break ;
            }
        }

        if (!count) {
            return SMS_SendOffline(playerid, target_nr, inputtext) ;
        }

        SMS_DisplayInbox_SQL(playerid) ;
        return true ;
    }

    Dialog_ShowCallback(playerid, using inline phone_quick_reply,
        DIALOG_STYLE_INPUT,
        sprintf("{DEDEDE}Reply to {5CC44F}%d", target_nr),
        sprintf("Enter your reply (max %d chars).", SMS_MAX_LENGTH),
        "Send", "Back") ;

    return true ;
}

// Records a sent text in the sender's sent box (memory and database).
SMS_AddToSentBox(sms_sender, receiver_charid, sms_text[], timestamp) {

    new sender_number = Character[sms_sender][E_CHARACTER_PHONE_NUMBER] ;
    new sender_charid = Character[sms_sender][E_CHARACTER_ID] ;
    new sent_count    = player_sent_sms_count[sms_sender] ;

    if (sent_count >= MAX_SENT_SMS) return false ;

    PhoneSentSMS[sms_sender][sent_count][E_SMS_SQLID]     = MAX_SENT_SMS + 1 ;
    PhoneSentSMS[sms_sender][sent_count][E_SMS_CHAR_ID]   = sender_charid ;
    PhoneSentSMS[sms_sender][sent_count][E_SMS_RECEIVER]  = receiver_charid ;
    PhoneSentSMS[sms_sender][sent_count][E_SMS_SENDER]    = sender_number ;
    PhoneSentSMS[sms_sender][sent_count][E_SMS_DATA_TYPE] = SMS_DATA_TYPE_SENT ;
    PhoneSentSMS[sms_sender][sent_count][E_SMS_DATE]      = timestamp ;
    PhoneSentSMS[sms_sender][sent_count][E_SMS_READ]      = 1 ;
    PhoneSentSMS[sms_sender][sent_count][E_SMS_TEXT][0]   = EOS ;
    strcat(PhoneSentSMS[sms_sender][sent_count][E_SMS_TEXT], sms_text) ;

    player_sent_sms_count[sms_sender]++ ;

    new captured_sent = sent_count ;
    new query2[512] ;
    mysql_format(mysql, query2, sizeof(query2),
        "INSERT INTO sms(sms_character_id, sms_sender, sms_receiver_charid, sms_data_type, sms_text, sms_date, sms_read) VALUES (%d, %d, %d, %d, '%e', %d, 1)", sender_charid, sender_number, receiver_charid, SMS_DATA_TYPE_SENT, sms_text, timestamp) ;

    inline SMS_OnSentInsert() {
        PhoneSentSMS[sms_sender][captured_sent][E_SMS_SQLID] = cache_insert_id() ;
    }

    MySQL_TQueryInline(mysql, using inline SMS_OnSentInsert, query2, "") ;
    return true ;
}

// Texts a number whose owner isn't online. The text waits in their inbox, unread, until they next log in.
SMS_SendOffline(sms_sender, target_nr, const sms_text[]) {

    new sender_charid = Character[sms_sender][E_CHARACTER_ID] ;
    new query[128] ;

    mysql_format(mysql, query, sizeof(query),
        "SELECT player_id FROM characters WHERE player_phnumber = %d LIMIT 1", target_nr) ;

    new text[SMS_MAX_LENGTH + 1] ;
    strcat(text, sms_text) ;

    inline SMS_OnOfflineLookup() {

        if (!IsPlayerConnected(sms_sender) || Character[sms_sender][E_CHARACTER_ID] != sender_charid) return true ;

        if (!cache_num_rows()) {
            return SendServerMessage(sms_sender, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                sprintf("The number %d can't be reached.", target_nr)) ;
        }

        new receiver_charid, sender_number = Character[sms_sender][E_CHARACTER_PHONE_NUMBER], timestamp = gettime() ;
        cache_get_value_name_int(0, "player_id", receiver_charid) ;

        new insert_query[512 + SMS_MAX_LENGTH] ;
        mysql_format(mysql, insert_query, sizeof(insert_query),
            "INSERT INTO sms(sms_character_id, sms_sender, sms_receiver_charid, sms_data_type, sms_text, sms_date, sms_read) SELECT %d, %d, %d, %d, '%e', %d, 0 FROM DUAL WHERE (SELECT COUNT(*) FROM sms WHERE sms_character_id = %d AND sms_data_type = %d) < %d",
            receiver_charid, sender_number, receiver_charid, SMS_DATA_TYPE_INBOX, text, timestamp,
            receiver_charid, SMS_DATA_TYPE_INBOX, MAX_INBOX_SMS) ;

        inline SMS_OnOfflineInsert() {

            if (!IsPlayerConnected(sms_sender) || Character[sms_sender][E_CHARACTER_ID] != sender_charid) return true ;

            if (!cache_affected_rows()) {
                return SendServerMessage(sms_sender, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                    sprintf("The number %d can't be reached.", target_nr)) ;
            }

            SMS_AddToSentBox(sms_sender, receiver_charid, text, timestamp) ;

            SendClientMessage(sms_sender, 0xDEC61FFF, sprintf("[SMS] %d -> %d: %s", sender_number, target_nr, text)) ;

            new log_buf[256] ;
            format(log_buf, sizeof(log_buf), "%s sends SMS to offline number %d: %s",
                ReturnMixedName(sms_sender), target_nr, text) ;
            SendAdminListen(sms_sender, log_buf) ;
            return true ;
        }

        MySQL_TQueryInline(mysql, using inline SMS_OnOfflineInsert, insert_query, "") ;
        return true ;
    }

    MySQL_TQueryInline(mysql, using inline SMS_OnOfflineLookup, query, "") ;
    return true ;
}

// On login: tell the player about texts that arrived while they were away.
SMS_NotifyUnread(playerid) {

    new query[160] ;
    mysql_format(mysql, query, sizeof(query),
        "SELECT COUNT(*) AS unread FROM sms WHERE sms_character_id = %d AND sms_data_type = %d AND sms_read = 0",
        Character[playerid][E_CHARACTER_ID], SMS_DATA_TYPE_INBOX) ;

    new charid = Character[playerid][E_CHARACTER_ID] ;

    inline SMS_OnUnreadCount() {

        if (!IsPlayerConnected(playerid) || Character[playerid][E_CHARACTER_ID] != charid) return true ;

        new unread ;
        cache_get_value_name_int(0, "unread", unread) ;

        if (unread > 0) {
            SendServerMessage(playerid, 0x1F85DEFF, "Phone", "A3A3A3",
                sprintf("You have %d unread text message(s). Use /inbox. Check your call history for missed calls.", unread)) ;
        }
        return true ;
    }

    MySQL_TQueryInline(mysql, using inline SMS_OnUnreadCount, query, "") ;
    return true ;
}

// Delivers a text to the receiver (stores it, alerts them, saves it).
SMS_SendMessage(sms_target, sms_sender, sms_text[]) {

    new sender_number   = Character[sms_sender][E_CHARACTER_PHONE_NUMBER] ;
    new receiver_charid = Character[sms_target][E_CHARACTER_ID] ;
    new timestamp       = gettime() ;

    new inbox_count = player_sms_count[sms_target] ;

    if (inbox_count >= MAX_INBOX_SMS) {
        SendServerMessage(sms_target, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "Your inbox is full (128 messages). Delete old texts to receive new ones.") ;
    }
    else {
        new idx = inbox_count ;

        PhoneSMS[sms_target][idx][E_SMS_SQLID]     = MAX_INBOX_SMS + 1 ; // temp placeholder
        PhoneSMS[sms_target][idx][E_SMS_CHAR_ID]   = receiver_charid ;
        PhoneSMS[sms_target][idx][E_SMS_RECEIVER]  = receiver_charid ;
        PhoneSMS[sms_target][idx][E_SMS_SENDER]    = sender_number ;
        PhoneSMS[sms_target][idx][E_SMS_DATA_TYPE] = SMS_DATA_TYPE_INBOX ;
        PhoneSMS[sms_target][idx][E_SMS_DATE]      = timestamp ;
        PhoneSMS[sms_target][idx][E_SMS_READ]      = 0 ;
        PhoneSMS[sms_target][idx][E_SMS_TEXT][0]   = EOS ;
        strcat(PhoneSMS[sms_target][idx][E_SMS_TEXT], sms_text) ;

        player_sms_count[sms_target]++ ;

        new captured_idx = idx ;
        new query[512] ;
        mysql_format(mysql, query, sizeof(query),
            "INSERT INTO sms(sms_character_id, sms_sender, sms_receiver_charid, sms_data_type, sms_text, sms_date, sms_read) VALUES (%d, %d, %d, %d, '%e', %d, 0)", receiver_charid, sender_number, receiver_charid, SMS_DATA_TYPE_INBOX, sms_text, timestamp) ;

        inline SMS_OnInboxInsert() {
            PhoneSMS[sms_target][captured_idx][E_SMS_SQLID] = cache_insert_id() ;
        }

        MySQL_TQueryInline(mysql, using inline SMS_OnInboxInsert, query, "") ;
    }

    SMS_AddToSentBox(sms_sender, receiver_charid, sms_text, timestamp) ;

    SendClientMessage(sms_sender, 0xDEC61FFF,
        sprintf("[SMS] %d -> %d: %s",
            sender_number,
            Character[sms_target][E_CHARACTER_PHONE_NUMBER],
            sms_text)) ;

    new log_buf[256] ;
    format(log_buf, sizeof(log_buf), "%s sends SMS to %s: %s",
        ReturnMixedName(sms_sender), ReturnMixedName(sms_target), sms_text) ;
    SendAdminListen(sms_sender, log_buf) ;

    return true ;
}

// Shows a single message with reply and delete options.
SMS_DisplayMessage(playerid, selection, box_type) {

    new sqlid, sender, receiver, date_val, read_val ;
    new text[SMS_MAX_LENGTH] ;

    if (box_type == SMS_DATA_TYPE_SENT) {
        if (selection < 0 || selection >= MAX_SENT_SMS) return true ;
        if (PhoneSentSMS[playerid][selection][E_SMS_SQLID] == 0) return true ;
        sqlid    = PhoneSentSMS[playerid][selection][E_SMS_SQLID] ;
        sender   = PhoneSentSMS[playerid][selection][E_SMS_SENDER] ;
        receiver = PhoneSentSMS[playerid][selection][E_SMS_RECEIVER] ;
        date_val = PhoneSentSMS[playerid][selection][E_SMS_DATE] ;
        read_val = PhoneSentSMS[playerid][selection][E_SMS_READ] ;
        strcat(text, PhoneSentSMS[playerid][selection][E_SMS_TEXT]) ;
    }
    else {
        if (selection < 0 || selection >= MAX_STORED_SMS) return true ;
        if (PhoneSMS[playerid][selection][E_SMS_SQLID] == 0) return true ;
        sqlid    = PhoneSMS[playerid][selection][E_SMS_SQLID] ;
        sender   = PhoneSMS[playerid][selection][E_SMS_SENDER] ;
        receiver = PhoneSMS[playerid][selection][E_SMS_RECEIVER] ;
        date_val = PhoneSMS[playerid][selection][E_SMS_DATE] ;
        read_val = PhoneSMS[playerid][selection][E_SMS_READ] ;
        strcat(text, PhoneSMS[playerid][selection][E_SMS_TEXT]) ;
    }

    new wrapped[SMS_MAX_LENGTH * 2] ;
    new raw_len = strlen(text) ;
    new w_pos = 0, col = 0 ;

    for (new i = 0 ; i < raw_len && w_pos < sizeof(wrapped) - 2 ; i++) {
        wrapped[w_pos++] = text[i] ;
        col++ ;
        if (col >= 40) {
            new found_space = false ;
            for (new k = i + 1 ; k < raw_len && k < i + 10 ; k++) {
                if (text[k] == ' ') { found_space = true ; break ; }
            }
            if (!found_space) { wrapped[w_pos++] = '\n' ; col = 0 ; }
        }
        if (text[i] == ' ' && col >= 38) { wrapped[w_pos - 1] = '\n' ; col = 0 ; }
    }
    wrapped[w_pos] = EOS ;

    new date_str[64], year, month, day, hour, minute, second ;
    stamp2datetime(date_val, year, month, day, hour, minute, second, 1) ;
    format(date_str, sizeof(date_str), "%02d/%02d/%d - %02d:%02d:%02d",
        day, month, year, hour, minute, second) ;

    new string[640] ;

    if (box_type == SMS_DATA_TYPE_SENT) {
        new to_label[MAX_PHONEBOOK_DESC + 16] = "[offline]" ;
        foreach (new t: Player) {
            if (Character[t][E_CHARACTER_ID] == receiver) {
                new to_nr = Character[t][E_CHARACTER_PHONE_NUMBER] ;
                new resolved = false ;
                for (new c ; c < MAX_SAVED_NUMBERS ; c++) {
                    if (Phonebook[playerid][c][E_PHBOOK_NR] == to_nr) {
                        format(to_label, sizeof(to_label), "%s (%d)",
                            Phonebook[playerid][c][E_PHBOOK_DESC], to_nr) ;
                        resolved = true ;
                        break ;
                    }
                }
                if (!resolved) format(to_label, sizeof(to_label), "%d", to_nr) ;
                break ;
            }
        }
        format(string, sizeof(string), "{DEC61F}To:{DEDEDE}    %s\n{DEC61F}Date:{DEDEDE}  %s\n\n%s",
            to_label, date_str, wrapped) ;
    }
    else {
        new from_label[MAX_PHONEBOOK_DESC + 16] ;
        new resolved = false ;
        for (new c ; c < MAX_SAVED_NUMBERS ; c++) {
            if (Phonebook[playerid][c][E_PHBOOK_NR] == sender) {
                format(from_label, sizeof(from_label), "%s (%d)",
                    Phonebook[playerid][c][E_PHBOOK_DESC], sender) ;
                resolved = true ;
                break ;
            }
        }
        if (!resolved) format(from_label, sizeof(from_label), "%d", sender) ;

        format(string, sizeof(string), "{DEC61F}From:{DEDEDE}  %s\n{DEC61F}Date:{DEDEDE}  %s\n\n%s",
            from_label, date_str, wrapped) ;
    }

    inline phone_msg_back(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
        #pragma unused pidx, dialogidx, responsex, listitemx, inputtextx
        if (box_type == SMS_DATA_TYPE_SENT) SMS_DisplaySentbox_SQL(playerid) ;
        else SMS_DisplayInbox_SQL(playerid) ;
        return true ;
    }

    new dlg_title[64] ;
    if (box_type == SMS_DATA_TYPE_SENT)
        format(dlg_title, sizeof(dlg_title), "Sent Message #%d", selection + 1) ;
    else
        format(dlg_title, sizeof(dlg_title), "Message from %d", sender) ;

    Dialog_ShowCallback(playerid, using inline phone_msg_back,
        DIALOG_STYLE_MSGBOX, dlg_title, string, "Back") ;

    if (box_type == SMS_DATA_TYPE_INBOX && !read_val) {
        PhoneSMS[playerid][selection][E_SMS_READ] = 1 ;
        new q[128] ;
        mysql_format(mysql, q, sizeof(q),
            "UPDATE sms SET sms_read = 1 WHERE sms_id = %d", sqlid) ;
        mysql_tquery(mysql, q) ;
    }

    return true ;
}
