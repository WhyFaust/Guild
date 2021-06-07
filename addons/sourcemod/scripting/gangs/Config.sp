public void LoadConfig()
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
        g_iCreateGangDays = ConfigSettings.GetNum("create_days");
        
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

    if(g_bDebug)
        LogToFile("addons/sourcemod/logs/gangs_debug.txt", "Config Loaded");
}

void LoadConfigSettings(char kvName[256],char file[256])
{
    delete ConfigSettings;
    ConfigSettings = new KeyValues(kvName);
    char SzBuffer[256];
    BuildPath(Path_SM, SzBuffer,256, file);
    ConfigSettings.ImportFromFile(SzBuffer);
}