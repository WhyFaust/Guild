#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <gangs>
#include <sdkhooks>
#include <csgocolors>

enum struct Scores
{
	int Kill;
	int Death;
	int Win;
	int Suicide;
}
Scores g_iScore;

public Plugin myinfo =
{
	name = "[GANGS MODULE] Score Standart",
	author = "BaFeR",
	version = GANGS_VERSION
};

/*public void Gangs_OnLoaded()
{
	Handle g_hCvar = FindConVar("sm_gangs_terrorist_only");
	if (g_hCvar != INVALID_HANDLE)
		g_bOnlyTerrorist = GetConVarBool(g_hCvar);
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");
}*/

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}
	
	KFG_load();
	
	//HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
}

/*public OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i)) CreateTimer(TimeGetHP, TIMER_PlayerSpawn, i);
	}
}*/

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(g_iScore.Kill > 0)
	{
		if (IsValidClient(attacker) && IsValidClient(iClient) && iClient != attacker && Gangs_ClientHasGang(attacker))
		{
			char sGangName[256], sGangName1[256];
			Gangs_GetClientGangName(attacker, sGangName, sizeof(sGangName));
			Gangs_GetClientGangName(iClient, sGangName1, sizeof(sGangName1));
			if (!StrEqual(sGangName, sGangName1))
			{
				Gangs_SetClientGangScore(attacker, Gangs_GetClientGangScore(attacker)+g_iScore.Kill);
			}
		}
	}
	
	if(g_iScore.Death > 0 || g_iScore.Suicide >0)
	{
		if (IsValidClient(attacker) && IsValidClient(iClient) && Gangs_ClientHasGang(iClient))
		{
			if(iClient == attacker)
			{
				Gangs_SetClientGangScore(iClient, Gangs_GetClientGangScore(iClient)-g_iScore.Suicide);
			}
			else
			{
				char sGangName[256], sGangName1[256];
				Gangs_GetClientGangName(attacker, sGangName, sizeof(sGangName));
				Gangs_GetClientGangName(iClient, sGangName1, sizeof(sGangName1));
				if (!StrEqual(sGangName, sGangName1))
				{
					Gangs_SetClientGangScore(iClient, Gangs_GetClientGangScore(iClient)-g_iScore.Suicide);
				}
			}
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(g_iScore.Win>0)
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i, _, false) && Gangs_ClientHasGang(i))
				Gangs_SetClientGangScore(i, Gangs_GetClientGangScore(i)+g_iScore.Win);
}

public void OnMapStart()
{
	KFG_load();
}

void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("ScoreStandart");
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_score_standart.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][Score Standart] - Configuration file not found");
	kfg.Rewind();
	g_iScore.Kill = kfg.GetNum("kill");
	g_iScore.Death = kfg.GetNum("death");
	g_iScore.Win = kfg.GetNum("win");
	g_iScore.Suicide = kfg.GetNum("suicide");
	delete kfg;
}