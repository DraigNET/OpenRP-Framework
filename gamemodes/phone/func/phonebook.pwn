// ============================================================================
// File: phone/func/phonebook.pwn
// Phonebook contacts: adding, renaming, deleting and looking up contacts by name or number.
// ============================================================================


#define MAX_PHONEBOOK_DESC  ( 64 )
#define MAX_SAVED_NUMBERS   ( 128 )

enum E_PH_BOOK_DATA {
    E_PHBOOK_SQLID,
    E_PHBOOK_NR,
    E_PHBOOK_DESC [ MAX_PHONEBOOK_DESC ]
} ;

enum {
    PHONEBOOK_INDEX_CALL,
    PHONEBOOK_INDEX_SMS,
    PHONEBOOK_INDEX_EDIT,
    PHONEBOOK_INDEX_REMOVE
}

new Phonebook [ MAX_PLAYERS ] [ MAX_SAVED_NUMBERS ] [ E_PH_BOOK_DATA ] ;

Phone_Phonebook_Add ( playerid ) {

    inline phone_phonebook_add(pid, dialogid, response, listitem, string: inputtext[]) {
        #pragma unused pid, dialogid, listitem

        if ( ! response ) {
            Phone_ViewDialMenu ( playerid ) ;
            return true ;
        }

        if ( ! CheckInputtextCrash ( playerid, inputtext ) ) return true ;

        new number ;
        if ( sscanf ( inputtext, "i", number ) ) {
            SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "You've entered an invalid number. Please only use digits." ) ;
            return true ;
        }

        if ( number <= 0 ) {
            SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "That is not a valid phone number." ) ;
            return true ;
        }

        for ( new i ; i < MAX_SAVED_NUMBERS ; i ++ ) {
            if ( Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ] == number ) {
                SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "That number is already in your phonebook." ) ;
                return true ;
            }
        }

        inline phone_phonebook_add2(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
            #pragma unused pidx, dialogidx, listitemx

            if ( ! responsex ) {
                Phone_ViewDialMenu ( playerid ) ;
                return true ;
            }

            if ( ! CheckInputtextCrash ( playerid, inputtextx ) ) return true ;

            if ( strlen ( inputtextx ) < 1 ) {
                SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Contact name cannot be empty." ) ;
                return true ;
            }

            SendServerMessage( playerid, PHONE_COLOUR_OK, "Phone", "A3A3A3",
                sprintf( "Added new contact \"%s\" - number %d.", inputtextx, number ) ) ;

            new query [ 512 ] ;
            mysql_format ( mysql, query, sizeof ( query ),
                "INSERT INTO phonebook(character_id, phone_number, phone_desc) VALUES (%d, %d, '%e')",
                Character [ playerid ] [ E_CHARACTER_ID ], number, inputtextx ) ;
            mysql_tquery ( mysql, query ) ;

            Phone_ViewPhonebook_SQL ( playerid ) ;
            return true ;
        }

        Dialog_ShowCallback ( playerid, using inline phone_phonebook_add2,
            DIALOG_STYLE_INPUT, "Add new contact: name",
            "Enter the name of the contact you wish to add.", "Add", "Back" ) ;

        return true ;
    }

    Dialog_ShowCallback ( playerid, using inline phone_phonebook_add,
        DIALOG_STYLE_INPUT, "Add new contact: number",
        "Enter the phone number of the contact you wish to add.", "Proceed", "Back" ) ;

    return true ;
}

Phone_ViewPhonebook_SQL ( playerid, view = true ) {

    for ( new i ; i < MAX_SAVED_NUMBERS ; i ++ ) {
        Phonebook [ playerid ] [ i ] [ E_PHBOOK_SQLID ] = 0 ;
        Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ]   = 0 ;
        Phonebook [ playerid ] [ i ] [ E_PHBOOK_DESC ][ 0 ] = EOS ;
    }

    new query [ 256 + MAX_PHONEBOOK_DESC ] ;
    mysql_format ( mysql, query, sizeof ( query ),
        "SELECT * FROM phonebook WHERE character_id = %d ORDER BY phone_desc ASC",
        Character [ playerid ] [ E_CHARACTER_ID ] ) ;

    inline phone_phbook_sql() {

        new r = cache_num_rows() ;

        if ( r ) {

            for ( new i = 0 ; i < r ; i ++ ) {

                if ( i >= MAX_SAVED_NUMBERS ) {
                    if ( view ) {
                        SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                            "You have reached the maximum number of saved contacts (128). Delete some to add more." ) ;
                    }
                    break ;
                }

                cache_get_value_name_int( i, "phonebook_id",   Phonebook [ playerid ] [ i ] [ E_PHBOOK_SQLID ] ) ;
                cache_get_value_name_int( i, "phone_number",   Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ] ) ;
                cache_get_value_name    ( i, "phone_desc",     Phonebook [ playerid ] [ i ] [ E_PHBOOK_DESC ] ) ;
            }

            if ( view ) Phone_ViewPhonebook ( playerid ) ;
        }

        else {
            if ( view ) SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "You have no saved contacts." ) ;
        }
        
        PhoneHistory_Load ( playerid ) ;
    }

    MySQL_TQueryInline ( mysql, using inline phone_phbook_sql, query, "" ) ;
    return true ;
}

Phone_ViewPhonebook ( playerid ) {

    if ( PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] == 0 ) {
        PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] = 1 ;
    }

    new const MAX_ITEMS_ON_PAGE = 10 ;
    new string [ 1024 ], bool: nextpage ;

    new start_index = ( PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] - 1 ) * MAX_ITEMS_ON_PAGE ;
    new items_on_page = 0 ;

    strcat( string, "Phone Number\tDescription\n" ) ;

    new total_contacts = 0 ;
    for ( new i ; i < MAX_SAVED_NUMBERS ; i ++ ) {
        if ( Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ] != 0 ) total_contacts ++ ;
    }

    new filled = 0 ;
    for ( new i ; i < MAX_SAVED_NUMBERS ; i ++ ) {

        if ( Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ] == 0 ) continue ;

        if ( filled < start_index ) {
            filled ++ ;
            continue ;
        }

        if ( items_on_page >= MAX_ITEMS_ON_PAGE ) {
            nextpage = true ;
            break ;
        }

        format( string, sizeof( string ), "%s%d\t%s\n", string,
            Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ],
            Phonebook [ playerid ] [ i ] [ E_PHBOOK_DESC ] ) ;

        filled ++ ;
        items_on_page ++ ;
    }

    if ( nextpage ) strcat( string, "Next Page >>" ) ;

    new total_pages = max( 1, ( total_contacts + MAX_ITEMS_ON_PAGE - 1 ) / MAX_ITEMS_ON_PAGE ) ;

    inline phone_view_phonebook(pid, dialogid, response, listitem, string: inputtext[]) {
        #pragma unused pid, dialogid, inputtext

        if ( ! response ) {

            if ( PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] > 1 ) {
                PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] -- ;
                return Phone_ViewPhonebook ( playerid ) ;
            }
            else Phone_ViewDialMenu ( playerid ) ;
            return true ;
        }

        if ( listitem >= MAX_ITEMS_ON_PAGE ) {
            PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] ++ ;
            return Phone_ViewPhonebook ( playerid ) ;
        }

        new slot_start = ( PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] - 1 ) * MAX_ITEMS_ON_PAGE ;
        new found      = 0 ;
        new selection  = -1 ;

        for ( new i ; i < MAX_SAVED_NUMBERS ; i ++ ) {

            if ( Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ] == 0 ) continue ;

            if ( found == slot_start + listitem ) {
                selection = i ;
                break ;
            }
            found ++ ;
        }

        if ( selection == -1 ) return true ;

        inline phone_phbook_options(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
            #pragma unused pidx, dialogidx, inputtextx

            if ( ! responsex ) {
                Phone_ViewPhonebook ( playerid ) ;
                return true ;
            }

            switch ( listitemx ) {
                case 0: Phonebook_OnActionPerformed ( playerid, selection, PHONEBOOK_INDEX_CALL ) ;
                case 1: Phonebook_OnActionPerformed ( playerid, selection, PHONEBOOK_INDEX_SMS ) ;
                case 2: Phonebook_OnActionPerformed ( playerid, selection, PHONEBOOK_INDEX_EDIT ) ;
                case 3: Phonebook_OnActionPerformed ( playerid, selection, PHONEBOOK_INDEX_REMOVE ) ;
            }
        }

        Dialog_ShowCallback ( playerid, using inline phone_phbook_options,
            DIALOG_STYLE_LIST,
            sprintf( "Phonebook: %s (%d)",
                Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ],
                Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] ),
            "Call\nSend SMS\nEdit Contact\nDelete Contact", "Select", "Back" ) ;

        return true ;
    }

    new title [ 64 ] ;
    format( title, sizeof( title ), "Phonebook: Page %d of %d", PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ], total_pages ) ;

    if ( PlayerVar [ playerid ] [ E_PLAYER_PHONE_PHONEBOOK_PAGE ] > 1 ) {
        Dialog_ShowCallback ( playerid, using inline phone_view_phonebook,
            DIALOG_STYLE_TABLIST_HEADERS, title, string, "Select", "Previous" ) ;
    }
    else {
        Dialog_ShowCallback ( playerid, using inline phone_view_phonebook,
            DIALOG_STYLE_TABLIST_HEADERS, title, string, "Select", "Back" ) ;
    }

    return true ;
}

Phonebook_OnActionPerformed ( playerid, selection, index = 0 ) {

    new query [ 512 ] ;

    switch ( index ) {

        case PHONEBOOK_INDEX_CALL: {

            if ( GetPlayerState ( playerid ) == PLAYER_STATE_SPECTATING ) {
                SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "You can't make calls while spectating." ) ;
                return true ;
            }

            new target_nr = Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] ;
            new count ;

            foreach ( new target: Player ) {
                if ( Character [ target ] [ E_CHARACTER_PHONE_NUMBER ] == target_nr ) {
                    Phone_OnPlayerReceiveAlert ( target, playerid, PHONE_ALERT_CALL ) ;
                    count ++ ;
                    break ;
                }
            }

            if ( ! count ) {
                SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                    sprintf( "The number %d can't be reached.", target_nr ) ) ;
            }
            else {
                SendServerMessage( playerid, PHONE_COLOUR_OK, "Phone", "A3A3A3",
                    sprintf( "Calling %s (%d)...",
                        Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ],
                        target_nr ) ) ;
            }
        }

        case PHONEBOOK_INDEX_SMS: {

            inline phone_send_smstext(pidj, dialogidj, responsej, listitemj, string: inputtextj[]) {
                #pragma unused pidj, dialogidj, listitemj

                if ( ! responsej ) {
                    Phone_ViewPhonebook ( playerid ) ;
                    return true ;
                }

                if ( ! CheckInputtextCrash ( playerid, inputtextj ) ) return true ;

                if ( strlen ( inputtextj ) < 1 ) {
                    SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "Message cannot be empty." ) ;
                    return true ;
                }

                if ( strlen ( inputtextj ) > SMS_MAX_LENGTH ) {
                    SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                        sprintf( "Your message is too long (max %d characters).", SMS_MAX_LENGTH ) ) ;
                    return true ;
                }

                new target_nr = Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] ;
                new count ;

                foreach ( new target: Player ) {
                    if ( Character [ target ] [ E_CHARACTER_PHONE_NUMBER ] == target_nr ) {
                        SMS_SendMessage ( target, playerid, inputtextj ) ;
                        Phone_OnPlayerReceiveAlert ( target, playerid, PHONE_ALERT_SMS ) ;
                        count ++ ;
                        break ;
                    }
                }

                if ( ! count ) {
                    SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                        sprintf( "The number %d can't be reached.", target_nr ) ) ;
                    return true ;
                }

                SendClientMessage ( playerid, 0xDEC61FFF,
                    sprintf( "[SMS] %d → %d: %s",
                        Character [ playerid ] [ E_CHARACTER_PHONE_NUMBER ],
                        target_nr, inputtextj ) ) ;

                return true ;
            }

            Dialog_ShowCallback ( playerid, using inline phone_send_smstext,
                DIALOG_STYLE_INPUT,
                sprintf( "{DEDEDE}SMS to {5CC44F}%s {DEDEDE}(%d)",
                    Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ],
                    Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] ),
                sprintf( "Enter your message (max %d chars).", SMS_MAX_LENGTH ),
                "Send", "Back" ) ;
        }

        case PHONEBOOK_INDEX_EDIT: {

            inline phone_phbook_edit(pid, dialogid, response, listitem, string: inputtext[]) {
                #pragma unused pid, dialogid, listitem

                if ( ! response ) {
                    Phone_ViewPhonebook ( playerid ) ;
                    return true ;
                }

                if ( ! CheckInputtextCrash ( playerid, inputtext ) ) return true ;

                new new_number ;
                if ( sscanf ( inputtext, "i", new_number ) || new_number <= 0 ) {
                    SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
                        "You've entered an invalid number. Please only use digits." ) ;
                    return true ;
                }

                new old_number = Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] ;
                new sql_id     = Phonebook [ playerid ] [ selection ] [ E_PHBOOK_SQLID ] ;

                mysql_format ( mysql, query, sizeof ( query ),
                    "UPDATE phonebook SET phone_number = %d WHERE phonebook_id = %d",
                    new_number, sql_id ) ;
                mysql_tquery ( mysql, query ) ;

                Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] = new_number ;

                SendServerMessage( playerid, PHONE_COLOUR_OK, "Phone", "A3A3A3",
                    sprintf( "Number changed from %d to %d.", old_number, new_number ) ) ;

                inline phone_phbook_edit2(pidx, dialogidx, responsex, listitemx, string: inputtextx[]) {
                    #pragma unused pidx, dialogidx, listitemx

                    if ( ! responsex ) {
                        Phone_ViewPhonebook ( playerid ) ;
                        return true ;
                    }

                    if ( ! CheckInputtextCrash ( playerid, inputtextx ) ) return true ;

                    new old_desc [ MAX_PHONEBOOK_DESC ] ;
                    strcat ( old_desc, Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ] ) ;

                    Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ][ 0 ] = EOS ;
                    strcat ( Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ], inputtextx ) ;

                    mysql_format ( mysql, query, sizeof ( query ),
                        "UPDATE phonebook SET phone_desc = '%e' WHERE phonebook_id = %d",
                        Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ],
                        Phonebook [ playerid ] [ selection ] [ E_PHBOOK_SQLID ] ) ;
                    mysql_tquery ( mysql, query ) ;

                    SendServerMessage( playerid, PHONE_COLOUR_OK, "Phone", "A3A3A3",
                        sprintf( "Description changed from \"%s\" to \"%s\".", old_desc, inputtextx ) ) ;

                    Phone_ViewPhonebook ( playerid ) ;
                    return true ;
                }

                Dialog_ShowCallback ( playerid, using inline phone_phbook_edit2,
                    DIALOG_STYLE_INPUT,
                    sprintf( "Phonebook: Editing Contact #%d", selection ),
                    sprintf( "Enter the new description\n(currently \"%s\")", Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ] ),
                    "Save", "Back" ) ;

                return true ;
            }

            Dialog_ShowCallback ( playerid, using inline phone_phbook_edit,
                DIALOG_STYLE_INPUT,
                sprintf( "Phonebook: Editing Contact #%d", selection ),
                sprintf( "Enter the new number (currently %d)", Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] ),
                "Save", "Back" ) ;
        }

        case PHONEBOOK_INDEX_REMOVE: {

            inline phone_phbook_del(pid, dialogid, response, listitem, string: inputtext[]) {
                #pragma unused pid, dialogid, listitem, inputtext

                if ( ! response ) {
                    Phone_ViewPhonebook ( playerid ) ;
                    return true ;
                }

                mysql_format ( mysql, query, sizeof ( query ),
                    "DELETE FROM phonebook WHERE phonebook_id = %d",
                    Phonebook [ playerid ] [ selection ] [ E_PHBOOK_SQLID ] ) ;
                mysql_tquery ( mysql, query, "OnPhoneContactDeleted", "i", playerid ) ;

                return true ;
            }

            Dialog_ShowCallback ( playerid, using inline phone_phbook_del,
                DIALOG_STYLE_MSGBOX,
                "Phonebook: Delete Contact",
                sprintf( "{DEDEDE}Are you sure you want to delete this contact?\n\nName:   {5CC44F}%s\n{DEDEDE}Number: {5CC44F}%d",
                    Phonebook [ playerid ] [ selection ] [ E_PHBOOK_DESC ],
                    Phonebook [ playerid ] [ selection ] [ E_PHBOOK_NR ] ),
                "Yes, Delete", "Cancel" ) ;
        }
    }

    return true ;
}

forward OnPhoneContactDeleted ( playerid ) ;
public  OnPhoneContactDeleted ( playerid ) {
    Phone_ViewPhonebook_SQL ( playerid ) ;
    return 1 ;
}

CallRemoteNumberFromPhonebook ( playerid, input[] ) {

    if ( GetPlayerState ( playerid ) == PLAYER_STATE_SPECTATING ) {
        return SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3", "You can't make calls while spectating." ) ;
    }

    new count, result_nr ;

    for ( new i ; i < MAX_SAVED_NUMBERS ; i ++ ) {
        if ( Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ] == 0 ) continue ;

        if ( strfind ( Phonebook [ playerid ] [ i ] [ E_PHBOOK_DESC ], input, true ) != -1 ) {
            result_nr = Phonebook [ playerid ] [ i ] [ E_PHBOOK_NR ] ;
            count ++ ;
        }
    }

    if ( count <= 0 ) {
        return SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            sprintf( "No contact found matching \"%s\".", input ) ) ;
    }

    if ( count > 1 ) {
        return SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            sprintf( "Multiple contacts match \"%s\" - please be more specific.", input ) ) ;
    }

    new reached ;

    foreach ( new target: Player ) {
        if ( Character [ target ] [ E_CHARACTER_PHONE_NUMBER ] == result_nr ) {
            Phone_OnPlayerReceiveAlert ( target, playerid, PHONE_ALERT_CALL ) ;
            reached ++ ;
            break ;
        }
    }

    if ( ! reached ) {
        SendServerMessage( playerid, PHONE_COLOUR_BAD, "Phone", "A3A3A3",
            sprintf( "The number %d (%s) can't be reached.", result_nr, input ) ) ;
    }

    return true ;
}
