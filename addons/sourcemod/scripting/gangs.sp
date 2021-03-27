#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <autoexecconfig>
#include <gangs>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <gamecms_system>
#tryinclude <shop>
#tryinclude <wcs>
#tryinclude <lk>
#tryinclude <gangs_size>
#tryinclude <myjailshop>
#tryinclude <gangs_statistic_rating>
#define REQUIRE_PLUGIN

#include "gangs/Globals.sp"
#include "gangs/Natives.sp"
#include "gangs/Forwards.sp"
#include "gangs/Cmds.sp"
#include "gangs/Database.sp"
#include "gangs/Stocks.sp"
#include "gangs/Menus.sp"

public void OnLibraryRemoved(const char[] name)
{
    if(StrEqual(name, "lk"))
    {
        g_bLKLoaded = false;
    }
    if(StrEqual(name, "gamecms_system"))
    {
        g_bGameCMSExist = false;
    }
    if(StrEqual(name, "gangs_size"))
    {
        g_bModuleSizeExist = false;
    }
    if(StrEqual(name, "myjailshop"))
    {
        g_bMyJBShopExist = false;
    }
    if(StrEqual(name, "gangs_statistic_rating"))
    {
        g_bStatisticRating = false;
    }
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "lk"))
    {
        g_bLKLoaded = true;
    }
    if(StrEqual(name, "gamecms_system"))
    {
        g_bGameCMSExist = true;
    }
    if(StrEqual(name, "gangs_size"))
    {
        g_bModuleSizeExist = true;
    }
    if(StrEqual(name, "myjailshop"))
    {
        g_bMyJBShopExist = true;
    }
    if(StrEqual(name, "gangs_statistic_rating"))
    {
        g_bStatisticRating = true;
    }
}

public Plugin myinfo =
{
    name = "Gangs",
    author = "Faust [PUBLIC]",
    description = "Gang system for server cs",
    version = GANGS_VERSION
};

public void OnPluginStart()
{
    //#emit load.s.pri 0
    BuildPath(Path_SM, g_sFile, sizeof(g_sFile), "configs/gangs/info.ini");

    LoadTranslations("gangs.phrases");
    LoadTranslations("gangs_modules.phrases");
    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    
    AutoExecConfig_SetFile("gangs");
    ConVar CVar;
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_enabled", "1", "Включить плагин? (1 = Да, 0 = Нет)", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(UpdatePluginEnabled);
    g_bPluginEnabled = CVar.BoolValue;
    
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_invite_style", "1", "Стиль для принятия приглашения в банду. \n(1 = Через Меню, 0 = Через комманду !accept)", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(UpdateInviteStyle);
    g_bInviteStyle = CVar.BoolValue;
    
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_terrorist_only", "0", "Все фун-ии доступны только Т команде?\n(1 - Да, только для Т, 0 - Для всех команд)")).AddChangeHook(UpdateTerroristOnly);
    g_bTerroristOnly = CVar.BoolValue;
    
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_db_statistic_name", "total", "Название столбца киллов в базе статистики")).AddChangeHook(UpdateDbStatisticName);
    CVar.GetString(g_sDbStatisticName, sizeof(g_sDbStatisticName));
    
    g_cvCustomCommands = AutoExecConfig_CreateConVar("sm_gangs_custom_commands", "g, gang, gangs, guild, guilds, b, banda", "Команды открытия Меню Банд\n Разделять через ','");
    
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
    
    CreateArrays();
    CreateForwardss();
    RegAllCmds();
    
    RegConsoleCmd("gangs_config_reload", Command_Gang_Config_Reload, "Reload config file!");
                
    AddCommandListener(OnSay, "say"); 
    AddCommandListener(OnSay, "say_team");
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i))
        {
            LoadSteamID(i);
            OnClientPutInServer(i);
        }
    }
    OnMapStart();
}

public void OnAllPluginsLoaded()
{
    DB_OnPluginStart();

    g_bLKLoaded = LibraryExists("lk");
    g_bGameCMSExist = LibraryExists("gamecms_system");
    g_bModuleSizeExist = LibraryExists("gangs_size");
    g_bMyJBShopExist = LibraryExists("myjailshop");
    g_bStatisticRating = LibraryExists("gangs_statistic_rating");
    
    if(GetFeatureStatus(FeatureType_Native, "Shop_GetClientGold") == FeatureStatus_Available && GetFeatureStatus(FeatureType_Native, "Shop_SetClientGold") == FeatureStatus_Available)
        g_bLShopGoldExist = true;
    else
        g_bLShopGoldExist = false;
}

void UpdatePluginEnabled(ConVar convar, char [] oldValue, char [] newValue)
{
    g_bPluginEnabled = convar.BoolValue;
}

void UpdateInviteStyle(ConVar convar, char [] oldValue, char [] newValue)
{
    g_bInviteStyle = convar.BoolValue;
}

void UpdateTerroristOnly(ConVar convar, char [] oldValue, char [] newValue)
{
    g_bTerroristOnly = convar.BoolValue;
}

void UpdateDbStatisticName(ConVar convar, char [] oldValue, char [] newValue)
{
    convar.GetString(g_sDbStatisticName, sizeof(g_sDbStatisticName));
}

public Action Command_Gang_Config_Reload(int iClient, int args)
{
    OnMapStart();
    return Plugin_Handled;
}

public void OnMapStart()
{
    if(g_bPluginEnabled)
    {
        LoadConfigSettings("Setting", "configs/gangs/settings.txt");
    
        ConfigSettings.Rewind();

        g_bLog = ConfigSettings.GetNum("log");
        g_bDebug = ConfigSettings.GetNum("debug");
        
        g_iServerID = ConfigSettings.GetNum("server_id");
        
        if(ConfigSettings.JumpToKey("gang"))
        {
            g_bMenuValue = ConfigSettings.GetNum("menu_value");
            
            g_bMenuInfo = ConfigSettings.GetNum("menu_info");
        
            g_bCreateGangSellMode = ConfigSettings.GetNum("create_mode");
            g_iCreateGangPrice = ConfigSettings.GetNum("create");
            
            g_bRenameBank = ConfigSettings.GetNum("rename_bank");
            g_bRenamePriceSellMode = ConfigSettings.GetNum("rename_mode");
            g_iRenamePrice = ConfigSettings.GetNum("rename");
            
            g_iSize = ConfigSettings.GetNum("num_slots");
            
            g_iScoreExpInc = ConfigSettings.GetNum("exp_inc");
            
            g_bExtendBank = ConfigSettings.GetNum("extend_bank");
            g_iExtendPriceSellMode = ConfigSettings.GetNum("extend_mode");
            g_bExtendCostFormula = ConfigSettings.GetNum("extend_formula");
            g_iExtendCostPrice = ConfigSettings.GetNum("extend_start");
            g_iExtendModifier = ConfigSettings.GetNum("extend_modifier");
        }
        
        ConfigSettings.Rewind();
        if(ConfigSettings.JumpToKey("bank"))
        {
            g_bEnableBank = ConfigSettings.GetNum("enable");
            g_bBankRubles = ConfigSettings.GetNum("rubles");
            g_bBankShop = ConfigSettings.GetNum("shop");
            g_bBankShopGold = ConfigSettings.GetNum("shop_gold");
            g_bBankWcsGold = ConfigSettings.GetNum("wcs_gold");
            g_bBankLkRubles = ConfigSettings.GetNum("lk_rubles");
            g_bBankMyJBCredits = ConfigSettings.GetNum("myjb_credits");
        }
        
        CreateTimer(10.0, Timer_CheckGangEnd);
        
        if(g_bDebug)
            LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Config Loaded");
    }
}

public Action Timer_CheckGangEnd(Handle timer)
{
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Check Gang End");
    
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "SELECT gang, end_date FROM gangs_groups;");
    g_hDatabase.Query(SQLCallback_Check_Gangs_End, sQuery);	
}

public void SQLCallback_Check_Gangs_End(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_Check_Gangs_End] Error (%i): %s", data, error);
        return;
    }
    
    while(results.FetchRow())
    {
        char GangName[128];
        results.FetchString(0, GangName, sizeof(GangName));
        int endtime = results.FetchInt(1);
        if(g_bDebug)
            LogToFile("addons/sourcemod/logs/gangs_debug.txt", "(%i>%i, %s) - Check gang end time", GetTime(), endtime, GangName);
        if(GetTime()>endtime) DissolveGang(GangName);
    }
}

public void OnMapEnd()
{
    delete ConfigSettings;
}

public int OnItemPressed(int iClient, const char[] sName)
{
    //FakeClientCommand(iClient, "sm_gangs");
    StartOpeningGangMenu(iClient);
} 

public void OnClientConnected(int iClient)
{
    if(g_bPluginEnabled)
    {
        ResetVariables(iClient);
    }
}

public void OnClientDisconnect(int iClient)
{
    if(g_bPluginEnabled)
    {
        //UpdateSQL(iClient);
        
        ResetVariables(iClient);
    }
}

public void OnConfigsExecuted()
{
    if(g_bPluginEnabled)
    {		
        // Set custom Commands
        int iCount = 0;
        char sCommandsL[12][32], sCommand[32], sCustomCommands[256];
        
        g_cvCustomCommands.GetString(sCustomCommands, sizeof(sCustomCommands));
        ReplaceString(sCustomCommands, sizeof(sCustomCommands), " ", "");
        iCount = ExplodeString(sCustomCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));

        for(int i = 0; i < iCount; i++)
        {
            Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
            if(GetCommandFlags(sCommand) == INVALID_FCVAR_FLAGS)  // if command not already exist
            {
                RegConsoleCmd(sCommand, Command_Gang, "Open the gang menu!");
            }
        }
        
                    
        g_iPerksCount = -1;
        g_iGamesCount = -1;
        g_iStatsCount = -1;
        ClearArrays();
        Call_StartForward(hGangs_OnLoaded);
        Call_Finish();
    }
}

public Action RefreshSteamID(Handle hTimer, int iUserID)
{
    int iClient = iUserID;
    if(!IsValidClient(iClient))
    {
        return;
    }

    GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));
    
    if(StrContains(ga_sSteamID[iClient], "STEAM_1", true) == -1) //still invalid - retry again
    {

        CreateTimer(5.0, RefreshSteamID, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        LoadSteamID(iClient);
    }
}

public void OnClientPutInServer(int iClient) 
{
    if(IsValidClient(iClient))
    {
        CreateTimer(2.0, Timer_AlertGang, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action Timer_AlertGang(Handle hTimer, int userid)
{
    int iClient = userid;
    
    if(!IsValidClient(iClient))
    {
        return;
    }
    
    char szName[MAX_NAME_LENGTH];
    GetClientName(iClient, szName, sizeof(szName));
    PrintToGang(iClient, false, "%T", "GangAlert", iClient, szName);
}

public void OnClientPostAdminCheck(int iClient)
{
    if(g_bPluginEnabled)
    {	
        LoadSteamID(iClient);
        GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));
        if(g_bDebug)
            LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Client %N(%i) SteamID: %s connected", iClient, iClient, ga_sSteamID[iClient]);
    }
}

void LoadSteamID(int iClient)
{
    if(g_bPluginEnabled)
    {
        if(!IsValidClient(iClient))
        {
            return;
        }
        GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));

        if(StrContains(ga_sSteamID[iClient], "STEAM_1", true) == -1) //if ID is invalid
        {
            CreateTimer(5.0, RefreshSteamID, iClient, TIMER_FLAG_NO_MAPCHANGE);
        }
        
        if(g_hDatabase == null) //connect not loaded - retry to give it time
        {
            CreateTimer(1.0, RepeatCheckRank, iClient, TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
            char sQuery[300];
            Format(sQuery, sizeof(sQuery), "SELECT gang, rank, invitedby, date FROM gangs_players WHERE steamid = '%s' AND server_id = %i;", ga_sSteamID[iClient], g_iServerID);
            g_hDatabase.Query(SQLCallback_CheckSQL_Player, sQuery, iClient);
            Format(sQuery, sizeof(sQuery), "SELECT pref FROM gangs_prefs WHERE steamid = '%s';", ga_sSteamID[iClient]);
            g_hDatabase.Query(SQLCallback_GetPreference, sQuery, iClient);
            if(g_bDebug)
                LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Load SteamID for %N(%i) SteamID: %s", iClient, iClient, ga_sSteamID[iClient]);
        }
    }
}

public void SQLCallback_GetPreference(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_GetPreference] Error (%i): %s", data, error);
        return;
    }
    
    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        if(results.RowCount > 0)
        {
            results.FetchRow();
            ga_bBlockInvites[iClient] = view_as<bool>(results.FetchInt(0));
            ga_bHasPref[iClient] = true;
        }
        else
        {
            ga_bBlockInvites[iClient] = false;
            ga_bHasPref[iClient] = false;
        }
    }
}

public void SQLCallback_CheckSQL_Player(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_CheckSQL_Player] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        if(results.RowCount == 1)
        {
            results.FetchRow();
            

            results.FetchString(0, ga_sGangName[iClient], sizeof(ga_sGangName[]));
            ga_iRank[iClient] = results.FetchInt(1);
            results.FetchString(2, ga_sInvitedBy[iClient], sizeof(ga_sInvitedBy[]));
            ga_iDateJoined[iClient] = results.FetchInt(3);
            
            ga_bIsPlayerInDatabase[iClient] = true;
            ga_bHasGang[iClient] = true;
            ga_bLoaded[iClient] = true;
            
            int iLen = 2*strlen(ga_sGangName[iClient])+1;
            char[] szEscapedGang = new char[iLen];
            g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

            char sQuery_2[300];
            Format(sQuery_2, sizeof(sQuery_2), "SELECT end_date, extend_count, rubles, credits, gold, wcsgold, lk_rubles FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
            g_hDatabase.Query(SQLCallback_CheckSQL_Groups, sQuery_2, iClient);
        }
        else
        {
            if(results.RowCount > 1)
            {
                LogError("Player %L has multiple entries under their ID. Running script to clean up duplicates and keep original entry (oldest)", iClient);
                CreateTimer(20.0, RepeatCheckRank, iClient, TIMER_FLAG_NO_MAPCHANGE);
            }
            else if(g_hDatabase == null)
            {
                CreateTimer(2.0, RepeatCheckRank, iClient, TIMER_FLAG_NO_MAPCHANGE);
            }
            else
            {
                ga_bHasGang[iClient] = false;
                ga_bLoaded[iClient] = true;
            }
        }
    }
}

public void SQLCallback_CheckSQL_Groups(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_CheckSQL_Groups] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        if(results.RowCount == 1)
        {
            results.FetchRow();

            //int endtime = results.FetchInt(0);
            ga_iExtendCount[iClient] = results.FetchInt(1);
            ga_iBankRubles[iClient] = results.FetchInt(2);
            ga_iBankCredits[iClient] = results.FetchInt(3);
            ga_iBankGold[iClient] = results.FetchInt(4);
            ga_iBankWCSGold[iClient] = results.FetchInt(5);
            ga_iBankLKRubles[iClient] = results.FetchInt(6);

            int iLen = 2*strlen(ga_sGangName[iClient])+1;
            char[] szEscapedGang = new char[iLen];
            g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

            char sQuery[300];
            Format(sQuery, sizeof(sQuery), "SELECT %s FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", g_sDbStatisticName, szEscapedGang, g_iServerID);
            g_hDatabase.Query(SQL_Callback_Kills, sQuery, iClient);
            //if(GetTime()>endtime) DissolveGang(iClient);
        }
    }
}

void DissolveGang(char[] GangName)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_players WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_bank_logs WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_perks WHERE gang = '%s' AND server_id = %i;", GangName, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && StrEqual(ga_sGangName[i], GangName))
        {
            API_OnExitFromGang(i);
            ResetVariables(i);
        }
    }
}
public void SQL_Callback_Kills(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQL_Callback_Kills] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        if(results.FetchRow()) // row exists
        {
            ga_iScore[iClient] = results.FetchInt(0);
        }
    }
}

public Action RepeatCheckRank(Handle timer, int iUserID)
{
    int iClient = iUserID;
    LoadSteamID(iClient);
}

public Action Command_AdminGang(int iClient, int args)
{
    if(!IsValidClient(iClient))
    {
        ReplyToCommand(iClient, "[SM] %t", "PlayerNotInGame");
        return Plugin_Handled;
    }
    FakeClientCommand(iClient, "sm_admgang");
    return Plugin_Handled;
}
/*****************************************************************
***********************	 GANG CREATION	**************************
******************************************************************/
void StartGangCreation(int iClient)
{
    if(!IsValidClient(iClient))
    {
        ReplyToCommand(iClient, "[SM] %t", "PlayerNotInGame", iClient);
        return;
    }
    if(g_bTerroristOnly && GetClientTeam(iClient) != 2)
    {
        ReplyToCommand(iClient, "[SM] %t", "WrongTeam", iClient);
        return;
    }
    for(int i = 0; i <= 5; i++)
    {
        CPrintToChat(iClient, "%t %t", "Prefix", "GangName");
    }
    ga_bSetName[iClient] = true;
}

public Action OnSay(int iClient, const char[] command, int args) 
{
    if(!IsValidClient(iClient))
    {
        return Plugin_Continue;
    }
    if(ga_bSetName[iClient])
    {
        char sText[64], sFormattedText[2*sizeof(sText)+1]; 
        GetCmdArgString(sText, sizeof(sText));
        StripQuotes(sText);
        if(StrEqual(sText,"!cancel"))
        {
            ga_bSetName[iClient] = false;
            return Plugin_Handled;
        }

        g_hDatabase.Escape(GetFixString(sText), sFormattedText, sizeof(sFormattedText));
        TrimString(sFormattedText);
        
        if(strlen(sText) > 16)
        {
            CPrintToChat(iClient, "%t %t", "Prefix", "NameTooLong");
            return Plugin_Handled;
        }
        else if(strlen(sText) == 0)
        {
            return Plugin_Handled;
        }
        
        DataPack data = new DataPack();
        data.WriteCell(iClient);
        data.WriteString(sText);
        data.Reset();

        char sQuery[1024];
        Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", sFormattedText, g_iServerID);
        g_hDatabase.Query(SQL_Callback_CheckName, sQuery, data);

        return Plugin_Handled;
    }
    else if(ga_bRename[iClient])
    {
        char sText[64], sFormattedText[2*sizeof(sText)+1]; 
        GetCmdArgString(sText, sizeof(sText));
        StripQuotes(sText);
        TrimString(sFormattedText);
        if(StrEqual(sText,"!cancel"))
        {
            ga_bRename[iClient] = false;
            return Plugin_Handled;
        }
        if(strlen(sText) > 16)
        {
            CPrintToChat(iClient, "%t %t", "Prefix", "NameTooLong");
            return Plugin_Handled;
        }
        else if(strlen(sText) == 0)
        {
            return Plugin_Handled;
        }
        
        DataPack data = new DataPack();
        data.WriteCell(iClient);
        data.WriteString(sText);
        data.Reset();

        char sQuery[1024];
        Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", sFormattedText, g_iServerID);
        g_hDatabase.Query(SQL_Callback_CheckName, sQuery, data);

        return Plugin_Handled;
    }
    else if(g_iBankCountType[iClient]>0)
    {
        char sText[64]; 
        GetCmdArgString(sText, sizeof(sText));
        StripQuotes(sText);
        TrimString(sText);
        if(StrEqual(sText,"!cancel"))
        {
            g_iBankCountType[iClient] = 0;
            return Plugin_Handled;
        }
        int iCount = StringToInt(sText);
        if(iCount != 0)
        {
            switch(g_iBankCountType[iClient])
            {
                case 1:
                {
                    if(GameCMS_GetClientRubles(iClient) >= iCount)
                    {
                        GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) - iCount);
                        SetBankRubles(iClient, ga_iBankRubles[iClient] + iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 2:
                {
                    if(ga_iBankRubles[iClient] >= iCount)
                    {
                        GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) + iCount);
                        SetBankRubles(iClient, ga_iBankRubles[iClient] - iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 3:
                {
                    if(Shop_GetClientCredits(iClient) >= iCount)
                    {
                        Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - iCount);
                        SetBankCredits(iClient, ga_iBankCredits[iClient] + iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 4:
                {
                    if(ga_iBankCredits[iClient] >= iCount)
                    {
                        Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) + iCount);
                        SetBankCredits(iClient, ga_iBankCredits[iClient] - iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 5:
                {
                    if(Shop_GetClientGold(iClient) >= iCount)
                    {
                        Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) - iCount);
                        SetBankCredits(iClient, ga_iBankCredits[iClient] + iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 6:
                {
                    if(ga_iBankCredits[iClient] >= iCount)
                    {
                        Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) + iCount);
                        SetBankCredits(iClient, ga_iBankCredits[iClient] - iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 7:
                {
                    if(WCS_GetGold(iClient) >= iCount)
                    {
                        WCS_TakeGold(iClient, iCount);
                        SetBankWCSGold(iClient, ga_iBankWCSGold[iClient] + iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 8:
                {
                    if(ga_iBankWCSGold[iClient] >= iCount)
                    {
                        WCS_GiveGold(iClient, iCount);
                        SetBankWCSGold(iClient, ga_iBankWCSGold[iClient] - iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 9:
                {
                    if(LK_GetClientCash(iClient) >= iCount)
                    {
                        LK_SetClientCash(iClient, LK_GetClientCash(iClient) - iCount);
                        SetBankLKRubles(iClient, ga_iBankLKRubles[iClient] + iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 10:
                {
                    if(ga_iBankLKRubles[iClient] >= iCount)
                    {
                        LK_SetClientCash(iClient, LK_GetClientCash(iClient) + iCount);
                        SetBankLKRubles(iClient, ga_iBankLKRubles[iClient] - iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 11:
                {
                    if(MyJailShop_GetCredits(iClient) >= iCount)
                    {
                        MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) - iCount);
                        SetBankMyJBCredits(iClient, ga_iBankMyJBCredits[iClient] + iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                case 12:
                {
                    if(ga_iBankMyJBCredits[iClient] >= iCount)
                    {
                        MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) + iCount);
                        SetBankMyJBCredits(iClient, ga_iBankMyJBCredits[iClient] - iCount);
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                    }
                    else
                        CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                }
                        
            }
            g_iBankCountType[iClient] = 0;
        }
        else
            CPrintToChat(iClient, "%t %t", "Prefix", "BankWrongAction");
        
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void SQL_Callback_CheckName(Database db, DBResultSet results, const char[] error, DataPack data)
{
    if(error[0])
    {
        LogError("[SQL_Callback_CheckName] Error (%i): %s", data, error);
        return;
    }

    char sText[64];
    int iClient = data.ReadCell();
    data.ReadString(sText, sizeof(sText));
    delete data;

    if(!IsValidClient(iClient))
    {
        return;
    }
    else
    {
        if(ga_bSetName[iClient])
        {
            if(results.RowCount == 0)
            {
                strcopy(ga_sGangName[iClient], sizeof(ga_sGangName[]), sText);
                if(CheckBadNameGang(ga_sGangName[iClient]))
                {
                    ga_bHasGang[iClient] = true;
                    ga_iDateJoined[iClient] = GetTime();
                    ga_sInvitedBy[iClient] = "N/A";
                    //ga_iRank[iClient] = GetLastConfigRank();
                    ga_iRank[iClient] = 0;
                    ga_iGangSize[iClient] = 1;

                    
                    ga_iExtendCount[iClient] = 0;
                    
                    ga_iBankRubles[iClient] = 0;
                    ga_iBankCredits[iClient] = 0;
                    ga_iBankGold[iClient] = 0;
                    ga_iBankWCSGold[iClient] = 0;
                    ga_iBankLKRubles[iClient] = 0;
                    
                    UpdateSQL(iClient);
                    
                    if(g_bCreateGangSellMode == 0 && g_bGameCMSExist)
                    {
                        int Discount;
                        if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
                            Discount = GameCMS_GetGlobalDiscount();
                        else Discount = GameCMS_GetClientDiscount(iClient);
                        GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) - Colculate(iClient, g_iCreateGangPrice, Discount));
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i рублей", iClient, ga_sGangName[iClient], Colculate(iClient, g_iCreateGangPrice, Discount));
                    }
                    if(g_bCreateGangSellMode == 1)
                    {
                        Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iCreateGangPrice);
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i кредитов", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
                    }
                    else if(g_bCreateGangSellMode == 2 && g_bLShopGoldExist)
                    {
                        Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) - g_iCreateGangPrice);
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i голды", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
                    }
                    //else if(g_bCreateGangSellMode == 3 && g_bWCSLoaded)
                    else if(g_bCreateGangSellMode == 3)
                    {
                        WCS_TakeGold(iClient, g_iCreateGangPrice);
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i WCS голды", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
                    }
                    else if(g_bCreateGangSellMode == 4 && g_bLKLoaded)
                    {
                        LK_SetClientCash(iClient, LK_GetClientCash(iClient) - g_iCreateGangPrice);
                                    
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i MyJailShop Creditss", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
                    }
                    else if(g_bCreateGangSellMode == 5 && g_bMyJBShopExist)
                    {
                        MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) - g_iCreateGangPrice);
                                    
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N создал банду %s за %i LK рублей", iClient, ga_sGangName[iClient], g_iCreateGangPrice);
                    }
                    else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
                    
                    CreateTimer(0.2, Timer_OpenGangMenu, iClient, TIMER_FLAG_NO_MAPCHANGE);
                    
                    char szName[MAX_NAME_LENGTH];
                    GetClientName(iClient, szName, sizeof(szName));
                    CPrintToChatAll("%t %t", "Prefix", "GangCreated", szName, ga_sGangName[iClient]);
                }
                else CPrintToChat(iClient, "%t %t", "Prefix", "BadName");
            }
            else CPrintToChat(iClient, "%t %t", "Prefix", "NameAlreadyUsed");
            
            ga_bSetName[iClient] = false;
        }
        else if(ga_bRename[iClient])
        {
            if(results.RowCount == 0)
            {
                char sOldName[32];
                strcopy(sOldName, sizeof(sOldName), ga_sGangName[iClient]);
                strcopy(ga_sGangName[iClient], sizeof(ga_sGangName[]), sText);
                if(CheckBadNameGang(ga_sGangName[iClient]))
                {
                    for(int i = 1; i <= MaxClients; i++)
                    {
                        if(IsValidClient(i) && StrEqual(ga_sGangName[i], sOldName))
                        {
                            strcopy(ga_sGangName[i], sizeof(ga_sGangName[]), sText);
                        }
                    }
                    char sQuery[300];
                    Format(sQuery, sizeof(sQuery), "UPDATE gangs_players SET gang = '%s' WHERE gang = '%s' AND server_id = %i;", sText, sOldName, g_iServerID);
                    g_hDatabase.Query(SQLCallback_Void, sQuery);

                    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET gang = '%s' WHERE gang = '%s' AND server_id = %i;", sText, sOldName, g_iServerID);
                    g_hDatabase.Query(SQLCallback_Void, sQuery);
            
                    Format(sQuery, sizeof(sQuery), "UPDATE gangs_statistics SET gang = '%s' WHERE gang = '%s' AND server_id = %i;", sText, sOldName, g_iServerID);
                    g_hDatabase.Query(SQLCallback_Void, sQuery);
            
                    Format(sQuery, sizeof(sQuery), "UPDATE gangs_bank_logs SET gang = '%s' WHERE gang = '%s' AND server_id = %i;", sText, sOldName, g_iServerID);
                    g_hDatabase.Query(SQLCallback_Void, sQuery);
            
                    Format(sQuery, sizeof(sQuery), "UPDATE gangs_perks SET gang = '%s' WHERE gang = '%s' AND server_id = %i;", sText, sOldName, g_iServerID);
                    g_hDatabase.Query(SQLCallback_Void, sQuery);
                    
                    if(g_bRenamePriceSellMode == 0 && g_bGameCMSExist)
                    {
                        int Discount;
                        if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
                            Discount = GameCMS_GetGlobalDiscount();
                        else Discount = GameCMS_GetClientDiscount(iClient);
                        
                        if(g_bEnableBank && g_bRenameBank)
                            SetBankRubles(iClient, ga_iBankRubles[iClient] - Colculate(iClient, g_iRenamePrice, Discount));
                        else
                            GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) - Colculate(iClient, g_iRenamePrice, Discount));
                        
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды с %s на %s за %i рублей", iClient, sOldName, sText, Colculate(iClient, g_iRenamePrice, Discount));
                    }
                    else if(g_bRenamePriceSellMode == 1)
                    {
                        //Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iRenamePrice);
                        if(g_bEnableBank && g_bBankShop && g_bRenameBank)
                            SetBankCredits(iClient, ga_iBankCredits[iClient] - g_iRenamePrice);
                        else
                            Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iRenamePrice);
                        
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды с %s на %s за %i кредитов", iClient, sOldName, sText, g_iRenamePrice);
                    }
                    else if(g_bRenamePriceSellMode == 2 && g_bLShopGoldExist)
                    {
                        //Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iRenamePrice);
                        if(g_bEnableBank && g_bBankShopGold && g_bRenameBank)
                            SetBankGold(iClient, ga_iBankGold[iClient] - g_iRenamePrice);
                        else
                            Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) - g_iRenamePrice);
                        
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды с %s на %s за %i голды", iClient, sOldName, sText, g_iRenamePrice);
                    }
                    //else if(g_bRenamePriceSellMode == 3 && g_bWCSLoaded)
                    else if(g_bRenamePriceSellMode == 3)
                    {
                        //Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iRenamePrice);
                        if(g_bEnableBank && g_bBankWcsGold && g_bRenameBank)
                            SetBankWCSGold(iClient, ga_iBankWCSGold[iClient] - g_iRenamePrice);
                        else
                            WCS_TakeGold(iClient, g_iRenamePrice);
                        
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды с %s на %s за %i WCS голды", iClient, sOldName, sText, g_iRenamePrice);
                    }
                    else if(g_bRenamePriceSellMode == 4 && g_bLKLoaded)
                    {
                        if(g_bEnableBank && g_bBankLkRubles && g_bRenameBank)
                            SetBankLKRubles(iClient, ga_iBankLKRubles[iClient] - g_iRenamePrice);
                        else
                            LK_SetClientCash(iClient, LK_GetClientCash(iClient) - g_iRenamePrice);
                                    
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды с %s на %s за %i LK рублей", iClient, sOldName, sText, g_iRenamePrice);
                    }
                    else if(g_bRenamePriceSellMode == 5 && g_bMyJBShopExist)
                    {
                        if(g_bEnableBank && g_bBankLkRubles && g_bRenameBank)
                            SetBankMyJBCredits(iClient, ga_iBankMyJBCredits[iClient] - g_iRenamePrice);
                        else
                            MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) - g_iRenamePrice);
                                    
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды с %s на %s за %i LK рублей", iClient, sOldName, sText, g_iRenamePrice);
                    }
                    else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
                    
                    char szName[MAX_NAME_LENGTH];
                    GetClientName(iClient, szName, sizeof(szName));
                    CPrintToChatAll("%t %t", "Prefix", "GangNameChange", szName, sOldName, sText);

                    StartOpeningGangMenu(iClient);
                }
                else CPrintToChat(iClient, "%t %t", "Prefix", "BadName");
            }
            else
            {
                CPrintToChat(iClient, "%t %t", "Prefix", "NameAlreadyUsed");
            }
            
            ga_bRename[iClient] = false;
        }
    }
}

public Action Timer_OpenGangMenu(Handle hTimer, int userid)
{
    int iClient = userid;
    if(IsValidClient(iClient))
    {
        StartOpeningGangMenu(iClient);
    }
}

public bool CheckBadNameGang(const char[] sName)
{
    bool bTrue = true;
    char file[255];
    BuildPath(Path_SM, file, sizeof(file), "configs/gangs/bad_names.ini");
    if(!FileExists(file)) CloseHandle(CreateFile(file, "a"));
    File hFile = OpenFile(file, "r");
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "----------START CHECK BAD NAME----------");
    if(hFile)
    {
        char ItemName[52];
        while(!hFile.EndOfFile() && hFile.ReadLine(ItemName, sizeof(ItemName)))
        {
            ReplaceString(ItemName, sizeof(ItemName), "\n", "");
            PrintToConsoleAll("'%s' : '%s' <-> %d", sName, ItemName, StrContains(sName, ItemName, false));
            if(g_bDebug)
                LogToFile("addons/sourcemod/logs/gangs_debug.txt", "'%s' : '%s' <-> %d", sName, ItemName, StrContains(sName, ItemName, false));
            if(StrContains(sName, ItemName, false) != -1)
            {
                bTrue = false;
                CloseHandle(hFile);
                return bTrue;
            }
        }
    }
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "----------END CHECK BAD NAME----------");
    CloseHandle(hFile);
    return bTrue;
}

/*****************************************************************
*********************** MEMBER LIST MENU *************************
******************************************************************/
void StartOpeningMembersMenu(int iClient)
{
    if(!StrEqual(ga_sGangName[iClient], ""))
    {
        int iLen = 2*strlen(ga_sGangName[iClient])+1;
        char[] szEscapedGang = new char[iLen];
        g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

        char sQuery[300];
        Format(sQuery, sizeof(sQuery), "SELECT steamid, playername, invitedby, rank, date, gang FROM gangs_players WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_OpenMembersMenu, sQuery, iClient);
    }
}

public void SQLCallback_OpenMembersMenu(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_OpenMembersMenu] Error (%i): %s", data, error);
        return;
    }
    
    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else
    {
        Menu menu = CreateMenu(MemberListMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
        
        char sTitleString[128];
        Format(sTitleString, sizeof(sTitleString), "%T", "MemberList", iClient);
        SetMenuTitle(menu, sTitleString);
        
        char sDisplayString[128];
        Format(sDisplayString, sizeof(sDisplayString), "%T\n \n", "InviteToGang", iClient);
        if(g_bModuleSizeExist)
            menu.AddItem("invite", sDisplayString, (GetClientRightStatus(iClient, "invite") && (ga_iGangSize[iClient] < g_iSize + Gangs_Size_GetCurrectLvl(iClient)))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("invite", sDisplayString, (GetClientRightStatus(iClient, "invite")	 && (ga_iGangSize[iClient] < g_iSize))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        
        
        while(results.FetchRow())
        {
            char a_sTempArray[6][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF)
            results.FetchString(0, a_sTempArray[0], sizeof(a_sTempArray[])); // Steam-ID
            results.FetchString(1, a_sTempArray[1], sizeof(a_sTempArray[])); // Player Name
            results.FetchString(2, a_sTempArray[2], sizeof(a_sTempArray[])); // Invited By
            IntToString(results.FetchInt(3), a_sTempArray[3], sizeof(a_sTempArray[])); // Rank
            IntToString(results.FetchInt(4), a_sTempArray[4], sizeof(a_sTempArray[])); // Date
            results.FetchString(5, a_sTempArray[5], sizeof(a_sTempArray[])); // Gang


            char sInfoString[1024];

            Format(sInfoString, sizeof(sInfoString), "%s;%s;%s;%i;%i;%s", a_sTempArray[0], a_sTempArray[1], a_sTempArray[2], StringToInt(a_sTempArray[3]), StringToInt(a_sTempArray[4]), a_sTempArray[5]);

            KeyValues ConfigRanks;
            ConfigRanks = new KeyValues("Ranks");
            char szBuffer[256];
            BuildPath(Path_SM, szBuffer, 256, "configs/gangs/ranks.txt");
            ConfigRanks.ImportFromFile(szBuffer);
            ConfigRanks.Rewind();
            if(ConfigRanks.JumpToKey(a_sTempArray[3]))
            {
                ConfigRanks.GetString("Name", szBuffer, sizeof(szBuffer));
                Format(sDisplayString, sizeof(sDisplayString), "%s (%T)", a_sTempArray[1], szBuffer, iClient);
            }
            delete ConfigRanks;
            
            menu.AddItem(sInfoString, sDisplayString);
        }
        
        menu.ExitBackButton = true;

        menu.Display(iClient, MENU_TIME_FOREVER);
    }
}

public int MemberListMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[128];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            if(StrEqual(sInfo, "invite"))
                OpenInvitationMenu(param1);
            else
                OpenIndividualMemberMenu(param1, sInfo);
        }
        case MenuAction_Cancel:
            if(param2 == MenuCancel_ExitBack)
                StartOpeningGangMenu(param1);
        case MenuAction_End:
            delete menu;
    }
    return;
}

void OpenIndividualMemberMenu(int iClient, char[] sInfo)
{
    Menu menu = CreateMenu(IndividualMemberMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
    SetMenuTitle(menu, "Информация : ");

    char sTempArray[6][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF) | 5 - Gang
    char sDisplayBuffer[64];

    ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

    Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "Name", iClient, sTempArray[1]);
    menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

    Format(sDisplayBuffer, sizeof(sDisplayBuffer), "Steam ID: %s", sTempArray[0]);
    menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

    Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "InvitedBy", iClient, sTempArray[2]);
    menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

    KeyValues ConfigRanks;
    ConfigRanks = new KeyValues("Ranks");
    char szBuffer[256];
    BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
    ConfigRanks.ImportFromFile(szBuffer);
    ConfigRanks.Rewind();
    if(ConfigRanks.JumpToKey(sTempArray[3]))
    {
        ConfigRanks.GetString("Name", szBuffer, sizeof(szBuffer));
        Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %T", "Rank", iClient, szBuffer, iClient);
    }
    delete ConfigRanks;
    menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);

    char sFormattedTime[64];
    FormatTime(sFormattedTime, sizeof(sFormattedTime), "%x", StringToInt(sTempArray[4]));
    Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T %s", "DateJoined", iClient, sFormattedTime);
    menu.AddItem("", sDisplayBuffer, ITEMDRAW_DISABLED);
    
    if(GetClientRightStatus(iClient, "kick") || GetClientRightStatus(iClient, "ranks") || GetClientRightStatus(iClient, "bank_logs") || ga_iRank[iClient] == 0)
    {
        Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Management", iClient);
        menu.AddItem(sInfo, sDisplayBuffer);
    }

    menu.ExitBackButton = true;

    menu.Display(iClient, MENU_TIME_FOREVER);
}

public int IndividualMemberMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int iClient = param1;
            char sInfo[1024];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            char sTempArray[6][128]; // 0 - SteamID | 1 - Name | 2 - Invited By | 3 - Rank | 4 - Date (UTF) | 5 - Gang
            ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));
            
            Menu menu1 = CreateMenu(IndividualManagementMemberMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
            SetMenuTitle(menu1, "%T:", "Management", iClient);
            char sDisplayBuffer[64];
            if(GetClientRightStatus(iClient, "kick") && !StrEqual(sTempArray[3], "0") && CheckRankImmune(ga_iRank[iClient], sTempArray[3]))
            {
                Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "KickAMember", iClient);
                Format(sInfo, sizeof(sInfo), "kick;%s;%s", sTempArray[0], sTempArray[1]);
                menu1.AddItem(sInfo, sDisplayBuffer);
            }
            if(GetClientRightStatus(iClient, "ranks") && !StrEqual(sTempArray[3], "0") && CheckRankImmune(ga_iRank[iClient], sTempArray[3]))
            {
                Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Promote", iClient);
                Format(sInfo, sizeof(sInfo), "ranks;%s;%s;%s;%s", sTempArray[0], sTempArray[1], sTempArray[3], sTempArray[5]);
                menu1.AddItem(sInfo, sDisplayBuffer);
            }
            if(ga_iRank[iClient] == 0)
            {
                if(!StrEqual(ga_sSteamID[iClient], sTempArray[0]))
                {
                    Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "TransferLeader", iClient);
                    Format(sInfo, sizeof(sInfo), "transferleader;%s;%s;%s", sTempArray[0], sTempArray[1], sTempArray[3]);
                    menu1.AddItem(sInfo, sDisplayBuffer);
                }
            }
            if(GetClientRightStatus(iClient, "bank_logs"))
            {
                Format(sDisplayBuffer, sizeof(sDisplayBuffer), "%T", "Logs", iClient);
                Format(sInfo, sizeof(sInfo), "bank_logs;%s;%s", sTempArray[1], sTempArray[5]);
                menu1.AddItem(sInfo, sDisplayBuffer, (GetClientRightStatus(iClient, "bank_logs"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
            }
            

            menu1.ExitBackButton = true;


            menu1.Display(iClient, MENU_TIME_FOREVER);
        }
        case MenuAction_Cancel:
        {
            StartOpeningMembersMenu(param1);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}

public int IndividualManagementMemberMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            int iClient = param1;
            char sInfo[1024];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            char sTempArray[5][128];
            ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));
            if(StrEqual(sTempArray[0], "kick"))
            {	
                char sQuery[256];
                Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_players WHERE steamid = '%s' AND server_id = %i;", sTempArray[1], g_iServerID);
                g_hDatabase.Query(SQLCallback_Void, sQuery);
                
                CPrintToChatAll("%t %t", "Prefix", "GangMemberKick", sTempArray[2], ga_sGangName[iClient]);
                
                char sSteamID[64];
                for(int i = 1; i <= MaxClients; i++)
                {
                    if(IsValidClient(i))
                    {
                        GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
                        if(StrEqual(sSteamID, sTempArray[1]))
                        {
                            API_OnExitFromGang(i);
                            ResetVariables(i, false);
                        }
                    }
                }
            }
            else if(StrEqual(sTempArray[0], "ranks"))
            {	
                Format(sInfo, sizeof(sInfo), "%s;%s;%s;%s", sTempArray[1], sTempArray[2], sTempArray[3], sTempArray[4]);
                OpenPromoteDemoteMenu(iClient, sInfo);
            }
            else if(StrEqual(sTempArray[0], "transferleader"))
            {	
                int iTarget = FindTarget(0, sTempArray[2], true, false);
                char sQuery[256];
                Format(sQuery, sizeof(sQuery), "UPDATE gangs_players SET rank = %s WHERE steamid = '%s' AND server_id = %i;", sTempArray[3], ga_sSteamID[iClient], g_iServerID);
                g_hDatabase.Query(SQLCallback_Void, sQuery);
                
                ga_iRank[iClient] = StringToInt(sTempArray[3]);
                
                Format(sQuery, sizeof(sQuery), "UPDATE gangs_players SET rank = 0 WHERE	 steamid = '%s' AND server_id = %i;", sTempArray[1], g_iServerID);
                g_hDatabase.Query(SQLCallback_Void, sQuery);
                
                if(iTarget != -1)
                    ga_iRank[iTarget] = 0;
                char szName[MAX_NAME_LENGTH];
                GetClientName(iClient, szName, sizeof(szName));
                CPrintToChatAll("%t %t", "Prefix", "LeaderTransfered", szName, sTempArray[2]);
            }
            else if(StrEqual(sTempArray[0], "bank_logs"))
            {	
                char sQuery[256];
                //Format(sQuery, sizeof(sQuery),"SELECT nick, logs, date FROM gangs_bank_logs WHERE gang = '%s' ORDER BY id DESC LIMIT 10;", ga_sGangName[iClient]);
                int iLen = 2*strlen(ga_sGangName[iClient])+1;
                char[] szEscapedGang = new char[iLen];
                g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

                Format(sQuery, sizeof(sQuery),"SELECT nick, logs, date FROM gangs_bank_logs WHERE gang = '%s' AND nick = '%s' ORDER BY id DESC LIMIT 21;", szEscapedGang, sTempArray[1]);
                g_hDatabase.Query(SQLCallback_OpenBankLogsMenu, sQuery, iClient);
            }
            
        }
        case MenuAction_Cancel:
        {
            StartOpeningMembersMenu(param1);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}
/*****************************************************************
*********************** INVITATION MENU **************************
******************************************************************/
void OpenInvitationMenu(int iClient)
{
    Menu menu = CreateMenu(InvitationMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
    
    char sInfoString[64];
    char sDisplayString[64];
    char sMenuString[64];
    
    Format(sMenuString, sizeof(sMenuString), "%T", "InviteToGang", iClient);
    SetMenuTitle(menu, sMenuString);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && i != iClient)
        {
            Format(sInfoString, sizeof(sInfoString), "%i", i);
            Format(sDisplayString, sizeof(sDisplayString), "%N", i);
            //menu.AddItem(sInfoString, sDisplayString, (ga_bHasGang[i] || ga_iRank[iClient] == Rank_Normal || ga_bBlockInvites[i])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
            menu.AddItem(sInfoString, sDisplayString, (ga_bHasGang[i] || ga_bBlockInvites[i])?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
        }
    }

    menu.ExitBackButton = true;
    menu.Display(iClient, MENU_TIME_FOREVER);

}

public int InvitationMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{					 
    switch (action)
    {
        case MenuAction_Select:
        {
            if(!ga_bInvitationSent[param1])
            {
                char sInfo[64];
                GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
                int iUserID = StringToInt(sInfo);

                ga_iInvitation[iUserID] = param1;
                ga_bInvitationSent[param1] = true;

                if(g_bModuleSizeExist)
                {
                    if(ga_iGangSize[param1] >= g_iSize + Gangs_Size_GetCurrectLvl(param1))
                    {
                        CPrintToChat(param1, "%t %t", "Prefix", "GangIsFull");
                        return;
                    }
                }
                else
                {
                    if(ga_iGangSize[param1] >= g_iSize)
                    {
                        CPrintToChat(param1, "%t %t", "Prefix", "GangIsFull");
                        return;
                    }
                }

                if(!g_bInviteStyle)
                {
                    CPrintToChat(iUserID, "%t %t", "Prefix", "AcceptInstructions", ga_sGangName[param1]);
                    DataPack data = new DataPack();
                    data.WriteCell(param1);
                    data.WriteCell(iUserID);
                    CreateTimer(15.0, AcceptTimer, data);
                }
                else
                {
                    OpenGangInvitationMenu(iUserID);
                }
                StartOpeningGangMenu(param1);
            }
            else
            {
                CPrintToChat(param1, "%t %t", "Prefix", "InvitationSent");
                return;
            }
            
        }
        case MenuAction_Cancel:
            if(param2 == MenuCancel_ExitBack)
                OpenAdministrationMenu(param1);
        case MenuAction_End:
            delete menu;
    }
    return;
}

public Action AcceptTimer(Handle timer, DataPack data)
{
    int iClient = data.ReadCell();
    int iTarget = data.ReadCell();
    if(IsValidClient(iClient) && ga_bInvitationSent[iClient])
        ga_bInvitationSent[iClient] = false;
    if(IsValidClient(iTarget) && ga_iInvitation[iTarget])
        ga_iInvitation[IsValidClient] = -1;
}


void OpenGangInvitationMenu(int iClient)
{
    if(!IsValidClient(iClient))
    {
        return;
    }
    Menu menu = CreateMenu(SentInviteMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
    char sDisplayString[64];
    char sTitleString[64];
    
    Format(sTitleString, sizeof(sTitleString), "%T", "GangInvitation", iClient);
    SetMenuTitle(menu, sTitleString);

    int sender = ga_iInvitation[iClient];
    char szName[MAX_NAME_LENGTH];
    GetClientName(sender, szName, sizeof(szName));

    Format(sDisplayString, sizeof(sDisplayString), "%T", "InviteString", iClient, szName);
    menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

    Format(sDisplayString, sizeof(sDisplayString), "%T", "WouldYouLikeToJoin", iClient, ga_sGangName[sender]);
    menu.AddItem("", sDisplayString, ITEMDRAW_DISABLED);

    Format(sDisplayString, sizeof(sDisplayString), "%T", "IWouldLikeTo", iClient);
    menu.AddItem("yes", sDisplayString);
    
    Format(sDisplayString, sizeof(sDisplayString), "%T", "IWouldNotLikeTo", iClient);
    menu.AddItem("no", sDisplayString);

    menu.Display(iClient, 15);
}

public int SentInviteMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    if(!IsValidClient(param1))
    {
        return;
    }
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[64];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            int sender = ga_iInvitation[param1];
            
            if(StrEqual(sInfo, "yes"))
            {
                ga_sGangName[param1] = ga_sGangName[sender];
                ga_iDateJoined[param1] = GetTime();
                ga_bHasGang[param1] =  true;
                ga_bSetName[param1] = false;
                
                ga_iScore[param1] = ga_iScore[sender];
                ga_iBankRubles[param1] = ga_iBankRubles[sender];
                ga_iBankCredits[param1] = ga_iBankCredits[sender];
                ga_iBankGold[param1] = ga_iBankGold[sender];
                ga_iBankWCSGold[param1] = ga_iBankWCSGold[sender];
                ga_iBankLKRubles[param1] = ga_iBankLKRubles[sender];
                ga_iExtendCount[param1] = ga_iExtendCount[sender];
                ga_iGangSize[param1] = ++ga_iGangSize[sender];
                
                ga_bInvitationSent[sender] = false;

                char szName[MAX_NAME_LENGTH];
                GetClientName(sender, szName, sizeof(szName));
                ga_sInvitedBy[param1] = szName;
                ga_iRank[param1] = GetLastConfigRank();
                UpdateSQL(param1);
                
                GetClientName(param1, szName, sizeof(szName));
                
                CPrintToChatAll("%t %t", "Prefix", "GangJoined", szName, ga_sGangName[param1]);
            }
            else if(StrEqual(sInfo, "no"))		
            {
                ga_bInvitationSent[sender] = false;
            }
        }
        case MenuAction_Cancel:
        {
            int sender = ga_iInvitation[param1];
            ga_bInvitationSent[sender] = false;
            
            StartOpeningGangMenu(param1);
        }
        case MenuAction_End:
        {
            int sender = ga_iInvitation[param1];
            ga_bInvitationSent[sender] = false;
            
            delete menu;
        }
    }
    return;
}

public int MenuHandler_Bank(Handle menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
    {
        delete(menu);
    }
    else if(action == MenuAction_Cancel)
    {
        if(param2 == MenuCancel_ExitBack)
        {
            StartOpeningGangMenu(param1);
        }
    }
    else if(action == MenuAction_Select)
    {
        char info[32];

        GetMenuItem(menu, param2, info, sizeof(info));
        if(StrEqual(info ,"1"))
        {
            g_iBankCountType[param1] = 1;
            //DisplayCountRublesGive(param1);
        }
        else if(StrEqual(info ,"2"))
        {
            g_iBankCountType[param1] = 2;
            //DisplayCountRublesTake(param1);
        }
        else if(StrEqual(info ,"3"))
        {
            g_iBankCountType[param1] = 3;
            //DisplayCountCreditsGive(param1);
        }
        else if(StrEqual(info ,"4"))
        {
            g_iBankCountType[param1] = 4;
            //DisplayCountCreditsTake(param1);
        }
        else if(StrEqual(info ,"5"))
        {
            g_iBankCountType[param1] = 5;
            //DisplayCountGoldGive(param1);
        }
        else if(StrEqual(info ,"6"))
        {
            g_iBankCountType[param1] = 6;
            //DisplayCountGoldTake(param1);
        }
        else if(StrEqual(info ,"7"))
        {
            g_iBankCountType[param1] = 7;
            //DisplayCountWCSGoldGive(param1);
        }
        else if(StrEqual(info ,"8"))
        {
            g_iBankCountType[param1] = 8;
            //DisplayCountWCSGoldTake(param1);
        }
        else if(StrEqual(info ,"9"))
        {
            g_iBankCountType[param1] = 9;
            //DisplayCountLKRublesGive(param1);
        }
        else if(StrEqual(info ,"10"))
        {
            g_iBankCountType[param1] = 10;
            //DisplayCountLKRublesTake(param1);
        }
        else if(StrEqual(info ,"11"))
        {
            g_iBankCountType[param1] = 11;
            //DisplayCountMyJBCreditsGive(param1);
        }
        else if(StrEqual(info ,"12"))
        {
            g_iBankCountType[param1] = 12;
            //DisplayCountMyJBCreditsTake(param1);
        }
        CPrintToChat(param1, "%t %t", "Prefix", "BankAction");
        delete(menu);
        //else if(StrEqual(info ,"13"))
        //{
        //	DisplayBankLogs(param1);
        //}
    }
}

public void SQLCallback_OpenBankLogsMenu(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_OpenBankLogsMenu] Error (%i): %s", data, error);
        return;
    }
    
    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        Menu menu = new Menu(MenuHandler_BankLogs, MenuAction_End|MenuAction_Cancel|MenuAction_Select|MenuAction_DrawItem);

        char title[100];
        Format(title, sizeof(title), "%T", "Logs", iClient);
        SetMenuTitle(menu, title);
        SetMenuExitBackButton(menu, true);
        int i = 0;
        while(results.FetchRow())
        {
            char sPunkt[256], sTime[64], sSetchik[32];
            FormatTime(sTime, sizeof(sTime), "%d/%m/%Y (%I:%M:%S)", results.FetchInt(2));
            char sName[128];
            results.FetchString(0, sName, sizeof(sName));
            Format(sPunkt, sizeof(sPunkt), "%s - %s", sName, sTime);
            Format(sSetchik, sizeof(sSetchik), "%i", i);
            menu.AddItem(sSetchik, sPunkt);
            i++;
            //Format(sPunkt, sizeof(sPunkt), "%s", results.FetchInt(1));
            results.FetchString(1, sPunkt, sizeof(sPunkt));
            Format(sSetchik, sizeof(sSetchik), "%i", i);
            menu.AddItem(sSetchik, sPunkt);
            i++;
        }
        if(i == 0)
        {
            char sInfo[128];
            Format(sInfo, sizeof(sInfo), "%T", "NoLogs", iClient);
            menu.AddItem("", sInfo, ITEMDRAW_DISABLED);
        }
            
        DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
    }
}

public int MenuHandler_BankLogs(Handle menu, MenuAction action, int param1, int param2)
{
    if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
    else if(action == MenuAction_Cancel)
    {
        if(param2 == MenuCancel_ExitBack)
        {
            StartOpeningMembersMenu(param1);
        }
    }
    else if(action == MenuAction_DrawItem)
    {
        return ITEMDRAW_DISABLED;
    }
    return 0;
}

void DisplayBankMenu(int iClient)
{
    Menu menu = new Menu(MenuHandler_Bank);

    char title[100];
    Format(title, sizeof(title), "%T\n%T:", "Bank", iClient, "Balance", iClient);
    if(g_bBankRubles && g_bGameCMSExist)
    {
        Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankRubles[iClient], "rubles", iClient);
    }
    if(g_bBankShop)
    {
        Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankCredits[iClient], "shop", iClient);
    }
    if(g_bBankShopGold && g_bLShopGoldExist)
    {
        Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankGold[iClient], "shopgold", iClient);
    }
    //if(g_bBankWcsGold && g_bWCSLoaded)
    if(g_bBankWcsGold)
    {
        Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankWCSGold[iClient], "wcsgold", iClient);
    }
    if(g_bBankLkRubles && g_bLKLoaded)
    {
        Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankLKRubles[iClient], "lkrubles", iClient);
    }
    if(g_bBankMyJBCredits && g_bMyJBShopExist)
    {
        Format(title, sizeof(title), "%s\n %i %T", title, ga_iBankMyJBCredits[iClient], "myjb", iClient);
    }
    SetMenuTitle(menu, title);
    SetMenuExitBackButton(menu, true);
    
    if(g_bBankRubles && g_bGameCMSExist)
    {
        Format(title, sizeof(title), "%T", "PRub", iClient);
        menu.AddItem("1", title, ((!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient)) || !GetClientRightStatus(iClient, "bang_give"))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
        Format(title, sizeof(title), "%T", "PURub", iClient);
        menu.AddItem("2", title, ((!GetClientRightStatus(iClient, "bank_take")) || ((!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient))))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
    }
    if(g_bBankShop)
    {
        Format(title, sizeof(title), "%T", "PCred", iClient);
        menu.AddItem("3", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        Format(title, sizeof(title), "%T", "PUCred", iClient);
        menu.AddItem("4", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    if(g_bBankShopGold && g_bLShopGoldExist)
    {
        Format(title, sizeof(title), "%T", "PGold", iClient);
        menu.AddItem("5", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        Format(title, sizeof(title), "%T", "PUGold", iClient);
        menu.AddItem("6", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    //if(g_bBankWcsGold && g_bWCSLoaded)
    if(g_bBankWcsGold)
    {
        Format(title, sizeof(title), "%T", "PWCSGold", iClient);
        menu.AddItem("7", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        Format(title, sizeof(title), "%T", "PUWCSGold", iClient);
        menu.AddItem("8", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    //if(g_bLKLoaded || g_bLKSystemLoaded)
    if(g_bBankLkRubles && g_bLKLoaded)
    {
        Format(title, sizeof(title), "%T", "PLKRub", iClient);
        menu.AddItem("9", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        Format(title, sizeof(title), "%T", "PULKRub", iClient);
        menu.AddItem("10", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    
    if(g_bBankMyJBCredits && g_bMyJBShopExist)
    {
        Format(title, sizeof(title), "%T", "PMyJBCredits", iClient);
        menu.AddItem("11", title, (GetClientRightStatus(iClient, "bank_give"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        Format(title, sizeof(title), "%T", "PUMyJBCredits", iClient);
        menu.AddItem("12", title, (GetClientRightStatus(iClient, "bank_take"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    
    //Format(title, sizeof(title), "%t", "Logs");
    //menu.AddItem("13", title, (GetClientRightStatus(iClient, "bank_logs"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    
    DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

/*****************************************************************
*******************	   LEAVE CONFIRMATION	  ********************
******************************************************************/


void OpenLeaveConfirmation(int iClient)
{
    Menu menu = CreateMenu(LeaveConfirmation_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
    
    char tempBuffer[128];
    
    Format(tempBuffer, sizeof(tempBuffer), "%T", "LeaveGang", iClient);
    SetMenuTitle(menu, tempBuffer);
    
    Format(tempBuffer, sizeof(tempBuffer), "%T", "AreYouSure", iClient);
    menu.AddItem("", tempBuffer, ITEMDRAW_DISABLED);
    if(ga_iRank[iClient] == 0)
    {
        Format(tempBuffer, sizeof(tempBuffer), "%T", "OwnerWarning", iClient);
        menu.AddItem("", tempBuffer, ITEMDRAW_DISABLED);
    }

    Format(tempBuffer, sizeof(tempBuffer), "%T", "YesLeave", iClient);
    menu.AddItem("yes", tempBuffer);
    
    Format(tempBuffer, sizeof(tempBuffer), "%T", "NoLeave", iClient);
    menu.AddItem("no", tempBuffer);

    menu.ExitBackButton = true;

    menu.Display(iClient, MENU_TIME_FOREVER);
}

public int LeaveConfirmation_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[64];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            if(StrEqual(sInfo, "yes"))
            {
                RemoveFromGang(param1);
            }
            else if(StrEqual(sInfo, "no"))
            {
                StartOpeningGangMenu(param1);
            }

        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
                StartOpeningGangMenu(param1);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}




/*****************************************************************
*********************  ADMIN MAIN MENU	**************************
******************************************************************/
void OpenAdministrationMenu(int iClient)
{
    if(!IsValidClient(iClient))
    {
        return;
    }
    Menu menu = CreateMenu(AdministrationMenu_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
    
    char tempBuffer[128];
    Format(tempBuffer, sizeof(tempBuffer), "%T", "GangAdmin", iClient);
    SetMenuTitle(menu, tempBuffer);
    
    char sDisplayString[128];
    
    Format(sDisplayString, sizeof(sDisplayString), "%T", "InviteToGang", iClient);
    //if(g_bModuleSizeExist)
    //	menu.AddItem("invite", sDisplayString, (ga_bHasGang[iClient] && GetClientRightStatus(iClient, "invite") && (ga_iGangSize[iClient] < g_iSize + Gangs_Size_GetCurrectLvl(iClient)))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    //else
    //	menu.AddItem("invite", sDisplayString, (ga_bHasGang[iClient] && GetClientRightStatus(iClient, "invite")	 && (ga_iGangSize[iClient] < g_iSize))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    
    //Format(sDisplayString, sizeof(sDisplayString), "%T", "KickAMember", iClient);
    //menu.AddItem("kick", sDisplayString, (GetClientRightStatus(iClient, "kick"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    
    if(g_bRenamePriceSellMode == 0 && g_bGameCMSExist)
    {
        int Discount;
        if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
            Discount = GameCMS_GetGlobalDiscount();
        else Discount = GameCMS_GetClientDiscount(iClient);
        
        Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, Colculate(iClient, g_iRenamePrice, Discount), "rubles", iClient);
        if(g_bEnableBank && g_bBankRubles && g_bRenameBank)
            menu.AddItem("rename", sDisplayString, (!GetClientRightStatus(iClient, "rename") || ga_iBankRubles[iClient] < g_iRenamePrice || (!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient)))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
        else
            menu.AddItem("rename", sDisplayString, (!GetClientRightStatus(iClient, "rename") || GameCMS_GetClientRubles(iClient) < g_iRenamePrice || (!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient)))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
    }
    else if(g_bRenamePriceSellMode == 1)
    {
        Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "shop", iClient);
        if(g_bEnableBank && g_bBankShop && g_bRenameBank)
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankCredits[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && Shop_GetClientCredits(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_bRenamePriceSellMode == 2 && g_bLShopGoldExist)
    {
        Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "shopgold", iClient);
        if(g_bEnableBank && g_bBankShopGold && g_bRenameBank)
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankGold[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && Shop_GetClientGold(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_bRenamePriceSellMode == 3)
    {
        Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "wcsgold", iClient);
        if(g_bEnableBank && g_bBankWcsGold && g_bRenameBank)
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankWCSGold[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && WCS_GetGold(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_bRenamePriceSellMode == 4 && g_bLKLoaded)
    {
        Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "lkrubles", iClient);
        if(g_bEnableBank && g_bBankLkRubles && g_bRenameBank)
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankLKRubles[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && LK_GetClientCash(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_bRenamePriceSellMode == 5 && g_bMyJBShopExist)
    {
        Format(sDisplayString, sizeof(sDisplayString), "%T [%i %T]", "RenameGang", iClient, g_iRenamePrice, "myjb", iClient);
        if(g_bEnableBank && g_bBankMyJBCredits && g_bRenameBank)
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && ga_iBankMyJBCredits[iClient] >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("rename", sDisplayString, (GetClientRightStatus(iClient, "rename") && MyJailShop_GetCredits(iClient) >= g_iRenamePrice)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    
    //Format(sDisplayString, sizeof(sDisplayString), "%T", "Promote", iClient);
    //menu.AddItem("promote", sDisplayString, (GetClientRightStatus(iClient, "ranks"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    
    Format(sDisplayString, sizeof(sDisplayString), "%T", "Disband", iClient);
    menu.AddItem("disband", sDisplayString, (ga_iRank[iClient] == 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);

    Format(sDisplayString, sizeof(sDisplayString), "%T", "Extend", iClient);
    //menu.AddItem("extend", sDisplayString, (ga_iRank[iClient] < Rank_Admin || (!g_bMenuInfo && g_bGameCMSExist && !GameCMS_Registered(iClient)))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
    menu.AddItem("extend", sDisplayString, (GetClientRightStatus(iClient, "extend"))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    
    //Format(sDisplayString, sizeof(sDisplayString), "%T", "TransferLeader", iClient);
    //menu.AddItem("transferleader", sDisplayString, (ga_iRank[iClient] == 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);

    menu.ExitBackButton = true;

    menu.Display(iClient, MENU_TIME_FOREVER);

}

public int AdministrationMenu_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    if(!IsValidClient(param1))
    {
        return;
    }
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[64];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            //if(StrEqual(sInfo, "kick"))
            //{
            //	OpenAdministrationKickMenu(param1);
            //}
            if(StrEqual(sInfo, "rename"))
            {
                for(int i = 1; i <= 5; i++)
                {
                    CPrintToChat(param1, "%t %t", "Prefix", "GangName");
                }
                ga_bRename[param1] = true;
            }
            //else if(StrEqual(sInfo, "promote"))
            //{
            //	OpenAdministrationPromotionMenu(param1);
            //}
            else if(StrEqual(sInfo, "disband"))
            {
                OpenDisbandMenu(param1);
            }
            else if(StrEqual(sInfo, "extend"))
            {
                char szQuery[256];
                Format( szQuery, sizeof( szQuery ),"SELECT end_date FROM gangs_groups WHERE gang = '%s' AND server_id = %i", ga_sGangName[param1], g_iServerID);
                g_hDatabase.Query(SQLCallback_OpenExtendMenu, szQuery, param1);
            }
            //else if(StrEqual(sInfo, "transferleader"))
            //{
            //	OpenTransferLeaderMenu(param1);
            //}
            //else if(StrEqual(sInfo, "invite"))
            //{
            //	OpenInvitationMenu(param1);
            //}
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
                StartOpeningGangMenu(param1);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}

public void SQLCallback_OpenExtendMenu(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_OpenExtendMenu] Error (%i): %s", data, error);
        return;
    }
    
    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        while(results.FetchRow())
        {
            OpenAdministrationMenuExtendGang(iClient, results.FetchInt(0));
        }
        
    }

}

void OpenAdministrationMenuExtendGang(int iClient,int endtime)
{
    if(!IsValidClient(iClient))
    {
        return;
    }
    Menu menu = CreateMenu(AdministrationMenuExtend_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
    
    char tempBuffer[512], sDisplayString[128];
    
    int days = (endtime-GetTime())/86400;
    if(days<0) days = 0;
    
    int iPrice;
    if(g_bExtendCostFormula)
        iPrice = g_iExtendCostPrice+g_iExtendModifier*GetGangLvl(ga_iScore[iClient]);
    else 
        iPrice = g_iExtendCostPrice;
        
    if(g_iExtendPriceSellMode == 0 && g_bGameCMSExist && GameCMS_Registered(iClient))
    {
        int Discount;
        if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
            Discount = GameCMS_GetGlobalDiscount();
        else Discount = GameCMS_GetClientDiscount(iClient);
        
        Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T\n%T", "GangExtend", iClient,days, Colculate(iClient, iPrice, Discount), "rubles", iClient, "Want?", iClient, "YourDiscount", iClient, Discount);		
    
        if(days>7)
            Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
        SetMenuTitle(menu, tempBuffer);
    
        Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
        
        if(g_bEnableBank && g_bBankRubles && g_bExtendBank)
            menu.AddItem("yes", sDisplayString, (ga_iBankRubles[iClient] >= Colculate(iClient, iPrice, Discount) && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("yes", sDisplayString, (GameCMS_GetClientRubles(iClient) >= Colculate(iClient, iPrice, Discount) && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_iExtendPriceSellMode == 1)
    {
        Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "shop", iClient, "Want?", iClient);		
    
        if(days>7)
            Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
        SetMenuTitle(menu, tempBuffer);
    
        Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
        
        if(g_bEnableBank && g_bBankShop && g_bExtendBank)
            menu.AddItem("yes", sDisplayString, (ga_iBankCredits[iClient] >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("yes", sDisplayString, (Shop_GetClientCredits(iClient) >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_iExtendPriceSellMode == 2 && g_bLShopGoldExist)
    {
        Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "shopgold", iClient, "Want?", iClient);		
    
        if(days>7)
            Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
        SetMenuTitle(menu, tempBuffer);
    
        Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
        
        if(g_bEnableBank && g_bBankShopGold && g_bExtendBank)
            menu.AddItem("yes", sDisplayString, (ga_iBankGold[iClient] >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("yes", sDisplayString, (Shop_GetClientGold(iClient) >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_iExtendPriceSellMode == 3)
    {
        Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "wcsgold", iClient, "Want?", iClient);		
    
        if(days>7)
            Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
        SetMenuTitle(menu, tempBuffer);
    
        Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
        
        if(g_bEnableBank && g_bBankWcsGold && g_bExtendBank)
            menu.AddItem("yes", sDisplayString, (ga_iBankWCSGold[iClient] >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("yes", sDisplayString, (WCS_GetGold(iClient) >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_iExtendPriceSellMode == 4 && g_bLKLoaded)
    {
        Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "lkrubles", iClient, "Want?", iClient);		
    
        if(days>7)
            Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
        SetMenuTitle(menu, tempBuffer);
    
        Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
        
        if(g_bEnableBank && g_bBankLkRubles && g_bExtendBank)
            menu.AddItem("yes", sDisplayString, (ga_iBankLKRubles[iClient] >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("yes", sDisplayString, (LK_GetClientCash(iClient) >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else if(g_iExtendPriceSellMode == 5 && g_bMyJBShopExist)
    {
        Format(tempBuffer, sizeof(tempBuffer), "%T %T\n%T", "GangExtend", iClient, days, iPrice, "myjb", iClient, "Want?", iClient);		
    
        if(days>7)
            Format(tempBuffer, sizeof(tempBuffer), "%s\n%T", tempBuffer, "ExtendedAvailable", iClient, days-7);
        SetMenuTitle(menu, tempBuffer);
    
        Format(sDisplayString, sizeof(sDisplayString), "%T", "Yes", iClient);
        
        if(g_bEnableBank && g_bBankMyJBCredits && g_bExtendBank)
            menu.AddItem("yes", sDisplayString, (ga_iBankMyJBCredits[iClient] >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
        else
            menu.AddItem("yes", sDisplayString, (MyJailShop_GetCredits(iClient) >= iPrice && days<=7)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
    }
    else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
    
    
    Format(sDisplayString, sizeof(sDisplayString), "%T", "No", iClient);
    menu.AddItem("no", sDisplayString);
    

    menu.ExitBackButton = true;

    menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AdministrationMenuExtend_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    if(!IsValidClient(param1))
    {
        return;
    }
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[64];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            if(StrEqual(sInfo, "yes"))
            {
                char szQuery[256];
                Format( szQuery, sizeof( szQuery ),"SELECT end_date FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", ga_sGangName[param1], g_iServerID);
                g_hDatabase.Query(SQLCallback_ExtendGang, szQuery, param1);
            }
            else if(StrEqual(sInfo, "no"))
            {
                OpenAdministrationMenu(param1);
            }
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
                OpenAdministrationMenu(param1);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}

public void SQLCallback_ExtendGang(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_ExtendGang] Error (%i): %s", data, error);
        return;
    }
    
    int iClient = data;
    if(!IsValidClient(iClient))
    {
        return;
    }
    else 
    {
        while(results.FetchRow())
        {
            SetTimeEndGang(ga_sGangName[iClient],results.FetchInt(0)+2629743);
            CPrintToChat(iClient, "%t %t", "Prefix", "GangExtended");
            char sQuery[300];
            int iPrice;
            if(g_bExtendCostFormula)
                iPrice = g_iExtendCostPrice+g_iExtendModifier*GetGangLvl(ga_iScore[iClient]);
            else 
                iPrice = g_iExtendCostPrice;
            if(g_iExtendPriceSellMode == 0 && g_bGameCMSExist)
            {
                int Discount;
                if(GameCMS_GetGlobalDiscount() > GameCMS_GetClientDiscount(iClient))
                    Discount = GameCMS_GetGlobalDiscount();
                else Discount = GameCMS_GetClientDiscount(iClient);
                
                if(g_bEnableBank && g_bBankRubles && g_bExtendBank)
                    SetBankRubles(iClient, ga_iBankRubles[iClient] - Colculate(iClient, iPrice, Discount));
                else
                    GameCMS_SetClientRubles(iClient, GameCMS_GetClientRubles(iClient) - Colculate(iClient, iPrice, Discount));
            
                if(g_bLog)
                    LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i рублей", iClient, Colculate(iClient, iPrice, Discount));
            }
            else if(g_iExtendPriceSellMode == 1)
            {
                if(g_bEnableBank && g_bBankShop && g_bExtendBank)
                    SetBankCredits(iClient, ga_iBankCredits[iClient] - iPrice);
                else
                    Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - iPrice);
            
                if(g_bLog)
                    LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i кредитов", iClient, iPrice);
            }
            else if(g_iExtendPriceSellMode == 2 && g_bLShopGoldExist)
            {
                if(g_bEnableBank && g_bBankShopGold && g_bExtendBank)
                    SetBankGold(iClient, ga_iBankGold[iClient] - iPrice);
                else
                    Shop_SetClientGold(iClient, Shop_GetClientGold(iClient) - iPrice);
            
                if(g_bLog)
                    LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i голды", iClient, iPrice);
            }
            //else if(g_iExtendPriceSellMode == 3 && g_bWCSLoaded)
            else if(g_iExtendPriceSellMode == 3)
            {
                if(g_bEnableBank && g_bBankWcsGold && g_bExtendBank)
                    SetBankWCSGold(iClient, ga_iBankWCSGold[iClient] - iPrice);
                else
                    WCS_TakeGold(iClient, iPrice);
            
                if(g_bLog)
                    LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i WCS голды", iClient, iPrice);
            }
            else if(g_iExtendPriceSellMode == 4 && g_bLKLoaded)
            {
                if(g_bEnableBank && g_bBankLkRubles && g_bExtendBank)
                    SetBankLKRubles(iClient, ga_iBankLKRubles[iClient] - iPrice);
                else
                    LK_SetClientCash(iClient, LK_GetClientCash(iClient) - iPrice);
                            
                if(g_bLog)
                    LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i lk рублей", iClient, iPrice);
            }
            else if(g_iExtendPriceSellMode == 5 && g_bMyJBShopExist)
            {
                if(g_bEnableBank && g_bBankMyJBCredits && g_bExtendBank)
                    SetBankMyJBCredits(iClient, ga_iBankMyJBCredits[iClient] - iPrice);
                else
                    MyJailShop_SetCredits(iClient, MyJailShop_GetCredits(iClient) - iPrice);
                            
                if(g_bLog)
                    LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N продлил банду за %i lk рублей", iClient, iPrice);
            }
            else CPrintToChat(iClient, "%t %t", "Prefix", "Error");
            
            ga_iExtendCount[iClient]++;
            for(int i = 1; i <= MaxClients; i++)
            {
                if(IsValidClient(i) && iClient != i)
                {
                    if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
                    {
                        ga_iExtendCount[i]++;
                    }
                }
            }
            Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET extend_count = '%i' WHERE gang = '%s' AND server_id = %i;", ga_iExtendCount[iClient], ga_sGangName[iClient], g_iServerID);
            g_hDatabase.Query(SQLCallback_Void, sQuery);
        }
        
    }

}

/*****************************************************************
*******************	 ADMIN PROMOTION MENU  ***********************
******************************************************************/
void OpenPromoteDemoteMenu(int iClient, const char[] sInfo)
{
    char sTempArray[4][128];
    ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

    Menu menu = CreateMenu(AdministrationPromoDemoteMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
    
    char tempBuffer[128];
    Format(tempBuffer, sizeof(tempBuffer), "%T", "GangMembersRanks", iClient);
    SetMenuTitle(menu, tempBuffer);
    
    char sInfoString[1025];
    
    KeyValues ConfigRanks;
    ConfigRanks = new KeyValues("Ranks");
    char szBuffer[256];
    BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
    ConfigRanks.ImportFromFile(szBuffer);
    ConfigRanks.Rewind();
    if(ConfigRanks.GotoFirstSubKey())
    {
        do
        {
            ConfigRanks.GetSectionName(szBuffer, sizeof(szBuffer));
            if(!StrEqual("0", szBuffer))
            {
                Format(sInfoString, sizeof(sInfoString), "%s;%s;%s;%s", szBuffer, sTempArray[0], sTempArray[3], sTempArray[1]);
                char sName[128];
                ConfigRanks.GetString("Name", sName, sizeof(sName));
                Format(tempBuffer, sizeof(tempBuffer), "%T", sName, iClient);
                menu.AddItem(sInfoString, tempBuffer, (StrEqual(sTempArray[2], szBuffer))?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
            }
        } while(ConfigRanks.GotoNextKey());
    }
    delete ConfigRanks;
    
    menu.ExitBackButton = true;

    menu.Display(iClient, MENU_TIME_FOREVER);
}

public int AdministrationPromoDemoteMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[256];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            char sTempArray[4][128];
            ExplodeString(sInfo, ";", sTempArray, sizeof(sTempArray), sizeof(sTempArray[]));

            char sQuery[300];
            
            Format(sQuery, sizeof(sQuery), "UPDATE gangs_players SET rank = '%s' WHERE steamid = '%s' AND server_id = %i;", sTempArray[0], sTempArray[1], g_iServerID);
            g_hDatabase.Query(SQLCallback_Void, sQuery);
            
            char sRank[128];
            KeyValues ConfigRanks;
            ConfigRanks = new KeyValues("Ranks");
            char szBuffer[256];
            BuildPath(Path_SM, szBuffer,256, "configs/gangs/ranks.txt");
            ConfigRanks.ImportFromFile(szBuffer);
            ConfigRanks.Rewind();
            if(ConfigRanks.JumpToKey(sTempArray[0])) // Попытка перейти к ключу
            {
                ConfigRanks.GetString("Name", sRank, sizeof(sRank));
            }
            delete ConfigRanks;
            
            char sSteamID[32];
            for(int i = 1; i <= MaxClients; i++)
            {
                if(IsValidClient(i))
                {
                    if(StrEqual(ga_sGangName[i],sTempArray[2]))
                    {
                        CPrintToChat(i, "%t %t", "Prefix", "ChangeRank", sTempArray[3], sRank);
                    }
                    GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof(sSteamID));
                    if(StrEqual(sSteamID, sTempArray[0]))
                    {
                        LoadSteamID(i);
                        break;
                    }
                }
            }
        }
        case MenuAction_Cancel:
        {
            OpenAdministrationMenu(param1);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}

/*****************************************************************
*********************	DISBAND MENU	**************************
******************************************************************/
void OpenDisbandMenu(int iClient)
{
    Menu menu = CreateMenu(DisbandMenu_CallBack, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem | MenuAction_Cancel);
    
    char tempString[256];
    
    Format(tempString, sizeof(tempString), "%T", "DisbandGang", iClient);
    SetMenuTitle(menu, tempString);

    Format(tempString, sizeof(tempString), "%T", "DisbandConfirmation", iClient);
    menu.AddItem("", tempString, ITEMDRAW_DISABLED);
    
    Format(tempString, sizeof(tempString), "%T", "YesDisband", iClient);
    menu.AddItem("disband", tempString);

    Format(tempString, sizeof(tempString), "%T", "NoDisband", iClient);
    menu.AddItem("no", tempString);

    menu.ExitBackButton = true;

    menu.Display(iClient, MENU_TIME_FOREVER);
}

public int DisbandMenu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[256];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            if(StrEqual(sInfo, "disband"))
            {
                RemoveFromGang(param1);
            }
        }
        case MenuAction_Cancel:
        {
            OpenAdministrationMenu(param1);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}

/*****************************************************************
**********************	TOP GANGS MENU	**************************
******************************************************************/
public void StartOpeningTopGangsMenu(int iClient)
{
    char ItemName[52], text[76];
    Menu hMenu = new Menu(ShowStatisticMenu_CallBack);
    
    char sTitleString[64];
    Format(sTitleString, sizeof(sTitleString), "%T", "TopGangs", iClient);
    hMenu.SetTitle(sTitleString);
    
    for(int i; i < g_iStatsCount; i++)
    {
        char sInfo[128];
        g_hStatName.GetString(i, ItemName, sizeof(ItemName));
        FormatEx(text, sizeof(text), "%T", ItemName, iClient);
        FormatEx(sInfo, sizeof(sInfo), "%i;%s", g_hStatID.Get(i, 0, false), ItemName);
        hMenu.AddItem(sInfo, text);
    }
    hMenu.ExitBackButton = true;
    hMenu.Display(iClient, 0);
}

public int ShowStatisticMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
    switch(action)
    {
        case MenuAction_End: 
            delete hMenu;
        case MenuAction_Select:
        {
            char sInfo[128], sBuffers[2][64];
            hMenu.GetItem(iItem, sInfo, sizeof(sInfo));
            ExplodeString(sInfo, ";", sBuffers, 2, 64);
            int index = -1;
            if((index = g_hStatsArray.FindString(sBuffers[1])) != -1)
            {
                DataPack hPack;
                hPack = g_hStatsArray.Get(index+1);
                hPack.Reset();
                Handle hPlugin = hPack.ReadCell();
                Function fncCallback = hPack.ReadFunction();
                if(IsCallValid(hPlugin, fncCallback))
                {
                    Call_StartFunction(hPlugin, fncCallback);
                    Call_PushCell(iClient);
                    Call_PushCell(StringToInt(sBuffers[0]));
                    Call_PushString(sBuffers[1]);
                    Call_Finish();
                }
            }
        }
        case MenuAction_Cancel:
            if(iItem == MenuCancel_ExitBack)
                StartOpeningGangMenu(iClient);
    }
}

/*****************************************************************
***********************	 HELPER FUNCTIONS  ***********************
******************************************************************/
void UpdateSQL(int iClient)
{
    if(ga_bHasGang[iClient])
    {
        GetClientAuthId(iClient, AuthId_Steam2, ga_sSteamID[iClient], sizeof(ga_sSteamID[]));
        
        char sQuery[300];
        Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_players WHERE steamid = '%s' AND server_id = %i;", ga_sSteamID[iClient], g_iServerID);

        g_hDatabase.Query(SQLCallback_CheckIfInDatabase_Player, sQuery, iClient);
    }
}

public void SQLCallback_CheckIfInDatabase_Player(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCallback_CheckIfInDatabase_Player] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }
    if(results.RowCount == 0)
    {
        ga_bIsPlayerInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsPlayerInDatabase[iClient] = true;
    }
    
    char sQuery[300];
    
    char sName[MAX_NAME_LENGTH];
    GetClientName(iClient, sName, sizeof(sName));
    int iLen = 2*strlen(sName)+1;
    char[] szEscapedName = new char[iLen];
    g_hDatabase.Escape(GetFixString(sName), szEscapedName, iLen);

    iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] sEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), sEscapedGang, iLen);
    
    if(!ga_bIsPlayerInDatabase[iClient])
    {
        Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_players (gang, server_id, invitedby, rank, date, steamid, playername) VALUES('%s', '%i', '%s', '%i', '%i', '%s', '%s');", sEscapedGang, g_iServerID, ga_sInvitedBy[iClient], ga_iRank[iClient], ga_iDateJoined[iClient], ga_sSteamID[iClient], szEscapedName);
    }
    else
    {
        Format(sQuery, sizeof(sQuery), "UPDATE gangs_players SET gang = '%s', invitedby = '%s', playername = '%s', rank = '%i', date = '%i' WHERE steamid = '%s' AND server_id = %i;", sEscapedGang, ga_sInvitedBy[iClient], szEscapedName, ga_iRank[iClient], ga_iDateJoined[iClient], ga_sSteamID[iClient], g_iServerID);
    }
    if(iClient<=MaxClients && iClient > 0)
    {
        API_OnGoToGang(iClient, ga_sGangName[iClient], ga_iInvitation[iClient]);
    }
    g_hDatabase.Query(SQLCallback_Void, sQuery, 111);

    Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", sEscapedGang, g_iServerID);
    
    g_hDatabase.Query(SQLCALLBACK_GROUPS, sQuery, iClient);
}

public void SQLCALLBACK_GROUPS(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQLCALLBACK_GROUPS] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }

    if(results.RowCount == 0)
    {
        ga_bIsGangInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsGangInDatabase[iClient] = true;
    }

    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    if(!ga_bIsGangInDatabase[iClient])
    {
        int created = GetTime();
        int ended = created+2629743;

        Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_groups (gang, server_id, create_date, end_date, extend_count) VALUES('%s', '%i', '%i', '%i', '%i');", szEscapedGang, g_iServerID, created, ended, ga_iExtendCount[iClient]);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 222);
    }


    Format(sQuery, sizeof(sQuery), "SELECT * FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQL_Callback_LoadStatistics, sQuery, iClient);

}

public void SQL_Callback_LoadStatistics(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQL_Callback_LoadStatistics] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }

    if(results.RowCount == 0)
    {
        ga_bIsGangInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsGangInDatabase[iClient] = true;
    }

    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    if(!ga_bIsGangInDatabase[iClient])
        Format(sQuery, sizeof(sQuery), "INSERT INTO `gangs_statistics` (`gang`, `server_id`, `%s`) VALUES('%s', '%i', '%i');", g_sDbStatisticName, szEscapedGang, g_iServerID, ga_iScore[iClient]);
    else
        Format(sQuery, sizeof(sQuery), "UPDATE `gangs_statistics SET` `%s` = '%i' WHERE gang= '%s' AND `server_id` = %i;", g_sDbStatisticName, ga_iScore[iClient], szEscapedGang, g_iServerID);

    g_hDatabase.Query(SQLCallback_Void, sQuery, 333);

    Format(sQuery, sizeof(sQuery), "SELECT * FROM `gangs_perks` WHERE `gang` = '%s' AND `server_id` = %i;", szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQL_Callback_LoadPerks, sQuery, iClient);
}

public void SQL_Callback_LoadPerks(Database db, DBResultSet results, const char[] error, int data)
{
    if(error[0])
    {
        LogError("[SQL_Callback_LoadPerks] Error (%i): %s", data, error);
        return;
    }

    int iClient = data;

    if(!IsValidClient(iClient))
    {
        return;
    }

    if(results.RowCount == 0)
    {
        ga_bIsGangInDatabase[iClient] = false;
    }
    else
    {
        ga_bIsGangInDatabase[iClient] = true;
    }

    char sQuery[300];
    if(!ga_bIsGangInDatabase[iClient])
    {
        int iLen = 2*strlen(ga_sGangName[iClient])+1;
        char[] szEscapedGang = new char[iLen];
        g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

        Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_perks (gang, server_id) VALUES('%s', '%i');", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 444);
    }

}

void RemoveFromGang(int iClient)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    if(ga_iRank[iClient] == 0)
    {

        char sQuery[300];
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_players WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_groups WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_statistics WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_bank_logs WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gangs_perks WHERE gang = '%s' AND server_id = %i;", szEscapedGang, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "GangDisbanded", szName, szEscapedGang);
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsValidClient(i) && StrEqual(ga_sGangName[i], ga_sGangName[iClient]) && i != iClient)
            {
                API_OnExitFromGang(i);
                ResetVariables(i, false);
            }
        }
        API_OnExitFromGang(iClient);
        ResetVariables(iClient, false);
    }
    else
    {
        char sQuery1[128];
        Format(sQuery1, sizeof(sQuery1), "DELETE FROM gangs_players WHERE steamid = '%s' AND server_id = %i;", ga_sSteamID[iClient], g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery1);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "LeftGang", szName, ga_sGangName[iClient]);
        API_OnExitFromGang(iClient);
        ResetVariables(iClient, false);
    }
}

void PrintToGang(int iClient, bool bPrintToClient = false, const char[] sMsg, any ...)
{
    if(!IsValidClient(iClient))
    {
        return;
    }
    char sFormattedMsg[256];
    VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 4); 

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && StrEqual(ga_sGangName[i], ga_sGangName[iClient]) && !StrEqual(ga_sGangName[iClient], ""))
        {
            if(bPrintToClient)
            {
                CPrintToChat(i, sFormattedMsg);
            }
            else
            {
                if(i == iClient)
                {
                    // Do nothing
                }
                else
                {
                    CPrintToChat(i, sFormattedMsg);
                }
            }
        }
    }
}

void ResetVariables(int iClient, bool full = true)
{
    ga_iRank[iClient] = -1;
    ga_iGangSize[iClient] = -1;
    ga_iInvitation[iClient] = -1;
    ga_iDateJoined[iClient] = -1;
    ga_iSize[iClient] = 0;
    ga_iScore[iClient] = 0;
    ga_iBankRubles[iClient] = 0;
    ga_iBankCredits[iClient] = 0;
    ga_iBankGold[iClient] = 0;
    ga_iBankWCSGold[iClient] = 0;
    ga_iExtendCount[iClient] = 0;
    ga_iTempInt1[iClient] = 0;
    ga_iTempInt2[iClient] = 0;
    ga_sGangName[iClient] = "";
    ga_sInvitedBy[iClient] = "";
    ga_bSetName[iClient] = false;
    ga_bIsPlayerInDatabase[iClient] = false;
    ga_bIsGangInDatabase[iClient] = false;
    ga_bHasGang[iClient] = false;
    ga_bRename[iClient] = false;
    ga_iEndTime[iClient] = -1;
    ga_bInvitationSent[iClient] = false;
    g_iBankCountType[iClient] = 0;
    if(full)
    {
        ga_sSteamID[iClient] = "";
        //ga_iProfileID[iClient] = -1;
        //ga_sProfileName[iClient] = "";
        //ga_iProfileSale[iClient] = 0;
        //ga_iDiscount[iClient] = 0;
        //ga_iPlayerShilings[iClient] = 0;
        ga_bBlockInvites[iClient] = false;
        ga_bHasPref[iClient] = false;
        ga_bLoaded[iClient] = false;
    }
}


void SetTimeEndGang(char[] gang,int time)
{
    char szQuery[256];
    Format( szQuery, sizeof( szQuery ),"UPDATE gangs_groups SET end_date = '%i' WHERE gang = '%s' AND server_id = %i;", time, gang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, szQuery);
}

void API_OnGoToGang(int iClient, char[] sGang, int Inviter) {
    Call_StartForward(g_hOnGangGoToGang);
    Call_PushCell(iClient);
    Call_PushString(sGang);
    Call_PushCell(Inviter);
    Call_Finish();
}

void API_OnExitFromGang(int iClient) {
    Call_StartForward(g_hOnGangExitFromGang);
    Call_PushCell(iClient);
    Call_Finish();
}

public Action SetBankRubles(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET rubles = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankRubles[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i рублей", iClient, shilings-ga_iBankRubles[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i рублей", iClient, ga_iBankRubles[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    
    bool check;int money;
    if(ga_iBankRubles[iClient] < shilings)
    {
        check = false;
        money = shilings - ga_iBankRubles[iClient];
    }
    else 
    {
        check = true;
        money = ga_iBankRubles[iClient] - shilings;
    }
    
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N забрал из казны %i рублей ( Было %i, стало %i)", iClient, money, ga_iBankRubles[iClient], shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N положил в казну %i рублей ( Было %i, стало %i)", iClient, money, ga_iBankRubles[iClient], shilings);
    }
        
    ga_iBankRubles[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankRubles[i]=ga_iBankRubles[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankCredits(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET credits = %i WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>=ga_iBankCredits[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i кредитов", iClient, shilings-ga_iBankCredits[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i кредитов", iClient, ga_iBankCredits[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', %d, %i);", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankCredits[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankCredits[i]=ga_iBankCredits[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankGold(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET gold = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankGold[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i голды", iClient, shilings-ga_iBankGold[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i голды", iClient, ga_iBankGold[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankGold[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankGold[i]=ga_iBankGold[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankWCSGold(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET wcsgold = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankWCSGold[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i WCS голды", iClient, shilings-ga_iBankWCSGold[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i WCS голды", iClient, ga_iBankWCSGold[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankWCSGold[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankWCSGold[i]=ga_iBankWCSGold[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankLKRubles(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET lk_rubles = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankLKRubles[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i LK рубли", iClient, shilings-ga_iBankLKRubles[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i LK рубли", iClient, ga_iBankLKRubles[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date, server_id) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankLKRubles[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankLKRubles[i]=ga_iBankLKRubles[iClient];
            }
        }
    }
    
    return;
}

public Action SetBankMyJBCredits(int iClient, int shilings)
{
    int iLen = 2*strlen(ga_sGangName[iClient])+1;
    char[] szEscapedGang = new char[iLen];
    g_hDatabase.Escape(GetFixString(ga_sGangName[iClient]), szEscapedGang, iLen);

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gangs_groups SET myjb_credits = '%i' WHERE gang = '%s' AND server_id = %i;", shilings, szEscapedGang, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    char log[300];
    if(shilings>ga_iBankMyJBCredits[iClient])
        Format(log, sizeof(log), "Игрок %N положил в банк %i MyJB Кредиты", iClient, shilings-ga_iBankMyJBCredits[iClient]);
    else
        Format(log, sizeof(log), "Игрок %N забрал из банка %i MyJB Кредиты", iClient, ga_iBankMyJBCredits[iClient]-shilings);
    Format(sQuery, sizeof(sQuery), "INSERT INTO gangs_bank_logs (gang, nick, logs, date) VALUES('%s', '%N', '%s', '%d', '%i');", szEscapedGang, iClient, log, GetTime(), g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery);
    ga_iBankMyJBCredits[iClient]=shilings;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && iClient != i)
        {
            if(StrEqual(ga_sGangName[i], ga_sGangName[iClient]))
            {
                ga_iBankMyJBCredits[i]=ga_iBankMyJBCredits[iClient];
            }
        }
    }
    
    return;
}

public int Colculate(int iClient, int Number, int Discount)
{
    int Sale = RoundToNearest((float(Number) * float(Discount))/100.0);
    
    return Number-Sale;
}

void LoadConfigSettings(char kvName[256],char file[256])
{
    delete ConfigSettings;
    ConfigSettings = new KeyValues(kvName);
    char SzBuffer[256];
    BuildPath(Path_SM, SzBuffer,256, file);
    ConfigSettings.ImportFromFile(SzBuffer);
}