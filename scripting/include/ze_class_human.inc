#if defined _ze_class_human_ex_included
	#endinput
#endif
#define _ze_class_human_ex_included

#include <ze_class_const>

/**
 * -=| Natives |=-
 */

/**
 * Registers new Class on Humans Menu.
 *
 * @note Maximum Name and Model length is 32 characters,
 *       Maximum Description and Melee length is 64 characters.
 *
 * @param szName[]     Human Name.
 * @param szDesc[]     Human Description.
 * @param szModel[]    Human Player Model.
 * @param flHealth     Human Health.
 * @param flArmor      Human Shield.
 * @param fSpeedFactor Human Speed type (1 = Speed Factor [Weapon Speed + flSpeed] | 0 = Static Speed [flSpeed])
 * @param flSpeed      Human Speed.
 * @param flGravity    Human Gravity.
 *
 * @return             A valid class ID on registered, ZE_CLASS_INVALID when failure.
 *
 * @error              If class without Name or Name already exist.
 */
native ze_hclass_register(const szName[], const szDesc[], const szModel[], Float:flHealth, Float:flArmor, bool:fSpeedFactor, Float:flSpeed, Float:flGravity);

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
native ze_hclass_get_current(id);

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
native ze_hclass_get_next(id);

/**
 * Check If class id is valid or not.
 *
 * @param iClassID   class ID.
 *
 * @return           true  | If class id is valid.
 *                   false | Otherwise.
 */
native ze_hclass_is_valid(iClassID);

/**
 * Gets a class Name.
 *
 * @param iClassID    A valid class ID.
 * @param szBuffer[]  Buffer to copy name to.
 * @param iLength     Maximum buffer size.
 *
 * @return            true  | If copied successfully.
 *                    false | If failure.
 *
 * @error             If the class ID is invalid.
 */
native ze_hclass_get_name(iClassID, szBuffer[], iLength);

/**
 * Gets a class Description.
 *
 * @param iClassID    A valid class ID.
 * @param szBuffer[]  Buffer to copy description to.
 * @param iLength     Maximum buffer size.
 *
 * @return            true  | If copied successfully.
 *                    false | If failure.
 *
 * @error             If the class ID is invalid.
 */
native ze_hclass_get_desc(iClassID, szBuffer[], iLength);

/**
 * Gets a class Model.
 *
 * @param iClassID    A valid class ID.
 * @param szBuffer[]  Buffer to copy model name to.
 * @param iLength     Maximum buffer size.
 *
 * @return            true  | If copied successfully.
 *                    false | If failure.
 *
 * @error             If the class ID is invalid.
 */
native ze_hclass_get_model(iClassID, szBuffer[], iLength);

/**
 * Gets a class Health.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Health value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_hclass_get_health(iClassID);

/**
 * Gets a class Shield.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Shield value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_hclass_get_armor(iClassID);

/**
 * Check speed type of the Class.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            1                | Dynamic speed (Speed Factor).
 *                    0                | Static speed.
 *                    ZE_CLASS_INVALID | class ID is invalid.
 *
 * @error             If this class ID is invalid.
 */
native ze_hclass_is_speed_factor(iClassID);

/**
 * Gets a class Speed.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Speed value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_hclass_get_speed(iClassID);

/**
 * Gets a class Gravity.
 *
 * @param iClassID    A valid class ID.
 *
 * @return            Gravity value on success, ZE_CLASS_INVALID when failure.
 *
 * @error             If this class ID is invalid.
 */
native Float:ze_hclass_get_gravity(iClassID);

/**
 * Sets a class for specific player.
 *
 * @param id          Client index.
 * @param iClassID    A valid class ID.
 * @param bCure       true = set Human attributes | false = Otherwise.
 *
 * @return            true  | If assigned successfully.
 *                    false | If failure.
 *
 * @error             If this player not on game or class ID is invalid.
 */
native ze_hclass_set_current(id, iClassID, bool:bCure = false);

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
native ze_hclass_set_next(id, iClassID);

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
native ze_hclass_set_name(iClassID, const szName[]);

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
native ze_hclass_set_desc(iClassID, const szDesc[]);

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
native ze_hclass_set_health(iClassID, Float:flHealth);

/**
 * Sets speed type for specific class.
 *
 * @param iClassID      A valid class ID.
 * @param bSpeedFactor  true = Dynamic (Speed factor) | false = Static.
 *
 * @return              true  | If changed successfully.
 *                      false | If failure.
 *
 * @error               If this class ID is invalid.
 */
native ze_hclass_set_speed_factor(iClassID, bool:bSpeedFactor = true)

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
native ze_hclass_set_speed(iClassID, Float:flSpeed);

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
native ze_hclass_set_gravity(iClassID, Float:flGravity);

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
native ze_hclass_show_menu(id);