#pragma newdecls required

#include <gangs>
#include <sdkhooks>
#include <csgocolors>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>
#include <gamecms_system>
#include <gangs_statistic_rating>
#define REQUIRE_PLUGIN

enum struct enum_Item
{
    int Time;
    int StartMode;
    int TimeOutMode;
    int TimeOut;
    int ProcentAccept;
    int TimerAccept;
    int MinPlayers;
    int WinMode;
    int Summa;
    int GiveMode;
    int Take;
    int WhoCanSeeInfo;
    int Score;
    int Rating;
}

enum struct enum_TeamSettings
{
    int Point;
    char GangName[128];
}

enum struct enum_Team
{
    enum_TeamSettings Team1;
    enum_TeamSettings Team2;
}

enum_Item g_Item;
enum_Team g_Team;

char g_sGameName[] = "point_race";
Handle g_hTimer, g_hTimerShowInfo, g_hAcceptTimer;
bool g_bIsGameStarted = false;
int g_iTimeOut = 0;
int g_iCountAccept = 0;
int iGangPlayersCount;

int g_iTimeRemaining;

Handle g_hTimeOutTimer;

bool g_bStatisticRating = false;

public void OnAllPluginsLoaded()
{
    g_bStatisticRating = LibraryExists("gangs_statistic_rating");
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "gangs_statistic_rating"))
    {
        g_bStatisticRating = false;
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "gangs_statistic_rating"))
    {
        g_bStatisticRating = true;
    }
}

public Plugin myinfo =
{
    name = "[GANGS GAME] Point Race",
    author = "Faust",
    version = GANGS_VERSION
};

public void OnPluginStart()
{
    if(GetEngineVersion() != Engine_CSGO)
    {
        SetFailState("This plugin works only on CS:GO");
    }
    
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    KFG_load();
    
    Gangs_OnLoaded();
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if(g_bIsGameStarted)
    {
        g_bIsGameStarted = false;
        g_hTimer = CreateTimer(float(g_Item.Time), Timer_Delay);
        g_hTimerShowInfo = CreateTimer(1.0, Timer_ShowInfo, _, TIMER_REPEAT);
        g_iTimeRemaining = g_Item.Time;
        if(g_Item.TimeOutMode == 0)
            g_iTimeOut = g_Item.TimeOut;
        else if(g_Item.TimeOutMode == 1)
        {
            g_iTimeOut = 0;
            g_hTimeOutTimer = g_hTimer = CreateTimer(60.0, Timer_TimeOut, _, TIMER_REPEAT);
        }
    }
    if(g_Item.TimeOutMode == 0 && g_iTimeOut > 0)
    {
        g_iTimeOut--;
    }
}

public Action Timer_TimeOut(Handle hTimer, any iData) // Каллбек нашего таймера
{
    g_iTimeOut++;
    if(g_iTimeOut == g_Item.TimeOut)
    {
        if(g_hTimeOutTimer != INVALID_HANDLE)
        {
            KillTimer(g_hTimeOutTimer);
            g_hTimeOutTimer = INVALID_HANDLE;
        }

    }
}

public void Gangs_OnLoaded()
{
    LoadTranslations("gangs.phrases");
    LoadTranslations("gangs_modules.phrases");
    CreateTimer(5.0, AddToGamesMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
    char sGangNameClient[MAXPLAYERS + 1][256];
    if(g_hTimer != null)
    {
        if(attacker != iClient)
        {
            Gangs_GetClientGangName(attacker, sGangNameClient[attacker], sizeof(sGangNameClient[]));
            if(StrEqual(sGangNameClient[attacker], g_Team.Team1.GangName))
            {
                g_Team.Team1.Point++;
            }
            else if(StrEqual(sGangNameClient[attacker], g_Team.Team2.GangName))
            {
                g_Team.Team2.Point++;
            }
        }
    }
}

public Action AddToGamesMenu(Handle timer)
{
    Gangs_AddToGamesMenu(g_sGameName, PointRaceCallback);
}

public void OnPluginEnd()
{
    Gangs_DeleteFromGamesMenu(g_sGameName);
}

public void OnMapStart()
{
    KFG_load();
}

public void PointRaceCallback(int iClient, int ItemID, const char[] ItemName)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "SELECT name \
                                    FROM gang_group;");
    Database hDatabase = Gangs_GetDatabase();
    hDatabase.Query(SQLCallback_GetGangGroups, sQuery, iClient);
    delete hDatabase;
}

public void SQLCallback_GetGangGroups(Database db, DBResultSet results, const char[] error, int iClient)
{
    if (error[0])
    {
        LogError("[SQLCallback_GetGangGroups] Error (%i): %s", iClient, error);
        return;
    }

    if (!IsValidClient(iClient))
        return;
    
        
    if (results.RowCount != 0)
    {
        Menu menu = CreateMenu(ChoseEnemy_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
        menu.SetTitle("Выберите противника");

        char sGangName[128];
        char sGangNameClient[256];
        Gangs_GetClientGangName(iClient, sGangNameClient, sizeof(sGangNameClient));
        int iGangCountPlayers;
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsValidClient(i))
            {
                char sGangNameI[256];
                Gangs_GetClientGangName(i, sGangNameI, sizeof(sGangNameI));
                if(StrEqual(sGangNameClient, sGangNameI))
                {
                    iGangCountPlayers++;
                }
            }
        }
        while (results.FetchRow())
        {
            results.FetchString(0, sGangName, sizeof(sGangName));
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i) && i != iClient)
                {
                    char sGangNameI[256];
                    Gangs_GetClientGangName(i, sGangNameI, sizeof(sGangNameI));
                    if(StrEqual(sGangName, sGangNameI) && !StrEqual(sGangNameClient, sGangNameI))
                    {
                        iGangPlayersCount++;
                    }
                }
            }
            if(iGangPlayersCount >= g_Item.MinPlayers)
            {
                char sInfo[128];
                Format(sInfo, sizeof(sInfo), "%s;%i", sGangName, iGangPlayersCount);
                menu.AddItem(sInfo, sGangName);
            }
            iGangPlayersCount = 0;
        }
        menu.ExitBackButton = true;
        if(iGangCountPlayers >= g_Item.MinPlayers)
            menu.Display(iClient, MENU_TIME_FOREVER);
        else
            CPrintToChat(iClient, "%t %t", "Prefix", "point_race_not_enough_allies");
    }
}

public int ChoseEnemy_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if(g_hTimer == null || g_bIsGameStarted)
            {
                if(g_hAcceptTimer == null)
                {
                    if(g_iTimeOut == 0)
                    {
                        char sInfo[300];
                        char sPostInfo[2][128];
                        GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
                        
                        ExplodeString(sInfo, ";", sPostInfo, 2, sizeof(sPostInfo[]));
                        
                        char sGangNameClient[MAXPLAYERS + 1][128];
                        Gangs_GetClientGangName(param1, sGangNameClient[param1], sizeof(sGangNameClient[]));
                        
                        Menu menu1 = CreateMenu(Accept_Callback, MenuAction_Select | MenuAction_End | MenuAction_DisplayItem);
                        char sTitle[128];
                        Format(sTitle, sizeof(sTitle), "Вам бросила вызов банда %s", sGangNameClient[param1]);
                        menu1.SetTitle(sTitle);
            
                        menu1.AddItem("1", "Принять вызов");
                        menu1.AddItem("2", "Отказаться");
                                
                        menu1.ExitBackButton = false;
                        for (int i = 1; i <= MaxClients; i++)
                        {
                            if (IsValidClient(i))
                            {
                                char sGangName[256];
                                Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                                if(StrEqual(sGangName, sPostInfo[0]))
                                {
                                    menu1.Display(i, g_Item.TimerAccept);
                                }
                            }
                        }
                        g_hAcceptTimer = CreateTimer(float(g_Item.TimerAccept), Timer_Accept, StringToInt(sPostInfo[1]));
                        
                        g_Team.Team1.Point = 0;
                        //strcopy(g_Team.Team1.GangName, sizeof(128), sGangNameClient[param1]);
                        //Format(g_Team.Team1.GangName, sizeof(128), "%s", sGangNameClient[param1]);
                        strcopy(g_Team.Team1.GangName, 128, sGangNameClient[param1]);
                        g_Team.Team2.Point = 0;
                        //strcopy(g_Team.Team2.GangName, sizeof(128), sPostInfo[0]);
                        //Format(g_Team.Team2.GangName, sizeof(128), "%s", sPostInfo[0]);
                        strcopy(g_Team.Team2.GangName, 128, sPostInfo[0]);
                        //StartGame(sGangNameClient[param1], sInfo);
                    }
                    else
                        CPrintToChat(param1, "%t %t", "Prefix", "point_race_wait", g_iTimeOut);
                }
                else
                    CPrintToChat(param1, "%t %t", "Prefix", "point_race_preparing");
            }
            else
                CPrintToChat(param1, "%t %t", "Prefix", "point_race_battle_between", g_Team.Team1.GangName, g_Team.Team2.GangName);
        }
        case MenuAction_End:
            delete menu;
        case MenuAction_Cancel:
            if(param2 == MenuCancel_ExitBack)
                Gangs_ShowGamesMenu(param1);
    }
    return;
}

public Action Timer_Accept(Handle hTimer, int iPlayersGangCount) // Каллбек нашего таймера
{
    if(((g_iCountAccept*100.0)/iPlayersGangCount) >= float(g_Item.ProcentAccept))
    {
        StartGame();
    }
    KillTimer(g_hAcceptTimer);
    g_hAcceptTimer = null;
}

public int Accept_Callback(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sInfo[64];
            GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
            if(StrEqual(sInfo, "1"))
            {
                g_iCountAccept++;
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return;
}

void StartGame()
{
    if(!g_Item.StartMode)
    {
        g_hTimer = CreateTimer(float(g_Item.Time), Timer_Delay);
        g_hTimerShowInfo = CreateTimer(1.0, Timer_ShowInfo, _, TIMER_REPEAT);
        g_iTimeRemaining = g_Item.Time;
        g_iTimeOut = g_Item.TimeOut;
    }
    else
    {
        g_bIsGameStarted = true;
    }
}

public Action Timer_Delay(Handle hTimer, any iData) // Каллбек нашего таймера
{
    if (g_hTimer != INVALID_HANDLE)
    {
        KillTimer(g_hTimer);
        g_hTimer = INVALID_HANDLE;		// Обнуляем значения дескриптора
    }
    if(g_Team.Team1.Point > g_Team.Team2.Point)
    {
        CPrintToChatAll("%t %t", "Prefix", "point_race_win", g_Team.Team1.GangName);
        if(!g_Item.WinMode)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    char sGangName[256];
                    Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                    if(StrEqual(sGangName, g_Team.Team1.GangName))
                    {
                        switch(g_Item.GiveMode)
                        {
                            case 0:
                                Gangs_GiveBankClientCash(i, "rubles", g_Item.Summa);
                            case 1:
                                Gangs_GiveBankClientCash(i, "shop", g_Item.Summa);
                            case 2:
                                Gangs_GiveBankClientCash(i, "shopgold", g_Item.Summa);
                            case 3:
                                Gangs_GiveBankClientCash(i, "wcsgold", g_Item.Summa);
                            case 4:
                                Gangs_GiveBankClientCash(i, "lkrubles", g_Item.Summa);
                            case 5:
                                Gangs_GiveBankClientCash(i, "myjb", g_Item.Summa);
                        }
                        Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)+g_Item.Rating);
                        break;
                    }
                }
            }
            if(g_Item.Take)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsValidClient(i))
                    {
                        char sGangName[256];
                        Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                        if(StrEqual(sGangName, g_Team.Team2.GangName))
                        {
                            switch(g_Item.GiveMode)
                            {
                                case 0:
                                    Gangs_TakeBankClientCash(i, "rubles", g_Item.Summa);
                                case 1:
                                    Gangs_TakeBankClientCash(i, "shop", g_Item.Summa);
                                case 2:
                                    Gangs_TakeBankClientCash(i, "shopgold", g_Item.Summa);
                                case 3:
                                    Gangs_TakeBankClientCash(i, "wcsgold", g_Item.Summa);
                                case 4:
                                    Gangs_TakeBankClientCash(i, "lkrubles", g_Item.Summa);
                                case 5:
                                    Gangs_TakeBankClientCash(i, "myjb", g_Item.Summa);
                            }
                            Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)-g_Item.Rating);
                            break;
                        }
                    }
                }
            }
        }
        else
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    char sGangName[256];
                    Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                    if(StrEqual(sGangName, g_Team.Team1.GangName))
                    {
                        switch(g_Item.GiveMode)
                        {
                            case 0:
                                    Gangs_GiveClientCash(i, "rubles", g_Item.Summa);
                            case 1:
                                    Gangs_GiveClientCash(i, "shop", g_Item.Summa);
                            case 2:
                                    Gangs_GiveClientCash(i, "shopgold", g_Item.Summa);
                            case 3:
                                    Gangs_GiveClientCash(i, "wcsgold", g_Item.Summa);
                            case 4:
                                    Gangs_GiveClientCash(i, "lkrubles", g_Item.Summa);
                            case 5:
                                    Gangs_GiveClientCash(i, "myjb", g_Item.Summa);
                        }
                    }
                }
            }
            if(g_bStatisticRating)
            {
                if(g_Item.Rating>0)
                {
                    for (int i = 1; i <= MaxClients; i++)
                    {
                        if (IsValidClient(i))
                        {
                            char sGangName[256];
                            Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                            if(StrEqual(sGangName, g_Team.Team1.GangName))
                            {
                                Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)+g_Item.Rating);
                                break;
                            }
                        }
                    }
                }
            }
            if(g_Item.Take)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsValidClient(i))
                    {
                        char sGangName[256];
                        Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                        if(StrEqual(sGangName, g_Team.Team2.GangName))
                        {
                            switch(g_Item.GiveMode)
                            {
                                case 0:
                                        Gangs_TakeClientCash(i, "rubles", g_Item.Summa);
                                case 1:
                                        Gangs_TakeClientCash(i, "shop", g_Item.Summa);
                                case 2:
                                        Gangs_TakeClientCash(i, "shopgold", g_Item.Summa);
                                case 3:
                                        Gangs_TakeClientCash(i, "wcsgold", g_Item.Summa);
                                case 4:
                                        Gangs_TakeClientCash(i, "lkrubles", g_Item.Summa);
                                case 5:
                                        Gangs_TakeClientCash(i, "myjb", g_Item.Summa);
                            }
                        }
                    }
                }
                if(g_bStatisticRating)
                {
                    if(g_Item.Rating>0)
                    {
                        for (int i = 1; i <= MaxClients; i++)
                        {
                            if (IsValidClient(i))
                            {
                                char sGangName[256];
                                Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                                if(StrEqual(sGangName, g_Team.Team2.GangName))
                                {
                                    Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)-g_Item.Rating);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        if(g_Item.Score>0)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    char sGangName[256];
                    Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                    if(StrEqual(sGangName, g_Team.Team1.GangName))
                    {
                        Gangs_SetClientGangScore(i, Gangs_GetClientGangScore(i)+g_Item.Score);
                        break;
                    }
                }
            }
        }
    }
    else if(g_Team.Team1.Point < g_Team.Team2.Point)
    {
        CPrintToChatAll("%t %t", "Prefix", "point_race_win", g_Team.Team2.GangName);
        if(!g_Item.WinMode)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    char sGangName[256];
                    Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                    if(StrEqual(sGangName, g_Team.Team2.GangName))
                    {
                        switch(g_Item.GiveMode)
                        {
                            case 0:
                                    Gangs_GiveBankClientCash(i, "rubles", g_Item.Summa);
                            case 1:
                                    Gangs_GiveBankClientCash(i, "shop", g_Item.Summa);
                            case 2:
                                    Gangs_GiveBankClientCash(i, "shopgold", g_Item.Summa);
                            case 3:
                                    Gangs_GiveBankClientCash(i, "wcsgold", g_Item.Summa);
                            case 4:
                                    Gangs_GiveBankClientCash(i, "lkrubles", g_Item.Summa);
                            case 5:
                                    Gangs_GiveBankClientCash(i, "myjb", g_Item.Summa);
                        }
                        Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)+g_Item.Rating);
                        break;
                    }
                }
            }
            if(g_Item.Take)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsValidClient(i))
                    {
                        char sGangName[256];
                        Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                        if(StrEqual(sGangName, g_Team.Team1.GangName))
                        {
                            switch(g_Item.GiveMode)
                            {
                                case 0:
                                    Gangs_TakeBankClientCash(i, "rubles", g_Item.Summa);
                                case 1:
                                    Gangs_TakeBankClientCash(i, "shop", g_Item.Summa);
                                case 2:
                                    Gangs_TakeBankClientCash(i, "shopgold", g_Item.Summa);
                                case 3:
                                    Gangs_TakeBankClientCash(i, "wcsgold", g_Item.Summa);
                                case 4:
                                    Gangs_TakeBankClientCash(i, "lkrubles", g_Item.Summa);
                                case 5:
                                    Gangs_TakeBankClientCash(i, "myjb", g_Item.Summa);
                            }
                            Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)-g_Item.Rating);
                            break;
                        }
                    }
                }
            }
        }
        else
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    char sGangName[256];
                    Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                    if(StrEqual(sGangName, g_Team.Team2.GangName))
                    {
                        switch(g_Item.GiveMode)
                        {
                            case 0:
                                    Gangs_GiveClientCash(i, "rubles", g_Item.Summa);
                            case 1:
                                    Gangs_GiveClientCash(i, "shop", g_Item.Summa);
                            case 2:
                                    Gangs_GiveClientCash(i, "shopgold", g_Item.Summa);
                            case 3:
                                    Gangs_GiveClientCash(i, "wcsgold", g_Item.Summa);
                            case 4:
                                    Gangs_GiveClientCash(i, "lkrubles", g_Item.Summa);
                            case 5:
                                    Gangs_GiveClientCash(i, "lkrubles", g_Item.Summa);
                        }
                    }
                }
            }
            if(g_bStatisticRating)
            {
                if(g_Item.Rating>0)
                {
                    for (int i = 1; i <= MaxClients; i++)
                    {
                        if (IsValidClient(i))
                        {
                            char sGangName[256];
                            Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                            if(StrEqual(sGangName, g_Team.Team2.GangName))
                            {
                                Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)+g_Item.Rating);
                                break;
                            }
                        }
                    }
                }
            }
            if(g_Item.Take)
            {
                for (int i = 1; i <= MaxClients; i++)
                {
                    if (IsValidClient(i))
                    {
                        char sGangName[256];
                        Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                        if(StrEqual(sGangName, g_Team.Team1.GangName))
                        {
                            switch(g_Item.GiveMode)
                            {
                                case 0:
                                    Gangs_TakeClientCash(i, "rubles", g_Item.Summa);
                                case 1:
                                    Gangs_TakeClientCash(i, "shop", g_Item.Summa);
                                case 2:
                                    Gangs_TakeClientCash(i, "shopgold", g_Item.Summa);
                                case 3:
                                    Gangs_TakeClientCash(i, "wcsgold", g_Item.Summa);
                                case 4:
                                    Gangs_TakeClientCash(i, "lkrubles", g_Item.Summa);
                                case 5:
                                    Gangs_TakeClientCash(i, "myjb", g_Item.Summa);
                            }
                        }
                    }
                }
                if(g_bStatisticRating)
                {
                    if(g_Item.Rating>0)
                    {
                        for (int i = 1; i <= MaxClients; i++)
                        {
                            if (IsValidClient(i))
                            {
                                char sGangName[256];
                                Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                                if(StrEqual(sGangName, g_Team.Team1.GangName))
                                {
                                    Gangs_StatisticRating_SetClientRating(i, Gangs_StatisticRating_GetClientRating(i)-g_Item.Rating);
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
        if(g_Item.Score>0)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    char sGangName[256];
                    Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                    if(StrEqual(sGangName, g_Team.Team2.GangName))
                    {
                        Gangs_SetClientGangScore(i, Gangs_GetClientGangScore(i)+g_Item.Score);
                        break;
                    }
                }
            }
        }
    }
    else if(g_Team.Team1.Point == g_Team.Team2.Point)
        CPrintToChatAll("%t %t", "Prefix", "point_race_draw");
    return Plugin_Stop;
}

public Action Timer_ShowInfo(Handle hTimer, any iData) // Каллбек нашего таймера
{
    if(g_hTimer != INVALID_HANDLE)
    {
        g_iTimeRemaining--;
        if(g_Item.WhoCanSeeInfo)
        {
            for (int i = 1; i <= MaxClients; i++)
            {
                if (IsValidClient(i))
                {
                    char sGangName[256];
                    Gangs_GetClientGangName(i, sGangName, sizeof(sGangName));
                    if(StrEqual(sGangName, g_Team.Team1.GangName) || StrEqual(sGangName, g_Team.Team2.GangName))
                    {
                        char sBuffer[1024];
                        FormatEx(sBuffer, sizeof(sBuffer), "Битва между %s и %s\nОчков у %s: %i\nОчков у %s: %i\nОсталось времени: %i сек.", g_Team.Team1.GangName, g_Team.Team2.GangName, g_Team.Team1.GangName, g_Team.Team1.Point, g_Team.Team2.GangName, g_Team.Team2.Point, g_iTimeRemaining);
                        PrintCenterText(i, sBuffer);
                    }
                }
            }
        }
        else
        {
            char sBuffer[1024];
            FormatEx(sBuffer, sizeof(sBuffer), "Битва между %s и %s\nОчков у %s: %i\nОчков у %s: %i\nОсталось времени: %i сек.", g_Team.Team1.GangName, g_Team.Team2.GangName, g_Team.Team1.GangName, g_Team.Team1.Point, g_Team.Team2.GangName, g_Team.Team2.Point, g_iTimeRemaining);
            PrintCenterTextAll(sBuffer);
        }
    }
    else
    {
        if (g_hTimerShowInfo != INVALID_HANDLE)
        {
            KillTimer(g_hTimerShowInfo);
            g_hTimerShowInfo = INVALID_HANDLE;
        }
    }
}

void KFG_load()
{
    char path[128];
    KeyValues kfg = new KeyValues("GANGS_GAME");
    BuildPath(Path_SM, path, sizeof(path), "configs/gangs/gangs_game_point_race.ini");
    if(!kfg.ImportFromFile(path)) SetFailState("[GANGS GAME][POINT RACE] - Configuration file not found");
    kfg.Rewind();
    g_Item.Time = kfg.GetNum("time");
    g_Item.StartMode = kfg.GetNum("start_mode");
    g_Item.TimeOutMode = kfg.GetNum("timeout_mode");
    g_Item.TimeOut = kfg.GetNum("timeout");
    g_Item.ProcentAccept = kfg.GetNum("procent_accept");
    g_Item.TimerAccept = kfg.GetNum("timer_accept");
    g_Item.MinPlayers = kfg.GetNum("min_players");
    g_Item.WinMode = kfg.GetNum("win_mode");
    g_Item.Summa = kfg.GetNum("summa");
    g_Item.GiveMode = kfg.GetNum("give_mode");
    g_Item.Take = kfg.GetNum("take");
    g_Item.WhoCanSeeInfo = kfg.GetNum("whocanseeinfo");
    g_Item.Score = kfg.GetNum("score");
    if(g_bStatisticRating)
        g_Item.Rating = kfg.GetNum("rating");
    delete kfg;
}