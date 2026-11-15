// ============================================================================
// File: drugs/header.pwn
// Main drug system: planting, watering, cooking, harvesting and carrying. Commands include
// /drugsetup, /drugwater, /drugcook, /drugcollect, /drugmerge, /mydrugs and /dropdrug.
// Commands: /drugsnear /mydrugs /drugmerge /drugsetup /drugwater /drugcook /drugproduce
// /drugcollect /dropdrug
// ============================================================================

/*

	Drugs System

		There are 3 NPC "cartels" on each island (LS, SF, LV). They are each tied to a drug. You can buy the ingredients required
		to produce the drug yourself. This is the only purpose of these cartels. The player is meant to produce and supply the drugs.

		You now have 25 slots to put drugs in. This is meant to overhaul the buggy /mydrugs.
		Add a "potency" depending on cook effort, plant water effort, etc.  This adds to the base effect (healing, dmg, armour)

		(For cocaine, crack and meth)
			Add an addiction system that takes into account amount of drugs taken, last time drugs taken and do damage based on that.
			

		Weed
			We added weed as a healing drug. You buy seeds from the cartel in Los Sanros and grow the plant. 
			When you smoke a blunt you have a change to get healed 0.5 to 3.5dmg depending on the strain. 
			Types: Maui Waui, O.G. Kush, Purple Kush, Northern Lights, Silver Haze

		Cocaine

			Cocaine gives you extra melee damage depending on type (.5 to 3.5). This has to be grown in Las Venturas 
			due to the climate - you buy seeds at the cartel from San Fierro. Types TBA (3)

		Crack
			Crack gives you some armour (15 to 45 based on type). It is cooked in a pot and you need some cheaply 
			cut cocaine which you can buy from the cartel in San Fierro. Types: TBA (3)

		Meth
			Meth is the most elaborate and expensive drug. It gives you extra melee damage and some armour depending 
			on type. The downside is that it takes some health in return and makes you weaker to hits. You need to 
			chemically produce it similar to PD2. types TBA (3)

		Steroids
			Steroids do some health damage but allow you to increase your stamina / muscle at an increased rate
			for a limited amount of time. Any faction with drug links can sell steroids. Types: Powder, Pills, Syringe.
			Based on type the time lasts longer and the increased rate is higher.


*/

forward Float: Drugs_GetPackageMaxWeight(idx) ;

#include "drugs/data.pwn"

#include "drugs/packages/header.pwn"
#include "drugs/data/header.pwn"
#include "drugs/player/header.pwn"
#include "drugs/cartel/header.pwn"

#include "drugs/utils.pwn"
#include "drugs/func.pwn"
#include "drugs/dev.pwn"
#include "drugs/vehicle.pwn" // MOved to vehicle module

// Loads all drug plants and labs and starts their growth.
Drugs_LoadEntities() {
	for ( new i, j = sizeof ( Drugs ); i < j ; i ++ ) {

		Drugs [ i ] [ E_DRUG_SQLID ] = INVALID_DRUG_ID ;
		Drugs [ i ] [ E_DRUG_OBJECT ] = INVALID_STREAMER_ID ;
		Drugs [ i ] [ E_DRUG_OBJECT_EXTRA ] = INVALID_STREAMER_ID ;
		Drugs [ i ] [ E_DRUG_LABEL ] = DynamicText3D:INVALID_STREAMER_ID ;
	}

	for ( new i , j = MAX_PLAYERS; i < j ; i ++ ) {

		for ( new x, y = MAX_PLAYER_DRUGS; x < y ; x ++ ) {

			PlayerDrugs [ i ] [ x ] [ E_PLAYER_DRUG_SQLID ] = INVALID_DRUG_ID ;
		}
	}

	Drugs_LoadEntity() ;
	Cartel_LoadEntities() ;
}


// /drugsnear - tells you which drug plant/lab id is next to you.
CMD:drugsnear(playerid, params[]) {

	new nearid = Drugs_GetClosestEntity ( playerid ) ;

	if ( nearid == INVALID_DRUG_ID ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Not near plant!" ) ;
	}

	SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("Nearest plant (lowest ID fetched): %d", nearid ) ) ;

	return true ;
}

// /mydrugs - lists the drugs you carry.
CMD:mydrugs(playerid, params[]) {

	ShowPlayerDrugsDlg(playerid, playerid);
	SendClientMessage(playerid, COLOR_YELLOW, "To see your supplies, use /drugsupplies. For packages, use /drugpackages.");

	return true ;
}

static drugs_dlg_str[2048];

// Shows the drugs dialog for a player (slot, amount, name, type); `print` writes them to chat
// instead.
ShowPlayerDrugsDlg(playerid, targetid, bool:print=false)
{
	
	format(drugs_dlg_str, sizeof(drugs_dlg_str), "Slot\tDrug Amount\tDrug Name\tDrug Type");
	new drug_name [ 32 ], drug_type [ 32 ], package_name [ 32 ], bool: resave = false, count = 0;

	if (print) { SendClientMessage(playerid, COLOR_BLUE, sprintf("Drugs of %s:", ReturnSettingsName(targetid, playerid))); } 

	for ( new i, j = MAX_PLAYER_DRUGS; i < j ; i ++ ) {

		if ( PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_TYPE ] != E_DRUG_TYPE_NONE ) {


			if ( PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_AMOUNT ] < 0.01 ) {
				PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_TYPE ] 		= E_DRUG_TYPE_NONE ;
				PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_SQLID ] 		= -1 ;
				PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_TYPE ] 		= 0 ;
				PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_PARAM ] 		= 0 ;
				PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_CONTAINER ] 	= 0 ;
				PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_AMOUNT ]		= 0.0 ;

				resave = true ;
				continue ;
			}

			Drugs_GetParamName ( PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_TYPE ], 
				PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_PARAM ], drug_name 
			) ;

			Drugs_GetPackageName ( PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_CONTAINER ], package_name ) ;

			Drugs_GetTypeName(PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_TYPE ], drug_type ) ;

			if (print)
			{
				SendClientMessage(playerid, COLOR_DRUGS, sprintf("[Slot %d]{DEDEDE} %.02fgr of %s stored in a %s. {FFFF00}[%s] ",
					i, PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_AMOUNT ], drug_name, package_name, drug_type
				) ) ;

			} else {
			 	format(drugs_dlg_str, sizeof(drugs_dlg_str), "%s\n{F48FB1}Slot %d\t%.02fg (%s)\t%s\t%s", drugs_dlg_str, i, PlayerDrugs [ playerid ] [ i ] [ E_PLAYER_DRUG_AMOUNT ], package_name, drug_name, drug_type);
			}

			count++;
		}
	}

	if (count == 0) {
		if (print) SendClientMessage(playerid, COLOR_RED, "No drugs found.");
		else format(drugs_dlg_str, sizeof(drugs_dlg_str), "%s\n{FFAB91}No drugs found.", drugs_dlg_str);
	}

	if ( resave ) {

		PlayerDrugs_Save(playerid) ;
	}


	inline DrugsDlg(pid, dialogid, response, listitem, string:inputtext[]) 
	{
        #pragma unused pid, dialogid, inputtext, listitem

		if (response)
		{
			ShowPlayerDrugsDlg(playerid, targetid, true);
		}
    }

	if (!print)
	{
		Dialog_ShowCallback ( playerid, using inline DrugsDlg, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Drugs of %s", ReturnSettingsName(targetid, playerid)), drugs_dlg_str, "Print", "Close" );
		return 1;
	}

	return 1;
}

CMD:drugmerge (playerid, params[]) {

	if(IsPlayerIncapacitated(playerid, false))
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use this command right now!");

	new slot1, slot2;
	new drug_name [ 32 ], drug_type [ 32 ], package_name [ 32 ];

	if(sscanf(params, "ii", slot1, slot2)) {
		SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/drugmerge [slot1] [slot2]");
		return SendServerMessage(playerid, COLOR_ERROR, "Info", "A3A3A3", "The container type will be the same as slot1.");
	}

	if(slot1 < 0 || slot1 > MAX_PLAYER_DRUGS) 
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have that many slots.");

	if(slot2 < 0 || slot2 > MAX_PLAYER_DRUGS) 
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have that many slots.");
 
	// check if both slots are valid ( 2 if statements are used to the player knows which slot is faulty.)

	if( PlayerDrugs[playerid][slot1][E_PLAYER_DRUG_AMOUNT] < 0.01 )
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have anything in slot 1.");

	if( PlayerDrugs[playerid][slot2][E_PLAYER_DRUG_AMOUNT] < 0.01 )
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You don't have anything in slot 2.");

	// check if both slots are the same type.

	if(PlayerDrugs[playerid][slot1][E_PLAYER_DRUG_TYPE] != PlayerDrugs[playerid][slot2][E_PLAYER_DRUG_TYPE])
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only merge drugs of the same type.");

	if(PlayerDrugs[playerid][slot1][E_PLAYER_DRUG_PARAM] != PlayerDrugs[playerid][slot2][E_PLAYER_DRUG_PARAM])
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can only merge drugs of the same kind.");

	if( PlayerDrugs [ playerid ] [ slot1 ] [E_PLAYER_DRUG_AMOUNT] + PlayerDrugs [ playerid ] [ slot2 ] [E_PLAYER_DRUG_AMOUNT] > 50.0)
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Merge limit exceeded. You cannot merge that much.");

	PlayerDrugs [ playerid ] [ slot1 ] [E_PLAYER_DRUG_AMOUNT] += PlayerDrugs [ playerid ] [ slot2 ] [E_PLAYER_DRUG_AMOUNT];

	// reset slot2 data.
	PlayerDrugs [ playerid ] [ slot2 ] [ E_PLAYER_DRUG_TYPE ] 		= E_DRUG_TYPE_NONE ;
	PlayerDrugs [ playerid ] [ slot2 ] [ E_PLAYER_DRUG_SQLID ] 		= -1 ;
	PlayerDrugs [ playerid ] [ slot2 ] [ E_PLAYER_DRUG_TYPE ] 		= 0 ;
	PlayerDrugs [ playerid ] [ slot2 ] [ E_PLAYER_DRUG_PARAM ] 		= 0 ;
	PlayerDrugs [ playerid ] [ slot2 ] [ E_PLAYER_DRUG_CONTAINER ] 	= 0 ;
	PlayerDrugs [ playerid ] [ slot2 ] [ E_PLAYER_DRUG_AMOUNT ]		= 0.0 ;

	new nslot = PlayerDrugs_GetFreeID(playerid);

	// move all slot1 data into new slot;

	PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_TYPE ] 		= PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_TYPE ];
	PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_SQLID ] 		= PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_SQLID ]; 
	PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_TYPE ] 		= PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_TYPE ];
	PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_PARAM ] 		= PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_PARAM ];
	PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_CONTAINER ] 	= PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_CONTAINER ];
	PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_AMOUNT ]		= PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_AMOUNT ];

	// reset slot1 data.

	PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_TYPE ] 		= E_DRUG_TYPE_NONE ;
	PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_SQLID ] 		= -1 ;
	PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_TYPE ] 		= 0 ;
	PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_PARAM ] 		= 0 ;
	PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_CONTAINER ] 	= 0 ;
	PlayerDrugs [ playerid ] [ slot1 ] [ E_PLAYER_DRUG_AMOUNT ]		= 0.0 ;


	Drugs_GetParamName ( PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_TYPE ], 
		PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_PARAM ], drug_name 
	) ;

	Drugs_GetPackageName ( PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_CONTAINER ], package_name ) ;

	Drugs_GetTypeName(PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_TYPE ], drug_type ) ;

	SendServerMessage(playerid, COLOR_HINT, "Merge", "A3A3A3", sprintf("You have sucessfully merged the two slots into %.02fgr of %s stored in a %s.",
		PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_AMOUNT ], drug_name, package_name, drug_type
	));

	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", sprintf("merges some %s into a %s.", drug_name, package_name), .annonated=true);

	AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Merged two %s into one %.02fgr stored in a %s.", drug_name, PlayerDrugs [ playerid ] [ nslot ] [ E_PLAYER_DRUG_AMOUNT ], package_name ));

	// save drugs.
	PlayerDrugs_Save(playerid) ;

	return true;
}

// /drugsetup [weed/coke/crack/meth] [slot] - plants seeds or sets up a lab using one of your
// supplies.
CMD:drugsetup(playerid, params[]) {


	new input [ 32 ], slot ;
	new Float: x, Float: y, Float: z ;

	if ( sscanf ( params, "s[32]i", input, slot ) ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "/drugsetup [weed/coke/crack/meth] [slot] (/drugsupplies)" ) ;
	}

	if ( slot < 0 || slot > 2 ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Slot can't be less than 0 or more than 2." ) ;
	}

	if ( IsValidDynamicObject(PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ]) ) {
		ORP_DestroyObject(PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ], "Drugs/DrugSetup Creation", true ) ;

		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ] = -1 ;
		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ] = E_DRUG_TYPE_NONE ;
		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] = E_DRUG_TYPE_NONE ;
	}

	GetPlayerPos ( playerid, x, y, z ) ;
	x += 1.0, y += 1.0 ;

	if ( ! strcmp ( input, "weed", true ) ) {

		if ( ! Character [ playerid ] [ E_CHARACTER_WEED_SUPPLIES ] [ slot ] ) {

			return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "There's no drug ingredient in this slot!" ) ;
		}

		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ] = E_DRUG_TYPE_WEED ;
		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] = Character [ playerid ] [ E_CHARACTER_WEED_SUPPLIES ] [ slot ]  ;
	}

	else if ( ! strcmp ( input, "coke", true ) ) {

		if ( ! Character [ playerid ] [ E_CHARACTER_COKE_SUPPLIES ] [ slot ] ) {

			return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "There's no drug ingredient in this slot!" ) ;
		}

		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ] = E_DRUG_TYPE_COKE ;
		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] = Character [ playerid ] [ E_CHARACTER_COKE_SUPPLIES ] [ slot ]  ;
	}

	else if ( ! strcmp ( input, "crack", true ) ) {

		if ( ! Character [ playerid ] [ E_CHARACTER_CRACK_SUPPLIES ] [ slot ] ) {

			return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "There's no drug ingredient in this slot!" ) ;
		}

		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ] = E_DRUG_TYPE_CRACK ;
		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] = Character [ playerid ] [ E_CHARACTER_CRACK_SUPPLIES ] [ slot ]  ;
	}

	else if ( ! strcmp ( input, "meth", true ) ) {

		if ( ! Character [ playerid ] [ E_CHARACTER_METH_SUPPLIES ] [ slot ] ) {

			return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "There's no drug ingredient in this slot!" ) ;
		}

		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_TYPE  ] = E_DRUG_TYPE_METH ;
		PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_PARAM ] = Character [ playerid ] [ E_CHARACTER_METH_SUPPLIES ] [ slot ]  ;
	}

	else return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Param error: /drugsetup [weed/coke/crack/meth] [slot] (/drugsupplies)" ) ;

	PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ] = CreateDynamicObject(1271, x, y, z, 0.0, 0.0, 0.0, GetPlayerVirtualWorld(playerid), GetPlayerInterior ( playerid ) ) ;
	SetDynamicObjectMaterial(PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ], 0, 19519, "noncolored", "gen_white");
	EditDynamicObject(playerid,PlayerVar [ playerid ] [ E_PLAYER_DRUGS_PLACING_OBJECT ]);

	return true ;
}

CMD:drugwater(playerid, params[]) {

	return cmd_drugproduce(playerid, params);
}

CMD:drugcook(playerid, params[]) {

	return cmd_drugproduce(playerid, params);
}

// /drugproduce [id] - starts producing at a plant/lab you are next to.
CMD:drugproduce(playerid, params[]) {

	new id ;

	if ( sscanf ( params, "i", id ) ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "/drugproduce [id] (/drugwater, /drugcook)" ) ;
	}

	new Float: dist = Drugs_GetPlayerDistFromPoint(playerid, id) ;

	if ( dist >= 3.0 ) {
		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You're not near the plant!" ) ;
	}

	if (  Drugs [ id ] [ E_DRUG_STAGE ] == E_DRUG_STAGE_NONE) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Drug isn't set up." ) ;
	}
	if (  Drugs [ id ] [ E_DRUG_TYPE ] == E_DRUG_TYPE_NONE) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Drug isn't set up." ) ;
	}

	if ( Drugs [ id ] [ E_DRUG_STAGE ] == E_DRUG_STAGE_START ) {

		switch ( Drugs [ id ] [ E_DRUG_TYPE ] ) {
			case E_DRUG_TYPE_WEED: Weed_SetupGrowth(id);
			case E_DRUG_TYPE_COKE: Coke_SetupGrowth ( id ) ;
			case E_DRUG_TYPE_CRACK: Crack_SetupGrowth ( id ) ;
			//case E_DRUG_TYPE_METH: return true ;
		}
	}

	else SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "This drug is already in production." ) ;
	return true ;
}

// /drugcollect [id] [container] [amount] - collects the finished product into a container.
CMD:drugcollect(playerid, params[]) {

	new id, container, Float: amount ;

	if ( sscanf  (params, "iif", id, container, amount ) ) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "/drugcollect [id] [container] [amount] " ) ;
	}

	new Float: dist = Drugs_GetPlayerDistFromPoint(playerid, id) ;

	if ( dist >= 3.0 ) {
		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You're not near the plant!" ) ;
	}

	if (  Drugs [ id ] [ E_DRUG_STAGE ] == E_DRUG_STAGE_NONE) {

		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "Drug isn't set up." ) ;
	}

	if ( amount < 0.01 ) {
		return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You can't collect less than 0.01gr." ) ;
	}

	if ( Drugs [ id ] [ E_DRUG_STAGE ] == E_DRUG_STAGE_FINISH ) {

		if ( container < 0 || container > sizeof ( DrugPackages ) ) {

			return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("Container can't be less than 1 or higher than %d", sizeof ( DrugPackages ) ) ) ;
		}

		if ( Drugs_GetPackageMaxWeight ( container ) < amount ) {

			return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", sprintf("Your container can only hold %0.2fgr!", Drugs_GetPackageMaxWeight ( container ) ) ) ;
		}

		if ( ! Drugs_DoesPlayerHaveContainer ( playerid, container ) ) {

			return SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You don't have this container!" ) ;

		}
		Drugs_OnPlantCollect ( playerid, id, container, amount ) ;
	}

	else SendServerMessage ( playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "This drug is still in production." ) ;

	return true ;
}

// /dropdrug [slot] - drops a drug you carry on the ground.
CMD:dropdrug(playerid, params[]) {

    if (IsPlayerIncapacitated(playerid, false))
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You can't use this command right now!");

    new slot;

    if (sscanf(params, "i", slot))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/dropdrug [slot] (use /mydrugs to see your slots)");

    if (slot < 0 || slot >= MAX_PLAYER_DRUGS)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Invalid slot.");

    if (PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT] < 0.01)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "That slot is empty.");

    new drug_name[32], drug_type[32], package_name[32];

    Drugs_GetParamName(
        PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE],
        PlayerDrugs[playerid][slot][E_PLAYER_DRUG_PARAM],
        drug_name
    );

    Drugs_GetTypeName(PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE], drug_type);
    Drugs_GetPackageName(PlayerDrugs[playerid][slot][E_PLAYER_DRUG_CONTAINER], package_name);

    static DropDrugDlgStr[1024];

    format(DropDrugDlgStr, sizeof(DropDrugDlgStr), "{D82323}Warning! {DEDEDE}This is a destructive action!");
    strcat(DropDrugDlgStr, "\n\n{DEDEDE}You are about to drop and {D82323}DESTROY{DEDEDE} your drugs.");
    strcat(DropDrugDlgStr, "\n{DEDEDE}They will be lost forever. If you want to give them");
    strcat(DropDrugDlgStr, "\nto someone else, use /passdrug instead.");
    strcat(DropDrugDlgStr, sprintf("\n\n{FFFF00}Slot %d: {DEDEDE}%.02fgr of %s stored in a %s.", slot, PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT], drug_name, package_name));
    strcat(DropDrugDlgStr, "\n\n{DEDEDE}Are you sure you want to continue?");
    strcat(DropDrugDlgStr, "\n{EF7C7C}You will not be refunded if you change your mind.");

    inline ConfirmDropDrug(pid, dialogid, response, listitem, string:inputtext[])
    {
        #pragma unused pid, dialogid, listitem, inputtext

        if (!response)
            return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You have cancelled the drop, your drugs are still on you.");

        if (response) {

            new drop_name[32], drop_type[32], drop_package[32];

            Drugs_GetParamName(
                PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE],
                PlayerDrugs[playerid][slot][E_PLAYER_DRUG_PARAM],
                drop_name
            );

            Drugs_GetTypeName(PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE], drop_type);
            Drugs_GetPackageName(PlayerDrugs[playerid][slot][E_PLAYER_DRUG_CONTAINER], drop_package);

            new Float:amount = PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT];

            ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", sprintf("drops some %s from a %s.", drop_name, drop_package), .annonated=true);

            AddLogEntry(playerid, LOG_TYPE_SCRIPT, sprintf("Dropped slot %d: %.02fgr of %s (%s) stored in a %s.",
                slot, amount, drop_name, drop_type, drop_package
            ));

            PlayerDrugs[playerid][slot][E_PLAYER_DRUG_TYPE]        = E_DRUG_TYPE_NONE;
            PlayerDrugs[playerid][slot][E_PLAYER_DRUG_SQLID]        = -1;
            PlayerDrugs[playerid][slot][E_PLAYER_DRUG_PARAM]        = 0;
            PlayerDrugs[playerid][slot][E_PLAYER_DRUG_CONTAINER]    = 0;
            PlayerDrugs[playerid][slot][E_PLAYER_DRUG_AMOUNT]       = 0.0;

            PlayerDrugs_Save(playerid);
        }

        return true;
    }

    Dialog_ShowCallback(playerid, using inline ConfirmDropDrug, DIALOG_STYLE_MSGBOX, "{D82323}DROPDRUG WARNING{DEDEDE}", DropDrugDlgStr, "Delete it", "Cancel");

    return true;
}


// Repeating task: advances the growth of every plant and lab, and moves it through its stages.
task Drugs_OnGrowth[2500]() {

	new type, max_ticks, query [ 128 ] ;

	for ( new i, j = sizeof ( Drugs ); i < j ; i ++ ) {

		if ( Drugs [ i ] [ E_DRUG_TYPE ] != E_DRUG_TYPE_NONE ) {

			if ( Drugs [ i ] [ E_DRUG_STAGE ] == E_DRUG_STAGE_TICKS ) {

				Drugs [ i ] [ E_DRUG_TICKS ] ++ ;
				type = Drugs [ i ] [ E_DRUG_PARAM ] ;

				switch ( Drugs [ i ] [ E_DRUG_TYPE ] ) {
					case E_DRUG_TYPE_WEED: max_ticks = Weed [ type ] [ E_WEED_TICKS ] ;
					case E_DRUG_TYPE_COKE: max_ticks = Cocaine [ type ] [ E_COKE_TICKS ] ;
					case E_DRUG_TYPE_CRACK: max_ticks = Crack [ type ] [ E_CRACK_TICKS ]  ; 
					//case E_DRUG_TYPE_METH: max_ticks = -1 ; 
				}

				mysql_format(mysql, query, sizeof ( query ), "UPDATE drugs_player_stations SET drug_ticks = %d WHERE drug_sqlid = %d", 

					Drugs [ i ] [ E_DRUG_TICKS ], Drugs [ i ] [ E_DRUG_SQLID ]
				) ;

				mysql_tquery(mysql, query);

				if ( Drugs [ i ] [ E_DRUG_TICKS ] >= max_ticks ) {

					Drugs [ i ] [ E_DRUG_STAGE ] = E_DRUG_STAGE_FINISH ;
					Drugs_OnFinishTicks ( i ) ;

					break ;
				}

				Drugs_UpdateObject ( i  ) ;
				continue ;
			}
		}

		else continue ;
	}
}
