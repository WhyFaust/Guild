namespace Guild{
    public class UserInfo
    {
        public required string SteamID { get; set; }
        public int Status { get; set; } = 0;
        public int DatabaseID { get; set; } = -1;
        public int GangId { get; set; }
        public int Rank { get; set; }
        public string? InviterName { get; set; }
        public int InviteDate { get; set; }
    }
}