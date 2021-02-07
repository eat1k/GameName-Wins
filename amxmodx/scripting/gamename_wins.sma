/*
 * Official resource topic: https://dev-cs.ru/resources/593/
 */

#include <amxmodx>
#include <amxmisc>
#include <reapi>

#pragma semicolon 1

#define IntToStr(%1) fmt("%d",%1)

public stock const PluginName[] = "GameName Wins";
public stock const PluginVersion[] = "1.0.4";
public stock const PluginAuthor[] = "twisterniq";
public stock const PluginURL[] = "https://github.com/twisterniq/amxx-gamename-wins";
public stock const PluginDescription[] = "Replaces gamename field with the number of CT and T round wins";

new const CONFIG_NAME[] = "gamename_wins";

const TASK_INTERVAL = 100;
new g_iCvarMode;
new g_szTpl[64];

public plugin_init()
{
#if AMXX_VERSION_NUM == 190
	register_plugin(
		.plugin_name = PluginName,
		.version = PluginVersion,
		.author = PluginAuthor
	);
#endif
	RegisterHookChain(RG_RoundEnd, "@func_SetGameDesc", true);

	bind_pcvar_num(create_cvar(
		.name = "gamename_wins_mode",
		.string = "0",
		.flags = FCVAR_NONE,
		.description = "0 - to count all players\n1 - to count only alive players",
		.has_min = true,
		.min_val = 0.0,
		.has_max = true,
		.max_val = 1.0),
		g_iCvarMode);

	bind_pcvar_string(create_cvar(
		.name = "gamename_wins_tpl",
		.string = "%ctNum% CT « %ctWins%:%tWins% » T %tNum%",
		.flags = FCVAR_NONE,
		.description = "Template of game name.^n^nPlaceholders:^n%ctNum% - Number of CT^n%tNum% - Number of T^n%ctWins% - CT wins number^n%tWins% - T wins number^n%rounds% - Rounds num"),
		g_szTpl, charsmax(g_szTpl));

	hook_cvar_change(create_cvar(
		.name = "gamename_wins_update_interval",
		.string = "10.0",
		.flags = FCVAR_NONE,
		.description = "How often change the information",
		.has_min = true,
		.min_val = 0.1), "@OnUpdateIntervalChange");

	AutoExecConfig(true, CONFIG_NAME);

	new szPath[PLATFORM_MAX_PATH];
	get_localinfo("amxx_configsdir", szPath, charsmax(szPath));
	server_cmd("exec %s/plugins/%s.cfg", szPath, CONFIG_NAME);
	server_exec();

	new Float:flInterval = get_cvar_float("gamename_wins_update_interval");

	@func_SetGameDesc();
	set_task_ex(flInterval, "@func_SetGameDesc", TASK_INTERVAL, .flags = SetTask_Repeat);
}

@func_SetGameDesc()
{
	new GetPlayersFlags:iFlags = g_iCvarMode == 0 ? GetPlayers_MatchTeam : (GetPlayers_ExcludeDead|GetPlayers_MatchTeam);
	new iNumT = get_playersnum_ex(iFlags, "TERRORIST");
	new iNumCT = get_playersnum_ex(iFlags, "CT");

	new szGameName[64];
	copy(szGameName, charsmax(szGameName), g_szTpl);
	replace(szGameName, charsmax(szGameName), "%ctNum%", IntToStr(iNumCT));
	replace(szGameName, charsmax(szGameName), "%tNum%", IntToStr(iNumT));
	replace(szGameName, charsmax(szGameName), "%ctWins%", IntToStr(get_member_game(m_iNumCTWins)));
	replace(szGameName, charsmax(szGameName), "%tWins%", IntToStr(get_member_game(m_iNumTerroristWins)));
	replace(szGameName, charsmax(szGameName), "%rounds%", IntToStr(get_member_game(m_iTotalRoundsPlayed)));

	set_member_game(m_GameDesc, szGameName);
}

@OnUpdateIntervalChange(const iHandle, const szOldValue[], const szNewValue[])
{
	@func_SetGameDesc();
	change_task(TASK_INTERVAL, str_to_float(szNewValue));
}