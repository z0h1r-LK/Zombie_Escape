#if defined _zombie_escape_const_included
	#endinput
#endif
#define _zombie_escape_const_included

/**
 * File Name (.cfg/.ini)
 */
stock const ZE_FILENAME[] = "zombie_escape"
stock const ZE_ET_FILENAME[] = "ze_extra_items"

/**
 * Mod Version and Authors.
 */
stock const ZE_VERSION[] = "Rebuild 1.0-beta 3"
stock const ZE_AUTHORS[] = "Escapers-Zone Team"
stock const ZE_MD5HASH[] = "fee53df017da228327e7192c28cc5ad3"

/**
 * Update check, Host info.
 */
stock const ZE_HOME_HOST[] = "escapers-zone.net"
stock const ZE_HOME_TOPIC[] = "latest.json"
stock const ZE_HOME_PORT = 80

/**
 * Maximum Knockback speed.
 */
stock const Float:MAX_KNOCKBACK = 1000.0

/**
 * General return value.
 */
enum (+=1)
{
	ZE_CONTINUE = 0,
	ZE_STOP,
	ZE_BREAK
}

/**
 * Team Name.
 */
enum (+=1)
{
	ZE_TEAM_UNA = 0,
	ZE_TEAM_ZOMBIE,
	ZE_TEAM_HUMAN,
	ZE_TEAM_SPECTATOR
}

// Maximum items on Extra-Items.
const ZE_MAX_ITEMS = 70

/**
 * Used in ze_select_item_pre().
 */
enum (+=1)
{
	ZE_ITEM_WRONG = -1,
	ZE_ITEM_AVAILABLE,
	ZE_ITEM_UNAVAILABLE,
	ZE_ITEM_DONT_SHOW
}

/**
 * Type of sound, Used in ze_fw_res_player_sound()
 */
enum
{
	ZE_SND_PAIN = 0,
	ZE_SND_SLASH,
	ZE_SND_WALL,
	ZE_SND_ATTACK,
	ZE_SND_DIE
}

/**
 * Types of grenades, Used in ze_grenade_exploded():
 */
enum NadeType
{
	FROST_NADE = 0,
	FIRE_NADE,
	FLARE_NADE
}

/**
 * XVARs Name.
 */
#define X_Core_RoundNum        "x_iRoundNum"
#define X_Core_RoundTime       "x_iRoundTime"
#define X_Core_FixSpawn        "x_bFixSpawn"
#define X_Core_GameStarted     "x_bGameStarted"
#define X_Core_GamemodeBegin   "x_bGameChosen"
#define X_Core_RespawnAsZm     "x_bRespawnAsZombie"
#define X_Core_UpdateAvailable "x_bUpdateAvailable"