#pragma newdecls required

#include <gangs>
#include <sdktools>
#include <sdkhooks>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>
#define REQUIRE_PLUGIN

enum struct enum_Item
{
	int Bank;
	int SellMode;
	int Price;
	float Delay;
	int ColorForTeam;
	int NoVip;
}

#define PerkName    "skin"

KeyValues ConfigSkins;
char ga_sGangSkin[MAXPLAYERS + 1][32];
char ga_sGangSkinModel[MAXPLAYERS + 1][128];
char ga_sGangSkinArms[MAXPLAYERS + 1][128];
enum_Item g_Item;
bool g_bOnlyTerrorist;
Handle SkinMenu;
bool g_bUse[MAXPLAYERS +1];
int g_iEntity[MAXPLAYERS +1];

bool g_bVipCoreExist = false;
bool g_bGangCoreExist = false;
 
public void OnAllPluginsLoaded()
{
	g_bVipCoreExist = LibraryExists("vip_core");
	g_bGangCoreExist = LibraryExists("gangs");
}
 
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "vip_core"))
		g_bVipCoreExist = false;
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = false;
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "vip_core"))
		g_bVipCoreExist = true;
	if (StrEqual(name, "gangs"))
		g_bGangCoreExist = true;
}

public Plugin myinfo =
{
	name = "[GANGS MODULE] Skins",
	author = "baferpro",
	version = GANGS_VERSION
};

public void Gangs_OnLoaded()
{
	Handle g_hCvar = FindConVar("sm_gangs_terrorist_only");
	if (g_hCvar != INVALID_HANDLE)
		g_bOnlyTerrorist = GetConVarBool(g_hCvar);
	LoadTranslations("gangs.phrases");
	LoadTranslations("gangs_modules.phrases");
	CreateTimer(5.0, AddToPerkMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AddToPerkMenu(Handle timer)
{
	char sQuery[300];
	Format(sQuery, sizeof(sQuery), "SELECT %s FROM gangs_perks;", PerkName);
	Database hDatabase = Gangs_GetDatabase();
	hDatabase.Query(SQLCallback_CheckPerk, sQuery);
	delete hDatabase;

	Gangs_AddToPerkMenu(PerkName, SKINS_CallBack, false);
}

public void SQLCallback_CheckPerk(Database db, DBResultSet hResults, const char[] sError, any iDataPack)
{
	if(sError[0]) // Если произошла ошибка
	{
		if(StrContains(sError, "Duplicate column name", false))
		{
			char sQuery[256];
			if(Gangs_GetDatabaseDriver())
				Format(sQuery, sizeof(sQuery), "ALTER TABLE gangs_perks ADD COLUMN %s varchar(32) NULL DEFAULT NULL;", PerkName);
			else
				Format(sQuery, sizeof(sQuery), "ALTER TABLE gangs_perks ADD COLUMN %s TEXT(32) NULL DEFAULT NULL;", PerkName);
			db.Query(SQLCallback_Void, sQuery);
		}
		else
			LogError("[SQLCallback_CheckPerk] Error :  %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	if(hResults.FetchRow())
	{
		return; // Прекращаем выполнение ф-и
	}
}

public void OnClientDisconnect(int iClient)
{
	ResetVariables(iClient);
}

public void OnClientConnected(int iClient)
{
	ResetVariables(iClient);
}

public void OnClientPutInServer(int iClient)
{
	if(g_bGangCoreExist)
	{
		CreateTimer(2.0, LoadPerkLvl, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		CreateTimer(5.0, ReLoadPerkLvl, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action LoadPerkLvl(Handle hTimer, int iUserID)
{
	int iClient = iUserID;
	if(IsValidClient(iClient) && Gangs_ClientHasGang(iClient))
	{
		char sGangName[256];
		Gangs_GetClientGangName(iClient, sGangName, sizeof(sGangName));
		char sQuery[300];
		Format(sQuery, sizeof(sQuery), "SELECT %s FROM gangs_perks WHERE gang = '%s' AND server_id = %i;", PerkName, sGangName, Gangs_GetServerID());
		Database hDatabase = Gangs_GetDatabase();
		hDatabase.Query(SQLCallback_GetPerkLvl, sQuery, iClient);
		delete hDatabase;
	}
}

public Action ReLoadPerkLvl(Handle hTimer, int iUserID)
{
	OnClientPutInServer(iUserID);
}

public void SQLCallback_GetPerkLvl(Database db, DBResultSet results, const char[] error, int data)
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
		if (results.RowCount == 1)
		{
			results.FetchRow();
			if(!results.IsFieldNull(0))
			{
				results.FetchString(0, ga_sGangSkin[iClient], sizeof(ga_sGangSkin));
				ConfigSkins.Rewind();
				if(ConfigSkins.JumpToKey(ga_sGangSkin[iClient]))
				{
					ConfigSkins.GetString("model", ga_sGangSkinModel[iClient], sizeof(ga_sGangSkinModel[]));
					ConfigSkins.GetString("arms", ga_sGangSkinArms[iClient], sizeof(ga_sGangSkinArms[]));
				}
				else
				{
					Format(ga_sGangSkinModel[iClient], sizeof(ga_sGangSkinModel[]), "NONE");
					Format(ga_sGangSkinArms[iClient], sizeof(ga_sGangSkinArms[]), "NONE");
					LogError("Not found skin %s in config", ga_sGangSkin[iClient]);
				}
			}
			else
			{
				Format(ga_sGangSkin[iClient], sizeof(ga_sGangSkin[]), "NONE");
			}
		}
		else
		{
			Format(ga_sGangSkin[iClient], sizeof(ga_sGangSkin[]), "NONE");
		}
	}
	
	if(StrEqual(ga_sGangSkin[iClient], "ERROR"))
	{
		OnClientPutInServer(iClient);
	}
}

public void OnPluginEnd()
{
	if(g_bGangCoreExist)
		Gangs_DeleteFromPerkMenu(PerkName);
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("This plugin works only on CS:GO");
	}
	
	OnMapStart();
	Gangs_OnLoaded();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			ResetVariables(i);
			OnClientPutInServer(i);
		}
	}
}

public void OnMapStart()
{
	KFG_load();
	LoadConfigSkins("Skins", "configs/gangs/skins.txt");
}

public void OnMapEnd()
{
	delete ConfigSkins;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(iClient))
	{
		if(!Gangs_ClientHasGang(iClient))
			return;
		if(g_bOnlyTerrorist && GetClientTeam(iClient) != 2)
			return;
		if(g_Item.NoVip && g_bVipCoreExist && VIP_IsClientVIP(iClient))
			return;
		CreateTimer(g_Item.Delay, Timer_SetSkins, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_SetSkins(Handle timer, any iClient)
{
	UpdateClientSkinsGang(iClient);
}

public void Gangs_OnGoToGang(int iClient, char[] sGang, int Inviter)
{
	ga_sGangSkin[iClient] = ga_sGangSkin[Inviter];
	ga_sGangSkinModel[iClient] = ga_sGangSkinModel[Inviter];
	ga_sGangSkinArms[iClient] = ga_sGangSkinArms[Inviter];
	UpdateClientSkinsGang(iClient);
}

public void Gangs_OnExitFromGang(int iClient)
{
	ResetVariables(iClient);
	UpdateClientSkinsGang(iClient);
}

void UpdateClientSkinsGang(int iClient)
{
	if (IsValidClient(iClient, _, false) && !StrEqual(ga_sGangSkin[iClient], "ERROR") && !StrEqual(ga_sGangSkin[iClient], "NONE"))
	{
		if(!StrEqual(ga_sGangSkinModel[iClient], "ERROR") && !StrEqual(ga_sGangSkinModel[iClient], "NONE"))
			SetClientSkin(iClient, ga_sGangSkinModel[iClient]);
		if(!StrEqual(ga_sGangSkinArms[iClient], "ERROR") && !StrEqual(ga_sGangSkinArms[iClient], "NONE"))
			SetClientArms(iClient, ga_sGangSkinArms[iClient]);
	}
}

void SetClientSkin(int iClient,char model[128])
{
	if(FileExists(model, true))
	{
		if(IsModelPrecached(model))
		{
			SetEntityModel(iClient,model);
			if(g_Item.ColorForTeam)
			{
				int iTeam = GetClientTeam(iClient);
				int iColor[4];
				GetEntityRenderColor(iClient, iColor[0], iColor[1], iColor[2], iColor[3]);
				SetEntityRenderMode(iClient, RENDER_TRANSCOLOR);
				if(iTeam == 2)
					SetEntityRenderColor(iClient, 255, 0, 0, iColor[3]);
				else if(iTeam == 3)
					SetEntityRenderColor(iClient, 0, 0, 255, iColor[3]);
			}
		}
		else LogError("Model '%s' doesn't pass precache", model);
	}else LogError("Model '%s' not found on the server", model);
}

void SetClientArms(int iClient,char arms[128])
{
	if(FileExists(arms, true))
	{
		//PrecacheModel(arms, true);
		if(IsModelPrecached(arms))
			SetEntPropString(iClient, Prop_Send, "m_szArmsModel", arms);
		else LogError("Arms '%s' doesn't pass precache", arms);
	}else LogError("Arms '%s' not found on the server", arms);
}

public void SKINS_CallBack(int iClient, int ItemID, const char[] ItemName)
{
	char szQuery[256];
	Format(szQuery, sizeof(szQuery),"SELECT gang, %s FROM gangs_perks;", PerkName);
	//PrintToChat(iClient, "%s", PerkName);
	Database hDatabase = Gangs_GetDatabase();
	hDatabase.Query(SQLCallback_OpenSkinMenu, szQuery, iClient);
	delete hDatabase;
}

public void SQLCallback_OpenSkinMenu(Database db, DBResultSet results, const char[] error, int iClient)
{
	if (error[0])
	{
		LogError(error);
		return;
	}
	
	if (!IsValidClient(iClient))
		return;
	else 
	{
		int iRows = results.RowCount;
		int iFields = results.FieldCount;
		//PrintToChat(iClient, "%i-%i", iRows, iFields);
		int i = 0, j;
		char[][][] sBuffer = new char[iRows][iFields][256];
		while(results.FetchRow())
		{
			for(j = 0; j < iFields; ++j)
			{
				results.FetchString(j, sBuffer[i][j], 256);
				//PrintToChat(iClient, "%s", sBuffer[i][1]);
			}	

			i++;
		}
		ConfigSkins.Rewind();
		if(ConfigSkins.GotoFirstSubKey())
		{
			SkinMenu = CreateArray(128);
			do
			{
				char szBuffer[64], szBuffer1[64], option[128];
				bool SkinUse = false;
				ConfigSkins.GetSectionName(szBuffer1, sizeof(szBuffer1));
				ConfigSkins.GetString("name", szBuffer, sizeof(szBuffer));
				for(j = 0; j < iRows; ++j)
				{
					if(StrEqual(szBuffer1, sBuffer[j][1]))
						SkinUse = true;
				}
				if(SkinUse)
					Format(option, sizeof(option), "%s-%s-%s", szBuffer1, szBuffer, "ITEMDRAW_DISABLED");
				else
					Format(option, sizeof(option), "%s-%s-%s", szBuffer1, szBuffer, "ITEMDRAW_DEFAULT");
					
				if(FindStringInArray(SkinMenu, option) == -1)	
					PushArrayString(SkinMenu, option);
			}
			while (ConfigSkins.GotoNextKey());
			OpenMenuSkinGang(iClient);
		}
	}
}

void OpenMenuSkinGang(int iClient)
{
	if (!IsValidClient(iClient))
		return;
	Menu menu = CreateMenu(MenuSkin_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
	char tempBuffer[512];
	Format(tempBuffer, sizeof(tempBuffer), "%T\n%T", "Skin", iClient, "currentskin", iClient, iClient, ga_sGangSkin[iClient]);
	SetMenuTitle(menu, tempBuffer);
	if(GetArraySize(SkinMenu) > 0)
	{
		for(int i = 0; i < GetArraySize(SkinMenu); i++)
		{
			char menu_string[256];
			GetArrayString(SkinMenu, i, menu_string, sizeof(menu_string));
			char menu_options[3][128];
			ExplodeString(menu_string, "-", menu_options, 3, 128);
			menu.AddItem(menu_options[0], menu_options[1], (StrEqual(menu_options[2], "ITEMDRAW_DISABLED"))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuSkin_Callback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if (!IsValidClient(iClient))
		return;
	switch (action)
	{
		case MenuAction_Select:
		{
			char szInfo[64], szTitle[128];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));
			OpenMenuSkinSet(iClient, szInfo);
		}
		case MenuAction_Cancel:
			if(iItem == MenuCancel_ExitBack)
				Gangs_ShowPerksMenu(iClient);
		case MenuAction_End: delete hMenu;
	}
	return;
}

void OpenMenuSkinSet(int iClient, char buffer[64])
{
	if (!IsValidClient(iClient))
		return;
	Menu menu = new Menu(MenuSkinSet_Callback, MenuAction_End|MenuAction_Cancel|MenuAction_Select|MenuAction_DrawItem);
	ConfigSkins.Rewind();
	if(ConfigSkins.JumpToKey(buffer))
	{
		char szBuffer[64], sDisplayBuffer[128];
		ConfigSkins.GetString("name", szBuffer, sizeof(szBuffer));
		SetMenuTitle(menu, szBuffer);
		
		switch(g_Item.SellMode)
		{
			case 0:
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %i %T", "setskin", iClient, g_Item.Price, "rubles", iClient);
			case 1:
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %i %T", "setskin", iClient, g_Item.Price, "shop", iClient);
			case 2:
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %i %T", "setskin", iClient, g_Item.Price, "shopgold", iClient);
			case 3:
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %i %T", "setskin", iClient, g_Item.Price, "wcsgold", iClient);
			case 4:
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %i %T", "setskin", iClient, g_Item.Price, "lkrubles", iClient);
			case 5:
				Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %i %T", "setskin", iClient, g_Item.Price, "myjb", iClient);
		}
		menu.AddItem(buffer, sDisplayBuffer);
		Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "preview", iClient);
		menu.AddItem(buffer, sDisplayBuffer);
	}
	menu.ExitBackButton = true;
	menu.Display(iClient, MENU_TIME_FOREVER);
}

public int MenuSkinSet_Callback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if (!IsValidClient(iClient))
		return 0;
	switch (action)
	{
		case MenuAction_Select:
		{
			char szInfo[64], szTitle[128];
			hMenu.GetItem(iItem, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));
			if(iItem == 0)
			{
				char sQuery[256];
				Format(sQuery, sizeof(sQuery),"SELECT gang FROM gangs_perks WHERE %s = '%s' AND server_id = %i;", PerkName, szInfo, Gangs_GetServerID());
				DataPack hPack = new DataPack();
				hPack.WriteCell(iClient);
				hPack.WriteString(szInfo);
				Database hDatabase = Gangs_GetDatabase();
				hDatabase.Query(SQLCallback_CheckSkin, sQuery, hPack);
				delete hDatabase;
			}
			else if (iItem == 1)
			{
				if(IsPlayerAlive(iClient))
				{
					if(!g_bUse[iClient])
					{
						if((g_iEntity[iClient] = CreateEntityByName("prop_physics_override")) != -1)
						{
							ConfigSkins.Rewind();
							if(ConfigSkins.JumpToKey(szInfo))
							{
								char g_sModel[128];
								ConfigSkins.GetString("model", g_sModel, sizeof(g_sModel));
								DispatchKeyValue(g_iEntity[iClient], "model", g_sModel);
								DispatchKeyValue(g_iEntity[iClient], "physicsmode", "2");
								DispatchKeyValue(g_iEntity[iClient], "massScale", "1.0");
								DispatchKeyValue(g_iEntity[iClient], "spawnflags", "0");
								DispatchSpawn(g_iEntity[iClient]); 
								SetEntProp(g_iEntity[iClient], Prop_Send, "m_usSolidFlags",	 8);
								SetEntProp(g_iEntity[iClient], Prop_Send, "m_CollisionGroup", 1);
								float fPos[3], fAng[3];
								GetClientEyePosition(iClient, fPos);
								GetClientEyeAngles(iClient, fAng);
								TR_TraceRayFilter(fPos, fAng, MASK_SOLID, RayType_Infinite, Filter, iClient);
								TR_GetEndPosition(fPos);
								GetClientAbsAngles(iClient, fAng); fAng[1] -= 180.0;
								TeleportEntity(g_iEntity[iClient], fPos, fAng, NULL_VECTOR);
								SetEntityMoveType(g_iEntity[iClient], MOVETYPE_NONE);
								SDKHook(g_iEntity[iClient], SDKHook_SetTransmit, SetTransmit);
								g_bUse[iClient] = true;
								OpenMenuSkinGang(iClient);
								CreateTimer(5.0, Timer_DeletePrw, iClient);
							}
							else LogError("Not found skin %s in config", szInfo);
						}
					}
					else CPrintToChat(iClient, "%t %t", "Prefix", "NotSoFast");
				}
				else CPrintToChat(iClient, "%t %t", "Prefix", "OnlyAlive");
			}
		}
		case MenuAction_End: delete hMenu;
		case MenuAction_DrawItem:
		{
			if(iItem == 0)
			{
				int ClientCash;
				if(g_Item.Bank)
				{
					switch(g_Item.SellMode)
					{
						case 0:
							ClientCash = Gangs_GetBankClientCash(iClient, "rubles");
						case 1:
							ClientCash = Gangs_GetBankClientCash(iClient, "shop");
						case 2:
							ClientCash = Gangs_GetBankClientCash(iClient, "shopgold");
						case 3:
							ClientCash = Gangs_GetBankClientCash(iClient, "wcsgold");
						case 4:
							ClientCash = Gangs_GetBankClientCash(iClient, "lkrubles");
						case 5:
							ClientCash = Gangs_GetBankClientCash(iClient, "myjb");
					}
				}
				else
				{
					switch(g_Item.SellMode)
					{
						case 0:
							ClientCash = Gangs_GetClientCash(iClient, "rubles");
						case 1:
							ClientCash = Gangs_GetClientCash(iClient, "shop");
						case 2:
							ClientCash = Gangs_GetClientCash(iClient, "shopgold");
						case 3:
							ClientCash = Gangs_GetClientCash(iClient, "wcsgold");
						case 4:
							ClientCash = Gangs_GetClientCash(iClient, "lkrubles");
						case 5:
							ClientCash = Gangs_GetClientCash(iClient, "myjb");
					}
				}
				if(ClientCash < g_Item.Price)
					return ITEMDRAW_DISABLED;
				else return ITEMDRAW_DEFAULT;
			}
		}
	}
	return 0;
}

public Action Timer_DeletePrw(Handle hTimer, int userid)
{
	int iClient = userid;
	if(IsValidClient(iClient))
		DeleteEntity(iClient);
}

bool Filter(int iEnt, int iMask, any iEntity)
{
	return iEnt != iEntity;
}

public Action SetTransmit(int iEntity, int iClient) 
{ 
	return g_bUse[iClient]?Plugin_Continue:Plugin_Handled; 
}

void DeleteEntity(int iClient)
{
	if(g_iEntity[iClient] > 0 && IsValidEntity(g_iEntity[iClient])) AcceptEntityInput(g_iEntity[iClient], "Kill"); 
	g_bUse[iClient] = false;
}

public void SQLCallback_CheckSkin(Database db, DBResultSet results, const char[] error, Handle hDataPack)
{
	if (error[0])
	{
		LogError(error);
		return;
	}
	
	DataPack hPack = view_as<DataPack>(hDataPack);
	hPack.Reset();
	int iClient = hPack.ReadCell();
	char szBuffer[256];
	hPack.ReadString(szBuffer, sizeof(szBuffer));
	delete hPack;
	if (!IsValidClient(iClient))
		return;
	else 
	{
		if(results.RowCount == 0)
		{
			ConfigSkins.Rewind();
				
			if(ConfigSkins.JumpToKey(szBuffer))
			{
				if(g_Item.Bank)
				{
					switch(g_Item.SellMode)
					{
						case 0:
							Gangs_TakeBankClientCash(iClient, "rubles", g_Item.Price);
						case 1:
							Gangs_TakeBankClientCash(iClient, "shop", g_Item.Price);
						case 2:
							Gangs_TakeBankClientCash(iClient, "shopgold", g_Item.Price);
						case 3:
							Gangs_TakeBankClientCash(iClient, "wcsgold", g_Item.Price);
						case 4:
							Gangs_TakeBankClientCash(iClient, "lkrubles", g_Item.Price);
						case 5:
							Gangs_TakeBankClientCash(iClient, "myjb", g_Item.Price);
					}
				}
				else
				{
					switch(g_Item.SellMode)
					{
						case 0:
							Gangs_TakeClientCash(iClient, "rubles", g_Item.Price);
						case 1:
							Gangs_TakeClientCash(iClient, "shop", g_Item.Price);
						case 2:
							Gangs_TakeClientCash(iClient, "shopgold", g_Item.Price);
						case 3:
							Gangs_TakeClientCash(iClient, "wcsgold", g_Item.Price);
						case 4:
							Gangs_TakeClientCash(iClient, "lkrubles", g_Item.Price);
						case 5:
							Gangs_TakeClientCash(iClient, "myjb", g_Item.Price);
					}
				}
				ConfigSkins.GetString("model", ga_sGangSkinModel[iClient], sizeof(ga_sGangSkinModel[]));
				ConfigSkins.GetString("arms", ga_sGangSkinArms[iClient], sizeof(ga_sGangSkinArms[]));
				Format(ga_sGangSkin[iClient], sizeof(ga_sGangSkin[]), szBuffer);
				char sGangName[MAXPLAYERS+1][256];
				Gangs_GetClientGangName(iClient, sGangName[iClient], sizeof(sGangName));
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && iClient != i)
					{
						Gangs_GetClientGangName(i, sGangName[i], sizeof(sGangName));
						if (StrEqual(sGangName[i], sGangName[iClient]))
						{
							ga_sGangSkin[i] = ga_sGangSkin[iClient];
							ga_sGangSkinModel[i] = ga_sGangSkinModel[iClient];
							ga_sGangSkinArms[i] = ga_sGangSkinArms[iClient];
						}
					}
				}
				char sQuery[256];
				Format(sQuery, sizeof(sQuery),"UPDATE gangs_perks SET %s = '%s' WHERE gang = '%s' AND server_id = %i;", PerkName, szBuffer, sGangName[iClient], Gangs_GetServerID());
				//PrintToChatAll("%s-%s", szBuffer, sGangName[iClient]); 
				Database hDatabase = Gangs_GetDatabase();
				hDatabase.Query(SQLCallback_Void, sQuery);
				Format(sQuery, sizeof(sQuery),"SELECT gang, %s FROM gangs_perks", PerkName);
				hDatabase.Query(SQLCallback_OpenSkinMenu, sQuery, iClient);
				delete hDatabase;
			}
			else LogError("Not found skin %s in config", szBuffer);
		}
	}
}

void KFG_load()
{
	char path[128];
	KeyValues kfg = new KeyValues("GANGS_MODULE");
	BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_module_skins.ini");
	if(!kfg.ImportFromFile(path)) SetFailState("[GANGS MODULE][Gravity] - Configuration file not found");
	kfg.Rewind();
	g_Item.Bank = kfg.GetNum("bank");
	g_Item.SellMode = kfg.GetNum("sell_mode");
	g_Item.Price = kfg.GetNum("price");
	g_Item.Delay = kfg.GetFloat("delay");
	g_Item.ColorForTeam = kfg.GetNum("color_for_team");
	g_Item.NoVip = kfg.GetNum("no_vip");
	delete kfg;
}

void ResetVariables(int iClient)
{
	ga_sGangSkin[iClient] = "ERROR";
	ga_sGangSkinModel[iClient] = "ERROR";
	ga_sGangSkinArms[iClient] = "ERROR";
}

void LoadConfigSkins(char kvName[256],char file[256])
{
	delete ConfigSkins;
	ConfigSkins = new KeyValues(kvName);
	char SzBuffer[256];
	BuildPath(Path_SM, SzBuffer,256, file);
	ConfigSkins.ImportFromFile(SzBuffer);
}

public void SQLCallback_Void(Database db, DBResultSet results, const char[] error, int data)
{
	if (error[0])
	{
		LogError("Error (%i): %s", data, error);
	}
}