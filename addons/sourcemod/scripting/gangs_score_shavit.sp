#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <gangs>
#include <sdkhooks>
#include <csgocolors>
#include <shavit>

enum struct enum_Item
{
	int Score;
	int Messages;
	int Map;
	int Bonus;
}
enum_Item g_Item;

int g_iMapUser[MAXPLAYERS+1] = 0;

public Plugin myinfo =
{
	name = "[GANGS MODULE] Score Shavit",
	author = "baferpro",
	version = GANGS_VERSION
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}
	
	RegAdminCmd("sm_setscoreshavit", Command_SetScoreShavit, ADMFLAG_ROOT);
	
	KFG_load();
}

public Action Command_SetScoreShavit(int client, int args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setscoreshavit <score>");
		return Plugin_Handled;
	}
	
	char buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	g_Item.Score = StringToInt(buffer);
	
	char path[128];
	KeyValues kfg = new KeyValues("ScoreShavit");
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_score_shavit.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][Score Standart] - Configuration file not found");
	kfg.Rewind();
	kfg.SetNum("score", g_Item.Score);
	delete kfg;
	
	ReplyToCommand(client, "[SM] Successfully set %i's score.", g_Item.Score);
	return Plugin_Handled;
}

public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldtime, float perfs)
{
	if(g_Item.Score > 0)
	{
		if(IsValidClient(client) && Gangs_ClientHasGang(client) && (g_Item.Map <= 0 || g_iMapUser[client] < g_Item.Map))
		{
			if(Shavit_GetClientTrack(client) == Track_Bonus && !g_Item.Bonus)
				return;
			Gangs_SetClientGangScore(client, Gangs_GetClientGangScore(client)+g_Item.Score);
			g_iMapUser[client]++;
			if(g_Item.Messages)
			{
				CPrintToChat(client, "Вы заработали %i опыта для банды за прохождение карты", g_Item.Score);
			}
		}
	}
}

public void OnMapStart()
{
	KFG_load();
}

public void OnMapEnd()
{
	for(int i = 0; i <= MaxClients; i++) 
	{
		if(IsValidClient(i))
		{
			g_iMapUser[i] = 0;
		}
	}
}

void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("ScoreShavit");
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_score_shavit.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][Score Standart] - Configuration file not found");
	kfg.Rewind();
	g_Item.Score = kfg.GetNum("score");
	g_Item.Messages = kfg.GetNum("messages");
	g_Item.Map = kfg.GetNum("map");
	g_Item.Bonus = kfg.GetNum("bonus");
	delete kfg;
}