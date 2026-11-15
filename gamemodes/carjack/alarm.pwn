// ============================================================================
// File: carjack/alarm.pwn
// Vehicle alarm state. StartVehicleAlarm() sets off the horn and lights when someone tries to
// break in; Get/SetAlarmStatus track whether it is currently going off.
// ============================================================================

// Sets off a vehicle alarm (horn and lights) and starts the timer that stops it.
StartVehicleAlarm(vehicleid) {

	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;

	if ( veh_enum_id == -1 ) {

		return true ;
	}

	if ( GetAlarmStatus(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ]) || GetObjectiveStatus(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ]) ) {

		return true ;
	}

	SetAlarmStatus ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], true ) ;
	SetObjectivetatus ( Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ], true ) ;
	Alarm_SendPoliceAlert(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ]);


	defer StopVehicleAlarm(vehicleid) ;

	return true ;
}

// Timer: switches a vehicle alarm off after three minutes.
timer StopVehicleAlarm[180000](vehicleid) {

	new veh_enum_id = Vehicle_GetEnumID(vehicleid) ;

	if ( veh_enum_id == -1 ) {

		return true ;
	}

	if ( IsValidVehicle(Vehicle [ veh_enum_id ] [ E_VEHICLE_ID ] ) ) {

		ClearAlarmData ( vehicleid ) ;
	}

	return true ;
}

ClearAlarmData ( vehicleid ) {
	SetAlarmStatus ( vehicleid, false ) ;
	SetObjectivetatus ( vehicleid, false ) ;
}

// Returns whether the vehicle's alarm is currently going off.
stock GetAlarmStatus(vehicleid) {
	static engine, lights, alarm, doors, bonnet, boot, objective;

	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);

	if (alarm != 1)
		return 0;

	return 1;
}
// Turns a vehicle's alarm on or off.
stock SetAlarmStatus(vehicleid, status) {
	static engine, lights, alarm, doors, bonnet, boot, objective;

	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	return SetVehicleParamsEx(vehicleid, engine, lights, status, doors, bonnet, boot, objective);
}

// Returns whether the vehicle's objective marker is on.
stock GetObjectiveStatus(vehicleid) {
	static engine, lights, alarm, doors, bonnet, boot, objective;

	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);

	if (objective != 1)
		return 0;

	return 1;
}
// Turns a vehicle's objective marker on or off.
stock SetObjectivetatus(vehicleid, status) {
	static engine, lights, alarm, doors, bonnet, boot, objective;

	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
	return SetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, status);
}
