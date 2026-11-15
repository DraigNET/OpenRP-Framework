// ============================================================================
// File: gangzones/drugnpc/defines.pwn
// Constants for the drug NPC system: demand amounts per drug and price ranges per gram.
// ============================================================================

#define MAX_JUNKIE_LOCATIONS        200    
#define MAX_ACTIVE_JUNKIES          200     
#define INVALID_JUNKIE_LOC          -1
#define INVALID_JUNKIE_SLOT         -1

#define JUNKIE_INTERACT_KEY         KEY_YES
#define JUNKIE_INTERACT_HINT_TIME   4000    
#define JUNKIE_MSG_DISPLAY_TIME     6000   
#define JUNKIE_MSG_COOLDOWN         30      

#define JUNKIE_DESPAWN_TIME         1800    // 30 min  - no-sale auto-despawn
#define JUNKIE_NO_SALE_COOLDOWN     1800    // 30 min  - post-no-sale location cooldown
#define JUNKIE_COOLDOWN_TIME        2700    // 45 min  - post-sale location cooldown
#define JUNKIE_CHECK_INTERVAL       30   // 30 s    - periodic tick interval

enum E_JUNKIE_LOCATION {
    E_JLOC_SQLID,
    Float:  E_JLOC_X,
    Float:  E_JLOC_Y,
    Float:  E_JLOC_Z,
    Float:  E_JLOC_A,
    E_JLOC_ZONE,                // gangzone enum index at time of creation
    E_JLOC_FACTION,             // faction sqlid at time of creation
    E_JLOC_SKIN,                // forced skin ID; -1 = pick randomly from JunkieSkinPool
    E_JLOC_ACTIVE_JUNKIE,       // slot in JunkieActor[], INVALID_JUNKIE_SLOT = none
    E_JLOC_COOLDOWN_UNTIL,      // gettime() timestamp; 0 = ready to spawn
    E_JLOC_VIRTUALWORLD,        // virtual world
    E_JLOC_INTERIOR,            // interior ID
    bool: E_JLOC_CREATED
};

enum E_JUNKIE_ACTOR {

    E_JUNKIE_ACTOR_ID,          
    E_JUNKIE_AREA_ID,           // Streamer dynamic sphere (3 m radius)
    E_JUNKIE_LOC_SLOT,          // parent E_JUNKIE_LOCATION index
    E_JUNKIE_SKIN,
    E_JUNKIE_SPAWN_TIME,        // gettime() at spawn (drives 20-min timer)
    bool: E_JUNKIE_HAD_SALE,    // true once >=1 successful sale has occurred

    // demands (grams); 0 = drug not requested
    E_JUNKIE_WEED_DEMAND,
    E_JUNKIE_CRACK_DEMAND,
    E_JUNKIE_COCAINE_DEMAND,
    // prices per gram
    E_JUNKIE_WEED_PRICE,
    E_JUNKIE_CRACK_PRICE,
    E_JUNKIE_COCAINE_PRICE,
    bool: E_JUNKIE_CREATED
};

#if defined FEATURE_GANGZONES
new JunkieLocation[MAX_JUNKIE_LOCATIONS][E_JUNKIE_LOCATION];
#endif
#if defined FEATURE_GANGZONES
new JunkieActor[MAX_ACTIVE_JUNKIES][E_JUNKIE_ACTOR];
#endif
#if defined FEATURE_GANGZONES
new JunkieCheckTimer = -1;
#endif

#if defined FEATURE_GANGZONES
new JunkieSkinPool[] = { 105, 106, 114, 116, 123, 185, 186 };
#endif

#if defined FEATURE_GANGZONES
new PlayerLastJunkieMsg[MAX_PLAYERS];
#endif

#define MAX_DEALER_NPC_SLOTS    2

#define MAX_DRUG_DEALERS            100
#define MAX_STREET_BOSS_NPCS        50
#define INVALID_DRUG_DEALER_ID      -1
#define INVALID_AREA_ID             -1

#define DEALER_RANK_STREET          0
#define DEALER_RANK_CORNER_BOSS     1
#define DEALER_RANK_STREET_BOSS     2
#define DEALER_RANK_SUPPLIER        3

#define SALES_REQUIRED_CORNER_BOSS  100
#define SALES_REQUIRED_STREET_BOSS  200
#define SALES_REQUIRED_SUPPLIER     300

#define JUNKIE_PLAYER_COOLDOWN_TIME     900


enum E_STREET_BOSS_NPC_DATA {
    E_STREET_NPC_ID,
    E_STREET_NPC_SQLID,
    E_STREET_NPC_OWNER,
    E_STREET_NPC_OWNER_NAME[MAX_PLAYER_NAME],
    Float: E_STREET_NPC_X,
    Float: E_STREET_NPC_Y,
    Float: E_STREET_NPC_Z,
    Float: E_STREET_NPC_A,
    E_STREET_NPC_SKIN,
    E_STREET_NPC_AREA,
    E_STREET_NPC_CREATED,
    E_STREET_NPC_CREATION_TIME,
    E_STREET_NPC_WEED_PRICE,
    E_STREET_NPC_CRACK_PRICE,
    E_STREET_NPC_COCAINE_PRICE,
    E_STREET_NPC_EARNINGS,
    E_STREET_NPC_TOTAL_SALES,
    E_STREET_NPC_VIRTUALWORLD,  
    E_STREET_NPC_INTERIOR,      
    bool: E_STREET_NPC_SEIZED,  // true = currently seized by police
    E_STREET_NPC_SEIZED_BY,     // character_id of the officer who seized it
    DynamicText3D: E_STREET_NPC_LABEL
};

#if defined FEATURE_GANGZONES
new StreetBossNPC[MAX_STREET_BOSS_NPCS][E_STREET_BOSS_NPC_DATA];
#endif

#define MAX_NPC_STOCK_ENTRIES 20

enum E_NPC_STOCK_DATA {
    E_STOCK_DRUG_TYPE,
    E_STOCK_TIER,
    Float: E_STOCK_AMOUNT,
    E_STOCK_PRICE,
    E_STOCK_SQLID
};

#if defined FEATURE_GANGZONES
new NPCStock[MAX_STREET_BOSS_NPCS][MAX_NPC_STOCK_ENTRIES][E_NPC_STOCK_DATA];
#endif

enum E_PLAYER_DRUG_DEALER_DATA {
    bool: E_PLAYER_IS_DRUG_DEALER,
    E_PLAYER_DRUG_DEALER_RANK,
    E_PLAYER_DRUG_SALES_TODAY,
    E_PLAYER_DRUG_TOTAL_SALES,
    E_PLAYER_LAST_SALE_TIME,
    E_PLAYER_STREET_NPC_SLOT,
    E_PLAYER_STREET_NPC_SLOT2,
    E_PLAYER_JUNKIE_COOLDOWN_UNTIL,         
    bool: E_PLAYER_JUNKIE_PENDING_SALE      
};

new PlayerDrugDealer[MAX_PLAYERS][E_PLAYER_DRUG_DEALER_DATA];
