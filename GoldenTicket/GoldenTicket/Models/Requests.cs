using GoldenTicket.Entities;

namespace GoldenTicket.Models
{
    public class RegisterRequest {
        public string? username {get;set;} = "";
        public string? password {get;set;} = "";
        public string? firstName {get;set;} = "";
        public char middleInitial {get;set;}
        public string? lastName {get;set;} = "";
        
    }

    public class LoginRequest {
        public string? username {get;set;}
        public string? password {get;set;}
    }
}