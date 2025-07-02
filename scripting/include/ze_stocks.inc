#if defined _ze_stocks_included
	#endinput
#endif
#define _ze_stocks_included

#include <amxmisc> // <- amxmodx.inc already included here.

// Macroses.
#define flag_get(%0,%1)         %0 & (1<<(%1))
#define flag_get_boolean(%0,%1) bool:(flag_get(%0,%1) ? true : false)
#define flag_set(%0,%1)         %0 |= (1<<(%1))
#define flag_unset(%0,%1)       %0 &= ~(1<<(%1))

/**
 * Send colored message on chat for specific player or everyone.
 *
 * @param id       Client index (0 = Everyone).
 * @param message  Formatting rules.
 * @param ...      Variable number of formatting parameters.
 *
 * @return         Number of printed characters.
 *
 * @error          If this player not on game.
 */
stock ze_colored_print(const target, const message[], any:...)
{
	if (target)
	{
		if (!is_user_connected(target))
		{
			log_error(AMX_ERR_NATIVE, "[ZE] Player not on game (%d)", target);
			return 0;
		}
	}

	new szBuffer[256];
	new i = formatex(szBuffer, charsmax(szBuffer), "%L ", LANG_PLAYER, "CHAT_PREFIX");
	vformat(szBuffer[i], charsmax(szBuffer) - i, message, 3);

	replace_string(szBuffer, charsmax(szBuffer), "!g", "^4");
	replace_string(szBuffer, charsmax(szBuffer), "!t", "^3");
	replace_string(szBuffer, charsmax(szBuffer), "!y", "^1");

	return client_print_color(target, print_team_default, szBuffer);
}

/**
 * Returns the number of required Zombies.
 *
 * @param iAliveNum    The number of alive players.
 *
 */
stock GetRequiredZombies(iAliveNum)
{
	switch (iAliveNum)
	{
		case 2..5: return 1;
		case 6..15: return 2;
		case 16..25: return 3;
		case 26..32: return 4;
	}

	return 0;
}

/**
 * Precache sky files.
 *
 * @param szSkyName[]     Sky name.
 *
 * @noreturn
 *
 */
stock precache_sky(const szSkyName[])
{
	new const szSuffix[6][3] = {"up", "dn", "ft", "bk", "lf", "rt"};
	for(new szTgaFile[MAX_NAME_LENGTH+3], i = 0; i < 6; i++)
	{
		// Get full path of the File.
		formatex(szTgaFile, charsmax(szTgaFile), "gfx/env/%s%s.tga", szSkyName, szSuffix[i]);

		// File is exist?
		if(file_exists(szTgaFile, true))
			precache_generic(szTgaFile);
		else
			server_print("[ZE] Cannot locate file '%s', Skipping...", szTgaFile);
	}
}

/**
 * Play sound for specific player or all players.
 *
 * @note Counter-Strike support only .mp3 and .wav
 *
 * @param target  Client index (0 = everyone).
 * @param sound[] Sound path.
 *
 * @noreturn
 */
stock PlaySound(target, const sound[])
{
	// MP3 Sound?
	if (sound[strlen(sound) - 1] == '3')
		client_cmd(target, "mp3 play ^"sound/%s^"", sound);
	else
		client_cmd(target, "spk ^"%s^"", sound);
}

/**
 * Stop sound for specific player or all players.
 *
 * @note It's stop speak, MP3 and emit_sound().
 *
 * @param id     Client index (0 = everyone).
 *
 * @noreturn
 */
stock StopSound(target = 0)
{
	// Credit: Templaso
	client_cmd(target, "mp3 stop;stopsound");
}

/**
 * Get the number of players on server.
 *
 * @return        Number of players.
 */
stock get_PlayersNum()
{
	new iNum;
	for (new id = 1; id <= MaxClients; id++)
	{
		if (!is_user_connected(id))
			continue;

		if (is_user_hltv(id))
			continue;

		if (get_member(id, m_iTeam) == TEAM_SPECTATOR)
			continue;

		iNum++;
	}

	return iNum;
}

/**
 * Log MySQL errors.
 *
 * @param iFailState     Faile state.
 * @param iError         Error code.
 * @param szError[]      Error message.
 * @param szLogFile[]    Log file path.
 *
 * @return               true  | MySQL failed, There a error.
 *                       false | MySQL Success, No Error.
 */
stock SQL_IsFail(iFailState, iError, const szError[], const szLogFile[])
{
	if (iFailState == TQUERY_CONNECT_FAILED)
	{
		log_to_file(szLogFile, "[MySQL] Could not connect to SQL database: %s", szError)
		return true
	}
	else if (iFailState == TQUERY_QUERY_FAILED)
	{
		log_to_file(szLogFile, "[MySQL] Query failed: %s", szError)
		return true
	}
	else if (iError)
	{
		log_to_file(szLogFile, "[MySQL] Error on query: %s", szError)
		return true
	}

	return false
}

stock AddCommas(iNum, szOutput[], iLen)
{
	new szTmp[32], iOutputPos, iNumPos, iNumLen
	szTmp = NULL_STRING; iOutputPos = iNumPos = iNumLen = 0

	if (iNum < 0)
	{
		szOutput[iOutputPos++] = '-'
		iNum = abs(iNum)
	}

	iNumLen = num_to_str(iNum, szTmp, charsmax(szTmp))

	if (iNumLen <= 3)
	{
		iOutputPos += copy(szOutput[iOutputPos], iLen, szTmp)
	}
	else
	{
		while ((iNumPos < iNumLen) && (iOutputPos < iLen))
		{
			szOutput[iOutputPos++] = szTmp[iNumPos++]

			if((iNumLen - iNumPos) && !((iNumLen - iNumPos) % 3))
				szOutput[iOutputPos++] = ','
		}

		szOutput[iOutputPos] = EOS
	}

	return iOutputPos
}

stock NumAbbrev(iNum, szOutput[], iLen)
{
	if (iNum <= 999)
	{
		return num_to_str(iNum, szOutput, iLen)
	}
	else
	{
		if (iNum >= 1000000000) // Billions.
		{
			return formatex(szOutput, iLen, "%.1f%L", iNum / 1000000000.0, LANG_PLAYER, "NABBR_BILLIONS")
		}
		else if (iNum >= 1000000) // Millions.
		{
			return formatex(szOutput, iLen, "%.1f%L", iNum / 1000000.0, LANG_PLAYER, "NABBR_MILLIONS")
		}
		else if (iNum >= 1000) // Thousands.
		{
			return formatex(szOutput, iLen, "%.1f%L", iNum / 1000.0, LANG_PLAYER, "NABBR_THOUSANDS")
		}
	}

	return 0
}