// ============================================================================
// File: gps/header.pwn
// Includes the GPS files and defines /clearcp (/nocp, /cleargps, /removecp) to remove the
// current map marker or checkpoint.
// Commands: /clearcp /nocp /cleargps /removecp /deletecp
// ============================================================================

#include "gps/data.pwn"
#include "gps/utils.pwn"
#include "gps/func.pwn"

CMD:clearcp(playerid) 
{
	GPS_ClearCheckpoint(playerid);
	SendClientMessage(playerid, -1, "Removed all visible synced checkpoints. Your GPS has also been reset.");

	return true ;
}

CMD:nocp(playerid) return cmd_clearcp(playerid);
CMD:cleargps(playerid) return cmd_clearcp(playerid);
CMD:removecp(playerid) return cmd_clearcp(playerid);
CMD:deletecp(playerid) return cmd_clearcp(playerid);