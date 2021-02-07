#if defined _lk_core_included
  #endinput
#endif
#define _lk_core_included

public SharedPlugin __pl_lk_core = 
{
	name = "lk",
	file = "lk_core.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_lk_core_SetNTVOptional()
{
	MarkNativeAsOptional("LK_GetMainMenuTitle");
	MarkNativeAsOptional("LK_GetCurrency");
	MarkNativeAsOptional("LK_GetDatabase");
	MarkNativeAsOptional("LK_ShowMainMenu");
	MarkNativeAsOptional("LK_GameCMS_Mode");
	MarkNativeAsOptional("LK_GetVersion");
	MarkNativeAsOptional("LK_GetClientCash");
	MarkNativeAsOptional("LK_SetClientCash");
	MarkNativeAsOptional("LK_AddClientCash");
	MarkNativeAsOptional("LK_TakeClientCash");
	MarkNativeAsOptional("LK_ResetClientCash");
	MarkNativeAsOptional("LK_GetClientAllCash");
	MarkNativeAsOptional("LK_AddClientAllCash");
	MarkNativeAsOptional("LK_ResetClientAllCash");
	MarkNativeAsOptional("LK_RegisterItem");
	MarkNativeAsOptional("LK_UnRegisterItem");
	MarkNativeAsOptional("LK_LogMessage");
	MarkNativeAsOptional("LK_PrintToChat");
	MarkNativeAsOptional("LK_PrintToChatAll");
}
#endif

/*
 * Получает Title главного меню c балансом игрока, взятое из перевода
 *
 * @param iClient 			индекс игрока.
 * @param sTitle			Буфер, в который будет помещен результат.
 * @param iMaxLength		Размер буфера.
 *
 * @return
 * true - успешно.
 * false - игрок не прошел проверку(бот или не в игре)
 */
native bool LK_GetMainMenuTitle(int iClient, char[] sTitle, int iMaxLength);

/*
 * Получает Currency(валюта) переведенное под игрока, взятое из перевода
 *
 * @param iClient 			индекс игрока.
 * @param sTitle			Буфер, в который будет помещен результат.
 * @param iMaxLength		Размер буфера.
 *
 * @return
 * true - успешно.
 * false - игрок не прошел проверку(бот или не в игре)
 */
native bool LK_GetCurrency(int iClient, char[] sTitle, int iMaxLength);

/*
 * Возвращает Database(базу данных), для работы модулей, если это необходимо
 */
native Database LK_GetDatabase();

/*
 * Открыть главное меню
 */
native int LK_ShowMainMenu(int iClient);

/*
 * Возращает в каком режиме работает ядро
 *
 * @return
 *
 * false - Как отдельный плагин
 * true - Режим совместимости с GameCMS
 */
native bool LK_GameCMS_Mode();

/*
 * Получение версии ядра числом(int)
 *
 * @return value
 *
 */
native int LK_GetVersion();

/*
 * Получение количества денег на счету у игрока
 *
 * @param iClient 			индекс игрока.
 * @return value
 *
 */
native int LK_GetClientCash(int iClient);

/*
 * Устанавить значение денег на счету у игрока
 *
 * @param iClient 			индекс игрока.
 * @param amount 			кол-во денег
 *
 */

native int LK_SetClientCash(int iClient, int amount);

/*
 * Добавить значение денег на счет игрока
 *
 * @param iClient 			индекс игрока.
 * @param amount 			кол-во денег
 *
 */

native int LK_AddClientCash(int iClient, int amount);

/*
 * Отнять значение денег со счета игрока
 *
 * @param iClient 			индекс игрока.
 * @param amount 			кол-во денег
 */

native int LK_TakeClientCash(int iClient, int amount);

/*
 * Обнуление количества денег на счету у игрока
 *
 * @param iClient 			индекс игрока.
 * @noreturn
 */

native int LK_ResetClientCash(int iClient);

/*
 * Получение количество денег за все время
 * AllCash - Количество всех денег "задоначеных" игроков за все время(если не обнуляли)
 *
 * @param iClient 			индекс игрока.
 * @return value
 */

native int LK_GetClientAllCash(int iClient);

/*
 * Добавить количество денег за все время
 *
 * @param iClient 			индекс игрока.
 * @param amount 			кол-во денег
 */

native int LK_AddClientAllCash(int iClient, int amount);

/*
 * Обнуление счетчика у игрока (allcash)
 *
 * @param iClient 			индекс игрока.
 * @return value
 */

native int LK_ResetClientAllCash(int iClient);

/**
 *
 * Создать функцию (опцию в !lk меню)
 *
 * sItemName - уникальное имя, например "top10", этот ключ будет переводится в lk.phrases.txt
 * RegisterCallback - Callback фукции, когда игрок нажал в главном меню на ваш sItemName
 *
**/
native void LK_RegisterItem(const char[] sItemName, RegisterCallback callback);

/**
 *
 * RegisterCallback
 *
 * @param iClient 			индекс игрока.
 * @param iItemID 			порядковый номер в главном меню (уже прошел сортировку)
 * @param sItemName 		уникальное имя, например "top10", этот ключ будет переводится в lk.phrases.txt
 *
**/
typedef RegisterCallback = function void (int iClient, int iItemID, const char[] sItemName);

/**
 *
 * Удалить функцию из !lk меню
 *
**/
native int LK_UnRegisterItem(const char[] sItemName);

/**
 *
 *	Записывает сообщение в лог.
 *	-
 * @param sMessage			Cообщение.
 * @param ...				Параметры.
 *
*/
native int LK_LogMessage(const char[] sMessage, any:...);

/**
 *
 *	Печатает в чат всем игрокам(проходит проверку на то какая игра, так как у ядра несколько библеотек на цвета)
 *  p.s. sMessage уже включает в себя Chat_Prefix из файла перевода, lk.prhases.txt
 *	-
 * @param sMessage			Cообщение.
 * @param ...				Параметры.
 *
*/
native int LK_PrintToChat(int iClient, const char[] sMessage, any:...);

/**
 *
 *	Печатает в чат всем игрокам(проходит проверку на то какая игра, так как у ядра несколько библеотек на цвета)
 *  p.s. sMessage уже включает в себя Chat_Prefix из файла перевода, lk.prhases.txt
 *	-
 * @param sMessage			Cообщение.
 * @param ...				Параметры.
 *
**/
native int LK_PrintToChatAll(const char[] sMessage, any:...);

/**
 *
 * Игрок успешно использовал ключ
 *	-
 * @param iClient 			индекс игрока.
 * @param szAuth			SteamID.
 * @param sKey				ключ.
 *
**/
forward void LK_OnKeyWasUsed(int iClient, const char[] szAuth, const char[] sKey);

/**
 *
 *	Вызывается когда ядро LK загрузилось.
 *
*/
forward void LK_OnLoaded();