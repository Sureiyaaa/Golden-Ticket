using GoldenTicket.Database;
using GoldenTicket.Entities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Utilities
{
    public class DBUtil()
    {
        #region FAQ



        #region -   GetFAQs
        public static List<FAQDTO> GetFAQs()
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
        #endregion
        #region -   AddFAQ
        public static FAQ AddFAQ(string _title, string _description, string _solution, string _mainTagName, string _subTagName)
        {
            int? mainTagID = null;
            int? subTagID = null;

            if (_mainTagName != "null")
            {
                var mainTag = GetTags().FirstOrDefault(x => x.MainTagName == _mainTagName);
                if (mainTag != null)
                {
                    mainTagID = mainTag.MainTagID;
                    if (_subTagName != "null")
                    {
                        var subTag = mainTag.SubTags?.FirstOrDefault(x => x.SubTagName == _subTagName);
                        if (subTag != null)
                        {
                            subTagID = subTag.SubTagID;
                        }
                    }
                }
            }

            using(var context = new ApplicationDbContext()){
                
                var newFAQ = new FAQ
                {
                    Title = _title,
                    Description = _description,
                    Solution = _solution,
                    CreatedAt = DateTime.Now,
                    IsArchived = false,
                    MainTagID = mainTagID,
                    SubTagID = subTagID,
                    MainTag = context.MainTag.Include(m => m.ChildTags).FirstOrDefault(tag => tag.TagID == mainTagID),
                    SubTag = context.SubTag.FirstOrDefault(tag => tag.TagID == subTagID && tag.MainTagID == mainTagID)
                };
                context.Faq.Add(newFAQ);
                context.SaveChanges();
                return newFAQ;
            }
        }
        #endregion
        #endregion

        #region Tags



        #region -   GetTags
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
        #endregion
        #region -   AddMainTag
        public static bool AddMainTag(string TagName)
        {
            using(var context = new ApplicationDbContext()){
                if(context.MainTag.FirstOrDefault(tag => tag.TagName!.ToLower() == TagName.ToLower()) != null)
                    return false;
                var newTag = new MainTag
                {
                    TagName = TagName
                };
                context.MainTag.Add(newTag);
                context.SaveChanges();
                return true;
            }
        }
        #endregion
        #region -   AddSubTag
        public static bool AddSubTag(string TagName, string MainTagName)
        {
            using(var context = new ApplicationDbContext()){
                if(context.SubTag.FirstOrDefault(tag => tag.TagName == TagName && tag.MainTag!.TagName!.ToLower() == MainTagName.ToLower()) != null)
                    return false;
                var newTag = new SubTag
                {
                    TagName = TagName,
                    MainTagID = context.MainTag.FirstOrDefault(tag => tag.TagName!.ToLower() == MainTagName.ToLower())!.TagID,
                };
                context.SubTag.Add(newTag);
                context.SaveChanges();
                return true;
            }
        }
        #endregion
        #endregion
        #region User




        #region -   RegisterAccount
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
        #endregion
        #region -   IsUserExisting
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
        #endregion
        #region -   FindUser
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
                var user = context.Users.Include(u => u.Role).FirstOrDefault(user => user.UserID == Id);

                return user!;
            }
        }
        #endregion
        #region -   GetUsersByRole
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
        #endregion
        #region -   GetAdminUsers
        public static List<UserDTO> GetAdminUsers() {
            using(var context = new ApplicationDbContext()){
                return context.Users.Include(u => u.Role).Where(user => user.Role!.RoleName == "Admin").Select(user => new UserDTO(user)).ToList();
            }
        }
        #endregion
        #endregion
        #region Ticket




        #region -   AddTicket
        public async static Task<Tickets> AddTicket(string TicketTitle, int AuthorID, string MainTagName, string SubTagName, int ChatroomID)
        {
            int? mainTagID = null;
            int? subTagID = null;

            if (MainTagName != "null")
            {
                var mainTag = GetTags().FirstOrDefault(x => x.MainTagName == MainTagName);
                if (mainTag != null)
                {
                    mainTagID = mainTag.MainTagID;
                    if (SubTagName != "null")
                    {
                        var subTag = mainTag.SubTags?.FirstOrDefault(x => x.SubTagName == SubTagName);
                        if (subTag != null)
                        {
                            subTagID = subTag.SubTagID;
                        }
                    }
                }
            }

            using (var context = new ApplicationDbContext())
            {
                // Creates Ticket
                var newTicket = new Tickets
                {
                    TicketTitle = TicketTitle,
                    AuthorID = AuthorID,
                    StatusID = 1
                };

                // Only assign MainTagID and SubTagID if they are not null
                if (mainTagID.HasValue)
                {
                    newTicket.MainTagID = mainTagID.Value;
                }
                if (subTagID.HasValue)
                {
                    newTicket.SubTagID = subTagID.Value;
                }

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
                if (chatroom != null)
                {
                    context.Chatrooms.Attach(chatroom);
                    chatroom.TicketID = newTicket.TicketID;
                    await context.SaveChangesAsync();
                }

                return newTicket;
            }
        }
        #endregion
        #region -   GetTickets
        public static List<TicketDTO> GetTickets(int userID, bool isEmployee)
        {
            
            using(var context = new ApplicationDbContext())
            {
                List<TicketDTO> ticketDTOs = new List<TicketDTO>();
                List<Tickets> ticketList = context.Tickets
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
                if (isEmployee)
                {
                    foreach(var ticket in ticketList.Where(c => c.AuthorID == userID)){
                        ticketDTOs.Add(new TicketDTO(ticket));
                    }
                }
                else
                {
                    foreach(var ticket in ticketList){
                        ticketDTOs.Add(new TicketDTO(ticket));
                    }
                }
                return ticketDTOs;
            }
        }
        #endregion
        #region -   GetTicket
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
        #endregion
        #region -   GetStatuses
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
        #endregion
        #region Chatroom





        #region -   AddChatroom
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
        #endregion
        #region -   JoinChatroom
        public static ChatroomDTO JoinChatroom(int UserID, int ChatroomID)
        {
            using(var context = new ApplicationDbContext()) 
            {
                var chatroom = GetChatroom(ChatroomID);
                var newMember = new GroupMember 
                {
                    ChatroomID = ChatroomID,
                    MemberID = UserID,
                };
                chatroom!.Members.Add(newMember);
                context.Chatrooms.Attach(chatroom!);
                context.SaveChanges();
                var updatedChatroom = GetChatroom(ChatroomID);
                return new ChatroomDTO(updatedChatroom!);
            }
        }
        #endregion
        #region -   GetChatrooms
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
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.Role) // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.ticketHistories)
                            .ThenInclude(t => t!.Action)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Status)
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
        #endregion
public static List<ChatroomDTO> GetChatrooms()
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
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.Role) // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.ticketHistories)
                            .ThenInclude(t => t!.Action)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Status)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role).ToList();
                foreach(var chatroom in chatrooms.Where(c => c.TicketID != null)){
                    dtos.Add(new ChatroomDTO(chatroom));
                }
                return dtos;
            }
        }
        #region -   GetChatroom
        public static Chatroom? GetChatroom(int ChatroomID)
        {
            using (var context = new ApplicationDbContext())
            {
                return context.Chatrooms
                    .Include(c => c.Members)
                        .ThenInclude(m => m.Member)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.Role) // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.ticketHistories)
                            .ThenInclude(t => t!.Action)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Status)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.Role)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role)
                    .FirstOrDefault(c => c.ChatroomID == ChatroomID);
            }
        }
        #endregion
        #region -   UpdateLastSeen
        public static void UpdateLastSeen(int UserID, int ChatroomID)
        {
            using(var context = new ApplicationDbContext())
            {
                var member = context.GroupMembers.FirstOrDefault(m => m.MemberID == UserID && m.ChatroomID == ChatroomID);
                if(member != null){
                    member.LastSeenAt = DateTime.Now;
                    context.SaveChanges();
                }
            }
        }
        #endregion
        #region -   SendMessage
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
        #endregion
        #region -   GetMessage
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
        #endregion
    }
}