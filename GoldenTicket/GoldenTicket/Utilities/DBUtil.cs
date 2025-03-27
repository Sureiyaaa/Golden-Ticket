using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Utilities
{
    public class DBUtil()
    {
        #region FAQ
        public static List<FAQDTO> GetFAQ()
        {
            using(var context = new ApplicationDbContext()){
                var faqs = context.Faq.Include(faq => faq.MainTag).Include(faq => faq.SubTag).Select(faq => new FAQDTO{
                    FaqID = faq.FaqID,
                    Title = faq.Title,
                    Description = faq.Description,
                    Solution = faq.Solution,
                    CreatedAt = faq.CreatedAt,
                    IsArchived = faq.IsArchived,
                    MainTag = new MainTagDTO(faq.MainTag!),
                    SubTag = new SubTagDTO(faq.SubTag!)
                }).ToList();
                if(faqs.Count == 0 )
                    return [];
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
        public static List<MainTagDTO> GetTags()
        {
            using (var context = new ApplicationDbContext())
            {
                return context.MainTag.Include(m => m.ChildTags)
                    .Select(m => new MainTagDTO(m)
                    {
                        MainTagID = m.TagID,
                        MainTagName = m.TagName!,
                        SubTags = m.ChildTags.Select(c => new SubTagDTO(c)
                        {
                            SubTagID = c.TagID,
                            SubTagName = c.TagName!,
                            MainTagName = m.TagName!
                        }).ToList()
                    })
                    .ToList();
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
        public static void AddSubTag(string TagName, string MainTagName)
        {
            using(var context = new ApplicationDbContext()){
                var newTag = new SubTag
                {
                    TagName = TagName,
                    MainTagID = context.MainTag.FirstOrDefault(tag => tag.TagName == MainTagName)!.TagID,
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
        public static Dictionary<string, List<UserDTO>> GetUsersByRole() 
        {
            using (var context = new ApplicationDbContext())
            {
                var users = context.Users
                    .Include(u => u.Role)
                    .ToList()
                    .Select(user => new UserDTO(user))
                    .GroupBy(user => user.Role!)
                    .ToDictionary(group => group.Key, group => group.ToList());

                var requiredRoles = new[] { "Admin", "Staff", "Employee" };
                foreach (var role in requiredRoles)
                {
                    if (!users.ContainsKey(role))
                    {
                        users[role] = new List<UserDTO>();
                    }
                }
                return users;
            }
        }
        public static List<UserDTO> GetAdminUsers() {
            using(var context = new ApplicationDbContext()){
                return context.Users.Include(u => u.Role).Where(user => user.Role!.RoleName == "Admin").Select(user => new UserDTO(user)).ToList();
            }
        }
        #endregion


        #region Ticket
        public async static Task<Tickets> AddTicket(string TicketTitle, int AuthorID, int MainTagID, int SubTagID,  int ChatroomID)
        {
            using(var context = new ApplicationDbContext()){
                // Creates Ticket
                var newTicket = new Tickets
                {
                    TicketTitle = TicketTitle,
                    AuthorID = AuthorID,
                    MainTagID = MainTagID,
                    SubTagID = SubTagID,
                    StatusID = 1,
                };
                context.Tickets.Add(newTicket);
                await context.SaveChangesAsync();

                // Creates Ticket History
                var ticketHistory = new TicketHistory 
                {
                    TicketID = newTicket.TicketID,
                    ActionID = 1,
                    ActionMessage = "Ticket Created",
                };
                context.TicketHistory.Add(ticketHistory);
                await context.SaveChangesAsync();

                // Updates the Chatroom with the TicketID
                var chatroom = GetChatroom(ChatroomID);
                chatroom!.TicketID = newTicket.TicketID;
                context.SaveChanges();
                return newTicket;
            }
        }
        public async static Task<Tickets> AddTicket(string TicketTitle, int AuthorID, string MainTagName, string SubTagName, int ChatroomID)
        {
            int mainTagID = GetTags().FirstOrDefault(x => x.MainTagName == MainTagName)!.MainTagID;
            int subTagID = GetTags().FirstOrDefault(x => x.MainTagID == mainTagID)!.SubTags!.FirstOrDefault(x => x.SubTagName == SubTagName)!.SubTagID;

            using(var context = new ApplicationDbContext()){
                // Creates Ticket
                var newTicket = new Tickets
                {
                    TicketTitle = TicketTitle,
                    AuthorID = AuthorID,
                    MainTagID = mainTagID,
                    SubTagID = subTagID,
                    StatusID = 1,
                };
                context.Tickets.Add(newTicket);
                await context.SaveChangesAsync();

                // Creates Ticket History
                var ticketHistory = new TicketHistory 
                {
                    TicketID = newTicket.TicketID,
                    ActionID = 1,
                    ActionMessage = "Ticket Created",
                };
                context.TicketHistory.Add(ticketHistory);
                await context.SaveChangesAsync();

                // Updates the Chatroom with the TicketID
                var chatroom = GetChatroom(ChatroomID);
                chatroom!.TicketID = newTicket.TicketID;
                context.SaveChanges();
                return newTicket;
            }
        }
        public static List<Tickets> GetTickets(int userID, bool isEmployee)
        {
            using(var context = new ApplicationDbContext())
            {
                if (isEmployee)
                {
                    return context.Tickets
                        .Include(t => t.ticketHistories)
                            .ThenInclude(t => t.Action)
                        .Include(t => t.Author)
                            .ThenInclude(a => a!.Role)
                        .Include(t => t.Assigned)
                            .ThenInclude(a => a!.Role)
                        .Include(t => t.MainTag)
                        .Include(t => t.SubTag)
                        .Include(t => t.Status)
                        .ToList();
                }
                else
                {
                    return context.Tickets
                        .Include(t => t.ticketHistories)
                            .ThenInclude(t => t.Action)
                        .Include(t => t.Author)
                            .ThenInclude(a => a!.Role)
                        .Include(t => t.Assigned)
                            .ThenInclude(a => a!.Role)
                        .Include(t => t.MainTag)
                        .Include(t => t.SubTag)
                        .Include(t => t.Status)
                        .Where(t => t.AuthorID == userID)
                        .ToList();
                }
            }
        }
        public static Tickets? GetTicket(int ticketID) 
        {
            using(var context = new ApplicationDbContext())
            {
                return context.Tickets
                    .Include(t => t.ticketHistories)
                        .ThenInclude(t => t.Action)
                    .Include(t => t.Author)
                        .ThenInclude(a => a!.Role)
                    .Include(t => t.Assigned)
                        .ThenInclude(a => a!.Role)
                    .Include(t => t.MainTag)
                    .Include(t => t.SubTag)
                    .Include(t => t.Status)
                    .FirstOrDefault(t => t.TicketID == ticketID);
            }
        }
        public static List<string> GetStatuses()
        {
            using(var context = new ApplicationDbContext())
            {
                return context.Status
                    .Select(s => s.StatusName)
                    .ToList()!;
            }
        }
        #endregion


        #region Chatroom
        public async static Task<Chatroom> AddChatroom(int AuthorID)
        {
            using(var context = new ApplicationDbContext())
            {
                var newChat = new Chatroom{
                    AuthorID = AuthorID,
                };
                context.Chatrooms.Add(newChat);
                await context.SaveChangesAsync();

                var members = new List<GroupMember>{
                    new GroupMember {
                        ChatroomID = newChat.ChatroomID,
                        MemberID = AuthorID,
                    },
                    new GroupMember {
                        ChatroomID = newChat.ChatroomID,
                        MemberID = 100000001,
                    }
                };
                context.GroupMembers.AddRange(members);
                context.SaveChanges();

                var aiMessage = new Message {
                    ChatroomID = newChat.ChatroomID,
                    SenderID = 100000001,
                    MessageContent = "Hello! I'm AI, your virtual assistant. How can I help you today?",
                };
                context.Messages.Add(aiMessage);
                context.SaveChanges();
                return newChat;
            }
        }
        public static List<ChatroomDTO> GetChatrooms(int userID, bool isEmployee = false)
        {
            using(var context = new ApplicationDbContext())
            {
                List<ChatroomDTO> dtos = new List<ChatroomDTO>();
                List<Chatroom> chatrooms = context.Chatrooms
                    .Include(c => c.Members)
                        .ThenInclude(m => m.Member)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author).ThenInclude(t => t!.Role) // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned).ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role).ToList();
                if(isEmployee){   
                    foreach(var chatroom in chatrooms.Where(c => c.AuthorID == userID)){
                        dtos.Add(new ChatroomDTO(chatroom));
                    }
                }else{
                    foreach(var chatroom in chatrooms.Where(c => c.TicketID != null)){
                        dtos.Add(new ChatroomDTO(chatroom));
                    }
                }
                return dtos;
            }
        }
        public static Chatroom? GetChatroom(int ChatroomID)
        {
            using (var context = new ApplicationDbContext())
            {
                return context.Chatrooms
                    .Include(c => c.Members)
                        .ThenInclude(m => m.Member).ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author).ThenInclude(t => t!.Role) // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned).ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.Role)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role)
                    .FirstOrDefault(c => c.ChatroomID == ChatroomID);
            }
        }
        public static void UpdateLastSeen(int UserID, int ChatroomID)
        {
            using(var context = new ApplicationDbContext())
            {
                var member = context.GroupMembers.FirstOrDefault(m => m.MemberID == UserID && m.ChatroomID == ChatroomID);
                if(member != null){
                    member.LastSeenAt = DateTime.Now;
                    context.SaveChanges();
                } else {
                    Console.WriteLine("Member not found");
                }
            }
        }
        public async static Task<Message> SendMessage(int SenderID, int ChatroomID, string Message)
        {
            using(var context = new ApplicationDbContext())
            {
                var message = new Message
                {
                    SenderID = SenderID,
                    ChatroomID = ChatroomID,
                    MessageContent = Message,
                };
                context.Messages.Add(message);
                await context.SaveChangesAsync();
                return message;
            }
        }
        public static Message? GetMessage(int MessageID)
        {
            using (var context = new ApplicationDbContext())
            {
                return context.Messages
                    .Include(m => m.Sender)
                        .ThenInclude(s => s!.Role)
                    .FirstOrDefault(m => m.MessageID == MessageID);
            }
        }
        
        #endregion
    }
}