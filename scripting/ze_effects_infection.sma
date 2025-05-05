#include <amxmodx>
#include <reapi>

#include <ze_core>
#include <ini_file>

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
	FLAG_PARTICLES,
	FLAG_THUNDER,
	FLAG_TRACERS
}

// Enum (Array Colors)
enum any:Colors
{
	Red = 0,
	Green,
	Blue
}

enum _:HUDs
{
	Float:HUD_INFECT_X = 0,
	Float:HUD_INFECT_Y
}

// Cvars.
new g_szFlags[16],
	g_iThunderSize,
	g_iThunderNoise,
	g_iThunderAlpha,
	g_iTracersCount,
	g_iTracersRadius,
	g_iParticleColor,
	g_iFadeColors[Colors],
	g_iNoticeColors[Colors],
	g_iLightColors[Colors],
	g_iThunderColors[Colors],
	bool:g_bGreenSkullIcon

// Xvars.
public x_bBlockInfectEff;

// Variables.
new g_iGibsSpr,
	g_iBeamSpr,
	g_iInfectMsg,
	g_iMsgDamage,
	g_iMsgDeathMsg,
	g_iMsgScoreAttrib,
	g_iMsgScreenShake,
	g_iMsgScreenFade

// Array.
new Float:g_flHudPosit[HUDs]

// Dynamic Array.
new Array:g_aComingSounds,
	Array:g_aInfectSounds,
	Array:g_aThunderSounds

public plugin_precache()
{
	// Create new dyn Array.
	g_aComingSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aInfectSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aThunderSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Default infection effects sprites.
	new szInfectGibs[MAX_RESOURCE_PATH_LENGTH] = "sprites/flare6.spr"
	new szThunderBeam[MAX_RESOURCE_PATH_LENGTH] = "sprites/laserbeam.spr"

	// Load sprites from INI file.
	if (!ini_read_string(ZE_FILENAME, "Sprites", "INFECTION_GIBS", szInfectGibs, charsmax(szInfectGibs)))
		ini_write_string(ZE_FILENAME, "Sprites", "INFECTION_GIBS", szInfectGibs)
	if (!ini_read_string(ZE_FILENAME, "Sprites", "THUNDER_SPRITE", szThunderBeam, charsmax(szThunderBeam)))
		ini_write_string(ZE_FILENAME, "Sprites", "THUNDER_SPRITE", szThunderBeam)

	// Precache Model.
	g_iGibsSpr = precache_model(szInfectGibs)
	g_iBeamSpr = precache_model(szThunderBeam)

	// Default infection & coming sounds.
	new const szInfectSounds[][] = { "zm_es/zombi_infect_1.wav", "zm_es/zombie_infect_2.wav" }
	new const szComingSounds[][] = { "zm_es/zombi_coming_1.wav", "zm_es/zombie_coming_2.wav", "zm_es/zombie_coming_3.wav" }
	new const szThunderSounds[][] = { "ambience/thunder_clap.wav" }

	new i

	// Load Infection, Coming and Thunder Clap sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "INFECT", g_aInfectSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "COMING", g_aComingSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "THUNDER", g_aThunderSounds)

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

	if (!ArraySize(g_aThunderSounds))
	{
		for (i = 0; i < sizeof(szThunderSounds); i++)
			ArrayPushString(g_aThunderSounds, szThunderSounds[i])

		// Save Coming sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "THUNDER", g_aThunderSounds)
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

	// Get the number of the sounds on dyn array.
	iArraySize = ArraySize(g_aThunderSounds)

	for (i = 0; i < iArraySize; i++)
	{
		ArrayGetString(g_aThunderSounds, i, szSound, charsmax(szSound))

		// Precache Sound.
		precache_sound(szSound)
	}
}

public plugin_init()
{
	// Load plugin.
	register_plugin("[ZE] Infection Effects", ZE_VERSION, ZE_AUTHORS)

	// Cvars.
	bind_pcvar_string(register_cvar("ze_infection_flags", "abcdefghijk"), g_szFlags, charsmax(g_szFlags))
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
	bind_pcvar_num(register_cvar("ze_infect_thunder_size", "32"), g_iThunderSize)
	bind_pcvar_num(register_cvar("ze_infect_thunder_red", "120"), g_iThunderColors[Red])
	bind_pcvar_num(register_cvar("ze_infect_thunder_green", "120"), g_iThunderColors[Green])
	bind_pcvar_num(register_cvar("ze_infect_thunder_blue", "120"), g_iThunderColors[Blue])
	bind_pcvar_num(register_cvar("ze_infect_thunder_noise", "32"), g_iThunderNoise)
	bind_pcvar_num(register_cvar("ze_infect_thunder_alpha", "200"), g_iThunderAlpha)
	bind_pcvar_num(register_cvar("ze_infect_tracers_count", "100"), g_iTracersCount)
	bind_pcvar_num(register_cvar("ze_infect_tracers_radius", "120"), g_iTracersRadius)

	// Set Values.
	x_bBlockInfectEff = 0
	g_iMsgDamage = get_user_msgid("Damage")
	g_iMsgDeathMsg = get_user_msgid("DeathMsg")
	g_iMsgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_iMsgScreenShake = get_user_msgid("ScreenShake")
	g_iMsgScreenFade = get_user_msgid("ScreenFade")
	g_iInfectMsg = CreateHudSyncObj()
}

public plugin_cfg()
{
	g_flHudPosit[HUD_INFECT_X] = 0.2
	g_flHudPosit[HUD_INFECT_Y] = -1.0

	// Read HUD positions from INI file.
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_INFECT_X", g_flHudPosit[HUD_INFECT_X]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_INFECT_X", g_flHudPosit[HUD_INFECT_X])
	if (!ini_read_float(ZE_FILENAME, "HUDs", "HUD_INFECT_Y", g_flHudPosit[HUD_INFECT_Y]))
		ini_write_float(ZE_FILENAME, "HUDs", "HUD_INFECT_Y", g_flHudPosit[HUD_INFECT_Y])
}

public plugin_end()
{
	// Free the Memory.
	ArrayDestroy(g_aComingSounds)
	ArrayDestroy(g_aInfectSounds)
	ArrayDestroy(g_aThunderSounds)
}

public ze_user_infected_ex(iVictim, iInfector, iHeadshot)
{
	if (!g_szFlags[0] || x_bBlockInfectEff == ZE_INFECT_ALWAYS)
		return

	if (x_bBlockInfectEff == ZE_INFECT_ONCE)
	{
		x_bBlockInfectEff = 0
		return
	}

	static szSound[MAX_RESOURCE_PATH_LENGTH], bitsFlags; bitsFlags = read_flags(g_szFlags)
	szSound = NULL_STRING

	// Get player's origin.
	static vOrigin[3]; vOrigin = { 0, 0, 0 }
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

			static szMessage[256]
			formatex(szMessage, charsmax(szMessage), "%L", LANG_PLAYER, "HUD_INFECT_NOTICE")

			replace_string(szMessage, charsmax(szMessage), "{$VICTIM}", szVicName)
			replace_string(szMessage, charsmax(szMessage), "{$ATTACKER}", szInfName)

			// Send colored HUD message for everyone.
			set_hudmessage(g_iNoticeColors[Red], g_iNoticeColors[Green], g_iNoticeColors[Blue], g_flHudPosit[HUD_INFECT_X], g_flHudPosit[HUD_INFECT_Y], 1, 3.0, 3.0, 0.1, 0.1)
			ShowSyncHudMsg(0, g_iInfectMsg, szMessage)
			szMessage = NULL_STRING
		}
	}

	// Fade Screen.
	if (bitsFlags & FLAG_FADE)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgScreenFade, .player = iVictim)
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
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgScreenShake, .player = iVictim)
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
		message_begin(MSG_ONE_UNRELIABLE, g_iMsgDamage, .player = iVictim)
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

	// Particles burst.
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

	// Thunder.
	if (bitsFlags & FLAG_THUNDER)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMPOINTS) // TE id.
		write_coord(vOrigin[0]) // Start Position X.
		write_coord(vOrigin[1]) // Start Position Y.
		write_coord(2048) // Start Position Z.
		write_coord(vOrigin[0]) // End Position X.
		write_coord(vOrigin[1]) // End Position Y.
		write_coord(vOrigin[2]) // End Position Z.
		write_short(g_iBeamSpr) // Sprite index.
		write_byte(0) // Frame.
		write_byte(0) // Frame rate.
		write_byte(8) // Duration.
		write_byte(g_iThunderSize) // Width.
		write_byte(g_iThunderNoise) // Noise amplitude.
		write_byte(g_iThunderColors[Red]) // Red.
		write_byte(g_iThunderColors[Green]) // Green.
		write_byte(g_iThunderColors[Blue]) // Blue.
		write_byte(g_iThunderAlpha) // Brightness.
		write_byte(-75) // Scroll Speed.
		message_end()

		// Play thunder sound for everyone.
		ArrayGetString(g_aThunderSounds, random_num(0, ArraySize(g_aThunderSounds) - 1), szSound, charsmax(szSound))
		emit_sound(iVictim, CHAN_WEAPON, szSound, VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
	}

	// Tracers.
	if (bitsFlags & FLAG_TRACERS)
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, vOrigin)
		write_byte(TE_IMPLOSION) // TE id.
		write_coord(vOrigin[0]) // Position X.
		write_coord(vOrigin[1]) // Position Y.
		write_coord(vOrigin[2]) // Position Z.
		write_byte(g_iTracersRadius) // Radius.
		write_byte(g_iTracersCount) // Count.
		write_byte(4) // Duration.
		message_end()
	}

	// Send death message to everyone.
	message_begin(MSG_ALL, g_iMsgDeathMsg)
	write_byte(iInfector) // Attacker.
	write_byte(iVictim) // Victim.
	write_byte(iHeadshot) // 1 = Headshot.
	write_string(g_bGreenSkullIcon ? "teammate" : "claws") // Weapon Name.
	message_end()

	// Fix Dead attrib on Scoreboard
	message_begin(MSG_ALL, g_iMsgScoreAttrib)
	write_byte(iVictim) // Client index.
	write_byte(0) // 0 - None | 1 - Dead
	message_end()
}