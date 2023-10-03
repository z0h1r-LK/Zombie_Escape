#if defined _zombie_escape_included
	#endinput
#endif
#define _zombie_escape_included

#include <ze_stocks>
#include <ze_core_const>

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
 * @param iVictim     Victim index.
 * @param iInfector   Attacker index. (0 = SERVER)
 *
 * @noreturn
 */
forward ze_user_infected(iVictim, iInfector);

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