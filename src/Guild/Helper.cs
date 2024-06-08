using System.Data;
using System.Reflection;
using System.Text.Json;
using CounterStrikeSharp.API;
using CounterStrikeSharp.API.Core;

namespace Guild
{
	internal class Helper
	{        
        private static readonly string AssemblyName = Assembly.GetExecutingAssembly().GetName().Name ?? "";
        private static readonly string CfgPath = $"{Server.GameDirectory}/csgo/addons/counterstrikesharp/configs/plugins/{AssemblyName}/{AssemblyName}.json";
        public static void UpdateConfig<T>(T config) where T : BasePluginConfig, new()
		{
			// get newest config version
			var newCfgVersion = new T().Version;

			// loaded config is up to date
			if (config.Version == newCfgVersion)
				return;

			// update the version
			config.Version = newCfgVersion;

			// serialize the updated config back to json
			var updatedJsonContent = JsonSerializer.Serialize(config, new JsonSerializerOptions { WriteIndented = true, DictionaryKeyPolicy = JsonNamingPolicy.CamelCase, Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping });
			File.WriteAllText(CfgPath, updatedJsonContent);
		}
		
		public static DateTime ConvertUnixToDateTime(double unixTime)
		{
			System.DateTime dt = new DateTime(1970,1,1,0,0,0,0,System.DateTimeKind.Utc);
			return dt.AddSeconds(unixTime).ToLocalTime();
		}
		
		public static int GetNowUnixTime()
		{
			var unixTime = DateTime.Now.ToUniversalTime() -
						new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);

			return (int)unixTime.TotalSeconds;
		}
    }
	public static class SqlHelper
	{
		private static Dictionary<Type, SqlDbType> typeMap;

		// Create and populate the dictionary in the static constructor
		static SqlHelper()
		{
			typeMap = new Dictionary<Type, SqlDbType>();

			typeMap[typeof(string)]         = SqlDbType.NVarChar;
			typeMap[typeof(char[])]         = SqlDbType.NVarChar;
			typeMap[typeof(byte)]           = SqlDbType.TinyInt;
			typeMap[typeof(short)]          = SqlDbType.SmallInt;
			typeMap[typeof(int)]            = SqlDbType.Int;
			typeMap[typeof(long)]           = SqlDbType.BigInt;
			typeMap[typeof(byte[])]         = SqlDbType.Image;
			typeMap[typeof(bool)]           = SqlDbType.Bit;
			typeMap[typeof(DateTime)]       = SqlDbType.DateTime2;
			typeMap[typeof(DateTimeOffset)] = SqlDbType.DateTimeOffset;
			typeMap[typeof(decimal)]        = SqlDbType.Money;
			typeMap[typeof(float)]          = SqlDbType.Real;
			typeMap[typeof(double)]         = SqlDbType.Float;
			typeMap[typeof(TimeSpan)]       = SqlDbType.Time;
			/* ... and so on ... */
		}

		// Non-generic argument-based method
		public static SqlDbType GetDbType(Type giveType)
		{
			// Allow nullable types to be handled
			giveType = Nullable.GetUnderlyingType(giveType) ?? giveType;

			if (typeMap.ContainsKey(giveType))
			{
				return typeMap[giveType];
			}

			throw new ArgumentException($"{giveType.FullName} is not a supported .NET class");
		}

		// Generic version
		public static SqlDbType GetDbType<T>()
		{
			return GetDbType(typeof(T));
		}
	}
}