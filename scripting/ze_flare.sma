#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <reapi>
#include <ze_core>
#define LIBRARY_WPNMODELS "ze_weap_models_api"

// Macroses.
#define FIsClient(%0) (1<=(%0)<=MaxClients)

// Defines.
#define FLARE_RADIUS 240.0
#define FLARE_RING_PERIOD 1
#define FLARE_RING_AXIS_X 240
#define FLARE_RING_AXIS_Y 240
#define FLARE_RING_AXIS_Z 2400

#define GRENADE_ID 4444

// Flare-Nade Models.
new g_v_szFlareModel[MAX_RESOURCE_PATH_LENGTH] = "models/v_smokegrenade.mdl"
new g_p_szFlareModel[MAX_RESOURCE_PATH_LENGTH] = "models/p_smokegrenade.mdl"
new g_w_szFlareModel[MAX_RESOURCE_PATH_LENGTH] = "models/w_smokegrenade.mdl"

// CVars.
new Float:g_flFlareDamage

// Variables.
new g_iRingSpr,
	g_iTrailSpr,
	g_iForward

// Dynamic Arrays.
new Array:g_aFlareExplodeSounds

public plugin_natives()
{
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

	new szExplodeSounds[][] = {"weapons/explode3.wav", "weapons/explode4.wav", "weapons/explode5.wav"}

	// Create new dyn Array.
	g_aFlareExplodeSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read Flare-Nade models from INI file.
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "V_FLARENADE", g_v_szFlareModel, charsmax(g_v_szFlareModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "V_FLARENADE", g_v_szFlareModel)
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "P_FLARENADE", g_p_szFlareModel, charsmax(g_p_szFlareModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "P_FLARENADE", g_p_szFlareModel)
	if (!ini_read_string(ZE_FILENAME, "Weapon Models", "W_FLARENADE", g_w_szFlareModel, charsmax(g_w_szFlareModel)))
		ini_write_string(ZE_FILENAME, "Weapon Models", "W_FLARENADE", g_w_szFlareModel)

	// Read Flare Nade resources from INI file.
	if (!ini_read_string(ZE_FILENAME, "Grenades Effects", "FLARE_RING", szRingSprite, charsmax(szRingSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Effects", "FLARE_RING", szRingSprite)
	if (!ini_read_string(ZE_FILENAME, "Grenades Effects", "FLARE_TRAIL", szTrailSprite, charsmax(szTrailSprite)))
		ini_write_string(ZE_FILENAME, "Grenades Effects", "FLARE_TRAIL", szTrailSprite)

	// Read Flare-Nade explode sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "FLARE_EXPLODE", g_aFlareExplodeSounds)

	if (!ArraySize(g_aFlareExplodeSounds))
	{
		for (new i = 0; i < sizeof(szExplodeSounds); i++)
			ArrayPushString(g_aFlareExplodeSounds, szExplodeSounds[i])

		// Write Flare-Nade explode sounds from INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "FLARE_EXPLODE", g_aFlareExplodeSounds)
	}

	precache_model(g_p_szFlareModel)
	precache_model(g_v_szFlareModel)
	precache_model(g_w_szFlareModel)

	g_iRingSpr = precache_model(szRingSprite)
	g_iTrailSpr = precache_model(szTrailSprite)

	new szSound[MAX_RESOURCE_PATH_LENGTH], iFiles

	iFiles = ArraySize(g_aFlareExplodeSounds)
	for (new i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aFlareExplodeSounds, i, szSound, charsmax(szSound))
		precache_sound(szSound)
	}
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Grenade: Flare", ZE_VERSION, ZE_AUTHORS)

	// Hook Chains.
	RegisterHookChain(RG_ThrowSmokeGrenade, "fw_GrenadeThrown_Post", 1)

	// Hams.
	RegisterHam(Ham_Think, "grenade", "fw_GrenadeThink_Pre")

	// CVars.
	bind_pcvar_float(register_cvar("ze_flare_damage", "500.0"), g_flFlareDamage)

	// Create Forward.
	g_iForward = CreateMultiForward("ze_grenade_exploded", ET_IGNORE, FP_CELL, FP_CELL, FP_ARRAY)
}

public ze_game_started()
{
	new iEnt = NULLENT
	while ((iEnt = rg_find_ent_by_class(iEnt, "armoury_entity")))
	{
		// SmokeGrenade?
		if (get_member(iEnt, m_Armoury_iItem) == ARMOURY_SMOKEGRENADE)
			entity_set_model(iEnt, g_w_szFlareModel)
	}
}

public ze_user_humanized(id)
{
	if (module_exists(LIBRARY_WPNMODELS))
	{
		// View and Weapon Model.
		ze_set_user_view_model(id, CSW_SMOKEGRENADE, g_v_szFlareModel)
		ze_set_user_weap_model(id, CSW_SMOKEGRENADE, g_p_szFlareModel)
	}
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
	entity_set_model(iEnt, g_w_szFlareModel)

	// Set entity unique id.
	set_entvar(iEnt, var_impulse, GRENADE_ID)

	// Set entity Glow Shell.
	set_ent_rendering(iEnt, kRenderFxGlowShell, 200, 200, 200, kRenderNormal, 10)

	// Grenade Trail.
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id.
	write_short(iEnt) // Entity ID.
	write_short(g_iTrailSpr) // Sprite Index.
	write_byte(5) // Duration.
	write_byte(5) // Width.
	write_byte(200) // Red.
	write_byte(200) // Green.
	write_byte(200) // Blue.
	write_byte(255) // Brightness.
	message_end()
}

public fw_GrenadeThink_Pre(const iEnt)
{
	if (is_nullent(iEnt))
		return HAM_IGNORED

	// Grenade not blow yet?
	if (get_entvar(iEnt, var_dmgtime) > get_gametime())
		return HAM_IGNORED

	// Flare Nade?
	if (get_entvar(iEnt, var_impulse) != GRENADE_ID)
		return HAM_IGNORED

	flare_Explode(iEnt)

	// Remove entity.
	rg_remove_entity(iEnt)
	return HAM_SUPERCEDE // Prevent property of Grenade.
}

public flare_Explode(const iEnt)
{
	new Float:vOrigin[3]

	// Get entity's origin.
	get_entvar(iEnt, var_origin, vOrigin)

	// Call forward ze_flare_exploded(param, array[3])
	ExecuteForward(g_iForward, _/* Ignore return value */, iEnt, FLARE_NADE, PrepareArray(_:vOrigin, 3))

	new Float:flDamage, iAttacker = get_entvar(iEnt, var_owner)

	new iVictim = NULLENT
	while ((iVictim = find_ent_in_sphere(iVictim, vOrigin, FLARE_RADIUS)))
	{
		if (FIsClient(iVictim))
		{
			if (iVictim == iAttacker || !ze_is_user_zombie(iVictim))
				continue

			if (is_user_alive(iVictim))
			{
				flDamage = g_flFlareDamage * (1.0 - (entity_range(iEnt, iVictim) / FLARE_RADIUS))

				if (flDamage < 1.0)
					continue

				// Damage victim.
				ExecuteHamB(Ham_TakeDamage, iVictim, iEnt, iAttacker, flDamage, DMG_GRENADE|DMG_BLAST)
			}
		}
	}

	for (new i = 0; i < 2; i++)
	{
		// Ring effect.
		message_begin_f(MSG_PVS, SVC_TEMPENTITY, vOrigin)
		write_byte(TE_BEAMCYLINDER) // TE id.
		write_coord_f(vOrigin[0]) // Position X.
		write_coord_f(vOrigin[1]) // Position Y.
		write_coord_f(vOrigin[2] + 64.0) // Position Z.
		write_coord_f(vOrigin[0] + FLARE_RING_AXIS_X) // Axis X.
		write_coord_f(vOrigin[1] + FLARE_RING_AXIS_Y) // Axis Y.
		write_coord_f(vOrigin[2] + FLARE_RING_AXIS_Z) // Axis Z.
		write_short(g_iRingSpr) // Sprite Index.
		write_byte(0) // Frame.
		write_byte(0) // Frame rate.
		write_byte(FLARE_RING_PERIOD) // Duration.
		write_byte(64) // Width.
		write_byte(0) // Noise.
		write_byte(200) // Red.
		write_byte(200) // Green.
		write_byte(200) // Blue.
		write_byte(255) // Brightness.
		write_byte(0) // Scroll Speed.
		message_end()
	}

	// Emit explode sound.
	new szSound[MAX_RESOURCE_PATH_LENGTH]
	ArrayGetString(g_aFlareExplodeSounds, random_num(0, ArraySize(g_aFlareExplodeSounds) - 1), szSound, charsmax(szSound))
	emit_sound(iEnt, CHAN_WEAPON, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}