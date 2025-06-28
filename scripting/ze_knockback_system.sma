// This Knockback system taken from Zombie Plague 5.0.
// Because this is still a better Knockback system :)

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <reapi>
#include <xs>

#include <ze_core>

// Weapons Power.
new Float:g_flWeaponsPower[] =
{
	-1.0,   // ---
	2.4,    // P228
	-1.0,   // ---
	6.5,    // SCOUT
	-1.0,   // ---
	8.0,    // XM1014
	-1.0,   // ---
	2.3,    // MAC10
	5.0,    // AUG
	-1.0,   // ---
	2.4,    // ELITE
	2.0,    // FIVESEVEN
	2.4,    // UMP45
	5.3,    // SG550
	5.5,    // GALIL
	5.5,    // FAMAS
	2.2,    // USP
	2.0,    // GLOCK18
	10.0,   // AWP
	2.5,    // MP5NAVY
	5.2,    // M249
	8.0,    // M3
	5.0,    // M4A1
	2.4,    // TMP
	6.5,    // G3SG1
	-1.0,   // ---
	5.3,    // DEAGLE
	5.0,    // SG552
	6.0,    // AK47
	1.0,    // KNIFE
	2.0     // P90
}

// Cvars.
new bool:g_bPower,
	bool:g_bDamage,
	bool:g_bVerVelo,
	bool:g_bFreezeMode,
	Float:g_flDucking,
	Float:g_flDistance

// Variable.
new g_iFwHandle,
	g_iFwResult,
	bool:g_bReleaseTime

// Array
new Float:g_flKnockback[MAX_PLAYERS+1]

public plugin_natives()
{
	register_library("ze_kb_system")
	register_native("ze_get_zombie_knockback", "__native_get_zombie_knockback")
	register_native("ze_set_zombie_knockback", "__native_set_zombie_knockback")
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Knockback System", ZE_VERSION, ZE_AUTHORS)

	// Ham.
	RegisterHamPlayer(Ham_TraceAttack, "fw_TraceAttack_Post", 1)

	// Cvars.
	bind_pcvar_num(create_cvar("ze_knockback_damage", "1"), g_bDamage)
	bind_pcvar_num(create_cvar("ze_knockback_power", "1"), g_bPower)
	bind_pcvar_num(create_cvar("ze_knockback_vervelo", "0"), g_bVerVelo)
	bind_pcvar_float(create_cvar("ze_knockback_ducking", "0.25"), g_flDucking)
	bind_pcvar_float(create_cvar("ze_knockback_distance", "500.0"), g_flDistance)

	bind_pcvar_num(get_cvar_pointer("ze_escape_mode"), g_bFreezeMode)

	// Create Forwards.
	g_iFwHandle = CreateMultiForward("ze_take_knockback", ET_CONTINUE, FP_CELL, FP_CELL, FP_ARRAY)
}

public plugin_cfg()
{
	new szName[MAX_NAME_LENGTH]
	for (new iWeapon = CSW_P228; iWeapon <= CSW_LAST_WEAPON; iWeapon++)
	{
		// Useless weapon?
		if (g_flWeaponsPower[iWeapon] == -1.0)
			continue // Ignore weapon.

		// Get weapon name.
		get_weaponname(iWeapon, szName, charsmax(szName))

		// Read Weapon Power value from INI file.
		if (!ini_read_float(ZE_FILENAME, "Knockback", szName[7], g_flWeaponsPower[iWeapon]))
			ini_write_float(ZE_FILENAME, "Knockback", szName[7], g_flWeaponsPower[iWeapon])
	}
}

public plugin_end()
{
	// Free the Memory.
	DestroyForward(g_iFwHandle)
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	g_flKnockback[id] = 0.0
}

public ze_game_started_pre()
{
	g_bFreezeMode = false
}

public ze_zombie_appear(const iZombies[], iZombiesNum)
{
	if (g_bFreezeMode)
		g_bReleaseTime = true
}

public ze_zombie_release()
{
	g_bReleaseTime = false
}

public fw_TraceAttack_Post(const iVictim, iAttacker, Float:flDamage, Float:vDirection[3], tr, const bitsDamageType)
{
	// Non-player damage or self damage
	if (g_bReleaseTime || iVictim == iAttacker || !is_user_alive(iVictim) || !is_user_alive(iAttacker))
		return

	// Victim isn't zombie or attacker isn't human
	if (ze_is_user_zombie(iVictim) == ze_is_user_zombie(iAttacker))
		return

	// Not bullet damage
	if (!(bitsDamageType & DMG_BULLET))
		return

	// Knockback only if damage is done to victim
	if (flDamage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE || get_tr2(tr, TR_pHit) != iVictim)
		return

	// Get whether the victim is in a crouch state
	static iDucking; iDucking = get_entvar(iVictim, var_flags) & (FL_DUCKING|FL_ONGROUND) == (FL_DUCKING|FL_ONGROUND)

	// Zombie knockback when ducking disabled
	if (iDucking && g_flDucking == 0.0)
		return

	// Max distance exceeded
	if (entity_range(iVictim, iAttacker) > g_flDistance)
		return

	static Float:vSpeed[3]

	// Reset vector3.
	vSpeed = NULL_VECTOR

	// Get victim's velocity
	get_entvar(iVictim, var_velocity, vSpeed)

	// Use damage on knockback calculation
	if (g_bDamage)
		xs_vec_mul_scalar(vDirection, flDamage, vDirection)

	// Get attacker's weapon id
	static iWeapon;iWeapon = get_user_weapon(iAttacker)

	// Use weapon power on knockback calculation
	if (g_bPower && g_flWeaponsPower[iWeapon] > 0.0)
		xs_vec_mul_scalar(vDirection, g_flWeaponsPower[iWeapon], vDirection)

	// Apply ducking knockback multiplier
	if (iDucking)
		xs_vec_mul_scalar(vDirection, g_flDucking, vDirection)

	// Apply zombie class knockback multiplier
	xs_vec_mul_scalar(vDirection, g_flKnockback[iVictim], vDirection)

	// Add up the new vector
	xs_vec_add(vSpeed, vDirection, vDirection)

	// Should knockback also affect vertical velocity?
	if (!g_bVerVelo)
		vDirection[2] = vSpeed[2]

	// Call forward ze_take_knockback(param1, param2, array1[3]) and get return value.
	ExecuteForward(g_iFwHandle, g_iFwResult, iVictim, iAttacker, PrepareArray(_:vDirection, 3, 1))

	if (g_iFwResult >= ZE_STOP)
		return

	// Set the knockback'd victim's velocity
	set_entvar(iVictim, var_velocity, vDirection)
}

/**
 * NATIVE(s):
 */
public Float:__native_get_zombie_knockback(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return -1.00;
	}

	return g_flKnockback[id] / 100.0
}

public __native_set_zombie_knockback(const plugin_id, const num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	g_flKnockback[id] = get_param_f(2) / 100.0
	return true
}