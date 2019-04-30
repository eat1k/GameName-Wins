/*
 * Author contact: http://t.me/twisternick or:
 *	- Official resource topic on Russian forum: https://dev-cs.ru/threads/4323/
 *	- Official resource topic on English forum: https://forums.alliedmods.net/showthread.php?t=312282
 *	- Official resource topic on Spanish forum: https://amxmodx-es.com/Thread-GameName-Wins-v0-7?pid=191696#pid191696
 *
 * Changelog:
 *	- 0.7.1: Some improvements to the code.
 *	- 0.7: Optimization of code (thanks to georgeml)
 *		- get_playersnum_ex instead of get_players_ex.
 *		- change_task instead of remove_task + set_task.
 *	- 0.6: set_task changed to set_task_ex and get_players to get_players_ex (thanks to iceeedr).
 *	- 0.5.1: Fixed an issue regarding set_task when map starts.
 *	- 0.5:
 *		- CVar gamename_wins_update_interval instead of #define UPDATE_INTERVAL.
 *		- Added automatic creation and execution of a configuration file with CVars: "amxmodx/configs/plugins/gamename_wins.cfg".
 *	- 0.3:
 *		- Changed the method of counting the number of players. Moreover, the update of the number of players now occurs every 10 seconds, you can reduce the number in UPDATE_INTERVAL.
 *		- Added CVar gamename_wins_mode.
 *			- 0: counting all players (alive and dead).
 *			- 1: counting only alive players.
 *	- 0.2: Redone to a better method with full use of ReAPI, so fakemeta is removed. Thanks to fantom and wopox1337.
 *	- 0.1: Release.
 */

#include <amxmodx>
#include <amxmisc>
#include <reapi>

#pragma semicolon 1

#define PLUGIN_VERSION "0.7.1"

new g_iCvarMode;

enum (+= 100)
{
	TASK_INTERVAL
};

public plugin_init()
{
	register_plugin("GameName Wins", PLUGIN_VERSION, "w0w");
	RegisterHookChain(RG_RoundEnd, "func_SetGameDesc", true);

	new pCvar = create_cvar("gamename_wins_mode", "0", FCVAR_NONE, "Counting all players (0) or alive only (1)", true, 0.0, true, 1.0);
	bind_pcvar_num(pCvar, g_iCvarMode);

	pCvar = create_cvar("gamename_wins_update_interval", "10.0", FCVAR_NONE, "Period of info updates", true, 0.1);
	hook_cvar_change(pCvar, "CallBack_CvarChange");

	AutoExecConfig(true, "gamename_wins");

	func_SetGameDesc();
	set_task_ex(get_pcvar_float(pCvar), "func_SetGameDesc", TASK_INTERVAL, .flags = SetTask_Repeat);
}

public func_SetGameDesc()
{
	new iNumT = get_playersnum_ex(g_iCvarMode == 0 ? GetPlayers_MatchTeam : (GetPlayers_ExcludeDead|GetPlayers_MatchTeam), "TERRORIST");
	new iNumCT = get_playersnum_ex(g_iCvarMode == 0 ? GetPlayers_MatchTeam : (GetPlayers_ExcludeDead|GetPlayers_MatchTeam), "CT");

	new szText[64];
	formatex(szText, charsmax(szText), "%d CT « %d:%d » T %d", iNumCT, get_member_game(m_iNumCTWins), get_member_game(m_iNumTerroristWins), iNumT);

	set_member_game(m_GameDesc, szText);
}

public CallBack_CvarChange(pcvar, const szOldValue[], const szNewValue[])
{
	func_SetGameDesc();
	change_task(TASK_INTERVAL, str_to_float(szNewValue));
}