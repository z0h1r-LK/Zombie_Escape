#include <amxmodx>
#include <engine>
#include <reapi>

#include <ze_core>
#include <ini_file>
#include <ze_weap_models_api>
#define LIBRARY_WPNMODELS "ze_weap_models_api"

// Defines.
#define FROST_RADIUS 240.0
#define FROST_RING_PERIOD 1
#define FROST_RING_AXIS_X 240
#define FROST_RING_AXIS_Y 240
#define FROST_RING_AXIS_Z 2400

#define TASK_UNFREEZE 100

#define GRENADE_ID 2222

// Forwards.
enum _:FORWARDS
{
	FORWARD_FROST_FREEZE = 0,
	FORWARD_FROST_UNFREEZE
}

// Rendering.
enum _:RENDERING
{
	Render_Fx = 0,
	Render_Mode,
	Render_Colors[3],
	Render_Amount
}

// Frost-Nade Models.
new g_v_szFrostModel[MAX_RESOURCE_PATH_LENGTH] = "models/v_flashbang.mdl"
new g_p_szFrostModel[MAX_RESOURCE_PATH_LENGTH] = "models/p_flashbang.mdl"
new g_w_szFrostModel[MAX_RESOURCE_PATH_LENGTH] = "models/w_flashbang.mdl"

// Frost-Nade Sounds.
new g_szFrostExplodeSound[MAX_RESOURCE_PATH_LENGTH] = "zm_es/frost_explode.wav"
new g_szFrostFreezeSound[MAX_RESOURCE_PATH_LENGTH] = "zm_es/frost_freeze.wav"
new g_szFrostUnfreezeSound[MAX_RESOURCE_PATH_LENGTH] = "zm_es/frost_unfreeze.wav"

// Cvars.
new bool:g_bFrostIcon,
	bool:g_bFrostDamage,
	Float:g_flFrostPeriod

// Variables.
new g_iRingSpr,
	g_iTrailSpr,
	g_iFwReturn,
	g_iMsgDamage,
	g_iIceGibsMdl,
	g_iMsgScreenFade,
	g_bitsIsFrozen

// Array.
new g_iForwards[FORWARDS],
	g_iRendering[MAX_PLAYERS+1][RENDERING]

public plugin_natives()
{
	register_library("ze_frost")
	register_native("ze_user_in_frost", "__native_user_in_frost")
	register_native("ze_set_user_frost", "__native_set_user_frost")
	register_native("ze_set_user_frost_ex", "__native_set_user_frost_ex")

	set_module_filter("fw_module_fitler")
	set_module_filter("fw_native_fitler")
}

public fw_module_filter(const module[], LibType:libtype)
{
	if (equal(module, LIBRARY_WPNMODELS))
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public fw_native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	new szRingSprite[MAX_RESOURCE_PATH_LENGTH] = "sprites/shockwave.spr"
	new szTrailSprite[MAX_RESOURCE_PATH_LENGTH] = "sprites/laserbeam.spr"
	new szIceGibsModel[MAX_RESOURCE_PATH_LENGTH] = "models/glassgibs.mdl"

	// Read Frost-Nade models from INI file.
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "V_FROSTNADE", g_v_szFrostModel, charsmax(g_v_szFrostModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "V_FROSTNADE", g_v_szFrostModel)
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "P_FROSTNADE", g_p_szFrostModel, charsmax(g_p_szFrostModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "P_FROSTNADE", g_p_szFrostModel)
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "W_FROSTNADE", g_w_szFrostModel, charsmax(g_w_szFrostModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "W_FROSTNADE", g_w_szFrostModel)

	// Read Frost Nade resources from INI file.
	if (!ini_read_string(ZE_FILENAME, "Grenades Effects", "FROST_RING", szRingSprite, charsmax(szRingSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Effects", "FROST_RING", szRingSprite)
	if (!ini_read_string(ZE_FILENAME, "Grenades Effects", "FROST_TRAIL", szTrailSprite, charsmax(szTrailSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Effects", "FROST_TRAIL", szTrailSprite)
	if (!ini_read_string(ZE_FILENAME, "Grenades Resources", "BROKEN_ICE", szIceGibsModel, charsmax(szIceGibsModel)))
		ini_write_string(ZE_FILENAME, "Grenades Resources", "BROKEN_ICE", szIceGibsModel)

	// Read Frost Nade sounds from INI file.
	if (!ini_read_string(ZE_FILENAME, "Sounds", "FROST_EXPLODE", g_szFrostExplodeSound, charsmax(g_szFrostExplodeSound)))
		ini_write_string(ZE_FILENAME, "Sounds", "FROST_EXPLODE", g_szFrostExplodeSound)
	if (!ini_read_string(ZE_FILENAME, "Sounds", "FROST_FREEZE", g_szFrostFreezeSound, charsmax(g_szFrostFreezeSound)))
		ini_write_string(ZE_FILENAME, "Sounds", "FROST_FREEZE", g_szFrostFreezeSound)
	if (!ini_read_string(ZE_FILENAME, "Sounds", "FROST_UNFREEZE", g_szFrostUnfreezeSound, charsmax(g_szFrostUnfreezeSound)))
		ini_write_string(ZE_FILENAME, "Sounds", "FROST_UNFREEZE", g_szFrostUnfreezeSound)

	// Precache Models.
	precache_model(g_v_szFrostModel)
	precache_model(g_p_szFrostModel)
	precache_model(g_w_szFrostModel)

	g_iRingSpr = precache_model(szRingSprite)
	g_iTrailSpr = precache_model(szTrailSprite)
	g_iIceGibsMdl = precache_model(szIceGibsModel)

	// Precache Sounds.
	precache_sound(g_szFrostExplodeSound)
	precache_sound(g_szFrostFreezeSound)
	precache_sound(g_szFrostUnfreezeSound)
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Grenade: Frost", ZE_VERSION, ZE_AUTHORS)

	// Hook Chains.
	RegisterHookChain(RG_PM_Move, "fw_PlayerMove_Movement")
	RegisterHookChain(RG_PM_AirMove, "fw_PlayerMove_Movement")

	RegisterHookChain(RG_ThrowFlashbang, "fw_GrenadeThrown_Post", 1)
	RegisterHookChain(RG_CGrenade_ExplodeFlashbang, "fw_GrenadeExploded_Pre")

	RegisterHookChain(RG_CBasePlayer_TraceAttack, "fw_TraceAttack_Pre")

	// Cvars.
	bind_pcvar_num(register_cvar("ze_frost_icon", "1"), g_bFrostIcon)
	bind_pcvar_num(register_cvar("ze_frost_damage", "0"), g_bFrostDamage)
	bind_pcvar_float(create_cvar("ze_frost_period", "3.0"), g_flFrostPeriod)

	// Create new Forwards.
	g_iForwards[FORWARD_FROST_FREEZE] = CreateMultiForward("ze_frost_freeze_start", ET_CONTINUE, FP_CELL)
	g_iForwards[FORWARD_FROST_UNFREEZE] = CreateMultiForward("ze_frost_freeze_end", ET_CONTINUE, FP_CELL)

	// Set Values.
	g_iMsgDamage = get_user_msgid("Damage")
	g_iMsgScreenFade = get_user_msgid("ScreenFade")
}

public plugin_end()
{
	// Free the Memory.
	DestroyForward(g_iForwards[FORWARD_FROST_FREEZE])
	DestroyForward(g_iForwards[FORWARD_FROST_UNFREEZE])
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	remove_task(id+TASK_UNFREEZE)
	flag_unset(g_bitsIsFrozen, id)

	// Reset cell in Array.
	for (new i = 0; i < RENDERING; i++)
		g_iRendering[id][i] = 0
}

public ze_user_humanized(id)
{
	// Unfreeze victim.
	remove_task(id+TASK_UNFREEZE)
	flag_unset(g_bitsIsFrozen, id)

	if (module_exists(LIBRARY_WPNMODELS))
	{
		// View and Weapon Model.
		ze_set_user_view_model(id, CSW_FLASHBANG, g_v_szFrostModel)
		ze_set_user_weap_model(id, CSW_FLASHBANG, g_p_szFrostModel)
	}
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	// Unfreeze victim.
	remove_task(iVictim+TASK_UNFREEZE)
	flag_unset(g_bitsIsFrozen, iVictim)
}

public fw_PlayerMove_Movement(const id)
{
	if (!flag_get_boolean(g_bitsIsFrozen, id))
		return HC_CONTINUE

	// Freeze player.
	set_pmove(pm_maxspeed, 1.0)
	set_pmove(pm_velocity, Float:{0.0, 0.0, 0.0})
	return HC_CONTINUE
}

public fw_TraceAttack_Pre(const iVictim, iInflector, iAttacker, Float:flDamage, bitsDamageType)
{
	// Block Damage?
	if (!g_bFrostDamage && flag_get_boolean(g_bitsIsFrozen, iVictim))
		return HC_SUPERCEDE

	return HC_CONTINUE
}

public fw_GrenadeThrown_Post(const id)
{
	if (!is_user_connected(id))
		return

	// Is Zombie?
	if (ze_is_user_zombie(id))
		return

	// Get grenade entity.
	new iEnt = GetHookChainReturn(ATYPE_INTEGER)

	if (is_nullent(iEnt))
		return

	// Set entity World Model.
	entity_set_model(iEnt, g_w_szFrostModel)

	// Set entity unique id.
	set_entvar(iEnt, var_impulse, GRENADE_ID)

	// Set entity Glow Shell.
	set_ent_rendering(iEnt, kRenderFxGlowShell, 0, 127, 255, kRenderNormal, 10)

	// Grenade Trail.
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id.
	write_short(iEnt) // Entity ID.
	write_short(g_iTrailSpr) // Sprite Index.
	write_byte(5) // Duration.
	write_byte(5) // Width.
	write_byte(0) // Red.
	write_byte(127) // Green.
	write_byte(255) // Blue.
	write_byte(255) // Brightness.
	message_end()
}

public fw_GrenadeExploded_Pre(const iEnt)
{
	if (is_nullent(iEnt))
		return HC_CONTINUE

	// Frost Nade?
	if (get_entvar(iEnt, var_impulse) != GRENADE_ID)
		return HC_CONTINUE

	frost_Explode(iEnt)

	// Remove entity.
	rg_remove_entity(iEnt)
	return HC_SUPERCEDE // Prevent property of Grenade.
}

public frost_Explode(const iEnt)
{
	new Float:vOrigin[3]

	// Get entity's origin.
	get_entvar(iEnt, var_origin, vOrigin)

	// Search victims.
	new iPlayers[MAX_PLAYERS], victim
	new iAliveNum = find_sphere_class(0, "player", FROST_RADIUS, iPlayers, MAX_PLAYERS, vOrigin)

	// Freeze victims.
	for (new i = 0; i < iAliveNum; i++)
	{
		victim = iPlayers[i]

		// Is Zombie?
		if (!ze_is_user_zombie(victim) || flag_get_boolean(g_bitsIsFrozen, victim))
			continue

		// Freeze the player.
		freeze_Player(victim, g_flFrostPeriod)
	}

	for (new i = 0; i < 2; i++)
	{
		// Ring effect.
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vOrigin)
		write_byte(TE_BEAMCYLINDER) // TE id.
		write_coord_f(vOrigin[0]) // Position X.
		write_coord_f(vOrigin[1]) // Position Y.
		write_coord_f(vOrigin[2] + 64.0) // Position Z.
		write_coord_f(vOrigin[0] + FROST_RING_AXIS_X) // Axis X.
		write_coord_f(vOrigin[1] + FROST_RING_AXIS_Y) // Axis Y.
		write_coord_f(vOrigin[2] + FROST_RING_AXIS_Z) // Axis Z.
		write_short(g_iRingSpr) // Sprite Index.
		write_byte(0) // Frame.
		write_byte(0) // Frame rate.
		write_byte(FROST_RING_PERIOD) // Duration.
		write_byte(64) // Width.
		write_byte(0) // Noise.
		write_byte(0) // Red.
		write_byte(127) // Green.
		write_byte(255) // Blue.
		write_byte(255) // Brightness.
		write_byte(0) // Scroll Speed.
		message_end()
	}

	// Emit explode sound.
	emit_sound(iEnt, CHAN_WEAPON, g_szFrostExplodeSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public freeze_Player(const iVictim, Float:flFreezePeriod)
{
	// Call forward ze_frost_freeze(id) and get return value.
	ExecuteForward(g_iForwards[FORWARD_FROST_FREEZE], g_iFwReturn, iVictim)

	if (g_iFwReturn >= ZE_STOP)
		return false

	// Freeze player.
	flag_set(g_bitsIsFrozen, iVictim)

	// Freeze Icon.
	if (g_bFrostIcon)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgDamage, .player = iVictim)
		write_byte(0) // Damage Save.
		write_byte(0) // Damage Take.
		write_long(DMG_DROWN) // Damage Type.
		write_coord(0) // Position X.
		write_coord(0) // Position Y.
		write_coord(0) // Position Z.
		message_end()
	}

	// Fade Screen.
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgScreenFade, .player = iVictim)
	write_short(0) // Duration.
	write_short(0) // Hold time.
	write_short(0x0004) // Fade Type.
	write_byte(0) // Red.
	write_byte(127) // Green.
	write_byte(255) // Blue.
	write_byte(127) // Alpha.
	message_end()

	// Remember rendering of player.
	new Float:flColor[3]
	g_iRendering[iVictim][Render_Fx] = get_entvar(iVictim, var_renderfx)
	g_iRendering[iVictim][Render_Mode] = get_entvar(iVictim, var_rendermode)
	get_entvar(iVictim, var_rendercolor, flColor)
	g_iRendering[iVictim][Render_Colors + 0] = floatround(flColor[0])
	g_iRendering[iVictim][Render_Colors + 1] = floatround(flColor[1])
	g_iRendering[iVictim][Render_Colors + 2] = floatround(flColor[2])
	g_iRendering[iVictim][Render_Amount] = floatround(get_entvar(iVictim, var_renderamt))

	// Freeze effect.
	set_ent_rendering(iVictim, kRenderFxGlowShell, 0, 127, 255, kRenderNormal, 10)

	// Emit freeze sound.
	emit_sound(iVictim, CHAN_BODY, g_szFrostFreezeSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	// Task before unfreeze victim.
	set_task(flFreezePeriod, "unfreeze_Player", iVictim+TASK_UNFREEZE)
	return true
}

public unfreeze_Player(iVictim)
{
	iVictim -= TASK_UNFREEZE

	// Call forward ze_frost_unfreeze(id) and get return value.
	ExecuteForward(g_iForwards[FORWARD_FROST_UNFREEZE], g_iFwReturn, iVictim)

	if (g_iFwReturn >= ZE_STOP)
		return false

	// Unfreeze player.
	flag_unset(g_bitsIsFrozen, iVictim)

	// Back previous rendering of player.
	set_ent_rendering(iVictim, g_iRendering[iVictim][Render_Fx], g_iRendering[iVictim][Render_Colors + 0], g_iRendering[iVictim][Render_Colors + 1], g_iRendering[iVictim][Render_Colors + 2], g_iRendering[iVictim][Render_Mode], g_iRendering[iVictim][Render_Amount])

	// Get player's origin.
	new vOrigin[3]
	get_user_origin(iVictim, vOrigin, Origin_Client)

	// Broken Ice Gibs.
	message_begin(MSG_PVS, SVC_TEMPENTITY, vOrigin)
	write_byte(TE_BREAKMODEL) // TE id.
	write_coord(vOrigin[0]) // Position X.
	write_coord(vOrigin[1]) // Position Y.
	write_coord(vOrigin[2]) // Position Z.
	write_coord(32) // Size X.
	write_coord(32) // Size Y.
	write_coord(72) // Size Z.
	write_coord(0) // Velocity X.
	write_coord(0) // Velocity Y.
	write_coord(0) // Velocity Z.
	write_byte(4) // Random Velocity.
	write_short(g_iIceGibsMdl) // Sprite/Model Index.
	write_byte(8) // Count.
	write_byte(12) // Duration.
	write_byte(BREAK_GLASS)
	message_end()

	// Fade Screen.
	message_begin(MSG_ONE_UNRELIABLE, g_iMsgScreenFade, .player = iVictim)
	write_short(BIT(12)) // Duration.
	write_short(0) // Hold time.
	write_short(0x0000) // Fade Type.
	write_byte(0) // Red.
	write_byte(127) // Green.
	write_byte(255) // Blue.
	write_byte(100) // Alpha.
	message_end()

	// Emit unfreeze sound.
	emit_sound(iVictim, CHAN_BODY, g_szFrostUnfreezeSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	return true
}

/**
 * -=| Natives |=-
 */
public __native_user_in_frost(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	return flag_get_boolean(g_bitsIsFrozen, id)
}

public __native_set_user_frost(plugin_id, num_params)
{
	new victim = get_param(1)

	if (!is_user_connected(victim))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", victim)
		return false
	}

	if (get_param(2))
	{
		// Already Frozen?
		if (flag_get_boolean(g_bitsIsFrozen, victim))
			return false

		// Freeze the player.
		return freeze_Player(victim, g_flFrostPeriod)
	}

	// Already Frozen?
	if (!flag_get_boolean(g_bitsIsFrozen, victim))
		return true

	// Unfreeze player.
	return unfreeze_Player(victim+TASK_UNFREEZE)
}

public __native_set_user_frost_ex(plugin_id, num_params)
{
	new victim = get_param(1)

	if (!is_user_connected(victim))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", victim)
		return false
	}

	// Already Frozen?
	if (flag_get_boolean(g_bitsIsFrozen, victim))
		return false

	new Float:flFreezePeriod
	if ( (flFreezePeriod = get_param_f(2)) <= 0.0)
		return false

	// Freeze the player.
	return freeze_Player(victim, flFreezePeriod)
}