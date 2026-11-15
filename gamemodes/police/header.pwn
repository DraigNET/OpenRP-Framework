// ============================================================================
// File: police/header.pwn
// Police module entry point. IsPlayerInLEAFaction() and friends are CAPABILITY based: any
// faction with the FAC_CAP_LAW bit counts as law enforcement, so a new agency needs no code
// changes.
// ============================================================================

#include "police/systems/header.pwn"
#include "police/detaining/header.pwn"
#include "police/stun/header.pwn"



IsPlayerInLEAFaction(playerid, bool:onduty=false) 
{
    // Now capability-driven: any faction with the LAW bit is law enforcement.
    // Add an agency and set its LAW capability - covered everywhere, no edits.
    return Faction_Can(playerid, FAC_CAP_LAW, onduty);
}

IsPlayerInPoliceFaction(playerid, bool:onduty=false) 
{
    return IsPlayerInFactionType(playerid, FACTION_TYPE_LEO, onduty);
}

stock IsPlayerInFederalFaction(playerid, bool:onduty=false)
{
    return IsPlayerInFactionType(playerid, FACTION_TYPE_FEDERAL, onduty);
}

IsPlayerInSecurityFaction(playerid, bool:onduty=false) 
{
    return IsPlayerInFactionType(playerid, FACTION_TYPE_SECURITY, onduty);
}

