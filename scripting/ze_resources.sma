#include <amxmodx>

#include <ze_core>
#include <ini_file>

// Defines.
#define BEGIN_SOUNDS
#define READY_SOUNDS

// Dynamic Arrays.
#if defined BEGIN_SOUNDS
new Array:g_aBeginSounds
#endif

#if defined READY_SOUNDS
new Array:g_aReadySounds
#endif

public plugin_precache()
{
	new szSound[MAX_RESOURCE_PATH_LENGTH], iFiles, i

#if defined BEGIN_SOUNDS
	// Default Begin sound.
	new const szBeginSounds[][] = {"zm_es/ze_begin_1.wav"}

	// Create new dyn Arrays.
	g_aBeginSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read all sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "BEGIN_SOUNDS", g_aBeginSounds)

	if (!ArraySize(g_aBeginSounds))
	{
		for (i = 0; i < sizeof(szBeginSounds); i++)
			ArrayPushString(g_aBeginSounds, szBeginSounds[i])

		// Write Begin sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "BEGIN_SOUNDS", g_aBeginSounds)
	}

	iFiles = ArraySize(g_aBeginSounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aBeginSounds, i, szSound, charsmax(szSound))
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}
#endif

#if defined READY_SOUNDS
	// Default Ready sound.
	new const szReadySounds[][] = {"zm_es/ze_ready_1.mp3"}

	// Create new dyn Arrays.
	g_aReadySounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read Ready sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "READY_SOUNDS", g_aReadySounds)

	if (!ArraySize(g_aReadySounds))
	{
		for (i = 0; i < sizeof(g_aReadySounds); i++)
			ArrayPushString(g_aReadySounds, szReadySounds[i])

		// Write Ready sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "READY_SOUNDS", g_aReadySounds)
	}

	iFiles = ArraySize(g_aReadySounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aReadySounds, i, szSound, charsmax(szSound))
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}
#endif
}

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Resources", ZE_VERSION, ZE_AUTHORS)
}

public ze_game_started()
{
	new szSound[MAX_RESOURCE_PATH_LENGTH]

#if defined BEGIN_SOUNDS
	// Play Begin sound for everyone.
	ArrayGetString(g_aBeginSounds, random_num(0, ArraySize(g_aBeginSounds) - 1), szSound, charsmax(szSound))
	PlaySound(0, szSound)
#endif

#if defined READY_SOUNDS
	// Play Ready sound for everyone.
	ArrayGetString(g_aReadySounds, random_num(0, ArraySize(g_aReadySounds) - 1), szSound, charsmax(szSound))
	PlaySound(0, szSound)
#endif
}