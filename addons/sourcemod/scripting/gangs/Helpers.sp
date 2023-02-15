/* Gang expired */
public Action Timer_CheckGangEnd(Handle timer)
{
    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Check Gang End");
    
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "SELECT id, end_date \
                                    FROM gang_group;");
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
        int gangid = results.FetchInt(0);
        int endtime = results.FetchInt(1);
        if(g_bDebug)
            LogToFile("addons/sourcemod/logs/gangs_debug.txt", "(%i>%i, %i) - Check gang end time", GetTime(), endtime, gangid);
        if(GetTime()>endtime) DissolveGang(gangid);
    }
}
/*       end       */

public Action RefreshSteamID(Handle hTimer, int iUserID)
{
    int iClient = iUserID;
    if(!IsValidClient(iClient))
    {
        return;
    }

    GetClientAuthId(iClient, AuthId_Steam2, g_ClientInfo[iClient].steamid, 32);
    
    if(StrContains(g_ClientInfo[iClient].steamid, "STEAM_1", true) == -1) //still invalid - retry again
    {

        CreateTimer(5.0, RefreshSteamID, iClient, TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        LoadSteamID(iClient);
    }
}

public Action Timer_AlertGang(Handle hTimer, int iClient)
{
    if(!IsValidClient(iClient))
        return;
    
    char szName[MAX_NAME_LENGTH];
    GetClientName(iClient, szName, sizeof(szName));
    PrintToGang(iClient, false, "%T", "GangAlert", iClient, szName);
}

void DissolveGang(int gangid)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 34);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_statistic \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 35);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_bank_log \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 36);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_perk \
                                    WHERE gang_id = %i;", 
                                    gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 37);
    Format(sQuery, sizeof(sQuery), "DELETE FROM gang_group \
                                    WHERE id = %i AND server_id = %i;", 
                                    gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 38);
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && g_ClientInfo[i].gangid == gangid)
        {
            API_OnExitFromGang(i);
            ResetVariables(i);
        }
    }
}

public Action RepeatCheckRank(Handle timer, int iUserID)
{
    int iClient = iUserID;
    LoadSteamID(iClient);
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

void PrintToGang(int iClient, bool bPrintToClient = false, const char[] sMsg, any ...)
{
    if(!IsValidClient(iClient))
        return;

    char sFormattedMsg[256];
    VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 4); 

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsValidClient(i) && g_ClientInfo[i].gangid == g_ClientInfo[iClient].gangid)
        {
            if(bPrintToClient)
            {
                CPrintToChat(i, sFormattedMsg);
            }
            else
            {
                if(i != iClient)
                    CPrintToChat(i, sFormattedMsg);
            }
        }
    }
}

void SetTimeEndGang(int iClient, int iTime)
{
    g_GangInfo[GetGangLocalId(iClient)].extended_count++;

    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET end_date = %i, extend_count = %i \
                                    WHERE id = %i;", 
                                    iTime, g_GangInfo[GetGangLocalId(iClient)].extended_count, g_ClientInfo[iClient].gangid);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 6);
}

public Action SetBankRubles(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET rubles = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, g_ClientInfo[iClient].gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 7);

    char log[300];
    if(shilings > g_GangInfo[GetGangLocalId(iClient)].currency.rubles)
        Format(log, sizeof(log), "The player %N deposited %i rubles in the bank", iClient, shilings - g_GangInfo[GetGangLocalId(iClient)].currency.rubles);
    else
        Format(log, sizeof(log), "The player %N took %i rubles from the bank", iClient, g_GangInfo[GetGangLocalId(iClient)].currency.rubles - shilings);

    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    g_ClientInfo[iClient].gangid, g_ClientInfo[iClient].id, log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 8);
    
    bool check;
    int money;
    if(g_GangInfo[GetGangLocalId(iClient)].currency.rubles < shilings)
    {
        check = false;
        money = shilings - g_GangInfo[GetGangLocalId(iClient)].currency.rubles;
    }
    else 
    {
        check = true;
        money = g_GangInfo[GetGangLocalId(iClient)].currency.rubles - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "The player %N took %i rubles from the bank (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.rubles, shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "The player %N put into the bank %i rubles (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.rubles, shilings);
    }

    g_GangInfo[GetGangLocalId(iClient)].currency.rubles = shilings;
    
    return;
}

public Action SetBankCredits(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET credits = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, g_ClientInfo[iClient].gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 9);

    char log[300];
    if(shilings > g_GangInfo[GetGangLocalId(iClient)].currency.credits)
        Format(log, sizeof(log), "Player %N put %i credits in the bank", iClient, shilings - g_GangInfo[GetGangLocalId(iClient)].currency.credits);
    else
        Format(log, sizeof(log), "Player %N took %i credits from the bank", iClient, g_GangInfo[GetGangLocalId(iClient)].currency.credits - shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES(%i, %i, '%s', %d);", 
                                    g_ClientInfo[iClient].gangid, g_ClientInfo[iClient].id, log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 10);
    
    bool check;
    int money;
    if(g_GangInfo[GetGangLocalId(iClient)].currency.credits < shilings)
    {
        check = false;
        money = shilings - g_GangInfo[GetGangLocalId(iClient)].currency.credits;
    }
    else 
    {
        check = true;
        money = g_GangInfo[GetGangLocalId(iClient)].currency.credits - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Player %N took %i credits from the bank (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.credits, shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Player %N put into the bank %i credits (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.credits, shilings);
    }

    g_GangInfo[GetGangLocalId(iClient)].currency.credits = shilings;
    
    return;
}

public Action SetBankGold(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET gold = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, g_ClientInfo[iClient].gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 11);

    char log[300];
    if(shilings > g_GangInfo[GetGangLocalId(iClient)].currency.gold)
        Format(log, sizeof(log), "The player %N put in the bank %i of gold", iClient, shilings - g_GangInfo[GetGangLocalId(iClient)].currency.gold);
    else
        Format(log, sizeof(log), "Player %N took %i gold from the bank", iClient, g_GangInfo[GetGangLocalId(iClient)].currency.gold - shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    g_ClientInfo[iClient].gangid, g_ClientInfo[iClient].id, log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 12);
    
    bool check;
    int money;
    if(g_GangInfo[GetGangLocalId(iClient)].currency.gold < shilings)
    {
        check = false;
        money = shilings - g_GangInfo[GetGangLocalId(iClient)].currency.gold;
    }
    else 
    {
        check = true;
        money = g_GangInfo[GetGangLocalId(iClient)].currency.gold - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "The player %N took %i gold from the bank (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.gold, shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "The player %N put into the bank %i Gold (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.gold, shilings);
    }

    g_GangInfo[GetGangLocalId(iClient)].currency.gold = shilings;
    
    return;
}

public Action SetBankWCSGold(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET wcsgold = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, g_ClientInfo[iClient].gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 13);

    char log[300];
    if(shilings > g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold)
        Format(log, sizeof(log), "Player %N deposited %i WCS of gold in the bank", iClient, shilings - g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold);
    else
        Format(log, sizeof(log), "Player %N took %i WCS of gold from the bank", iClient, g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold - shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    g_ClientInfo[iClient].gangid, g_ClientInfo[iClient].id, log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 14);
    
    bool check;
    int money;
    if(g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold < shilings)
    {
        check = false;
        money = shilings - g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold;
    }
    else 
    {
        check = true;
        money = g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Player %N took from the bank %i wcs Gold (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold, shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "The player %N put into the bank %i wcs Gold (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold, shilings);
    }

    g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold = shilings;
    
    return;
}

public Action SetBankLKRubles(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET lk_rubles = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, g_ClientInfo[iClient].gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 15);

    char log[300];
    if(shilings > g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles)
        Format(log, sizeof(log), "The player %N put rubles in the bank %i LK", iClient, shilings - g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles);
    else
        Format(log, sizeof(log), "Player %N took rubles from the bank %i LK", iClient, g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles - shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES(%i, %i, '%s', '%d');", 
                                    g_ClientInfo[iClient].gangid, g_ClientInfo[iClient].id, log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 16);
    
    bool check;
    int money;
    if(g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles < shilings)
    {
        check = false;
        money = shilings - g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles;
    }
    else 
    {
        check = true;
        money = g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "The player %N took from the bank %i LK rubles (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles, shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "The player %N put into the bank %i LK rubles (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles, shilings);
    }

    g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles = shilings;
    
    return;
}

public Action SetBankMyJBCredits(int iClient, int shilings)
{
    char sQuery[300];
    Format(sQuery, sizeof(sQuery), "UPDATE gang_group \
                                    SET myjb_credits = %i \
                                    WHERE id = %i AND server_id = %i;", 
                                    shilings, g_ClientInfo[iClient].gangid, g_iServerID);
    g_hDatabase.Query(SQLCallback_Void, sQuery, 17);

    char log[300];
    if(shilings > g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits)
        Format(log, sizeof(log), "Player %N deposited %i MyJB Credits in the bank", iClient, shilings - g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits);
    else
        Format(log, sizeof(log), "Player %N took %i MyJB Credits from the bank", iClient, g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits - shilings);
    
    Format(sQuery, sizeof(sQuery), "INSERT INTO gang_bank_log \
                                    (gang_id, player_id, log, date) \
                                    VALUES (%i, %i, '%s', '%d');", 
                                    g_ClientInfo[iClient].gangid, g_ClientInfo[iClient].id, log, GetTime());
    g_hDatabase.Query(SQLCallback_Void, sQuery, 18);
    
    bool check;
    int money;
    if(g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits < shilings)
    {
        check = false;
        money = shilings - g_GangInfo[GetGangLocalId(iClient)].currency.lk_rubles;
    }
    else 
    {
        check = true;
        money = g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits - shilings;
    }
    
    if(g_bLog)
    {
        if(check)
            LogToFile("addons/sourcemod/logs/gangs.txt", "Player %N took from the bank %i MyJB credits (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits, shilings);
        else
            LogToFile("addons/sourcemod/logs/gangs.txt", "Player %N put into the bank %i MyJB credits (was %i, became %i)", iClient, money, g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits, shilings);
    }

    g_GangInfo[GetGangLocalId(iClient)].currency.myjb_credits = shilings;
    
    return;
}

void RemoveFromGang(int iClient)
{
    char sQuery[300];
    if(g_ClientInfo[iClient].rank == 0)
    {
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
                                        WHERE gang_id = %i;", 
                                        g_ClientInfo[iClient].gangid);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 19);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_statistic \
                                        WHERE gang_id = %i;", 
                                        g_ClientInfo[iClient].gangid);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 20);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_bank_log \
                                        WHERE gang_id = %i;", 
                                        g_ClientInfo[iClient].gangid);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 21);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_perk \
                                        WHERE gang_id = %i;", 
                                        g_ClientInfo[iClient].gangid);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 22);
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_group \
                                        WHERE id = %i AND server_id = %i;", 
                                        g_ClientInfo[iClient].gangid, g_iServerID);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 23);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "GangDisbanded", szName, g_GangInfo[GetGangLocalId(iClient)].name);
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsValidClient(i) && g_ClientInfo[iClient].gangid == g_ClientInfo[i].gangid)
            {
                API_OnExitFromGang(i);
                ResetVariables(i, false);
            }
        }
    }
    else
    {
        Format(sQuery, sizeof(sQuery), "DELETE FROM gang_player \
                                        WHERE id = %i AND gang_id = %i;", 
                                        g_ClientInfo[iClient].id, g_ClientInfo[iClient].gangid);
        g_hDatabase.Query(SQLCallback_Void, sQuery, 24);
        
        char szName[MAX_NAME_LENGTH];
        GetClientName(iClient, szName, sizeof(szName));
        CPrintToChatAll("%t %t", "Prefix", "LeftGang", szName, g_GangInfo[GetGangLocalId(iClient)].name);
        API_OnExitFromGang(iClient);
        ResetVariables(iClient, false);
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

/*****************************************************************
***********************	     OTHER	    **************************
******************************************************************/
public int GetGangLocalId(int iClient)
{
    for(int i = 0; i < sizeof(g_GangInfo); i++)
        if(g_GangInfo[i].id == g_ClientInfo[iClient].gangid)
            return i;
    return -1;
}

public Action Timer_OpenGangMenu(Handle hTimer, int userid)
{
    int iClient = userid;

    if(IsValidClient(iClient))
        StartOpeningGangMenu(iClient);
}

void ResetVariables(int iClient, bool full = true)
{
    g_ClientInfo[iClient].rank = -1;
    g_ClientInfo[iClient].inviter_id = -1;
    g_ClientInfo[iClient].invite_date = -1;
    if(g_ClientInfo[iClient].gangid > 0){
        g_GangInfo[GetGangLocalId(iClient)].players_count = -1;
        g_GangInfo[GetGangLocalId(iClient)].level = 0;
        g_GangInfo[GetGangLocalId(iClient)].exp = 0;
        g_GangInfo[GetGangLocalId(iClient)].currency.rubles = 0;
        g_GangInfo[GetGangLocalId(iClient)].currency.credits = 0;
        g_GangInfo[GetGangLocalId(iClient)].currency.gold = 0;
        g_GangInfo[GetGangLocalId(iClient)].currency.wcs_gold = 0;
        g_GangInfo[GetGangLocalId(iClient)].extended_count = 0;
        g_GangInfo[GetGangLocalId(iClient)].end_date = -1;
    }
    ga_iTempInt2[iClient] = 0;
    g_ClientInfo[iClient].gangid = -1;
    g_ClientInfo[iClient].inviter_name = "";
    ga_bSetName[iClient] = false;
    ga_bRename[iClient] = false;
    g_ClientInfo[iClient].invation_sent = false;
    g_iBankCountType[iClient] = 0;
    if(full)
    {
        g_ClientInfo[iClient].steamid = "";
        g_ClientInfo[iClient].blockinvites = false;
        //ga_iProfileID[iClient] = -1;
        //ga_sProfileName[iClient] = "";
        //ga_iProfileSale[iClient] = 0;
        //ga_iDiscount[iClient] = 0;
        //ga_iPlayerShilings[iClient] = 0;
    }
}