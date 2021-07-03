#define SZF(%0) 			%0, sizeof(%0)
#define SZFA(%0,%1)         %0[%1], sizeof(%0[])

ConVar g_cvCustomCommands;

bool g_bPluginEnabled;
bool g_bInviteStyle;
bool g_bTerroristOnly;
char g_sDbStatisticName[64];


/* Database Globals */
Database g_hDatabase;

bool g_bShopLoaded = false;
bool g_bStoreLoaded = false;
//bool g_bWCSLoaded = false;
bool g_bLKLoaded = false;
bool g_bLShopGoldExist = false;
//bool g_bLKSystemLoaded = false;
bool g_bGameCMSExist = false;
bool g_bModuleSizeExist = false;
bool g_bMyJBShopExist = false;
bool g_bStatisticRating = false;

//Globals
ArrayList g_hPerkName, g_hPerkID, g_hPerkArray, g_hGameName, g_hGameID, g_hGamesArray, g_hStatName, g_hStatID, g_hStatsArray;
int g_iPerksCount, g_iGamesCount, g_iStatsCount;
Handle hGangs_OnLoaded, hGangs_OnPlayerLoaded, hSortTimer, hSortTimer1, hSortTimer2;

char g_sFile[256];

int g_bLog;
int g_bDebug;

int g_iServerID = -1;

KeyValues ConfigSettings;

int g_bMenuValue;

int g_bMenuInfo;

int g_bCreateGangSellMode;
int g_iCreateGangPrice;
int g_iCreateGangDays;

int g_bRenameBank;
int g_iRenamePrice;
int g_bRenamePriceSellMode;

int g_bExtendBank;
int g_iExtendPriceSellMode;
int g_bExtendCostFormula;
int g_iExtendCostPrice;
int g_iExtendModifier;

int g_bEnableBank,
     g_bBankRubles,
     g_bBankShop,
     g_bBankShopGold,
     g_bBankWcsGold,
     g_bBankLkRubles,
     g_bBankMyJBCredits;

int g_iScoreExpInc;

int g_iSize;

/* Forwards */
Handle g_hOnGangGoToGang;
Handle g_hOnGangExitFromGang;

/* Temps player */
int ga_iTempInt2[MAXPLAYERS + 1] = {0, ...};
bool ga_bSetName[MAXPLAYERS + 1] = {false, ...};
bool ga_bRename[MAXPLAYERS + 1] = {false, ...};
int g_iBankCountType[MAXPLAYERS + 1] = 0;

/* Gang Globals */
enum struct GangCurrencies
{
     int rubles;
     int credits;
     int gold;
     int wcs_gold;
     int lk_rubles;
     int myjb_credits;
}
enum struct ClientGangInfo
{
    int id;
    char name[128];
    int players_count;
    int level;
    int exp;
    int create_date;
    int end_date;
    int extended_count;
    GangCurrencies currency;
}
ClientGangInfo g_GangInfo[256];

/* Player Globals */
enum struct ClientInfo
{
    int id;
    int gangid;
    char steamid[32];
    int rank;
    char inviter_name[128];
    int inviter_id;
    int invite_date;
    bool blockinvites;
    bool invation_sent;
}
ClientInfo g_ClientInfo[MAXPLAYERS+1];