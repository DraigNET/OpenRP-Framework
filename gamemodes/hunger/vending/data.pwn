// ============================================================================
// File: hunger/vending/data.pwn
// Vending machine locations (x, y, z, rotation) and creation. Removes the default GTA machines
// and places new ones. Admin tools: /tpvend, /editvend.
// Commands: /tpvend /editvend
// ============================================================================

enum E_VENDING_MACHINE {
      	e_Model,
      	e_Interior,
		Float:e_PosX,
		Float:e_PosY,
		Float:e_PosZ,
		Float:e_RotX,
		Float:e_RotY,
		Float:e_RotZ,
		Float:e_FrontX,
		Float:e_FrontY
	}

new const Float:sc_VendingMachines[][E_VENDING_MACHINE] = {
		{E_VENDING_MACHINE_SPRUNK, 0, -862.82, 1536.59, 22.65, 0.00, 0.00, 180.00, -861.82, 1536.59},
		{E_VENDING_MACHINE_ECOLA, 0, 2271.71, -76.45, 26.67, 0.00, 0.00, 0.00, 2270.71, -76.45}, // Machine 1 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 1277.82, 372.51, 19.65, 0.00, 0.00, 64.00, 1277.39, 371.61}, // Machine 2 updated
		{E_VENDING_MACHINE_ECOLA, 0, 662.41, -552.15, 16.41, 0.00, 0.00, 180.00, 663.41, -552.15}, // Machine 3 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 201.00, -107.61, 1.57, 0.00, 0.00, 270.00, 201.00, -106.61}, // Machine 4 updated
		{E_VENDING_MACHINE_SPRUNK, 0, -253.74, 2597.94, 62.90, 0.00, 0.00, 90.00, -253.74, 2596.94}, // Machine 5 updated
		{E_VENDING_MACHINE_ECOLA, 0, -253.74, 2599.75, 62.94, 0.00, 0.00, 90.00, -253.74, 2598.75}, // Machine 6 updated
		{E_VENDING_MACHINE_ECOLA, 0, -76.02, 1227.98, 19.84, 0.00, 0.00, 90.00, -76.02, 1226.98}, // Machine 7 updated
		{E_VENDING_MACHINE_SPRUNK, 0, -14.69, 1175.34, 19.62, 0.00, 0.00, 180.00, -13.69, 1175.34}, // Machine 8 updated
		{E_VENDING_MACHINE_ECOLA, 7, 316.86, -140.35, 999.69, 0.00, 0.00, 270.00, 316.86, -139.35}, // Machine 9 updated
		{E_VENDING_MACHINE_SPRUNK, 17, 373.82, -178.14, 1000.73, 0.00, 0.00, 0.00, 373.82, -179.14},
		{E_VENDING_MACHINE_ECOLA, 17, 379.03, -178.88, 1000.73, 0.00, 0.00, 270.00, 378.03, -178.90},
		{E_VENDING_MACHINE_SPRUNK, 17, 495.96, -24.32, 1000.73, 0.00, 0.00, 180.00, 495.95, -23.32},
		{E_VENDING_MACHINE_ECOLA, 17, 500.56, -1.36, 1000.73, 0.00, 0.00, 0.00, 500.56, -2.36},
		{E_VENDING_MACHINE_SPRUNK, 17, 501.82, -1.42, 1000.73, 0.00, 0.00, 0.00, 501.82, -2.42},
		{E_VENDING_MACHINE_ECOLA, 0, -1455.10, 2591.65, 55.91, 0.00, 0.00, 180.00, -1454.10, 2591.65}, // Machine 15 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 2352.16, -1357.15, 24.46, 0.00, 0.00, 90.00, 2352.16, -1358.15}, // Machine 16 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 2325.96, -1645.13, 14.90, 0.00, 0.00, 0.00, 2324.96, -1645.13}, // Machine 17 updated
		{E_VENDING_MACHINE_ECOLA, 0, 2139.51, -1161.47, 24.08, 0.00, 0.00, 87.00, 2139.45, -1162.47}, // Machine 18 updated
		{E_VENDING_MACHINE_ECOLA, 0, 2153.22, -1016.14, 62.95, 0.00, 0.00, 127.00, 2153.83, -1016.93}, // Machine 19 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 1928.72, -1772.43, 13.66, 0.00, 0.00, 90.00, 1928.72, -1773.43}, // Machine 20 updated
		{E_VENDING_MACHINE_ECOLA, 1, 2222.36, 1602.64, 1000.06, 0.00, 0.00, 90.00, 2223.36, 1602.64},
		{E_VENDING_MACHINE_SPRUNK, 1, 2222.20, 1606.77, 1000.05, 0.00, 0.00, 90.00, 2223.20, 1606.77},
		{E_VENDING_MACHINE_SPRUNK, 1, 2155.90, 1606.77, 1000.05, 0.00, 0.00, 90.00, 2156.90, 1606.77},
		{E_VENDING_MACHINE_SPRUNK, 1, 2209.90, 1607.19, 1000.05, 0.00, 0.00, 270.00, 2208.90, 1607.17},
		{E_VENDING_MACHINE_ECOLA, 1, 2155.84, 1607.87, 1000.06, 0.00, 0.00, 90.00, 2156.84, 1607.87},
		{E_VENDING_MACHINE_ECOLA, 1, 2202.45, 1617.00, 1000.06, 0.00, 0.00, 180.00, 2202.43, 1618.00},
		{E_VENDING_MACHINE_ECOLA, 1, 2209.24, 1621.21, 1000.06, 0.00, 0.00, 0.00, 2209.24, 1620.21},
		{E_VENDING_MACHINE_ECOLA, 3, 330.67, 178.50, 1020.07, 0.00, 0.00, 0.00, 330.67, 177.50},
		{E_VENDING_MACHINE_ECOLA, 3, 331.92, 178.50, 1020.07, 0.00, 0.00, 0.00, 331.92, 177.50},
		{E_VENDING_MACHINE_ECOLA, 3, 350.90, 206.08, 1008.47, 0.00, 0.00, 90.00, 351.90, 206.08},
		{E_VENDING_MACHINE_ECOLA, 3, 361.56, 158.61, 1008.47, 0.00, 0.00, 180.00, 361.54, 159.61},
		{E_VENDING_MACHINE_ECOLA, 3, 371.59, 178.45, 1020.07, 0.00, 0.00, 0.00, 371.59, 177.45},
		{E_VENDING_MACHINE_ECOLA, 3, 374.89, 188.97, 1008.47, 0.00, 0.00, 0.00, 374.89, 187.97},
		{E_VENDING_MACHINE_SPRUNK, 2, 2576.70, -1284.43, 1061.09, 0.00, 0.00, 270.00, 2575.70, -1284.44},
		{E_VENDING_MACHINE_SPRUNK, 15, 2225.20, -1153.42, 1025.90, 0.00, 0.00, 270.00, 2224.20, -1153.43},
		//{E_VENDING_MACHINE_SPRUNK, 0, 1154.71, -1460.89, 15.85, 0.00, 0.00, 270.00, 1154.71, -1459.89}, // Machine 36 updated
		{E_VENDING_MACHINE_ECOLA, 0, 2480.85, -1959.27, 13.66, 0.00, 0.00, 180.00, 2481.85, -1959.27}, // Machine 37 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 2060.11, -1897.64, 13.62, 0.00, 0.00, 0.00, 2059.11, -1897.64}, // Machine 38 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 1729.78, -1943.04, 13.65, 0.00, 0.00, 0.00, 1728.78, -1943.04}, // Machine 39 updated
		{E_VENDING_MACHINE_ECOLA, 0, 1634.09, -2237.53, 13.61, 0.00, 0.00, 0.00, 1633.09, -2237.53}, // Machine 40 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 1789.20, -1369.26, 15.82, 0.00, 0.00, 270.00, 1789.20, -1368.26}, // Machine 41 updated
		{E_VENDING_MACHINE_ECOLA, 0, -2229.17, 286.41, 35.40, 0.00, 0.00, 180.00, -2228.17, 286.41}, // Machine 42 updated
		{E_VENDING_MACHINE_SPRUNK, 256, -1980.78, 142.66, 27.07, 0.00, 0.00, 270.00, -1981.78, 142.64},
		{E_VENDING_MACHINE_SPRUNK, 256, -2118.96, -423.64, 34.72, 0.00, 0.00, 255.00, -2119.93, -423.40},
		{E_VENDING_MACHINE_SPRUNK, 256, -2118.61, -422.41, 34.72, 0.00, 0.00, 255.00, -2119.58, -422.17},
		{E_VENDING_MACHINE_SPRUNK, 256, -2097.27, -398.33, 34.72, 0.00, 0.00, 180.00, -2097.29, -397.33},
		{E_VENDING_MACHINE_SPRUNK, 256, -2092.08, -490.05, 34.72, 0.00, 0.00, 0.00, -2092.08, -491.05},
		{E_VENDING_MACHINE_SPRUNK, 256, -2063.27, -490.05, 34.72, 0.00, 0.00, 0.00, -2063.27, -491.05},
		{E_VENDING_MACHINE_SPRUNK, 256, -2005.64, -490.05, 34.72, 0.00, 0.00, 0.00, -2005.64, -491.05},
		{E_VENDING_MACHINE_SPRUNK, 256, -2034.46, -490.05, 34.72, 0.00, 0.00, 0.00, -2034.46, -491.05},
		{E_VENDING_MACHINE_SPRUNK, 256, -2068.56, -398.33, 34.72, 0.00, 0.00, 180.00, -2068.58, -397.33},
		{E_VENDING_MACHINE_SPRUNK, 256, -2039.85, -398.33, 34.72, 0.00, 0.00, 180.00, -2039.86, -397.33},
		{E_VENDING_MACHINE_SPRUNK, 256, -2011.14, -398.33, 34.72, 0.00, 0.00, 180.00, -2011.15, -397.33},
		{E_VENDING_MACHINE_SPRUNK, 2048, -1350.11, 492.28, 10.58, 0.00, 0.00, 90.00, -1349.11, 492.28},
		{E_VENDING_MACHINE_ECOLA, 2048, -1350.11, 493.85, 10.58, 0.00, 0.00, 90.00, -1349.11, 493.85},
		{E_VENDING_MACHINE_SPRUNK, 0, 2319.98, 2532.85, 10.90, 0.00, 0.00, 0.00, 2318.98, 2532.85}, // Machine 56 updated
		{E_VENDING_MACHINE_ECOLA, 0, 2845.71, 1295.04, 11.48, 0.00, 0.00, 0.00, 2844.71, 1295.04}, // Machine 57 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 2503.13, 1243.68, 10.92, 0.00, 0.00, 180.00, 2504.13, 1243.68}, // Machine 58 updated
		{E_VENDING_MACHINE_ECOLA, 0, 2647.68, 1129.66, 11.26, 0.00, 0.00, 0.00, 2646.68, 1129.66}, // Machine 59 updated
		{E_VENDING_MACHINE_ECOLA, 0, -2420.20, 984.57, 45.38, 0.00, 0.00, 90.00, -2420.20, 983.57}, // Machine 60 updated
		{E_VENDING_MACHINE_ECOLA, 0, -2420.16, 985.94, 45.39, 0.00, 0.00, 90.00, -2420.16, 984.94}, // Machine 61 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 2085.77, 2071.35, 11.14, 0.00, 0.00, 90.00, 2085.77, 2070.35}, // Machine 62 updated
		{E_VENDING_MACHINE_ECOLA, 0, 1398.83, 2222.60, 11.13, 0.00, 0.00, 180.00, 1399.83, 2222.60}, // Machine 63 updated
		{E_VENDING_MACHINE_ECOLA, 0, 1659.45, 1722.84, 10.89, 0.00, 0.00, 0.00, 1658.45, 1722.84}, // Machine 64 updated
		{E_VENDING_MACHINE_SPRUNK, 0, 1520.14, 1055.26, 10.92, 0.00, 0.00, 270.00, 1520.14, 1056.26}, // Machine 65 updated
		{E_VENDING_MACHINE_SPRUNK, 6, -19.03, -57.83, 1003.63, 0.00, 0.00, 180.00, -19.05, -56.83},
		{E_VENDING_MACHINE_SPRUNK, 18, -16.11, -91.64, 1003.63, 0.00, 0.00, 180.00, -16.13, -90.64},
		{E_VENDING_MACHINE_SPRUNK, 16, -15.10, -140.22, 1003.63, 0.00, 0.00, 180.00, -15.11, -139.22},
		{E_VENDING_MACHINE_SPRUNK, 17, -32.44, -186.69, 1003.63, 0.00, 0.00, 180.00, -32.46, -185.69},
		{E_VENDING_MACHINE_SPRUNK, 16, -35.72, -140.22, 1003.63, 0.00, 0.00, 180.00, -35.74, -139.22},
		{E_VENDING_MACHINE_ECOLA, 6, -36.14, -57.87, 1003.63, 0.00, 0.00, 180.00, -36.16, -56.87},
		{E_VENDING_MACHINE_ECOLA, 18, -17.54, -91.71, 1003.63, 0.00, 0.00, 180.00, -17.56, -90.71},
		{E_VENDING_MACHINE_ECOLA, 16, -16.53, -140.29, 1003.63, 0.00, 0.00, 180.00, -16.54, -139.29},
		{E_VENDING_MACHINE_ECOLA, 17, -33.87, -186.76, 1003.63, 0.00, 0.00, 180.00, -33.89, -185.76},

		// Custom LSFD
		{E_VENDING_MACHINE_ECOLA, 0, 1826.515, -1441.716, 12.95, 0.00, 0.00, 270.00, 1825.515, -1441.716}	
	};
new s_VendingMachineObject[sizeof(sc_VendingMachines)] = {-1, ...};
new s_VendingMachineArea[sizeof(sc_VendingMachines)] = {-1, ...};

#include <YSI_Coding\y_hooks>
hook OnRemoveBuilding() {
	RemoveDefaultVendingMachines();
}

// Removes the default GTA vending machines from the map so ours replace them.
stock RemoveDefaultVendingMachines() {
	RemoveBuilding(955, 0.0, 0.0, 0.0, 10000.0); // CJ_EXT_SPRUNK
	RemoveBuilding(956, 0.0, 0.0, 0.0, 10000.0); // CJ_EXT_CANDY
	RemoveBuilding(1209, 0.0, 0.0, 0.0, 10000.0); // vendmach
	RemoveBuilding(1302, 0.0, 0.0, 0.0, 10000.0); // vendmachfd
	RemoveBuilding(1775, 0.0, 0.0, 0.0, 10000.0); // CJ_SPRUNK1
	RemoveBuilding(1776, 0.0, 0.0, 0.0, 10000.0); // CJ_CANDYVENDOR
	RemoveBuilding(1977, 1826.515, -1441.716, 12.95, 256); // vendin3

	/*
	// Make sure they're all gone..
	for (new i = 0; i < sizeof(sc_VendingMachines); i++) {
		RemoveBuilding(
			playerid,
			sc_VendingMachines[i][e_Model],
			sc_VendingMachines[i][e_PosX],
			sc_VendingMachines[i][e_PosY],
			sc_VendingMachines[i][e_PosZ],
			1.0
		);
	}*/
}

// Creates every vending machine object and its trigger area from the sc_VendingMachines table.
CreateVendingMachines() {

	for (new i = 0; i < sizeof(sc_VendingMachines); i++) {

		s_VendingMachineObject[i] = CreateDynamicObject(
			sc_VendingMachines[i][e_Model],
			sc_VendingMachines[i][e_PosX],
			sc_VendingMachines[i][e_PosY],
			sc_VendingMachines[i][e_PosZ],
			sc_VendingMachines[i][e_RotX],
			sc_VendingMachines[i][e_RotY],
			sc_VendingMachines[i][e_RotZ],
			.interiorid = sc_VendingMachines[i][e_Interior]
		);

		s_VendingMachineArea[i] = CreateDynamicCircle(
			sc_VendingMachines[i][e_PosX], 
			sc_VendingMachines[i][e_PosY], 
			2.0, 
			.interiorid = sc_VendingMachines[i][e_Interior] 
		); 
	}
}


// /tpvend [id] - (admin) teleports to a vending machine.
CMD:tpvend(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_GENERAL)
        return SendClientMessage(playerid, COLOR_ERROR, "You don't have permission to use this command.");


    new vendingid;
    if(sscanf(params, "i", vendingid))
        return SendClientMessage(playerid, COLOR_RED, "USAGE: /tpvend [vending_id]");
        
    if(vendingid < 0 || vendingid >= sizeof(sc_VendingMachines))
        return SendClientMessage(playerid, COLOR_RED, "Invalid vending machine ID!");
        
    new targetInterior = sc_VendingMachines[vendingid][e_Interior];
    
    SetPlayerInterior(playerid, targetInterior);
    SetPlayerPos(playerid, 
        sc_VendingMachines[vendingid][e_FrontX],
        sc_VendingMachines[vendingid][e_FrontY],
        sc_VendingMachines[vendingid][e_PosZ]
    );
    
    new Float:angle = sc_VendingMachines[vendingid][e_RotZ] - 180.0;
    SetPlayerFacingAngle(playerid, angle);
    
    new string[128];
    format(string, sizeof(string), "Teleported to vending machine ID: %d (Model: %d, Interior: %d)", 
        vendingid, 
        sc_VendingMachines[vendingid][e_Model],
        targetInterior
    );
    SendClientMessage(playerid, COLOR_GREEN, string);
    
    return 1;
}

/*
// /editvend - (admin) lets you move the nearest vending machine with the object editor.
CMD:editvend(playerid, params[])
{
    new closestVending = -1;
    new Float:closestDistance = 5.0;
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    
    for(new i = 0; i < sizeof(sc_VendingMachines); i++)
    {
        new Float:distance = GetDistanceBetweenPoints(px, py, pz,sc_VendingMachines[i][e_PosX],sc_VendingMachines[i][e_PosY],sc_VendingMachines[i][e_PosZ]);
        
        if(distance < closestDistance)
        {
            closestDistance = distance;
            closestVending = i;
        }
    }
    
    if(closestVending == -1)
        return SendClientMessage(playerid, COLOR_RED, "No vending machines nearby");
        
    gVendingOriginalPos[playerid][0] = sc_VendingMachines[closestVending][e_PosX];
    gVendingOriginalPos[playerid][1] = sc_VendingMachines[closestVending][e_PosY];
    gVendingOriginalPos[playerid][2] = sc_VendingMachines[closestVending][e_PosZ];
    gVendingOriginalRot[playerid][0] = sc_VendingMachines[closestVending][e_RotX];
    gVendingOriginalRot[playerid][1] = sc_VendingMachines[closestVending][e_RotY];
    gVendingOriginalRot[playerid][2] = sc_VendingMachines[closestVending][e_RotZ];
    
    PlayerVending[playerid][E_PLAYER_VENDING_ID] = closestVending;
    PlayerVending[playerid][E_PLAYER_VENDING_EDITING] = true;
    
    EditDynamicObject(playerid, s_VendingMachineObject[closestVending]);
    
    new string[128];
    format(string, sizeof(string), "Now editing vending machine ID: %d (Model: %d)", 
        closestVending, 
        sc_VendingMachines[closestVending][e_Model]
    );
    SendClientMessage(playerid, COLOR_GREEN, string);
    
    return 1;
}
// Handles the object editor result for moving a vending machine.
public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    
    if(!PlayerVending[playerid][E_PLAYER_VENDING_EDITING])
        return 1;
        
    new vendingid = PlayerVending[playerid][E_PLAYER_VENDING_ID];   
    switch(response)
    {
        case EDIT_RESPONSE_FINAL:
        {
            new Float:angle = rz + 90.0; // 90 degrees to the right of rotation
            new Float:frontX = x + (1.0 * floatsin(-angle, degrees));
            new Float:frontY = y + (1.0 * floatcos(-angle, degrees));
            
            printf("{E_VENDING_MACHINE_%s, %d, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f},",
                (sc_VendingMachines[vendingid][e_Model] == E_VENDING_MACHINE_SPRUNK) ? "SPRUNK" : "ECOLA",
                sc_VendingMachines[vendingid][e_Interior],
                x, y, z, rx, ry, rz,
                frontX, frontY
            );
            
            DestroyDynamicArea(s_VendingMachineArea[vendingid]);
            s_VendingMachineArea[vendingid] = CreateDynamicCircle(x, y, 2.0, .interiorid = sc_VendingMachines[vendingid][e_Interior]);
            
            SendClientMessage(playerid, COLOR_GREEN, "Vending machine position updated. new coordinates printed to console.");
            
            PlayerVending[playerid][E_PLAYER_VENDING_ID] = -1;
            PlayerVending[playerid][E_PLAYER_VENDING_EDITING] = false;
        }
        
        case EDIT_RESPONSE_CANCEL:
        {
            SetDynamicObjectPos(s_VendingMachineObject[vendingid], 
                gVendingOriginalPos[playerid][0], 
                gVendingOriginalPos[playerid][1], 
                gVendingOriginalPos[playerid][2]
            );
            SetDynamicObjectRot(s_VendingMachineObject[vendingid],
                gVendingOriginalRot[playerid][0], 
                gVendingOriginalRot[playerid][1], 
                gVendingOriginalRot[playerid][2]
            );
            SendClientMessage(playerid, COLOR_RED, "Vending machine edit cancelled!");
            
            PlayerVending[playerid][E_PLAYER_VENDING_ID] = -1;
            PlayerVending[playerid][E_PLAYER_VENDING_EDITING] = false;
        }
        
        case EDIT_RESPONSE_UPDATE:
        {
			SetDynamicObjectPos(s_VendingMachineObject[vendingid], x, y, z);
			SetDynamicObjectRot(s_VendingMachineObject[vendingid], rx, ry, rz);
        }
    }
    
    #if defined vd_OnPlayerEditDynamicObject
        return vd_OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz);
    #else
        return 1;
    #endif
}

#if defined _ALS_OnPlayerEditDynamicObject
	#undef OnPlayerEditDynamicObject
#else
	#define _ALS_OnPlayerEditDynamicObject
#endif

#define OnPlayerEditDynamicObject vd_OnPlayerEditDynamicObject
#if defined vd_OnPlayerEditDynamicObject
	forward vd_OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz);
#endif

*/
