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