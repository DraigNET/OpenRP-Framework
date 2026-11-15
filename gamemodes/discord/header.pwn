// ============================================================================
// File: discord/header.pwn
// Discord integration (optional, off by default). Provides the DCC_Send* functions the rest of
// the script calls; enable it in config/secrets.pwn.
// ============================================================================

#include <a_samp>
// ---------------------------------------------------------------------------------------------
// Discord integration (optional).
//
// Disabled by default: every DCC_Send* wrapper below is an empty stub, so the
// discord-connector plugin is not required. To turn it on:
//   1. add "discord-connector" to the plugin list (config.json / server.cfg) and set the
//      discord_bot_token option,
//   2. uncomment `#define DISCORD_ENABLED` in config/secrets.pwn,
//   3. define the channel / role values you want to use in config/secrets.pwn
//      (see config/secrets.example.pwn). Any channel left empty is simply skipped.
// ---------------------------------------------------------------------------------------------

#if !defined DISCORD_CHANNEL_ADVERTS
	#define DISCORD_CHANNEL_ADVERTS ""
#endif
#if !defined DISCORD_CHANNEL_BREAKING
	#define DISCORD_CHANNEL_BREAKING ""
#endif
#if !defined DISCORD_CHANNEL_ADMINLOG
	#define DISCORD_CHANNEL_ADMINLOG ""
#endif
#if !defined DISCORD_CHANNEL_ANTICHEAT
	#define DISCORD_CHANNEL_ANTICHEAT ""
#endif
#if !defined DISCORD_CHANNEL_CHARITY
	#define DISCORD_CHANNEL_CHARITY ""
#endif
#if !defined DISCORD_CHANNEL_PUNISHMENTS
	#define DISCORD_CHANNEL_PUNISHMENTS ""
#endif
#if !defined DISCORD_CHANNEL_911_POLICE
	#define DISCORD_CHANNEL_911_POLICE ""
#endif
#if !defined DISCORD_CHANNEL_911_FIRE
	#define DISCORD_CHANNEL_911_FIRE ""
#endif
#if !defined DISCORD_CHANNEL_MDC_PAGER
	#define DISCORD_CHANNEL_MDC_PAGER ""
#endif

// Optional role IDs pinged by /pager (police MDC). Leave empty to not ping anyone.
#if !defined DISCORD_ROLE_LINE_STAFF
	#define DISCORD_ROLE_LINE_STAFF ""
#endif
#if !defined DISCORD_ROLE_SUPERVISORY
	#define DISCORD_ROLE_SUPERVISORY ""
#endif
#if !defined DISCORD_ROLE_COMMAND
	#define DISCORD_ROLE_COMMAND ""
#endif

#if defined DISCORD_ENABLED
#include <discord-connector>

#define DISCORD_COMMAND_PREFIX '-'

#include "discord/players.pwn"

// Posts an embed to a channel. Skipped on the test server or when the channel isn't configured.
static DCC_PostEmbed(const channel_id[], const title[], const msg[], color) {

	if (TEST_SERVER != 0 || !strlen(channel_id)) return false;

	new DCC_Channel:channel = DCC_FindChannelById(channel_id);
	if (channel == DCC_INVALID_CHANNEL) return false;

	new DCC_Embed:embed = DCC_CreateEmbed(title, msg, "", "", color, " ", "", "", "");
	DCC_SendChannelEmbedMessage(channel, embed);
	return true;
}

// Posts a /ad, /badvert or connection message to the adverts channel.
DCC_SendAdvertisementMessage(type, const msg[]) {

	switch (type) {
		case 0:  DCC_PostEmbed(DISCORD_CHANNEL_ADVERTS, "Advertisement", msg, 0x3dfc03); // /ad
		case 1:  DCC_PostEmbed(DISCORD_CHANNEL_ADVERTS, "Business",      msg, 0x03a5fc); // /badvert
		default: DCC_PostEmbed(DISCORD_CHANNEL_ADVERTS, "Connection",    msg, 0x03a5fc); // player connections
	}
	return true;
}

// Posts a breaking-news message to its Discord channel.
DCC_SendBreakingMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_BREAKING, "Breaking News", msg, 0xff2a00);
}

// Posts a staff action to the admin log channel.
DCC_SendAdminLogMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_ADMINLOG, "Admin Log", msg, 0xfce703);
}

// Posts an anti-cheat alert to its Discord channel.
DCC_SendAntiCheatMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_ANTICHEAT, "Anti-Cheat Log", msg, 0xFFAB00);
}

// Posts a charity donation to its Discord channel.
DCC_SendCharityLogMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_CHARITY, "Charity Log", msg, 0xfce703);
}

// Posts a punishment (ban, jail, kick) to its Discord channel.
DCC_SendAdminPunishmentMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_PUNISHMENTS, "Admin Log", msg, 0xfce703);
}

// 9-1-1 forwards. Police calls go to the police channel, medical calls to the fire channel.
DCC_Send911PoliceMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_911_POLICE, "9-1-1 Emergency", msg, 0x2c51c9);
}

// Forwards a medical 911 call to the fire/EMS channel.
DCC_Send911MedicMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_911_FIRE, "9-1-1 Emergency", msg, 0xff2121);
}

// Forwards a robbery alert to the police channel.
DCC_Send911RobberyMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_911_POLICE, "9-1-1 Emergency", msg, 0x9933ff);
}

// Forwards a burglary alarm to the police channel.
DCC_SendBurglaryAlertMessage(const msg[]) {
	return DCC_PostEmbed(DISCORD_CHANNEL_911_POLICE, "Burglary Alarm", msg, 0x49ba47);
}

// Police MDC pager: posts the embed and pings up to three roles.
DCC_SendPoliceMDCMessage(const msg[], const role1[], const role2[], const role3[]) {

	if (TEST_SERVER != 0 || !strlen(DISCORD_CHANNEL_MDC_PAGER)) return false;

	new DCC_Channel:channel = DCC_FindChannelById(DISCORD_CHANNEL_MDC_PAGER);
	if (channel == DCC_INVALID_CHANNEL) return false;

	new content[256];
	if (strlen(role1)) format(content, sizeof(content), "<@&%s> ", role1);
	if (strlen(role2)) format(content, sizeof(content), "%s<@&%s> ", content, role2);
	if (strlen(role3)) format(content, sizeof(content), "%s<@&%s>", content, role3);
	if (strlen(content)) DCC_SendChannelMessage(channel, content); // this is what triggers the pings

	DCC_PostEmbed(DISCORD_CHANNEL_MDC_PAGER, "Pager Request", msg, 0x2c51c9);
	return true;
}

#else

// Stub used when Discord is disabled: does nothing.
DCC_SendAdvertisementMessage(type, const msg[]) {
	#pragma unused type, msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_SendBreakingMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_SendAdminLogMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_SendAntiCheatMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_SendCharityLogMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_SendAdminPunishmentMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_Send911PoliceMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_Send911MedicMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_Send911RobberyMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_SendBurglaryAlertMessage(const msg[]) {
	#pragma unused msg
	return true;
}
// Stub used when Discord is disabled: does nothing.
DCC_SendPoliceMDCMessage(const msg[], const role1[], const role2[], const role3[]) {
	#pragma unused msg, role1, role2, role3
	return true;
}

#endif
