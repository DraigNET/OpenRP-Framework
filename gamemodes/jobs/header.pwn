// ============================================================================
// File: jobs/header.pwn
// Includes every job and starts them (Jobs_Init). Add a new job by including it here and
// calling its LoadEntities from Jobs_Init.
// ============================================================================


/*AddStaticVehicle(481,2745.7878,-2457.5078,13.1628,165.0299,179,1); // forklift_2
AddStaticVehicle(481,2742.2478,-2457.0244,13.1629,168.9156,179,1); // forklift_3*/

//#include "jobs/dockworker/header.pwn"
#include "jobs/trucker/header.pwn"
#include "jobs/garbage/header.pwn"
#include "jobs/fishing/header.pwn"
#include "jobs/pizza/header.pwn"
//#include "jobs/boatyard/header.pwn"


Jobs_Init() {

	//Job_Dockworker_Init() ;
	Trucker_LoadEntities();
	GarbageJob_LoadEntities();
	//BoatyardJob_LoadEntities();
	//ORP_AddStaticVehicle(537, 2154.3022,-672.2773,53.5877,233.0631, 1, 1);
}

#include <YSI_Coding\y_hooks>
/*hook OnPlayerConnect(playerid) {
	FTJ_OnPlayerConnect(playerid);
	return 1;
}

hook OnPlayerEnterDynamicArea(playerid, STREAMER_TAG_AREA:areaid) {
	FTJ_OnPlayerEnterArea(playerid, areaid);
	return 1;
}*/

stock SendDebug(msg[])
{
	SendClientMessageToAll(-1, msg);
	return 1;
}
