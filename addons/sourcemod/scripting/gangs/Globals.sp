#define GLOBAL_INFO			g_iClientInfo[0]

#define SZF(%0) 			%0, sizeof(%0)
#define SZFA(%0,%1)         %0[%1], sizeof(%0[])

#define SET_BIT(%0,%1) 		%0 |= %1
#define UNSET_BIT(%0,%1) 	%0 &= ~%1

#define IS_STARTED					(1<<0)
#define IS_MySQL					(1<<1)
#define IS_LOADING					(1<<2)

int			g_iClientInfo[MAXPLAYERS+1];

ConVar g_cvCustomCommands;

bool g_bPluginEnabled;
bool g_bInviteStyle;
bool g_bTerroristOnly;
char g_sDbStatisticName[64];

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

/* Gang Globals */
int ga_iRank[MAXPLAYERS + 1] = {-1, ...};
int ga_iGangSize[MAXPLAYERS + 1] = {-1, ...};
int ga_iInvitation[MAXPLAYERS + 1] = {-1, ...};
int ga_iDateJoined[MAXPLAYERS + 1] = {-1, ...};
int ga_iSize[MAXPLAYERS + 1] = {0, ...};
int ga_iBankRubles[MAXPLAYERS + 1] = {0, ...};
int ga_iBankCredits[MAXPLAYERS + 1] = {0, ...};
int ga_iBankGold[MAXPLAYERS + 1] = {0, ...};
int ga_iBankWCSGold[MAXPLAYERS + 1] = {0, ...};
int ga_iBankLKRubles[MAXPLAYERS + 1] = {0, ...};
int ga_iBankMyJBCredits[MAXPLAYERS + 1] = {0, ...};
int ga_iScore[MAXPLAYERS + 1] = 0;
int ga_iTempInt1[MAXPLAYERS + 1] = {0, ...};
int ga_iTempInt2[MAXPLAYERS + 1] = {0, ...};
int ga_iExtendCount[MAXPLAYERS + 1] = {0, ...};
int g_iGangAmmount = 0;

int ga_iPlayerId[MAXPLAYERS + 1];
int ga_iGangId[MAXPLAYERS + 1];
char ga_sGangName[MAXPLAYERS + 1][128];
char ga_sInvitedBy[MAXPLAYERS + 1][128];

bool ga_bSetName[MAXPLAYERS + 1] = {false, ...};
bool ga_bHasGang[MAXPLAYERS + 1] = {false, ...};
bool ga_bRename[MAXPLAYERS + 1] = {false, ...};
bool ga_bBlockInvites[MAXPLAYERS + 1] = {false, ...};
bool ga_bInvitationSent[MAXPLAYERS + 1];

int g_iBankCountType[MAXPLAYERS + 1] = 0;

/* Player Globals */
char ga_sSteamID[MAXPLAYERS + 1][32];
bool ga_bLoaded[MAXPLAYERS + 1] = {false, ...};
int ga_iEndTime[MAXPLAYERS + 1] = {-1, ...};

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