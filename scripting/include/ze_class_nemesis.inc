#if defined _class_nemesis_included
	#endinput
#endif
#define _class_nemesis_included

/**
 * Check if player is Nemesis or not.
 *
 * @param id     Client index.
 *
 * @return       true  | If player is Nemesis.
 *               false | If player isn't Nemesis or not on game.
 */
native bool:ze_is_user_nemesis(id);

/**
 * Turn a player into a Nemesis.
 *
 * @param id     Client index.
 *
 * @return       true  | If player turn into Nemesis.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_set_user_nemesis(id);

/**
 * Remove player Nemesis Flag then turn him to a Zombie or Human.
 *
 * @param id     Client index.
 * @param bHuman true = Turn a player to a Human | false = Turn a player to a Zombie.
 *
 * @return       true  | If turned into Zombie or Human.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_reset_user_nemesis(id, bool:bHuman);