using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
namespace GoldenTicket.Entities
{
    [Table("APIKeys")]
    public class APIKeys
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int APIKeyID { get; set; }
        [Required]
        public string? ApiKey {get; set;} = "";
        [Required]
        public string? Notes { get; set; } = "No note provided";
        [Required]
        public DateTime? LastRateLimit { get; set; } = null;
    }
    public class APIKeyDTO{
        public int? APIKeyID {get;set;}
        public string? APIKey {get;set;} = "";
        public string? Notes {get;set;} = "No note provided";
        public DateTime? LastRateLimit {get;set;} = null;
        

        public APIKeyDTO(APIKeys apiKey){
            this.APIKeyID = apiKey.APIKeyID;
            this.APIKey = apiKey.ApiKey;
            this.Notes = apiKey.Notes;
            this.LastRateLimit = apiKey.LastRateLimit;
        }
    }
}
