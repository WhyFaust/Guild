#pragma newdecls required
#include <sourcemod>
#include <cstrike>
#include <gangs>

public Plugin myinfo = 
{
	name = "[GANGS MODULE] Tag",
	author = "DeeperSpy, baferpro",
	version = GANGS_VERSION
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsValidClient(iClient) && Gangs_ClientHasGang(iClient))
	{
		char sGang[128];
		Gangs_GetClientGangName(iClient, sGang, sizeof(sGang));
		CS_SetClientClanTag(iClient, sGang);
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(iClient) && Gangs_ClientHasGang(iClient))
	{
		char sGang[128];
		Gangs_GetClientGangName(iClient, sGang, sizeof(sGang));
		CS_SetClientClanTag(iClient, sGang);
	}
	
	return Plugin_Continue;
}

public void Gangs_OnGoToGang(int iClient)
{
	char sGang[128];
	Gangs_GetClientGangName(iClient, sGang, sizeof(iClient));
	CS_SetClientClanTag(iClient, sGang);
}

public void Gangs_OnExitFromGang(int iClient)
{
	CS_SetClientClanTag(iClient, "");
}