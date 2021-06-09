#if defined _lk_core_included
  #endinput
#endif
#define _lk_core_included

#define SIZE_ITEM 32
#define SIZE_ITEMNAME 64
#define SIZE_INFOITEM 256

enum LK_CurrenyType
{
	LK_Cash = 0,			//Баланс игрока
	LK_AllCash				//Сумма общего доната
};

enum LK_ChangeType
{
	LK_Add = 0,				//Добавить
	LK_Take,				//Отнять
	LK_Set					//Установить
};

enum LK_ItemInfoType
{
	LK_Item = 0,				//Ключ товара, пример: "vip1d"
	LK_ItemName,				//Имя товара, как в меню
	LK_InfoItem					//Описание товара
};

/*
 * Управление балансом пользователя
 *
 * @param iClient 			индекс пользователя.
 * @param CurrenyType 		-
 * @param ChangeType 		-
 * @param iValue 			Значение
 *
 * @return
 * true 					успешно.
 * false 					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_ChangeBalance(int iClient, LK_CurrenyType CurrenyType, LK_ChangeType ChangeType, int iValue);

/*
 * Обнуление баланса пользователя
 *
 * @param iClient 			индекс пользователя.
 * @param CurrenyType 		-
 *
 * @return
 * true 					успешно.
 * false 					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_ResetBalance(int iClient, LK_CurrenyType CurrenyType);

/*
 * Получение баланса пользователя
 *
 * @param iClient 			индекс пользователя.
 * @param CurrenyType 		-
 *
 * @return value			значение
 *							-1, если произошла ошибка
 */
native int LK_GetBalance(int iClient, LK_CurrenyType CurrenyType);

/*
 * Получает Title главного меню c балансом пользователя, взятое из перевода
 *
 * @param iClient 			индекс пользователя.
 * @param sTitle			Буфер, в который будет помещен результат.
 * @param iMaxLength		Размер буфера.
 *
 * @return
 * true 					успешно.
 * false 					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_GetMainMenuTitle(int iClient, char[] sTitle, int iMaxLength);

/*
 * Получает Currency(валюта) переведенное под пользователя, взятое из перевода
 *
 * @param iClient 			индекс пользователя.
 * @param sTitle			Буфер, в который будет помещен результат.
 * @param iMaxLength		Размер буфера.
 *
 * @return
 * true 					успешно.
 * false 					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_GetCurrency(int iClient, char[] sTitle, int iMaxLength);

/*
 * Возвращает Database(базу данных), для работы модулей, если это необходимо
 *
 * @return					Подключение к базе данных (копия). 0 если нет подключения.
 */
native Database LK_GetDatabase();

/*
 * Открыть главное меню
 *
 * @return
 * true 					успешно.
 * false  					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_ShowMainMenu(int iClient);

/*
 * Получение версии ядра числом(int)
 *
 * @return value
 */
native int LK_GetVersion();

/*
 * Получает цену товара, с учетом скидки
 *
 * @param iItemID 			id зарегистрированого товара
 * @return value			возвращает цену товара с учетом скидки
 *		   -1				если произошла ошибка
 */
native int LK_GetItemPrice(int iItemID);

/*
 * Получить информацию по товару, по его iItemID
 *
 * @param iItemID 			id зарегистрированого товара
 * @param ItemInfoType 		-
 * @param sBuffer 			Буфер, в который будет помещен результат.
 * @param iMaxLength 		Размер буфера.
 *
 * @return
 * true 					успешно
 * false 					ошибка
 */
native bool LK_GetItemInfo(int iItemID, LK_ItemInfoType ItemInfoType, char[] sBuffer, int iMaxLength);

/**
 *
 * Создать торвар (опцию в !lk меню)
 *
 * @param sItem  			уникальное имя, например "vip30d" (только латинские символы)
 * @param sItemName  		Название товара, которое будет отображаться в списке товаров
 * @param sInfoItem 		Описание товара, которое будет отображаться при покупке товара
 * @param iPrice 			Цена товара
 * 
 * @return
 * iItemID					id зарегистрированного товара
**/
native int LK_RegisterItem(const char[] sItem, const char[] sItemName, const char[] sInfoItem, int iPrice);

/**
 *
 * Удалить товар из списка товаров
 * @param sItem - уникальное имя, например "vip30d" (только латинские символы)
 *
**/
native int LK_UnRegisterItem(const char[] sItem);

/**
 *
 *	Записывает сообщение в лог.
 *	-
 * @param sMessage			Cообщение.
 * @param ...				Параметры.
 *
*/
native int LK_LogMessage(const char[] sMessage, any ...);

/**
 *
 *	Записывает сообщение в лог ошибок.
 *	-
 * @param sMessage			Cообщение.
 * @param ...				Параметры.
 *
*/
native int LK_LogError(const char[] sMessage, any ...);

/**
 *
 *	Печатает в чат всем пользователям(проходит проверку на то какая игра, так как у ядра несколько библеотек на цвета),
 *  если у пользователя в настройках выключены уведомления, то в чат НЕ напечатает.
 *  p.s. sMessage уже включает в себя Chat_Prefix из файла перевода, lk.prhases.txt
 *	-
 * @param sMessage			Cообщение.
 * @param ...				Параметры.
 *
*/
native int LK_PrintToChat(int iClient, const char[] sMessage, any ...);

/**
 *
 *	Печатает в чат всем пользователям(проходит проверку на то какая игра, так как у ядра несколько библеотек на цвета)
 *  p.s. sMessage уже включает в себя Chat_Prefix из файла перевода, lk.prhases.txt
 *	-
 * @param sMessage			Cообщение.
 * @param ...				Параметры.
 *
**/
native int LK_PrintToChatAll(const char[] sMessage, any ...);

/**
 *
 * Загружено ли ядро
 *
 * @return
 * true 					загружено
 * false					не загружено
**/
native bool LK_IsLoaded();

/**
 * Перезагрузить конфиг ядра
**/
native void LK_ReloadConfigs();

/*
 * Обнуление истории покупок у пользователя
 *
 * @param iClient 			индекс пользователя.
 *
 * @return
 * true						успешно.
 * false					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_ResetHistory(int iClient);

/*
 * Получает ник пользователя, для коректной работы с базой (нужен для кривых ников, баг см 1.9)
 *
 * @param iClient 			индекс пользователя.
 * @param sName				Буфер, в который будет помещен результат.
 * @param iMaxLength		Размер буфера.
 *
 * @return
 * true						успешно.
 * false					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_GetNameUser(int iClient, char[] sName, int iMaxLength);

/*
 * Отправляет пользователя на проверку валидности (не бот, в игре)
 *
 * @param iClient 			индекс пользователя.
 *
 * @return
 * true						успешно.
 * false					игрок не прошел проверку(бот или не в игре)
 */
native bool LK_IsValidPlayer(int iClient);

/**
 *
 * Добавить в историю покупок клиента, кастомный товар
 *
 * @param iClient			индекс пользователя.
 * @param sItemName			Название, которое будет отображаться в списке истории(как товар)
 * @param iPrice			Цена, которая будет отображаться в списке истории(как цена товара)
 * 
**/
native void LK_AddHistory(int iClient, const char[] sItemName, int iPrice);

/**
 *
 * Вызывает Forward `LK_OnItemBuyPost`
 *
 * @param iClient 			индекс пользователя.
 * @param iItemID 			id зарегистрированного товара
 * @param sItemName 		имя товара
 * @param iPrice 			цена, которую заплатил пользователь
 * 
 * @return
 * true						Forward успешно был создан
 * false					Forward НЕ был создан
**/
native bool LK_FakeOnItemBuyPost(int iClient, int iItemID, const char[] sItemName, int iPrice);

/**
 *
 * Пользователь приобретает товар(pre)
 *	-
 * @param iClient 			индекс пользователя.
 * @param iItemID 			id зарегистрированного товара
 *
 *	-
 * @return					Plugin_Stop - не спишит деньги за покупку(отменит), закроет меню;
 *							Plugin_Handled  - не спишит деньги за покупку(отменит), откроет меню товаров;
 * 							Plugin_Continue - разрешит без изменений.
**/
forward Action LK_OnItemBuy(int iClient, int iItemID);

/**
 *
 * Пользователь успешно приобрел товар
 *	-
 * @param iClient 			индекс пользователя.
 * @param iItemID 			id зарегистрированного товара
 * @param sItemName 		имя товара
 * @param iPrice 			цена, которую заплатил пользователь
**/
forward void LK_OnItemBuyPost(int iClient, int iItemID, const char[] sItemName, int iPrice);

/**
 *	Вызывается когда ядро LK загрузилось.
*/
forward void LK_OnLoaded();

/**
 *	Вызывается когда пользователь открывает меню
*/
forward void LK_OnPreShowMainMenu(int iClient);

/**
 *	Вызывается когда пользователь прошел загрузку ЛК из базы
*/
forward void LK_OnClientLoaded(int iClient);

/**
 *	Событие подключение к бд.
 *
 *  @param db				бд.
*/
forward void LK_OnConnectDatabase(Database db);

public SharedPlugin __pl_lk_core = 
{
	name = "lk",
	file = "LK_Core.smx",
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
	MarkNativeAsOptional("LK_GetVersion");
	MarkNativeAsOptional("LK_RegisterItem");
	MarkNativeAsOptional("LK_UnRegisterItem");
	MarkNativeAsOptional("LK_LogMessage");
	MarkNativeAsOptional("LK_LogError");
	MarkNativeAsOptional("LK_PrintToChat");
	MarkNativeAsOptional("LK_PrintToChatAll");
	MarkNativeAsOptional("LK_ReloadConfigs");
	MarkNativeAsOptional("LK_ResetHistory");
	MarkNativeAsOptional("LK_GetNameUser");
	MarkNativeAsOptional("LK_IsValidPlayer");
	MarkNativeAsOptional("LK_AddHistory");
	MarkNativeAsOptional("LK_FakeOnItemBuyPost");
	MarkNativeAsOptional("LK_GetItemPrice");
	MarkNativeAsOptional("LK_ChangeBalance");
	MarkNativeAsOptional("LK_ResetBalance");
	MarkNativeAsOptional("LK_GetBalance");
	MarkNativeAsOptional("LK_IsLoaded");
	MarkNativeAsOptional("LK_GetItemInfo");
}
#endif