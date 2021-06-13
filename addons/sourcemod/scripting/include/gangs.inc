#if defined gangs_include
  #endinput
#endif
#define gangs_include

#define GANGS_VERSION "1.4.0 [PUBLIC]"

stock bool IsValidClient(int iClient, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= iClient <= MaxClients) || !IsClientInGame(iClient) || (IsFakeClient(iClient) && !bAllowBots) || IsClientSourceTV(iClient) || IsClientReplay(iClient) || (!bAllowDead && !IsPlayerAlive(iClient)))
		return false;
	return true;
}

/**
 *
 * Возвращает Database(базу данных).
 *
 */
native Database Gangs_GetDatabase();

/**
 *
 * Возвращает Database Driver.
 * 1 - MySQL
 * 0 - SQLite
 *
 */
native Database Gangs_GetDatabaseDriver();

/**
 *
 * Возвращает ServerID.
 *
 */
native int Gangs_GetServerID();

/**
 *
 * Получение уровня банды
 *
 * @param	iScore			Кол-во очков
 * @return  value
 *
 */
native int Gangs_GetGangLvl(int iScore);

/**
 *
 * Получение начального размера банды
 *
 * @return  value
 *
 */
native int Gangs_GetGangSize();

/**
 *
 * Получение кол-ва необходимого опыта для след. уровня
 *
 * @param	iScore			Кол-во очков
 * @return  value
 *
 */
native int Gangs_GetGangReqScore(int iScore);

/**
 *
 * Получает заново все данные игрока из базы данных
 *	-
 * @param iClient 			Индекс игрока
 *
 */
native void Gangs_ReloadClient(int iClient);

/**
 *
 * Returns if a iClient is a member of a gang
 *
 * @param	iClient			Индекс игрока
 * @return  bool
 *
 */
native bool Gangs_ClientHasGang(int iClient);

/**
 *
 * Получить ид банды, в которой состоит игрок
 *
 * @param	iClient			Индекс игрока
 * @return  int
 *
 */
native int Gangs_GetClientGangId(int iClient);

/**
 *
 * Получить название банды, в которой состоит игрок
 *
 * @param	iClient			Индекс игрока
 * @param	sBuffer			Куда записать название
 * @param	MaxLength		Максимальная длина sBuffer
 *
 */
native void Gangs_GetClientGangName(int iClient, char[] sBuffer, int MaxLength);

/**
 *
 * Получение ранга игрока
 *
 * @param	iClient			Индекс игрока
 * @return  GangRank
 *
 */
native int Gangs_GetClientGangRank(int iClient);

/**
 *
 * Получение очков банды игрока
 *	-
 * @param iClient 			Индекс игрока
 * @return value
 *
 */
native int Gangs_GetClientGangScore(int iClient);

/**
 *
 * Установка очков для банды игрока
 *	-
 * @param iClient 			Индекс игрока
 * @param iValue 			Кол-во очков
 *
 */
native int Gangs_SetClientGangScore(int iClient, int iValue);

/*
 * Показывает главное меню клиенту
 */
native int Gangs_ShowMainMenu(int iClient);

/*
 * Показывает меню улучшений клиенту
 */
native int Gangs_ShowPerksMenu(int iClient);

/*
 * Показывает меню игр клиенту
 */
native int Gangs_ShowGamesMenu(int iClient);

/**
 *
 * Добавление перка в меню привилегий
 *
 * sItemName - уникальное имя, например "damage", этот ключ будет переводится в hl_gangs.phrases.txt
 * RegisterPerkMenuCallback - Callback фукции, когда игрок нажал в главном меню на ваш sItemName
 * AddInDB - регестрировать ли перк в базе данных (false - нет\true - да)
 *
**/
native void Gangs_AddToPerkMenu(const char[] sItemName, RegisterPerkMenuCallback callback, bool AddInDB);

typedef RegisterPerkMenuCallback = function void (int iClient, int iItemID, const char[] sItemName);

/**
 *
 * Удаление перка из меню привилегий
 *
**/
native void Gangs_DeleteFromPerkMenu(const char[] sItemName);

/**
 *
 * Добавление игры в меню
 *
 * sItemName - уникальное имя, например "damage", этот ключ будет переводится в hl_gangs.phrases.txt
 * Gangs_AddToGamesMenu - Callback фукции, когда игрок нажал в главном меню на ваш sItemName
 *
**/
native void Gangs_AddToGamesMenu(const char[] sItemName, RegisterGamesMenuCallback callback);

typedef RegisterGamesMenuCallback = function void (int iClient, int iItemID, const char[] sItemName);

/**
 *
 * Удаление игры из меню
 *
**/
native void Gangs_DeleteFromGamesMenu(const char[] sItemName);

/**
 *
 * Добавление статистики в меню
 *
 * sItemName - уникальное имя, например "damage", этот ключ будет переводится в hl_gangs.phrases.txt
 * Gangs_AddToStatsMenu - Callback фукции, когда игрок нажал в главном меню на ваш sItemName
 *
**/
native void Gangs_AddToStatsMenu(const char[] sItemName, RegisterStatsMenuCallback callback);

typedef RegisterStatsMenuCallback = function void (int iClient, int iItemID, const char[] sItemName);

/**
 *
 * Удаление статистики из меню
 *
**/
native void Gangs_DeleteFromStatsMenu(const char[] sItemName);

/**
 *
 * Получение баланса определенного значения у игрока 
 *
 * rubles - рубли
 * shop - Shop кредиты
 * shopgold - Shop Gold
 * wcsgold - WCS Gold
 * lkrubles - LK рубли
 *
 * @param	iClient			Индекс игрока
 *
 */
native int Gangs_GetClientCash(int iClient, char[] sBuffer);

/**
 *
 * Повышение баланса определенного значения у игрока 
 *
 * rubles - рубли
 * shop - Shop кредиты
 * shopgold - Shop Gold
 * wcsgold - WCS Gold
 * lkrubles - LK рубли
 *
 * @param	iClient			Индекс игрока
 *
 */
native int Gangs_GiveClientCash(int iClient, char[] sBuffer, int NewCash);

/**
 *
 * Понижение баланса определенного значения у игрока
 *
 * rubles - рубли
 * shop - Shop кредиты
 * shopgold - Shop Gold
 * wcsgold - WCS Gold
 * lkrubles - LK рубли
 *
 * @param	iClient			Индекс игрока
 *
 */
native int Gangs_TakeClientCash(int iClient, char[] sBuffer, int NewCash);

/**
 *
 * Получение баланса банка определенного значения у игрока 
 *
 * rubles - рубли
 * shop - Shop кредиты
 * shopgold - Shop Gold
 * wcsgold - WCS Gold
 * lkrubles - LK рубли
 *
 * @param	iClient			Индекс игрока
 *
 */
native int Gangs_GetBankClientCash(int iClient, char[] sBuffer);

/**
 *
 * Повышение баланса банка определенного значения у игрока 
 *
 * rubles - рубли
 * shop - Shop кредиты
 * shopgold - Shop Gold
 * wcsgold - WCS Gold
 * lkrubles - LK рубли
 *
 * @param	iClient			Индекс игрока
 *
 */
native int Gangs_GiveBankClientCash(int iClient, char[] sBuffer, int NewCash);

/**
 *
 * Полный роспуск банды
 *
 * @param	sGang			Название банды
 *
 */
native int Gangs_DissolveGang(int iGangId);

/**
 *
 * Кик участника банды
 *
 * @param	iClient			Индекс игрока
 *
 */
native int Gangs_KickMember(int iClient);

/**
 *
 * Понижение баланса банка определенного значения у игрока
 *
 * rubles - рубли
 * shop - Shop кредиты
 * shopgold - Shop Gold
 * wcsgold - WCS Gold
 * lkrubles - LK рубли
 *
 * @param	iClient			Индекс игрока
 *
 */
native bool Gangs_TakeBankClientCash(int iClient, char[] sBuffer, int NewCash);

/**
 *
 * Игрок вступил в банду
 *	-
 * @param iClient 			Индекс игрока
 * @param sGang 			Название банды
 * @param Inviter 			Индекс игрока, который пригласил
 *
 */
forward void Gangs_OnGoToGang(int iClient, char[] sGang, int Inviter);

/**
 *
 * Игрок вышел из банды
 *	-
 * @param iClient 			Индекс игрока
 *
 */
forward void Gangs_OnExitFromGang(int iClient);

/**
 *
 *	Вызывается когда ядро Gangs загрузилось
 *
*/
forward void Gangs_OnLoaded();

/**
 *
 *	Вызывается когда пользователь Gangs загрузил все данные из бд.
 *
*/
forward void Gangs_OnPlayerLoaded(int iClient);

public SharedPlugin __pl_gangs  =
{
	name = "gangs",
	file = "gangs.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_gangs_SetNTVOptional()
{
	MarkNativeAsOptional("Gangs_GetDatabase");
	MarkNativeAsOptional("Gangs_GetServerID");
	MarkNativeAsOptional("Gangs_GetGangLvl");
	MarkNativeAsOptional("Gangs_GetGangSize");
	MarkNativeAsOptional("Gangs_GetGangReqScore");
	MarkNativeAsOptional("Gangs_ReloadClient");
	MarkNativeAsOptional("Gangs_ClientHasGang");
	MarkNativeAsOptional("Gangs_GetClientGangName");
	MarkNativeAsOptional("Gangs_GetClientGangId");
	MarkNativeAsOptional("Gangs_GetClientGangRank");
	MarkNativeAsOptional("Gangs_GetClientGangScore");
	MarkNativeAsOptional("Gangs_SetClientGangScore");
	MarkNativeAsOptional("Gangs_ShowMainMenu");
	MarkNativeAsOptional("Gangs_ShowPerksMenu");
	MarkNativeAsOptional("Gangs_ShowGamesMenu");
	MarkNativeAsOptional("Gangs_ShowStatsMenu");
	MarkNativeAsOptional("Gangs_AddToPerkMenu");
	MarkNativeAsOptional("Gangs_DeleteFromPerkMenu");
	MarkNativeAsOptional("Gangs_AddToGamesMenu");
	MarkNativeAsOptional("Gangs_DeleteFromGamesMenu");
	MarkNativeAsOptional("Gangs_AddToStatsMenu");
	MarkNativeAsOptional("Gangs_DeleteFromStatsMenu");
	MarkNativeAsOptional("Gangs_GetClientCash");
	MarkNativeAsOptional("Gangs_GiveClientCash");
	MarkNativeAsOptional("Gangs_TakeClientCash");
}
#endif