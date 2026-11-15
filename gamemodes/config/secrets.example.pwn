// ---------------------------------------------------------------------------
// Local configuration + secrets.
//
// Copy this file to config/secrets.pwn (gitignored) and fill it in.
// The gamemode will not compile without it.
// ---------------------------------------------------------------------------

// Password used by the built-in server-side password check (change it!).
#define SERVER_PASSWORD "change-me"

// ---- Discord (optional, disabled by default) ------------------------------
// Uncomment to compile the Discord integration in. Requires the discord-connector
// plugin and a `discord_bot_token` option in your server config.
//#define DISCORD_ENABLED
//
// To post to Discord channels or ping roles, #define the DISCORD_CHANNEL_* and
// DISCORD_ROLE_* values here (the list of names is in discord/header.pwn).
// Any channel left undefined is simply skipped.
