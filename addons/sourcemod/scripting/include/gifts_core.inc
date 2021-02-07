#if defined _gifts_core_included
 #endinput
#endif
#define _gifts_core_included

/**********************************************************************
 * Вызывается когда загружается подарок
 * *
 * @param		iGiftIndex		Индекс подарка
 * @param		hKeyValues		KeyValues структура ключа подарка
 * *
 * @noreturn
 **********************************************************************/
forward int Gifts_OnLoadGift(int iGiftIndex, Handle hKeyValues);

/**********************************************************************
 * Вызывается когда создается подарок
 * *
 * @param		iClient			Индекс игрока
 * @param		iEntity			Индекс объекта подарка
 * @param		hKeyValues		KeyValues структура ключа подарка
 * *
 * @return
 * 			Plugin_Continue		Разрешит создание
 * 			Plugin_Handled, Plugin_Stop, Plugin_Changed		Запретит создание подарка
 **********************************************************************/
forward Action Gifts_OnCreateGift_Pre(int iClient, Handle hKeyValues);

/**********************************************************************
 * Вызывается когда создается подарок
 * *
 * @param		iClient			Индекс игрока
 * @param		iEntity			Индекс объекта подарка
 * @param		hKeyValues		KeyValues структура ключа подарка
 * *
 * @noreturn
 **********************************************************************/
forward int Gifts_OnCreateGift_Post(int iClient, int iEntity, Handle hKeyValues);

/**********************************************************************
 * Вызывается когда игрок пытается взять подарок
 * *
 * @param		iClient			Индекс игрока
 * @param		hKeyValues		KeyValues структура ключа подарка
 * *
 * @return
 * 			Plugin_Continue		Разрешит поднятие и удалит подарок
 * 			Plugin_Handled		Запретит игроку поднять подарок
 * 			Plugin_Stop			Запретит игроку поднять подарок и удалит его
 **********************************************************************/
forward Action Gifts_OnPickUpGift_Pre(int iClient, Handle hKeyValues);

/**********************************************************************
 * Вызывается когда игрок поднимает подарок
 * *
 * @param		iClient			Индекс игрока
 * @param		hKeyValues		KeyValues структура ключа подарка
 * *
 * @noreturn
 **********************************************************************/
forward int Gifts_OnPickUpGift_Post(int iClient, Handle hKeyValues);

/**********************************************************************
 * Получает кол-во подарков в конфиге
 * *
 * @noparams
 * *
 * @return Кол-во подарков в конфиге
 **********************************************************************/
native int Gifts_GetGiftsCount();

/**********************************************************************
 * Получает конфиг подарков (KeyValues)
 * *
 * @noparams
 * *
 * @return Конфиг подарков (KeyValues)
 **********************************************************************/
native Handle Gifts_GetConfig();

/**********************************************************************
 * Создает подарок
 * *
 * @param		iClient			Индекс игрока
 * @param		fPos			Координаты
 * @param		index			Индекс подарка (0 если хотите использовать свои настройки, -1 - рандомный)
 * @param		hKeyValues		KeyValues структура ключа подарка
 * *
 * @return Индекс ентити созданного подарка. (В случае ошибки = -1)
 **********************************************************************/
native int Gifts_CreateGift(int iClient = 0, float fPos[3], int index = -1, Handle hKeyValues = INVALID_HANDLE);

public SharedPlugin __pl_gifts_core= 
{
	name = "gifts_core",
	file = "Gifts_Core.sp.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN

public void __pl_gifts_core_SetNTVOptional()
{
	MarkNativeAsOptional("Gifts_GetGiftsCount");
	MarkNativeAsOptional("Gifts_GetConfig");
	MarkNativeAsOptional("Gifts_CreateGift");
}
#endif
