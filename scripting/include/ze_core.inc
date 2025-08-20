#if defined _zombie_escape_included
	#endinput
#endif
#define _zombie_escape_included

#include <ini_file>
#include <ze_stocks>
#include <ze_core_const>

#include <ze_gamemodes>
#include <ze_weapons_menu>
#include <ze_class_nemesis>
#include <ze_items_manager>
#include <ze_weap_models_api>

/**
 * -=| Forwards |=-
 */

/**
 * Called every new round. (Before Zombie Escape starts).
 *
 * @return     ZE_STOP     | Prevent start the game.
 *             ZE_CONTINUE | Continue start the game.
 */
forward ze_game_started_pre();

/**
 * Called every new round. (After Zombie Escape started)
 *
 * @noreturn
 */
forward ze_game_started();

/**
 * Called before humanization event. It called whenever ze_set_user_human(param1) native used.
 *
 * @param id   Client index.
 *
 * @return     ZE_STOP     | Prevent humanization event.
 *             ZE_CONTINUE | Continue humanization event.
 */
forward ze_user_humanized_pre(id);

/**
 * Called after humanization event. It called whenever ze_set_user_human(param1) native used.
 *
 * @note This forward doesn't called, If pre-forward is return ZE_STOP.
 *
 * @param id   Client index.
 *
 * @noreturn
 */
forward ze_user_humanized(id);

/**
 * Called before infection event. It called whenever ze_set_user_zombie(param1, param2) native used.
 *
 * @param iVictim     Victim index.
 * @param iInfector   Attacker index. (0 = SERVER)
 * @param flDamage    Damage taken.
 *
 * @return            ZE_BREAK    | Prevent infection event (No Damage)
 *                    ZE_STOP     | Prevent infection event (Keep damage taken).
 *                    ZE_CONTINUE | Continue infection event.
 */
forward ze_user_infected_pre(iVictim, iInfector, Float:flDamage);

/**
 * Called after infection event. It called whenever ze_set_user_zombie(param1, param2) native used.
 *
 * @note This forward doesn't called, If pre-forward is return ZE_STOP or ZE_BREAK.
 *
 * @param iVictim     Victim index.
 * @param iInfector   Attacker index. (0 = SERVER)
 *
 * @noreturn
 */
forward ze_user_infected(iVictim, iInfector);

/**
 * Called after infection event. It called whenever ze_set_user_zombie(param1, param2) native used.
 *
 * @note This forward doesn't called, If pre-forward is return ZE_STOP or ZE_BREAK.
 *
 * @param iVictim     Victim index.
 * @param iInfector   Attacker index. (0 = SERVER)
 * @param iHeadshot   1 = Headshot | 0 = Otherwise.
 *
 * @noreturn
 */
forward ze_user_infected_ex(iVictim, iInfector, bHeadshot);

/**
 * Called after player spawn.
 *
 * @param id       Client index.
 *
 * @noreturn
 */
forward ze_user_spawn_post(id);

/**
 * Called after player killed.
 *
 * @param iVictim    Victim index.
 * @param iAttacker  Attacker index.
 * @param iGibs      Gibs (GIB_* enum).
 *
 * @noreturn
 */
forward ze_user_killed_post(iVictim, iAttacker, iGibs);

/**
 * Called when the last Human remains (one Human)
 *
 * @param id     Client index.
 *
 * @noreturn
 */
forward ze_user_last_human(id);

/**
 * Called when the last Zombie remains (one Zombie)
 *
 * @param id     Client index.
 *
 * @noreturn
 */
forward ze_user_last_zombie(id);

/**
 * Called when a client (player) is authorized.
 *
 * @note If the client is not authorized, this forward will still be called,
 *       but the authid may not be valid.
 *
 * @param id            Client index.
 * @param authid[]      Authentication ID (e.g., STEAMID/VALVEID).
 * @param unnauthorized Client type (enum ZE_AUTH_*).
 * @param not_loaded    true = Not authorized | false = Authorized.
 * @param auth_time     Time taken to authorize (in seconds).
 *
 * @noreturn
 */
forward ze_user_authorized(id, const authid[], RClientAuth:client_type, bool:unnauthorized, Float:auth_time);

/**
 * Called when player leave the server.
 *
 * @note Can prevent check Mod rules.
 *
 * @param id    Client index.
 *
 * @return      ZE_STOP     | Prevent checking the Mod rules.
 *              ZE_CONTINUE | Continue checking the Mod rules.
 */
forward ze_user_disconnected(id);

/**
 * Called after round ended.
 *
 * @param iWinTeam   Team winner (ZE_TEAM_* enum).
 *
 * @noreturn
 */
forward ze_roundend(iWinTeam);

/**
 * Called when the player Frozen by Frost-Nade. It is also called from native.
 *
 * @param id    Client index.
 *
 * @return      ZE_STOP     | Prevent freezing the player.
 *              ZE_CONTINUE | Continue freezing the player.
 */
forward ze_frost_freeze_start(id);

/**
 * Called when unfreeze the player.
 *
 * @param id    Client index.
 *
 * @return      ZE_STOP     | Leave player Frozen.
 *              ZE_CONTINUE | Unfreeze the player.
 */
forward ze_frost_freeze_end(id);

/**
 * Called when the player Burned by Fire-Nade. It is also called from native.
 *
 * @param id    Client index.
 *
 * @return      ZE_STOP     | Prevent burning the player.
 *              ZE_CONTINUE | Continue burning the player.
 */
forward ze_fire_burn_start(id);

/**
 * Called when burn the player.
 *
 * @param id    Client index.
 *
 * @return      ZE_STOP     | Leave player Burn.
 *              ZE_CONTINUE | Turn off the Flame.
 */
forward ze_fire_burn_end(id);

/**
 * Forward for Zombie Sounds.
 *
 * @param id        Client index.
 * @param iSnd      Sound type (Enum: ZE_SND_*)
 * @param szSound[] Sound to be played (can be overwritten)
 *
 * @return          ZE_STOP     | Prevent playing Sound.
 *                  ZE_CONTINUE | Continue playing Sound.
 */
forward ze_res_fw_zombie_sound(const id, iSnd, szSound[MAX_RESOURCE_PATH_LENGTH]);

/**
 * Called when Zombies appear.
 *
 * @note This forward called when Zombies appear in Escape and Swarm mode only.
 *
 * @param iZombies[]     Clients indexes.
 * @param iZombiesNum    The number of Zombies.
 *
 * @noreturn
 */
forward ze_zombie_appear(const iZombies[], iZombiesNum);

/**
 * Called when Zombies released.
 *
 * @note This forward called when Zombies release in Escape and Swarm mode only.
 *
 * @noreturn
 */
forward ze_zombie_release();

/**
 * Called when grenade (Frost, Fire or Flare) exploded.
 *
 * @param ent        Entity index.
 * @param iGrenade   Grenade type (*_NADE enum)
 * @param vOrigin[3] Origin of the entity.
 *
 * @noreturn
 */
forward ze_grenade_exploded(ent, NadeType:iGrenade, Float:vOrigin[3]);

/**
 * Called when Victim received knockback attack from Attacker.
 *
 * @note You can also modify on taken knockback.
 *
 * @param iVictim    Victim index.
 * @param iAttacker  Attacker index.
 * @param vSpeed[3]  Knockback speed taken.
 *
 * @return           ZE_STOP     | Prevent taken knockback.
 *                   ZE_CONTINUE | Otherwise.
 */
forward ze_take_knockback(iVictim, iAttacker, Float:vSpeed[3]);

/**
 * -=| Natives |=-
 */

/**
 * Check if the player is Zombie or Not.
 *
 * @note This native also check player connected or not.
 *
 * @param id    Client index.
 *
 * @return      true  | If player is Zombie.
 *              false | If player is not Zombie.
 */
native bool:ze_is_user_zombie(id);

/**
 * Turn a player into a Human.
 *
 * @param id     Client index.
 *
 * @return       true  | If player turned into Human.
 *               false | If player not on game or native prevented from ze_user_humanized_pre().
 *
 * @error        If this player not on game.
 */
native ze_set_user_human(id);

/**
 * Turn a player into a Zombie.
 *
 * @param iVictim     Victim index.
 * @param iInfector   Infector index. (0 = SKIP [Server])
 *
 * @return       true  | If player turned into Zombie.
 *               false | If player not on game or native prevented from ze_user_infected_pre()
 *
 * @error        If this player not on game.
 */
native ze_set_user_zombie(iVictim, iInfector = 0);

/**
 * Check If player is Human.
 *
 * @return       Client index of last Human, 0 If there is no last Human.
 */
native ze_is_last_human();

/**
 * Check If player is Zombie.
 *
 * @return      Client index of last Zombie. 0 If there is no last Zombie.
 */
native ze_is_last_zombie();

/**
 * Force turn a player into a Human.
 *
 * @param id     Client index.
 *
 * @return       true  | If player turned into Human.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_force_set_user_human(id);

/**
 * Force turn a player into a Zombie.
 *
 * @param iVictim    Victim index.
 * @param iAttacker  Attacker index. (0 = Server)
 *
 * @return       true  | If player turned into Zombie.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_force_set_user_zombie(iVictim, iAttacker = 0);

/**
 * Sets player maxspeed.
 *
 * @param id       Client index.
 * @param flSpeed  Speed to be set.
 * @param bFactor  true = Increase in maxspeed of the player (Weapon Speed + Value)
 *                 false = Set player new maxspeed.
 *
 * @return       true  | If changed successfully.
 *               false | If player not game.
 *
 * @error        If this player not on game.
 */
native ze_set_user_speed(id, Float:flSpeed, bool:bFactor = false);

/**
 * Reset player maxspeed.
 *
 * @param id     Client index.
 *
 * @return       true  | If reset successfully.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_reset_user_speed(id);

/**
 * Sets custom knockback speed for specific player.
 *
 * @param id     Client index
 *
 * @return       true  | If assigned successfully.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_set_zombie_knockback(id, Float:flSpeed);

/**
 * Gets knockback speed for specific player.
 *
 * @param id     Client index.
 *
 * @return       Speed  | If player id is valid.
 *               -1.0   | If player not on game.
 *
 * @error        If this player not on game.
 */
native Float:ze_get_zombie_knockback(id);

/**
 * Sets or Adds number of Point(s) for specific player.
 *
 * @param id     Client index.
 * @param iFrags Number of Frags.
 * @param bAdd   true = Add | false = Set.
 *
 * @return       true  | If operation successfully.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_add_user_frags(id, iFrags, bool:bAdd = true);

/**
 * Sets or Adds number of Death(s) for specific player.
 *
 * @param id      Client index.
 * @param iDeaths Number of Deaths.
 * @param bAdd    true = Add | false = Set.
 *
 * @return        true  | If operation successfully.
 *                false | If player not on game.
 *
 * @error         If this player not on game.
 */
native ze_add_user_deaths(id, iDeaths, bool:bAdd = true);

/**
 * @deprecated This function does not catch all cases.
 */
#pragma deprecated Use ze_res_ambx_register() instead.
native ze_res_ambience_register(const szName[], const szSound[], iLength);

/**
 * @deprecated This function does not catch all cases.
 */
#pragma deprecated Use ze_res_ambx_play() instead.
native ze_res_ambience_play(const iHandle, bool:bLoop = true);

/**
 * Registers ambience sounds for a specific game mode.
 *
 * @note You can register multiple ambience tracks.
 * Example: ze_res_ambx_register("Escape", "amb1.mp3", 150, "amb2.mp3", 120, "amb3.mp3", 200)
 * Don't forget to include the duration (in seconds) after each sound path.
 *
 * @param szName[]   Game mode name.
 * @param szSound[]  Path to the sound file ("" = ignore).
 * @param iLength    Length of the ambience sound in seconds.
 * @param any:...    Additional ambience tracks (pairs of path and duration).
 *
 * @return           true  | If the game mode ambience was registered successfully.
 *                   false | If no name was provided or the name already exists.
 * @error            If no name or no sound path are provided or the name already exists.
 */
native ze_res_ambx_register(const szName[], const szSound[], iLength, any:...);

/**
 * Plays an ambience sound for all players.
 *
 * @param szName[]  Game mode name.
 * @param bLoop     true = Loop sound | false = Once time.
 *
 * @return          true  | If the operation was successful.
 *                  false | If no name was provided or the name does not exist.
 * @error           If no name is provided or the name does not exist.
 */
native ze_res_ambx_play(const szName[], bool:bLoop = true);

/**
 * Plays menu sounds (Sent menu sound to client).
 *
 * @param id      Client index.
 * @param iPosit  Menu sound (ZE_MENU_* enum).
 *
 * @return        2 | If CVar's disabled.
 *                1 | If cmd sent successfully.
 *                0 | If player not on game.
 *
 * @error         If this player not on game.
 */
native ze_res_menu_sound(id, MenuSounds:iPosit);

/**
 * Get number of coins for specific player.
 *
 * @param id      Client index.
 *
 * @return        Number of Coin(s) | If got successfully.
 *                NULLENT (-1)      | If player not on game.
 *
 * @error         If this player not on game.
 */
native ze_get_user_coins(id);

/**
 * Sets or Adds coins for specific player.
 *
 * @param id      Client index.
 * @param iCoins  Number of coins.
 * @param bAdd    true = Add Coin(s) | false = Sets Coin(s).
 *
 * @return        true  | If added or assigned successfully.
 *                false | If player not on game.
 *
 * @error         If this player not on game.
 */
native ze_set_user_coins(id, iCoins, bool:bAdd = false);

/**
 * Show Coins message for specific player or all clients.
 *
 * @note Maximum message length is 256 bytes.
 *
 * @param id        Client index (0 = All clients).
 * @param message[] Message to be sent.
 * @param ...       Variable number of formatting parameters.
 *
 * @return          Number of printed characters.
 * @error           If this player not on game.
 */
native ze_show_coins_message(id, const message[], any:...);

/**
 * Check If the player is Frozen or not.
 *
 * @param id   Client index.
 *
 * @return     true  | If the player is Frozen.
 *             false | Otherwise.
 *
 * @error      If this player not on game.
 */
native ze_user_in_frost(id);

/**
 * Freeze or unfreeze the player.
 *
 * @param id    Client index.
 * @param bSet  true = Freeze the player | false = Unfreeze the player.
 *
 * @return      true  | If Freeze or unfreeze successfully.
 *              false | If player not on game or player already Frozen or prevent from Forward.
 *
 * @error       If the player not on game.
 */
native ze_set_user_frost(id, bool:bSet = false);

/**
 * Freeze the player with specific period.
 *
 * @param id      Client index.
 * @param fPeriod Freeze period (0.1 = Minimum)
 *
 * @return       true  | If Freeze successfully.
 *               false | If player not on game or already Fozen or prevent from Forward.
 *
 * @error        If the player not on game.
 */
native ze_set_user_frost_ex(id, Float:flPeriod);

/**
 * Check If the player is Burning or not.
 *
 * @param id    Client index.
 *
 * @return      true  | If the player is Burning.
 *              false | Otherwise.
 *
 * @error       If this player not on game.
 */
native ze_user_in_fire(id);

/**
 * Burn or unburn the player.
 *
 * @param id    Client index.
 *
 * @return      true  | If Burned successfully.
 *              false | If player not on game or prevent from Forward.
 *
 * @error       If this player not on game.
 */
native ze_set_user_fire(id, bool:bSet = false);

/**
 * Burn or unburn the player.
 *
 * @note Unburn player, Use native: ze_set_user_fire().
 *
 * @param id       Client index.
 * @param flPeriod Flame Period (0.1 = Minimum).
 *
 * @return         true  | If Burned successfully.
 *                 false | If player not on game or prevent from Forward.
 *
 * @error          If this player not on game.
 */
native ze_set_user_fire_ex(id, Float:flPeriod);

/**
 * Add class name and set color for HUD info.
 *
 * @param id        Client index.
 * @param szClass[] Class name (Ex: "Zombie", ... etc).
 * @param iColor[3] HUD Color (Red, Green, Blue).
 * @param bMl       true  = Class name will be looked up as multilingual key.
 *
 * @return          true  | If operation successfully.
 *                  false | Error.
 *
 * @error           If this player not on game,
 *                  Translation key does not exist.
 */
native ze_hud_info_set(id, const szClass[], const iColor[3], bMl = false);

/**
 * Forces finish the round.
 *
 * @note ZE_TEAM_UNA or ZE_TEAM_SPECTATOR the round will end in a Draw.
 *
 * @param team    Team Name (enum ZE_TEAM_*)
 *
 * @return        1  | Round ended successfully.
 *                0  | Round not over yet.
 *                -1 | Error in team ID.
 * @error         Invalid team ID.
 */
native ze_round_end(team);

/**
 * Check if Zombies are frozen or not.
 *
 * @note This native check Zombies are frozen in release time.
 *
 * @return       true  | If Zombies are Frozen.
 *               false | Otherwise.
 */
native ze_is_zombie_frozen();