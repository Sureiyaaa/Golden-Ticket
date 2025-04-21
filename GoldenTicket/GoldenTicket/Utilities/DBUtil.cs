using System.Diagnostics;
using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Utilities
{
    public class DBUtil()
    {
        public static int ChatbotID = AIUtil.GetChatbotID();
        #region FAQ



        #region -   GetFAQs
        public static List<FAQDTO> GetFAQs()
        {
            using(var context = new ApplicationDbContext()){
                var faqs = context.Faq
                    .AsNoTracking()
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
                return context.MainTag.AsNoTracking().Include(m => m.ChildTags)
                    .Select(m => new MainTagDTO(m))
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
                    .AsNoTracking()
                    .Include(u => u.Role)
                    .Include(m => m.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .Where(u => u.UserID != ChatbotID)
                    .Select(user => new UserDTO(user)).ToList();

                return users;
            }
        }
        #endregion
        #region -   GetAdminUsers
        public static List<UserDTO> GetAdminUsers() {
            using(var context = new ApplicationDbContext()){
                return context.Users
                    .AsNoTracking()
                    .Include(u => u.Role)
                    .Include(u => u.AssignedTags)
                        .ThenInclude(a => a.MainTag)
                    .Where(user => (user.Role!.RoleName == "Admin" || user.Role!.RoleName == "Staff") && user.UserID != ChatbotID)
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

            var stopwatch = Stopwatch.StartNew();
            int? mainTagID = null;
            int? subTagID = null;
            int? priorityID = null;
            List<TicketHistory> histories = new();
            
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
                var priority = await context.Priorities.FirstOrDefaultAsync(p => p.PriorityName == Priority);
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
            histories.Add(new TicketHistory
            {
                TicketID = newTicket.TicketID,
                ActionID = 1,
                ActionMessage = "Ticket Created",
            });

            // Creates Ticket History if there is an assignedID
            if(AssignedID != 0)
            {
                histories.Add(new TicketHistory
                {
                    TicketID = newTicket.TicketID,
                    ActionID = 2,
                    ActionMessage = $"Ticket is automatically assigned to {context.Users.FirstOrDefault(u => u.UserID == AssignedID)!.FirstName} by Golden AI",
                });
            }
            

            // Updates the Chatroom with the TicketID
            var chatroom = context.Chatrooms.Where(c => c.ChatroomID == ChatroomID).FirstOrDefault();
            if (chatroom != null)
            {
                chatroom.TicketID = newTicket.TicketID;
            }
            
            context.TicketHistory.AddRange(histories);
            await context.SaveChangesAsync();
            stopwatch.Stop();
            Console.WriteLine($"Adding Ticket Successfull: {stopwatch.ElapsedMilliseconds} ms");


            return newTicket;
            }
        }
        #endregion
        #region -   GetTickets
        public static List<TicketDTO> GetTickets(int userID, bool isEmployee)
        {
            Console.WriteLine($"GetTickets(userID:{userID}, isEmployee:{isEmployee}) ran!");
            var stopwatch = Stopwatch.StartNew();
            using(var context = new ApplicationDbContext())
            {
                List<TicketDTO> ticketDTOs = new List<TicketDTO>();
                List<Tickets> ticketList = context.Tickets
                        .AsNoTracking()
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
                Console.WriteLine($"GetTickets(userID:{userID}, isEmployee:{isEmployee}) finish reading data at: {stopwatch.ElapsedMilliseconds} ms");
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
                Console.WriteLine($"GetTickets(int userID, bool isEmployee) sent successfully: {stopwatch.ElapsedMilliseconds} ms");
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
                    .AsNoTracking()
                    .Where(t => t.TicketID == ticketID)
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
                    .FirstOrDefault();
            }
        }
        #endregion
        #region -   UpdateTicket
        public async static Task<Tickets> UpdateTicket(int ticketID, string title, string statusName, string priorityName, string? MainTag, string? SubTag, int? assignedID, int EditorID)
        {
            var stopwatch = Stopwatch.StartNew();

            using (var context = new ApplicationDbContext())
            {
                string editorName = context.Users
                    .Where(u => u.UserID == EditorID)
                    .Select(u => u.FirstName + " " + u.LastName)
                    .FirstOrDefault()!;
                List<TicketHistory> histories = new();

                int statusID = await context.Status.Where(s => s.StatusName == statusName).Select(s => s.StatusID).FirstOrDefaultAsync();
                int priorityID = await context.Priorities.Where(p => p.PriorityName == priorityName).Select(p => p.PriorityID).FirstOrDefaultAsync();
                int? mainTagID = 0;
                int? subTagID = 0;
                
                if(MainTag != null)
                    mainTagID = context.MainTag.Include(m => m.ChildTags).Where(m => m.TagName == MainTag).Select(m => m.TagID).FirstOrDefault();
                if(SubTag != null)
                    subTagID = context.SubTag.Where(s => s.MainTagID == mainTagID! && s.TagName == SubTag).Select(s => s.TagID).FirstOrDefault();

                var newticket = context.Tickets.Where(t => t.TicketID == ticketID).Include(t => t.SubTag).Include(t => t.MainTag).FirstOrDefault();
                
                //TicketHistory Title Creation
                if (title != newticket!.TicketTitle)
                {
                    histories.Add(new TicketHistory {
                        TicketID = newticket.TicketID,
                        ActionID = 9,
                        ActionMessage = $"Ticket Title changed from {newticket.TicketTitle} to {title} by {editorName}"
                    });
                }
                                // TicketHistory Status Creation
                if (statusID != newticket.StatusID)
                {
                    int action = statusID switch {
                        1 => 8,
                        2 => 4,
                        3 => 5,
                        4 => 6,
                        5 => 7,
                        _ => 0
                    };

                    string message = statusID switch {
                        1 => $"Ticket Re-Opened by **{editorName}**",
                        2 => $"Ticket set In Progress by **{editorName}**",
                        3 => $"Ticket On Hold by **{editorName}**",
                        4 => $"Ticket Closed by **{editorName}**",
                        5 => $"Ticket set as Unresolved by **{editorName}**",
                        _ => ""
                    };

                    histories.Add(new TicketHistory {
                        TicketID = newticket.TicketID,
                        ActionID = action,
                        ActionMessage = message
                    });
                }
                
                // TicketHistory Priority Creation
                if(priorityID != newticket!.PriorityID)
                {
                    histories.Add(new TicketHistory
                    {
                        TicketID = newticket.TicketID,
                        ActionID = 12,
                        ActionMessage = $"Ticket Priority changed from {newticket!.Priority!.PriorityName} to {priorityName} by {editorName}",
                    });
                }
                
                // TicketHistory MainTag Creation
                if(mainTagID != newticket!.MainTagID)
                {
                    histories.Add(new TicketHistory {TicketID = newticket.TicketID, ActionID = 10, ActionMessage = (newticket!.MainTagID != null) ?
                        $"Ticket Maintag changed from {newticket!.MainTag!.TagName} to {MainTag} by {editorName}" :
                        $"Ticket Maintag changed to {MainTag} by {editorName}"}
                    );
                        
                }
                

                // TicketHistory SubTag Creation
                if(subTagID != newticket!.SubTagID)
                {
                    histories.Add(new TicketHistory{ TicketID = newticket.TicketID, ActionID = 11, ActionMessage = (newticket!.SubTagID != null) ? 
                        $"Ticket Subtag changed from {newticket!.SubTag?.TagName} to {SubTag} by {editorName}" : 
                        $"Ticket Subtag changed to {SubTag} by {editorName}"});
                }
                
                // TicketHistory Assign Creation
                if(assignedID != newticket!.AssignedID)
                {
                    var user = await context.Users.FindAsync(assignedID); // better than Where(...).FirstOrDefault()

                    if(newticket!.AssignedID == null)
                    {
                        histories.Add(new TicketHistory 
                        {
                            TicketID = newticket.TicketID,
                            ActionID = 2,
                            ActionMessage = $"Ticket Assigned to {user!.FirstName} by {editorName}",
                        });
                    } else {
                        histories.Add(new TicketHistory 
                        {
                            TicketID = newticket.TicketID,
                            ActionID = 3,
                            ActionMessage = $"Ticket Re-Assigned From {user!.FirstName} by {editorName}",
                        });
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

                if(statusName == "Closed") {
                    var chatroom = context.Chatrooms.Where(c => c.TicketID == ticketID).FirstOrDefault();
                    chatroom!.IsClosed = true;
                }
                context.TicketHistory.AddRange(histories);
                await context.SaveChangesAsync();
                stopwatch.Stop();
                Console.WriteLine($"Updated Ticket Successfull: {stopwatch.ElapsedMilliseconds} ms");

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
                        MemberID = ChatbotID,
                    }
                };
                context.GroupMembers.AddRange(members);
                await context.SaveChangesAsync();

                var aiMessage = new Message {
                    ChatroomID = newChat.ChatroomID,
                    SenderID = ChatbotID,
                    MessageContent = AIResponse.FirstMessage(true),
                };
                context.Messages.Add(aiMessage);
                await context.SaveChangesAsync();
                return newChat;
            }
        }
        #endregion
        #region -   CloseChatroom
        public async static Task<Chatroom> CloseChatroom(int chatroomID)
        {
            using(var context = new ApplicationDbContext())
            {
                var chatroom = context.Chatrooms.Where(c => c.ChatroomID == chatroomID).FirstOrDefault();
                chatroom!.IsClosed = true;
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
                var chatroom = context.Chatrooms.Where(c => c.ChatroomID == chatroomID).FirstOrDefault();
                chatroom!.IsClosed = false;
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
                var chatroom = context.Chatrooms.Where(c => c.ChatroomID == ChatroomID).FirstOrDefault();
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
                context.SaveChanges();
                var updatedChatroom = GetChatroom(ChatroomID, false);
                return new ChatroomDTO(updatedChatroom!);
            }
        }
        #endregion
        #region -   GetChatrooms
        public async static Task<List<ChatroomDTO>> GetChatrooms(int userID, bool isEmployee = false)
        {
            using(var context = new ApplicationDbContext())
            {
                Console.WriteLine($"GetChatrooms(userID:{userID}, {isEmployee}) ran!");
                var stopwatch = Stopwatch.StartNew();
                List<ChatroomDTO> dtos = new List<ChatroomDTO>();
                List<Chatroom> chatrooms = await ContextUtil.Chatrooms(context, false);
                Console.WriteLine($"GetChatrooms({userID}, {isEmployee}) finish reading data at: {stopwatch.ElapsedMilliseconds} ms");
                if(isEmployee){   
                    foreach(var chatroom in chatrooms.Where(c => c.AuthorID == userID)){
                        dtos.Add(new ChatroomDTO(chatroom));
                    }
                }else{
                    foreach(var chatroom in chatrooms.Where(c => c.TicketID != null)){
                        dtos.Add(new ChatroomDTO(chatroom));
                    }
                }
                stopwatch.Stop();
                Console.WriteLine($"GetChatrooms({userID}, {isEmployee}) sent successfully: {stopwatch.ElapsedMilliseconds} ms");
                return dtos;
            }
        }
        #endregion
        public async static Task<List<ChatroomDTO>> GetChatrooms(bool includeMessages = true)
        {
            var stopwatch = Stopwatch.StartNew();
            using(var context = new ApplicationDbContext())
            {
                List<ChatroomDTO> dtos = new List<ChatroomDTO>();
                List<Chatroom> chatrooms = await ContextUtil.Chatrooms(context, includeMessages);
                foreach(var chatroom in chatrooms.Where(c => c.TicketID != null)) {
                    dtos.Add(new ChatroomDTO(chatroom));
                }
                stopwatch.Stop();
                Console.WriteLine($"GetChatrooms() sent successfully: {stopwatch.ElapsedMilliseconds} ms");
                return dtos;
            }
        }
        #region -   GetChatroom
        public static Chatroom? GetChatroom(int ChatroomID, bool includeMessages = true)
        {
            var stopwatch = Stopwatch.StartNew();
            using (var context = new ApplicationDbContext())
            {
                var chatroom = ContextUtil.Chatroom(ChatroomID, context, includeMessages);
                stopwatch.Stop();
                Console.WriteLine($"GetChatroom(chatroomID:{ChatroomID}) sent successfully: {stopwatch.ElapsedMilliseconds} ms");
                return chatroom;
            }
        }
        #region -   GetChatroomByTicketID
        public static Chatroom? GetChatroomByTicketID(int TicketID, bool includeMessages = true)
        {
            var stopwatch = Stopwatch.StartNew();
            using (var context = new ApplicationDbContext())
            {
                var chatroom = ContextUtil.ChatroomByTicketID(TicketID, context, includeMessages);
                stopwatch.Stop();
                Console.WriteLine($"GetChatroom(chatroomID:{TicketID}) sent successfully: {stopwatch.ElapsedMilliseconds} ms");
                return chatroom;
            }
        }
        #endregion
        #endregion
        #region -   UpdateLastSeen
        public static async Task UpdateLastSeen(int UserID, int ChatroomID)
        {
            using(var context = new ApplicationDbContext())
            {
                var member = context.GroupMembers.Where(u=> u.MemberID == UserID && u.ChatroomID == ChatroomID).FirstOrDefault();
                if(member != null){
                    member.LastSeenAt = DateTime.Now;
                    await context.SaveChangesAsync();
                }
            }
        }
        #endregion
        #region -   SendMessage
        public async static Task<Message> SendMessage(int SenderID, int ChatroomID, string Message)
        {
            using(var context = new ApplicationDbContext())
            {
                var stopwatch = Stopwatch.StartNew();
                var message = new Message
                {
                    SenderID = SenderID,
                    ChatroomID = ChatroomID,
                    MessageContent = Message,
                };
                context.Messages.Add(message);
                await context.SaveChangesAsync();
                stopwatch.Stop();
                Console.WriteLine($"Adding Message Successfull: {stopwatch.ElapsedMilliseconds} ms");
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
                    .AsNoTracking()
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
        public async static Task<Rating> AddRating(int ChatroomID, int Score, string? Feedback)
        {
            var existingRating = GetRating(ChatroomID);
            if(existingRating == null)
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
                await context.SaveChangesAsync();
                return newRating;
            } else {
                return GetRating(ChatroomID)!;
            }
        }
        #endregion
        #region -   GetRatings
        public async static Task<List<RatingDTO>> GetRatings(int UserID)
        {
            var RatingList = new List<RatingDTO>();
            using (var context = new ApplicationDbContext())
            {
                var ratings = context.Rating
                    
                    .ToListAsync();
                foreach (var rating in await ratings)
                {
                    RatingList.Add(new RatingDTO(rating));
                }
                return RatingList;
            }
        }
        public async static Task<List<RatingDTO>> GetRatings()
        {
            Console.WriteLine($"GetRating() ran!");
            var stopwatch = Stopwatch.StartNew();
            var RatingList = new List<RatingDTO>();
            using (var context = new ApplicationDbContext())
            {
                var ratings = await ContextUtil.Ratings(context);
                if(ratings != null)
                {
                    Console.WriteLine($"GetRating() data read at: {stopwatch.ElapsedMilliseconds} ms");
                    foreach (var rating in ratings!)
                    {
                        RatingList.Add(new RatingDTO(rating));
                    }
                } 
                else Console.WriteLine($"[DBUtil] Rating table empty, no data found.");
                Console.WriteLine($"GetRating() sent successfully: {stopwatch.ElapsedMilliseconds} ms");
                return RatingList;
            }
        }
        #endregion
        #region -   GetRating
        public static Rating? GetRating(int ChatroomID)
        {
            using (var context = new ApplicationDbContext())
            {
                var rating = ContextUtil.Rating(ChatroomID, context);
                if(rating == null) Console.WriteLine($"[DBUtil] Rating with ChatroomID {ChatroomID} not found.");
                return rating;
            }
        }
        #endregion
        #region -   UpdateRating
        public async static Task<Rating?> UpdateRating(int chatroomID, int? score, string? feedback)
        {
            using (var context = new ApplicationDbContext())
            {
                var rating = context.Rating.FirstOrDefault(r => r.ChatroomID == chatroomID);
                if (rating == null)
                {
                    Console.WriteLine($"[DBUtil] Rating with Chatroom ID {chatroomID} not found.");
                    return null;
                }
                if (score.HasValue)
                {
                    rating.Score = score.Value;
                }
                if (!string.IsNullOrEmpty(feedback))
                {
                    rating.Feedback = feedback;
                }
                await context.SaveChangesAsync();
                return rating;
            }
        }
        #endregion
        #endregion
    }
}