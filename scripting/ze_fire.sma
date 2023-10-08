#include <amxmodx>
#include <engine>
#include <reapi>

#include <ze_core>
#include <ini_file>
#include <ze_weap_models_api>

// Defines.
#define FIRE_RADIUS 240.0
#define FIRE_RING_PERIOD 1
#define FIRE_RING_AXIS_X 240
#define FIRE_RING_AXIS_Y 240
#define FIRE_RING_AXIS_Z 2400

#define TASK_BURNING 100

#define GRENADE_ID 3333

// Forwards.
enum _:FORWARDS
{
	FORWARD_FIRE_BURN_START = 0,
	FORWARD_FIRE_BURN_END
}

// Fire-Nade Models.
new g_v_szFireModel[MAX_RESOURCE_PATH_LENGTH] = "models/v_hegrenade.mdl"
new g_p_szFireModel[MAX_RESOURCE_PATH_LENGTH] = "models/p_hegrenade.mdl"
new g_w_szFireModel[MAX_RESOURCE_PATH_LENGTH] = "models/w_hegrenade.mdl"

// Cvars.
new bool:g_bFireIcon,
	Float:g_flSlowdown,
	Float:g_flFireDamage,
	Float:g_flFirePeriod

// Variables.
new g_iRingSpr,
	g_iFwReturn,
	g_iTrailSpr,
	g_iFlameSpr,
	g_iSmokeSpr,
	g_iMsgDamage,
	g_bitsIsBurning

// Array.
new g_iForwards[FORWARDS],
	Float:g_flBurnTime[MAX_PLAYERS+1]

// Dynamic Array.
new Array:g_aFireExplodeSounds,
	Array:g_aBurningZombieSounds

public plugin_natives()
{
	register_native("ze_zombie_in_fire", "__native_zombie_in_fire")
	register_native("ze_set_user_fire", "__native_set_user_fire")
	register_native("ze_set_user_fire_ex", "__native_set_user_fire_ex")
}

public plugin_precache()
{
	new szRingSprite[MAX_RESOURCE_PATH_LENGTH] = "sprites/shockwave.spr"
	new szTrailSprite[MAX_RESOURCE_PATH_LENGTH] = "sprites/laserbeam.spr"
	new szFlameSprite[MAX_RESOURCE_PATH_LENGTH] = "sprites/flame.spr"
	new szSmokeSprite[MAX_RESOURCE_PATH_LENGTH] = "sprites/black_smoke1.spr"

	// Read Fire-Nade models from INI file.
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "V_FIRENADE", g_v_szFireModel, charsmax(g_v_szFireModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "V_FIRENADE", g_v_szFireModel)
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "P_FIRENADE", g_p_szFireModel, charsmax(g_p_szFireModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "P_FIRENADE", g_p_szFireModel)
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "W_FIRENADE", g_w_szFireModel, charsmax(g_w_szFireModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "W_FIRENADE", g_w_szFireModel)

	// Read Fire-Nade resources from INI file.
	if (!ini_read_string(ZE_FILENAME, "Grenades Effects", "FIRE_RING", szRingSprite, charsmax(szRingSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Effects", "FIRE_RING", szRingSprite)
	if (!ini_read_string(ZE_FILENAME, "Grenades Effects", "FIRE_TRAIL", szTrailSprite, charsmax(szTrailSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Effects", "FIRE_TRAIL", szTrailSprite)
	if (!ini_read_string(ZE_FILENAME, "Grenades Resources", "FLAME", szFlameSprite, charsmax(szFlameSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Resources", "FLAME", szFlameSprite)
	if (!ini_read_string(ZE_FILENAME, "Grenades Resources", "SMOKE", szSmokeSprite, charsmax(szSmokeSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Resources", "SMOKE", szSmokeSprite)

	// Create new dynamic Arrays.
	g_aFireExplodeSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aBurningZombieSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read Fire-Nade sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "FIRE_EXPLODE", g_aFireExplodeSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "BURNING_ZOMBIE", g_aBurningZombieSounds)

	// Default Fire-Nade sounds.
	new const szFireZombieSounds[][] = {"weapons/hegrenade-1.wav", "weapons/hegrenade-2.wav"}
	new const szBurningZombieSounds[][] = {"zm_es/zombi_burn_1.wav", "zm_es/zombi_burn_2.wav", "zm_es/zombi_burn_3.wav", "zm_es/zombi_burn_4.wav", "zm_es/zombi_burn_5.wav"}

	new i

	if (!ArraySize(g_aFireExplodeSounds))
	{
		for (i = 0; i < sizeof(szFireZombieSounds); i++)
			ArrayPushString(g_aFireExplodeSounds, szFireZombieSounds[i])

		// Write Fire-Nade sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "FIRE_EXPLODE", g_aFireExplodeSounds)
	}

	if (!ArraySize(g_aBurningZombieSounds))
	{
		for (i = 0; i < sizeof(szBurningZombieSounds); i++)
			ArrayPushString(g_aBurningZombieSounds, szBurningZombieSounds[i])

		// Write Fire-Nade sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "BURNING_ZOMBIE", g_aBurningZombieSounds)
	}

	// Precache Models.
	precache_model(g_v_szFireModel)
	precache_model(g_p_szFireModel)
	precache_model(g_w_szFireModel)

	g_iRingSpr = precache_model(szRingSprite)
	g_iTrailSpr = precache_model(szTrailSprite)
	g_iFlameSpr = precache_model(szFlameSprite)
	g_iSmokeSpr = precache_model(szSmokeSprite)

	new szSound[MAX_RESOURCE_PATH_LENGTH], iFiles

	// Precache Sounds.
	iFiles = ArraySize(g_aFireExplodeSounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aFireExplodeSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}

	iFiles = ArraySize(g_aBurningZombieSounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aBurningZombieSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Grenade: Fire", ZE_VERSION, ZE_AUTHORS)

	// Hook Chains.
	RegisterHookChain(RG_ThrowHeGrenade, "fw_GrenadeThrown_Post", 1)
	RegisterHookChain(RG_CGrenade_ExplodeHeGrenade, "fw_GrenadeExploded_Pre")

	// Cvars.
	bind_pcvar_num(register_cvar("ze_fire_icon", "1"), g_bFireIcon)
	bind_pcvar_float(register_cvar("ze_fire_damage", "2.0"), g_flFireDamage)
	bind_pcvar_float(register_cvar("ze_fire_period", "3.0"), g_flFirePeriod)
	bind_pcvar_float(register_cvar("ze_fire_slowdown", "0.1"), g_flSlowdown)

	// Create Forwards.
	g_iForwards[FORWARD_FIRE_BURN_START] = CreateMultiForward("ze_fire_burn_start", ET_CONTINUE, FP_CELL)
	g_iForwards[FORWARD_FIRE_BURN_END] = CreateMultiForward("ze_fire_burn_end", ET_CONTINUE, FP_CELL)

	// Set Values.
	g_iMsgDamage = get_user_msgid("Damage")
}

public plugin_end()
{
	// Free the Memory.
	DestroyForward(g_iForwards[FORWARD_FIRE_BURN_START])
	DestroyForward(g_iForwards[FORWARD_FIRE_BURN_END])
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	// HLTV Proxy?
	if (is_user_hltv(id))
		return

	// Turn off the Flame.
	g_flBurnTime[id] = 0.0
	remove_task(id+TASK_BURNING)
	flag_unset(g_bitsIsBurning, id)
}

public ze_user_humanized(id)
{
	// Turn off the Flame.
	g_flBurnTime[id] = 0.0
	remove_task(id+TASK_BURNING)
	flag_unset(g_bitsIsBurning, id)
}

public ze_user_killed_post(iVictim, iAttacker, iGibs)
{
	// Turn off the Flame.
	g_flBurnTime[iVictim] = 0.0
	remove_task(iVictim+TASK_BURNING)
	flag_unset(g_bitsIsBurning, iVictim)
}

public fw_GrenadeThrown_Post(const id)
{
	if (!is_user_alive(id))
		return

	// Get grenade entity.
	new iEnt = GetHookChainReturn(ATYPE_INTEGER)

	if (is_nullent(iEnt))
		return

	// Set entity World Model.
	entity_set_model(iEnt, g_w_szFireModel)

	// Set entity unique id.
	set_entvar(iEnt, var_impulse, GRENADE_ID)

	// Set entity Glow Shell.
	set_ent_rendering(iEnt, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 10)

	// Grenade Trail.
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id.
	write_short(iEnt) // Entity ID.
	write_short(g_iTrailSpr) // Sprite Index.
	write_byte(5) // Duration.
	write_byte(5) // Width.
	write_byte(200) // Red.
	write_byte(0) // Green.
	write_byte(0) // Blue.
	write_byte(255) // Brightness.
	message_end()
}

public fw_GrenadeExploded_Pre(const iEnt)
{
	if (is_nullent(iEnt))
		return HC_CONTINUE

	// Fire Nade?
	if (get_entvar(iEnt, var_impulse) != GRENADE_ID)
		return HC_CONTINUE

	fire_Explode(iEnt)

	// Remove entity.
	remove_entity(iEnt)
	return HC_SUPERCEDE // Prevent property of Grenade.
}

public fire_Explode(const iEnt)
{
	new Float:vOrigin[3]

	// Get entity's origin.
	get_entvar(iEnt, var_origin, vOrigin)

	// Search victims.
	new iPlayers[MAX_PLAYERS], victim
	new iAliveNum = find_sphere_class(0, "player", FIRE_RADIUS, iPlayers, MAX_PLAYERS, vOrigin)

	// Burn victims.
	for (new i = 0; i < iAliveNum; i++)
	{
		victim = iPlayers[i]

		// Is Zombie?
		if (!ze_is_user_zombie(victim))
			continue

		// Call forward ze_fire_burn_start(id) and get return value.
		ExecuteForward(g_iForwards[FORWARD_FIRE_BURN_START], g_iFwReturn, victim)

		if (g_iFwReturn >= ZE_STOP)
			continue

		// Burn the player.
		flag_set(g_bitsIsBurning, victim)
		g_flBurnTime[victim] = g_flFirePeriod

		// Task repeat damage the player.
		set_task(0.1, "burn_Player", victim+TASK_BURNING, .flags = "b")
	}

	// Ring effect.
	message_begin_f(MSG_PVS, SVC_TEMPENTITY, vOrigin)
	write_byte(TE_BEAMCYLINDER) // TE id.
	write_coord_f(vOrigin[0]) // Position X.
	write_coord_f(vOrigin[1]) // Position Y.
	write_coord_f(vOrigin[2] + 64.0) // Position Z.
	write_coord(FIRE_RING_AXIS_X) // Axis X.
	write_coord(FIRE_RING_AXIS_Y) // Axis Y.
	write_coord(FIRE_RING_AXIS_Z) // Axis Z.
	write_short(g_iRingSpr) // Sprite Index.
	write_byte(0) // Frame.
	write_byte(0) // Frame rate.
	write_byte(FIRE_RING_PERIOD) // Duration.
	write_byte(64) // Width.
	write_byte(0) // Noise.
	write_byte(200) // Red.
	write_byte(0) // Green.
	write_byte(0) // Blue.
	write_byte(255) // Brightness.
	write_byte(0) // Scroll Speed.
	message_end()

	// Emit explode sound.
	new szSound[MAX_RESOURCE_PATH_LENGTH]
	ArrayGetString(g_aBurningZombieSounds, random_num(0, ArraySize(g_aFireExplodeSounds) - 1), szSound, charsmax(szSound))
	emit_sound(iEnt, CHAN_WEAPON, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public burn_Player(iVictim)
{
	iVictim -= TASK_BURNING

	// Get player's origin.
	static vOrigin[3]; vOrigin = { 0, 0, 0 }
	get_user_origin(iVictim, vOrigin, Origin_Client)

	// -100ms
	g_flBurnTime[iVictim] -= 0.1

	// Turn off the Fire.
	if (g_flBurnTime[iVictim] <= 0.0)
	{
		// Turn off the Smoke.
		smoke_Effect(vOrigin, iVictim)
		return
	}

	static bitsFlags; bitsFlags = get_entvar(iVictim, var_flags)

	// In Water?
	if (bitsFlags & FL_INWATER)
	{
		// Turn off the Smoke.
		smoke_Effect(vOrigin, iVictim)
		return
	}

	if (g_flSlowdown != 1.0)
	{
		if (bitsFlags & FL_ONGROUND)
		{
			static Float:vSpeed[3]; vSpeed = NULL_VECTOR
			get_entvar(iVictim, var_velocity, vSpeed)

			// Slowdown.
			vSpeed[0] *= g_flSlowdown
			vSpeed[1] *= g_flSlowdown
			vSpeed[2] *= g_flSlowdown

			// Set player new Velocity.
			set_entvar(iVictim, var_velocity, vSpeed)
		}
	}

	static Float:flHealth; flHealth = get_entvar(iVictim, var_health)
	if (flHealth - g_flFireDamage > 1.0)
	{
		// Damage victim.
		set_entvar(iVictim, var_health, flHealth - g_flFireDamage)
	}

	// Fire Icon?
	if (g_bFireIcon)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgDamage, .player = iVictim)
		write_byte(0) // Damage Save.
		write_byte(0) // Damage Take.
		write_long(DMG_BURN) // Damage Type.
		write_coord(0) // Position X.
		write_coord(0) // Position Y.
		write_coord(0) // Position Z.
		message_end()
	}

	if (random(16) == 1)
	{
		static szSound[MAX_RESOURCE_PATH_LENGTH]; szSound = NULL_STRING
		ArrayGetString(g_aBurningZombieSounds, random_num(0, ArraySize(g_aBurningZombieSounds) - 1), szSound, charsmax(szSound))

		// Emit pain sound.
		emit_sound(iVictim, CHAN_VOICE, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	// Flame Sprite.
	message_begin(MSG_PVS, SVC_TEMPENTITY, vOrigin)
	write_byte(TE_EXPLOSION) // TE id.
	write_coord(vOrigin[0]) // Position X.
	write_coord(vOrigin[1]) // Position Y.
	write_coord(vOrigin[2] - 16) // Position Z.
	write_short(g_iFlameSpr) // Sprite Index.
	write_byte(random_num(5, 10)) // Scale.
	write_byte(random_num(10, 15)) // Frame rate.
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES) // Flags.
	message_end()
}

public smoke_Effect(const vOrigin[3], victim)
{
	// Call forward ze_fire_burn_end(id)
	ExecuteForward(g_iForwards[FORWARD_FIRE_BURN_END], g_iFwReturn, victim)

	if (g_iFwReturn >= ZE_STOP)
		return

	// Remove task.
	remove_task(victim+TASK_BURNING)
	flag_unset(g_bitsIsBurning, victim)

	// Smoke effect.
	message_begin(MSG_PVS, SVC_TEMPENTITY, vOrigin)
	write_byte(TE_SMOKE) // TE id.
	write_coord(vOrigin[0]) // Position X.
	write_coord(vOrigin[1]) // Position Y.
	write_coord(vOrigin[2] - 16) // Position Z.
	write_short(g_iSmokeSpr) // Sprite Index.
	write_byte(15) // Scale.
	write_byte(15) // Frame rate.
	message_end()
}

/**
 * -=| Natives |=-
 */
public __native_zombie_in_fire(plugin_id, num_params)
{
	new id = get_param(1)

	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", id)
		return false
	}

	return true
}

public __native_set_user_fire(plugin_id, num_params)
{
	new victim = get_param(1)

	if (!is_user_connected(victim))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", victim)
		return false
	}

	if (get_param(2))
	{
		// Call forward ze_fire_burn_start(id) and get return value.
		ExecuteForward(g_iForwards[FORWARD_FIRE_BURN_START], g_iFwReturn, victim)

		if (g_iFwReturn >= ZE_STOP)
			return false

		// Burn the player.
		flag_set(g_bitsIsBurning, victim)
		g_flBurnTime[victim] = g_flFirePeriod

		// Task repeat Damage the player.
		set_task(0.1, "burn_Player", victim+TASK_BURNING, .flags = "b")
	}
	else
	{
		g_flBurnTime[victim] = 0.0
		remove_task(victim+TASK_BURNING)
		flag_unset(g_bitsIsBurning, victim)
	}

	return true
}

public ze_set_user_fire_ex(plugin_id, num_params)
{
	new victim = get_param(1)

	if (!is_user_connected(victim))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", victim)
		return false
	}

	new Float:flBurnTime = get_param_f(2)
	if (flag_get_boolean(g_bitsIsBurning, victim))
	{
		g_flBurnTime[victim] += flBurnTime
	}
	else
	{
		// Call forward ze_fire_burn_start(id) and get return value.
		ExecuteForward(g_iForwards[FORWARD_FIRE_BURN_START], g_iFwReturn, victim)

		if (g_iFwReturn >= ZE_STOP)
			return false

		// Burn the player.
		flag_set(g_bitsIsBurning, victim)
		g_flBurnTime[victim] = g_flFirePeriod
		set_task(0.1, "burn_Player", victim+TASK_BURNING, .flags = "b")
	}

	return true
}