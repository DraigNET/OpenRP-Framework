// ============================================================================
// File: police/systems/drugs.pwn
// /destroyplant: officers can destroy a drug plant they find.
// Commands: /destroyplant
// ============================================================================

// /destroyplant - law enforcement destroys a drug plant next to them.
CMD:destroyplant(playerid, params[]) {

	if (!IsPlayerInLEAFaction(playerid, true))
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "You must be a law enforcement officer on duty to use this command.");

	new enum_id = Drugs_GetClosestEntity(playerid, 3.0);

	if (enum_id == INVALID_DRUG_ID)
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "You are not near any drug plant.");

	if (Drugs[enum_id][E_DRUG_STAGE] == E_DRUG_STAGE_NONE || Drugs[enum_id][E_DRUG_TYPE] == E_DRUG_TYPE_NONE)
		return SendServerMessage(playerid, COLOR_DRUGS, "Drugs", "A3A3A3", "This plant has no active growth.");

	new drug_name[32], query[128];
	Drugs_GetTypeName(Drugs[enum_id][E_DRUG_TYPE], drug_name);

	mysql_format(mysql, query, sizeof(query), "DELETE FROM `drugs_player_stations` WHERE drug_sqlid = %d", Drugs[enum_id][E_DRUG_SQLID]);
	mysql_tquery(mysql, query);

	AddLogEntry(playerid, LOG_TYPE_DRUGS, sprintf("Destroyed drug plant (station %d, type: %s) via /destroyplant.", Drugs[enum_id][E_DRUG_SQLID], drug_name));

	Drugs[enum_id][E_DRUG_SQLID]                   = INVALID_DRUG_ID;
	Drugs[enum_id][E_DRUG_TYPE]                     = E_DRUG_TYPE_NONE;
	Drugs[enum_id][E_DRUG_PARAM]                    = 0;
	Drugs[enum_id][E_DRUG_STAGE]                    = E_DRUG_STAGE_NONE;
	Drugs[enum_id][E_DRUG_TICKS]                    = -1;
	Drugs[enum_id][E_DRUG_POS_X]                    = 0.0;
	Drugs[enum_id][E_DRUG_POS_Y]                    = 0.0;
	Drugs[enum_id][E_DRUG_POS_Z]                    = 0.0;
	Drugs[enum_id][E_DRUG_WORLDID]                  = 0;
	Drugs[enum_id][E_DRUG_INTERIOR]                 = 0;
	Drugs[enum_id][E_DRUG_GROWTH_PARAM_INT]         = 0;
	Drugs[enum_id][E_DRUG_GROWTH_PARAM_FLOAT_I]     = 0.0;
	Drugs[enum_id][E_DRUG_GROWTH_PARAM_FLOAT_II]    = 0.0;
	Drugs[enum_id][E_DRUG_GROWTH_PARAM_FLOAT_III]   = 0.0;

	if (IsValidDynamicObject(Drugs[enum_id][E_DRUG_OBJECT])) {
		ORP_DestroyObject(Drugs[enum_id][E_DRUG_OBJECT], "Police/DestroyPlant (Object)", true);
		Drugs[enum_id][E_DRUG_OBJECT] = INVALID_STREAMER_ID;
	}

	if (IsValidDynamicObject(Drugs[enum_id][E_DRUG_OBJECT_EXTRA])) {
		ORP_DestroyObject(Drugs[enum_id][E_DRUG_OBJECT_EXTRA], "Police/DestroyPlant (Extra)", true);
		Drugs[enum_id][E_DRUG_OBJECT_EXTRA] = INVALID_STREAMER_ID;
	}

	if (IsValidDynamic3DTextLabel(Drugs[enum_id][E_DRUG_LABEL])) {
		DestroyDynamic3DTextLabel(Drugs[enum_id][E_DRUG_LABEL]);
		Drugs[enum_id][E_DRUG_LABEL] = DynamicText3D:INVALID_STREAMER_ID;
	}

	ApplyAnim(playerid, "BOMBER", "BOM_Plant", 4.0, 0, 0, 0, 0, 0, 1);
	ProxDetectorEx(playerid, 15.0, COLOR_ACTION, "*", sprintf("destroys a %s plant.", drug_name), .annonated=true);
	SendServerMessage(playerid, COLOR_POLICE, "Drugs", "A3A3A3", sprintf("You have destroyed a %s plant.", drug_name));

	return true;
}
