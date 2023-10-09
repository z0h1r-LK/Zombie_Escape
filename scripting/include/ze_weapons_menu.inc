#if defined _weapons_menu_defined
	#endinput
#endif
#define _weapons_menu_defined

/**
 * Check if auto select previous weapons Enabled or Disabled.
 *
 * @param id     Client index.
 *
 * @return       true  | If auto select Enabled.
 *               false | Otherwise.
 *
 * @error        If this player not on game.
 */
native ze_auto_buy_enabled(id);

/**
 * Enable or disable auto select.
 *
 * @param id     Client index.
 * @param bSet   true = Enable auto select | false = Otherwise.
 *
 * @return       true  | If operation successfully.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_set_auto_buy(id, bool:bSet = false);

/**
 * Show weapons menu for specific player.
 *
 * @param id     Client index.
 * @param bCheck Skip checks.
 *
 * @return       true  | If appeared successfully.
 *               false | If player not on game or Zombie or not alive or buy time over or menu Disabled.
 *
 * @error        If this player not on game.
 */
native ze_show_weapons_menu(id, bool:bCheck = false);