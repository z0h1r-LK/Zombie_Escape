#if defined _zombie_escape_const_included
	#endinput
#endif
#define _zombie_escape_const_included

/**
 * File Name (.cfg/.ini)
 */
stock const ZE_FILENAME[] = "zombie_escape"

/**
 * Mod Version and Authors.
 */
stock const ZE_VERSION[] = "1.0.0"
stock const ZE_AUTHORS[] = "z0h1r-LK"

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