using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace GoldenTicket.Entities
{
    [Table("tblUsers")]
    public class User {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int UserID { get; set; }
        [Required]
        public string? Username { get; set; }
        [Required]
        public string? Password { get; set; }
        [Required]
        public string? FirstName { get; set; }
        [Required]
        public char? MiddleInitial { get; set; }
        [Required]
        public string? LastName { get; set; }
        public string Email { get; set; } = "None Provided";
        public string PhoneNumber { get; set; } = "None Provided";
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? lastOnlineAt { get;set; }

    }
    public class UserDTO { 
        public int UserID { get; set; }
        public string? Username { get; set; }
        public string? FirstName { get; set; }
        public char? MiddleInitial { get; set; }
        public string? LastName { get; set; }
        public DateTime? lastOnlineAt { get; set; }
        
        public UserDTO(User user){
            this.UserID = user.UserID;
            this.Username = user.Username;
            this.FirstName = user.FirstName;
            this.MiddleInitial = user.MiddleInitial;
            this.LastName = user.LastName;
            this.lastOnlineAt = user.lastOnlineAt;
        }
    }
}