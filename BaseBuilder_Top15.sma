#include <amxmodx>
#include <basebuilder>
#include <nvault>
#include <nvault_util>
#include <ColorChat>

forward zwieksz_exp_za_cele(id);

native register_forward(_forwardType,const _function[],_post=0);
native unregister_forward(_forwardType,registerId,post=0);
#define FM_ClientUserInfoChanged 122
#define FM_ServerDeactivate 103
#define FM_Sys_Error 113
#define FM_GameShutdown 120

#define MAX_STATS 10000

#define KILL_PKT 1.0
#define DEATH_PKT 0.75
#define GOAL_PKT 7.0
#define SURVIVE_PKT 10.0
#define SECOND_PKT 0.0025

// %0 zabicia, %1 smierci, %2 cele, %3 przetrwania, %4 czas gry
#define calculate_points(%0,%1,%2,%3,%4) (float(%0)*KILL_PKT+float(%1)*DEATH_PKT+float(%2)*GOAL_PKT+float(%3)*SURVIVE_PKT+float(%4)*SECOND_PKT)

enum _:_stats { _nick[32], _czas_gry, _zabicia, _smierci, _cele, _przetrwania, Float:_punkty, _pos }
new stats[MAX_STATS][_stats];
new userstats[33][_stats];

new fwdOnNameChange;

public plugin_init()
{
	register_plugin("BASEBUILDER Top15", "1.0", "Amator 2k23");
	set_task(1.0, "second", .flags="b");
	register_event("DeathMsg", "DeathMsg", "a");
	register_logevent("RoundEnd", 2, "1=Round_End");
	read_stats();
	register_event("HLTV", "newround", "a", "1=0", "2=0");
	register_clcmd("say /rank", "rank");
	register_clcmd("say /top15", "top15");
	register_clcmd("say /rankstats", "rankstats");
	register_event("SayText", "SayText_Name_Change", "a", "2=#Cstrike_Name_Change");
	register_forward(FM_ServerDeactivate, "fwServerDown");
	register_forward(FM_Sys_Error, "fwServerDown");
	register_forward(FM_GameShutdown, "fwServerDown");
}

public fwServerDown()
{
	read_stats();
}

public client_authorized(id)
{
	if(strlen(userstats[id][_nick]))
		return;
	
	get_user_name(id, userstats[id][_nick], 31);
	new vault = nvault_open("bbtop15");
	
	new szData[96];
	if(nvault_get(vault, userstats[id][_nick], szData, charsmax(szData)))
	{
		new szParsed[6][12];
		parse(szData, szParsed[0], charsmax(szParsed[]), szParsed[1], charsmax(szParsed[]), szParsed[2], charsmax(szParsed[]),
		szParsed[3], charsmax(szParsed[]), szParsed[4], charsmax(szParsed[]), szParsed[5], charsmax(szParsed[]));
		userstats[id][_pos] = str_to_num(szParsed[0]);
		userstats[id][_zabicia] = str_to_num(szParsed[1]);
		userstats[id][_smierci] = str_to_num(szParsed[2]);
		userstats[id][_cele] = str_to_num(szParsed[3]);
		userstats[id][_przetrwania] = str_to_num(szParsed[4]);
		userstats[id][_czas_gry] = str_to_num(szParsed[5]);
		userstats[id][_punkty] = _:calculate_points(userstats[id][_zabicia], userstats[id][_smierci], userstats[id][_cele], userstats[id][_przetrwania], userstats[id][_czas_gry]);
	}
	else
	{
		userstats[id][_zabicia] = 0;
		userstats[id][_smierci] = 0;
		userstats[id][_cele] = 0;
		userstats[id][_przetrwania] = 0;
		userstats[id][_czas_gry] = 0;
		userstats[id][_punkty] = _:0.0;
		
		new vault2 = nvault_util_open("bbtop15");
		userstats[id][_pos] = nvault_util_count(vault2) + 1;
		nvault_util_close(vault2);
		
		formatex(szData, charsmax(szData), "^"%i^" ^"0^" ^"0^" ^"0^" ^"0^" ^"0^"", userstats[id][_pos]);
		nvault_set(vault, userstats[id][_nick], szData);
	}
	
	nvault_close(vault);
}

public client_disconnect(id)
{
	new vault = nvault_open("bbtop15");
	
	new szData[96];
	formatex(szData, charsmax(szData), "^"%i^" ^"%i^" ^"%i^" ^"%i^" ^"%i^" ^"%i^"", userstats[id][_pos], userstats[id][_zabicia],
	userstats[id][_smierci], userstats[id][_cele], userstats[id][_przetrwania], userstats[id][_czas_gry]);
	nvault_set(id, userstats[id][_nick], szData);
	nvault_close(vault);
	
	formatex(userstats[id][_nick], 31, "");
	userstats[id][_zabicia] = 0;
	userstats[id][_smierci] = 0;
	userstats[id][_cele] = 0;
	userstats[id][_przetrwania] = 0;
	userstats[id][_czas_gry] = 0;
	userstats[id][_punkty] = _:0.0;
	userstats[id][_pos] = 0;
}

public SayText_Name_Change()
{
	fwdOnNameChange = register_forward(FM_ClientUserInfoChanged, "OnClientNameChange_Post", 1);
}

public OnClientNameChange_Post(id)
{
	if(is_user_connected(id))
	{
		client_disconnect(id);
		client_authorized(id);
	}
	
	unregister_forward(FM_ClientUserInfoChanged, fwdOnNameChange, 1);
}

public second()
{
	for(new i = 1; i <= 32; ++i)
		if(is_user_connected(i))
			++userstats[i][_czas_gry];
}

public DeathMsg()
{
	new killer = read_data(1);
	new victim = read_data(2);
	
	if(!bb_is_user_zombie(killer) && bb_is_user_zombie(victim))
	{
		++userstats[killer][_zabicia];
		++userstats[victim][_smierci];
	}
}

public zwieksz_exp_za_cele(id)
{
	++userstats[id][_cele];
}

public RoundEnd()
{
	for(new i = 1; i <= 32; ++i)
		if(is_user_alive(i) && !bb_is_user_zombie(i))
			++userstats[i][_przetrwania];
}

public newround()
{
	read_stats();
}

public read_stats()
{
	new vault = nvault_open("bbtop15");
	
	for(new i = 1; i <= 32; ++i)
	{
		if(!is_user_connected(i))
			continue;
		
		if(userstats[i][_zabicia] == stats[userstats[i][_pos]-1][_zabicia]
		&& userstats[i][_smierci] == stats[userstats[i][_pos]-1][_smierci]
		&& userstats[i][_cele] == stats[userstats[i][_pos]-1][_cele]
		&& userstats[i][_przetrwania] == stats[userstats[i][_pos]-1][_przetrwania]
		&& userstats[i][_czas_gry] == stats[userstats[i][_pos]-1][_czas_gry])
			continue;
		
		new szData[96];
		formatex(szData, charsmax(szData), "^"%i^" ^"%i^" ^"%i^" ^"%i^" ^"%i^" ^"%i^"", userstats[i][_pos], userstats[i][_zabicia],
		userstats[i][_smierci], userstats[i][_cele], userstats[i][_przetrwania], userstats[i][_czas_gry]);
		nvault_set(vault, userstats[i][_nick], szData);
	}
	
	nvault_close(vault);
	vault = nvault_util_open("bbtop15");
	nvault_util_readall(vault, "read_stats_handle");
	nvault_util_close(vault);
}

public read_stats_handle(current, entries, key[], values[], timestamp, Data[], DataSize)
{
	new szParsed[6][12];
	parse(values, szParsed[0], charsmax(szParsed[]), szParsed[1], charsmax(szParsed[]), szParsed[2], charsmax(szParsed[]),
	szParsed[3], charsmax(szParsed[]), szParsed[4], charsmax(szParsed[]), szParsed[5], charsmax(szParsed[]));
	
	copy(stats[current-1][_nick], 31, key);
	stats[current-1][_zabicia] = str_to_num(szParsed[1]);
	stats[current-1][_smierci] = str_to_num(szParsed[2]);
	stats[current-1][_cele] = str_to_num(szParsed[3]);
	stats[current-1][_przetrwania] = str_to_num(szParsed[4]);
	stats[current-1][_czas_gry] = str_to_num(szParsed[5]);
	stats[current-1][_punkty] = _:calculate_points(stats[current-1][_zabicia], stats[current-1][_smierci], stats[current-1][_cele], stats[current-1][_przetrwania], stats[current-1][_czas_gry]);
	
	if(current == entries)
	{
		SortCustom2D(stats, entries, "sort_stats");
		for(new i = 0; i < entries && i < MAX_STATS; ++i)
		{
			for(new j = 1; j <= 32; ++j)
			{
				if(is_user_connected(j) && equal(stats[i][_nick], userstats[j][_nick]))
				{
					userstats[j][_punkty] = _:stats[i][_punkty];
					userstats[j][_pos] = i + 1;
					break;
				}
			}
		}
		
		replace_positions(entries);
	}
}

public sort_stats(const elem1[], const elem2[], const array[], const data[], data_size)
{
	if(elem1[_punkty] > elem2[_punkty])
		return -1;
	else if(elem1[_punkty] < elem2[_punkty])
		return 1;
	return 0;
}

public replace_positions(entries)
{
	new vault = nvault_open("bbtop15");
	
	for(new i = 0; i < entries && i < MAX_STATS; ++i)
	{
		new szData[96];
		formatex(szData, charsmax(szData), "^"%i^" ^"%i^" ^"%i^" ^"%i^" ^"%i^" ^"%i^"", i+1, stats[i][_zabicia], stats[i][_smierci],
		stats[i][_cele], stats[i][_przetrwania], stats[i][_czas_gry]);
		nvault_set(vault, stats[i][_nick], szData);
	}
	
	nvault_close(vault);
}

public rank(id)
{
	ColorChat(id, GREEN, "[BaseBuilder]^1 Zajmujesz %i pozycje w rankingu z %.2f punktami.", userstats[id][_pos], userstats[id][_punkty]);
}

public top15(id)
{
	new szMotd[1537];
	formatex(szMotd, charsmax(szMotd), "<body bgcolor=#666666><center><b><font size=6 color=#00cd00>TOP15 Graczy</b><hr size=1 color=#00cd00><table style=^"color:#ffffff;width:650%^">");
	formatex(szMotd, charsmax(szMotd), "%s<tr style=color:#00cd00;><td>Gracz<td>Punkty<td>Zabicia<td>Smierci<td>Przetrwania<td>Czas gry<td>Cele", szMotd);
	
	new i;
	for(i = 0; i < 15; ++i)
	{
		if(!strlen(stats[i][_nick]))
			break;
		
		formatex(szMotd, charsmax(szMotd), "%s<tr><td>%i. %s<td>%.2f<td>%i<td>%i<td>%i", szMotd, i+1, stats[i][_nick],
		stats[i][_punkty], stats[i][_zabicia], stats[i][_smierci], stats[i][_przetrwania]);
		
		new szTime[24];
		if(stats[i][_czas_gry] >= 3600)
			formatex(szTime, charsmax(szTime), "%ih ", stats[i][_czas_gry] / 3600);
		if(stats[i][_czas_gry] % 3600 >= 60)
			formatex(szTime, charsmax(szTime), "%s%i min ", szTime, (stats[i][_czas_gry] % 3600) / 60);
		if(stats[i][_czas_gry] % 60 > 0)
			formatex(szTime, charsmax(szTime), "%s%is", szTime, stats[i][_czas_gry] % 60);
		else if(stats[i][_czas_gry] > 0)
			szTime[strlen(szTime)-1] = 0;
		else
			formatex(szTime, charsmax(szTime), "0s");
		
		formatex(szMotd, charsmax(szMotd), "%s<td>%s<td>%i", szMotd, szTime, stats[i][_cele]);
	}
	
	formatex(szMotd, charsmax(szMotd), "%s</table>", szMotd);
	
	if(!i)
		formatex(szMotd, charsmax(szMotd), "%s<br>W top15 nie ma jeszcze zadnych graczy.", szMotd);
	
	show_motd(id, szMotd, "Top15");
}

public rankstats(id)
{
	new szMotd[1537];
	formatex(szMotd, charsmax(szMotd), "<body bgcolor=#000000><font size=3 color=e6a000>");
	formatex(szMotd, charsmax(szMotd), "%sNick: %s", szMotd, userstats[id][_nick]);
	formatex(szMotd, charsmax(szMotd), "%s<br>Punkty: %.2f", szMotd,
	calculate_points(userstats[id][_zabicia], userstats[id][_smierci], userstats[id][_cele], userstats[id][_przetrwania], userstats[id][_czas_gry]));
	formatex(szMotd, charsmax(szMotd), "%s<br>Zabicia: %i - %.2f punktow", szMotd, userstats[id][_zabicia], userstats[id][_zabicia] * KILL_PKT);
	formatex(szMotd, charsmax(szMotd), "%s<br>Smierci jako Zombie: %i - %.2f punktow", szMotd, userstats[id][_smierci], userstats[id][_smierci] * DEATH_PKT);
	formatex(szMotd, charsmax(szMotd), "%s<br>Przetrwania jako czlowiek: %i - %.2f punktow", szMotd, userstats[id][_przetrwania], userstats[id][_przetrwania] * SURVIVE_PKT);
	
	new szTime[24];
	if(userstats[id][_czas_gry] >= 3600)
		formatex(szTime, charsmax(szTime), "%ih ", userstats[id][_czas_gry] / 3600);
	if(userstats[id][_czas_gry] % 3600 >= 60)
		formatex(szTime, charsmax(szTime), "%s%i min ", szTime, (userstats[id][_czas_gry] % 3600) / 60);
	if(userstats[id][_czas_gry] % 60 > 0)
		formatex(szTime, charsmax(szTime), "%s%is", szTime, userstats[id][_czas_gry] % 60);
	else if(userstats[id][_czas_gry] > 0)
		szTime[strlen(szTime)-1] = 0;
	else
		formatex(szTime, charsmax(szTime), "0s");
	
	formatex(szMotd, charsmax(szMotd), "%s<br>Czas gry: %s - %.2f punktow", szMotd, szTime, userstats[id][_czas_gry] * SECOND_PKT);
	formatex(szMotd, charsmax(szMotd), "%s<br>Bonus za wykonywanie celi: %i razy - %.2f punktow<br>", szMotd, userstats[id][_cele], userstats[id][_cele] * GOAL_PKT);
	
	if(userstats[id][_pos] > 1)
	{
		if(stats[userstats[id][_pos]-2][_punkty] - userstats[id][_punkty] >= 0.01)
			formatex(szMotd, charsmax(szMotd), "%s<br>Do %i pozycji brakuje ci %.2f punktow.", szMotd, userstats[id][_pos] - 1, stats[userstats[id][_pos]-2][_punkty] - userstats[id][_punkty]);
		else
			formatex(szMotd, charsmax(szMotd), "%s<br>Do %i pozycji brakuje ci <0.01 punktow.", szMotd);
	}
	else if(userstats[id][_pos] == 1)
		formatex(szMotd, charsmax(szMotd), "%s<br>Masz 1 miejsce w Top15 !", szMotd);
	else
		formatex(szMotd, charsmax(szMotd), "%s<br>Aktualnie nie masz pozycji w Top15.", szMotd);
	
	formatex(szMotd, charsmax(szMotd), "%s<br>Top15 odswieza sie co runde.", szMotd);
	show_motd(id, szMotd, "O mnie:");
}
