#if defined _ze_gamemodes_included
	#endinput
#endif
#define _ze_gamemodes_included

#include <ze_gamemodes_const>

/**
 * -=| Forwards |=-
 */

/**
 * Called before game mode chosen.
 *
 * @param game_id    A valid game id.
 * @param target     Target index. (0 = no target)
 * @param bSkipCheck true = Skip Check | false = Otherwise.
 *
 * @return           ZE_STOP     | Prevent starting game mode.
 *                   ZE_CONTINUE | Continue starting game mode.
 */
forward ze_gamemode_chosen_pre(game_id, target, bool:bSkipCheck);

/**
 * Called after game mode chosen.
 *
 * @param game_id    A valid game id.
 * @param target     Target index (0 = no target)
 *
 * @noreturn
 */
forward ze_gamemode_chosen(game_id, target);

/**
 * -=| Natives |=-
 */

/**
 * Registers a new game mode with specific name.
 *
 * @note Maximum name length is 32 characters.
 *
 * @param szName[]  Game mode name.
 *
 * @return          A valid game id | If registered successfully.
 *                  ZE_GAME_INVALID | If game mode without name or name already exist.
 *
 * @error           If game mode without name or name already exist.
 */
native ze_gamemode_register(const szName[]);

/**
 * Sets specific game mode as default.
 *
 * @note The default game mode will be choose, when no game mode is chosen.
 *
 * @param game_id   A valid game id.
 *
 * @return          true  | If assigned successfully.
 *                  false | If game mode id invalid.
 *
 * @error           If game mode id invalid.
 */
native ze_gamemode_set_default(game_id);

/**
 * Gets current game mode.
 *
 * @return      A valid game id | If game mode running.
 *              ZE_GAME_INVALID | If no game mode chosen.
 */
native ze_gamemode_get_current();

/**
 * Sets specific game mode for the next round.
 *
 * @note Use this native before game mode start.
 *
 * @param game_id   A valid game id.
 *
 * @return          true  | If assigned successfully.
 *                  false | If game mode id invalid.
 *
 * @error           If game mode id invalid.
 */
native ze_gamemode_set_next(game_id);

/**
 * Gets the name for the specific gamemode.
 *
 * @param game_id    A valid game id.
 * @param szName[]   Buffer to store string in.
 * @param iLength    Buffer length.
 *
 * @return           Number of cells written.
 *
 * @error            If game mod is invalid.
 */
native ze_gamemode_get_name(game_id, szName[], iLength);

/**
 * Gets the game mode id via name.
 *
 * @note Maximum name length is 32 character.
 *
 * @param szName[]   Gamemode Name.
 *
 * @return           A valid game id | If the name is correct.
 *                   ZE_GAME_INVALID | If the name is incorrect or no name is entered.
 *
 * @error            If no name is entered.
 */
native ze_gamemode_get_id(const szName[]);

/**
 * Start a specific game mode.
 *
 * @note Game mode will not start if it is disabled from CVar.
 *
 * @param game_id    A valid game id.
 * @param target     Target index (0 = Ignore).
 *
 * @return           true  | If game mode started successfully.
 *                   false | If error.
 *
 * @error            If game mode invalid or player not on game.
 */
native ze_gamemode_start(game_id, target = 0);

/**
 * Gets the number of registered game modes.
 *
 * @return           Number of game modes.
 */
native ze_gamemode_get_count();

/**
 * Gets the next game mode.
 *
 * @return           A valid game mode id.
 */
native ze_gamemode_get_next();

/**
 * Checks if gamemode index is valid.
 *
 * @param            game mode id.
 *
 * @return           true  | If game mode index is valid.
 *                   false | Otherwise.
 */
native ze_gamemode_is_valid(game_id);