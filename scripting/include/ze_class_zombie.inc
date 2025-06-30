#if defined _ze_class_zombie_ex_included
	#endinput
#endif
#define _ze_class_zombie_ex_included

#include <ze_class_const>

/**
 * -=| Forwards |=-
 */

/**
 * Called when a player selects a Zombie class. This function is also called when displaying the class in the menu.
 *
 * @note It is also called when a player gets infected and before assign Zombie attributes.
 *
 * @param id          Client index.
 * @param iClassID    Class index.
 * @param bInfected   true = Assigning Zombie attributes to the player | false = Do not assign attributes.
 * @param bInMenu     true = Ignore item cost (menu preview) | false = Apply item cost.
 * @param szName[]    Zombie name.
 * @param szDesc[]    Zombie description.
 * @param szModel[]   Zombie player model.
 * @param szMelee[]   Zombie melee model.
 * @param flHealth    Zombie health
 * @param flSpeed     Zombie maxsppeed
 * @param flGravity   Zombie gravity.
 * @param flKnockback Zombie knockback
 * @param iLevel      Zombie required level.
 *
 * @return           ZE_CLASS_AVAILABLE   | Make class available for player.
 *                   ZE_CLASS_UNAVAILABLE | Make class unavailable for player.
 *                   ZE_CLASS_DONT_SHOW   | Don't display the class in Menu.
 */
forward ze_select_zclass_pre(id, iClassID, bool:bInfected, bool:bInMenu, const szName[], const szDesc[], const szModel[], const szMelee[], Float:flHealth, Float:flSpeed, Float:flGravity, Float:flKnockback, iLevel);

/**
 * Called after a player selects a Zombie class.
 *
 * @note It is also called when a player gets infected and after assign Zombie attributes.
 *
 * @param id          Client index.
 * @param iClassID    Class index.
 * @param bInfected   true = Assigning Zombie attributes to the player | false = Otherwise
 * @param szName[]    Zombie name.
 * @param szDesc[]    Zombie description.
 * @param szModel[]   Zombie player model.
 * @param szMelee[]   Zombie melee model.
 * @param flHealth    Zombie health
 * @param flSpeed     Zombie maxsppeed
 * @param flGravity   Zombie gravity.
 * @param flKnockback Zombie knockback
 * @param iLevel      Zombie required level.
 *
 * @noreturn
 */
forward ze_select_zclass_post(id, iClassID, bool:bInfected, const szName[], const szDesc[], const szModel[], const szMelee[], Float:flHealth, Float:flSpeed, Float:flGravity, Float:flKnockback, iLevel);

/**
 * -=| Natives |=-
 */

/**
 * Registers new Class on Zombies Menu.
 *
 * @note Maximum Name and Model length is 32 characters,
 *       Maximum Description and Melee length is 64 characters.
 *
 * @param szName[]     Zombie Name.
 * @param szDesc[]     Zombie Description.
 * @param szModel[]    Zombie Player Model.
 * @param szMelee[]    Zombie Melee Model.
 * @param flHealth     Zombie Health.
 * @param flSpeed      Zombie Speed.
 * @param flGravity    Zombie Gravity.
 * @param flKnockback  Zombie Knockback.
 * @param iLevel       Zombie required level (0 = Ignore)
 *
 * @return             A valid class ID on registered, ZE_CLASS_INVALID when failure.
 *
 * @error              If class without Name or Name already exist.
 */
native ze_zclass_register(const szName[], const szDesc[], const szModel[], const szMelee[], Float:flHealth, Float:flSpeed, Float:flGravity, Float:flKnockback, iLevel = 0);

/**
 * Gets current class for specific player.
 *
 * @param id    Client index.
 *
 * @return      A valid class ID | If successfully.
 *              ZE_CLASS_INVALID | If failure.
 *
 * @error       If this player not on game.
 */
native ze_zclass_get_current(id);

/**
 * Gets next class for specific player.
 *
 * @param id    Client index.
 *
 * @return      A valid class ID | If successfully.
 *              ZE_CLASS_INVALID | If failure.
 *
 * @error       If this player not on game.
 */
native ze_zclass_get_next(id);

/**
 * Check If class id is valid or not.
 *
 * @param iClassID   class ID.
 *
 * @return           true  | If class id is valid.
 *                   false | Otherwise.
 */
native ze_zclass_is_valid(iClassID);

/**
 * Gets a class Name.
 *
 * @param iClassID    A valid class ID.
 * @param szBuffer[]  Buffer to copy name to.
 * @param iLength     Maximum buffer size.
 *
 * @return            Number of cells written.
 *
 * @error             If the class ID is invalid.
 */
native ze_zclass_get_name(iClassID, szBuffer[], iLength);

/**
 * Gets a class Description.
 *
 * @param iClassID    A valid class ID.
 * @param szBuffer[]  Buffer to copy description to.
 * @param iLength     Maximum buffer size.
 *
 * @return            Number of cells written.
 *
 * @error             If the class ID is invalid.
 */
native ze_zclass_get_desc(iClassID, szBuffer[], iLength);

/**
 * Gets a class Model.
 *
 * @param iClassID    A valid class ID.
 * @param szBuffer[]  Buffer to copy model name to.
 * @param iLength     Maximum buffer size.
 *
 * @return            Number of cells written.
 *
 * @error             If the class ID is invalid.
 */
native ze_zclass_get_model(iClassID, szBuffer[], iLength);

/**
 * Gets a class Melee path.
 *
 * @param iClassID    A valid class ID.
 * @param szBuffer[]  Buffer to copy model to.
 * @param iLength     Maximum buffer size.
 *
 * @return            true  | If copied successfully.
 *                    false | If failure.
 *
 * @error             If the class ID is invalid.
 */
native ze_zclass_get_melee(iClassID, szBuffer[], iLength);

/**
 * Gets a class Health.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Health value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_zclass_get_health(iClassID);

/**
 * Gets a class Speed.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Speed value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_zclass_get_speed(iClassID);

/**
 * Gets a class Gravity.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Gravity value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_zclass_get_gravity(iClassID);

/**
 * Gets a class Knockback speed.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Knockback speed on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_zclass_get_knockback(iClassID);

/**
 * Gets a class Level.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Level value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_get_level(iClassID);

/**
 * Look for an index of the class via the name.
 *
 * @param szName[]    A valid class ID.
 *
 * @return            Class index on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_get_index(const szName[]);

/**
 * Sets a class for specific player.
 *
 * @param id          Client index.
 * @param iClassID    A valid class ID.
 * @param bInfect     true = Infect player to set Zombie attributes | false = Otherwise.
 *
 * @return            true  | If assigned successfully.
 *                    false | If failure.
 *
 * @error             If this player not on game or class ID is invalid.
 */
native ze_zclass_set_current(id, iClassID, bool:bInfect = false);

/**
 * Sets a class for specific player.
 *
 * @param id          Client index.
 * @param iClassID    A valid class ID.
 *
 * @return            true  | If assigned successfully.
 *                    false | If failure.
 *
 * @error             If this player not on game or class ID is invalid.
 */
native ze_zclass_set_next(id, iClassID);

/**
 * Sets new name for specific class.
 *
 * @note Maximum name length is 32 characters.
 *
 * @param iClassID    A valid class ID.
 * @param szName[]    Name to be set.
 *
 * @return            true  | If changed successfully.
 *                    false | If failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_set_name(iClassID, const szName[]);

/**
 * Sets new description for specific class.
 *
 * @note Maximum description length is 64 characters.
 *
 * @param iClassID    A valid class ID.
 * @param szDesc[]    Description to be set.
 *
 * @return            true  | If changed successfully.
 *                    false | If failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_set_desc(iClassID, const szDesc[]);

/**
 * Sets new Health for specific class.
 *
 * @param iClassID    A valid class ID.
 * @param flHealth    Health to be set.
 *
 * @return            true  | If changed successfully.
 *                    false | If failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_set_health(iClassID, Float:flHealth);

/**
 * Sets new Speed for specific class.
 *
 * @param iClassID    A valid class ID.
 * @param flSpeed     Speed to be set.
 *
 * @return            true  | If changed successfully.
 *                    false | If failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_set_speed(iClassID, Float:flSpeed);

/**
 * Sets new Gravity for specific class.
 *
 * @param iClassID    A valid class ID.
 * @param flGravity   Gravity to be set.
 *
 * @return            true  | If changed successfully.
 *                    false | If failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_set_gravity(iClassID, Float:flGravity);

/**
 * Sets new Knockback speed for specific class.
 *
 * @param iClassID    A valid class ID.
 * @param flSpeed     Knockback speed to be set.
 *
 * @return            true  | If changed successfully.
 *                    false | If failure.
 *
 * @error             If this class ID is invalid.
 */
native ze_zclass_set_knockback(iClassID, Float:flSpeed);

/**
 * Sets new Level for specific class.
 *
 * @param iClassID    A valid class ID.
 * @param iLevel      Level to be set.
 *
 * @return            true  | If changed successfully.
 *                    false | If failure.
 *
 * @error             If this class IS is invalid.
 */
native ze_zclass_set_level(iClassID, iLevel);

/**
 * Adds additional text to the class in the menu.
 *
 * @note Maximum text length is 64 bytes.
 *
 * @param szText[]  Text to be add.
 *
 * @return          Number of cells written.
 */
native ze_zclass_add_text(const szText[], any:...);

/**
 * Show Zombies Classes Menu for specific player.
 *
 * @param id     Client index.
 *
 * @return       true  | If displayed successfully.
 *               false | If player not on game.
 *
 * @error        If this player not on game.
 */
native ze_zclass_show_menu(id);