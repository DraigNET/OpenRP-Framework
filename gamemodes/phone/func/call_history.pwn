// ============================================================================
// File: phone/func/call_history.pwn
// Call history: records each call as answered, missed, declined or unreachable and loads it
// back for the phone screen.
// ============================================================================


enum E_CALL_HISTORY_DIRECTION {
    CALL_DIR_OUTGOING,
    CALL_DIR_INCOMING
}

enum E_CALL_HISTORY_STATUS {
    CALL_STATUS_ANSWERED,   // both sides picked up
    CALL_STATUS_MISSED,     // recipient never answered / timed out
    CALL_STATUS_DECLINED,   // recipient pressed decline
    CALL_STATUS_UNREACHABLE // number was offline / not found
}

enum E_CALL_HISTORY_ENTRY {
    E_CH_SQLID,
    E_CH_NUMBER,
    E_CALL_HISTORY_DIRECTION: E_CH_DIRECTION,
    E_CALL_HISTORY_STATUS:    E_CH_STATUS,
    E_CH_TIMESTAMP,
    E_CH_CONTACT_NAME [ MAX_PHONEBOOK_DESC ]
}

new CallHistory      [ MAX_PLAYERS ] [ MAX_CALL_HISTORY ] [ E_CALL_HISTORY_ENTRY ] ;
new CallHistoryCount [ MAX_PLAYERS ] ;

// Looks up a contact name for a number in the player's phonebook.
static stock PhoneHistory_ResolveContact(playerid, number, dest[], dest_len) {
    dest[0] = EOS ;
    for (new i ; i < MAX_SAVED_NUMBERS ; i++) {
        if (Phonebook[playerid][i][E_PHBOOK_NR] == number) {
            strmid(dest, Phonebook[playerid][i][E_PHBOOK_DESC], 0, dest_len - 1, dest_len) ;
            return true ;
        }
    }
    return false ;
}

// Clears a player's loaded call history.
stock PhoneHistory_Reset(playerid) {
    CallHistoryCount[playerid] = 0 ;
    for (new i ; i < MAX_CALL_HISTORY ; i++) {
        CallHistory[playerid][i][E_CH_SQLID]     = 0 ;
        CallHistory[playerid][i][E_CH_NUMBER]    = 0 ;
        CallHistory[playerid][i][E_CH_CONTACT_NAME][0] = EOS ;
    }
    return true ;
}

// Loads a player's call history from the database.
stock PhoneHistory_Load(playerid) {

    PhoneHistory_Reset(playerid) ;

    new query[256] ;
    mysql_format(mysql, query, sizeof(query),
        "SELECT * FROM call_history WHERE character_id = %d ORDER BY call_timestamp DESC LIMIT %d",
        Character[playerid][E_CHARACTER_ID], MAX_CALL_HISTORY) ;

    inline OnCallHistoryLoaded() {

        new r = cache_num_rows() ;

        for (new i = 0 ; i < r ; i++) {

            if (i >= MAX_CALL_HISTORY) break ;

            cache_get_value_name_int(i, "call_id",        CallHistory[playerid][i][E_CH_SQLID]) ;
            cache_get_value_name_int(i, "call_number",    CallHistory[playerid][i][E_CH_NUMBER]) ;
            cache_get_value_name_int(i, "call_direction", _:CallHistory[playerid][i][E_CH_DIRECTION]) ;
            cache_get_value_name_int(i, "call_status",    _:CallHistory[playerid][i][E_CH_STATUS]) ;
            cache_get_value_name_int(i, "call_timestamp", CallHistory[playerid][i][E_CH_TIMESTAMP]) ;

            PhoneHistory_ResolveContact(playerid,
                CallHistory[playerid][i][E_CH_NUMBER],
                CallHistory[playerid][i][E_CH_CONTACT_NAME],
                MAX_PHONEBOOK_DESC) ;

            CallHistoryCount[playerid]++ ;
        }
    }

    MySQL_TQueryInline(mysql, using inline OnCallHistoryLoaded, query, "") ;
    return true ;
}

stock PhoneHistory_Record(playerid, number,
    E_CALL_HISTORY_DIRECTION: direction,
    E_CALL_HISTORY_STATUS:    status)
{
    new maxRecord = min(CallHistoryCount[playerid], MAX_CALL_HISTORY - 1) ;
    for (new i = maxRecord ; i > 0 ; i--) {
        CallHistory[playerid][i][E_CH_SQLID]      = CallHistory[playerid][i-1][E_CH_SQLID] ;
        CallHistory[playerid][i][E_CH_NUMBER]      = CallHistory[playerid][i-1][E_CH_NUMBER] ;
        CallHistory[playerid][i][E_CH_DIRECTION]   = CallHistory[playerid][i-1][E_CH_DIRECTION] ;
        CallHistory[playerid][i][E_CH_STATUS]      = CallHistory[playerid][i-1][E_CH_STATUS] ;
        CallHistory[playerid][i][E_CH_TIMESTAMP]   = CallHistory[playerid][i-1][E_CH_TIMESTAMP] ;
        CallHistory[playerid][i][E_CH_CONTACT_NAME][0] = EOS ;
        strcat(CallHistory[playerid][i][E_CH_CONTACT_NAME],
               CallHistory[playerid][i-1][E_CH_CONTACT_NAME]) ;
    }

    CallHistory[playerid][0][E_CH_SQLID]     = 0 ;
    CallHistory[playerid][0][E_CH_NUMBER]    = number ;
    CallHistory[playerid][0][E_CH_DIRECTION] = direction ;
    CallHistory[playerid][0][E_CH_STATUS]    = status ;
    CallHistory[playerid][0][E_CH_TIMESTAMP] = gettime() ;

    PhoneHistory_ResolveContact(playerid, number,
        CallHistory[playerid][0][E_CH_CONTACT_NAME], MAX_PHONEBOOK_DESC) ;

    if (CallHistoryCount[playerid] < MAX_CALL_HISTORY)
        CallHistoryCount[playerid]++ ;

    new charid = Character[playerid][E_CHARACTER_ID] ;
    new ts     = CallHistory[playerid][0][E_CH_TIMESTAMP] ;

    new query[256] ;
    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO call_history(character_id, call_number, call_direction, call_status, call_timestamp) VALUES (%d, %d, %d, %d, %d)", charid, number, _:direction, _:status, ts) ;

    inline OnCallHistoryInserted() {
        CallHistory[playerid][0][E_CH_SQLID] = cache_insert_id() ;
    }

    MySQL_TQueryInline(mysql, using inline OnCallHistoryInserted, query, "") ;

    new prune_q[256] ;
    mysql_format(mysql, prune_q, sizeof(prune_q),
        "DELETE FROM call_history WHERE character_id = %d AND call_id NOT IN ( SELECT call_id FROM ( SELECT call_id FROM call_history WHERE character_id = %d ORDER BY call_timestamp DESC LIMIT %d) AS sub )", charid, charid, MAX_CALL_HISTORY) ;
    mysql_tquery(mysql, prune_q) ;

    return true ;
}

// when the callee answers (both sides get ANSWERED)
stock PhoneRecordAnswered(callee, caller) {
    new callee_nr = Character[callee][E_CHARACTER_PHONE_NUMBER] ;
    new caller_nr = Character[caller][E_CHARACTER_PHONE_NUMBER] ;
    PhoneHistory_Record(callee, caller_nr, CALL_DIR_INCOMING,  CALL_STATUS_ANSWERED) ;
    PhoneHistory_Record(caller, callee_nr, CALL_DIR_OUTGOING,  CALL_STATUS_ANSWERED) ;
}

// when the call timed out (callee missed, caller sees missed outgoing)
stock PhoneRecordMissed(callee, caller) {
    new callee_nr = Character[callee][E_CHARACTER_PHONE_NUMBER] ;
    new caller_nr = Character[caller][E_CHARACTER_PHONE_NUMBER] ;
    PhoneHistory_Record(callee, caller_nr, CALL_DIR_INCOMING,  CALL_STATUS_MISSED) ;
    PhoneHistory_Record(caller, callee_nr, CALL_DIR_OUTGOING,  CALL_STATUS_MISSED) ;
}

// when someone pressed decline
stock PhoneRecordDeclined(callee, caller) {
    new callee_nr = Character[callee][E_CHARACTER_PHONE_NUMBER] ;
    new caller_nr = Character[caller][E_CHARACTER_PHONE_NUMBER] ;
    PhoneHistory_Record(callee, caller_nr, CALL_DIR_INCOMING,  CALL_STATUS_DECLINED) ;
    PhoneHistory_Record(caller, callee_nr, CALL_DIR_OUTGOING,  CALL_STATUS_DECLINED) ;
}

// when the dialled number had no online player (caller-only, outgoing)
stock PhoneRecordUnreachable(caller, number) {
    PhoneHistory_Record(caller, number, CALL_DIR_OUTGOING, CALL_STATUS_UNREACHABLE) ;
    PhoneHistory_RecordOffline(caller, number) ;
}

// The dialled number has an owner who isn't online: log it as a missed call in their history.
stock PhoneHistory_RecordOffline(caller, number) {

    new caller_nr = Character[caller][E_CHARACTER_PHONE_NUMBER] ;

    if (!caller_nr || caller_nr == number) return false ;

    new query[320] ;
    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO call_history(character_id, call_number, call_direction, call_status, call_timestamp) SELECT player_id, %d, %d, %d, %d FROM characters WHERE player_phnumber = %d LIMIT 1",
        caller_nr, _:CALL_DIR_INCOMING, _:CALL_STATUS_MISSED, gettime(), number) ;
    mysql_tquery(mysql, query) ;
    return true ;
}

// Shows the call history dialog (answered, missed, declined).
Phone_ViewCallHistory(playerid) {

    new count = CallHistoryCount[playerid] ;

    if (!count) {
        return SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            "You have no call history.") ;
    }

    new string[2048] ;
    strcat(string, "Number\tType\tStatus\n") ;

    for (new i ; i < count ; i++) {

        new dir_str[4], status_str[22], label[MAX_PHONEBOOK_DESC + 20] ;

        if (CallHistory[playerid][i][E_CH_DIRECTION] == CALL_DIR_OUTGOING)
            strcat(dir_str, "Out") ;
        else
            strcat(dir_str, "In") ;

        switch (CallHistory[playerid][i][E_CH_STATUS]) {
            case CALL_STATUS_ANSWERED:    strcat(status_str, "{4FA070}A") ;
            case CALL_STATUS_MISSED:      strcat(status_str, "{EC6149}M") ;
            case CALL_STATUS_DECLINED:    strcat(status_str, "{EEDB61}D") ;
            case CALL_STATUS_UNREACHABLE: strcat(status_str, "{A3A3A3}U") ;
        }

        if (strlen(CallHistory[playerid][i][E_CH_CONTACT_NAME])) {
            format(label, sizeof(label), "%s (%d)",
                CallHistory[playerid][i][E_CH_CONTACT_NAME],
                CallHistory[playerid][i][E_CH_NUMBER]) ;
        } else {
            format(label, sizeof(label), "%d", CallHistory[playerid][i][E_CH_NUMBER]) ;
        }

        format(string, sizeof(string), "%s%s\t%s\t%s\n",
            string, label, dir_str, status_str) ;
    }

    inline PhoneHistory_select(pid, dialogid, response, listitem, string: inputtext[]) {
        #pragma unused pid, dialogid, inputtext

        if (!response) {
            Phone_ViewDialMenu(playerid) ;
            return true ;
        }

        if (listitem >= CallHistoryCount[playerid]) return true ;

        new sel_number = CallHistory[playerid][listitem][E_CH_NUMBER] ;

        new contact_label[MAX_PHONEBOOK_DESC + 32] ;
        if (strlen(CallHistory[playerid][listitem][E_CH_CONTACT_NAME])) {
            format(contact_label, sizeof(contact_label), "Call History: %s (%d)",
                CallHistory[playerid][listitem][E_CH_CONTACT_NAME], sel_number) ;
        } else {
            format(contact_label, sizeof(contact_label), "Call History: %d", sel_number) ;
        }

        inline phone_ch_action(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
            #pragma unused pidx, dialogidx, inputtextx

            if (!responsex) {
                Phone_ViewCallHistory(playerid) ;
                return true ;
            }

            switch (listitemx) {

                case 0: { // Call back
                    new cb_count ;
                    foreach (new target: Player) {
                        if (Character[target][E_CHARACTER_PHONE_NUMBER] == sel_number) {
                            Phone_OnPlayerReceiveAlert(target, playerid, PHONE_ALERT_CALL) ;
                            cb_count++ ;
                            break ;
                        }
                    }
                    if (!cb_count) {
                        PhoneRecordUnreachable(playerid, sel_number) ;
                        SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                            sprintf("The number \"%d\" can't be reached.", sel_number)) ;
                    }
                }

                case 1: { // SMS back
                    inline phone_ch_smstext(pidj, dialogidj, responsej, listitemj, string: inputtextj[]) {
                        #pragma unused pidj, dialogidj, listitemj

                        if (!responsej) {
                            Phone_ViewCallHistory(playerid) ;
                            return true ;
                        }

                        if (!CheckInputtextCrash(playerid, inputtextj)) return true ;

                        if (strlen(inputtextj) > SMS_MAX_LENGTH) {
                            SendServerMessage(playerid, PHONE_COLOUR_MED, "Phone", "A3A3A3",
                                "Your text message can't be longer than 128 characters. It's been cut off!") ;
                        }

                        new sms_count ;
                        foreach (new target: Player) {
                            if (Character[target][E_CHARACTER_PHONE_NUMBER] == sel_number) {
                                SMS_SendMessage(target, playerid, inputtextj) ;
                                Phone_OnPlayerReceiveAlert(target, playerid, PHONE_ALERT_SMS) ;
                                sms_count++ ;
                                break ;
                            }
                        }
                        if (!sms_count) {
                            SendServerMessage(playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                                sprintf("The number \"%d\" can't be reached.", sel_number)) ;
                        }
                        return true ;
                    }

                    Dialog_ShowCallback(playerid, using inline phone_ch_smstext,
                        DIALOG_STYLE_INPUT,
                        sprintf("{DEDEDE}Reply to %d [{5CC44F}Credit: %d{DEDEDE}]",
                            sel_number, Character[playerid][E_CHARACTER_PHONE_CREDIT]),
                        "Enter your message.", "Send", "Back") ;
                }
            }
            return true ;
        }

        Dialog_ShowCallback(playerid, using inline phone_ch_action,
            DIALOG_STYLE_LIST, contact_label,
            "Call Back\nSend SMS", "Select", "Back") ;

        return true ;
    }

    Dialog_ShowCallback(playerid, using inline PhoneHistory_select,
        DIALOG_STYLE_TABLIST_HEADERS,
        sprintf("Call History (%d entries)", count),
        string, "Select", "Back") ;

    return true ;
}

// Alias that opens the call history.
stock ViewPhoneCallHistory(playerid) {
    return Phone_ViewCallHistory(playerid) ;
}
