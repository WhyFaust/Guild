public void CreateCvars()
{
    AutoExecConfig_SetFile("gangs");
    ConVar CVar;
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_enabled", "1", "Do you want to enable the plugin? (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(UpdatePluginEnabled);
    g_bPluginEnabled = CVar.BoolValue;
    
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_invite_style", "1", "Style for accepting an invitation to the gang. \n(1 = Via Menu, 0 = Via !accept)", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(UpdateInviteStyle);
    g_bInviteStyle = CVar.BoolValue;
    
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_terrorist_only", "0", "All functions are only available to T team? \n1 - Yes, only for T, 0 - For all teams)")).AddChangeHook(UpdateTerroristOnly);
    g_bTerroristOnly = CVar.BoolValue;
    
    (CVar = AutoExecConfig_CreateConVar("sm_gangs_db_statistic_name", "total", "Name of the Kill column in the statistics base")).AddChangeHook(UpdateDbStatisticName);
    CVar.GetString(g_sDbStatisticName, sizeof(g_sDbStatisticName));
    
    g_cvCustomCommands = AutoExecConfig_CreateConVar("sm_gangs_custom_commands", "g, gang, gangs, guild, guilds, b, banda", " Gang Menu Opening Commands \n Separate with ','");
    
    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
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

public void OnConfigsExecuted()
{
    if(g_bPluginEnabled)
    {
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
    }
}