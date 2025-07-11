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
stock const ZE_VERSION[] = "Rebuild 1.2"
stock const ZE_AUTHORS[] = "Escapers-Zone Team"
stock const ZE_MD5HASH[] = "d6cd769667209c4d2d210626910c52c8"
stock const Float:ZE_VERSION_FL = 1.2

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
 * Type of sound, Used in ze_fw_res_zombie_sound()
 */
enum
{
	ZE_SND_PAIN = 0,
	ZE_SND_HDSHOT,
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
 * Zombie Escape: Menu Sounds
 */
enum MenuSounds
{
	ZE_MENU_SELECT = 0,
	ZE_MENU_DISPLAY
}

/**
 * For x_Infect_BlockEffect.
 */
enum
{
	ZE_INFECT_ONCE = 1,
	ZE_INFECT_ALWAYS
}

/**
 * Types of clients: Used in ze_user_authorized(id, const szAuthID[], iClType)
 */
enum RClientAuth
{
	ZE_AUTH_CLIENT = 0,
	ZE_AUTH_BOT,
	ZE_AUTH_PROXY
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
#define x_Infect_BlockEffect   "x_bBlockInfectEff"
#define x_Weather_3DSkyBoxEnt  "x_i3DSkyEnt"