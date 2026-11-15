// ============================================================================
// File: visuals/models.pwn
// Registers the UI sprite sheets the core systems need (licence cards, phone, gym HUD) and
// documents how to register your own custom models with AddSimpleModel / AddCharModel.
// ============================================================================

// ---------------------------------------------------------------------------
// UI sprite sheets (shipped in /models)
//
// Textdraws can show an image from a .txd with the string "mdl-<model id>:<sprite name>".
// Each sheet below is registered under a negative model id, which is the number used in
// those strings. Example: "mdl-23992:id" draws the sprite called "id" from license.txd.
//
// Don't change these ids unless you also change every "mdl-..." string that uses them.
//
//   -23992  license.txd      licence cards and badges (licenses/gui.pwn)
//   -24995  phone.txd        phone frame, wallpapers and icons (phone/gui/)
//   -24994  phone_nice.txd   phone message / bell icons (phone/gui/)
//   -22586  gymbar.txd       gym progress bar (gym/hud.pwn)
// ---------------------------------------------------------------------------
hook OnModelsPreload() {

	Models_AddUISprites();
	return 1;
}

Models_AddUISprites() {

	AddSimpleModel(-1, 1337, -23992, "sprite_model.dff", "license.txd");
	AddSimpleModel(-1, 1337, -24994, "phone.dff", "phone_nice.txd");
	AddSimpleModel(-1, 1337, -24995, "phone.dff", "phone.txd");
	AddSimpleModel(-1, 1337, -22586, "sprite_model.dff", "gymbar.txd");
}

// ---------------------------------------------------------------------------
// Your own custom models
//
// Put the .dff / .txd files in /models (they are served to players automatically, see
// "artwork" in config.json) and register them the same way:
//
//   hook OnModelsPreload() {
//       AddSimpleModel(-1, 1337, -1000, "mymodels/thing.dff", "mymodels/thing.txd");
//       return 1;
//   }
//
// Reference: https://github.com/openmultiplayer/open.mp/wiki (custom models)
// ---------------------------------------------------------------------------
