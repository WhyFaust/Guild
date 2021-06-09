#pragma newdecls required

#include <gangs>

public Plugin myinfo = 
{
	name = "[Gangs] Admin Menu", 
	author = "Faust", 
	version = GANGS_VERSION
}

public void OnPluginStart()
{	
	RegAdminCmd("sm_gangadmin", Command_GangAdmin, ADMFLAG_ROOT);
}

public Action Command_GangAdmin(int iClient, int args)
{
	if (!IsValidClient(iClient))
	{
		ReplyToCommand(iClient, "[SM] %T", "PlayerNotInGame", iClient);
		return Plugin_Handled;
	}	
	Menu menu = new Menu(MenuHandler);
	menu.SetTitle("Gangs Admin Menu");
	menu.AddItem("0", "GangsDissolve");
	menu.AddItem("1", "KickMember");
	menu.AddItem("2", "Score");
	menu.ExitBackButton = false;
	menu.Display(iClient, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int client = param1;

			char info[16];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				int iParam2 = StringToInt(info);

				switch (iParam2)
				{
					case 0:
						StartOpeningGangsList(client);
					case 1:
						StartOpeningGangsList1(client);
					case 2:
						StartOpeningGangsList2(client);
				}
			}
			menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
	}
}

void StartOpeningGangsList(int iClient)
{
	Database hDatabase = Gangs_GetDatabase();
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT gang FROM gangs_groups WHERE server_id = %i;", Gangs_GetServerID());
	hDatabase.Query(SQLCallback_OneOpenGangAdminMenu, sQuery, iClient);
	delete hDatabase;
}

public void SQLCallback_OneOpenGangAdminMenu(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError(error);
		return;
	}
	
	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		Menu menu = new Menu(MenuHandlerGangName);
		menu.SetTitle("Pick gang for dissolve:");
		
		while(results.FetchRow())
		{
			char GangName[128];
			results.FetchString(0, GangName, sizeof(GangName));
			menu.AddItem(GangName, GangName);
		}
		
		menu.ExitBackButton = true;
		menu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int MenuHandlerGangName(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int client = param1;

			char info[32];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				OpenConfirmMenu(client, info);
			}
			//menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
	}
}

public void OpenConfirmMenu(int client, char[] info)
{
	//info - GangName
	Menu menu = new Menu(MenuHandlerConfirmMenu);
	char sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "Dissolve Gang %s?", info);
	menu.SetTitle(sBuffer);
				
	menu.AddItem(info, "Yes");
	menu.AddItem("0", "No");
				
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandlerConfirmMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int client = param1;

			char info[16];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				if(!StrEqual(info, "0"))
				{
					Gangs_DissolveGang(StringToInt(info));
					StartOpeningGangsList(client);
				}
				else
				{
					StartOpeningGangsList(client);
				}
			}
			//menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
		}
	}
}

void StartOpeningGangsList1(int iClient)
{
	Database hDatabase = Gangs_GetDatabase();
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT id, name \
									FROM gang_group \
									WHERE server_id = %i;", 
									Gangs_GetServerID());
	hDatabase.Query(SQLCallback_OneOpenGangAdminMenu1, sQuery, iClient);
	delete hDatabase;
}

public void SQLCallback_OneOpenGangAdminMenu1(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError(error);
		return;
	}
	
	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		Menu menu = new Menu(MenuHandlerGangName1);
		menu.SetTitle("Pick gang:");
		
		while(results.FetchRow())
		{
			char GangId[4];
			IntToString(results.FetchInt(0), GangId, sizeof(GangId));
			char GangName[128];
			results.FetchString(1, GangName, sizeof(GangName));
			menu.AddItem(GangId, GangName);
		}
		
		menu.ExitBackButton = true;
		
		menu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int MenuHandlerGangName1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int iClient = param1;

			char info[32];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				Database hDatabase = Gangs_GetDatabase();
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "SELECT name, steam_id, rank \
												FROM gang_player \
												WHERE gang_id = %i;", 
												StringToInt(info));
				hDatabase.Query(SQLCallback_GangPlayerList, sQuery, iClient);
				delete hDatabase;
			}
		}
	}
}

public void SQLCallback_GangPlayerList(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError(error);
		return;
	}
	
	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		Menu menu = new Menu(MenuHandlerPlayersList);
		menu.SetTitle("Pick player:");
		
		while(results.FetchRow())
		{
			char sPlayerName[256], sPlayerSteamID[256], sMenu[256];
			results.FetchString(0, sPlayerName, sizeof(sPlayerName));
			results.FetchString(1, sPlayerSteamID, sizeof(sPlayerSteamID));
			int iRank = results.FetchInt(2);
			if(iRank != 3)
			{
				Format(sMenu, sizeof(sMenu), "%s [%s]", sPlayerName, sPlayerSteamID);
				menu.AddItem(sPlayerSteamID, sMenu);
			}
		}
		
		menu.ExitBackButton = true;
		
		menu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int MenuHandlerPlayersList(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int iClient = param1;

			Gangs_KickMember(iClient);
			StartOpeningGangsList1(iClient);
		}
	}
}

void StartOpeningGangsList2(int iClient)
{
	Database hDatabase = Gangs_GetDatabase();
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT gang \
									FROM gangs_groups \
									WHERE server_id = %i;", Gangs_GetServerID());
	hDatabase.Query(SQLCallback_OneOpenGangAdminMenu2, sQuery, iClient);
	delete hDatabase;
}

public void SQLCallback_OneOpenGangAdminMenu2(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError(error);
		return;
	}
	
	int iClient = data;
	if (!IsValidClient(iClient))
	{
		return;
	}
	else 
	{
		Menu menu = new Menu(MenuHandlerGangName2);
		menu.SetTitle("Pick gang:");
		
		while(results.FetchRow())
		{
			char GangName[128];
			results.FetchString(0, GangName, sizeof(GangName));
			menu.AddItem(GangName, GangName);
		}
		
		menu.ExitBackButton = true;
		
		menu.Display(iClient, MENU_TIME_FOREVER);
	}
}

public int MenuHandlerGangName2(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int iClient = param1;

			char info[32];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				Menu menu1 = new Menu(MenuHandlerGangName3);
				menu1.SetTitle("Gang %s", info);
				
				char sItem[32];
				Format(sItem, sizeof(sItem), "1_%s", info);
				menu1.AddItem(sItem, "Give");
				Format(sItem, sizeof(sItem), "2_%s", info);
				menu1.AddItem(sItem, "Take");
				
				menu1.ExitBackButton = true;
				
				menu1.Display(iClient, MENU_TIME_FOREVER);
			}
		}
	}
}

public int MenuHandlerGangName3(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int iClient = param1;

			char info[32];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				char sInfo[2][64];
				ExplodeString(info, "_", sInfo, sizeof(sInfo), sizeof(sInfo[]));
				if(StrEqual(sInfo[0],"1",true))
				{
					char path[128];
					KeyValues kfg = new KeyValues("GangAdmin");
					BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_adminmenu.ini");
					if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][AdminMenu] - Configuration file not found");
					kfg.Rewind();
					
					Menu menu1 = new Menu(MenuHandlerGangName4);
					menu1.SetTitle("Gang %s", sInfo[1]);
					
					if(kfg.JumpToKey("menu"))
					{
						char KeyName[256];
						kfg.GotoFirstSubKey(false); 
						do
						{
							kfg.GetString(NULL_STRING, KeyName, sizeof(KeyName));
							char sItem[34];
							Format(sItem, sizeof(sItem), "%s_%s", sInfo[1], KeyName);
							menu1.AddItem(sItem, KeyName);
						} while (kfg.GotoNextKey(false));
					}
					
					menu1.ExitBackButton = true;
					menu1.Display(iClient, MENU_TIME_FOREVER);
					
					delete kfg;
					
				}
				else if(StrEqual(sInfo[0],"2",true))
				{
					char path[128];
					KeyValues kfg = new KeyValues("GangAdmin");
					BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_adminmenu.ini");
					if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][AdminMenu] - Configuration file not found");
					kfg.Rewind();
					
					Menu menu1 = new Menu(MenuHandlerGangName5);
					menu1.SetTitle("Gang %s", sInfo[1]);
					
					if(kfg.JumpToKey("menu"))
					{
						char KeyName[256];
						kfg.GotoFirstSubKey(false); 
						do
						{
							kfg.GetString(NULL_STRING, KeyName, sizeof(KeyName));
							char sItem[34];
							Format(sItem, sizeof(sItem), "%s_%s", sInfo[1], KeyName);
							menu1.AddItem(sItem, KeyName);
						} while (kfg.GotoNextKey(false));
					}
					
					menu1.ExitBackButton = true;
					menu1.Display(iClient, MENU_TIME_FOREVER);
					
					delete kfg;
				}
			}
		}
	}
}

public int MenuHandlerGangName4(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int iClient = param1;

			char info[32];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				char sInfo[2][64];
				ExplodeString(info, "_", sInfo, sizeof(sInfo), sizeof(sInfo[])); // 0 - Gang Name | 1 - Members count
				
				Handle g_hCvar = FindConVar("sm_gangs_db_statistic_name");
				char sBuffer[64];
				if (g_hCvar != INVALID_HANDLE)
					GetConVarString(g_hCvar, sBuffer, sizeof(sBuffer));
				
				Database hDatabase = Gangs_GetDatabase();
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE gangs_statistics SET %s = %s+%s WHERE gang = '%s' AND server_id = %i;", sBuffer, sBuffer, sInfo[1], sInfo[0], Gangs_GetServerID());
				hDatabase.Query(SQLCallback_Void, sQuery, iClient);
				delete hDatabase;
				for(int i=0; i < MaxClients; ++i) 
				{
					if(Gangs_ClientHasGang(i))
					{
						char sGang[64];
						Gangs_GetClientGangName(i, sGang, sizeof(sGang));
						if(StrEqual(sGang, sInfo[0]))
							if(IsValidClient(i))
								Gangs_ReloadClient(i);
					}
				}
			}
		}
	}
}

public int MenuHandlerGangName5(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{		
		case MenuAction_Select:
		{
			int iClient = param1;

			char info[32];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				char sInfo[2][64];
				ExplodeString(info, "_", sInfo, sizeof(sInfo), sizeof(sInfo[])); // 0 - Gang Name | 1 - Members count
				
				Handle g_hCvar = FindConVar("sm_gangs_db_statistic_name");
				char sBuffer[64];
				if (g_hCvar != INVALID_HANDLE)
					GetConVarString(g_hCvar, sBuffer, sizeof(sBuffer));
				
				Database hDatabase = Gangs_GetDatabase();
				char sQuery[300];
				Format(sQuery, sizeof(sQuery), "UPDATE gangs_statistics SET %s = %s-%s WHERE gang = '%s' AND server_id = %i;", sBuffer, sBuffer, sInfo[1], sInfo[0], Gangs_GetServerID());
				hDatabase.Query(SQLCallback_Void, sQuery, iClient);
				delete hDatabase;
				for(int i=0; i < MaxClients; ++i) 
				{
					if(Gangs_ClientHasGang(i))
					{
						char sGang[64];
						Gangs_GetClientGangName(i, sGang, sizeof(sGang));
						if(StrEqual(sGang, sInfo[0]))
							if(IsValidClient(i))
								Gangs_ReloadClient(i);
					}
				}
			}
		}
	}
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError(error);
	}
}