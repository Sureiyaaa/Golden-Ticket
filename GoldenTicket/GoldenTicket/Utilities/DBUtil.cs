using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTracker.Models
{
    public class DBUtil()
    {
        #region FAQ
        public static List<FAQ> GetFAQ()
        {
            using(var context = new ApplicationDbContext()){
                var faqs = context.Faq.ToList();
                if(faqs.Count == 0 )
                    throw new Exception("No FAQs found");
                return faqs;
            }
        }
        public static void AddFAQ(string _title, string _description, string _solution, int _mainTagID, int _subTagID)
        {
            using(var context = new ApplicationDbContext()){
                var newFAQ = new FAQ
                {
                    Title = _title,
                    Description = _description,
                    Solution = _solution,
                    CreatedAt = DateTime.Now,
                    IsArchived = false,
                    MainTagID = _mainTagID,
                    SubTagID = _subTagID,
                    MainTag = context.MainTag.Include(m => m.ChildTags).FirstOrDefault(tag => tag.TagID == _mainTagID),
                    SubTag = context.SubTag.FirstOrDefault(tag => tag.TagID == _subTagID && tag.MainTagID == _mainTagID)
                };
                context.Faq.Add(newFAQ);
                context.SaveChanges();
            }
        }
        #endregion

        #region Tags
        public static List<T> GetTags<T>() where T : class {
            using(var context = new ApplicationDbContext()){
            
            var maintags = context.MainTag.Include(m => m.ChildTags).Select(m => new {
                mainTagID = m.TagID,
                mainTagName = m.TagName,
                subTags = m.ChildTags.Select(c => new 
                {
                subTagID = c.TagID,
                subTagName = c.TagName,
                mainTagName = m.TagName
                }).ToList()
            }).ToList();
            return maintags.Cast<T>().ToList();
            }
        } 
        public static void AddMainTag(string TagName)
        {
            using(var context = new ApplicationDbContext()){
                if(context.MainTag.FirstOrDefault(tag => tag.TagName == TagName) != null)
                    throw new Exception("Tag already exists");
                var newTag = new MainTag
                {
                    TagName = TagName
                };
                context.MainTag.Add(newTag);
                context.SaveChanges();
            }
        }
        public static void AddSubTag(string TagName, int MainTagID)
        {
            using(var context = new ApplicationDbContext()){
                var newTag = new SubTag
                {
                    TagName = TagName,
                    MainTagID = MainTagID,
                    MainTag = context.MainTag.FirstOrDefault(tag => tag.TagID == MainTagID)
                };
                context.SubTag.Add(newTag);
                context.SaveChanges();
            }
        }
        #endregion

        #region User
        public static void RegisterAccount(string Username, string Password, string FirstName, string? MiddleName, string LastName, int? RoleID)
        {
            using(var Context = new ApplicationDbContext()){
                var HashedPassword = AuthUtils.HashPassword(Password, out string salt);
                var NewUser = new User
                {
                    Username = Username,
                    Password = $"{salt}:{HashedPassword}",
                    FirstName = FirstName,
                    MiddleName = MiddleName ?? "",
                    LastName = LastName,
                    RoleID = RoleID ?? throw new Exception("Error")
                };

                Context.Add(NewUser);
                Context.SaveChanges();
            }
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
                var user = context.Users.Include(u => u.Role).FirstOrDefault(user => user.Username!.Equals(Username));

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
        #endregion
    }
}