#if defined _store_included
	#endinput
#endif
#define _store_included

public SharedPlugin __pl_store = 
{
	name = "store",
	file = "store.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

public Extension __ext_store_sm =
{
	name = "Store - The Resurrection",
	file = "store_sm.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_store_SetNTVOptional()
{
	MarkNativeAsOptional("Store_RegisterHandler");
	MarkNativeAsOptional("Store_RegisterMenuHandler");
	MarkNativeAsOptional("Store_SetDataIndex");
	MarkNativeAsOptional("Store_GetDataIndex");
	MarkNativeAsOptional("Store_GetEquippedItem");
	MarkNativeAsOptional("Store_IsClientLoaded");
	MarkNativeAsOptional("Store_DisplayPreviousMenu");
	MarkNativeAsOptional("Store_SetClientMenu");
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
	MarkNativeAsOptional("Store_IsClientVIP");
	MarkNativeAsOptional("Store_IsItemInBoughtPackage");
	MarkNativeAsOptional("Store_ShouldConfirm");
	MarkNativeAsOptional("Store_DisplayConfirmMenu");
	MarkNativeAsOptional("Store_GetItem");
	MarkNativeAsOptional("Store_GetHandler");
	MarkNativeAsOptional("Store_GiveItem");
	MarkNativeAsOptional("Store_RemoveItem");
	MarkNativeAsOptional("Store_GetClientItem");
	MarkNativeAsOptional("Store_GetClientTarget");
	MarkNativeAsOptional("Store_GiveClientItem");
	MarkNativeAsOptional("Store_HasClientItem");
	MarkNativeAsOptional("Store_IterateEquippedItems");
}
#endif

new g_cvarChatTag = -1;
#define CHAT_TAG g_eCvars[g_cvarChatTag][sCache]

#define ITEM_NAME_LENGTH 64
#define STORE_MAX_ITEMS 2048
#define STORE_MAX_HANDLERS 64
#define STORE_MAX_PLANS 8
#define STORE_MAX_SLOTS 4

enum Item_Plan
{
	String:sl_ItemName[ITEM_NAME_LENGTH],
	il_ItemPrice,
	il_Time
}

enum Store_Item
{
	String:sl_StoreName[ITEM_NAME_LENGTH],
	String:sl_UniqueId[PLATFORM_MAX_PATH],
	String:sl_Shortcut[64],
	il_StoreId,
	il_StorePrice,
	il_Parent,
	il_Handler,
	il_FlagBits,
	il_Data,
	il_Plans,
	bool:bl_Buyable,
	bool:bl_IgnoreVIP,
	Handle:hl_Attributes
}

enum Type_Handler
{
	String:sl_Type[64],
	String:sl_UniqueKey[32],
	bool:bl_Equipable,
	bool:bl_Raw,
	Handle:hl_Plugin,
	Function:fnl_MapStart,
	Function:fnl_Reset,
	Function:fnl_Config,
	Function:fnl_Use,
	Function:fnl_Remove
}

enum Client_Item
{
	il_ClientId,
	il_UniqueId,
	bool:bl_Synced,
	bool:bl_Deleted,
	il_DateOfPurchase,
	il_DateOfExpiration,
	il_PriceOfPurchase,
}

native Store_RegisterHandler(String:type[], String:uniquekey[], Function:mapstart, Function:reset, Function:config, Function:use, Function:remove, bool:equipable = true, bool:raw = false);
native Store_RegisterMenuHandler(String:identifier[], Function:menu, Function:handler);
native Store_SetDataIndex(itemid, index);
native Store_GetDataIndex(itemid);
native Store_GetEquippedItem(client, String:type[], slot=0);
native Store_IsClientLoaded(client);
native Store_DisplayPreviousMenu(client);
native Store_SetClientMenu(client, num);
native Store_GetClientCredits(client);
native Store_SetClientCredits(client, credits);
native Store_IsClientVIP(client);
native Store_IsItemInBoughtPackage(client, itemid, uid=-1);
native Store_ShouldConfirm();
native Store_DisplayConfirmMenu(client, String:title[], Function:callback, data);
native Store_GetItem(itemid, output[Store_Item]);
native Store_GetHandler(index, output[Type_Handler]);
native Store_GiveItem(client, itemid, purchase=0, expiration=0, price=0);
native Store_RemoveItem(client, itemid);
native Store_GetClientItem(client, itemid, output[Client_Item]);
native Store_GetClientTarget(client);
native Store_GiveClientItem(client, recipient, itemid);
native Store_HasClientItem(client, itemid);
native Store_IterateEquippedItems(client, &start, bool:attributes=false);

forward Store_OnClientModelChanged(client, String:model[]);