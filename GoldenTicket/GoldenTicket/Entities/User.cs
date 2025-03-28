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
        public string? MiddleName { get; set; } = "";
        [Required]
        public string? LastName { get; set; }
        [Required]
        public int RoleID { get; set; }
        [ForeignKey("RoleID")]
        public Roles? Role { get; set; } = null;
        public string Email { get; set; } = "None Provided";
        public string PhoneNumber { get; set; } = "None Provided";
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? lastOnlineAt { get;set; }

    }
    public class UserDTO { 
        public int UserID { get; set; }
        public string? Username { get; set; }
        public string? FirstName { get; set; }
        public string? MiddleName { get; set; }
        public string? LastName { get; set; }
        public string? Role {get;set;}
        public DateTime? lastOnlineAt { get; set; }
        public DateTime createdAt {get;set;}
        public UserDTO(User user){
            this.UserID = user.UserID;
            this.Username = user.Username;
            this.FirstName = user.FirstName;
            this.MiddleName = user.MiddleName;
            this.LastName = user.LastName;
            this.Role = user.Role!.RoleName;
            this.lastOnlineAt = user.lastOnlineAt;
            this.createdAt = user.CreatedAt;
        }
    }
}