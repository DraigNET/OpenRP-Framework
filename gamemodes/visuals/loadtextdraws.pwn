// ============================================================================
// File: visuals/loadtextdraws.pwn
// Creates and destroys every global and player textdraw in one place (OnLoadTextdraws,
// OnLoadPlayerTextdraws, OnDestroyPlayerTextdraws).
// ============================================================================

OnLoadTextdraws()
{
	LoadFaderTextdraw () ;
	TutorialGUI_CreateStatic();
	ClassBrowser_LoadStaticDraws(); 
	mBrowser_LoadStaticDraws();
	GUI_LoadLockpickGUI();
	GUI_LoadHotwireGUI();

}

OnLoadPlayerTextdraws(playerid) {

	mBrowser_LoadPlayerDraws(playerid);
	TutorialGUI_CreatePlayer(playerid);

	GUI_LoadLockpickPlayerGUI(playerid);
	GUI_LoadHotwirePlayerGUI(playerid);

	LoadMinigameHelpBox(playerid) ;

	GUI_LoadSpectatorPanel(playerid)  ;
	//GUI_LoadDirectionLabels(playerid) ;

	//Vehicle_LoadPlayerGUI(playerid) ;

	ClassBrowser_LoadPlayerDraws(playerid); 
}

OnDestroyPlayerTextdraws(playerid) {

	TutorialGUI_DestroyPlayer(playerid);
	mBrowser_DestroyPlayerDraws(playerid);

	GUI_DestroyLockpickPlayerGUI(playerid) ;
	GUI_DestroyHotwirePlayerGUI(playerid) ;

	DestroyMinigameHelpBox ( playerid ) ;

	GUI_DestroySpectatorPanel ( playerid ) ;
	//GUI_DestroyDirectionLabels(playerid) ;

	//Vehicle_DestroyPlayerOldGUI(playerid) ;	
	ClassBrowser_DestroyPlayerDraws(playerid) ;	

	TextDrawHideForPlayer(playerid, gBlindfoldTD);
	TextDrawHideForPlayer(playerid, E_ADMIN_DUTY_TEXT );
}