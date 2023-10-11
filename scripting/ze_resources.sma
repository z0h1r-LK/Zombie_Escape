#include <amxmodx>

#include <ze_core>
#include <ini_file>

// Defines.
#define BEGIN_SOUNDS
#define READY_SOUNDS
#define WINS_SOUNDS

// Dynamic Arrays.
#if defined BEGIN_SOUNDS
new Array:g_aBeginSounds
#endif

#if defined READY_SOUNDS
new Array:g_aReadySounds
#endif

#if defined WINS_SOUNDS
new Array:g_aEscapeFailSounds,
	Array:g_aEscapeSuccessSounds
#endif

public plugin_precache()
{
	new szSound[MAX_RESOURCE_PATH_LENGTH], iFiles, i

#if defined BEGIN_SOUNDS
	// Default Begin sound.
	new const szBeginSounds[][] = {"zm_es/ze_newround.wav"}

	// Create new dyn Arrays.
	g_aBeginSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read all sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "BEGIN", g_aBeginSounds)

	if (!ArraySize(g_aBeginSounds))
	{
		for (i = 0; i < sizeof(szBeginSounds); i++)
			ArrayPushString(g_aBeginSounds, szBeginSounds[i])

		// Write Begin sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "BEGIN", g_aBeginSounds)
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
	new const szReadySounds[][] = {"zm_es/ze_ready.mp3"}

	// Create new dyn Arrays.
	g_aReadySounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read Ready sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "READY", g_aReadySounds)

	if (!ArraySize(g_aReadySounds))
	{
		for (i = 0; i < sizeof(g_aReadySounds); i++)
			ArrayPushString(g_aReadySounds, szReadySounds[i])

		// Write Ready sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "READY", g_aReadySounds)
	}

	iFiles = ArraySize(g_aReadySounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aReadySounds, i, szSound, charsmax(szSound))
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}
#endif

#if defined WINS_SOUNDS
	// Default Escape Success/Fail sounds.
	new const szEscapeFailSound[][] = {"zm_es/escape_success.wav"}
	new const szEscapeSucessSound[][] = {"zm_es/escape_fail.wav"}

	// Create new dyn Arrays.
	g_aEscapeFailSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)
	g_aEscapeSuccessSounds = ArrayCreate(MAX_RESOURCE_PATH_LENGTH, 1)

	// Read Escape Success and Fail sounds from INI file.
	ini_read_string_array(ZE_FILENAME, "Sounds", "ESCAPE_FAIL", g_aEscapeFailSounds)
	ini_read_string_array(ZE_FILENAME, "Sounds", "ESCAPE_SUCCESS", g_aEscapeSuccessSounds)

	if (!ArraySize(g_aEscapeFailSounds))
	{
		for (i = 0; i < sizeof(szEscapeFailSound); i++)
			ArrayPushString(g_aEscapeFailSounds, szEscapeFailSound[i])

		// Write Escape Fail sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "ESCAPE_FAIL", g_aEscapeFailSounds)
	}

	if (!ArraySize(g_aEscapeSuccessSounds))
	{
		for (i = 0; i < sizeof(szEscapeSucessSound); i++)
			ArrayPushString(g_aEscapeSuccessSounds, szEscapeSucessSound[i])

		// Write Escape Success sounds on INI file.
		ini_write_string_array(ZE_FILENAME, "Sounds", "ESCAPE_SUCCESS", g_aEscapeSuccessSounds)
	}

	iFiles = ArraySize(g_aEscapeFailSounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aEscapeFailSounds, i, szSound, charsmax(szSound))
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}

	iFiles = ArraySize(g_aEscapeSuccessSounds)
	for (i = 0; i < iFiles; i++)
	{
		ArrayGetString(g_aEscapeSuccessSounds, i, szSound, charsmax(szSound))
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

#if defined WINS_SOUNDS
public ze_roundend(iWinTeam)
{
	switch (iWinTeam)
	{
		case ZE_TEAM_HUMAN:
		{
			new szSound[MAX_RESOURCE_PATH_LENGTH]
			ArrayGetString(g_aEscapeSuccessSounds, random_num(0, ArraySize(g_aEscapeSuccessSounds) - 1), szSound, charsmax(szSound))
			PlaySound(0, szSound)
		}
		case ZE_TEAM_ZOMBIE:
		{
			new szSound[MAX_RESOURCE_PATH_LENGTH]
			ArrayGetString(g_aEscapeFailSounds, random_num(0, ArraySize(g_aEscapeFailSounds) - 1), szSound, charsmax(szSound))
			PlaySound(0, szSound)
		}
	}
}
#endif