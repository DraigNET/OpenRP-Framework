// ============================================================================
// File: player/auth/email.pwn
// Email address validation (IsValidEmail) written without regex.
// ============================================================================



// To avoid stack size stuff
static EmailDlgStr[1024];

// Asks the player for an email address and saves it after validation.
GetPlayerEmail(playerid){

	inline GetEmail(pid, dialogid, response, listitem, string:inputtext[]) 
	{
	    #pragma unused pid, dialogid, listitem

		if ( ! response ) {
			SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "For safety reasons, you MUST set an email address.");
			return GetPlayerEmail(playerid);
		}

		if ( response ) {

			if(!IsValidEmail(inputtext)){
				SendServerMessage ( playerid, COLOR_ERROR, "Error", "A3A3A3", "Please enter a valid email!");
				return GetPlayerEmail(playerid);
			}
 	
 			new query [ 512 ] ;
			mysql_format(mysql, query, sizeof(query),
				"UPDATE accounts SET account_email = '%e' WHERE account_id = %d",
				inputtext,
				Account[playerid][E_PLAYER_ACCOUNT_ID]
			);
			mysql_tquery(mysql, query);

			inline CheckEmailValidity() {
				if ( cache_num_rows() ) {

					SendServerMessage( playerid, COLOR_ERROR, "Security", "A3A3A3", "This email is already used by someone else! Enter a new one, or visit our UCP to reset it!");
					return GetPlayerEmail(playerid);
				}
				else {
					mysql_format(mysql, query, sizeof(query),
						"UPDATE accounts SET account_email = '%e' WHERE account_id = %d",
						inputtext,
						Account[playerid][E_PLAYER_ACCOUNT_ID]
					);

					mysql_tquery(mysql, query);
					
					Account [ playerid ] [ E_PLAYER_ACCOUNT_EMAIL ] [ 0 ] = EOS ;
					strcat(Account [ playerid ] [ E_PLAYER_ACCOUNT_EMAIL ], inputtext);

					SendServerMessage( playerid, COLOR_SECURITY, "Security", "A3A3A3", sprintf("You have set your email to {adadad}%s{dedede}.", Account[playerid][E_PLAYER_ACCOUNT_EMAIL]));
					SendServerMessage( playerid, COLOR_SECURITY, "Security", "A3A3A3", "If you have entered the wrong email, contact a staff member to reset it."); // REMOVE / EDIT ON UCP!!
					return true ;
				}
			} 

			MySQL_TQueryInline(mysql, using inline CheckEmailValidity, query, "");
		}

		return true ;
	}

	format(EmailDlgStr, sizeof(EmailDlgStr), "{FFFFFF}We need you to {AA3333}enter an e-mail address{FFFFFF} before continuing.");

	strcat(EmailDlgStr, "\n\n{FFFFFF}Why do you need to do this?{ADBEE6}");
	strcat(EmailDlgStr, "\n- To let you reset your password incase you forget it.");
	strcat(EmailDlgStr, "\n- To let you know when you have refunds waiting.");
	strcat(EmailDlgStr, "\n- To let you know of unauthorized attempts to access your account.");

	strcat(EmailDlgStr, "{FFFFFF}Please enter your e-mail address below and press {AA3333}Confirm{FFFFFF} to continue.");
	strcat(EmailDlgStr, "\n{ADBEE6}Note that your e-mail address will never be visible to other players or moderators.");

	Dialog_ShowCallback ( playerid, using inline GetEmail, DIALOG_STYLE_INPUT, "Enter an Email Address", EmailDlgStr, "Continue" );
	return true;
}

// \w in the original regex = [A-Za-z0-9_]
static stock bool:Email_IsWordChar(c)
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';

// Pure-Pawn equivalent of ^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$
// (was Regex_New/Regex_Check -- pawnregex.so crashes the server on some input).
stock IsValidEmail(const email[])
{
    new len = strlen(email), atpos = -1;

    // Exactly one '@', not at the very start (local part must be non-empty).
    for (new i = 0; i < len; i++)
    {
        if (email[i] == '@')
        {
            if (atpos != -1) return false; // second '@'
            atpos = i;
        }
    }
    if (atpos < 1) return false;

    // Local part: [\w.-]+  (chars before '@')
    for (new i = 0; i < atpos; i++)
        if (!Email_IsWordChar(email[i]) && email[i] != '.' && email[i] != '-')
            return false;

    // Domain: (label '.')+ tld  -- split on '.', every segment [\w-]+,
    // at least two segments, final segment (TLD) length 2..4.
    new segStart = atpos + 1, segCount = 0, lastSegLen = 0;
    if (segStart >= len) return false; // nothing after '@'

    for (new i = segStart; i <= len; i++)
    {
        if (i == len || email[i] == '.')
        {
            new segLen = i - segStart;
            if (segLen < 1) return false; // empty label (leading/trailing/double dot)

            for (new j = segStart; j < i; j++)
                if (!Email_IsWordChar(email[j]) && email[j] != '-')
                    return false;

            segCount++;
            lastSegLen = segLen;
            segStart = i + 1;
        }
    }

    if (segCount < 2) return false;              // need at least label + tld
    return lastSegLen >= 2 && lastSegLen <= 4;   // [\w-]{2,4}
}
