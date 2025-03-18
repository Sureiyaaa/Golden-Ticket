using GoldenTicket.Database;
using GoldenTicket.Entities;

namespace GoldenTracker.Models
{
    public class DBUtil()
    {
        public static void RegisterAccount(string Username, string Password, string FirstName, char MiddleInitial, string LastName)
        {
            var context = new ApplicationDbContext();

            var newUser = new User
            {
                Username = Username,
                Password = Password,
                FirstName = FirstName,
                MiddleInitial = MiddleInitial,
                LastName = LastName
            };

            context.Add(newUser);
            context.SaveChanges();
        }
        public static bool IsUserExisting(string username)
        {
            using(var context = new ApplicationDbContext()){
                var user = context.Users.FirstOrDefault(user => user.Username == username);
                return user == null ? false : true ;
            }
        }
        public static bool IsUserExisting(int Id)
        {
            using(var context = new ApplicationDbContext()){
                var user = context.Users.FirstOrDefault(user => user.UserID == Id);
                return user == null ? false : true;
            }
        }
        public static User FindUser(string Username)
        {
            using(var context = new ApplicationDbContext()){
                var user = context.Users.FirstOrDefault(user => user.Username!.Equals(Username));

                return user!;
            }
        }
        public static User FindUser(int Id)
        {
            using(var context = new ApplicationDbContext()){
                var user = context.Users.FirstOrDefault(user => user.UserID == Id);

                return user!;
            }
        }

    }
}