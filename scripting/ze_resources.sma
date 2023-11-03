#include <amxmodx>
#include <fakemeta>
#include <ze_core>

// Macroses.
#define FInvalidAmbHandle(%0) (INVALID_HANDLE>=(%0)>=g_iAmbNum)

// Defines.
#define BEGIN_SOUNDS
#define READY_SOUNDS
#define WINS_SOUNDS
#define AMBIENCE_SOUNDS

#if defined AMBIENCE_SOUNDS
#define TASK_AMBIENCE 100

// Enum.
enum _:AMBIENCE_DATA
{
	AMB_NAME[MAX_NAME_LENGTH] = 0,
	AMB_SOUND[MAX_RESOURCE_PATH_LENGTH],
	AMB_LENGTH
}

// Cvars.
new Float:g_flAmbDelay

// Variables.
new g_iAmbNum
#endif
new g_iForward

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

#if defined AMBIENCE_SOUNDS
new Array:g_aAmbienceSounds
#endif

#if defined AMBIENCE_SOUNDS
public plugin_natives()
{
	// Create new dyn Array.
	g_aAmbienceSounds = ArrayCreate(AMBIENCE_DATA, 1)

	register_native("ze_res_ambience_register", "__native_res_ambience_register")
	register_native("ze_res_ambience_play", "__native_res_ambience_play")
}
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

	// Hook Chain.
	register_forward(FM_EmitSound, "fw_EmitSound_Pre")

#if defined AMBIENCE_SOUNDS
	// CVars.
	bind_pcvar_float(get_cvar_pointer("ze_release_time"), g_flAmbDelay)
#endif

	// Create Forwards.
	g_iForward = CreateMultiForward("ze_res_fw_zombie_sound", ET_IGNORE, FP_CELL, FP_CELL, FP_ARRAY)
}

public plugin_end()
{
	// Free the Memory.
	DestroyForward(g_iForward)

	#if defined BEGIN_SOUNDS
	ArrayDestroy(g_aBeginSounds)
	#endif
	#if defined READY_SOUNDS
	ArrayDestroy(g_aReadySounds)
	#endif
	#if defined AMBIENCE_SOUNDS
	ArrayDestroy(g_aAmbienceSounds)
	#endif
	#if defined WINS_SOUNDS
	ArrayDestroy(g_aEscapeFailSounds)
	ArrayDestroy(g_aEscapeSuccessSounds)
	#endif
}

public ze_game_started()
{
	new szSound[MAX_RESOURCE_PATH_LENGTH]

	// Stop all sounds.
	StopSound()

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

#if defined AMBIENCE_SOUNDS
	remove_task(TASK_AMBIENCE)
#endif
}

public ze_roundend(iWinTeam)
{
#if defined WINS_SOUNDS
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
#endif

	// Stop all sounds.
	StopSound()

#if defined AMBIENCE_SOUNDS
	remove_task(TASK_AMBIENCE)
#endif
}

public fw_EmitSound_Pre(const iEnt, iChan, const szSample[], Float:flVol, Float:flAttn, bitsFlags, iPitch)
{
	// Is not Player?
	if (szSample[0] != 'p' && szSample[1] != 'l' && szSample[2] != 'a')
		return FMRES_IGNORED

	// Is not Zombie?
	if (!ze_is_user_zombie(iEnt))
		return FMRES_IGNORED

	static szSound[64]

	// Reset string.
	szSound = NULL_STRING

	// Pain.
	if (szSample[7] == 'b' && szSample[8] == 'h' && szSample[9] == 'i')
	{
		ExecuteForward(g_iForward, _/* Ignore return value */, iEnt, ZE_SND_PAIN, PrepareArray(szSound, sizeof(szSound), 1))
		emit_sound(iEnt, iChan, szSound, flVol, flAttn, bitsFlags, iPitch)
		return FMRES_SUPERCEDE
	}

	if (szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i')
	{
		// Miss Slash.
		if (szSample[14] == 's' && szSample[15] == 'l' && szSample[16] == 'a')
		{
			ExecuteForward(g_iForward, _/* Ignore return value */, iEnt, ZE_SND_SLASH, PrepareArray(szSound, sizeof(szSound), 1))
			emit_sound(iEnt, iChan, szSound, flVol, flAttn, bitsFlags, iPitch)
			return FMRES_SUPERCEDE
		}

		if (szSample[14] == 'h' && szSample[15] == 'i' && szSample[16] == 't')
		{
			// Miss Wall.
			if (szSample[17] == 'w')
			{
				ExecuteForward(g_iForward, _/* Ignore return value */, iEnt, ZE_SND_WALL, PrepareArray(szSound, sizeof(szSound), 1))
				emit_sound(iEnt, iChan, szSound, flVol, flAttn, bitsFlags, iPitch)
				return FMRES_SUPERCEDE
			}
			else // Attack.
			{
				ExecuteForward(g_iForward, _/* Ignore return value */, iEnt, ZE_SND_ATTACK, PrepareArray(szSound, sizeof(szSound), 1))
				emit_sound(iEnt, iChan, szSound, flVol, flAttn, bitsFlags, iPitch)
				return FMRES_SUPERCEDE
			}
		}

		// Attack.
		if (szSample[14] == 's' && szSample[15] == 't' && szSample[16] == 'a')
		{
			ExecuteForward(g_iForward, _/* Ignore return value */, iEnt, ZE_SND_ATTACK, PrepareArray(szSound, sizeof(szSound), 1))
			emit_sound(iEnt, iChan, szSound, flVol, flAttn, bitsFlags, iPitch)
			return FMRES_SUPERCEDE
		}
	}

	// Die | Death.
	if (szSample[7] == 'd' && (szSample[8] == 'i' || szSample[8] == 'e') && (szSample[9] == 'e' || szSample[9] == 'a'))
	{
		ExecuteForward(g_iForward, _/* Ignore return value */, iEnt, ZE_SND_DIE, PrepareArray(szSound, sizeof(szSound), 1))
		emit_sound(iEnt, iChan, szSound, flVol, flAttn, bitsFlags, iPitch)
		return FMRES_SUPERCEDE
	}

	return FMRES_IGNORED
}

/**
 * -=| Natives |=-
 */
#if defined AMBIENCE_SOUNDS
public __native_res_ambience_register(plugin_id, num_params)
{
	new szName[MAX_NAME_LENGTH]
	get_string(1, szName, charsmax(szName))

	if (!strlen(szName))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Can't register new ambience sound without game-mode name.")
		return INVALID_HANDLE
	}

	new pArray[AMBIENCE_DATA]
	for (new i = 0; i < g_iAmbNum; i++)
	{
		ArrayGetArray(g_aAmbienceSounds, i, pArray)

		if (equali(szName, pArray[AMB_NAME]))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Already game-mode ^'%s^' has ambience sound.", pArray[AMB_NAME])
			return INVALID_HANDLE
		}
	}

	get_string(2, pArray[AMB_SOUND], charsmax(pArray) - AMB_SOUND)
	pArray[AMB_LENGTH] = get_param(3)

	new szTemp[MAX_NAME_LENGTH]
	mb_strtoupper(szName, charsmax(szName))

	// Read Ambience sound and Length from INI file.
	formatex(szTemp, charsmax(szTemp), "%s_SOUND", szName)
	if (!ini_read_string(ZE_FILENAME, "Ambience", szTemp, pArray[AMB_SOUND], charsmax(pArray) - AMB_SOUND))
		ini_write_string(ZE_FILENAME, "Ambience", szTemp, pArray[AMB_SOUND])

	formatex(szTemp, charsmax(szTemp), "%s_LENGTH", szName)
	if (!ini_read_int(ZE_FILENAME, "Ambience", szTemp, pArray[AMB_LENGTH]))
		ini_write_int(ZE_FILENAME, "Ambience", szTemp, pArray[AMB_LENGTH])

	// Precache Sound.
	formatex(szTemp, charsmax(szTemp), "sound/%s", pArray[AMB_SOUND])
	precache_generic(szTemp)

	ArrayPushArray(g_aAmbienceSounds, pArray)
	return ++g_iAmbNum - 1
}

public __native_res_ambience_play(plugin_id, num_params)
{
	new iHandle = get_param(1)

	if (FInvalidAmbHandle(iHandle))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Ambience handle id (%d)", iHandle)
		return false
	}

	new pArray[AMBIENCE_DATA]
	ArrayGetArray(g_aAmbienceSounds, iHandle, pArray)

	// Delay before play Ambience sound.
	set_task(g_flAmbDelay, "@play_Sound", TASK_AMBIENCE, pArray[AMB_SOUND], sizeof(pArray) - AMB_SOUND)

	if (get_param(2))
	{
		// Task for repeat Ambience sound.
		set_task(float(pArray[AMB_LENGTH]), "@play_Sound", TASK_AMBIENCE, pArray[AMB_SOUND], AMB_SOUND, "b")
	}

	return true
}

@play_Sound(const szSound[], taskid)
{
	new iPlayers[MAX_PLAYERS], iAliveNum
	get_players(iPlayers, iAliveNum, "h")

	for (new id, i = 0; i < iAliveNum; i++)
	{
		id = iPlayers[i]

		// Play sound for player.
		PlaySound(id, szSound)
	}
}
#endif