// ============================================================================
// File: admin/actors.pwn
// Admin tools for placing static NPC 'actors' (shopkeepers, bystanders) in the world:
// /actorcreate, /actormove, /actoranim, /actordelete and so on. Actors are stored in the
// `actors` table and loaded on start (LoadActors).
// Commands: /actorcreate /reloadactors /actordelete /actornear /actormove /actoranim /actorinfo
// ============================================================================

#include <a_samp>
#include <streamer>
#include <sscanf2>
#include <a_mysql>

#define MAX_SERVER_ACTORS (500)

enum actorData
{
    actor_sid,
    actor_dynamic_id,
    actor_model,

    Float:actor_pos_x,
    Float:actor_pos_y,
    Float:actor_pos_z,
    Float:actor_pos_r,

    actor_world,
    actor_interior,
    actor_invulnerable,

    actor_anim_lib[50],
    actor_anim_name[50],
    actor_anim_loop,
    actor_anim_freeze,
    actor_created_by
};

new ServerActor[MAX_SERVER_ACTORS][actorData];
new ActorCount;


/*==================================================
    LOAD ACTORS
==================================================*/

// Loads every actor from the `actors` table; the result is handled by OnActorsLoaded.
LoadActors()
{
    mysql_tquery(mysql, "SELECT * FROM actors", "OnActorsLoaded");
    return true;
}

forward OnActorsLoaded();
// MySQL callback: creates a streamer actor for each loaded row and stores it in ServerActor[].
public OnActorsLoaded()
{
    ActorCount = 0;

    if (!cache_num_rows())
    {
        printf("[ACTORS] Loaded 0 actors.");
        return true;
    }

    for (new i = 0, r = cache_num_rows(); i < r && i < MAX_SERVER_ACTORS; ++i)
    {
        cache_get_value_name_int(i, "id", ServerActor[i][actor_sid]);
        cache_get_value_name_int(i, "model", ServerActor[i][actor_model]);

        cache_get_value_name_float(i, "pos_x", ServerActor[i][actor_pos_x]);
        cache_get_value_name_float(i, "pos_y", ServerActor[i][actor_pos_y]);
        cache_get_value_name_float(i, "pos_z", ServerActor[i][actor_pos_z]);
        cache_get_value_name_float(i, "pos_r", ServerActor[i][actor_pos_r]);

        cache_get_value_name_int(i, "world", ServerActor[i][actor_world]);
        cache_get_value_name_int(i, "interior", ServerActor[i][actor_interior]);
        cache_get_value_name_int(i, "invulnerable", ServerActor[i][actor_invulnerable]);

        cache_get_value_name(i, "anim_lib", ServerActor[i][actor_anim_lib], 50);
        cache_get_value_name(i, "anim_name", ServerActor[i][actor_anim_name], 50);

        cache_get_value_name_int(i, "anim_loop", ServerActor[i][actor_anim_loop]);
        cache_get_value_name_int(i, "anim_freeze", ServerActor[i][actor_anim_freeze]);

        cache_get_value_name_int(i, "created_by", ServerActor[i][actor_created_by]);

        // Correct parameter order for streamer CreateDynamicActor:
        // invulnerable, health, worldid, interiorid
        ServerActor[i][actor_dynamic_id] = CreateDynamicActor(
            ServerActor[i][actor_model],
            ServerActor[i][actor_pos_x],
            ServerActor[i][actor_pos_y],
            ServerActor[i][actor_pos_z],
            ServerActor[i][actor_pos_r],
            (ServerActor[i][actor_invulnerable] != 0),
            100.0,
            ServerActor[i][actor_world],
            ServerActor[i][actor_interior]
        );

        if (ServerActor[i][actor_anim_lib][0] != '\0' && ServerActor[i][actor_anim_name][0] != '\0')
        {
            ApplyDynamicActorAnimation(
                ServerActor[i][actor_dynamic_id],
                ServerActor[i][actor_anim_lib],
                ServerActor[i][actor_anim_name],
                4.1,
                ServerActor[i][actor_anim_loop],
                1,
                1,
                ServerActor[i][actor_anim_freeze],
                0
            );
        }

        ActorCount++;
    }

    printf("[ACTORS] Loaded %d actors.", ActorCount);
    return true;
}


/*==================================================
    CREATE ACTOR (AUTO SAVE)
==================================================*/

// /actorcreate [skinid] - (senior admin) places a new actor at your position and saves it to the
// database.
CMD:actorcreate(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return false;

    new model;

    if (sscanf(params, "d", model))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/actorcreate [skinid]");

    if (ActorCount >= MAX_SERVER_ACTORS)
        return SendServerMessage(playerid, COLOR_ERROR, "Error", "A3A3A3", "Actor limit reached.");

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new world    = GetPlayerVirtualWorld(playerid);
    new interior = GetPlayerInterior(playerid);

    new query[512];

    mysql_format(mysql, query, sizeof(query),
        "INSERT INTO actors (model, pos_x, pos_y, pos_z, pos_r, world, interior, invulnerable, created_by) \
        VALUES (%d, %.4f, %.4f, %.4f, %.4f, %d, %d, 1, %d)",
        model, x, y, z, a, world, interior, Account[playerid][E_PLAYER_ACCOUNT_ID]
    );

    mysql_tquery(mysql, query, "OnActorCreated", "iiffffiii",
        playerid, model, x, y, z, a, world, interior, Account[playerid][E_PLAYER_ACCOUNT_ID]);

    return true;
}


/*==================================================
    RELOAD ACTORS
==================================================*/

// /reloadactors - (senior admin) destroys all actors and loads them again from the database.
CMD:reloadactors(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return false;

    for (new i = 0; i < ActorCount; i++)
    {
        if (ServerActor[i][actor_dynamic_id])
        {
            DestroyDynamicActor(ServerActor[i][actor_dynamic_id]);
        }
    }

    ActorCount = 0;

    LoadActors();

    AddLogEntry(playerid, LOG_TYPE_ADMIN, "Reloaded decorative actors.");
    SendServerMessage(playerid, COLOR_EMMET, "Actor", "A3A3A3", "Decorative actors reloaded.");

    return true;
}


/*==================================================
    DELETE ACTOR
==================================================*/

// /actordelete [dbid] - (senior admin) removes an actor from the world and the database.
CMD:actordelete(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return false;

    new id;

    if (sscanf(params, "d", id))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/actordelete [dbid]");

    new index = -1;

    for (new i = 0; i < ActorCount; i++)
    {
        if (ServerActor[i][actor_sid] == id)
        {
            index = i;
            break;
        }
    }

    if (index == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Actor", "A3A3A3", "Actor not found.");

    DestroyDynamicActor(ServerActor[index][actor_dynamic_id]);

    // Remove from memory properly
    for (new i = index; i < ActorCount - 1; i++)
    {
        ServerActor[i] = ServerActor[i + 1];
    }

    ActorCount--;

    new query[128];
    mysql_format(mysql, query, sizeof(query),
        "DELETE FROM actors WHERE id = %d",
        id
    );

    mysql_tquery(mysql, query);

    format(query, sizeof(query), "Deleted decorative actor ID %d.", id);
    AddLogEntry(playerid, LOG_TYPE_ADMIN, query);

    SendServerMessage(playerid, COLOR_EMMET, "Actor", "A3A3A3", "Actor deleted permanently.");

    return true;
}


/*==================================================
    NEAREST ACTOR (SAME WORLD/INTERIOR)
==================================================*/

// /actornear - (senior admin) lists actors close to you in your world and interior.
CMD:actornear(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return false;

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new playerWorld    = GetPlayerVirtualWorld(playerid);
    new playerInterior = GetPlayerInterior(playerid);

    new closestIndex = -1;
    new Float:closestDist = 30.0;

    for (new i = 0; i < ActorCount; i++)
    {
        if (!ServerActor[i][actor_dynamic_id])
            continue;

        if (ServerActor[i][actor_world] != playerWorld)
            continue;

        if (ServerActor[i][actor_interior] != playerInterior)
            continue;

        new Float:dist = floatsqroot(
            floatpower(ServerActor[i][actor_pos_x] - px, 2.0) +
            floatpower(ServerActor[i][actor_pos_y] - py, 2.0) +
            floatpower(ServerActor[i][actor_pos_z] - pz, 2.0)
        );

        if (dist <= closestDist)
        {
            closestDist = dist;
            closestIndex = i;
        }
    }

    if (closestIndex == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Actor", "A3A3A3", "No actor within 30.0 units (same world/interior).");

    new msg[144];
    format(msg, sizeof(msg), "Nearest Actor SQL ID: %d | Distance: %.2f | VW: %d | Int: %d",
        ServerActor[closestIndex][actor_sid],
        closestDist,
        ServerActor[closestIndex][actor_world],
        ServerActor[closestIndex][actor_interior]
    );

    SendServerMessage(playerid, COLOR_EMMET, "Actor", "A3A3A3", msg);

    return true;
}


/*==================================================
    MOVE ACTOR
==================================================*/

// /actormove [dbid] - (senior admin) moves an existing actor to your current position.
CMD:actormove(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return false;

    new id;

    if (sscanf(params, "d", id))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/actormove [dbid]");

    new index = -1;

    for (new i = 0; i < ActorCount; i++)
    {
        if (ServerActor[i][actor_sid] == id)
        {
            index = i;
            break;
        }
    }

    if (index == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Actor", "A3A3A3", "Actor not found.");

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    SetDynamicActorPos(ServerActor[index][actor_dynamic_id], x, y, z);
    SetDynamicActorFacingAngle(ServerActor[index][actor_dynamic_id], a);

    ServerActor[index][actor_pos_x] = x;
    ServerActor[index][actor_pos_y] = y;
    ServerActor[index][actor_pos_z] = z;
    ServerActor[index][actor_pos_r] = a;

    new query[256];

    mysql_format(mysql, query, sizeof(query),
        "UPDATE actors SET pos_x = %.4f, pos_y = %.4f, pos_z = %.4f, pos_r = %.4f WHERE id = %d",
        x, y, z, a, id
    );

    mysql_tquery(mysql, query);

    SendServerMessage(playerid, COLOR_EMMET, "Actor", "A3A3A3", "Actor moved and updated.");

    return true;
}


/*==================================================
    ACTOR ANIMATION
==================================================*/

// /actoranim [dbid] [lib] [name] (loop) (freeze) - (senior admin) gives an actor an animation, or
// clears it with 'none none'.
CMD:actoranim(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return false;

    new id;
    new animlib[50];
    new animname[50];
    new loop = 1;
    new freeze = 0;

    if (sscanf(params, "ds[50]s[50]II", id, animlib, animname, loop, freeze))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3",
            "/actoranim [dbid] [lib] [name] (loop 0/1) (freeze 0/1)\nUse 'none none' to clear animation.");

    new index = -1;

    for (new i = 0; i < ActorCount; i++)
    {
        if (ServerActor[i][actor_sid] == id)
        {
            index = i;
            break;
        }
    }

    if (index == -1)
        return SendServerMessage(playerid, COLOR_ERROR, "Actor", "A3A3A3", "Actor not found.");

    // CLEAR ANIMATION
    if (!strcmp(animlib, "none", true) && !strcmp(animname, "none", true))
    {
        ClearDynamicActorAnimations(ServerActor[index][actor_dynamic_id]);

        ServerActor[index][actor_anim_lib][0]  = '\0';
        ServerActor[index][actor_anim_name][0] = '\0';
        ServerActor[index][actor_anim_loop]    = 0;
        ServerActor[index][actor_anim_freeze]  = 0;

        new query[256];
        mysql_format(mysql, query, sizeof(query),
            "UPDATE actors SET anim_lib = '', anim_name = '', anim_loop = 0, anim_freeze = 0 WHERE id = %d",
            id
        );

        mysql_tquery(mysql, query);

        SendServerMessage(playerid, COLOR_EMMET, "Actor", "A3A3A3", "Animation cleared.");
        return true;
    }

    // APPLY ANIMATION
    format(ServerActor[index][actor_anim_lib], 50, "%s", animlib);
    format(ServerActor[index][actor_anim_name], 50, "%s", animname);
    ServerActor[index][actor_anim_loop]   = loop;
    ServerActor[index][actor_anim_freeze] = freeze;

    ApplyDynamicActorAnimation(
        ServerActor[index][actor_dynamic_id],
        animlib,
        animname,
        4.1,
        loop,
        1,
        1,
        freeze,
        0
    );

    new query[256];
    mysql_format(mysql, query, sizeof(query),
        "UPDATE actors SET anim_lib = '%e', anim_name = '%e', anim_loop = %d, anim_freeze = %d WHERE id = %d",
        animlib, animname, loop, freeze, id
    );

    mysql_tquery(mysql, query);

    SendServerMessage(playerid, COLOR_EMMET, "Actor", "A3A3A3", "Animation applied and saved.");

    return true;
}

// /actorinfo [dbid] - (senior admin) shows the details stored for an actor.
CMD:actorinfo(playerid, params[])
{
    if (GetPlayerAdminLevel(playerid) < ADMIN_LVL_SENIOR)
        return false;

    new id;

    if (sscanf(params, "d", id))
        return SendServerMessage(playerid, COLOR_ERROR, "Syntax", "A3A3A3", "/actorinfo [dbid]");

    new query[256];

    mysql_format(mysql, query, sizeof(query),
        "SELECT a.id, a.model, a.pos_x, a.pos_y, a.pos_z, a.pos_r, \
        a.world, a.interior, a.invulnerable, a.created_by, \
        acc.account_name AS creator_name \
        FROM actors a \
        LEFT JOIN accounts acc ON acc.account_id = a.created_by \
        WHERE a.id = %d LIMIT 1",
        id
    );

    mysql_tquery(mysql, query, "OnActorInfo", "ii", playerid, id);

    return true;
}


/*==================================================
    INSERT CALLBACK
==================================================*/

forward OnActorCreated(playerid, model, Float:x, Float:y, Float:z, Float:a, world, interior, created_by);
// MySQL callback after /actorcreate: records the new database id and creates the actor in the
// world.
public OnActorCreated(playerid, model, Float:x, Float:y, Float:z, Float:a, world, interior, created_by)
{
    new dbid = cache_insert_id();

    if (ActorCount >= MAX_SERVER_ACTORS)
        return 1;

    // Correct parameter order for streamer CreateDynamicActor
    new actorid = CreateDynamicActor(
        model,
        x,
        y,
        z,
        a,
        true,
        100.0,
        world,
        interior
    );

    ServerActor[ActorCount][actor_sid]          = dbid;
    ServerActor[ActorCount][actor_dynamic_id]   = actorid;
    ServerActor[ActorCount][actor_model]        = model;
    ServerActor[ActorCount][actor_pos_x]        = x;
    ServerActor[ActorCount][actor_pos_y]        = y;
    ServerActor[ActorCount][actor_pos_z]        = z;
    ServerActor[ActorCount][actor_pos_r]        = a;
    ServerActor[ActorCount][actor_world]        = world;
    ServerActor[ActorCount][actor_interior]     = interior;
    ServerActor[ActorCount][actor_invulnerable] = 1;

    ServerActor[ActorCount][actor_anim_lib][0]  = '\0';
    ServerActor[ActorCount][actor_anim_name][0] = '\0';
    ServerActor[ActorCount][actor_anim_loop]    = 0;
    ServerActor[ActorCount][actor_anim_freeze]  = 0;

    ServerActor[ActorCount][actor_created_by] = created_by;

    ActorCount++;

    new msg[128];
    format(msg, sizeof(msg), "Actor created. SQL ID: %d | VW: %d | Int: %d", dbid, world, interior);
    SendServerMessage(playerid, COLOR_EMMET, "Actor", "A3A3A3", msg);

    return 1;
}

forward OnActorInfo(playerid, actorid);
// MySQL callback for /actorinfo: prints the actor's stored details to the admin.
public OnActorInfo(playerid, actorid)
{
    if (!cache_num_rows())
        return SendServerMessage(playerid, COLOR_ERROR, "Actor", "A3A3A3", "Actor not found.");

    new model, world, interior, invul, created_by;
    new Float:x, Float:y, Float:z, Float:r;
    new creator_name[24];

    cache_get_value_name_int(0, "model", model);
    cache_get_value_name_float(0, "pos_x", x);
    cache_get_value_name_float(0, "pos_y", y);
    cache_get_value_name_float(0, "pos_z", z);
    cache_get_value_name_float(0, "pos_r", r);

    cache_get_value_name_int(0, "world", world);
    cache_get_value_name_int(0, "interior", interior);
    cache_get_value_name_int(0, "invulnerable", invul);
    cache_get_value_name_int(0, "created_by", created_by);

    cache_get_value_name(0, "creator_name", creator_name, sizeof(creator_name));

    new msg[144];

    format(msg, sizeof(msg),
        "Actor ID: %d | Model: %d | VW: %d | Int: %d",
        actorid, model, world, interior);
    SendServerMessage(playerid, COLOR_EMMET, "Actor Info", "A3A3A3", msg);

    format(msg, sizeof(msg),
        "Position: %.2f %.2f %.2f | Facing: %.2f | Invul: %d",
        x, y, z, r, invul);
    SendServerMessage(playerid, COLOR_EMMET, "Actor Info", "A3A3A3", msg);

    if (creator_name[0] != '\0')
    {
        format(msg, sizeof(msg),
            "Created By: %s (Account ID: %d)",
            creator_name, created_by);
    }
    else
    {
        format(msg, sizeof(msg),
            "Created By: Unknown (Account ID: %d)",
            created_by);
    }

    SendServerMessage(playerid, COLOR_EMMET, "Actor Info", "A3A3A3", msg);

    return 1;
}
