#include <sdktools>
#include <sdkhooks>
#include <autoexecconfig>
#include <gangs>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <gamecms_system>
#tryinclude <shop>
#tryinclude <store>
#tryinclude <wcs>
#tryinclude <lk>
#tryinclude <gangs_size>
#tryinclude <myjailshop>
#tryinclude <gangs_statistic_rating>
#define REQUIRE_PLUGIN

#pragma newdecls required

#include "gangs/Globals.sp"
#include "gangs/Cvars.sp"
#include "gangs/Config.sp"
#include "gangs/Natives.sp"
#include "gangs/Forwards.sp"
#include "gangs/Cmds.sp"
#include "gangs/Database.sp"
#include "gangs/Stocks.sp"
#include "gangs/Menus.sp"
#include "gangs/Helpers.sp"

public Plugin myinfo =
{
    name = "GANGS CORE",
    author = "Faust",
    description = "Gang system for server cs",
    version = GANGS_VERSION
};

public void OnLibraryRemoved(const char[] name)
{
    if(StrEqual(name, "shop"))
        g_bShopLoaded = false;
    if(StrEqual(name, "store"))
        g_bStoreLoaded = false;
    if(StrEqual(name, "lk"))
        g_bLKLoaded = false;
    if(StrEqual(name, "gamecms_system"))
        g_bGameCMSExist = false;
    if(StrEqual(name, "gangs_size"))
        g_bModuleSizeExist = false;
    if(StrEqual(name, "myjailshop"))
        g_bMyJBShopExist = false;
    if(StrEqual(name, "gangs_statistic_rating"))
        g_bStatisticRating = false;
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "shop"))
        g_bShopLoaded = true;
    if(StrEqual(name, "store"))
        g_bStoreLoaded = true;
    if(StrEqual(name, "lk"))
        g_bLKLoaded = true;
    if(StrEqual(name, "gamecms_system"))
        g_bGameCMSExist = true;
    if(StrEqual(name, "gangs_size"))
        g_bModuleSizeExist = true;
    if(StrEqual(name, "myjailshop"))
        g_bMyJBShopExist = true;
    if(StrEqual(name, "gangs_statistic_rating"))
        g_bStatisticRating = true;
}

public void OnPluginStart()
{
    BuildPath(Path_SM, g_sFile, sizeof(g_sFile), "configs/gangs/info.ini");

    LoadTranslations("gangs.phrases");
    LoadTranslations("gangs_modules.phrases");
    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    
    CreateCvars();
    CreateArrays();
    CreateForwards();
    RegAllCmds();
                
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

public void OnMapStart()
{
    if(g_bPluginEnabled)
    {
        LoadConfig();
        
        if(g_iCreateGangDays>0)
            CreateTimer(10.0, Timer_CheckGangEnd);
    }
}

public void OnMapEnd()
{
    delete ConfigSettings;
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
        ResetVariables(iClient);
    }
}

public void OnClientPutInServer(int iClient) 
{
    if(IsValidClient(iClient))
    {
        CreateTimer(2.0, Timer_AlertGang, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
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
                    if(g_bShopLoaded)
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
                    else if(g_bStoreLoaded)
                    {
                        if(Store_GetClientCredits(iClient) >= iCount)
                        {
                            Store_SetClientCredits(iClient, Store_GetClientCredits(iClient) - iCount);
                            SetBankCredits(iClient, ga_iBankCredits[iClient] + iCount);
                            CPrintToChat(iClient, "%t %t", "Prefix", "BankSuccessfullyAction");
                        }
                        else
                            CPrintToChat(iClient, "%t %t", "Prefix", "BankNotEnoughAction");
                    }
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
        {
            CPrintToChat(iClient, "%t %t", "Prefix", "BankWrongAction");
        }
        
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
                    else if(g_bCreateGangSellMode == 1)
                    {
                        if(g_bShopLoaded)
                        {
                            Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iCreateGangPrice);
                        }
                        else if(g_bStoreLoaded)
                        {
                            Store_SetClientCredits(iClient, Store_GetClientCredits(iClient) - g_iCreateGangPrice);
                        }
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
                        if(g_bEnableBank && g_bBankShop && g_bRenameBank)
                            SetBankCredits(iClient, ga_iBankCredits[iClient] - g_iRenamePrice);
                        else
                        {
                            if(g_bShopLoaded)
                                Shop_SetClientCredits(iClient, Shop_GetClientCredits(iClient) - g_iRenamePrice);
                            else if(g_bStoreLoaded)
                                Store_SetClientCredits(iClient, Store_GetClientCredits(iClient) - g_iRenamePrice);
                        }
                        
                        if(g_bLog)
                            LogToFile("addons/sourcemod/logs/gangs.txt", "Игрок %N изменил название банды с %s на %s за %i кредитов", iClient, sOldName, sText, g_iRenamePrice);
                    }
                    else if(g_bRenamePriceSellMode == 2 && g_bLShopGoldExist)
                    {
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
    }
}