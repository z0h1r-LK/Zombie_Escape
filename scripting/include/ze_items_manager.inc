#if defined _items_manager_included
	#endinput
#endif
#define _items_manager_included

/**
 * -=| Forwards |=-
 */

/**
 * Called when player select item, It is called also when display item on Menu.
 *
 * @param id           Client index.
 * @param iItem        Item index.
 * @param bIgnoreCost  true = Ignore item cost | false = Otherwise.
 * @param bInMenu      true = Display item on Menu | false = Otherwise.
 *
 * @return             ZE_ITEM_AVAILABLE   | Make item available for player.
 *                     ZE_ITEM_UNAVAILABLE | Make item unavailable for player.
 *                     ZE_ITEM_DONT_SHOW   | Don't display item on Menu.
 */
forward ze_select_item_pre(id, iItem, bool:bIgnoreCost, bool:bInMenu);

/**
 * Called after player select item.
 *
 * @param id           Client index.
 * @param iItem        Item index.
 * @param bIgnoreCost  true = Ignore item cost | false = Otherwise.
 *
 * @noreturn
 */
forward ze_select_item_post(id, iItem, bool:bIgnoreCost);

/**
 * -=| Natives |=-
 */

/**
 * Registers an item on Menu.
 *
 * @note Maximum item name length is 32 characters,
 *       Check amxconst.inc and MAX_NAME_LENGTH
 *
 * @param szName[]     Item Name.
 * @param iCost        Item Cost.
 * @param iLimit       Item Limit (0 = Unlimited).
 *
 * @return             A valid item id | If registered successfully.
 *                     ZE_ITEM_WRONG   | If item without name or item name already exist.
 *
 * @error              Register item without name or item name already used.
 */
native ze_item_register(const szName[], iCost, iLimit);
native ze_register_item(const szName[], iCost, iLimit);

/**
 * Returns an item name.
 *
 * @param id           Item id.
 * @param szName[]     Buffer to store string in.
 * @param iMaxLen      Buffer length.
 *
 * @return             Number of cells written.
 *
 * @error              If item id is invalid.
 */
native ze_item_get_name(iItem, szName[], iMaxLen);

/**
 * Returns an item cost.
 *
 * @param id           Item id.
 *
 * @return             Item cost     | If item id is valid.
 *                     ZE_ITEM_WRONG | If item id in invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_get_cost(iItem);

/**
 * Returns an item limit
 *
 * @param id           Item id.
 *
 * @return             Item limit    | If item id is valid.
 *                     ZE_ITEM_WRONG | If item is is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_get_limit(iItem);

/**
 * Add additional text in item name on Menu.
 *
 * @param text[]       Text to be added.
 * @param ...          Variable number of formatting parameters.
 *
 * @noreturn
 */
native ze_item_add_text(const text[], any:...);

/**
 * Force give item for specific player.
 *
 * @param id           Client index.
 * @param iItem        Item id.
 * @param bIgnoreCost  true = Ignore item cost | false = Otherwise.
 *
 * @return             true  | If operation successfully.
 *                     false | If handled by forward or item id invalid or player not on game.
 *
 * @error              If this player not on game or item id is invalid.
 */
native ze_item_force_buy(id, iItem, bool:bIgnoreCost = false);

/**
 * Set an item new name.
 *
 * @note Maximum name length is 32 characters.
 *
 * @param iItem        Item id.
 * @param szName[]     New item name.
 *
 * @return             Number of cells written.
 *
 * @error              Invalid item id or no item name entered or name already duplicated.
 */
native ze_item_set_name(iItem, const szName[]);

/**
 * Sets an item new cost.
 *
 * @param iItem        Item id.
 * @param iCost        Cost to be set.
 *
 * @return             true  | If new cost assigned.
 *                     false | If item id is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_set_cost(iItem, iCost);

/**
 * Sets an item new limit.
 *
 * @param iItem        Item id.
 * @param iLimit       Limit to be set.
 *
 * @return             true  | If new cost assigned.
 *                     false | If item id is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_set_limit(iItem, iLimit);

/**
 * Check If item id is valid or not.
 *
 * @param id           Item id.
 *
 * @return             true  | If item id is valid.
 *                     false | If item id is invalid.
 */
native ze_item_is_valid(id);

/**
 * Show menu for specific player.
 *
 * @param id           Client index.
 *
 * @return             true  | If command sent successfully.
 *                     false | If player not on game.
 *
 * @error              If this player not on game.
 */
native ze_item_show_menu(id);