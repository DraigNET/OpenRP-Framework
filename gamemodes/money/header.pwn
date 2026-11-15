// ============================================================================
// File: money/header.pwn
// Money helper: IntegerWithDelimiter() formats numbers like 1,250,000.
// ============================================================================


#include "money/paying.pwn"
#include "money/admin.pwn"
#include "money/snapshots.pwn"


IntegerWithDelimiter(integer, const delimiter[] = ",") {
    new string[16];

    format(string, sizeof string, "%i", integer);

    for (new i = strlen(string) - 3, j = ((integer < 0) ? 1 : 0); i > j; i -= 3) {

        strins(string, delimiter, i, sizeof string);
    }

    return string;
}
