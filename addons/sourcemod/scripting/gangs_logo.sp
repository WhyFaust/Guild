#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <gangs>

#define Scoreboard_Reveal 1

int m_nPersonaDataPublicLevel;

public Plugin myinfo = 
{
	name = "[Gangs] Logo", 
	author = "baferpro", 
	version = GANGS_VERSION
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}	
	
	OnMapStart();

	m_nPersonaDataPublicLevel = FindSendPropInfo("CCSPlayerResource", "m_nPersonaDataPublicLevel");
}

public void OnMapStart()
{
	KFG_load();

	CreateTimer(2.0, Timer_ReCheck);
}

public Action Timer_ReCheck(Handle timer)
{
	if(GetPlayerResourceEntity() != -1)
		SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
	else
		CreateTimer(2.0, Timer_ReCheck);
}

void OnThinkPost(int iEnt)
{
	for(int i; i <=MaxClients; i++)
	{
		if(IsValidClient(i) && Gangs_ClientHasGang(i))
		{
			char sGangName[128];
			Gangs_GetClientGangName(i,sGangName, sizeof(sGangName));
				
			char path[128];
			KeyValues kfg = new KeyValues("GANGS_MODULE");
			BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_logo.ini");
			if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][Logo] - Configuration file not found");
			kfg.Rewind();
			if(kfg.JumpToKey(sGangName)) // Попытка перейти к ключу "key1"
			{
				int iValue = kfg.GetNum("level");
				SetEntData(iEnt, m_nPersonaDataPublicLevel + i*4, iValue);
			}
			else
				SetEntData(iEnt, m_nPersonaDataPublicLevel + i*4, 0);
			delete kfg;
		}
		else
			SetEntData(iEnt, m_nPersonaDataPublicLevel + i*4, 0);
	}
}

#if Scoreboard_Reveal
public void OnPlayerRunCmdPost(int iClient, int iButtons)
{
	static int iOldButtons[MAXPLAYERS+1];

	if(iButtons & IN_SCORE && !(iOldButtons[iClient] & IN_SCORE))
	{
		StartMessageOne("ServerRankRevealAll", iClient, USERMSG_BLOCKHOOKS);
		EndMessage();
	}

	iOldButtons[iClient] = iButtons;
}
#endif

void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("GANGS_MODULE");
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_logo.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][Logo] - Configuration file not found");
	kfg.Rewind();
	if(kfg.GotoFirstSubKey()) // Переходим к первому ключу внутри "GlobalKey"
	{
		do	  // Создаем цикл с послеусловием
		{
			static char sBuffer[PLATFORM_MAX_PATH];
			int iValue = kfg.GetNum("level");
			FormatEx(sBuffer, sizeof(sBuffer), "materials/panorama/images/icons/xp/level%i.png", iValue);
			AddFileToDownloadsTable(sBuffer);
		} while (kfg.GotoNextKey());
	}
	delete kfg;
}