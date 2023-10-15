#if defined _ini_file_included
	#endinput
#endif
#define _ini_file_included

/**
 * INI File Reader/Writer was created by CrazY. on 03/17/2019
 * This INI system uses actual files and no modules and it is very flexible
 * Visit this page for more information: https://forums.alliedmods.net/showthread.php?p=2643837
 *
 * Credits goes to:
 *	MeRcyLeZZ (Settings API: https://forums.alliedmods.net/showthread.php?t=243202)
 *	Exolent (FVault: https://forums.alliedmods.net/showthread.php?t=76453)
 */

#include <amxmodx>
#include <amxmisc>

/**
 * Each value type has a maximum length of:
 *
 * integer - 22 characters
 * float - 22 characters
 * string - 64 characters
 *
 *
 * A standard INI file looks like:
 *
 * [SectionName]
 * Key=Value
 *
 * Visit this page for more information: https://en.wikipedia.org/wiki/INI_file
 */

/**
 * Hardcoded max length of a line.
 * Increase this if the values are being cut.
 */
#define INI_MAX_STRING_LEN 512

/**
 * Reads an integer value from a INI file.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param var 			Variable to store the value in
 *
 * @return 				1 on success or 0 if the file, section or key does not exists.
 */
stock ini_read_int(const file[], const section[], const key[], &var)
{
	new szBuffer[22];

	if (!_ini_read(file, section, key, szBuffer, charsmax(szBuffer)))
		return 0;

	var = str_to_num(szBuffer);
	return 1;
}

/**
 * Writes an integer value to a INI file.
 *
 * @note If the file does not already exists, it is created in the ${amxx_configsdir} directory.
 * 		 Keys and/or sections are added to the end.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param value 		The value to write/change
 *
 * @return 				1 on success, 0 otherwise.
 */
stock ini_write_int(const file[], const section[], const key[], value)
{
	new szBuffer[22];
	num_to_str(value, szBuffer, charsmax(szBuffer));
	return _ini_write(file, section, key, szBuffer);
}

/**
 * Reads every single comma separated integer value from a INI file and store to a cellarray.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param array 		The cellarray handle to store the values in
 *
 * @return 				1 on success or 0 if an invalid cellarray handle is provided
 * 						or the file, section or key does not exists.
 */
stock ini_read_int_array(const file[], const section[], const key[], Array:array)
{
	if (array == Invalid_Array)
		return 0;

	new szBuffer[INI_MAX_STRING_LEN], Data[32][22];
	new iStringCount, i;

	if (!_ini_read(file, section, key, szBuffer, charsmax(szBuffer)))
		return 0;

	iStringCount = explode_string(szBuffer, ",", Data, sizeof Data, charsmax(Data[]));

	for (i = 0; i < iStringCount; i++)
	{
		trim(Data[i]);
		ArrayPushCell(array, str_to_num(Data[i]));
	}

	return 1;
}

/**
 * Writes every integer value stored in the cellarray to a INI file.
 *
 * @note If the file does not already exists, it is created in the ${amxx_configsdir} directory.
 * 		 Keys and/or sections are added to the end.
 * @note The values will be separated by commas (e.g. val1 , val2 , val3 , val4)
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param array 		The cellarray handle to parse the values from
 *
 * @return 				1 on success, 0 otherwise.
 */
stock ini_write_int_array(const file[], const section[], const key[], Array:array)
{
	if (array == Invalid_Array)
		return 0;

	new szBuffer[INI_MAX_STRING_LEN];
	new i, iStringCount, iLen, iTotalLen;

	iStringCount = ArraySize(array);

	for (i = 0; i < iStringCount; i++)
	{
		iTotalLen += formatex(szBuffer[iTotalLen], charsmax(szBuffer) - iTotalLen, "%i", ArrayGetCell(array, i));

		if (i != iStringCount - 1)
		{
			iLen = copy(szBuffer[iTotalLen], charsmax(szBuffer) - iTotalLen, " , ");
			iTotalLen += iLen;

			if (iLen < 3)
				break;
		}
	}

	return _ini_write(file, section, key, szBuffer);
}

/**
 * Reads a float value from a INI file.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param var 			Variable to store the value in
 *
 * @return 				1 on success or 0 if the file, section or key does not exists.
 */
stock ini_read_float(const file[], const section[], const key[], &Float:var)
{
	new szBuffer[22];

	if (!_ini_read(file, section, key, szBuffer, charsmax(szBuffer)))
		return 0;

	var = str_to_float(szBuffer);
	return 1;
}

/**
 * Writes an float value to a INI file.
 *
 * @note If the file does not already exists, it is created in the ${amxx_configsdir} directory.
 * 		 Keys and/or sections are added to the end.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param value 		The value to write/change
 *
 * @return 				1 on success, 0 otherwise.
 */
stock ini_write_float(const file[], const section[], const key[], Float:value)
{
	new szBuffer[22];
	formatex(szBuffer, charsmax(szBuffer), "%.2f", value);
	return _ini_write(file, section, key, szBuffer);
}

/**
 * Reads every single comma separated float value from a INI file and store to a cellarray.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param array 		The cellarray handle to store the values in
 *
 * @return 				1 on success or 0 if an invalid cellarray handle is provided
 * 						or the file, section or key does not exists.
 */
stock ini_read_float_array(const file[], const section[], const key[], Array:array)
{
	if (array == Invalid_Array)
		return 0;

	new szBuffer[INI_MAX_STRING_LEN], Data[32][22];
	new iStringCount, i;

	if (!_ini_read(file, section, key, szBuffer, charsmax(szBuffer)))
		return 0;

	iStringCount = explode_string(szBuffer, ",", Data, sizeof Data, charsmax(Data[]));

	for (i = 0; i < iStringCount; i++)
	{
		trim(Data[i]);
		ArrayPushCell(array, str_to_float(Data[i]));
	}

	return 1;
}

/**
 * Writes every float value stored in the cellarray to a INI file.
 *
 * @note If the file does not already exists, it is created in the ${amxx_configsdir} directory.
 * 		 Keys and/or sections are added to the end.
 * @note The values will be separated by commas (e.g. val1 , val2 , val3 , val4)
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param array 		The cellarray handle to parse the values from
 *
 * @return 				1 on success, 0 otherwise.
 */
stock ini_write_float_array(const file[], const section[], const key[], Array:array)
{
	if (array == Invalid_Array)
		return 0;

	new szBuffer[INI_MAX_STRING_LEN];
	new i, iStringCount, iLen, iTotalLen;

	iStringCount = ArraySize(array);

	for (i = 0; i < iStringCount; i++)
	{
		iTotalLen += formatex(szBuffer[iTotalLen], charsmax(szBuffer) - iTotalLen, "%.2f", ArrayGetCell(array, i));

		if (i != iStringCount - 1)
		{
			iLen = copy(szBuffer[iTotalLen], charsmax(szBuffer) - iTotalLen, " , ");
			iTotalLen += iLen;

			if (iLen < 3)
				break;
		}
	}

	return _ini_write(file, section, key, szBuffer);
}

/**
 * Reads a string from a INI file.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param dest 			Buffer to copy the value to
 * @param len 			Max length of the buffer
 *
 * @return 				Number of cells written to buffer on success
 * 						or 0 if the file, section or key does not exists.
 */
stock ini_read_string(const file[], const section[], const key[], dest[], len)
{
	return _ini_read(file, section, key, dest, len);
}

/**
 * Writes a string to a INI file.
 *
 * @note If the file does not already exists, it is created in the ${amxx_configsdir} directory.
 * 		 Keys and/or sections are added to the end.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param value 		The value to write/change
 *
 * @return 				1 on success, 0 otherwise.
 */
stock ini_write_string(const file[], const section[], const key[], value[])
{
	return _ini_write(file, section, key, value);
}

/**
 * Reads every single comma separated string from a INI file and store to a cellarray.
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param array 		The cellarray handle to store the values in
 *
 * @return 				1 on success or 0 if an invalid cellarray handle is provided
 * 						or the file, section or key does not exists.
 */
stock ini_read_string_array(const file[], const section[], const key[], Array:array)
{
	if (array == Invalid_Array)
		return 0;

	new szBuffer[INI_MAX_STRING_LEN], Data[32][64];
	new iStringCount, i;

	if (!_ini_read(file, section, key, szBuffer, charsmax(szBuffer)))
		return 0;

	iStringCount = explode_string(szBuffer, ",", Data, sizeof Data, charsmax(Data[]));

	for (i = 0; i < iStringCount; i++)
	{
		trim(Data[i]);
		ArrayPushString(array, Data[i]);
	}

	return 1;
}

/**
 * Writes every string stored in the cellarray to a INI file.
 *
 * @note If the file does not already exists, it is created in the ${amxx_configsdir} directory.
 * 		 Keys and/or sections are added to the end.
 * @note The values will be separated by commas (e.g. str1 , str2 , str3 , str4)
 *
 * @param file 			The filename of the INI file
 * @param section 		The section name in the INI file
 * @param key 			The key name in the INI file
 * @param array 		The cellarray handle to parse the values from
 *
 * @return 				1 on success, 0 otherwise.
 */
stock ini_write_string_array(const file[], const section[], const key[], Array:array)
{
	if (array == Invalid_Array)
		return 0;

	new szBuffer[INI_MAX_STRING_LEN];
	new i, iStringCount, iLen, iTotalLen;

	iStringCount = ArraySize(array);

	for (i = 0; i < iStringCount; i++)
	{
		iTotalLen += ArrayGetString(array, i, szBuffer[iTotalLen], charsmax(szBuffer) - iTotalLen);

		if (i != iStringCount - 1)
		{
			iLen = copy(szBuffer[iTotalLen], charsmax(szBuffer) - iTotalLen, " , ");
			iTotalLen += iLen;

			if (iLen < 3)
				break;
		}
	}

	return _ini_write(file, section, key, szBuffer);
}

stock _ini_copyc(dest[], len, const src[], ch)
{
	new i, iRetVal;
	new bool:bCharFound;

	for (i = len; i >= 0; i--)
	{
		dest[i] = 0;

		if (!src[i])
			continue;

		if (!bCharFound && src[i] == ch)
		{
			bCharFound = true;
			continue;
		}

		dest[i] = src[i];
		iRetVal++;
	}

	return iRetVal;
}

stock _ini_read(const file[], const section[], const key[], dest[], len)
{
	new hFile;
	new iRetVal;
	new bool:bSectionFound;
	new szBuffer[INI_MAX_STRING_LEN], szFile[64], szKey[32], szSection[32];

	formatex(szFile[get_configsdir(szFile, charsmax(szFile))], charsmax(szFile), "/%s.ini", file);

	if (!(hFile = fopen(szFile, "rt")))
		return 0;

	while (!feof(hFile))
	{
		if (fgets(hFile, szBuffer, charsmax(szBuffer)) == 0)
			break;

		trim(szBuffer);

		if (!szBuffer[0] || szBuffer[0] == ';')
			continue;

		if (szBuffer[0] == '[')
		{
			if (bSectionFound)
				break;

			_ini_copyc(szSection, charsmax(szSection), szBuffer[1], ']');

			if (equali(section, szSection))
				bSectionFound = true;
		}

		if (bSectionFound)
		{
			split(szBuffer, szKey, charsmax(szKey), szBuffer, charsmax(szBuffer), "=");
			trim(szKey);
			trim(szBuffer);

			if (equali(szKey, key))
				iRetVal = copy(dest, len, szBuffer);
		}
	}

	fclose(hFile);
	return iRetVal;
}

stock _ini_write(const file[], const section[], const key[], value[])
{
	new hFile, hTempFile;
	new bool:bSectionExists, bool:bKeyExists, bool:bReplace;
	new iKeyPosStart, iKeyPosEnd;
	new szBuffer[INI_MAX_STRING_LEN], szFile[64], szTempFile[64], szKey[32], szSection[32];

	formatex(szFile[get_configsdir(szFile, charsmax(szFile))], charsmax(szFile), "/%s.ini", file);
	bReplace = true;

	if (!(hFile = fopen(szFile, "a+t")))
		return 0;

	while (!feof(hFile))
	{
		if (fgets(hFile, szBuffer, charsmax(szBuffer)) == 0)
			break;

		trim(szBuffer);

		if (szBuffer[0] == '[')
		{
			_ini_copyc(szSection, charsmax(szSection), szBuffer[1], ']');

			if (equali(section, szSection))
			{
				bSectionExists = true;
				break;
			}
		}
	}

	if (!bSectionExists)
	{
		fprintf(hFile, "^n[%s]^n%s = %s^n", section, key, value);
		fclose(hFile);
		return 1;
	}

	while (!feof(hFile))
	{
		iKeyPosStart = ftell(hFile);

		if (fgets(hFile, szBuffer, charsmax(szBuffer)) == 0)
			break;

		trim(szBuffer);

		if (szBuffer[0] == '[')
			break;

		if (!szBuffer[0] || szBuffer[0] == ';')
			continue;

		split(szBuffer, szKey, charsmax(szKey), szBuffer, charsmax(szBuffer), "=");
		trim(szKey);
		trim(szBuffer);

		iKeyPosEnd = ftell(hFile);

		if (equali(szKey, key))
		{
			bKeyExists = true;
			break;
		}
	}

	if (!bKeyExists)
	{
		if (feof(hFile))
		{
			fprintf(hFile, "%s = %s^n", key, value);
			fclose(hFile);
			return 1;
		}

		bReplace = false;
	}

	formatex(szTempFile[get_configsdir(szTempFile, charsmax(szTempFile))], charsmax(szTempFile), "/ini_file_temp.ini");
	hTempFile = fopen(szTempFile, "wt");

	if (!hTempFile)
	{
		fclose(hTempFile);
		fclose(hFile);
		return 0;
	}

	if (!bReplace)
	{
		fseek(hFile, 0, SEEK_SET);

		while (ftell(hFile) < iKeyPosEnd)
		{
			fgets(hFile, szBuffer, charsmax(szBuffer));
			fputs(hTempFile, szBuffer);
		}
	}
	else
	{
		fseek(hFile, 0, SEEK_SET);

		while (ftell(hFile) < iKeyPosStart)
		{
			fgets(hFile, szBuffer, charsmax(szBuffer));
			fputs(hTempFile, szBuffer);
		}

		fgets(hFile, szBuffer, charsmax(szBuffer));
	}

	fprintf(hTempFile, "%s = %s^n", key, value);

	while (!feof(hFile))
	{
		fgets(hFile, szBuffer, charsmax(szBuffer));
		fputs(hTempFile, szBuffer);
	}

	fclose(hFile);
	fclose(hTempFile);

	delete_file(szFile);

	if (!rename_file(szTempFile, szFile, 1))
		return 0;

	return 1;
}