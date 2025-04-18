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
 * Registers an item on Menu.
 *
 * @note Maximum item name length is 32 characters,
 *       Check amxconst.inc and MAX_NAME_LENGTH
 *       Level-XP System is required, Download it (escapers-zone.net)
 *
 * @param szName[]     Item Name.
 * @param iCost        Item Cost.
 * @param iLimit       Item Limit (0 = Unlimited).
 * @param iLevel       Item Level (0 = Free).
 * @paral iGLimit      Item Global Limit (0 = Unlimited).
 *
 * @return             A valid item id | If registered successfully.
 *                     ZE_ITEM_WRONG   | If item without name or item name already exist.
 *
 * @error              Register item without name or item name already used.
 */
native ze_item_register_ex(const szName[], iCost, iLimit, iLevel = 0, iGLimit = 0);

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
 *                     ZE_ITEM_WRONG | If item id is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_get_limit(iItem);

/**
 * Returns an item level.
 *
 * @param id           Item id.
 *
 * @return             Item level    | If item id is valid.
 *                     ZE_ITEM_WRONG | If item id is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_get_level(iItem);

/**
 * Returns an item global limit.
 *
 * @param id           Item id.
 *
 * @return             Item limit    | If item id is valid.
 *                     ZE_ITEM_WRONG | If item is is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_get_glimit(iItem);

/**
 * Returns the number of the purchases.
 *
 * @param id     Client index.
 *
 * @return       Number of purchases, -1 While player not on game.
 * @error        If this player not on game.
 */
native ze_item_get_num_pur(id);

/**
 * Look for an index of the item via the name
 *
 * @param szName[]   Item name.
 *
 * @return           Item index    | If item's found.
 *                   ZE_WRONG_ITEM | If no name entered or item's not found.
 * @error            If no name has entered.
 */
native ze_item_get_index(const szName[]);

/**
 * Add additional text in item name on Menu.
 *
 * @param text[]       Text to be added.
 * @param ...          Variable number of formatting parameters.
 *
 * @return             Number of cells written.
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
 * @return             true  | If new limit assigned.
 *                     false | If item id is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_set_limit(iItem, iLimit);

/**
 * Sets an item level.
 *
 * @param id           Item id.
 * @param iLevel       Level to be set.
 *
 * @return             true  | If new level assigned.
 *                     false | If item id is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_set_level(iItem, iLevel);

/**
 * Sets an item new global limit.
 *
 * @param iItem        Item id.
 * @param iLimit       Global limit to be set.
 *
 * @return             true  | If new limit assigned.
 *                     false | If item id is invalid.
 *
 * @error              If item id is invalid.
 */
native ze_item_set_glimit(iItem, iLimit);

/**
 * Sets or add the number of items.
 *
 * @param id     Client index
 * @param iSet   Number of purchases to be set.
 * @param bAdd   true = Set value | false = Add value.
 *
 * @return       true  | If value assigned successfully.
 *               false | If player not on game.
 * @error        If this player not on game.
 */
native ze_item_set_num_pur(id, iSet, bool:bAdd = false);

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