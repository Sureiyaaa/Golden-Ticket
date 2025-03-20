using System.ComponentModel.DataAnnotations;

namespace GoldenTicket.Models
{
    public class RegisterRequest
    {
        [Required(ErrorMessage = "Username is required")]
        public string? username { get; set; }

        [Required(ErrorMessage = "Password is required")]
        public string? password { get; set; }

        [Required(ErrorMessage = "First name is required")]
        public string? firstName { get; set; }

        public char? middleInitial { get; set; } // Optional

        [Required(ErrorMessage = "Last name is required")]
        public string? lastName { get; set; }

        [Required(ErrorMessage = "Role ID is required")]
        public int? roleID { get; set; }
    }
    public class LoginRequest {
        public string? username {get;set;}
        public string? password {get;set;}
    }
}