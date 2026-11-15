// ============================================================================
// File: player/help.pwn
// The /help system: category menus and the staff command lists (/help, /househelp, /bizhelp,
// /staffhelp...). Edit it when you add commands.
// Commands: /dockhelp /dockinfo /fnrhelp /fearhelp /respecthelp /burglaryhelp /burghelp /help
// /oldahelp /staffhelp /bizhelp /househelp /prophelp /propertyhelp /vhelp /vehiclehelp /carhelp
// /ghelp /weaponhelp /gunhelp /truckerhelp /jobs /jobhelp /fhelp /factionhelp /drughelp
// /voicehelp /phonehelp /furniturehelp /furnihelp
// ============================================================================


#define DIALOG_FNR_HELP (6942)
#define DIALOG_BURGLARY_HELP (6943)

// Prints the vehicle command list.
ShowVehicleCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Vehicle Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]: {B2FFCD}/mycars, /carfind, /engine, /carlock, /carlights, /carwindow");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]: {B2FFCD}/cartrunk, /carhood, /carcheck, /setstation, /seatbelt, /searchplate");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]: {B2FFCD}/carspawn, /cardespawn, /cartransfer, /carsell, /carattach, /detach (Trailers)");
	SendClientMessage(playerid, 0xF87070FF, "[STORAGE]: {FDBCBC}/cartrunkstoregun (/ctsgun), /cartrunktakegun (/cttgun)");
	SendClientMessage(playerid, 0xF87070FF, "[STORAGE]: {FDBCBC}/cartrunkstoredrug (/ctsdrug), /cartrunktakedrug (/cttdrug)");
	SendClientMessage(playerid, 0xF87070FF, "[STORAGE]: {FDBCBC}/cartrunkstoreburglary (/ctsburg), /cartrunktakeburglary (/cttburg)");
	SendClientMessage(playerid, 0xF87070FF, "[STORAGE]: {FDBCBC}/cartrunkcheck (/ctcheck, /cartrunkshow), /carscrap, /cartow, /carcolor");
	SendClientMessage(playerid, 0xFFCC68FF, "[MISC]: {FFE1A8}/removemods, /setaw, /vehiclename, /carblink, /cardoor [open/close]");

	return true ;
}


// Prints the property command list.
ShowPropertyCommands(playerid) {
		
	SendClientMessage(playerid, 0x297183FF, "[ ___________ Property Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]: {B2FFCD}/myproperties, /propertybuy, /propertysell, /propertylock, /propertyfind");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]: {B2FFCD}/propertytransfer, /propertyscrap, /nosound, /furnihelp, /propertycollect");
	SendClientMessage(playerid, 0xFFCC68FF, "[RENTING]: {FFE1A8}/(un)rentroom, /propertyrent, /propertyinvite, /propertyevict");
	SendClientMessage(playerid, 0xF87070FF, "[STORAGE]: {FDBCBC}/propstorage, /propstoregun, /proptakegun, /propstoredrug, /proptakedrug");
	SendClientMessage(playerid, 0x77BBFAFF, "[COMMUNICATION]: {BBDEFF}/doorknock, /doorbell, /doorshout, /doorme, /doordo");
	SendClientMessage(playerid, 0x77BBFAFF, "[MISC]: {DEDEDE}/propertyad, /propertyname, /propertynamecolor, /propertywardrobe");
	SendClientMessage(playerid, 0x77BBFAFF, "[AUDIO/VISUAL]: {DEDEDE}/propertytime, /propertyweather, /propertyaudio");
	return true;
}

// Prints the gun command list.
ShowGunCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Gun Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]: {B2FFCD}/passgun, /passammo, /seta(rmed)w(eapon)");
	ZMsg_SendClientMessage(playerid, 0x297183FF, "If you want to store / retrieve a gun, see /help property or /help vehicle.");

	return true;
}

// Prints the fishing command list.
ShowFishCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Fish Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]: {B2FFCD}/fish, /sellfish, /fishes, /putback, /putallback");

	return true ;
}


// Prints the job command list.
ShowJobCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Job Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "[Dockworker]:{B2FFCD} /cargojob, /cargostop, /cargocollect, /cargostore") ;
	SendClientMessage(playerid, 0xF87070FF, "[TRUCKER]:{FDBCBC} /truckerjob, /loadtruck, /canceldelivery") ;
	SendClientMessage(playerid, 0xFFCC68FF, "[GARBAGEMAN]:{FFE1A8} Go to the trash depot (/gps), enter a truck and type /garbagejob!") ;
	SendClientMessage(playerid, 0xFFCC68FF, "[PIZZABOY]:{FFE1A8} Enter a Pizzaboy and type /pizza to start a delivery route (/endpizza to stop)!") ;
	SendClientMessage(playerid, 0xFFCC68FF, "[TRANSIT FIRM]:{FFFF00} /fare, /startmeter, /stopmeter (Transit firm duty, Taxi or Cabbie)") ;

	return true ;
}

// Prints the drug command list.
ShowDrugCommands(playerid){

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Drug Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "[STORAGE]: {B2FFCD}/mydrugs, /drugsupplies, /drugcontainers (/drugpackages)" ) ;
	SendClientMessage(playerid, 0xF87070FF, "[PRODUCTION]: {FDBCBC}/drugsnear, /buysupplies, /drugsetup, /drugproduce (/drugwater, /drugcook), /drugcollect" ) ;
	SendClientMessage(playerid, 0xFFCC68FF, "[USAGE]: {FFE1A8}/druguse, /drugpass, /blunt, /stopdrugeffect [will not refund]" ) ;
	SendClientMessage(playerid, 0xFFCC68FF, "[USAGE]: {FFE1A8}/drugsplit, /drugmerge, /dropdrug" ) ;

	return true;
}

// Prints the voice line command list.
ShowVoiceCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Voiceline Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "{B2FFCD}/voicelines - Shows all possible voicelines in a list");
	SendClientMessage(playerid, 0xF87070FF, "{FDBCBC}/myvoices - A list of your saved voicelines");
	SendClientMessage(playerid, 0xFFCC68FF, "{FFE1A8}/vl - Play a voiceline from your saved voicelines");

	return true ;
}

// Prints the phone command list.
ShowPhoneCommands(playerid) {
	SendClientMessage(playerid, 0x297183FF, "[ ___________ Phone Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "[GENERAL]:{B2FFCD} /ph(one), /pc, /ph(one)anim");
	SendClientMessage(playerid, 0xF87070FF, "[TEXTING]:{FDBCBC} /inbox, /sms");
	SendClientMessage(playerid, 0xFFCC68FF, "[CALLING]:{FFE1A8} /call, /h(angup), /pickup");

	return true;
}

// Prints the furniture command list.
ShowFurniCommands(playerid) {


	SendClientMessage(playerid, 0x5FB9D1FF, "[ ___________ Furniture Commands  ___________ ]");
	SendClientMessage(playerid, 0x58DD85FF, "{B2FFCD}/furnimode - use this at your property exit point");
	SendClientMessage(playerid, 0xF87070FF, "{FDBCBC}/furni - to buy new furniture, for a price");
	SendClientMessage(playerid, 0xFFCC68FF, "{FFE1A8}/furnilist - shows a list of all furniture spawned in the property");
	SendClientMessage(playerid, 0xFFCC68FF, "{FFE1A8}/furniedit - lets you select furniture to edit");
	SendClientMessage(playerid, 0x77BBFAFF, "{BBDEFF}/furniwipe - removes and refunds all furni");
	SendClientMessage(playerid, 0x58DD85FF, "{B2FFCD}/intfurni - lets you change interior to blank interior");
	SendClientMessage(playerid, 0x58DD85FF, "{B2FFCD}/furniperm - gives another player furniture permissions");

	return true ;
}


// Prints the spray tag command list.
ShowSpraytagCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Spraytag Commands  ___________ ]");
#if defined FEATURE_GANGTAGS
	SendClientMessage(playerid, COLOR_GRAD0, "{B2FFCD}/s(pray)t(ag)choose - pick a static and/or dynamic tag");
#else
	SendClientMessage(playerid, COLOR_GRAD0, "{B2FFCD}/s(pray)t(ag)choose - write your own custom text tag");
#endif
	SendClientMessage(playerid, COLOR_GRAD1, "{FDBCBC}/s(pray)t(ag)info - shows information of the spraytag");
	SendClientMessage(playerid, COLOR_GRAD0, "{FFE1A8}/s(pray)t(ag)wipe - lets you wipe the spraytag (LEO only)");

	return true ;
}

// Prints the gate command list.
ShowGateCommands(playerid){


	SendClientMessage(playerid, 0x297183FF, "[ ___________ Gate Commands  ___________ ]");
	SendClientMessage(playerid, COLOR_GRAD0, "{B2FFCD}/gate - opens / closes a gate.");
	/*if ( Account [ playerid ] [ E_PLAYER_ACCOUNT_STAFFLEVEL ] > ADMIN_LVL_NONE ) {

		SendClientMessage(playerid, COLOR_YELLOW, "When using admin commands on gates, use the NORMAL ID. Not the SQL/Database ID!");
		SendClientMessage(playerid, COLOR_BLUE, "[ADMIN]{A3A3A3}/gatecreate, /gateradius, /gateopen, /gatemove, /gatetexture");
		SendClientMessage(playerid, COLOR_BLUE, "[ADMIN]{DEDEDE}/gateworld, /gateint, /gatetype, /gatedelete, /gatespeed");
	}*/
	
	return true ;
}

// Prints the animation command list.
ShowAnimCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ________________________ Available Animations ________________________ ]") ;

	SendClientMessage(playerid, 0xF1D55EFF, "» Actions {FFFFFF}| /time - /jog - /handsup - /crossarms - /spray - /fucku - /wank - /throw - /lean - /gsign - /salute") ;
	SendClientMessage(playerid, 0xF1D55EFF, "» Actions {FFFFFF}| /slapass - /wave - /wash - /ganghands - /guardstance - /patdown - /cmon - /jump - /bomb") ;
	SendClientMessage(playerid, 0xF1D55EFF, "» Actions {FFFFFF}| /goggles - /slide - /balcony - /undercar - /flagdrop - /liftup - /casino - /swipe - /press ") ;
	SendClientMessage(playerid, 0xF1D55EFF, "» Actions {FFFFFF}| /cover - /look - /squat - /plunger - /carry - /hitchhike - /deal - /gkick - /walk - /switchseat") ;
	SendClientMessage(playerid, 0xF1D55EFF, "» Actions {FFFFFF}| /camcrouch - /carryidle - /taichi - /skate - /liftdown - /jogging") ;
	SendClientMessage(playerid, 0x729767FF, "» Express {FFFFFF}| /kiss - /eat - /smoke - /drink - /laugh - /cry - /tired - /facepalm - /angry - /dancing - /drunk") ;	
	SendClientMessage(playerid, 0xEF6060FF, "» Injury {FFFFFF}| /injured - /fall - /crack - /ko - /gethit - /fight - /cpr - /getup - /hurt") ;
	SendClientMessage(playerid, 0xA0765AFF, "» Weapons {FFFFFF}| /aim - /bat - /batidle - /knifehold - /pointgun - /pistolwhip - /riflehold - /knife - /point") ;
	SendClientMessage(playerid, 0xA0765AFF, "» Weapons {FFFFFF}| /reloadanim - /bikepunch - /gunhold") ;
	SendClientMessage(playerid, 0xACA179FF, "» Comfort {FFFFFF}| /sit - /lay - /sleep - /foodsit - /office - /blowjob") ;
	SendClientMessage(playerid, 0x81AE99FF, "» Ambient {FFFFFF}| /dance - /gfunk - /playidle - /copambient - /clothes - /recruit - /bop - /handstand - /dj") ;
	SendClientMessage(playerid, 0x81AE99FF, "» Ambient {FFFFFF}| /bar - /barber - /workout - /chat - /cheer - /strip - /smokeidle - /stop") ;
	SendClientMessage(playerid, 0xF2A55DFF, "» Vehicle {FFFFFF}| /carlook - /caranim - /carphone - /carfuss - /cartalk - /driverko - /lowrideranim") ;
	SendClientMessage(playerid, 0x985F83FF, "» Particle {FFFFFF}| /puke - /exhale - /shakebottle");

	SendClientMessage(playerid, 0xffffffFF, "To stop an animation use /sa or /stopanim.");

	return 1;
}

// Prints miscellaneous commands.
ShowMiscCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Miscellaneous Commands  ___________ ]");
	SendClientMessage(playerid, COLOR_GRAD0, "/settings, /pay, /paya(nim), /id, /boombox, /factions, /showinjuries, /showmasked");
	SendClientMessage(playerid, COLOR_GRAD1, "/(un)rentvehicle, /taketest, /setchat, /clearcp (/nocp), /nosound, /license(s)");
	SendClientMessage(playerid, COLOR_GRAD0, "/fillcar, /carcolorlist, /hudscalefix, /payfine");
	SendClientMessage(playerid, COLOR_GRAD1, "/gascan, /cmc, /mask, /removemask, /call, /sms, /pickup, /h(angup)");
	SendClientMessage(playerid, COLOR_GRAD0, "/helpup, /surgery, /address (/whereami, /street), /adminrecord, /playerskin");
	SendClientMessage(playerid, COLOR_GRAD1, "/rules, /blindfold, /accept, /charity, /servertime, /advert, /coin, /dice, /greet");
	SendClientMessage(playerid, COLOR_GRAD0, "/namechange, /toys, /reloadtoys, /buytoys, /lockpick");
	SendClientMessage(playerid, COLOR_GRAD1, "/dropgun, /credits, /atc, /toys, /mytoys, /mycrimes, /fightstyle");
	SendClientMessage(playerid, COLOR_GRAD0, "/chopshop, /prisoners, /savings, /mytickets, /togdc, /gymstats");
	SendClientMessage(playerid, COLOR_GRAD1, "/spawn, /myspawns, /dc, /hold");
	
	return true ;
}

// Prints the main /help screen.
ShowHelpCommands(playerid) {

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Common Server Commands  ___________ ]");

	SendClientMessage(playerid, 0xDEDEDEFF, "[COMMANDS]: {DEDEDE}/help {b8b8b8}[ chat, vehicle, property, guns, job, faction, drug, voice, phone,");
#if defined FEATURE_FNR
	SendClientMessage(playerid, 0xb8b8b8FF, "furniture, basketball, gate, anims, misc, dock, fnr, burglary ]");
#else
	SendClientMessage(playerid, 0xb8b8b8FF, "furniture, basketball, gate, anims, misc, dock, burglary ]");
#endif
	ZMsg_SendClientMessage(playerid, 0x297183FF, "Useful commands:{DEDEDE} /mycars, /myproperties, /myguns, /mydrugs, /myslots, /myitems, /myprofile, /syncnames, /synccarsigns");
	if(IsPlayerHelper(playerid)) {
		SendClientMessage(playerid, 0xF1D55EFF, "[STAFF]: {DEDEDE}Use /staffhelp to see all staff commands.");
	}

	return true;
}

// Prints the chat command list.
ShowChatCommands(playerid) {
	
	SendClientMessage(playerid, 0x297183FF, "[ ___________ Chat Commands  ___________ ]");


	SendClientMessage(playerid, 0x58DD85FF, "[OOC]:{B2FFCD} /b, /bl(ow), /c(ar)b, /toggleooc, /o(oc), /pm, /blockpm, /unblockpm, /togglepms, /listblockedpms");
	SendClientMessage(playerid, 0x58DC99FF, "[LOCAL]:{B2FFCD} /s(hout), /l(ow), /t, /setchat, /w(hisper), /c(ar)w(hisper)");
	SendClientMessage(playerid, 0x58DD85FF, "[ACTIONS]:{B2FFCD} /me, /mel(ow), /do, /ado, /dol(ow), /my, /attempt, /ame");

	return true;
}

// Prints the helper command list.
ShowHelperCommands(playerid) {

	if(!Account[playerid][E_PLAYER_ACCOUNT_SUPPORTER] && !Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
		return true;
	}

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Helper Commands  ___________ ]");

	if(Account[playerid][E_PLAYER_ACCOUNT_SUPPORTER] == 1) {
		SendClientMessage(playerid, 0x58DD85FF, "[CHAT]: {B2FFCD}/h(elper)c(hat)");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/a(ccept)h(elp), /answer, /questions");
		SendClientMessage(playerid, 0x58DD85FF, "[MISC]: {B2FFCD}/cleartrucker, /checkcars");
	}

	if(Account[playerid][E_PLAYER_ACCOUNT_SUPPORTER] == 2) {
		SendClientMessage(playerid, 0x58DD85FF, "[CHAT]: {B2FFCD}/h(elper)c(hat)");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/a(ccept)h(elp), /answer, /questions, /helperduty");
		SendClientMessage(playerid, 0x58DD85FF, "[MISC]: {B2FFCD}/cleartrucker, /checkcars, /resetattributes, /respawnplayer, /processnc");
	}

	if(Account[playerid][E_PLAYER_ACCOUNT_SUPPORTER] > 2 || Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL] ) {
		SendClientMessage(playerid, 0x58DD85FF, "[CHAT]: {B2FFCD}/h(elper)c(hat)");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/a(ccept)h(elp), /answer, /questions, /helperduty, /kick");
		SendClientMessage(playerid, 0x58DD85FF, "[MISC]: {B2FFCD}/cleartrucker, /checkcars, /resetattributes, /respawnplayer, /processnc");
	}

	return true;
}


// Prints general administrator commands.
ShowAdminGeneralCommands(playerid) {

	if(!Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
		return true;
	}

	SendClientMessage(playerid, 0x297183FF, "[ ___________ General Administrator Commands  ___________ ]");
	
	if ( GetPlayerAdminLevel ( playerid ) == 2 ) {

		SendClientMessage(playerid, 0xF87070FF, "[ADMIN]: {FDBCBC}/ajail, /unajail, /offlineajail, /gotoajail, /kick, /slap, /(un)freeze, /(un)ban");
		SendClientMessage(playerid, 0x58DC99FF, "[DUTY]: {B2FFCD}/aduty, /reports, /a(ccept)r(eport), /d(eny)r(eport), /punishlist, /(get)dist(ance)");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/spec(tate), /getcoordinates, /whonear, /clearinjuries");
		SendClientMessage(playerid, 0xD95023FF, "[CHAT]: {FA6D3E}/a(chat), /acinvite, /acuninvite, /toggleooc, /adminrumour");
		SendClientMessage(playerid, 0xFFCC68FF, "[TELEPORT]: {DEDEDE}/fw, /up, /dn, /goto, /gethere, /staffroom");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/getcharid, /getc, /getma, /adminrecord, /maskid, /getnumber, /processjfl");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/disarm, /confiscate, /frisk, /resetemail, /processn(ame)c(hange), /namechanges");
		SendClientMessage(playerid, 0x985F83FF, "[MISC]: {BF7AA6}/setint, /setvw, /removemask, /omaskid");
	}


	if ( GetPlayerAdminLevel ( playerid ) == 3 || GetPlayerAdminLevel ( playerid ) == 4 ) {

		SendClientMessage(playerid, 0xF87070FF, "[ADMIN]: {FDBCBC}/ajail, /unajail, /offlineajail, /kick, /slap, /(un)freeze, /(un)ban");
		SendClientMessage(playerid, 0xF87070FF, "[ADMIN]: {FDBCBC}/offlineban, /(un)banip, /settime, /setweather, /(get)dist(ance), /getstate");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/aduty, /reports, /a(ccept)r(eport), /d(eny)r(eport), /punishlist");
		SendClientMessage(playerid, 0x58DC99FF, "[DUTY]: {B2FFCD}/spec(tate), /getcoordinates, /whonear, /clearinjuries, /jetpack");
		SendClientMessage(playerid, 0xD95023FF, "[CHAT]: {FA6D3E}/a(chat), /acinvite, /acuninvite, /toggleooc, /aooc, /adminrumour");
		SendClientMessage(playerid, 0xFFCC68FF, "[TELEPORT]: {FFE1A8}/fw, /up, /dn, /goto, /gethere, /mark[1-3], /gotomark[1-3], /gotoxyz, /gotomarker");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/getcharid, /getc, /getma, /adminrecord, /maskid, /getnumber");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/disarm, /confiscate, /frisk, /resetemail, /processn(ame)c(hange), /namechanges");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/setskin, /geoip, /checkstats, /checkproperties, /checkguns, /makeooc, /admin911");
		SendClientMessage(playerid, 0x985F83FF, "[MISC]: {BF7AA6}/ecc, /entercar, /setint, /setvw, /removemask, /omaskid, /adminad, /adminbreaking");

	}

	if ( GetPlayerAdminLevel ( playerid ) == 5 ) {

		SendClientMessage(playerid, 0xF87070FF, "[ADMIN]: {FDBCBC}/ajail, /unajail, /offlineajail, /kick, /slap, /(un)freeze, /(un)ban");
		SendClientMessage(playerid, 0xF87070FF, "[ADMIN]: {FDBCBC}/offlineban, /(un)banip, /settime, /setweather, /setgunrights ((gun ban))");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/aduty, /reports, /a(ccept)r(eport), /d(eny)r(eport), /punishlist");
		SendClientMessage(playerid, 0x58DC99FF, "[DUTY]: {B2FFCD}/spec(tate), /getcoordinates, /whonear, /clearinjuries, /jetpack, /faction(un)ban, /ofactionban");
		SendClientMessage(playerid, 0xD95023FF, "[CHAT]: {FA6D3E}/a(chat), /acinvite, /acuninvite, /toggleooc, /aooc, /adminrumour, /togd(onator)c(hat)");
		SendClientMessage(playerid, 0xFFCC68FF, "[TELEPORT]: {FFE1A8}/fw, /up, /dn, /goto, /gethere, /mark[1-3], /gotomark[1-3], /gotoxyz, /tp");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/getcharid, /getc, /getma, /adminrecord, /maskid, /getnumber");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/disarm, /confiscate, /frisk, /resetemail, /processn(ame)c(hange), /namechanges");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/setskin, /geoip, /checkstats, /checkproperties, /checkguns, /makeooc");
		SendClientMessage(playerid, 0x985F83FF, "[MISC]: {BF7AA6}/ecc, /entercar, /setint, /setvw, /removemask, /omaskid, /adminad, /adminbreaking");
		SendClientMessage(playerid, 0x985F83FF, "[MISC]: {BF7AA6}/setmotd, /(toggle)noclip, /(set)customanim, /admin911, /makehelper, /createatm");
		SendClientMessage(playerid, 0x58DC99FF, "[REFUNDS]: {B2FFCD}/addrefund, /oaddrefund, /checkrefunds");
		SendClientMessage(playerid, 0xF87070FF, "[ANTICHEAT]: {FDBCBC}/toggleac, /checkpausedac");

	}

	if ( GetPlayerAdminLevel ( playerid ) > 6 ) {

		SendClientMessage(playerid, 0xF87070FF, "[ADMIN]: {FDBCBC}/ajail, /unajail, /offlineajail, /kick, /slap, /(un)freeze, /(un)ban");
		SendClientMessage(playerid, 0xF87070FF, "[ADMIN]: {FDBCBC}/offlineban, /(un)banip, /settime, /setweather, /setintrosong");
		SendClientMessage(playerid, 0xF87070FF, "[MANAGER]: {FDBCBC}/makeadmin /makehelper, /adminhex, /helperhex, /givemoney, /takemoney");
		SendClientMessage(playerid, 0xF87070FF, "[MANAGER]: {FDBCBC}/addplayerskin, /makecontributor, /setgunrights ((gun ban))");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/aduty, /reports, /a(ccept)r(eport), /d(eny)r(eport), /punishlist");
		SendClientMessage(playerid, 0x58DD85FF, "[DUTY]: {B2FFCD}/spec(tate), /getcoordinates, /whonear, /clearinjuries, /jetpack, /faction(un)ban, /ofactionban");
		SendClientMessage(playerid, 0xD95023FF, "[CHAT]: {FA6D3E}/a(chat), /acinvite, /acuninvite, /toggleooc, /aooc, /man, /togd(onator)c(hat), /adminrumour");
		SendClientMessage(playerid, 0xFFCC68FF, "[TELEPORT]: {FFE1A8}/fw, /up, /dn, /goto, /gethere, /mark[1-3], /gotomark[1-3], /gotoxyz, /tp");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/getcharid, /getc, /getma, /adminrecord, /maskid, /getnumber");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/disarm, /confiscate, /frisk, /resetemail, /processn(ame)c(hange), /namechanges");
		SendClientMessage(playerid, 0x77BBFAFF, "[PLAYER]: {BBDEFF}/setskin, /geoip, /checkstats, /checkproperties, /checkguns, /makeooc");
		SendClientMessage(playerid, 0x985F83FF, "[MISC]: {BF7AA6}/ecc, /entercar, /setint, /setvw, /removemask, /omaskid, /adminad, /adminbreaking");
		SendClientMessage(playerid, 0x985F83FF, "[MISC]: {BF7AA6}/setmotd, /(toggle)noclip, /(set)customanim, /admin911");
		SendClientMessage(playerid, 0x58DC99FF, "[REFUNDS]: {B2FFCD}/addrefund, /oaddrefund, /checkrefunds");
		SendClientMessage(playerid, 0xF87070FF, "[ANTICHEAT]: {FDBCBC}/toggleac, /checkpausedac");

	}

	return true;
}

// Prints vehicle administrator commands.
ShowAdminVehicleCommands(playerid) {

	if(!Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
		return true;
	}

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Vehicle Administrator Commands  ___________ ]");
	
	if ( GetPlayerAdminLevel ( playerid ) == 2 ) {
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carfix, /acarfuel, /respawnrentals, /respawnallcars, /findrentals");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carrespawn, /gotocar, /getcar, /fservervehs");
	}


	if ( GetPlayerAdminLevel ( playerid ) == 3 ) {
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carfix, /acarfuel, /respawnrentals, /respawnallcars, /findrentals");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carrespawn, /gotocar, /getcar, /carflip, /deletecar, /carslap");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carhp, /carsavesiren, /caradminpark, /ecc, /entercar, /engine");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/caradmincolor");
	}

	if ( GetPlayerAdminLevel ( playerid ) == 4 ) {
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carfix, /acarfuel, /respawnrentals, /respawnallcars, /findrentals");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carrespawn, /gotocar, /getcar, /carflip, /deletecar, /carslap");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carhp, /carsavesiren, /caradminpark, /ecc, /entercar, /engine");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/caradmincolor, /viewcars");
	}

	if ( GetPlayerAdminLevel ( playerid ) >= 5 ) {
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carfix, /acarfuel, /respawnrentals, /respawnallcars, /findrentals");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carrespawn, /gotocar, /getcar, /carflip, /deletecar, /carslap");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/carhp, /carsavesiren, /caradminpark, /ecc, /entercar, /engine");
		SendClientMessage(playerid, 0xF87070FF, "[VEHICLE]: {FDBCBC}/caradmincolor, /viewcars, /carcreate, /carowner, /cartype, /carjob");
	}

	return true;
}

// Prints property administrator commands.
ShowAdminPropertyCommands(playerid) {

	if(!Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
		return true;
	}

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Property Administrator Commands  ___________ ]");
	
	if ( GetPlayerAdminLevel ( playerid ) == 2 ) {
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
	}


	if ( GetPlayerAdminLevel ( playerid ) == 3 ) {
		SendClientMessage(playerid, 0x58DD85FF, "[PROPERTY]: {B2FFCD}/propertycheck, /propertygoto, /propertyintlist, /checkproperties");
	}

	if ( GetPlayerAdminLevel ( playerid ) >= 4 ) {
		SendClientMessage(playerid, 0x58DD85FF, "[PROPERTY]: {B2FFCD}/propertycheck, /propertygoto, /propertyintlist, /checkproperties");
		SendClientMessage(playerid, 0x58DD85FF, "[PROPERTY]: {B2FFCD}/propertycreate, /propertymove, /propertydelete, /propertyprice, /propertyauction");
		SendClientMessage(playerid, 0x58DD85FF, "[PROPERTY]: {B2FFCD}/propertybuytype, /propertybuypoint, /propertyint(erior), /propertytype, /passpointcreate");
		SendClientMessage(playerid, 0x58DD85FF, "[PROPERTY]: {B2FFCD}/passpointdelete, /passpointlink, /passpointmove, /passpointgoto, /passpointname, /passpointtype");
		SendClientMessage(playerid, 0x58DD85FF, "[PROPERTY]: {B2FFCD}/passpointcolor, /passpointfaction, /passpointplayer");
	}

	return true;
}

// Prints faction administrator commands.
ShowAdminFactionCommands(playerid) {

	if(!Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
		return true;
	}

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Faction Administrator Commands  ___________ ]");
	
	if ( GetPlayerAdminLevel ( playerid ) == 2 ) {
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
	}

	if ( GetPlayerAdminLevel ( playerid ) == 3 ) {
		SendClientMessage(playerid, 0x77BBFAFF, "[FACTION]: {BBDEFF}/afjoin, /fchatban, /setduty");
		SendClientMessage(playerid, 0x77BBFAFF, "[ARMORY]: {BBDEFF}/armoryplace, /reloadarmories");
	}

	if ( GetPlayerAdminLevel ( playerid ) >= 4 ) {
		SendClientMessage(playerid, 0x77BBFAFF, "[FACTION]: {BBDEFF}/afjoin, /f(action)name, /f(action)create, /f(action)hex, /f(action)skinadd");
		SendClientMessage(playerid, 0x77BBFAFF, "[FACTION]: {BBDEFF}/f(action)extra, /factionresetperkcd, /f(action)visible, /fchatban");
		SendClientMessage(playerid, 0x77BBFAFF, "[ARMORY]: {BBDEFF}/armoryplace, /reloadarmories");
	}

	return true;
}

// Prints dynamic-system administrator commands (gates, ATMs, objects...).
ShowAdminDynamicCommands(playerid) {

	if(!Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
		return true;
	}

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Dynamic System Administrator Commands  ___________ ]");
	
	if ( GetPlayerAdminLevel ( playerid ) <= 3 ) {
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
	}

	if ( GetPlayerAdminLevel ( playerid ) == 4 ) {
		SendClientMessage(playerid, 0x58DD85FF, "[GATE]: {B2FFCD}/gatecreate, /gateradius, /gateopen, /gatetoll, /gategoto, /gatemove, /gateclone, /gatefaction");
		SendClientMessage(playerid, 0x58DD85FF, "[GATE]: {B2FFCD}/gatetexture, /gateworld, /gateint, /gatetype, /gatespeed, /gateautoclose, /gateautoopen");

		SendClientMessage(playerid, 0xF87070FF, "[POOL]: {FDBCBC}/poolcreate, /poolendgame, /poolcolor,  /poolmove, /pooldelete");


		SendClientMessage(playerid, 0x094204FF, "[TURF]: {199C0E}/gangzoneassign, /gangzonecontest, /gangzoneid");

		SendClientMessage(playerid, 0x985F83FF, "[ATTACH]: {BF7AA6}/addattachpoint, /attachpointdelete, /attachpointlink");

		SendClientMessage(playerid, 0x297183FF, "[WARDROBE]: {FFE1A8}/wardrobecheck, /wardrobeadd, /wardrobedelete");
		SendClientMessage(playerid, 0x297183FF, "[WARDROBE]: {FFE1A8}/wardrobetype, /wardrobeowner, /wardrobemove, /wardrobegoto");

		SendClientMessage(playerid, 0xd768d9FF, "[ACTORS]: {feadff}/actorcreate, /reloadactors, /actordelete, /actornear, /actormove, /actoranim, /actorinfo");

		SendClientMessage(playerid, 0x4FC3F7FF, "[OBJECTS]: {BDE9FF}/objcreate, /objnear, /objgoto, /objedit, /objclone, /objdelete");
	}

	if ( GetPlayerAdminLevel ( playerid ) == 5 ) {
		SendClientMessage(playerid, 0x58DD85FF, "[GATE]: {B2FFCD}gatecreate, /gateradius, /gateopen, /gatetoll, /gategoto, /gatemove, /gateclone, /gatefaction");
		SendClientMessage(playerid, 0x58DD85FF, "[GATE]: {B2FFCD}/gatetexture, /gateworld, /gateint, /gatetype, /gatespeed, /gateautoclose, /gateautoopen");

		SendClientMessage(playerid, 0xF87070FF, "[POOL]: {FDBCBC}/poolcreate, /poolendgame, /poolcolor,  /poolmove, /pooldelete");


		SendClientMessage(playerid, 0x985F83FF, "[ATTACH]: {BF7AA6}/addattachpoint, /attachpointdelete, /attachpointlink");

		SendClientMessage(playerid, 0x77BBFAFF, "[SPRAY]: {BBDEFF}/s(pray)t(ag)create, /s(pray)t(ag)delete");

		SendClientMessage(playerid, 0x094204FF, "[TURF]: {199C0E}/gangzoneassign, /gangzonecontest, /gangzoneid");
		
		SendClientMessage(playerid, 0xFFCC68FF, "[FUEL]: {FFE1A8}/createfuelpump, /linkpumptostation, /unlinkpump, /viewlinkedpumps, /gotopump");
		SendClientMessage(playerid, 0xFFCC68FF, "[FUEL]: {FFE1A8}/movepump, /deletepump, /unlinkedpumps, createfuelstation, /gotostation");
		SendClientMessage(playerid, 0xFFCC68FF, "[FUEL]: {FFE1A8}/movestation, /auctionstation, /deletestation, /stationinfo");

		// Emmet gun system disabled
		//SendClientMessage(playerid, 0x58DD85FF, "[EMMET]: {B2FFCD}/emmetcreate, /emmetowner, /emmetassign, /emmetid, /emmetgoto, /emmetmove, /emmetskin, /emmetname, /emmetcreatespawn, /emmetcrateinfo");
	
		SendClientMessage(playerid, 0x297183FF, "[WARDROBE]: {FFE1A8}/wardrobecheck, /wardrobeadd, /wardrobedelete");
		SendClientMessage(playerid, 0x297183FF, "[WARDROBE]: {FFE1A8}/wardrobetype, /wardrobeowner, /wardrobemove, /wardrobegoto");

		SendClientMessage(playerid, 0xd768d9FF, "[ACTORS]: {feadff}/actorcreate, /reloadactors, /actordelete, /actornear, /actormove, /actoranim, /actorinfo");

		SendClientMessage(playerid, 0x4FC3F7FF, "[OBJECTS]: {BDE9FF}/objcreate, /objnear, /objgoto, /objedit, /objclone, /objdelete");
	}

	if ( GetPlayerAdminLevel ( playerid ) > 5 ) {
		SendClientMessage(playerid, 0x58DD85FF, "[GATE]: {B2FFCD}/gatecreate, /gateradius, /gateopen, /gatetoll, /gategoto, /gatemove, /gateclone, /gatefaction");
		SendClientMessage(playerid, 0x58DD85FF, "[GATE]: {B2FFCD}/gatetexture, /gateworld, /gateint, /gatetype, /gatespeed, /gateautoclose, /gateautoopen");

		SendClientMessage(playerid, 0xF87070FF, "[POOL]: {FDBCBC}/poolcreate, /poolendgame, /poolcolor,  /poolmove, /pooldelete");


		SendClientMessage(playerid, 0x985F83FF, "[ATTACH]: {BF7AA6}/addattachpoint, /attachpointdelete, /attachpointlink");

		SendClientMessage(playerid, 0x77BBFAFF, "[SPRAY]: {BBDEFF}/s(pray)t(ag)create, /s(pray)t(ag)delete");

		SendClientMessage(playerid, 0x094204FF, "[TURF]: {199C0E}/gangzoneassign, /gangzonecontest, /gangzoneid");

		SendClientMessage(playerid, 0xFFCC68FF, "[FUEL]: {FFE1A8}/createfuelpump, /linkpumptostation, /unlinkpump, /viewlinkedpumps, /gotopump");
		SendClientMessage(playerid, 0xFFCC68FF, "[FUEL]: {FFE1A8}/movepump, /deletepump, /unlinkedpumps, createfuelstation, /gotostation");
		SendClientMessage(playerid, 0xFFCC68FF, "[FUEL]: {FFE1A8}/movestation, /auctionstation, /deletestation, /stationinfo");

		// Emmet gun system disabled
		//SendClientMessage(playerid, 0x58DD85FF, "[EMMET]: {B2FFCD}/emmetcreate, /emmetowner, /emmetassign, /emmetid, /emmetgoto, /emmetmove, /emmetskin, /emmetname");
		SendClientMessage(playerid, 0xF87070FF, "[DRUGS]: {FDBCBC}/drugsetparam, /drugsetstage /drugsetticks, /drugforcefinish, /drugsuppliergoto ");
	
		SendClientMessage(playerid, 0x297183FF, "[WARDROBE]: {FFE1A8}/wardrobecheck, /wardrobeadd, /wardrobedelete");
		SendClientMessage(playerid, 0x297183FF, "[WARDROBE]: {FFE1A8}/wardrobetype, /wardrobeowner, /wardrobemove, /wardrobegoto");

		SendClientMessage(playerid, 0xd768d9FF, "[ACTORS]: {feadff}/actorcreate, /reloadactors, /actordelete, /actornear, /actormove, /actoranim, /actorinfo");

		SendClientMessage(playerid, 0x4FC3F7FF, "[OBJECTS]: {BDE9FF}/objcreate, /objnear, /objgoto, /objedit, /objclone, /objdelete");
	}

	return true;
}

// Prints miscellaneous administrator commands.
ShowAdminMiscCommands(playerid) {

	if(!Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
		return true;
	}

	SendClientMessage(playerid, 0x297183FF, "[ ___________ Misc Administrator Commands  ___________ ]");
	
	if ( GetPlayerAdminLevel ( playerid ) <= 5 ) {
		return SendServerMessage(playerid, COLOR_ERROR, "Error", "DEDEDE", "There are no commands available to you in this category.");
	}

	if ( GetPlayerAdminLevel ( playerid ) >= 6) {
		SendClientMessage(playerid, 0x77BBFAFF, "[SPOOF]: {BBDEFF}/spoofbuy, /spoofpool, /spoofgun, /spoofmats, /spoofdrugstation, /spoofammo");
		SendClientMessage(playerid, 0x77BBFAFF, "[SPOOF]: {BBDEFF}/spoofattach, /spoofprop, /poolspoof, /forcechopshop, /tempclearchopshopcd");
	}

	return true;
}

#if defined FEATURE_FNR
// Shows the Fear & Respect guide (when that optional system is enabled).
ShowFnRCommands(playerid) {
	
	new string[2048];
	
	strcat(string, "{297183}Fear & Respect System Guide\n\n");
	
	strcat(string, "{58DD85}What is Fear & Respect?\n");
	strcat(string, "{DEDEDE}The F&R system tracks your character's street reputation through two stats: {252E92}Respect{DEDEDE} and {AC1818}Fear{DEDEDE}.\n");
	strcat(string, "{DEDEDE}Your combined total determines your level (1-11), unlocking perks and bonuses as you progress.\n\n");
	
	strcat(string, "{58DD85}How to Earn FnR Points:\n");
	strcat(string, "{B2FFCD}» {DEDEDE}Spray tags for your set\n");
	strcat(string, "{B2FFCD}» {DEDEDE}Compete in lowrider duels\n");
	strcat(string, "{B2FFCD}» {DEDEDE}Rob stores and participate in criminal activities\n");
	strcat(string, "{B2FFCD}» {DEDEDE}Buy properties and vehicles\n");
	strcat(string, "{B2FFCD}» {DEDEDE}Engage with other server features\n\n");
	
	strcat(string, "{58DD85}Player Interaction (Level 2+):\n");
	strcat(string, "{DEDEDE}Once you reach Level 2, you can give your earned FnR Points to other players as either ");
	strcat(string, "{252E92}Respect{DEDEDE} or {AC1818}Fear{DEDEDE}, rewarding them for good roleplay or their actions.\n\n");
	
	strcat(string, "{58DD85}Robbery Bonuses by Level:\n");
	strcat(string, "{B2FFCD}Level 1-2:{DEDEDE} Standard payouts\n");
	strcat(string, "{B2FFCD}Level 3-4:{DEDEDE} +15% bonus\n");
	strcat(string, "{B2FFCD}Level 5-6:{DEDEDE} +30% bonus\n");
	strcat(string, "{B2FFCD}Level 7-8:{DEDEDE} +50% bonus\n");
	strcat(string, "{B2FFCD}Level 9-10:{DEDEDE} +70% bonus\n");
	strcat(string, "{B2FFCD}Level 11 (Kingpin):{DEDEDE} +100% bonus (DOUBLE payouts!)\n\n");
	
	strcat(string, "{58DD85}Level Progression:\n");
	strcat(string, "{DEDEDE}1. Street Rookie\n");
	strcat(string, "{DEDEDE}2. Block Hustler {b8b8b8}(100 pts)\n");
	strcat(string, "{DEDEDE}3. Hood Soldier {b8b8b8}(300 pts)\n");
	strcat(string, "{DEDEDE}4. Street Captain {b8b8b8}(700 pts)\n");
	strcat(string, "{DEDEDE}5. Block Lieutenant {b8b8b8}(2,000 pts)\n");
	strcat(string, "{DEDEDE}6. Hood Commander {b8b8b8}(3,000 pts)\n");
	strcat(string, "{DEDEDE}7. Street Veteran {b8b8b8}(4,000 pts)\n");
	strcat(string, "{DEDEDE}8. Block Enforcer {b8b8b8}(5,000 pts)\n");
	strcat(string, "{DEDEDE}9. Hood Legend {b8b8b8}(6,000 pts)\n");
	strcat(string, "{DEDEDE}10. Street Boss {b8b8b8}(7,000 pts)\n");
	strcat(string, "{DEDEDE}11. Kingpin {b8b8b8}(8,000 pts - MAX)\n\n");
	
	strcat(string, "{58DD85}Commands:\n");
	strcat(string, "{B2FFCD}/fnrstats{DEDEDE} - Check your current Fear & Respect stats\n");
	strcat(string, "{B2FFCD}/giverespect{DEDEDE} - Give respect points to another player\n");
	strcat(string, "{B2FFCD}/givefear{DEDEDE} - Give fear points to another player\n\n");
	
	strcat(string, "{FFE1A8}Build your reputation, earn perks, and dominate the streets!");
	
	ShowPlayerDialog(playerid, DIALOG_FNR_HELP, DIALOG_STYLE_MSGBOX, "Fear & Respect System", string, "Close", "");
	
	return true;
}
#else
// Replacement shown when the Fear & Respect system is disabled.
ShowFnRCommands(playerid) {

	SendClientMessage(playerid, COLOR_GRAD0, "Fear & Respect is currently disabled.");

	return true ;
}
#endif

// Shows the burglary guide.
ShowBurglaryCommands(playerid) {

	new string[2048];

	strcat(string, "{297183}Burglary Guide\n\n");

	strcat(string, "{58DD85}Starting a Burglary:\n");
	strcat(string, "{B2FFCD}/burglary{DEDEDE} - Start a burglary while standing near a property exterior.\n");
	strcat(string, "{DEDEDE}Police cannot start burglaries, and you must finish your cooldown before starting another.\n\n");

	strcat(string, "{58DD85}Inside the Property:\n");
	strcat(string, "{B2FFCD}Y Key{DEDEDE} - Steal the nearest valid household item.\n");
	strcat(string, "{B2FFCD}Y Key while carrying{DEDEDE} - Drop the item you are carrying.\n");
	strcat(string, "{DEDEDE}Keep your noise meter low. Sprinting, jumping, stealing, and dropping items make noise.\n");
	strcat(string, "{DEDEDE}If the meter fills, the burglar alarm triggers and law enforcement is alerted.\n\n");

	strcat(string, "{58DD85}Session Rules:\n");
	strcat(string, "{DEDEDE}You have a limited window to steal items. Once it ends, you can leave but cannot steal more.\n");
	strcat(string, "{DEDEDE}Stay within 15 meters of the property exterior while outside, or the session ends.\n");
	strcat(string, "{DEDEDE}You cannot re-enter the property while carrying stolen goods.\n\n");

	strcat(string, "{58DD85}Selling and Storing Goods:\n");
	strcat(string, "{B2FFCD}/sellgoods{DEDEDE} - Sell carried stolen goods at a pawn shop.\n");
	strcat(string, "{B2FFCD}/cartrunkstoreburglary (/ctsburg){DEDEDE} - Store carried stolen goods in a vehicle trunk.\n");
	strcat(string, "{B2FFCD}/cartrunktakeburglary (/cttburg){DEDEDE} - Take stored burglary goods from a vehicle trunk.\n\n");

	strcat(string, "{FFE1A8}Get in, stay quiet, get out, and move the goods before the heat catches up.");

	ShowPlayerDialog(playerid, DIALOG_BURGLARY_HELP, DIALOG_STYLE_MSGBOX, "Burglary", string, "Close", "");

	return true;
}


// Shows the dock help overview.
ShowDockHelp_Overview(playerid) {
    SendClientMessage(playerid, 0x297183FF, "[ ___________ Dock Commands  ___________ ]");
    SendClientMessage(playerid, 0xDEDEDEFF, "[USAGE]: {B8B8B8}/help dock {b8b8b8}[ scrapyard, logistics, freighter ]");
    SendClientMessage(playerid, 0x58DD85FF, "[Scrapyard]:{B2FFCD} /startpackage, /claimpackage, /collectpackage, /leavescraprun, /cancelpackage");
    SendClientMessage(playerid, 0xFFCC68FF, "[Logistics Centre]:{FFE1A8} /startshipment, /checktrailer, /cancelshipment");
    SendClientMessage(playerid, 0x77BBFAFF, "[Freighter Yard]:{BBDEFF} /startcargorun, /claimcontainer, /collectcontainer, /putcargo, /leavemission");
    //SendClientMessage(playerid, 0x5CB8D1FF, "[INFO]: {B0E0EAFF}Use /dockstatus or /entitystatus to check dock entity ownership.");
    return true;
}

// Shows the scrapyard help.
ShowDockHelp_Scrapyard(playerid) {
    SendClientMessage(playerid, 0x297183FF, "[ ___________ Scrapyard  ___________ ]");
    SendClientMessage(playerid, 0xDEDEDEFF, "{DEDEDE}The Scrapyard is a faction-controlled dock entity. Every 100 dock missions");
    SendClientMessage(playerid, 0xDEDEDEFF, "{DEDEDE}a special package run unlocks, rewarding crew members with cash.");
    SendClientMessage(playerid, 0x58DD85FF, "[PACKAGE RUN]:{B2FFCD} /startpackage - Start a package run (Tier 1 only, unlocks every 100 missions)");
    SendClientMessage(playerid, 0x58DD85FF, "[PACKAGE RUN]:{B2FFCD} /claimpackage - Open the container at the marked location");
    SendClientMessage(playerid, 0x58DD85FF, "[PACKAGE RUN]:{B2FFCD} /collectpackage - Pick up the package from inside the container");
    SendClientMessage(playerid, 0x58DD85FF, "[PACKAGE RUN]:{B2FFCD} /leavescraprun - Leave the active run (not allowed while carrying the package)");
    SendClientMessage(playerid, 0x58DD85FF, "[PACKAGE RUN]:{B2FFCD} /cancelpackage - Cancel the run as the initiator");
    SendClientMessage(playerid, 0xFFCC68FF, "[PAYOUT]:{FFE1A8} Carrier: $15,000 | Crew: $7,500 each");
    if (Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /assignentity 0 [factionEnumID] - Assign Scrapyard (slot 0) to a faction");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /dockentities - List all dock entity owners");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /entitystatus - View each entity's bank & mission count");
    }
    return true;
}

// Shows the logistics centre help.
ShowDockHelp_Logistics(playerid) {
    SendClientMessage(playerid, 0x297183FF, "[ ___________ Logistics Centre  ___________ ]");
    SendClientMessage(playerid, 0xDEDEDEFF, "{DEDEDE}The Logistics Centre is a faction-controlled dock entity. After every 100");
    SendClientMessage(playerid, 0xDEDEDEFF, "{DEDEDE}dock missions a shipment run unlocks for Tier 1, rewarding the driver with cash.");
    SendClientMessage(playerid, 0xFFCC68FF, "[SHIPMENT RUN]:{FFE1A8} /startshipment - Begin a shipment run in your Linerunner (Tier 1 only)");
    SendClientMessage(playerid, 0xFFCC68FF, "[SHIPMENT RUN]:{FFE1A8} /checktrailer - Inspect a nearby trailer at the depot to find the correct one");
    SendClientMessage(playerid, 0xFFCC68FF, "[SHIPMENT RUN]:{FFE1A8} /cancelshipment - Cancel your active shipment run");
    SendClientMessage(playerid, 0x58DD85FF, "[NOTES]:{B2FFCD} You must own and be inside a spawned Linerunner (model 403) to start.");
    SendClientMessage(playerid, 0x58DD85FF, "[NOTES]:{B2FFCD} Drive to the depot checkpoint, get out and /checktrailer on each one to find the correct trailer.");
    SendClientMessage(playerid, 0x58DD85FF, "[NOTES]:{B2FFCD} Once attached, drive the Linerunner back to the Logistics Centre hub.");
    SendClientMessage(playerid, 0xFFCC68FF, "[PAYOUT]:{FFE1A8} Driver: $18,000");
    if (Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /assignentity 1 [factionEnumID] - Assign Logistics Centre (slot 1) to a faction");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /dockentities - List all dock entity owners");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /entitystatus - View each entity's bank & mission count");
    }
    return true;
}

// Shows the freighter yard help.
ShowDockHelp_Freighter(playerid) {
    SendClientMessage(playerid, 0x297183FF, "[ ___________ Freighter Yard  ___________ ]");
    SendClientMessage(playerid, 0xDEDEDEFF, "{DEDEDE}The Freighter Yard is a faction-controlled dock entity. Every 100 dock");
    SendClientMessage(playerid, 0xDEDEDEFF, "{DEDEDE}missions a cargo run unlocks. The entire faction crew is auto-enrolled.");
    SendClientMessage(playerid, 0x77BBFAFF, "[CARGO RUN]:{BBDEFF} /startcargorun - Start a cargo run (Tier 1 only, unlocks every 100 missions)");
    SendClientMessage(playerid, 0x77BBFAFF, "[CARGO RUN]:{BBDEFF} /claimcontainer - Open the cargo container at the freighter's stop");
    SendClientMessage(playerid, 0x77BBFAFF, "[CARGO RUN]:{BBDEFF} /collectcontainer - Pick up the cargo from inside the container");
    SendClientMessage(playerid, 0x77BBFAFF, "[CARGO RUN]:{BBDEFF} /putcargo - Load the cargo onto the freighter (must be within 50m of it)");
    SendClientMessage(playerid, 0x77BBFAFF, "[CARGO RUN]:{BBDEFF} /leavemission - Leave the cargo run (not allowed while carrying the cargo)");
    SendClientMessage(playerid, 0x58DD85FF, "[NOTES]:{B2FFCD} Follow the freighter when it departs. The stop location is random each run.");
    SendClientMessage(playerid, 0x58DD85FF, "[NOTES]:{B2FFCD} Once the cargo holder uses /putcargo, the freighter returns home to complete the run.");
    SendClientMessage(playerid, 0xFFCC68FF, "[PAYOUT]:{FFE1A8} Cargo holder: $15,000 | Crew: $7,500 each");
    if (Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /assignentity 2 [factionEnumID] - Assign Freighter Yard (slot 2) to a faction");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /dockentities - List all dock entity owners");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /entitystatus - View each entity's bank & mission count");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /freight [spawn/remove/goto/speed/info/list/assign/clear] - Manage freighters (developer only)");
        SendClientMessage(playerid, 0xF87070FF, "[ADMIN]:{FDBCBC} /pathway [new/node/save/cancel/list/remove] - Build & manage freighter pathways (developer only)");
    }
    return true;
}

// /dockhelp [topic] - help for the dock-related systems.
CMD:dockhelp(playerid, params[]) {

    new option[32];

    if (sscanf(params, "s[32]", option))
        return ShowDockHelp_Overview(playerid);

    if (!strcmp(option, "scrapyard", true) || !strcmp(option, "scrap", true))
        return ShowDockHelp_Scrapyard(playerid);

    if (!strcmp(option, "logistics", true) || !strcmp(option, "logistic", true) || !strcmp(option, "lc", true))
        return ShowDockHelp_Logistics(playerid);

    if (!strcmp(option, "freighter", true) || !strcmp(option, "freight", true) || !strcmp(option, "fy", true))
        return ShowDockHelp_Freighter(playerid);

    return ShowDockHelp_Overview(playerid);
}

CMD:dockinfo(playerid, params[]) {
    return cmd_dockhelp(playerid, params);
}


CMD:fnrhelp(playerid, params[]) {
	return ShowFnRCommands(playerid);
}

CMD:fearhelp(playerid, params[]) {
	return ShowFnRCommands(playerid);
}

CMD:respecthelp(playerid, params[]) {
	return ShowFnRCommands(playerid);
}

CMD:burglaryhelp(playerid, params[]) {
	return ShowBurglaryCommands(playerid);
}

CMD:burghelp(playerid, params[]) {
	return ShowBurglaryCommands(playerid);
}

// /help [topic] - the main help command; opens the topic you ask for.
CMD:help(playerid, params[]) {

	new option[32];

	if(sscanf(params, "s[32]", option))
		return ShowHelpCommands(playerid);

	if(!strcmp(option, "chat", true) || !strcmp(option, "text", true) || ! strcmp(option, "rp", true)) {
		return ShowChatCommands(playerid);
	}

	if(!strcmp(option, "property", true) || !strcmp(option, "prop", true) || !strcmp(option, "house", true) || !strcmp(option, "business", true) || !strcmp(option, "houses", true) || !strcmp(option, "properties", true) || !strcmp(option, "businesses", true))
		return ShowPropertyCommands(playerid);

	if(!strcmp(option, "car", true) || !strcmp(option, "vehicle", true) || !strcmp(option, "veh", true) || !strcmp(option, "v", true) || !strcmp(option, "cars", true) || !strcmp(option, "vehs", true)|| !strcmp(option, "vehicles", true))
		return ShowVehicleCommands(playerid);

	if(!strcmp(option, "gun", true) || !strcmp(option, "guns", true) || !strcmp(option, "weapon", true) || !strcmp(option, "weapons", true)|| !strcmp(option, "firearms", true))
		return ShowGunCommands(playerid);

	if(!strcmp(option, "jobs", true) || !strcmp(option, "job", true) || !strcmp(option, "work", true))
		return ShowJobCommands(playerid);

	if(!strcmp(option, "fish", true) || !strcmp(option, "fishing", true) || !strcmp(option, "fishes", true))
		return ShowFishCommands(playerid);

	if(!strcmp(option, "faction", true) || !strcmp(option, "factions", true))
		return ShowFactionCommands(playerid);

	if(!strcmp(option, "drug", true) || !strcmp(option, "drugs", true))
		return ShowDrugCommands(playerid);

	if(!strcmp(option, "voice", true) || !strcmp(option, "voiceline", true) || !strcmp(option, "voicelines", true))
		return ShowVoiceCommands(playerid);

	if(!strcmp(option, "phone", true) || !strcmp(option, "cell", true) || !strcmp(option, "call", true))
		return ShowPhoneCommands(playerid);

	if(!strcmp(option, "furniture", true) || !strcmp(option, "furni", true) || !strcmp(option, "decorate", true))
		return ShowFurniCommands(playerid);

	if(!strcmp(option, "spray", true) || !strcmp(option, "spraytag", true) || !strcmp(option, "tag", true))
		return ShowSpraytagCommands(playerid);

	if(!strcmp(option, "basket", true) || !strcmp(option, "basketball", true))
		return ShowBasketballCommmands(playerid);


	if(!strcmp(option, "gate", true) || !strcmp(option, "gates", true))
		return ShowGateCommands(playerid);

	if(!strcmp(option, "anim", true) || !strcmp(option, "anims", true))
		return ShowAnimCommands(playerid);

	if(!strcmp(option, "miscellaneous", true) || !strcmp(option, "misc", true))
		return ShowMiscCommands(playerid);

	if(!strcmp(option, "staff", true) || !strcmp(option, "admin", true))
		return ShowStaffCategoryCommands(playerid);
	
	if(!strcmp(option, "fnr", true) || !strcmp(option, "fear", true) || !strcmp(option, "respect", true))
		return ShowFnRCommands(playerid);

	if(!strcmp(option, "burglary", true) || !strcmp(option, "burg", true))
		return ShowBurglaryCommands(playerid);

	if (!strcmp(option, "dock", true) || !strcmp(option, "docks", true))
        return ShowDockHelp_Overview(playerid);


	return true ;
}

CMD:oldahelp(playerid, params[]) {
	return ShowOldStaffCommands(playerid);
}

// Prints the staff command categories.
ShowStaffCategoryCommands(playerid) {
	
	SendClientMessage(playerid, 0x297183FF, "[ ___________ Admin Commands  ___________ ]");

	SendClientMessage(playerid, 0xDEDEDEFF, "[COMMANDS]: {B8B8B8}/staffhelp {b8b8b8}[helper, admin, vehicle, property, faction, dynamic, misc ]");
	SendClientMessage(playerid, 0xDEDEDEFF, "Use /oldahelp for the old command list format.");
	
	return true;
}


// /staffhelp [category] - opens the staff command lists (helpers see helper commands).
CMD:staffhelp(playerid, params[]) {

	if(IsPlayerHelper(playerid) && !Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		ShowHelperCommands(playerid);
	}

	if(!Account[playerid][E_PLAYER_ACCOUNT_STAFFLEVEL]) {
		return false;
	}

	new option[32];

	if(sscanf(params, "s[32]", option))
		return ShowStaffCategoryCommands(playerid);

	if(!strcmp(option, "helper", true)) {
		return ShowHelperCommands(playerid);
	}

	if(!strcmp(option, "admin", true) || !strcmp(option, "administrator", true)) {
		return ShowAdminGeneralCommands(playerid);
	}

	if(!strcmp(option, "car", true) || !strcmp(option, "vehicle", true)) {
		return ShowAdminVehicleCommands(playerid);
	}

	if(!strcmp(option, "house", true) || !strcmp(option, "biz", true) || !strcmp(option, "prop", true) || !strcmp(option, "properties", true) || !strcmp(option, "property", true)) {
		return ShowAdminPropertyCommands(playerid);
	}

	if(!strcmp(option, "f", true) || !strcmp(option, "faction", true)) {
		return ShowAdminFactionCommands(playerid);
	}

	if(!strcmp(option, "miscellaneous", true) || !strcmp(option, "misc", true)) {
		return ShowAdminMiscCommands(playerid);
	}

	if(!strcmp(option, "dynamic", true) || !strcmp(option, "dyn", true)) {
		return ShowAdminDynamicCommands(playerid);
	}
	

	return true;
}



// all shortcuts.

// property

CMD:bizhelp(playerid, params[]) {return cmd_propertyhelp(playerid, params);}
CMD:househelp(playerid, params[]) {return cmd_propertyhelp(playerid, params);}
CMD:prophelp(playerid, params[]) {return cmd_propertyhelp(playerid, params);}

CMD:propertyhelp(playerid, params[]) {
	return ShowPropertyCommands(playerid);
}

// car

CMD:vhelp(playerid, params[]) {return cmd_carhelp(playerid, params);}
CMD:vehiclehelp(playerid, params[]) {return cmd_carhelp(playerid, params);}

CMD:carhelp(playerid, params[]) {
	return ShowVehicleCommands(playerid);
}


// guns


CMD:ghelp(playerid, params[]) {return cmd_gunhelp(playerid, params);}
CMD:weaponhelp(playerid, params[]) {return cmd_gunhelp(playerid, params);}

CMD:gunhelp(playerid, params[]) {
	return ShowGunCommands(playerid);
}


// jobs
CMD:truckerhelp(playerid, params[]) {return cmd_jobhelp(playerid, params);}

CMD:jobs(playerid, params[]) {return cmd_jobhelp(playerid, params);}

CMD:jobhelp(playerid, params[]) {
	return ShowJobCommands(playerid);
}


//factions

CMD:fhelp(playerid, params[]) {return cmd_factionhelp(playerid, params);}

CMD:factionhelp(playerid, params[]){
	return ShowFactionCommands(playerid);
}

// drugs

CMD:drughelp(playerid, params[]){
	return ShowDrugCommands(playerid);
}

// voice
CMD:voicehelp(playerid, params[]){
	return ShowVoiceCommands(playerid);
}

// call
CMD:phonehelp(playerid, params[]){
	return ShowPhoneCommands(playerid);
}

// furni

CMD:furniturehelp(playerid, params[]){
	return ShowFurniCommands(playerid);
}

CMD:furnihelp(playerid, params[]){
	return ShowFurniCommands(playerid);
}

// spraytag

CMD:spraytaghelp(playerid, params[]){
	return ShowSpraytagCommands(playerid);
}

CMD:sprayhelp(playerid, params[]){
	return ShowSpraytagCommands(playerid);
}

//gate

CMD:gatehelp(playerid, params[]){
	return ShowGateCommands(playerid);
}

// anims

CMD:animhelp ( playerid, params [] ) {
	return ShowAnimCommands(playerid);
}

CMD:anims ( playerid, params [] ) {
	return ShowAnimCommands(playerid);
}

// misc

CMD:mischelp ( playerid, params [] ) {
	return ShowMiscCommands(playerid);
}

CMD:commands ( playerid, params [] ) {
	return ShowMiscCommands(playerid);
}


// staff
CMD:ahelp ( playerid, params [] ) {
	return ShowStaffCategoryCommands(playerid);
}

CMD:helperhelp ( playerid, params [] ) {
	return ShowStaffCategoryCommands(playerid);
}

// /checkcd - shows your active cooldowns.
CMD:checkcd(playerid, params[])
{
    new cdstr[12];

    SendClientMessage(playerid, 0x297183FF, "[ ___________ Player Cooldowns ___________ ]");

    FormatCooldownTime(max(0, Character[playerid][E_CHARACTER_SPRAYTAG_DYN_CD] - gettime()), cdstr, sizeof(cdstr));
    SendClientMessage(playerid, 0x58DD85FF, sprintf("[Dynamic Spray]: %s", cdstr));

    FormatCooldownTime(max(0, Character[playerid][E_CHARACTER_CHOPSHOP_CD] - gettime()), cdstr, sizeof(cdstr));
    SendClientMessage(playerid, 0x58DD85FF, sprintf("[Chopshop]: %s", cdstr));

#if defined FEATURE_GANGTAGS
    FormatCooldownTime(max(0, Character[playerid][E_CHARACTER_SPRAYTAG_STATIC_CD] - gettime()), cdstr, sizeof(cdstr));
    SendClientMessage(playerid, 0x58DD85FF, sprintf("[Static Spray]: %s", cdstr));

#endif
    return 1;
}
