#pragma newdecls required

#include <csgocolors>
#include <gangs>
#include <autoexecconfig>

bool g_bChatTagMode;
ConVar g_cvChatCommand;

public Plugin myinfo = 
{
	name = "[Gangs] Chat", 
	author = "Faust", 
	version = GANGS_VERSION,
	url = "Faust#8073"
}

public void OnPluginStart()
{		
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");

	AutoExecConfig_SetFile("gangs_chat");
	
	g_cvChatCommand = AutoExecConfig_CreateConVar("sm_gangs_chat_command", "sm_g", "Command for gang chat");

	ConVar CVar;
	(CVar = AutoExecConfig_CreateConVar("sm_gangs_chat_tag_mode", "0", "Как отображать Название ранга / 1 - целиком / 0 - только первая буква")).AddChangeHook(UpdateChatTagMode);
	g_bChatTagMode = CVar.BoolValue;
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public void OnConfigsExecuted()
{
	char sCommand[64];
	g_cvChatCommand.GetString(sCommand, sizeof(sCommand));
	if (GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)
	{
		RegConsoleCmd(sCommand, Command_GangChat, "Command for gang chat");
	}
}

void UpdateChatTagMode(ConVar convar, char [] oldValue, char [] newValue)
{
	g_bChatTagMode = convar.BoolValue;
}

public Action Command_GangChat(int iClient, int args)
{
	if (!IsValidClient(iClient) || !Gangs_ClientHasGang(iClient))
	{
		return Plugin_Continue;
	}

	char sMessage[MAX_MESSAGE_LENGTH];
	GetCmdArgString(sMessage, sizeof(sMessage));

	TrimString(sMessage);
	StripQuotes(sMessage);

	if(!StrEqual(sMessage, ""))
	{
		char sRank[128];
		KeyValues ConfigRanks;
		ConfigRanks = new KeyValues("Ranks");
		char szBuffer[256];
		BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
		ConfigRanks.ImportFromFile(szBuffer);
		ConfigRanks.Rewind();
		char buffer[16];
		IntToString(Gangs_GetClientGangRank(iClient), buffer, sizeof(buffer));
		if(ConfigRanks.JumpToKey(buffer))
		{
			ConfigRanks.GetString("Name", szBuffer, sizeof(szBuffer));
			Format(sRank, sizeof(sRank), "%t", szBuffer);
		}
		delete ConfigRanks;
		char szName[MAX_NAME_LENGTH], sGangName1[128], sGangName2[128];
		GetClientName(iClient, szName, sizeof(szName));
		Gangs_GetClientGangName(iClient, sGangName1, sizeof(sGangName1));
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && Gangs_ClientHasGang(i))
			{
				Gangs_GetClientGangName(i, sGangName2, sizeof(sGangName2));
				if(StrEqual(sGangName1, sGangName2))
				{
					if(!g_bChatTagMode)
						sRank[2] = 0;
					
					CPrintToChat(i, "%t", "GangChatMessage", sRank, szName, sMessage);
				}
			}
		}
	}
		
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	char sCommand[64];
	g_cvChatCommand.GetString(sCommand, sizeof(sCommand));
	ReplaceString(sCommand, sizeof(sCommand), "sm_", "!");
	if(StrContains(sArgs, sCommand) == 0)
		return Plugin_Handled;
	else
		return Plugin_Continue;
}