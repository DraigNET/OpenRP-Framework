// ============================================================================
// File: config/utils/forwards.pwn
// Forward declarations for functions that are used before the file that defines them is
// included (health, armour and weapon damage calculation).
// ============================================================================


forward Float: GetCharacterHealth ( playerid ) ;
forward Float: GetCharacterArmour ( playerid )  ;

forward Float: CalculateWeaponDamage(playerid, issuerid, weaponid, bodypart) ;