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
    version = GANGS_VERSION,
	url = "https://uwu-party.ru"
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

public void OnPluginEnd()
{
	ClearArrays();
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
        ResetVariables(iClient);
}

public void OnClientDisconnect(int iClient)
{
    if(g_bPluginEnabled)
        ResetVariables(iClient);
}

public void OnClientPutInServer(int iClient) 
{
    if(IsValidClient(iClient))
        CreateTimer(2.0, Timer_AlertGang, iClient, TIMER_FLAG_NO_MAPCHANGE);
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

public Action OnSay(int iClient, const char[] command, int args) 
{
    if(!IsValidClient(iClient))
        return Plugin_Continue;

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
        Format(sQuery, sizeof(sQuery), "SELECT * \
                                        FROM gang_group \
                                        WHERE `name` = '%s' AND server_id = %i;", 
                                        sFormattedText, g_iServerID);
        g_hDatabase.Query(SQLCallback_CheckName, sQuery, data);

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
        Format(sQuery, sizeof(sQuery), "SELECT * \
                                        FROM gang_group \
                                        WHERE `name` = '%s' AND `server_id` = %i;", 
                                        sFormattedText, g_iServerID);
        g_hDatabase.Query(SQLCallback_CheckName, sQuery, data);

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
                    if(LK_GetBalance(iClient, LK_Cash) >= iCount)
                    {
                        LK_ChangeBalance(iClient, LK_Cash, LK_Take, iCount);
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
                        LK_ChangeBalance(iClient, LK_Cash, LK_Add, iCount);
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