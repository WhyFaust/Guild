#pragma newdecls required

#include <sourcemod>
#include <gangs>
#include <gifts_core>

public Plugin myinfo =
{
	name = "[Gangs] Score Gift",
	author = "R1KO, BaFeR",
	version = GANGS_VERSION
}

public void OnPluginStart()
{	
	Handle core = FindPluginByFile("gangs.smx"); 
	if (core != INVALID_HANDLE) PrintToServer("Success"); 
	else SetFailState("Core not found");
	
	char sVersion[128];
	if (GetPluginInfo(core, PlInfo_Version, sVersion, sizeof(sVersion)))
	{
		if(!StrEqual(sVersion, "1.2 [Private]")) 
			SetFailState("This plugin not work with this core version");
	}
	else SetFailState("Failed to get core version"); 
	core = INVALID_HANDLE;
}

public int Gifts_OnPickUpGift_Post(int iClient, Handle hKeyValues)
{
	if(IsValidClient(iClient))
	{
		int iValue = KvGetNum(hKeyValues, "gangs_score", 0);
		if(iValue && Gangs_ClientHasGang(iClient))
		{
			Gangs_SetClientGangScore(iClient, iValue);
		}
	}
}