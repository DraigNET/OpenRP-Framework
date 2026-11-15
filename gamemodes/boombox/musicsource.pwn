// ============================================================================
// File: boombox/musicsource.pwn
// Permanent music sources placed by admins (/musicsource): a station that plays to everyone
// within a radius, stored in the `music_sources` table. Unlike a boombox it has no object and
// survives restarts.
// Commands: /musicsource
// ============================================================================

// Permanent music sources: admin-placed audio that never expires. Like a boombox it plays a radio
// station to everyone who comes into its radius (the sound fades out towards the edge), but there is
// no object, only a 3D text label, it isn't tied to a player so it stays when the admin logs out, and
// only admins (General+) can place, change or remove one. They are saved in the music_sources table.
//
//   /musicsource create [radius]    places one where you stand (radius 5-100, 25 by default)
//   /musicsource list
//   /musicsource station [id]       choose the station, same dialogs as /setstation
//   /musicsource radius [id] [m]
//   /musicsource loop [id] [seconds]  restart the stream every [seconds] so a track loops (0 = off)
//   /musicsource move [id]          moves it to where you stand
//   /musicsource delete [id]
//   /musicsource goto [id]
// Wherever [id] is left out, the nearest source within 15 metres is used.

#include <YSI_Coding\y_hooks>

#define MAX_MUSIC_SOURCES               (128)
#define INVALID_MUSIC_SOURCE            (-1)
#define MUSIC_SOURCE_DEFAULT_RADIUS     (25.0)
#define MUSIC_SOURCE_MIN_RADIUS         (5.0)
#define MUSIC_SOURCE_MAX_RADIUS         (100.0)
#define MUSIC_SOURCE_MAX_LOOP           (14400)     // seconds, 4 hours
#define MUSIC_SOURCE_MIN_LOOP           (5)

enum E_MUSIC_SOURCE_DATA {

	E_MUSIC_SQLID,
	E_MUSIC_STATION [ 128 ],

	Float: E_MUSIC_X,
	Float: E_MUSIC_Y,
	Float: E_MUSIC_Z,
	E_MUSIC_INT,
	E_MUSIC_VW,
	Float: E_MUSIC_RADIUS,
	E_MUSIC_LOOP, // seconds between restarts of the stream, 0 = never (a radio station just keeps going)

	DynamicText3D: E_MUSIC_LABEL,
	E_MUSIC_AREA
} ;

new MusicSource [ MAX_MUSIC_SOURCES ] [ E_MUSIC_SOURCE_DATA ] ;

// The music source each player is listening to through this system, or INVALID_MUSIC_SOURCE.
new MusicSource_Listening [ MAX_PLAYERS ] = { INVALID_MUSIC_SOURCE, ... } ;

// When (unix time) each player's stream from that source last started, to know when a looping one is due.
new MusicSource_StartedAt [ MAX_PLAYERS ] ;

// ---------------------------------------------------------------------------------------------
// Lookups
// ---------------------------------------------------------------------------------------------

// Returns the array index of the music source with a given SQL id.
MusicSource_GetBySqlId(sqlid) {

	if ( sqlid <= 0 ) {

		return INVALID_MUSIC_SOURCE ;
	}

	for ( new i; i < MAX_MUSIC_SOURCES; i ++ ) {

		if ( MusicSource [ i ] [ E_MUSIC_SQLID ] == sqlid ) {

			return i ;
		}
	}

	return INVALID_MUSIC_SOURCE ;
}

// Returns the music source that owns a given streamer area.
MusicSource_GetByArea(STREAMER_TAG_AREA: areaid) {

	for ( new i; i < MAX_MUSIC_SOURCES; i ++ ) {

		if ( MusicSource [ i ] [ E_MUSIC_SQLID ] > 0 && MusicSource [ i ] [ E_MUSIC_AREA ] == _: areaid ) {

			return i ;
		}
	}

	return INVALID_MUSIC_SOURCE ;
}

// Returns the nearest music source within range of the player.
MusicSource_GetNearest(playerid, Float: range = 15.0) {

	new Float: best = range, index = INVALID_MUSIC_SOURCE ;

	for ( new i; i < MAX_MUSIC_SOURCES; i ++ ) {

		if ( MusicSource [ i ] [ E_MUSIC_SQLID ] <= 0 ) {

			continue ;
		}

		if ( GetPlayerInterior ( playerid ) != MusicSource [ i ] [ E_MUSIC_INT ] || GetPlayerVirtualWorld ( playerid ) != MusicSource [ i ] [ E_MUSIC_VW ] ) {

			continue ;
		}

		new Float: dist = GetPlayerDistanceFromPoint ( playerid, MusicSource [ i ] [ E_MUSIC_X ], MusicSource [ i ] [ E_MUSIC_Y ], MusicSource [ i ] [ E_MUSIC_Z ] ) ;

		if ( dist < best ) {

			best = dist ;
			index = i ;
		}
	}

	return index ;
}

// The id the admin typed, or the nearest source if they left it out.
static MusicSource_Resolve(playerid, const arg[]) {

	if ( isnull ( arg ) ) {

		return MusicSource_GetNearest ( playerid ) ;
	}

	return MusicSource_GetBySqlId ( strval ( arg ) ) ;
}

// What the label shows: the channel name for an official channel, "Custom stream" for anything else.
static MusicSource_GetStationName(const url[], name[], len = sizeof ( name )) {

	if ( strlen ( url ) < 3 ) {

		return format ( name, len, "Off" ) ;
	}

	for ( new i, j = sizeof ( RadioChannels ); i < j; i ++ ) {

		if ( ! strcmp ( RadioChannels [ i ] [ radioch_url ], url ) ) {

			return format ( name, len, "%s", RadioChannels [ i ] [ radioch_name ] ) ;
		}
	}

	return format ( name, len, "Custom stream" ) ;
}

// ---------------------------------------------------------------------------------------------
// The label and the area
// ---------------------------------------------------------------------------------------------

// Removes the 3D label and area of a music source.
MusicSource_DestroyVisuals(index) {

	if ( IsValidDynamic3DTextLabel ( MusicSource [ index ] [ E_MUSIC_LABEL ] ) ) {

		DestroyDynamic3DTextLabel ( MusicSource [ index ] [ E_MUSIC_LABEL ] ) ;
	}

	if ( IsValidDynamicArea ( STREAMER_TAG_AREA: MusicSource [ index ] [ E_MUSIC_AREA ] ) ) {

		DestroyDynamicArea ( STREAMER_TAG_AREA: MusicSource [ index ] [ E_MUSIC_AREA ] ) ;
	}

	MusicSource [ index ] [ E_MUSIC_LABEL ] = DynamicText3D: INVALID_3DTEXT_ID ;
	MusicSource [ index ] [ E_MUSIC_AREA ] = -1 ;

	return true ;
}

// Creates the 3D label and trigger area of a music source.
MusicSource_CreateVisuals(index) {

	MusicSource_DestroyVisuals ( index ) ;

	new station_name [ 40 ], text [ 128 ] ;

	MusicSource_GetStationName ( MusicSource [ index ] [ E_MUSIC_STATION ], station_name, sizeof ( station_name ) ) ;
	format ( text, sizeof ( text ), "[%d] [Music Source]{DEDEDE}\nNow playing: %s", MusicSource [ index ] [ E_MUSIC_SQLID ], station_name ) ;

	MusicSource [ index ] [ E_MUSIC_LABEL ] = CreateDynamic3DTextLabel ( text, 0x866D40FF,
		MusicSource [ index ] [ E_MUSIC_X ], MusicSource [ index ] [ E_MUSIC_Y ], MusicSource [ index ] [ E_MUSIC_Z ],
		10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, false, MusicSource [ index ] [ E_MUSIC_VW ], MusicSource [ index ] [ E_MUSIC_INT ] ) ;

	MusicSource [ index ] [ E_MUSIC_AREA ] = _: CreateDynamicCircle ( MusicSource [ index ] [ E_MUSIC_X ], MusicSource [ index ] [ E_MUSIC_Y ],
		MusicSource [ index ] [ E_MUSIC_RADIUS ], MusicSource [ index ] [ E_MUSIC_VW ], MusicSource [ index ] [ E_MUSIC_INT ] ) ;

	return true ;
}

// Resets one music source slot to empty.
MusicSource_ClearEntity(index) {

	new blank [ E_MUSIC_SOURCE_DATA ] ;

	MusicSource [ index ] = blank ;
	MusicSource [ index ] [ E_MUSIC_LABEL ] = DynamicText3D: INVALID_3DTEXT_ID ;
	MusicSource [ index ] [ E_MUSIC_AREA ] = -1 ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// Playing it to the people in range
// ---------------------------------------------------------------------------------------------

// Starts playing a music source's station for one player, fading with distance.
static MusicSource_Play(playerid, index) {

	ORP_PlayAudioStreamForPlayer ( playerid, MusicSource [ index ] [ E_MUSIC_STATION ],
		MusicSource [ index ] [ E_MUSIC_X ], MusicSource [ index ] [ E_MUSIC_Y ], MusicSource [ index ] [ E_MUSIC_Z ],
		MusicSource [ index ] [ E_MUSIC_RADIUS ], true ) ;

	MusicSource_Listening [ playerid ] = index ;
	MusicSource_StartedAt [ playerid ] = gettime () ;

	return true ;
}

// Starts the music for a player standing inside a source's radius, unless they're in a vehicle (the
// vehicle radio wins) or already listening to something else (a boombox, the vehicle radio, a property).
MusicSource_Sync(playerid) {

	if ( ! IsPlayerSpawned ( playerid ) || ! IsPlayerLogged ( playerid ) || IsPlayerInAnyVehicle ( playerid ) ) {

		return false ;
	}

	if ( MusicSource_Listening [ playerid ] == INVALID_MUSIC_SOURCE && IsPlayerListeningToAudioStream ( playerid ) ) {

		return false ;
	}

	for ( new i; i < MAX_MUSIC_SOURCES; i ++ ) {

		if ( MusicSource [ i ] [ E_MUSIC_SQLID ] <= 0 || strlen ( MusicSource [ i ] [ E_MUSIC_STATION ] ) < 3 ) {

			continue ;
		}

		if ( ! IsPlayerInDynamicArea ( playerid, STREAMER_TAG_AREA: MusicSource [ i ] [ E_MUSIC_AREA ] ) ) {

			continue ;
		}

		// Already hearing this one.
		if ( MusicSource_Listening [ playerid ] == i && IsPlayerListeningToAudioStream ( playerid ) ) {

			return true ;
		}

		return MusicSource_Play ( playerid, i ) ;
	}

	return false ;
}

// A source's station, radius or position changed (or it was removed): everyone inside it hears the change.
static MusicSource_Refresh(index) {

	foreach ( new i : Player ) {

		if ( ! IsPlayerSpawned ( i ) || ! IsPlayerLogged ( i ) || IsPlayerInAnyVehicle ( i ) ) {

			continue ;
		}

		new bool: inside = ( MusicSource [ index ] [ E_MUSIC_SQLID ] > 0 && IsPlayerInDynamicArea ( i, STREAMER_TAG_AREA: MusicSource [ index ] [ E_MUSIC_AREA ] ) ) ;

		if ( MusicSource_Listening [ i ] == index && ! inside ) {

			// They were hearing it and are no longer in range, or it's gone.
			MusicSource_Listening [ i ] = INVALID_MUSIC_SOURCE ;
			ORP_StopAudioStreamForPlayer ( i ) ;
			MusicSource_Sync ( i ) ;
			continue ;
		}

		if ( ! inside ) {

			continue ;
		}

		if ( strlen ( MusicSource [ index ] [ E_MUSIC_STATION ] ) >= 3 ) {

			if ( MusicSource_Listening [ i ] == index || ! IsPlayerListeningToAudioStream ( i ) ) {

				MusicSource_Play ( i, index ) ;
			}
		}

		else if ( MusicSource_Listening [ i ] == index ) {

			MusicSource_Listening [ i ] = INVALID_MUSIC_SOURCE ;
			ORP_StopAudioStreamForPlayer ( i ) ;
		}
	}

	return true ;
}

// Timer: syncs a player's music sources shortly after they spawn or change area.
timer MusicSource_DelayedSync[500](playerid) {

	MusicSource_Sync ( playerid ) ;
}

// SA-MP can't tell when a stream has finished, so a source that should loop is simply restarted for each
// listener once its loop length has passed. Radio stations never end, so those keep a loop of 0.
ptask MusicSource_LoopTick[1000](playerid) {

	new index = MusicSource_Listening [ playerid ] ;

	if ( index == INVALID_MUSIC_SOURCE || MusicSource [ index ] [ E_MUSIC_SQLID ] <= 0 || MusicSource [ index ] [ E_MUSIC_LOOP ] <= 0 ) {

		return 1 ;
	}

	if ( ! IsPlayerSpawned ( playerid ) || IsPlayerInAnyVehicle ( playerid ) || strlen ( MusicSource [ index ] [ E_MUSIC_STATION ] ) < 3 ) {

		return 1 ;
	}

	if ( gettime () - MusicSource_StartedAt [ playerid ] >= MusicSource [ index ] [ E_MUSIC_LOOP ] ) {

		MusicSource_Play ( playerid, index ) ;
	}

	return 1 ;
}

hook OnPlayerConnect(playerid) {

	MusicSource_Listening [ playerid ] = INVALID_MUSIC_SOURCE ;
	return 1 ;
}

hook OnPlayerDisconnect(playerid, reason) {

	MusicSource_Listening [ playerid ] = INVALID_MUSIC_SOURCE ;
	return 1 ;
}

hook OnPlayerSpawn(playerid) {

	defer MusicSource_DelayedSync[1000](playerid) ;
	return 1 ;
}

hook OnPlayerStateChange(playerid, newstate, oldstate) {

	if ( newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER ) {

		// Getting in a vehicle stops the stream (see boombox/native.pwn), so forget this source.
		MusicSource_Listening [ playerid ] = INVALID_MUSIC_SOURCE ;
	}

	else if ( newstate == PLAYER_STATE_ONFOOT ) {

		// Wait until the boombox code has stopped and restarted its own streams.
		defer MusicSource_DelayedSync[500](playerid) ;
	}

	return 1 ;
}

hook OnPlayerEnterDynamicArea(playerid, STREAMER_TAG_AREA:areaid) {

	if ( MusicSource_GetByArea ( areaid ) != INVALID_MUSIC_SOURCE ) {

		defer MusicSource_DelayedSync[250](playerid) ;
	}

	return 1 ;
}

hook OnPlayerLeaveDynamicArea(playerid, STREAMER_TAG_AREA:areaid) {

	new index = MusicSource_GetByArea ( areaid ) ;

	if ( index != INVALID_MUSIC_SOURCE && MusicSource_Listening [ playerid ] == index ) {

		MusicSource_Listening [ playerid ] = INVALID_MUSIC_SOURCE ;

		if ( ! IsPlayerInAnyVehicle ( playerid ) ) {

			ORP_StopAudioStreamForPlayer ( playerid ) ;
		}
	}

	// They may have walked into another source's radius, or left a boombox that was covering this one.
	defer MusicSource_DelayedSync[500](playerid) ;

	return 1 ;
}

// ---------------------------------------------------------------------------------------------
// Saving
// ---------------------------------------------------------------------------------------------

// Saves a music source's station to the database.
static MusicSource_SaveStation(index) {

	new query [ 256 ] ;

	mysql_format ( mysql, query, sizeof ( query ), "UPDATE music_sources SET music_station = '%e' WHERE music_id = %d", MusicSource [ index ] [ E_MUSIC_STATION ], MusicSource [ index ] [ E_MUSIC_SQLID ] ) ;
	mysql_tquery ( mysql, query ) ;

	return true ;
}

// Changes a music source's station and saves it.
static MusicSource_SetStation(index, const url[]) {

	MusicSource [ index ] [ E_MUSIC_STATION ] [ 0 ] = EOS ;
	strcat ( MusicSource [ index ] [ E_MUSIC_STATION ], url, 128 ) ;

	MusicSource_SaveStation ( index ) ;
	MusicSource_CreateVisuals ( index ) ;
	MusicSource_Refresh ( index ) ;

	return true ;
}

// Loads all permanent music sources from the database at start-up.
MusicSource_LoadEntities() {

	for ( new i; i < MAX_MUSIC_SOURCES; i ++ ) {

		MusicSource_DestroyVisuals ( i ) ;
		MusicSource_ClearEntity ( i ) ;
	}

	print ( " * [MUSIC] Loading permanent music sources..." ) ;

	inline MusicSource_OnLoad() {

		new loaded ;

		for ( new i = 0, r = cache_num_rows(); i < r && i < MAX_MUSIC_SOURCES; i ++ ) {

			cache_get_value_name_int ( i, "music_id", MusicSource [ i ] [ E_MUSIC_SQLID ] ) ;
			cache_get_value_name ( i, "music_station", MusicSource [ i ] [ E_MUSIC_STATION ], 128 ) ;
			cache_get_value_name_float ( i, "music_x", MusicSource [ i ] [ E_MUSIC_X ] ) ;
			cache_get_value_name_float ( i, "music_y", MusicSource [ i ] [ E_MUSIC_Y ] ) ;
			cache_get_value_name_float ( i, "music_z", MusicSource [ i ] [ E_MUSIC_Z ] ) ;
			cache_get_value_name_int ( i, "music_int", MusicSource [ i ] [ E_MUSIC_INT ] ) ;
			cache_get_value_name_int ( i, "music_vw", MusicSource [ i ] [ E_MUSIC_VW ] ) ;
			cache_get_value_name_float ( i, "music_radius", MusicSource [ i ] [ E_MUSIC_RADIUS ] ) ;
			cache_get_value_name_int ( i, "music_loop_seconds", MusicSource [ i ] [ E_MUSIC_LOOP ] ) ;

			if ( MusicSource [ i ] [ E_MUSIC_RADIUS ] < MUSIC_SOURCE_MIN_RADIUS ) {

				MusicSource [ i ] [ E_MUSIC_RADIUS ] = MUSIC_SOURCE_DEFAULT_RADIUS ;
			}

			MusicSource_CreateVisuals ( i ) ;
			loaded ++ ;
		}

		printf ( " * [MUSIC] Loaded %d permanent music sources.", loaded ) ;
	}

	MySQL_TQueryInline ( mysql, using inline MusicSource_OnLoad, "SELECT * FROM music_sources ORDER BY music_id ASC", "" ) ;

	return true ;
}

// ---------------------------------------------------------------------------------------------
// /musicsource
// ---------------------------------------------------------------------------------------------

// Shows the dialog menu for choosing a music source's station.
static MusicSource_ShowStationMenu(playerid, index) {

	new sqlid = MusicSource [ index ] [ E_MUSIC_SQLID ] ;

	inline MusicSource_StationIntro(pid, dialogid, response, listitem, string: inputtext[]) {

		#pragma unused pid, dialogid, inputtext

		if ( ! response ) {

			return true ;
		}

		new idx = MusicSource_GetBySqlId ( sqlid ) ;

		if ( idx == INVALID_MUSIC_SOURCE || GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

			return true ;
		}

		switch ( listitem ) {

			case 0: { // Official channels

				new channels [ 2048 ] ;

				for ( new i, j = sizeof ( RadioChannels ); i < j; i ++ ) {

					format ( channels, sizeof ( channels ), "%s%s\n", channels, RadioChannels [ i ] [ radioch_name ] ) ;
				}

				inline MusicSource_StationOfficial(pid2, dialogid2, response2, listitem2, string: inputtext2[]) {

					#pragma unused pid2, dialogid2, inputtext2

					if ( ! response2 ) {

						return MusicSource_ShowStationMenu ( playerid, idx ) ;
					}

					new idx2 = MusicSource_GetBySqlId ( sqlid ) ;

					if ( idx2 == INVALID_MUSIC_SOURCE || GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL || listitem2 < 0 || listitem2 >= sizeof ( RadioChannels ) ) {

						return true ;
					}

					MusicSource_SetStation ( idx2, RadioChannels [ listitem2 ] [ radioch_url ] ) ;

					AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set the station of music source %d to \"%s\"", sqlid, RadioChannels [ listitem2 ] [ radioch_name ] ) ) ;

					return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Music source %d now plays \"%s\".", sqlid, RadioChannels [ listitem2 ] [ radioch_name ] ) ) ;
				}

				Dialog_ShowCallback ( playerid, using inline MusicSource_StationOfficial, DIALOG_STYLE_LIST, "Music Source: Official Channels", channels, "Select", "Back" ) ;
			}

			case 1: { // Custom URL

				inline MusicSource_StationCustom(pid2, dialogid2, response2, listitem2, string: inputtext2[]) {

					#pragma unused pid2, dialogid2, listitem2

					if ( ! response2 ) {

						return MusicSource_ShowStationMenu ( playerid, idx ) ;
					}

					new idx2 = MusicSource_GetBySqlId ( sqlid ) ;

					if ( idx2 == INVALID_MUSIC_SOURCE || GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

						return true ;
					}

					if ( strlen ( inputtext2 ) < 5 ) {

						return SendClientMessage ( playerid, COLOR_ERROR, "Enter a proper stream URL, at least 5 characters." ) ;
					}

					if ( ! CheckInputtextCrash ( playerid, inputtext2 ) ) {

						return true ;
					}

					MusicSource_SetStation ( idx2, inputtext2 ) ;

					AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set music source %d to a custom stream", sqlid ) ) ;

					return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Music source %d now plays your custom stream.", sqlid ) ) ;
				}

				Dialog_ShowCallback ( playerid, using inline MusicSource_StationCustom, DIALOG_STYLE_INPUT, "Music Source: Custom Stream",
					"{DEDEDE}Enter an audio stream URL below.\n\nValid formats are mp3 and ogg/vorbis.\nA link to a .pls (playlist) file will play that playlist.", "Select", "Back" ) ;
			}

			case 2: { // Off

				MusicSource_SetStation ( idx, "" ) ;

				AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Turned music source %d off", sqlid ) ) ;

				return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Music source %d is now off.", sqlid ) ) ;
			}
		}

		return true ;
	}

	Dialog_ShowCallback ( playerid, using inline MusicSource_StationIntro, DIALOG_STYLE_LIST, sprintf ( "Music Source %d", sqlid ), "Official Channels\nEnter Custom URL\nTurn Off", "Select", "Close" ) ;

	return true ;
}

// Prints the /musicsource sub-commands.
static MusicSource_Usage(playerid) {

	SendClientMessage ( playerid, COLOR_GRAD0, "/musicsource [create / list / station / radius / loop / move / delete / goto]" ) ;
	SendClientMessage ( playerid, COLOR_GRAD0, "create [radius] | station [id] | radius [id] [meters] | loop [id] [seconds] | move [id] | delete [id] | goto [id]" ) ;
	SendClientMessage ( playerid, COLOR_GRAD0, "loop: for a track (not a radio station) enter its length in seconds and it restarts by itself, 0 turns it off." ) ;
	SendClientMessage ( playerid, COLOR_INFO, "A source plays to everyone who comes within its radius, permanently. If you leave out the id, the nearest source within 15 metres is used." ) ;

	return true ;
}

// /musicsource [create/list/station/radius/loop/delete...] - (staff) manage permanent music
// sources placed in the world.
CMD:musicsource(playerid, params[]) {

	if ( GetPlayerAdminLevel ( playerid ) < ADMIN_LVL_GENERAL ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Access Denied", "A3A3A3", "You don't have access to this command." ) ;
	}

	new sub [ 16 ], rest [ 64 ] ;

	if ( sscanf ( params, "s[16]S()[64]", sub, rest ) ) {

		return MusicSource_Usage ( playerid ) ;
	}

	if ( ! strcmp ( sub, "list", true ) ) {

		new count, station_name [ 40 ] ;

		SendClientMessage ( playerid, COLOR_INFO, "[ID] Playing | radius | position" ) ;

		for ( new i; i < MAX_MUSIC_SOURCES; i ++ ) {

			if ( MusicSource [ i ] [ E_MUSIC_SQLID ] <= 0 ) {

				continue ;
			}

			MusicSource_GetStationName ( MusicSource [ i ] [ E_MUSIC_STATION ], station_name, sizeof ( station_name ) ) ;

			SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "[%d] %s | %.0fm | loop %s | %.1f, %.1f, %.1f (int %d, world %d)", MusicSource [ i ] [ E_MUSIC_SQLID ], station_name, MusicSource [ i ] [ E_MUSIC_RADIUS ],
				MusicSource [ i ] [ E_MUSIC_LOOP ] > 0 ? ( sprintf ( "%ds", MusicSource [ i ] [ E_MUSIC_LOOP ] ) ) : ( "off" ),
				MusicSource [ i ] [ E_MUSIC_X ], MusicSource [ i ] [ E_MUSIC_Y ], MusicSource [ i ] [ E_MUSIC_Z ], MusicSource [ i ] [ E_MUSIC_INT ], MusicSource [ i ] [ E_MUSIC_VW ] ) ) ;

			count ++ ;
		}

		if ( ! count ) {

			SendClientMessage ( playerid, COLOR_GRAD0, "There are no music sources. Use /musicsource create." ) ;
		}

		return true ;
	}

	if ( ! strcmp ( sub, "create", true ) ) {

		new Float: radius = MUSIC_SOURCE_DEFAULT_RADIUS ;

		if ( ! isnull ( rest ) && sscanf ( rest, "f", radius ) ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, "/musicsource create [radius, 5-100 metres]" ) ;
		}

		if ( radius < MUSIC_SOURCE_MIN_RADIUS || radius > MUSIC_SOURCE_MAX_RADIUS ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Music Source", "A3A3A3", sprintf ( "The radius must be between %.0f and %.0f metres.", MUSIC_SOURCE_MIN_RADIUS, MUSIC_SOURCE_MAX_RADIUS ) ) ;
		}

		new index = INVALID_MUSIC_SOURCE ;

		for ( new i; i < MAX_MUSIC_SOURCES; i ++ ) {

			if ( MusicSource [ i ] [ E_MUSIC_SQLID ] == 0 ) {

				index = i ;
				break ;
			}
		}

		if ( index == INVALID_MUSIC_SOURCE ) {

			return SendServerMessage ( playerid, COLOR_ERROR, "Music Source", "A3A3A3", sprintf ( "The limit of %d music sources has been reached.", MAX_MUSIC_SOURCES ) ) ;
		}

		new Float: x, Float: y, Float: z, int = GetPlayerInterior ( playerid ), vw = GetPlayerVirtualWorld ( playerid ), query [ 384 ] ;

		GetPlayerPos ( playerid, x, y, z ) ;

		// Reserve the slot until the insert comes back.
		MusicSource_ClearEntity ( index ) ;
		MusicSource [ index ] [ E_MUSIC_SQLID ] = -1 ;

		mysql_format ( mysql, query, sizeof ( query ),
			"INSERT INTO music_sources (music_station, music_x, music_y, music_z, music_int, music_vw, music_radius, music_created_by, music_created_at) VALUES ('', '%f', '%f', '%f', %d, %d, '%f', '%e', %d)",
			x, y, z, int, vw, radius, Account [ playerid ] [ E_PLAYER_ACCOUNT_NAME ], gettime () ) ;

		inline MusicSource_OnCreate() {

			new sqlid = cache_insert_id () ;

			if ( sqlid <= 0 ) {

				MusicSource [ index ] [ E_MUSIC_SQLID ] = 0 ;
				return SendServerMessage ( playerid, COLOR_ERROR, "Music Source", "A3A3A3", "The music source couldn't be saved. Is the music_sources table there?" ) ;
			}

			MusicSource [ index ] [ E_MUSIC_SQLID ] = sqlid ;
			MusicSource [ index ] [ E_MUSIC_X ] = x ;
			MusicSource [ index ] [ E_MUSIC_Y ] = y ;
			MusicSource [ index ] [ E_MUSIC_Z ] = z ;
			MusicSource [ index ] [ E_MUSIC_INT ] = int ;
			MusicSource [ index ] [ E_MUSIC_VW ] = vw ;
			MusicSource [ index ] [ E_MUSIC_RADIUS ] = radius ;

			MusicSource_CreateVisuals ( index ) ;

			AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Created music source %d at %.1f, %.1f, %.1f (radius %.0f)", sqlid, x, y, z, radius ) ) ;

			SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Created music source %d here (radius %.0fm). Choose what it plays with /musicsource station %d.", sqlid, radius, sqlid ) ) ;

			return true ;
		}

		MySQL_TQueryInline ( mysql, using inline MusicSource_OnCreate, query, "" ) ;

		return true ;
	}

	// Everything else works on one source: [id] [extra]
	new arg [ 16 ], extra [ 32 ] ;

	sscanf ( rest, "S()[16]S()[32]", arg, extra ) ;

	// "radius" and "loop" need a number after the id, so with only one value it's for the nearest source.
	if ( ( ! strcmp ( sub, "radius", true ) || ! strcmp ( sub, "loop", true ) ) && isnull ( extra ) ) {

		format ( extra, sizeof ( extra ), "%s", arg ) ;
		arg [ 0 ] = EOS ;
	}

	new index = MusicSource_Resolve ( playerid, arg ) ;

	if ( index == INVALID_MUSIC_SOURCE ) {

		return SendServerMessage ( playerid, COLOR_ERROR, "Music Source", "A3A3A3", isnull ( arg ) ? ( "There is no music source within 15 metres. Give an id, see /musicsource list." ) : ( "That isn't a valid music source id. See /musicsource list." ) ) ;
	}

	new sqlid = MusicSource [ index ] [ E_MUSIC_SQLID ], query [ 256 ] ;

	if ( ! strcmp ( sub, "station", true ) ) {

		return MusicSource_ShowStationMenu ( playerid, index ) ;
	}

	if ( ! strcmp ( sub, "radius", true ) ) {

		new Float: radius ;

		if ( isnull ( extra ) || sscanf ( extra, "f", radius ) || radius < MUSIC_SOURCE_MIN_RADIUS || radius > MUSIC_SOURCE_MAX_RADIUS ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, "/musicsource radius [id] [meters, 5-100]" ) ;
		}

		MusicSource [ index ] [ E_MUSIC_RADIUS ] = radius ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE music_sources SET music_radius = '%f' WHERE music_id = %d", radius, sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		// The area is rebuilt, so everyone is re-synced against the new size.
		foreach ( new i : Player ) {

			if ( MusicSource_Listening [ i ] == index ) {

				MusicSource_Listening [ i ] = INVALID_MUSIC_SOURCE ;
				ORP_StopAudioStreamForPlayer ( i ) ;
			}
		}

		MusicSource_CreateVisuals ( index ) ;

		foreach ( new i : Player ) {

			defer MusicSource_DelayedSync[500](i) ;
		}

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set the radius of music source %d to %.0f", sqlid, radius ) ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Music source %d now reaches %.0f metres.", sqlid, radius ) ) ;
	}

	if ( ! strcmp ( sub, "loop", true ) ) {

		new seconds ;

		if ( isnull ( extra ) || sscanf ( extra, "i", seconds ) || seconds < 0 || ( seconds > 0 && ( seconds < MUSIC_SOURCE_MIN_LOOP || seconds > MUSIC_SOURCE_MAX_LOOP ) ) ) {

			return SendClientMessage ( playerid, COLOR_GRAD0, sprintf ( "/musicsource loop [id] [track length in seconds, %d-%d, or 0 to turn it off]", MUSIC_SOURCE_MIN_LOOP, MUSIC_SOURCE_MAX_LOOP ) ) ;
		}

		MusicSource [ index ] [ E_MUSIC_LOOP ] = seconds ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE music_sources SET music_loop_seconds = %d WHERE music_id = %d", seconds, sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		// Everyone hearing it starts the track over so the new loop length lines up with what they're hearing.
		foreach ( new i : Player ) {

			if ( MusicSource_Listening [ i ] == index ) {

				MusicSource_StartedAt [ i ] = gettime () ;
			}
		}

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Set the loop of music source %d to %d seconds", sqlid, seconds ) ) ;

		if ( seconds == 0 ) {

			return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Music source %d no longer restarts its stream.", sqlid ) ) ;
		}

		return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Music source %d now restarts its stream every %d seconds for everyone listening.", sqlid, seconds ) ) ;
	}

	if ( ! strcmp ( sub, "move", true ) ) {

		new Float: x, Float: y, Float: z ;

		GetPlayerPos ( playerid, x, y, z ) ;

		MusicSource [ index ] [ E_MUSIC_X ] = x ;
		MusicSource [ index ] [ E_MUSIC_Y ] = y ;
		MusicSource [ index ] [ E_MUSIC_Z ] = z ;
		MusicSource [ index ] [ E_MUSIC_INT ] = GetPlayerInterior ( playerid ) ;
		MusicSource [ index ] [ E_MUSIC_VW ] = GetPlayerVirtualWorld ( playerid ) ;

		mysql_format ( mysql, query, sizeof ( query ), "UPDATE music_sources SET music_x = '%f', music_y = '%f', music_z = '%f', music_int = %d, music_vw = %d WHERE music_id = %d",
			x, y, z, MusicSource [ index ] [ E_MUSIC_INT ], MusicSource [ index ] [ E_MUSIC_VW ], sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		foreach ( new i : Player ) {

			if ( MusicSource_Listening [ i ] == index ) {

				MusicSource_Listening [ i ] = INVALID_MUSIC_SOURCE ;
				ORP_StopAudioStreamForPlayer ( i ) ;
			}
		}

		MusicSource_CreateVisuals ( index ) ;

		foreach ( new i : Player ) {

			defer MusicSource_DelayedSync[500](i) ;
		}

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Moved music source %d", sqlid ) ) ;

		return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Music source %d moved to where you are standing.", sqlid ) ) ;
	}

	if ( ! strcmp ( sub, "delete", true ) ) {

		mysql_format ( mysql, query, sizeof ( query ), "DELETE FROM music_sources WHERE music_id = %d", sqlid ) ;
		mysql_tquery ( mysql, query ) ;

		AddLogEntry ( playerid, LOG_TYPE_ADMIN, sprintf ( "Deleted music source %d", sqlid ) ) ;

		// Stop it for everyone who was hearing it, then drop it.
		MusicSource_DestroyVisuals ( index ) ;

		foreach ( new i : Player ) {

			if ( MusicSource_Listening [ i ] == index ) {

				MusicSource_Listening [ i ] = INVALID_MUSIC_SOURCE ;
				ORP_StopAudioStreamForPlayer ( i ) ;
			}
		}

		MusicSource_ClearEntity ( index ) ;

		foreach ( new i : Player ) {

			defer MusicSource_DelayedSync[500](i) ;
		}

		return SendServerMessage ( playerid, COLOR_BLUE, "Music Source", "A3A3A3", sprintf ( "Deleted music source %d.", sqlid ) ) ;
	}

	if ( ! strcmp ( sub, "goto", true ) ) {

		PauseAC ( playerid, 3 ) ;
		SetPlayerPos ( playerid, MusicSource [ index ] [ E_MUSIC_X ], MusicSource [ index ] [ E_MUSIC_Y ], MusicSource [ index ] [ E_MUSIC_Z ] ) ;
		SetPlayerInterior ( playerid, MusicSource [ index ] [ E_MUSIC_INT ] ) ;
		SetPlayerVirtualWorld ( playerid, MusicSource [ index ] [ E_MUSIC_VW ] ) ;

		return true ;
	}

	return MusicSource_Usage ( playerid ) ;
}
