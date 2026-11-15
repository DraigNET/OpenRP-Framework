// ============================================================================
// File: vehicle/data/attach.pwn
// Admin-placed vehicle attachments (/vattach): visual objects attached to a vehicle with a
// gizmo editor, saved with the vehicle in the database.
// Commands: /vattach
// ============================================================================

#include <YSI_Coding\y_hooks>

// Admin-placed vehicle attachments (vehicles.vehicle_attach_*1..5).
//
// Data lives in Vehicle[][E_VEHICLE_ATTACH_*] (loaded in Vehicle_LoadEntities). Objects are
// created per engine vehicle id whenever a vehicle gets its enum mapping (Temp_SetVehicleEnumId)
// and destroyed when that mapping is released (Temp_ReleaseVehicleEnumId), so every spawn path -
// load, /carcreate, /carspawn, faction respawns, modshop re-creates - gets them for free.
//
// Editing: /vattach opens a slot menu. "Edit" is a key editor, exact values are typed in a
// dialog. Nothing touches the database until the admin saves.

#define VEH_ATTACH_EMPTY	(65535)

#define VAE_AXIS_COUNT		(6)
#define VAE_TICK_MS			(100)

forward Float:Vehicle_AttachGetAxis(veh_enum_id, slot, axis);
forward VAE_Tick(playerid);

static const VAE_AxisName[VAE_AXIS_COUNT][] = { "X", "Y", "Z", "RX", "RY", "RZ" };

new VehAttachObject[MAX_VEHICLES][MAX_VEHICLE_ATTACH_SLOTS];

// Per-admin editor state
new
	VAE_Vehicle[MAX_PLAYERS],			// engine vehicle id, 0 = not using the system
	VAE_Slot[MAX_PLAYERS],
	VAE_Axis[MAX_PLAYERS],
	VAE_Timer[MAX_PLAYERS],
	VAE_LastKeys[MAX_PLAYERS],
	VAE_LastLR[MAX_PLAYERS],
	bool:VAE_Gizmo[MAX_PLAYERS],		// mouse (drag) editor running
	VAE_GizmoObject[MAX_PLAYERS],
	bool:VAE_KeyMode[MAX_PLAYERS],		// key editor running (player frozen)
	bool:VAE_InDialog[MAX_PLAYERS],		// key editor paused while a dialog is up
	bool:VAE_Dirty[MAX_PLAYERS],
	VAE_BackupModel[MAX_PLAYERS],
	Float:VAE_Backup[MAX_PLAYERS][VAE_AXIS_COUNT];

// ----------------------------------------------------------------------------
// Data helpers
// ----------------------------------------------------------------------------

// Returns true if an attachment slot on the vehicle is in use.
stock bool:Vehicle_AttachSlotUsed(veh_enum_id, slot)
{
	new model = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ];

	return (model != VEH_ATTACH_EMPTY && model != 0);
}

// Clears the data of one attachment slot.
stock Vehicle_AttachClearSlotData(veh_enum_id, slot)
{
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ] = VEH_ATTACH_EMPTY;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ slot ] = 0.0;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ slot ] = 0.0;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ slot ] = 0.0;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ slot ] = 0.0;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ slot ] = 0.0;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ slot ] = 0.0;
}

// Clears all attachment slots of a vehicle.
stock Vehicle_AttachResetData(veh_enum_id)
{
	for (new s = 0; s < MAX_VEHICLE_ATTACH_SLOTS; ++s)
	{
		Vehicle_AttachClearSlotData(veh_enum_id, s);
	}
}

// Reads one axis (x, y, z, rotation) of an attachment slot.
Float:Vehicle_AttachGetAxis(veh_enum_id, slot, axis)
{
	switch (axis)
	{
		case 0: return Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ slot ];
		case 1: return Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ slot ];
		case 2: return Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ slot ];
		case 3: return Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ slot ];
		case 4: return Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ slot ];
	}

	return Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ slot ];
}

// Writes one axis of an attachment slot.
stock Vehicle_AttachSetAxis(veh_enum_id, slot, axis, Float:value)
{
	if (axis < 3)
	{
		if (value > 50.0) value = 50.0;
		else if (value < -50.0) value = -50.0;
	}
	else
	{
		while (value > 360.0) value -= 360.0;
		while (value < -360.0) value += 360.0;
	}

	switch (axis)
	{
		case 0: Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ slot ] = value;
		case 1: Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ slot ] = value;
		case 2: Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ slot ] = value;
		case 3: Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ slot ] = value;
		case 4: Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ slot ] = value;
		default: Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ slot ] = value;
	}
}

// Saves an attachment slot to the database.
stock Vehicle_AttachSaveSlot(veh_enum_id, slot)
{
	new query[512], n = slot + 1;

	mysql_format(mysql, query, sizeof(query),
		"UPDATE vehicles SET vehicle_attach_model%d = %d, vehicle_attach_x%d = '%f', vehicle_attach_y%d = '%f', vehicle_attach_z%d = '%f', vehicle_attach_rx%d = '%f', vehicle_attach_ry%d = '%f', vehicle_attach_rz%d = '%f' WHERE vehicle_sqlid = %d",
		n, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ],
		n, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ slot ],
		n, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ slot ],
		n, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ slot ],
		n, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ slot ],
		n, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ slot ],
		n, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ slot ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]
	);

	mysql_tquery(mysql, query);
}

// ----------------------------------------------------------------------------
// Runtime objects
// ----------------------------------------------------------------------------

// Returns true if the slot's object exists.
stock bool:VehicleAttachObjectValid(vehicleid, slot)
{
	return (VehAttachObject[vehicleid][slot] != 0 && IsValidDynamicObject(VehAttachObject[vehicleid][slot]));
}

// Destroys all attached objects on a vehicle.
stock Vehicle_AttachDestroyObjects(vehicleid)
{
	if (vehicleid < 1 || vehicleid >= MAX_VEHICLES) return;

	for (new s = 0; s < MAX_VEHICLE_ATTACH_SLOTS; ++s)
	{
		if (VehicleAttachObjectValid(vehicleid, s))
		{
			DestroyDynamicObject(VehAttachObject[vehicleid][s]);
		}

		VehAttachObject[vehicleid][s] = 0;
	}
}

// recreate = false just re-attaches an existing object with the new offsets (live editing).
stock Vehicle_AttachApplySlot(vehicleid, veh_enum_id, slot, bool:recreate = true)
{
	if (vehicleid < 1 || vehicleid >= MAX_VEHICLES) return;

	if (VehicleAttachObjectValid(vehicleid, slot) && !recreate && Vehicle_AttachSlotUsed(veh_enum_id, slot))
	{
		AttachDynamicObjectToVehicle(VehAttachObject[vehicleid][slot], vehicleid,
			Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ slot ],
			Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ slot ]);
		return;
	}

	if (VehicleAttachObjectValid(vehicleid, slot))
	{
		DestroyDynamicObject(VehAttachObject[vehicleid][slot]);
	}

	VehAttachObject[vehicleid][slot] = 0;

	if (!Vehicle_AttachSlotUsed(veh_enum_id, slot)) return;

	new objectid = CreateDynamicObject(Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

	if (objectid == INVALID_STREAMER_ID) return;

	VehAttachObject[vehicleid][slot] = objectid;

	AttachDynamicObjectToVehicle(objectid, vehicleid,
		Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ slot ],
		Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ slot ]);
}

// Creates the attached objects of a vehicle from its saved data.
stock Vehicle_AttachApply(vehicleid, veh_enum_id)
{
	if (veh_enum_id < 0 || veh_enum_id >= MAX_VEHICLES) return;

	for (new s = 0; s < MAX_VEHICLE_ATTACH_SLOTS; ++s)
	{
		Vehicle_AttachApplySlot(vehicleid, veh_enum_id, s);
	}
}

// ----------------------------------------------------------------------------
// Admin editor
// ----------------------------------------------------------------------------

// The vehicle being worked on must still be the same enum entry, or the admin loses the session.
stock bool:VAE_Validate(playerid, &veh_enum_id)
{
	new vehicleid = VAE_Vehicle[playerid];

	if (vehicleid < 1 || !IsValidVehicle(vehicleid)) return false;

	veh_enum_id = Vehicle_GetEnumID(vehicleid);

	return (veh_enum_id != -1);
}

// Leaves the key-based attachment editor.
stock VAE_StopKeyMode(playerid)
{
	if (VAE_KeyMode[playerid])
	{
		KillTimer(VAE_Timer[playerid]);
		TogglePlayerControllable(playerid, true);
	}

	VAE_KeyMode[playerid] = false;
	VAE_InDialog[playerid] = false;
	VAE_Dirty[playerid] = false;
}

// Restores the attachment from backup after cancelling an edit.
stock VAE_RestoreBackup(playerid)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id)) return;

	new slot = VAE_Slot[playerid];

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ] = VAE_BackupModel[playerid];

	for (new a = 0; a < VAE_AXIS_COUNT; ++a)
	{
		Vehicle_AttachSetAxis(veh_enum_id, slot, a, VAE_Backup[playerid][a]);
	}

	Vehicle_AttachApplySlot(VAE_Vehicle[playerid], veh_enum_id, slot);
}

// Cancels an attachment edit and discards the changes.
stock VAE_Cancel(playerid, const reason[] = "Edit cancelled - changes discarded.")
{
	if (!VAE_KeyMode[playerid]) return;

	VAE_StopKeyMode(playerid);
	VAE_RestoreBackup(playerid);
	SendClientMessage(playerid, COLOR_YELLOW, reason);
}

// Saves the attachment being edited.
stock VAE_Save(playerid)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id))
	{
		VAE_StopKeyMode(playerid);
		return;
	}

	new slot = VAE_Slot[playerid];

	VAE_StopKeyMode(playerid);
	Vehicle_AttachSaveSlot(veh_enum_id, slot);

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Saved vehicle attachment slot %d (model %d) on vehicle SQL ID %d.",
		slot + 1, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]));

	SendClientMessage(playerid, COLOR_INFO, sprintf("Attachment slot %d saved. Use /vattach to edit further.", slot + 1));
}

// Shows the editing help text.
stock VAE_ShowText(playerid, veh_enum_id)
{
	new text[96], axis = VAE_Axis[playerid], slot = VAE_Slot[playerid];

	format(text, sizeof(text), "~w~Slot %d  ~y~%s ~g~%.3f~n~~w~X %.2f Y %.2f Z %.2f~n~RX %.1f RY %.1f RZ %.1f",
		slot + 1, VAE_AxisName[axis], Vehicle_AttachGetAxis(veh_enum_id, slot, axis),
		Vehicle_AttachGetAxis(veh_enum_id, slot, 0), Vehicle_AttachGetAxis(veh_enum_id, slot, 1), Vehicle_AttachGetAxis(veh_enum_id, slot, 2),
		Vehicle_AttachGetAxis(veh_enum_id, slot, 3), Vehicle_AttachGetAxis(veh_enum_id, slot, 4), Vehicle_AttachGetAxis(veh_enum_id, slot, 5));

	GameTextForPlayer(playerid, text, 600, 3);
}

// Starts the key-based attachment editor for a slot.
stock VAE_StartKeyMode(playerid, slot)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id) || !Vehicle_AttachSlotUsed(veh_enum_id, slot)) return;

	VAE_StopKeyMode(playerid);

	VAE_Slot[playerid] = slot;
	VAE_Axis[playerid] = 0;
	VAE_BackupModel[playerid] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ];

	for (new a = 0; a < VAE_AXIS_COUNT; ++a)
	{
		VAE_Backup[playerid][a] = Vehicle_AttachGetAxis(veh_enum_id, slot, a);
	}

	if (GetPlayerVehicleID(playerid) != 0)
	{
		PauseAC(playerid, 3);
		JT_RemovePlayerFromVehicle(playerid);
	}

	TogglePlayerControllable(playerid, false);

	VAE_KeyMode[playerid] = true;
	VAE_InDialog[playerid] = false;
	VAE_LastKeys[playerid] = 0xFFFF; // ignore keys already held when the editor opens
	VAE_LastLR[playerid] = 0;
	VAE_Timer[playerid] = SetTimerEx("VAE_Tick", VAE_TICK_MS, true, "i", playerid);

	SendClientMessage(playerid, COLOR_INFO, "Attachment editor: {FFFFFF}W/S change the value, A/D switch axis (X Y Z RX RY RZ).");
	SendClientMessage(playerid, COLOR_INFO, "Hold {FFFFFF}SPRINT{A3A3A3} for big steps, {FFFFFF}WALK (alt){A3A3A3} for fine steps. {FFFFFF}C{A3A3A3} types an exact value.");
	SendClientMessage(playerid, COLOR_INFO, "{FFFFFF}Y{A3A3A3} saves, {FFFFFF}N{A3A3A3} cancels. You're frozen while editing.");
}

// Timer: reads the keys and moves the attachment while editing.
public VAE_Tick(playerid)
{
	if (!VAE_KeyMode[playerid]) return;

	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id))
	{
		VAE_StopKeyMode(playerid);
		SendClientMessage(playerid, COLOR_ERROR, "The vehicle you were editing no longer exists - edit aborted.");
		return;
	}

	if (VAE_InDialog[playerid]) return;

	new keys, ud, lr;
	GetPlayerKeys(playerid, keys, ud, lr);

	new pressed = keys & ~VAE_LastKeys[playerid];
	VAE_LastKeys[playerid] = keys;

	new lr_edge = (lr != 0 && lr != VAE_LastLR[playerid]) ? lr : 0;
	VAE_LastLR[playerid] = lr;

	if (pressed & KEY_YES)
	{
		VAE_Save(playerid);
		return;
	}
	if (pressed & KEY_NO)
	{
		VAE_Cancel(playerid);
		return;
	}
	if (pressed & KEY_CROUCH)
	{
		VAE_ShowValueInput(playerid, VAE_Axis[playerid], true);
		return;
	}

	new bool:changed = false, slot = VAE_Slot[playerid], axis = VAE_Axis[playerid];

	if (lr_edge == KEY_RIGHT)
	{
		VAE_Axis[playerid] = (axis + 1) % VAE_AXIS_COUNT;
		changed = true;
	}
	else if (lr_edge == KEY_LEFT)
	{
		VAE_Axis[playerid] = (axis + VAE_AXIS_COUNT - 1) % VAE_AXIS_COUNT;
		changed = true;
	}

	if (ud != 0)
	{
		new Float:step = (axis < 3) ? 0.02 : 0.5;

		if (keys & KEY_SPRINT) step *= 5.0;
		else if (keys & KEY_WALK) step *= 0.25;

		if (ud == KEY_DOWN) step = -step;

		Vehicle_AttachSetAxis(veh_enum_id, slot, axis, Vehicle_AttachGetAxis(veh_enum_id, slot, axis) + step);
		Vehicle_AttachApplySlot(VAE_Vehicle[playerid], veh_enum_id, slot, false);

		VAE_Dirty[playerid] = true;
		changed = true;
	}

	if (changed) VAE_ShowText(playerid, veh_enum_id);
}

// ----------------------------------------------------------------------------
// Mouse (drag gizmo) editor
//
// The slot's object is detached and placed at the world transform it currently has, then handed
// to EditDynamicObject. On save the world position is converted back into an offset from the
// vehicle. That conversion assumes the vehicle is level (only yaw is accounted for), so edit with
// the vehicle parked on flat ground. Attach rotation is applied as Rz*Rx*Ry, so the vehicle yaw
// is simply added to / removed from RZ.
// ----------------------------------------------------------------------------

// Destroys the editing gizmo.
stock VAE_GizmoDestroy(playerid)
{
	if (VAE_GizmoObject[playerid] != 0 && IsValidDynamicObject(VAE_GizmoObject[playerid]))
	{
		DestroyDynamicObject(VAE_GizmoObject[playerid]);
	}

	VAE_GizmoObject[playerid] = 0;
	VAE_Gizmo[playerid] = false;
}

// Starts the mouse gizmo editor for an attachment.
stock VAE_StartGizmo(playerid, slot)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id) || !Vehicle_AttachSlotUsed(veh_enum_id, slot)) return;

	new vehicleid = VAE_Vehicle[playerid], Float:vx, Float:vy, Float:vz, Float:ang;

	GetVehiclePos(vehicleid, vx, vy, vz);
	GetVehicleZAngle(vehicleid, ang);

	new Float:s = floatsin(ang, degrees), Float:c = floatcos(ang, degrees);
	new Float:ox = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ slot ];
	new Float:oy = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ slot ];
	new Float:oz = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ slot ];

	VAE_Slot[playerid] = slot;
	VAE_BackupModel[playerid] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ];

	for (new a = 0; a < VAE_AXIS_COUNT; ++a)
	{
		VAE_Backup[playerid][a] = Vehicle_AttachGetAxis(veh_enum_id, slot, a);
	}

	// Free the slot's attached object and put a loose copy in its place for the gizmo.
	if (VehicleAttachObjectValid(vehicleid, slot)) DestroyDynamicObject(VehAttachObject[vehicleid][slot]);
	VehAttachObject[vehicleid][slot] = 0;

	VAE_GizmoDestroy(playerid);

	VAE_GizmoObject[playerid] = CreateDynamicObject(VAE_BackupModel[playerid],
		vx + ox * c - oy * s, vy + ox * s + oy * c, vz + oz,
		VAE_Backup[playerid][3], VAE_Backup[playerid][4], VAE_Backup[playerid][5] + ang);

	if (VAE_GizmoObject[playerid] == INVALID_STREAMER_ID)
	{
		VAE_GizmoObject[playerid] = 0;
		Vehicle_AttachApplySlot(vehicleid, veh_enum_id, slot);
		SendClientMessage(playerid, COLOR_ERROR, "Couldn't create the edit object.");
		return;
	}

	if (GetPlayerVehicleID(playerid) != 0)
	{
		PauseAC(playerid, 3);
		JT_RemovePlayerFromVehicle(playerid);
	}

	VAE_Gizmo[playerid] = true;
	EditDynamicObject(playerid, VAE_GizmoObject[playerid]);

	SendClientMessage(playerid, COLOR_INFO, "Drag the arrows to move and the rings to rotate. Click the {FFFFFF}save icon{A3A3A3} to keep it or press {FFFFFF}ESC{A3A3A3} to cancel.");
	SendClientMessage(playerid, COLOR_INFO, "The vehicle must be on flat ground and stationary for the position to convert correctly.");
}

// Finishes the gizmo edit and saves or discards it.
stock VAE_GizmoFinish(playerid, bool:save, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	new veh_enum_id, slot = VAE_Slot[playerid];
	new bool:valid = VAE_Validate(playerid, veh_enum_id);

	VAE_GizmoDestroy(playerid);

	if (!valid) return;

	if (save)
	{
		new Float:vx, Float:vy, Float:vz, Float:ang;

		GetVehiclePos(VAE_Vehicle[playerid], vx, vy, vz);
		GetVehicleZAngle(VAE_Vehicle[playerid], ang);

		new Float:s = floatsin(ang, degrees), Float:c = floatcos(ang, degrees);
		new Float:dx = x - vx, Float:dy = y - vy;

		Vehicle_AttachSetAxis(veh_enum_id, slot, 0, dx * c + dy * s);
		Vehicle_AttachSetAxis(veh_enum_id, slot, 1, -dx * s + dy * c);
		Vehicle_AttachSetAxis(veh_enum_id, slot, 2, z - vz);
		Vehicle_AttachSetAxis(veh_enum_id, slot, 3, rx);
		Vehicle_AttachSetAxis(veh_enum_id, slot, 4, ry);
		Vehicle_AttachSetAxis(veh_enum_id, slot, 5, rz - ang);

		Vehicle_AttachSaveSlot(veh_enum_id, slot);

		AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Dragged vehicle attachment slot %d (model %d) on vehicle SQL ID %d.",
			slot + 1, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ], Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]));

		SendClientMessage(playerid, COLOR_INFO, sprintf("Attachment slot %d saved. Use /vattach to edit further.", slot + 1));
	}
	else
	{
		SendClientMessage(playerid, COLOR_YELLOW, "Edit cancelled - changes discarded.");
	}

	Vehicle_AttachApplySlot(VAE_Vehicle[playerid], veh_enum_id, slot);
}

// Streamer callback: the player finished dragging the attachment gizmo.
public OnPlayerEditDynamicObject(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
	if (!VAE_Gizmo[playerid] || objectid != STREAMER_TAG_OBJECT:VAE_GizmoObject[playerid])
	{
		#if defined vatt_OnPlayerEditDynObj
			return vatt_OnPlayerEditDynObj(playerid, objectid, response, x, y, z, rx, ry, rz);
		#else
			return 1;
		#endif
	}

	switch (response)
	{
		case EDIT_RESPONSE_FINAL: VAE_GizmoFinish(playerid, true, x, y, z, rx, ry, rz);
		case EDIT_RESPONSE_CANCEL: VAE_GizmoFinish(playerid, false, x, y, z, rx, ry, rz);
	}

	return -2; // handled - don't pass to other editors
}

#if defined _ALS_OnPlayerEditDynamicObject
	#undef OnPlayerEditDynamicObject
#else
	#define _ALS_OnPlayerEditDynamicObject
#endif

#define OnPlayerEditDynamicObject vatt_OnPlayerEditDynObj
#if defined vatt_OnPlayerEditDynObj
	forward vatt_OnPlayerEditDynObj(playerid, STREAMER_TAG_OBJECT:objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz);
#endif

// Type an exact value for one axis. from_keymode = opened with C inside the key editor.
stock VAE_ShowValueInput(playerid, axis, bool:from_keymode)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id)) return;

	new slot = VAE_Slot[playerid];

	inline DlgValue(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, listitem

		VAE_InDialog[playerid] = false;

		new fixed_enum;

		if (!VAE_Validate(playerid, fixed_enum)) return;

		if (response)
		{
			new Float:value;

			if (sscanf(inputtext, "f", value))
			{
				SendClientMessage(playerid, COLOR_ERROR, "That isn't a number.");
			}
			else
			{
				Vehicle_AttachSetAxis(fixed_enum, slot, axis, value);
				Vehicle_AttachApplySlot(VAE_Vehicle[playerid], fixed_enum, slot, false);
				VAE_Dirty[playerid] = true;

				if (!from_keymode) Vehicle_AttachSaveSlot(fixed_enum, slot);
			}
		}

		if (!from_keymode) Vehicle_AttachShowValues(playerid);
	}

	if (from_keymode) VAE_InDialog[playerid] = true;

	Dialog_ShowCallback(playerid, using inline DlgValue, DIALOG_STYLE_INPUT, sprintf("Slot %d - %s", slot + 1, VAE_AxisName[axis]),
		sprintf("Current value: %.3f\n\nEnter the new %s value:", Vehicle_AttachGetAxis(veh_enum_id, slot, axis), VAE_AxisName[axis]), "Set", "Back");
}

// Every slot, empty ones included.
stock Vehicle_AttachShowMenu(playerid)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id)) return;

	new list[768];

	list = "Slot\tModel\tPosition\n";

	for (new s = 0; s < MAX_VEHICLE_ATTACH_SLOTS; ++s)
	{
		if (Vehicle_AttachSlotUsed(veh_enum_id, s))
		{
			format(list, sizeof(list), "%s%d\t%d\t%.2f, %.2f, %.2f\n", list, s + 1, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ s ],
				Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ s ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ s ], Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ s ]);
		}
		else
		{
			format(list, sizeof(list), "%s%d\t{A3A3A3}(empty)\t\n", list, s + 1);
		}
	}

	inline DlgMenu(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, inputtext

		new fixed_enum;

		if (!response || !VAE_Validate(playerid, fixed_enum)) return;

		VAE_Slot[playerid] = listitem;

		if (Vehicle_AttachSlotUsed(fixed_enum, listitem)) Vehicle_AttachShowSlotMenu(playerid);
		else Vehicle_AttachPromptModel(playerid, true);
	}

	Dialog_ShowCallback(playerid, using inline DlgMenu, DIALOG_STYLE_TABLIST_HEADERS,
		sprintf("Vehicle attachments - %s (SQL %d)", ReturnVehicleName(VAE_Vehicle[playerid]), Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]),
		list, "Select", "Close");
}

// is_new = the slot is empty and this creates the attachment.
stock Vehicle_AttachPromptModel(playerid, bool:is_new)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id)) return;

	new slot = VAE_Slot[playerid];

	inline DlgModel(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, listitem

		new fixed_enum;

		if (!VAE_Validate(playerid, fixed_enum)) return;

		if (!response)
		{
			if (!is_new) Vehicle_AttachShowSlotMenu(playerid);
			return;
		}

		new model;

		if (sscanf(inputtext, "i", model) || model == 0 || model == VEH_ATTACH_EMPTY)
		{
			SendClientMessage(playerid, COLOR_ERROR, "Enter a valid object model ID (custom models are negative).");
			Vehicle_AttachPromptModel(playerid, is_new);
			return;
		}

		if (is_new)
		{
			Vehicle_AttachClearSlotData(fixed_enum, slot);
			Vehicle [ fixed_enum ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ] = model;
			Vehicle_AttachApplySlot(VAE_Vehicle[playerid], fixed_enum, slot);
			Vehicle_AttachSaveSlot(fixed_enum, slot);

			if (!VehicleAttachObjectValid(VAE_Vehicle[playerid], slot))
			{
				SendClientMessage(playerid, COLOR_ERROR, "The object couldn't be created - check the model ID.");
			}

			VAE_StartGizmo(playerid, slot);
		}
		else
		{
			Vehicle [ fixed_enum ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ] = model;
			Vehicle_AttachApplySlot(VAE_Vehicle[playerid], fixed_enum, slot);
			Vehicle_AttachSaveSlot(fixed_enum, slot);
			Vehicle_AttachShowSlotMenu(playerid);
		}
	}

	new back_label[8];
	format(back_label, sizeof(back_label), is_new ? "Cancel" : "Back");

	Dialog_ShowCallback(playerid, using inline DlgModel, DIALOG_STYLE_INPUT, sprintf("Slot %d - model", slot + 1),
		"Enter the object model ID to attach (e.g. 1337, or a negative custom model ID):", "Continue", back_label);
}

// Typed values for every field of the slot.
stock Vehicle_AttachShowValues(playerid)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id)) return;

	new slot = VAE_Slot[playerid], list[256];

	format(list, sizeof(list), "Field\tValue\nModel\t%d\n", Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ]);

	for (new a = 0; a < VAE_AXIS_COUNT; ++a)
	{
		format(list, sizeof(list), "%s%s\t%.3f\n", list, VAE_AxisName[a], Vehicle_AttachGetAxis(veh_enum_id, slot, a));
	}

	inline DlgValues(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, inputtext

		new fixed_enum;

		if (!VAE_Validate(playerid, fixed_enum)) return;

		if (!response)
		{
			Vehicle_AttachShowSlotMenu(playerid);
			return;
		}

		if (listitem == 0)
		{
			Vehicle_AttachPromptModel(playerid, false);
			return;
		}

		VAE_ShowValueInput(playerid, listitem - 1, false);
	}

	Dialog_ShowCallback(playerid, using inline DlgValues, DIALOG_STYLE_TABLIST_HEADERS, sprintf("Slot %d - exact values", slot + 1),
		list, "Change", "Back");
}

// Copies an attachment to another slot (optionally mirrored to the other side).
stock Vehicle_AttachClone(playerid, bool:mirror)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id)) return;

	new src = VAE_Slot[playerid], dest = -1;

	for (new s = 0; s < MAX_VEHICLE_ATTACH_SLOTS; ++s)
	{
		if (!Vehicle_AttachSlotUsed(veh_enum_id, s))
		{
			dest = s;
			break;
		}
	}

	if (dest == -1)
	{
		SendClientMessage(playerid, COLOR_ERROR, "All attachment slots are in use - delete one first.");
		Vehicle_AttachShowSlotMenu(playerid);
		return;
	}

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ dest ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ src ];

	new Float:sign = mirror ? -1.0 : 1.0;

	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ dest ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_X ] [ src ] * sign;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ dest ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Y ] [ src ];
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ dest ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_Z ] [ src ];
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ dest ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RX ] [ src ];
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ dest ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RY ] [ src ] * sign;
	Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ dest ] = Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_RZ ] [ src ] * sign;

	Vehicle_AttachApplySlot(VAE_Vehicle[playerid], veh_enum_id, dest);
	Vehicle_AttachSaveSlot(veh_enum_id, dest);

	AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Cloned vehicle attachment slot %d to slot %d on vehicle SQL ID %d.",
		src + 1, dest + 1, Vehicle [ veh_enum_id ] [ E_VEHICLE_SQLID ]));

	SendClientMessage(playerid, COLOR_INFO, sprintf("Slot %d cloned to slot %d%s - now editing the clone.", src + 1, dest + 1, mirror ? " (mirrored)" : ""));

	VAE_StartGizmo(playerid, dest);
}

// Shows the attachment slot menu.
stock Vehicle_AttachShowSlotMenu(playerid)
{
	new veh_enum_id;

	if (!VAE_Validate(playerid, veh_enum_id)) return;

	new slot = VAE_Slot[playerid];

	inline DlgSlot(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, inputtext

		new fixed_enum;

		if (!VAE_Validate(playerid, fixed_enum)) return;

		if (!response)
		{
			Vehicle_AttachShowMenu(playerid);
			return;
		}

		switch (listitem)
		{
			case 0: VAE_StartGizmo(playerid, slot);
			case 1: VAE_StartKeyMode(playerid, slot);
			case 2: Vehicle_AttachShowValues(playerid);
			case 3: Vehicle_AttachPromptModel(playerid, false);
			case 4: Vehicle_AttachShowCloneMenu(playerid);
			case 5: Vehicle_AttachShowDeleteConfirm(playerid);
		}
	}

	Dialog_ShowCallback(playerid, using inline DlgSlot, DIALOG_STYLE_LIST,
		sprintf("Slot %d - model %d", slot + 1, Vehicle [ veh_enum_id ] [ E_VEHICLE_ATTACH_MODEL ] [ slot ]),
		"Edit with mouse (drag)\nEdit with keys\nType exact values\nChange model\nClone\nDelete", "Select", "Back");
}

// Shows the clone menu.
stock Vehicle_AttachShowCloneMenu(playerid)
{
	inline DlgClone(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, inputtext

		if (!response)
		{
			Vehicle_AttachShowSlotMenu(playerid);
			return;
		}

		Vehicle_AttachClone(playerid, listitem == 1);
	}

	Dialog_ShowCallback(playerid, using inline DlgClone, DIALOG_STYLE_LIST, "Clone attachment",
		"Same position (copy as-is)\nMirrored (flip left/right)", "Clone", "Back");
}

// Asks the player to confirm deleting an attachment.
stock Vehicle_AttachShowDeleteConfirm(playerid)
{
	new slot = VAE_Slot[playerid];

	inline DlgDelete(pid, dialogid, response, listitem, string:inputtext[])
	{
		#pragma unused pid, dialogid, listitem, inputtext

		new fixed_enum;

		if (!VAE_Validate(playerid, fixed_enum)) return;

		if (!response)
		{
			Vehicle_AttachShowSlotMenu(playerid);
			return;
		}

		Vehicle_AttachClearSlotData(fixed_enum, slot);
		Vehicle_AttachApplySlot(VAE_Vehicle[playerid], fixed_enum, slot);
		Vehicle_AttachSaveSlot(fixed_enum, slot);

		AddLogEntry(playerid, LOG_TYPE_ADMIN, sprintf("Deleted vehicle attachment slot %d on vehicle SQL ID %d.",
			slot + 1, Vehicle [ fixed_enum ] [ E_VEHICLE_SQLID ]));

		SendClientMessage(playerid, COLOR_INFO, sprintf("Attachment slot %d deleted.", slot + 1));
		Vehicle_AttachShowMenu(playerid);
	}

	Dialog_ShowCallback(playerid, using inline DlgDelete, DIALOG_STYLE_MSGBOX, sprintf("Delete slot %d", slot + 1),
		"Permanently delete this attachment from the vehicle?", "Delete", "Back");
}

// /vattach - edits the attachments on your vehicle.
CMD:vattach(playerid, params[])
{
	if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_LEAD)
	{
		return SendServerMessage(playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command.");
	}

	new vehicleid = GetPlayerVehicleID(playerid);

	if (vehicleid == 0) vehicleid = Vehicle_GetClosestEntity(playerid, 8.0);

	if (vehicleid == INVALID_VEHICLE_ID || Vehicle_GetEnumID(vehicleid) == -1)
	{
		return SendClientMessage(playerid, COLOR_ERROR, "Sit in a vehicle or stand next to one.");
	}

	if (VAE_KeyMode[playerid] || VAE_Gizmo[playerid])
	{
		return SendClientMessage(playerid, COLOR_ERROR, "Finish your current attachment edit first (Y to save, N to cancel).");
	}

	VAE_Vehicle[playerid] = vehicleid;
	Vehicle_AttachShowMenu(playerid);

	return true;
}

hook OnPlayerDisconnect(playerid, reason)
{
	if (VAE_KeyMode[playerid])
	{
		VAE_StopKeyMode(playerid);
		VAE_RestoreBackup(playerid);
	}

	if (VAE_Gizmo[playerid])
	{
		CancelEdit(playerid);
		VAE_GizmoDestroy(playerid);

		new veh_enum_id;

		if (VAE_Validate(playerid, veh_enum_id)) Vehicle_AttachApplySlot(VAE_Vehicle[playerid], veh_enum_id, VAE_Slot[playerid]);
	}

	VAE_Vehicle[playerid] = 0;

	return 1;
}
