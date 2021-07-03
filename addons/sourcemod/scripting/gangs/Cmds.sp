void RegAllCmds()
{
	RegConsoleCmd("gangs_config_reload", Command_Gang_Config_Reload, "Reload config file!");
	RegConsoleCmd("sm_accept", Command_Accept, "Accept an invitation!");
}

public Action Command_Accept(int iClient, int args)
{
	if (!g_bPluginEnabled)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "DisabledPlugin");
		return Plugin_Handled;
	}
	if (g_bInviteStyle)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "DisabledAcceptCommand");
		return Plugin_Handled;
	}

	if (!IsValidClient(iClient))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "PlayerNotInGame");
		return Plugin_Handled;
	}
	if (g_bTerroristOnly && GetClientTeam(iClient) != 2)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "WrongTeam");
		return Plugin_Handled;
	}
	if (g_ClientInfo[iClient].gangid != -1)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "AlreadyInGang");
		return Plugin_Handled;
	}
	if (g_ClientInfo[iClient].inviter_id == -1)
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "NotInvited");
		return Plugin_Handled;
	}
	
	int sender = g_ClientInfo[iClient].inviter_id;
	if (g_GangInfo[GetGangLocalId(sender)].players_count >= g_iSize + Gangs_Size_GetCurrectLvl(sender))
	{
		CReplyToCommand(iClient, "%t %t", "Prefix", "GangIsFull");
		return Plugin_Handled;
	}

	g_ClientInfo[iClient].gangid = g_ClientInfo[sender].gangid
	g_ClientInfo[iClient].invite_date = GetTime();
	ga_bSetName[iClient] = false;

	char szName[MAX_NAME_LENGTH];
	GetClientName(sender, szName, sizeof(szName));

	g_GangInfo[GetGangLocalId(iClient)].players_count++;
	
	g_ClientInfo[sender].invation_sent = false;

	g_ClientInfo[iClient].inviter_name = szName;
	g_ClientInfo[iClient].rank = GetLastConfigRank();
	UpdateSQL(iClient);
	GetClientName(iClient, szName, sizeof(szName));
	CPrintToChatAll("%t %t", "Prefix", "GangJoined", szName, g_GangInfo[GetGangLocalId(iClient)].name);
	return Plugin_Handled;
}

public Action Command_Gang(int iClient, int args)
{
	if (!IsValidClient(iClient))
	{
		ReplyToCommand(iClient, "[SM] %t", "PlayerNotInGame");
		return Plugin_Handled;
	}
	if (g_bTerroristOnly && GetClientTeam(iClient) != 2)
	{
		ReplyToCommand(iClient, "[SM] %t", "WrongTeam");
		return Plugin_Handled;
	}
	StartOpeningGangMenu(iClient);
	return Plugin_Handled;
}

public Action Command_Gang_Config_Reload(int iClient, int args)
{
    OnMapStart();
    return Plugin_Handled;
}