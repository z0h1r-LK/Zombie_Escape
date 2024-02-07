#include <amxmodx>
#include <reapi>

#include <ze_core>
#include <ini_file>

// HUD Position.
const Float:HUD_INFECT_X = 0.2
const Float:HUD_INFECT_Y = -1.0

// Messages ID.
const msg_Damage = 71
const msg_DeathMsg = 83
const msg_ScoreAttrib = 84
const msg_ScreenShake = 97
const msg_ScreenFade = 98

// Effects Flags.
enum (<<=1)
{
	FLAG_NOTICE = 1,
	FLAG_FADE,
	FLAG_SHAKE,
	FLAG_LIGHT,
	FLAG_GIBS,
	FLAG_ICON,
	FLAG_SND_COMING,
	FLAG_SND_INFECT,
	FLAG_PARTICLES
}

// Enum (Array Colors)
enum any:Colors
{
	Red = 0,
	Green,
	Blue
}

// Cvars.
new g_szFlags[16],
	g_iParticleColor,
	g_iFadeColors[Colors],
	g_iNoticeColors[Colors],
	g_iLightColors[Colors],
	bool:g_bGreenSkullIcon

// Variables.
new g_iGibsSpr,
	g_iInfectMsg

// Dynamic Array.
new Array:g_aComingSounds,
	Array:g_aInfectSounds

public plugin_precache()
{
	// Create new dyn Array.
	g_aComingSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aInfectSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Default infection gibs.
	new szInfectGibs[MAX_RESOURCE_PATH_LENGTH] = "sprites/flare6.spr"

	// Load infection gibs sprite from INI file.
	if (!ini_read_string(ZE_FILENAME, "Sprites", "INFECTION_GIBS", szInfectGibs, charsmax(szInfectGibs)))
		ini_write_string(ZE_FILENAME, "Sprites", "INFECTION_GIBS", szInfectGibs)

	// Precache Model.
	g_iGibsSpr = precache_model(szInfectGibs)

	// Default infection & coming sounds.
	new const szInfectSounds[][] = { "ze/zombi_infect_1.wav", "ze/zombie_infect_2.wav" }
	new const szComingSounds[][] = { "ze/zombi_coming_1.wav", "ze/zombie_coming_2.wav", "ze/zombie_coming_3.wav" }

	new i

	// Load Infection and Coming sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "INFECT", g_aInfectSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "COMING", g_aComingSounds)

	if (!ArraySize(g_aInfectSounds))
	{
		for (i = 0; i < sizeof(szInfectSounds); i++)
			ArrayPushString(g_aInfectSounds, szInfectSounds[i])

		// Save Infection sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "INFECT", g_aInfectSounds)
	}

	if (!ArraySize(g_aComingSounds))
	{
		for (i = 0; i < sizeof(szComingSounds); i++)
			ArrayPushString(g_aComingSounds, szComingSounds[i])

		// Save Coming sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "COMING", g_aComingSounds)
	}

	new szSound[MAX_RESOURCE_PATH_LENGTH], iArraySize

	// Get the number of the sounds on dyn array.
	iArraySize = ArraySize(g_aInfectSounds)

	for (i = 0; i < iArraySize; i++)
	{
		ArrayGetString(g_aInfectSounds, i, szSound, charsmax(szSound))

		// Precache Sound.
		precache_sound(szSound)
	}

	// Get the number of the sounds on dyn array.
	iArraySize = ArraySize(g_aComingSounds)

	for (i = 0; i < iArraySize; i++)
	{
		ArrayGetString(g_aComingSounds, i, szSound, charsmax(szSound))

		// Precache Sound.
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}
}

public plugin_init()
{
	// Load plugin.
	register_plugin("[ZE] Infection Effects", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_string(register_cvar("ze_infection_flags", "abcdefgh"), g_szFlags, charsmax(g_szFlags))
	bind_pcvar_num(register_cvar("ze_infect_notice_red", "200"), g_iNoticeColors[Red])
	bind_pcvar_num(register_cvar("ze_infect_notice_green", "0"), g_iNoticeColors[Green])
	bind_pcvar_num(register_cvar("ze_infect_notice_blue", "0"), g_iNoticeColors[Blue])
	bind_pcvar_num(register_cvar("ze_infect_fade_red", "0"), g_iFadeColors[Red])
	bind_pcvar_num(register_cvar("ze_infect_fade_green", "200"), g_iFadeColors[Green])
	bind_pcvar_num(register_cvar("ze_infect_fade_blue", "0"), g_iFadeColors[Blue])
	bind_pcvar_num(register_cvar("ze_infect_light_red", "0"), g_iLightColors[Red])
	bind_pcvar_num(register_cvar("ze_infect_light_green", "200"), g_iLightColors[Green])
	bind_pcvar_num(register_cvar("ze_infect_light_blue", "0"), g_iLightColors[Blue])
	bind_pcvar_num(register_cvar("ze_infect_particles", "247"), g_iParticleColor)
	bind_pcvar_num(register_cvar("ze_infect_green_skull", "1"), g_bGreenSkullIcon)

	// Set Values.
	g_iInfectMsg = CreateHudSyncObj()
}

public plugin_end()
{
	// Free the Memory.
	ArrayDestroy(g_aComingSounds)
	ArrayDestroy(g_aInfectSounds)
}

public ze_user_infected(iVictim, iInfector)
{
	if (!g_szFlags[0])
		return

	static szSound[MAX_RESOURCE_PATH_LENGTH], bitsFlags; bitsFlags = read_flags(g_szFlags)
	szSound = NULL_STRING

	// Get player's origin.
	static vOrigin[3]
	get_user_origin(iVictim, vOrigin, Origin_Client)

	// Notice Message.
	if (iInfector)
	{
		if (bitsFlags & FLAG_NOTICE)
		{
			static szVicName[MAX_NAME_LENGTH], szInfName[MAX_NAME_LENGTH]
			szVicName = NULL_STRING, szInfName = NULL_STRING

			// Get victim and infector name.
			get_user_name(iVictim, szVicName, charsmax(szVicName))
			get_user_name(iInfector, szInfName, charsmax(szInfName))

			// Send colored HUD message for everyone.
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], HUD_INFECT_X, HUD_INFECT_Y, 1, 3.0, 3.0, 0.1, 0.1)
			ShowSyncHudMsg(0, g_iInfectMsg, "%L", LANG_PLAYER, "HUD_INFECT_NOTICE", szVicName, szInfName)
		}
	}

	// Fade Screen.
	if (bitsFlags & FLAG_FADE)
	{
		message_begin(MSG_ONE_UNRELIABLE, msg_ScreenFade, .player = iVictim)
		write_short(BIT(11)) // Duration.
		write_short(0) // Hold time.
		write_short(0) // Fade type.
		write_byte(g_iFadeColors[Red]) // Red.
		write_byte(g_iFadeColors[Green]) // Green.
		write_byte(g_iFadeColors[Blue]) // Blue.
		write_byte(100) // Alpha.
		message_end()
	}

	// Shake Screen.
	if (bitsFlags & FLAG_SHAKE)
	{
		message_begin(MSG_ONE_UNRELIABLE, msg_ScreenShake, .player = iVictim)
		write_short(2 * BIT(12)) // Duration.
		write_short(6 * BIT(12)) // Amplitude.
		write_short(3 * BIT(12)) // Frequence.
		message_end()
	}

	// Dynamic Light.
	if (bitsFlags & FLAG_LIGHT)
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, vOrigin)
		write_byte(TE_DLIGHT) // TE id.
		write_coord(vOrigin[0]) // Position X.
		write_coord(vOrigin[1]) // Position Y.
		write_coord(vOrigin[2]) // Position Z.
		write_byte(8) // Radius.
		write_byte(g_iLightColors[Red]) // Red.
		write_byte(g_iLightColors[Green]) // Green.
		write_byte(g_iLightColors[Blue]) // Blue.
		write_byte(2) // Life time.
		write_byte(0) // Decay Rate.
		message_end()
	}

	// Infection Gibs.
	if (bitsFlags & FLAG_GIBS)
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, vOrigin)
		write_byte(TE_SPRITETRAIL) // TE id.
		write_coord(vOrigin[0]) // Start Position X
		write_coord(vOrigin[1]) // Start Position Y
		write_coord(vOrigin[2]) // Start Position Z
		write_coord(vOrigin[0]) // End Position X
		write_coord(vOrigin[1]) // End Position Y
		write_coord(vOrigin[2] + 16) // End Position Z
		write_short(g_iGibsSpr) // Sprite index
		write_byte(10) // Count
		write_byte(5) // Life time
		write_byte(2) // Scale
		write_byte(32) // Velocity
		write_byte(0) // Randomly Velocity
		message_end()
	}

	// Infection icon.
	if (bitsFlags & FLAG_ICON)
	{
		message_begin(MSG_ONE_UNRELIABLE, msg_Damage, .player = iVictim)
		write_byte(0) // Damage Take
		write_byte(0) // Damage Save
		write_long(DMG_PARALYZE|DMG_NERVEGAS) // Damage Type
		write_coord(0) // X
		write_coord(0) // Y
		write_coord(0) // Z
		message_end()
	}

	// Coming Sounds.
	if (bitsFlags & FLAG_SND_COMING)
	{
		// Get randomly coming sound from dynamic array.
		ArrayGetString(g_aComingSounds, random_num(0, ArraySize(g_aComingSounds) - 1), szSound, charsmax(szSound))

		// Send Audio to everyone.
		client_cmd(0, "speak ^"%s^"", szSound)
	}

	// Infection Sounds.
	if (bitsFlags & FLAG_SND_INFECT)
	{
		// Get randomly infection sound from dynamic array.
		ArrayGetArray(g_aInfectSounds, random_num(0, ArraySize(g_aInfectSounds) - 1), szSound, charsmax(szSound))

		// Play emit sound (Infection Sound)
		emit_sound(iVictim, CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}

	if (bitsFlags & FLAG_PARTICLES)
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, vOrigin)
		write_byte(TE_PARTICLEBURST) // TE id.
		write_coord(vOrigin[0]) // Position X.
		write_coord(vOrigin[1]) // Position Y.
		write_coord(vOrigin[2]) // Position Z.
		write_short(32) // Radius.
		write_byte(g_iParticleColor) // Color.
		write_byte(2) // Duration.
		message_end()
	}

	// Send death message to everyone.
	message_begin(MSG_ALL, msg_DeathMsg)
	write_byte(iInfector) // Attacker.
	write_byte(iVictim) // Victim.
	write_byte(0) // 1 = Headshot.
	write_string(g_bGreenSkullIcon ? "teammate" : "claws") // Weapon Name.
	message_end()

	// Fix Dead attrib on Scoreboard
	message_begin(MSG_ALL, msg_ScoreAttrib)
	write_byte(iVictim) // Client index.
	write_byte(0) // 0 - None | 1 - Dead
	message_end()
}