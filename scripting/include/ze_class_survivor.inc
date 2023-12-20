#if defined _class_survivor_included
	#endinput
#endif
#define _class_survivor_included

/**
 * Check If player is Survivor or Not.
 *
 * @param id     Client index.
 *
 * @return       true  | If player is Survivor.
 *               false | If player isn't Survivor or not on game.
 *
 * @error        If this player not on game.
 */
native ze_is_user_survivor(id);

/**
 * Turn a player to Survivor.
 *
 * @param id     Client index.
 *
 * @return       ture  | If player turned successfully.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_set_user_survivor(id);

/**
 * Remove player Survivor class.
 *
 * @param id      Client index.
 * @param bInfect true = Infect player | false = Otherwise.
 *
 * @return        true  | If Survivor class removed.
 *                false | If player not on game.
 *
 * @error         If this player not on game.
 */
native ze_remove_user_survivor(id, bool:bInfect = false);