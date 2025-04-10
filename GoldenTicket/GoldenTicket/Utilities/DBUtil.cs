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
                var faqs = context.Faq
                    .Include(faq => faq.MainTag)
                    .Include(faq => faq.SubTag)
                    .Select(faq => new FAQDTO
                    {
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
        #region -   GetFAQ
        public static FAQ? GetFAQ(int faqID)
        {
            using(var context = new ApplicationDbContext()){
                var faq = context.Faq
                    .FirstOrDefault(faq => faq.FaqID == faqID);
                if(faq == null)
                {
                    Console.WriteLine($"[DBUtil] FAQ with {faqID} ID not found");
                    return null;
                }
                return faq;
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
        #region -   UpdateFAQ
        public async static Task<FAQ?> UpdateFAQ(int faqID, string? Title, string? Description, string? Solution, string? Maintag, string? Subtag, bool IsArchived)
        {
            using (var context = new ApplicationDbContext())
            {
                var faq = context.Faq.FirstOrDefault(f => f.FaqID == faqID);
                if (faq != null)
                {
                    faq.Title = Title ?? faq.Title;
                    faq.Description = Description ?? faq.Description;
                    faq.Solution = Solution ?? faq.Solution;
                    int? mainTagID = 0;
                    int? subTagID = 0;
                    
                    if(Maintag  != null)
                        mainTagID = context.MainTag.Include(m => m.ChildTags).Where(m => m.TagName == Maintag).Select(m => m.TagID).FirstOrDefault();
                    if(Subtag != null)
                        subTagID = context.SubTag.Where(s => s.MainTagID == mainTagID! && s.TagName == Subtag).Select(s => s.TagID).FirstOrDefault();
                    
                    if (!string.IsNullOrEmpty(Maintag))  
                        faq.MainTagID = mainTagID;
                    else faq.MainTagID = null;
                    
                    if (!string.IsNullOrEmpty(Maintag))  
                        faq.SubTagID = subTagID;
                    else faq.SubTagID = null;

                    faq.IsArchived = IsArchived;
                    await context.SaveChangesAsync();
                    return faq;
                } else
                {
                    Console.WriteLine($"[DBUtil] FAQ with {faqID} ID not found ");
                    return null;
                }
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
                var user = context.Users
                    .Include(u => u.Role)
                    .Include(u => u.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .FirstOrDefault(user => user.Username!.Equals(Username));

                return user!;
            }
        }
        public static User FindUser(int Id)
        {
            using(var context = new ApplicationDbContext()){
                var user = context.Users
                    .Include(u => u.Role)
                    .Include(u => u.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .FirstOrDefault(user => user.UserID == Id);

                return user!;
            }
        }
        #endregion
        #region -   GetUsersByRole
        public static List<UserDTO> GetUsersByRole() 
        {
            using (var context = new ApplicationDbContext())
            {
                var users = context.Users
                    .Include(u => u.Role)
                    .Include(m => m.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .Where(u => u.UserID != 100000001)
                    .Select(user => new UserDTO(user)).ToList();

                return users;
            }
        }
        #endregion
        #region -   GetAdminUsers
        public static List<UserDTO> GetAdminUsers() {
            using(var context = new ApplicationDbContext()){
                return context.Users
                    .Include(u => u.Role)
                    .Include(u => u.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .Where(user => (user.Role!.RoleName == "Admin" || user.Role!.RoleName == "Staff") && user.UserID != 100000001)
                    .Select(user => new UserDTO(user)).ToList();
            }
        }
        #endregion
        #region -   UpdateUser
        public async static Task<User?> UpdateUser(int _userID, string? _username, string? _firstname, string? _middlename, string? _lastname, string? _role, List<string?> _assignedTags) {
            using(var context = new ApplicationDbContext()){
                var user = context.Users
                    .Include(u => u.Role)
                    .Include(u => u.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .FirstOrDefault(user => user.UserID == _userID);

                if(user != null)
                {
                    var roleID = context.Roles.FirstOrDefault(role => role.RoleName == _role);

                    // My eye hurts
                    user.Username = _username ?? user.Username;
                    user.FirstName = _firstname ?? user.FirstName;
                    user.MiddleName = _middlename ?? user.MiddleName;
                    user.LastName = _lastname ?? user.LastName;
                    user.RoleID = roleID!.RoleID;
                    if(_assignedTags != null) 
                    {
                        // Emptys User's assignedTags so that database dont go crazy
                        user.AssignedTags = [];
                        await context.SaveChangesAsync();

                        // Removes existing AssignedTags of UserID
                        var existingTags = context.AssignedTags.Where(tag => tag.UserID == _userID).ToList();
                        context.AssignedTags.RemoveRange(existingTags);
                        await context.SaveChangesAsync();

                        // Adds new AssignedTags to UserID
                        user.AssignedTags = _assignedTags.Select(tagName => new AssignedTag
                        {
                            UserID = _userID,
                            MainTag = context.MainTag.FirstOrDefault(tag => tag.TagName == tagName)
                        }).ToList();
                    } else {
                        // Emptys User's assignedTags so that database dont go crazy
                        user.AssignedTags = [];
                        await context.SaveChangesAsync();

                        // Removes existing AssignedTags of UserID
                        var existingTags = context.AssignedTags.Where(tag => tag.UserID == _userID).ToList();
                        context.AssignedTags.RemoveRange(existingTags);
                        await context.SaveChangesAsync();
                    }
                } 
                else 
                {
                    Console.WriteLine($"[DBUtil] UserID {_userID} not found");
                }
                await context.SaveChangesAsync();
                return user;
            }
        }
        #endregion
        #region -   ChangePassword
        public async static Task ChangePassword(int _userID, string _newPassword)
        {
            using(var context = new ApplicationDbContext())
            {
                var user = context.Users
                    .Include(u => u.Role)
                    .Include(u => u.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .FirstOrDefault(user => user.UserID == _userID);
                if(user != null) {
                    var HashedPassword = AuthUtils.HashPassword(_newPassword, out string salt);
                    user.Password = $"{salt}:{HashedPassword}";
                    await context.SaveChangesAsync();
                }
            }
        }
        #endregion
        #region -   AddUser
        public async static Task<User?> AddUser(string Username, string Password, string FirstName, string? MiddleName, string LastName, string Role, List<string?> AssignedTags)
        {
            using(var context = new ApplicationDbContext()) 
            {
                if(context.Users.FirstOrDefault(user => user.Username == Username) != null)
                {
                    Console.WriteLine($"[DBUtil] User {Username} already exists.");
                    return null;
                }
                var roleID = context.Roles.FirstOrDefault(role => role.RoleName == Role);

                var HashedPassword = AuthUtils.HashPassword(Password, out string salt);
                var NewUser = new User
                {
                    Username = Username,
                    Password = $"{salt}:{HashedPassword}",
                    FirstName = FirstName,
                    MiddleName = MiddleName ?? "",
                    LastName = LastName,
                    RoleID = roleID!.RoleID,
                };
                context.Add(NewUser);
                await context.SaveChangesAsync();

                if(AssignedTags != null)
                {
                    NewUser.AssignedTags = AssignedTags.Select(tagName => new AssignedTag
                    {
                        UserID = NewUser.UserID,
                        MainTag = context.MainTag.FirstOrDefault(tag => tag.TagName == tagName)
                    }).ToList();
                }
                await context.SaveChangesAsync();
                return NewUser;
            }
        }
        #endregion
        #endregion
        #region Ticket




        #region -   AddTicket
        public async static Task<Tickets> AddTicket(string TicketTitle, int AuthorID, string MainTagName, string SubTagName, string Priority, int ChatroomID, int? AssignedID = 0)
        {
            int? mainTagID = null;
            int? subTagID = null;
            int? priorityID = null;

            // Checks if a Chatroom already have an existing ticket
            if(GetChatroom(ChatroomID)?.TicketID != null)
            {
                Console.WriteLine($"[DBUtil] Chatroom {ChatroomID} already has an existing ticket.");
                return null!;
            }

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
            // Get PriorityID based on Priority name
            if (Priority != "null")
            {
                var priority = context.Priorities.FirstOrDefault(p => p.PriorityName == Priority);
                if (priority != null)
                {
                priorityID = priority.PriorityID;
                }
            }

            // Creates Ticket
            var newTicket = new Tickets
            {
                TicketTitle = TicketTitle,
                AuthorID = AuthorID,
                StatusID = 1,
            };
            if (AssignedID != 0)
            {
                newTicket.StatusID = 2;
                newTicket.AssignedID = AssignedID;
            }

            // Only assign MainTagID, SubTagID, and PriorityID if they are not null
            if (mainTagID.HasValue)
            {
                newTicket.MainTagID = mainTagID.Value;
            }
            if (subTagID.HasValue)
            {
                newTicket.SubTagID = subTagID.Value;
            }
            if (priorityID.HasValue)
            {
                newTicket.PriorityID = priorityID.Value;
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

            // Creates Ticket History if there is an assignedID
            if(AssignedID != 0)
            {
                var ticketHistory2 = new TicketHistory
                {
                    TicketID = newTicket.TicketID,
                    ActionID = 2,
                    ActionMessage = $"Ticket is automatically assigned to {context.Users.FirstOrDefault(u => u.UserID == AssignedID)!.FirstName} by Golden AI",
                };
                context.TicketHistory.Add(ticketHistory2);
                await context.SaveChangesAsync();
            }

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
                        .Include(t => t.Author)
                            .ThenInclude(a => a!.AssignedTags)
                                .ThenInclude(a => a.MainTag)
                        .Include(t => t.Assigned)
                            .ThenInclude(a => a!.Role)
                        .Include(t => t.Assigned)
                            .ThenInclude(a => a!.AssignedTags)
                                .ThenInclude(a => a.MainTag)
                        .Include(t => t.MainTag)
                        .Include(t => t.SubTag)
                        .Include(t => t.Status)
                        .Include(t => t.Priority)
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
                    .Include(t => t.Author)
                        .ThenInclude(a => a!.AssignedTags)
                            .ThenInclude(a => a.MainTag)
                    .Include(t => t.Assigned)
                        .ThenInclude(a => a!.Role)
                    .Include(t => t.Assigned)
                        .ThenInclude(a => a!.AssignedTags)
                            .ThenInclude(a => a.MainTag)
                    .Include(t => t.MainTag)
                    .Include(t => t.SubTag)
                    .Include(t => t.Status)
                    .Include(t => t.Priority)
                    .FirstOrDefault(t => t.TicketID == ticketID);
            }
        }
        #endregion
        #region -   UpdateTicket
        public async static Task<Tickets> UpdateTicket(int ticketID, string title, string statusName, string priorityName, string? MainTag, string? SubTag, int? assignedID, int EditorID)
        {
            using (var context = new ApplicationDbContext())
            {
                string editorName = context.Users
                    .Where(u => u.UserID == EditorID)
                    .Select(u => u.FirstName + " " + u.LastName)
                    .FirstOrDefault()!;

                int statusID = context.Status.Where(s => s.StatusName == statusName).Select(s => s.StatusID).FirstOrDefault();
                int priorityID = context.Priorities.Where(p => p.PriorityName == priorityName).Select(p => p.PriorityID).FirstOrDefault();
                int? mainTagID = 0;
                int? subTagID = 0;
                
                if(MainTag != null)
                    mainTagID = context.MainTag.Include(m => m.ChildTags).Where(m => m.TagName == MainTag).Select(m => m.TagID).FirstOrDefault();
                if(SubTag != null)
                    subTagID = context.SubTag.Where(s => s.MainTagID == mainTagID! && s.TagName == SubTag).Select(s => s.TagID).FirstOrDefault();

                var newticket = context.Tickets.FirstOrDefault(t => t.TicketID == ticketID);

                //TicketHistory Title Creation
                if(title != newticket!.TicketTitle)
                {
                    var ticketHistory = new TicketHistory
                    {
                        TicketID = newticket.TicketID,
                        ActionID = 9,
                        ActionMessage = $"Ticket Title changed from {newticket!.TicketTitle} to {title} by {editorName}",
                    };
                    context.TicketHistory.Add(ticketHistory);
                    await context.SaveChangesAsync();
                }

                // TicketHistory Status Creation
                if(statusID != newticket!.StatusID)
                {
                    int Action = 1;
                    string Message = "";
                    switch(statusID)
                    {
                        case 1:
                            Action = 8;
                            Message = $"Ticket Re-Opened by **{editorName}**";
                            break;
                        case 2:
                            Action = 3;
                            Message = $"Ticket set In Progress by **{editorName}**";
                            break;
                        case 3:
                            Action = 5;
                            Message = $"Ticket On Hold by **{editorName}**";
                            break;
                        case 4:
                            Action = 4;
                            Message = $"Ticket Closed by **{editorName}**";
                            break;
                        case 5:
                            Action = 7;
                            Message = $"Ticket set as Unresolved by **{editorName}**";
                            break;
                    }
                    // Creates Ticket History
                    var ticketHistory = new TicketHistory
                    {
                        TicketID = newticket.TicketID,
                        ActionID = Action,
                        ActionMessage = Message,
                    };
                    context.TicketHistory.Add(ticketHistory);
                    await context.SaveChangesAsync();
                }

                // TicketHistory Priority Creation
                if(priorityID != newticket!.PriorityID)
                {
                    var ticketHistory = new TicketHistory
                    {
                        TicketID = newticket.TicketID,
                        ActionID = 12,
                        ActionMessage = $"Ticket Title changed from {newticket!.TicketTitle} to {title} by {editorName}",
                    };
                    context.TicketHistory.Add(ticketHistory);
                    await context.SaveChangesAsync();
                }

                // TicketHistory MainTag Creation
                if(mainTagID != newticket!.MainTagID)
                {
                    var ticketHistory = new TicketHistory {TicketID = newticket.TicketID, ActionID = 10};
                    ticketHistory.ActionMessage = (newticket!.MainTagID != null) ?
                        $"Ticket Maintag changed from {newticket!.MainTag!.TagName} to {MainTag} by {editorName}" :
                        $"Ticket Maintag changed to {MainTag} by {editorName}";
                    context.TicketHistory.Add(ticketHistory);
                    await context.SaveChangesAsync();
                }

                // TicketHistory SubTag Creation
                if(subTagID != newticket!.SubTagID)
                {
                    var ticketHistory = new TicketHistory{ TicketID = newticket.TicketID, ActionID = 11 };
                    ticketHistory.ActionMessage = (newticket!.SubTagID != null) ? 
                        $"Ticket Subtag changed from {newticket!.SubTag!.TagName} to {SubTag} by {editorName}" : 
                        $"Ticket Subtag changed to {SubTag} by {editorName}";
                    context.TicketHistory.Add(ticketHistory);
                    await context.SaveChangesAsync();
                }
                
                // TicketHistory Assign Creation
                if(assignedID != newticket!.AssignedID)
                {
                    if(newticket!.AssignedID == null)
                    {
                        var ticketHistory = new TicketHistory 
                        {
                            TicketID = newticket.TicketID,
                            ActionID = 2,
                            ActionMessage = $"Ticket Assigned to {context.Users.FirstOrDefault(u => u.UserID == assignedID)!.FirstName} by {editorName}",
                        };
                    } else {
                        var ticketHistory = new TicketHistory 
                        {
                            TicketID = newticket.TicketID,
                            ActionID = 3,
                            ActionMessage = $"Ticket Re-Assigned From {context.Users.FirstOrDefault(u => u.UserID == newticket!.AssignedID)!.FirstName} to {context.Users.FirstOrDefault(u => u.UserID == assignedID)!.FirstName} by {editorName}",
                        };
                    }
                }
                

                newticket!.TicketTitle = title;
                newticket.StatusID = statusID;
                newticket.PriorityID = priorityID;

                if (!string.IsNullOrEmpty(MainTag))  
                    newticket.MainTagID = mainTagID;
                else newticket.MainTagID = null;
                
                if (!string.IsNullOrEmpty(SubTag))  
                    newticket.SubTagID = subTagID;
                else newticket.SubTagID = null;

                if (assignedID != null && assignedID != 0)  
                    newticket.AssignedID = assignedID;
                else newticket.AssignedID = null;


                await context.SaveChangesAsync();
                return newticket;
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
        #region _   GetPriority
        public static List<string> GetPriorities(){
            using (var context = new ApplicationDbContext())
            {
                return context.Priorities.Select(m => m.PriorityName!).ToList();
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
        #region -   CloseChatroom
        public async static Task<Chatroom> CloseChatroom(int chatroomID)
        {
            using(var context = new ApplicationDbContext())
            {
                var chatroom = GetChatroom(chatroomID);
                chatroom!.IsClosed = true;
                context.Chatrooms.Attach(chatroom!);
                await context.SaveChangesAsync();
                return chatroom!;
            }
        }
        #endregion
        #region -   ReopenChatroom
        public async static Task<Chatroom> ReopenChatroom(int chatroomID)
        {
            using(var context = new ApplicationDbContext())
            {
                var chatroom = GetChatroom(chatroomID);
                chatroom!.IsClosed = false;
                context.Chatrooms.Attach(chatroom!);
                await context.SaveChangesAsync();
                return chatroom!;
            }
        }
        #endregion
        #region -   JoinChatroom
        public static ChatroomDTO JoinChatroom(int UserID, int ChatroomID)
        {
            using(var context = new ApplicationDbContext()) 
            {
                var chatroom = GetChatroom(ChatroomID);
                if(chatroom!.Members.Any(m => m.MemberID == UserID))
                {
                    Console.WriteLine($"[DBUtil] User {UserID} is already a member of chatroom {ChatroomID}");
                    return new ChatroomDTO(chatroom!);
                }
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
                    .Include(c => c.Members)
                        .ThenInclude(m => m.Member)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.Role)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                             // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.ticketHistories)
                            .ThenInclude(t => t!.Action)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Status)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Priority)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.AssignedTags)
                            .ThenInclude(t => t!.MainTag).ToList();
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
                    .Include(c => c.Members)
                        .ThenInclude(m => m.Member)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.Role)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.Role) // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.ticketHistories)
                            .ThenInclude(t => t!.Action)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Status)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Priority)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.AssignedTags)
                            .ThenInclude(t => t!.MainTag).ToList();
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
                    .Include(c => c.Members)
                        .ThenInclude(m => m.Member)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.Role) // Ensure Ticket's Author is loaded
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.ticketHistories)
                            .ThenInclude(t => t!.Action)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Status)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Priority)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.Role)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.AssignedTags)
                            .ThenInclude(t => t!.MainTag)
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
                    .Include(m => m.Sender)
                        .ThenInclude(s => s!.AssignedTags)
                            .ThenInclude(t => t!.MainTag)
                    .FirstOrDefault(m => m.MessageID == MessageID);
            }
        }
        #endregion
        #endregion
        #region Rating


        
        #region -   AddRating
        public static Rating AddRating(int ChatroomID, int Score, string? Feedback)
        {
            using (var context = new ApplicationDbContext())
            {
                var newRating = new Rating
                {
                    ChatroomID = ChatroomID,
                    CreatedAt = DateTime.Now,
                    Score = Score,
                    Feedback = Feedback
                };
                context.Rating.Add(newRating);
                context.SaveChanges();
                return newRating;
            }
        }
        #endregion
        #region -   GetRatings
        public static List<RatingDTO> GetRatings(int UserID)
        {
            var RatingList = new List<RatingDTO>();
            using (var context = new ApplicationDbContext())
            {
                var ratings = context.Rating
                    .Include(r => r.Chatroom)
                        .ThenInclude(c => c!.Author)
                            .ThenInclude(a => a!.Role)
                    .Include(r => r.Chatroom)
                        .ThenInclude(c => c!.Author)
                            .ThenInclude(a => a!.AssignedTags)
                                .ThenInclude(t => t!.MainTag)
                    .Include(r => r.Chatroom)
                        .ThenInclude(c => c!.Ticket)
                            .ThenInclude(t => t!.Author)
                                .ThenInclude(a => a!.Role)
                    .Include(r => r.Chatroom)
                        .ThenInclude(c => c!.Ticket)
                            .ThenInclude(c => c!.Author)
                                .ThenInclude(a => a!.AssignedTags)
                                    .ThenInclude(t => t!.MainTag)
                    .Include(r => r.Chatroom)
                        .ThenInclude(c => c!.Ticket)
                            .ThenInclude(t => t!.Assigned)
                                .ThenInclude(a => a!.Role)
                    .Include(r => r.Chatroom)
                        .ThenInclude(c => c!.Ticket)
                            .ThenInclude(t => t!.Assigned)
                                .ThenInclude(a => a!.AssignedTags)
                                    .ThenInclude(t => t!.MainTag)
                    .Include(r => r.Chatroom)
                        .ThenInclude(c => c!.Ticket)
                            .ThenInclude(t => t!.Assigned)
                                .ThenInclude(a => a!.AssignedTags)
                                    .ThenInclude(a => a.MainTag)
                    .Where(r => r.Chatroom!.Ticket!.AssignedID == UserID)
                    .ToList();
                foreach (var rating in ratings)
                {
                    RatingList.Add(new RatingDTO(rating));
                }
                return RatingList;
            }
        }
        #endregion
        #endregion
    }
}