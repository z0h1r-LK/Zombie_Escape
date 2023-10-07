#if defined _grenades_included
	#endinput
#endif
#define _grenades_included

/**
 * -=| Forwards |=-
 */

/**
 * Called when the player Frozen by Frost-Nade. It is also called from native.
 *
 * @param id    Client index.
 *
 * @return      ZE_STOP     | Prevent freezing the player.
 *              ZE_CONTINUE | Continue freezing the player.
 */
forward ze_frost_freeze(id);

/**
 * Called when unfreeze the player.
 *
 * @param id    Client index.
 *
 * @return      ZE_STOP     | Leave player Frozen.
 *              ZE_CONTINUE | Unfreeze the player.
 */
forward ze_frost_unfreeze(id);

/**
 * -=| Natives |=-
 */

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
 * @return      true  | If the player is Frozen.
 *              false | If player not on game.
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
 * @return       true  | If the player is Frozen.
 *               false | If player not on game.
 *
 * @error        If the player not on game.
 */
native ze_set_user_frost_ex(id, Float:flPeriod);