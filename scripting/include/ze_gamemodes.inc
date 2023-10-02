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
 * Sets specific game mode next.
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