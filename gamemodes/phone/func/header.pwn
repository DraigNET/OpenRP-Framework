// ============================================================================
// File: phone/func/header.pwn
// Constants for call history entries (call direction and status codes).
// ============================================================================


#define MAX_CALL_HISTORY        ( 20 )   
#define CALL_HISTORY_NR_LEN     ( 12 )
#define MAX_PHONEBOOK_DESC	( 64 )
#define MAX_SAVED_NUMBERS	( 128 )

#define SMS_MAX_LENGTH          ( 128 )
#define MAX_SENT_SMS            ( 128 )
#define MAX_INBOX_SMS           ( 128 )
#define MAX_STORED_SMS          ( MAX_SENT_SMS + MAX_INBOX_SMS )

//  call_direction: 0 = outgoing, 1 = incoming
//  call_status:    0 = answered, 1 = missed, 2 = declined, 3 = unreachable

#include "phone/func/phonebook.pwn"
#include "phone/func/call_history.pwn"
#include "phone/func/dialing.pwn"
#include "phone/func/calling.pwn"
#include "phone/func/texting.pwn"
