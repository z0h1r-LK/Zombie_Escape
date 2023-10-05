#if defined _weap_models_api_included
	#endinput
#endif
#define _weap_models_api_included

/**
 * Sets player a custom view model for specific weapon [v_*].
 *
 * @note Let model blank to unset no weapon for player.
 *
 * @param id         Client index.
 * @param iWeaponID  Weapon Index (CSW_*)
 *
 * @return          true  | If assigned successfully.
 *                  false | If player not on game or invalid weapon id.
 *
 * @error           If this player not on the game or invalid weapon id.
 */
native ze_set_user_view_model(id, iWeaponID, const szModel[] = "");

/**
 * Sets player a custom weapon model for specific weapon [p_*].
 *
 * @note   Let model blank to unset no weapon for player.
 *
 * @param id         Client index.
 * @param iWeaponID  Weapon Index (CSW_*)
 *
 * @return          true  | If assigned successfully.
 *                  false | If player not on game or invalid weapon id.
 *
 * @error           If this player not on the game or invalid weapon id.
 */
native ze_set_user_weap_model(id, iWeaponID, const szModel[] = "");

/**
 * Remove player a custom view model [v_*].
 *
 * @param id         Client index.
 * @param iWeaponID  Weapon Index (CSW_*)
 *
 * @return           true  | If assigned successfully.
 *                   false | If this player not on game or invalid weapon id.
 *
 * @error            If this player not on game or invalid weapon id.
 */
native ze_remove_user_view_model(id, iWeaponID);

/**
 * Remove player a custom weapon model [p_*]
 *
 * @param id         Client index.
 * @param iWeaponID  Weapon Index (CSW_*)
 *
 * @return           true  | If assigned successfully.
 *                   false | If this player not on game or invalid weapon id.
 *
 * @error            If this player not on game or invalid weapon id.
 */
native ze_remove_user_weap_model(id, iWeaponID);