// ============================================================================
// File: anticheat/header.pwn
// Includes every anti-cheat module (vehicle, player and miscellaneous checks) plus pause/toggle
// controls. Comment out an include here to disable that check.
// ============================================================================

#include "anticheat/toggle.pwn"
#include "anticheat/pause.pwn"
#include "anticheat/ac_detect.pwn"
#include "anticheat/modules/client_checks.pwn"
#include "anticheat/logging.pwn"

// Vehicle related
#include "anticheat/modules/car_troll.pwn"
#include "anticheat/modules/car_mods.pwn"
#include "anticheat/modules/car_respray.pwn"
#include "anticheat/modules/car_swing.pwn"
#include "anticheat/modules/car_particles.pwn"
#include "anticheat/modules/car_warp.pwn"
#include "anticheat/modules/car_jack.pwn"

// Player related
#include "anticheat/modules/airbreak.pwn"
#include "anticheat/modules/tp_hack.pwn"
#include "anticheat/modules/scrolldetect.pwn" // detects when a gun gets scroll reloaded
#include "anticheat/modules/noreload.pwn"
#include "anticheat/modules/rapidfire.pwn"
#include "anticheat/modules/health_hacks.pwn"
#include "anticheat/modules/fakekill.pwn"
#include "anticheat/modules/doubleconnect.pwn"
#include "anticheat/modules/money.pwn"
#include "anticheat/modules/afking.pwn"
#include "anticheat/modules/spectate.pwn"
#include "anticheat/modules/bunnyhop.pwn"
#include "anticheat/modules/vpn.pwn"
#include "anticheat/modules/cbug.pwn" // 



// Miscalleneous
#include "anticheat/modules/dialogs.pwn"
#include "anticheat/modules/anti_bot.pwn"