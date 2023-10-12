#if defined _ze_stocks_included
	#endinput
#endif
#define _ze_stocks_included

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <reapi>

// Macroses.
#define flag_get(%0,%1)         %0 & BIT(%1)
#define flag_get_boolean(%0,%1) bool:(flag_get(%0,%1) ? true : false)
#define flag_set(%0,%1)         %0 |= BIT(%1)
#define flag_unset(%0,%1)       %0 &= ~BIT(%1)

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
	new szTgaFile[MAX_NAME_LENGTH+3];

	for(new i = 0; i < 6; i++)
	{
		// Get full path of the File.
		formatex(szTgaFile, MAX_NAME_LENGTH-1, "gfx/env/%s%s.tga", szSkyName, szSuffix[i]);

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
	if (equali(sound[strlen(sound) - 4], ".mp3"))
		client_cmd(target, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(target, "spk ^"%s^"", sound)
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
	client_cmd(target, "mp3 stop;stopsound")
}