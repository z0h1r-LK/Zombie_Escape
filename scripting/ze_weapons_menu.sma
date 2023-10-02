#include <amxmodx>
#include <amxmisc>
#include <reapi>

#include <ze_core>

// Weapon Data.
enum _:WPN_DATA
{
	WPN_SECTION = 0,
	WPN_NAME[MAX_NAME_LENGTH],
	WPN_CLASS[MAX_NAME_LENGTH]
}

// Weapon Section.
enum (+=1)
{
	SECTION_NONE = 0,
	SECTION_PRIMARY,
	SECTION_SECONDARY
}

// Primary Weapons Name.
new const g_szDefPrimaryWpn[][WPN_DATA] =
{
	{SECTION_PRIMARY, "Famas", "weapon_famas"},
	{SECTION_PRIMARY, "Galil", "weapon_galil"},
	{SECTION_PRIMARY, "AK-47 Kalashnikov", "weapon_ak47"},
	{SECTION_PRIMARY, "M4A1 Carbine", "weapon_m4a1"},
	{SECTION_PRIMARY, "SG-552 Commando", "weapon_sg552"},
	{SECTION_PRIMARY, "Aug", "weapon_aug"},
	{SECTION_PRIMARY, "M3 Shotgun", "weapon_m3"},
	{SECTION_PRIMARY, "XM1014 Auto", "weapon_xm1014"},
	{SECTION_PRIMARY, "TMP 9mm", "weapon_tmp"},
	{SECTION_PRIMARY, "Mac-10", "weapon_mac10"},
	{SECTION_PRIMARY, "MP5 Navy", "weapon_mp5navy"},
	{SECTION_PRIMARY, "P90", "weapon_p90"},
	{SECTION_PRIMARY, "SG-550 Auto", "weapon_g3sg1"},
	{SECTION_PRIMARY, "G3SG1 Auto", "weapon_g3sg1"},
	{SECTION_PRIMARY, "AWP Heavy Sniper", "weapon_awp"},
	{SECTION_PRIMARY, "Scout Sniper", "weapon_scout"},
	{SECTION_PRIMARY, "M249 Machine Gun", "weapon_m249"}
}

// Secondary Weapons Name.
new const g_szDefSecondaryWpn[][WPN_DATA] =
{
	{SECTION_SECONDARY, "Glock-18", "weapon_glock18"},
	{SECTION_SECONDARY, "USP", "weapon_usp"},
	{SECTION_SECONDARY, "P-228", "weapon_p228"},
	{SECTION_SECONDARY, "Desert Eagle", "weapon_deagle"},
	{SECTION_SECONDARY, "Five-SeveN", "weapon_fiveseven"},
	{SECTION_SECONDARY, "Dual Elite", "weapon_elite"}
}

// Variables.
new g_iPrimaryNum,
	g_iSecondaryNum

public plugin_init()
{
	// Load Plug-In.
	register_plugin("[ZE] Weapons Menu", ZE_VERSION, ZE_AUTHORS)

	// Commands.
	register_clcmd("say /guns", "cmd_WeaponsMenu")
	register_clcmd("say_team /guns", "cmd_WeaponsMenu")
}

public plugin_cfg()
{
	new szFile[MAX_RESOURCE_PATH_LENGTH]

	// Get configs directory.
	new iLen = get_configsdir(szFile, charsmax(szFile))

	// Get full file path.
	formatex(szFile[iLen], charsmax(szFile) - iLen, "/%s.ini", ZE_FILENAME)

	// Read Weapons.
	read_Weapons(szFile)
}

public cmd_WeaponsMenu(id)
{

	return PLUGIN_CONTINUE
}

/**
 * -=| Function |=-
 */
read_Weapons(const szFile[])
{
	new hFile

	// Open the file.
	if ((hFile = fopen(szFile, "a+t")))
	{
		new szRead[256], szSection[64], bExist, iLine

		while (!feof(hFile))
		{
			iLine++

			if (!fgets(hFile, szRead, charsmax(szRead)))
				break

			// Remove blanks from Text.
			trim(szRead)

			switch (szRead[0])
			{
				case '#', ';', 0:
				{
					continue
				}
				case '[':
				{
					// Copy name on new Buffer.
					copyc(szSection, charsmax(szSection), szRead[1], ']')

					if (equal(szSection, "Weapons Menu"))
					{
						bExist = true
						break
					}
				}
			}
		}

		if (!bExist)
		{
			new i

			// Create new Section with default Weapons.
			for (i = 0; i < sizeof(g_szDefPrimaryWpn); i++)
				fprintf(hFile, "^"p^" ^"%s^" ^"%s^"^n", g_szDefPrimaryWpn[i][WPN_NAME], g_szDefPrimaryWpn[i][WPN_CLASS])

			for (i = 0; i < sizeof(g_szDefSecondaryWpn); i++)
				fprintf(hFile, "^"s^" ^"%s^" ^"%s^"^n", g_szDefSecondaryWpn[i][WPN_NAME], g_szDefSecondaryWpn[i][WPN_CLASS])

			// Close the file.
			fclose(hFile)
			return 0
		}

		new pArray[WPN_DATA], szWpnName[64], szWpnClass[64]

		while (!feof(hFile))
		{
			iLine++

			if (!fgets(hFile, szRead, charsmax(szRead)))
				break

			// Remove blanks from Text.
			trim(szRead)

			switch (szRead[0])
			{
				case '#', ';', 0:
				{
					continue
				}
			}

			// Parse the text.
			if (parse(szRead, szSection, charsmax(szSection), szWpnName, charsmax(szWpnName), szWpnClass, charsmax(szWpnClass)) < 3)
			{
				server_print("[ZE] Line #%i: Some arguments are not found !", iLine)
				continue
			}

			switch (szSection[0])
			{
				case 'P', 'p':
				{
					pArray[WPN_SECTION] = SECTION_PRIMARY
					copy(pArray[WPN_NAME], charsmax(pArray) - WPN_NAME, szWpnName)
					copy(pArray[WPN_CLASS], charsmax(pArray) - WPN_CLASS, szWpnClass)
					g_iPrimaryNum++
				}
				case 'S', 's':
				{
					pArray[WPN_SECTION] = SECTION_SECONDARY
					copy(pArray[WPN_NAME], charsmax(pArray) - WPN_NAME, szWpnName)
					copy(pArray[WPN_CLASS], charsmax(pArray) - WPN_CLASS, szWpnClass)
					g_iSecondaryNum++
				}
			}
		}

		// Close the file.
		fclose(hFile)
		return 1
	}

	return 0
}