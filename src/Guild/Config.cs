using CounterStrikeSharp.API.Core;
using System.Text.Json.Serialization;

namespace Guild
{
	public class GuildConfig : BasePluginConfig
	{
		[JsonPropertyName("ConfigVersion")]
		public override int Version { get; set; } = 1;
		[JsonPropertyName("OpenCommands")]
		public string OpenCommands { get; set; } = "css_gangs;css_g;css_gang";

		[JsonPropertyName("DatabaseHost")]
		public string DatabaseHost { get; set; } = "";

		[JsonPropertyName("DatabasePort")]
		public int DatabasePort { get; set; } = 3306;

		[JsonPropertyName("DatabaseUser")]
		public string DatabaseUser { get; set; } = "";

		[JsonPropertyName("DatabasePassword")]
		public string DatabasePassword { get; set; } = "";

		[JsonPropertyName("DatabaseName")]
		public string DatabaseName { get; set; } = "";

		[JsonPropertyName("ServerId")]
		public int ServerId { get; set; } = 0;

		[JsonPropertyName("CreateCost")]
		public CreateCost CreateCost { get; set; } = new();

		[JsonPropertyName("RenameCost")]
		public RenameCost RenameCost { get; set; } = new();

		[JsonPropertyName("ExtendCost")]
		public Prices ExtendCost { get; set; } = new();

		[JsonPropertyName("MaxMembers")]
		public int MaxMembers { get; set; } = 10;

		[JsonPropertyName("ExpInc")]
		public int ExpInc { get; set; } = 100;
	}
	public class CreateCost
	{
		[JsonPropertyName("_commentCost")]
        public string CommentCost { get; set; } = "Если 0, то бесплатно, если больше, нужен Mode";
        [JsonPropertyName("Value")]
		public int Value { get; set; } = 0;
        [JsonPropertyName("_commentMode")]
		public string CommentMode { get; set; } = "0 - Shop(Ganter), 1 - cs2-store";
        [JsonPropertyName("Mode")]
		public int Mode { get; set; } = 0;
        [JsonPropertyName("_commentDays")]
		public string CommentDays { get; set; } = "На какое количество дней создается банда, 0 - безлимит";
        [JsonPropertyName("Days")]
		public int Days { get; set; } = 0;
	}
	public class RenameCost
	{
		[JsonPropertyName("_commentCost")]
        public string CommentCost { get; set; } = "Если 0, то бесплатно, если больше, нужен Mode";
        [JsonPropertyName("Value")]
		public int Value { get; set; } = 0;
        [JsonPropertyName("_commentMode")]
		public string CommentMode { get; set; } = "0 - Shop(Ganter), 1 - cs2-store";
        [JsonPropertyName("Mode")]
		public int Mode { get; set; } = 0;
	}
	public class Prices
	{
		[JsonPropertyName("_commentPrices")]
        public string CommentCost { get; set; } = "Очистьте список, если не хотите продление";
		[JsonPropertyName("Prices")]
		public List<Price> Value { get; set; } = new();
	}
	public class Price
	{
		[JsonPropertyName("Day")]
		public int Day { get; set; }
		[JsonPropertyName("Value")]
		public int Value { get; set; }
	}
}