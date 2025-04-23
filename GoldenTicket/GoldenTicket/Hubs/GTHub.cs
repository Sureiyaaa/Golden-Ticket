using GoldenTicket.Database;
using System.Collections.Concurrent;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using GoldenTicket.Entities;
using GoldenTicket.Models;
using System.Diagnostics;


namespace GoldenTicket.Hubs
{
    public class GTHub : Hub
    {
        #region General



        private static readonly ConcurrentDictionary<int, HashSet<string>> _connections = new ConcurrentDictionary<int, HashSet<string>>();
        #region -   OnDisconnectedAsync
        #endregion
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            foreach (var entry in _connections)
            {
                if (entry.Value.Contains(Context.ConnectionId))
                {
                    entry.Value.Remove(Context.ConnectionId);
                    if (entry.Value.Count == 0)
                    {
                        _connections.TryRemove(entry.Key, out _);
                    }
                    break;
                }
            }
            Console.WriteLine($"[SignalR] User {Context.ConnectionId} disconnects");
            await base.OnDisconnectedAsync(exception);
        }


        #region -   Broadcast
        #endregion
        public async Task Broadcast(string message)
        {
            await Clients.All.SendAsync("Announce", message);
        }

        #region -   Online
        #endregion
        public async Task Online(int userID, string role)
        {
            _connections.AddOrUpdate(userID, new HashSet<string> { Context.ConnectionId },
                (key, existingSet) => 
                { 
                    existingSet.Add(Context.ConnectionId);
                    return existingSet;
                });

            Console.WriteLine($"[SignalR] User {userID} has connections: {string.Join(", ", _connections[userID])}");

            bool isEmployee = role == "Employee"; 
            await Clients.Caller.SendAsync("Online", new 
            {
                tags = DBUtil.GetTags(), 
                faq = DBUtil.GetFAQs(), 
                users = DBUtil.GetUsersByRole(), 
                chatrooms = await DBUtil.GetChatrooms(userID, isEmployee, true), 
                tickets = DBUtil.GetTickets(userID, isEmployee),
                status = DBUtil.GetStatuses(),
                priorities = DBUtil.GetPriorities(),
                ratings = await DBUtil.GetRatings(),
                notifications = await DBUtil.GetNotifications(userID)
            });
        }
        #region -   GetAvailableStaff
        #endregion
        public int? GetAvailableStaff(string? MainTagName)
        {
            if (!string.IsNullOrEmpty(MainTagName))
            {
                var adminUsers = DBUtil.GetAdminUsers()
                    .Where(user => (user.Role == "Admin" || user.Role == "Staff") && user.AssignedTags!.Any(tag => tag == MainTagName))
                    .ToList();
                var onlineStaff = adminUsers
                    .Where(user => _connections.ContainsKey(user.UserID))
                    .ToList();
                if (onlineStaff.Any())
                {
                    var availableStaff = onlineStaff
                    .OrderBy(user => DBUtil.GetTickets(user.UserID, false).Count)
                    .FirstOrDefault();

                    if (availableStaff != null)
                    {
                        return availableStaff.UserID;
                    }
                }
            }
            return null; // Return empty string if no staff is available
        }
        #endregion
        #region User




        #region -   UpdateUser
        #endregion
        public async Task UpdateUser(int _userID, string? _username, string? _firstname, string? _middlename, string? _lastname, string? _role, List<string?> _assignedTags, string? Password)
        {
            var updatedUser = await DBUtil.UpdateUser(_userID, _username, _firstname, _middlename, _lastname, _role, _assignedTags);
            if(updatedUser != null)
            {
                if (Password != null && Password != ""){
                    await DBUtil.ChangePassword(_userID, Password);
                }

                var adminUser = DBUtil.GetAdminUsers();
                foreach(var user in adminUser) {
                    if(user.Role == "Admin" || user.Role == "Staff" || user.UserID == _userID){
                        if (_connections.TryGetValue(user.UserID, out var connectionIds)){
                            foreach (var connectionId in connectionIds)
                            {
                                await Clients.Client(connectionId).SendAsync("UserUpdate", new {user = new UserDTO(updatedUser)});
                            }
                        }
                    }
                }
            }
        }
        #region -   AddUser
        #endregion
        public async Task AddUser(string Username, string Password, string FirstName, string? MiddleName, string LastName, string Role, List<string?> AssignedTags)
        {
            var newUser = await DBUtil.AddUser(Username, Password, FirstName, MiddleName, LastName, Role, AssignedTags);
            if(newUser == null)
            {
                await Clients.Caller.SendAsync("UserExist");
                return;
            }
            var adminUser = DBUtil.GetAdminUsers();
            foreach(var user in adminUser){
                if(user.Role == "Admin" || user.Role == "Staff"){
                    if (_connections.TryGetValue(user.UserID, out var connectionIds)){
                        foreach (var connectionId in connectionIds)
                        {
                            await Clients.Client(connectionId).SendAsync("UserUpdate", new {user = new UserDTO(newUser)});
                        }
                    }
                }
            }
        }
        #endregion
        #region FAQ




        #region -   AddFAQ
        #endregion
        public async Task AddFAQ(string Title, string Description, string Solution, string MainTagName, string SubTagName) 
        {
            DBUtil.AddFAQ(Title, Description, Solution, MainTagName, SubTagName);
            await Clients.All.SendAsync("FAQUpdate", new {faq = DBUtil.GetFAQs()});
        }
        #region -   UpdateFAQ
        #endregion
        public async Task UpdateFAQ(int faqID, string Title, string Description, string Solution, string Maintag, string Subtag, bool IsArchived)
        {
            await DBUtil.UpdateFAQ(faqID,Title, Description, Solution, Maintag, Subtag, IsArchived);
            await Clients.All.SendAsync("FAQUpdate", new {faq = DBUtil.GetFAQs()});
        }
        #endregion
        #region Chatroom




        #region -   RequestChat
        #endregion
        public async Task RequestChat(int AuthorID) 
        {
            var chatrooms = await DBUtil.GetChatrooms(AuthorID, true);
            int openChatroomsCount = chatrooms.Count(c => c.Ticket == null && c.IsClosed == false);
            if (openChatroomsCount >= 3)
            {
                await Clients.Caller.SendAsync("MaximumChatroom");
                return;
            }

            var chatroom = await DBUtil.AddChatroom(AuthorID);
            var adminUser = DBUtil.GetAdminUsers();
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(chatroom.ChatroomID)!, true);
            var chatroomDTOAdmin = new ChatroomDTO(DBUtil.GetChatroom(chatroom.ChatroomID, false)!);

            await Clients.Caller.SendAsync("ReceiveSupport", new { chatroom = chatroomDTO });
        }

        #region -   ResolveTickets
        #endregion
        public async void ResolveTickets(List<ChatroomDTO> Chatrooms)
        {
            if(Chatrooms == null || Chatrooms.Count() == 0) 
            {
                Console.WriteLine("[GTHub] [ResolveTickets] Chatrooms received is empty!");
                return;
            }
            foreach (var Chatroom in Chatrooms)
            {
                if (Chatroom.ChatroomID == null)
                {
                    continue;
                }
                int chatroomID = Chatroom.ChatroomID ?? 0;
                await CloseMessage(chatroomID);
                await DBUtil.CloseChatroom(chatroomID);
                Console.WriteLine($"[GTHub] Chatroom ID: {Chatroom.ChatroomID} by {Chatroom.Author!.FirstName} has been closed!");
                foreach (var member in Chatroom.GroupMembers)
                {
                    if (_connections.TryGetValue(member.User.UserID, out var connectionIds))
                    {
                        foreach (var connectionId in connectionIds)
                        {
                            await Clients.Client(connectionId).SendAsync("ChatroomUpdate", new { chatroom = Chatroom });
                        }
                    }
                }
            }
        }

        #region -   CloseChatroom
        #endregion
        public async Task CloseChatroom(int ChatroomID)
        {
            var chatroom = await DBUtil.CloseChatroom(ChatroomID);
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(chatroom.ChatroomID)!);
            await Clients.Caller.SendAsync("ChatroomUpdate", new { chatroom = chatroomDTO });
            int callerID = _connections.FirstOrDefault(kvp => kvp.Value.Contains(Context.ConnectionId)).Key;
            string userName = DBUtil.FindUser(callerID).FirstName!;
            if(chatroom.Ticket != null)
                NotifyUser(chatroom.Ticket!.AssignedID!.Value, 2, $"{userName} has closed the chatroom!", $"{userName} has closed the chatroom and is now ready for rating", ChatroomID);
            else
                NotifyUser(chatroom.Author!.UserID, 2, "Chatroom Closed", "The chatroom has been successfully closed. Thank you for using our service! If you have further questions or need assistance, feel free to reach out again.", ChatroomID);
        }

        #region -   JoinChatroom
        #endregion
        public async Task JoinChatroom(int UserID, int ChatroomID)
        {
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(ChatroomID, false)!);
            if (chatroomDTO!.GroupMembers.Any(m => m.User.UserID == UserID))
            {
                await Clients.Caller.SendAsync("AlreadyMember");
                return;
            }
            chatroomDTO = DBUtil.JoinChatroom(UserID, ChatroomID);
            var userDTO = new UserDTO(DBUtil.FindUser(UserID));
            List<int> userIDList = new List<int>();
            string userName = DBUtil.FindUser(UserID).FirstName!;
            foreach(var member in chatroomDTO.GroupMembers)
            {
                if(UserID != member.User.UserID)
                    userIDList.Add(member.User.UserID);
                if (_connections.TryGetValue(member.User.UserID, out var connectionIds)){
                    foreach (var connectionId in connectionIds)
                    {
                        await Clients.Client(connectionId).SendAsync("StaffJoined", new {user = userDTO, chatroom = chatroomDTO});
                    }
                }
            }
            NotifyGroup(userIDList, 2, $"{userName} has joined the chatroom!", $"A staff has joined the chatroom", ChatroomID);
        }
        #region -   OpenChatroom
        #endregion
        public async Task OpenChatroom(int UserID, int ChatroomID) 
        {
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(ChatroomID)!, true);
            
            await Clients.Caller.SendAsync("ReceiveMessages", new {chatroom = chatroomDTO});
            await UserSeen(UserID, ChatroomID);
        }
        #region -   UserSeen
        #endregion
        public async Task UserSeen(int UserID, int ChatroomID) 
        {
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(ChatroomID, false)!);
            await DBUtil.UpdateLastSeen(UserID, ChatroomID);
            foreach(var member in chatroomDTO.GroupMembers)
            {
                if (_connections.TryGetValue(member.User.UserID, out var connectionIds)){
                    foreach (var connectionId in connectionIds)
                    {
                        await Clients.Client(connectionId).SendAsync("UserSeen", new {userID = UserID, chatroomID = ChatroomID});
                    }
                }
            }
        }
        #region -   SendMessage
        #endregion
        public async Task SendMessage(int SenderID, int ChatroomID, string Message) 
        {
            if(_connections == null || _connections.Count() == 0) 
            {
                Console.WriteLine("[GTHub] [SendMessage] _connections is empty!");
                return;
            }
            var connectedUsers = _connections.Where(kvp => kvp.Value.Contains(Context.ConnectionId)).ToList();
            if (connectedUsers.Count == 0)
            {
                Console.WriteLine($"[SignalR] Connection {Context.ConnectionId} is no longer active.");
                return; // Return early if the connection is not valid
            }
            
            var message = await DBUtil.SendMessage(SenderID, ChatroomID, Message);
            // await UserSeen(SenderID, ChatroomID);

            var messageDTO = new MessageDTO(DBUtil.GetMessage(message.MessageID)!);
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(ChatroomID, false)!);
            var MembersToInvoke = new List<int>();
            
            foreach(var member in chatroomDTO.GroupMembers){
                MembersToInvoke.Add(member.User.UserID);
            }

            if(chatroomDTO.Ticket != null)
            {
                var adminUser = DBUtil.GetAdminUsers();
                foreach(var user in adminUser){
                    if(!MembersToInvoke.Contains(user.UserID)){
                        MembersToInvoke.Add(user.UserID);
                    }
                }
            }
            foreach(int memberID in MembersToInvoke){
                if (_connections.TryGetValue(memberID, out var connectionIds)){
                    foreach (var connectionId in connectionIds)
                    {
                        await Clients.Client(connectionId).SendAsync("ReceiveMessage", new {chatroom = chatroomDTO, message = messageDTO});
                        Console.WriteLine("Yes");
                    }
                }
            }

            // Notification System here brotah
            // if(chatroomDTO.Ticket != null && SenderID != AIUtil.GetChatbotID())
            // {
            //     MembersToInvoke.Remove(SenderID);
            //     NotifyGroup(MembersToInvoke, 2, $"{messageDTO.Sender!.FirstName} sent a Message", messageDTO.MessageContent!, ChatroomID);
            // }

            if(chatroomDTO.Ticket == null && SenderID != 100000001)
            {
                await AISendMessage(ChatroomID, Message, SenderID);
            }
        }
        #region -   AISendMessage
        #endregion
        public async Task AISendMessage(int chatroomID, string userMessage, int userID) 
        {
            int ChatbotID = AIUtil.GetChatbotID();
            var response = await AIUtil.GetJsonResponseAsync(chatroomID.ToString(), userMessage, userID);
            if (response == null)
            {
                response = AIResponse.Unavailable();
            }
          
            var message = await DBUtil.SendMessage(ChatbotID, chatroomID, response!.Message);
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(chatroomID, false)!);
            var messageDTO = new MessageDTO(DBUtil.GetMessage(message.MessageID)!);
            foreach(var member in chatroomDTO.GroupMembers){
                if(member.User.UserID == userID){
                    if (_connections.TryGetValue(userID, out var connectionIds)){
                        foreach (var connectionId in connectionIds)
                        {
                            await Clients.Client(connectionId).SendAsync("ReceiveMessage", new {chatroom = chatroomDTO, message = messageDTO});
                            Console.WriteLine("Wow");
                            await Clients.Client(connectionId).SendAsync("AllowMessage");
                        }
                    }
                }
            }
            if(chatroomDTO.Ticket == null)
            {
                if(response.CallAgent)
                {
                    if (_connections.TryGetValue(userID, out var connectionIds)){
                        if (response.MainTag != null || response.MainTag != "" || response.MainTag != "null")
                        {
                            int StaffID = GetAvailableStaff(response.MainTag) ?? 0;
                            if(StaffID != 0)
                            {
                                await AddTicket(response.Title, userID, response.MainTag!, response.SubTags, response.Priority, chatroomID, StaffID);
                                var StaffUser = DBUtil.FindUser(StaffID);
                                await SendMessage(ChatbotID, chatroomID, $"Your ticket has been created! Your issue has been assigned to **{StaffUser.FirstName} {StaffUser.LastName}**.");
                                
                            } else {
                                await AddTicket(response.Title, userID, response.MainTag!, response.SubTags, response.Priority, chatroomID);
                                await SendMessage(ChatbotID, chatroomID, $"Your ticket has been created! There are currently no online agent for your specific problem, please be patient and wait for a **Live Agent** to accept.");
                            }
                        } else {
                            await AddTicket(response.Title, userID, response.MainTag!, response.SubTags, response.Priority, chatroomID);
                            await SendMessage(ChatbotID, chatroomID, $"Your ticket has been created! Its status has been set to **\"Open\"** and is now waiting for a **Live Agent** to accept your ticket.");
                        }
                        
                        foreach (var connectionId in connectionIds)
                        {
                            chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(chatroomID, false)!);
                            await Clients.Client(connectionId).SendAsync("AllowMessage");
                        }
                    }
                }
            }
            
            await UserSeen(ChatbotID, chatroomID);
        }
        #endregion
        #region Tags




        #region -   AddMainTag
        #endregion
        public async Task AddMainTag(string TagName)
        {
            if(DBUtil.AddMainTag(TagName))
                await Clients.All.SendAsync("TagUpdate", new {tags = DBUtil.GetTags()});
            else
                await Clients.Caller.SendAsync("ExistingTag");
        }
        #region -   AddSubTag
        #endregion
        public async Task AddSubTag(string TagName, string MainTagName)
        {
            if(DBUtil.AddSubTag(TagName, MainTagName))
                await Clients.All.SendAsync("TagUpdate", new {tags = DBUtil.GetTags()});
            else
                await Clients.Caller.SendAsync("ExistingTag");
        }
        #endregion
        #region Ticket




        #region -   AddTicket
        #endregion
        public async Task AddTicket(string TicketTitle, int AuthorID, string MainTagName, string SubTagName, string Priority, int ChatroomID, int? AssignedID = 0)
        {
            var newTicket = await DBUtil.AddTicket(TicketTitle, AuthorID, MainTagName, SubTagName, Priority, ChatroomID, AssignedID);
            if (newTicket == null)
            {
                return;
            }
            var ticketDTO = new TicketDTO(DBUtil.GetTicket(newTicket.TicketID)!);
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(ChatroomID)!);
            var adminUser = DBUtil.GetAdminUsers();
            var adminUserID = new List<int>();
            foreach(var user in adminUser){
                if(user.Role == "Admin" || user.Role == "Staff")
                {
                    adminUserID.Add(user.UserID);
                    if (_connections.TryGetValue(user.UserID, out var connectionIds)){
                        foreach (var connectionId in connectionIds)
                        {
                            await Clients.Client(connectionId).SendAsync("TicketUpdate", new {ticket = ticketDTO});
                            await Clients.Client(connectionId).SendAsync("ChatroomUpdate", new {chatroom = chatroomDTO});
                        }
                    }
                }
            }
            await Clients.Caller.SendAsync("TicketUpdate", new {ticket = ticketDTO});
            await Clients.Caller.SendAsync("ChatroomUpdate", new {chatroom = chatroomDTO});
            if (AssignedID != null && AssignedID != 0)
                NotifyUser(AssignedID!.Value, 1, "New Ticket Assigned to you", $"You have been assigned to a new ticket! Ticket ID: {ticketDTO.TicketID}", ticketDTO.TicketID);
            else 
                NotifyGroup(adminUserID, 1, "New Open Ticket", $"A new ticket has been created! Ticket ID: {ticketDTO.TicketID}", ticketDTO.TicketID);
        }
        #region -   UpdateTicket
        #endregion
        public async Task UpdateTicket(int TicketID, string Title, string Status, string Priority, string? MainTag, string? SubTag, int? AssignedID)
        {
            
            var stopwatch = Stopwatch.StartNew();
            int EditorID = _connections.FirstOrDefault(kvp => kvp.Value.Contains(Context.ConnectionId)).Key;

            var updatedTicket = await DBUtil.UpdateTicket(TicketID, Title, Status, Priority, MainTag, SubTag, AssignedID, EditorID);
            var ticketDTO = new TicketDTO(DBUtil.GetTicket(TicketID)!);
            
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroomByTicketID(TicketID)!);
            int chatroomID = chatroomDTO?.ChatroomID ?? throw new InvalidOperationException("ChatroomID cannot be null.");

            // Chatroom Close
            if(Status == "Closed")
            {
                await DBUtil.CloseChatroom(chatroomID);
                chatroomDTO = new ChatroomDTO(DBUtil.GetChatroomByTicketID(TicketID, false)!);
                await CloseMessage(chatroomID);
            }
            // Chatroom Reopen
            if(Status == "Open")
            {
                await DBUtil.ReopenChatroom(chatroomID);
                chatroomDTO = new ChatroomDTO(DBUtil.GetChatroomByTicketID(TicketID, false)!);
            }
            // Chatroom Reopen
            if(Status == "In Progress")
            {
                await DBUtil.ReopenChatroom(chatroomID);
                chatroomDTO = new ChatroomDTO(DBUtil.GetChatroomByTicketID(TicketID, false)!);
            }

            var adminUser = DBUtil.GetAdminUsers();
            foreach (var user in adminUser)
            {
                if (user.Role == "Admin" || user.Role == "Staff")
                {
                    if (_connections.TryGetValue(user.UserID, out var connectionIds))
                    {
                        foreach (var connectionId in connectionIds)
                        {
                            await Clients.Client(connectionId).SendAsync("TicketUpdate", new { ticket = ticketDTO });
                            await Clients.Client(connectionId).SendAsync("ChatroomUpdate", new { chatroom = chatroomDTO });
                        }
                    }
                }
            }
            
            foreach (var member in chatroomDTO!.GroupMembers)
            {
                if (_connections.TryGetValue(member.User.UserID, out var connectionIds))
                {
                    foreach (var connectionId in connectionIds)
                    {
                        Console.WriteLine($"Broadcasted to User ID:{connectionId}");
                        await Clients.Client(connectionId).SendAsync("TicketUpdate", new { ticket = ticketDTO });
                        await Clients.Client(connectionId).SendAsync("ChatroomUpdate", new { chatroom = chatroomDTO });
                    }
                }
            }
            stopwatch.Stop();
            Console.WriteLine($"Ticket Repsonsetime: {stopwatch.ElapsedMilliseconds} ms");

            List<int> userIDList = new List<int>();
            string EditorName = DBUtil.FindUser(EditorID).FirstName!;
            foreach(var member in chatroomDTO.GroupMembers)
            {
                if (EditorID != member.User.UserID)
                    userIDList.Add(member.User.UserID);
            }

            // Notification system
            switch(Status)
            {
                case "Open":
                    NotifyGroup(userIDList, 1, $"Ticket {TicketID} Re-Opened!", $"Your ticket has been Re-Opened by {EditorName}.", TicketID);
                    break;
                case "Closed":
                    NotifyGroup(userIDList, 1, $"Ticket {TicketID} Closed!", $"Your ticket has been Close by {EditorName}.", TicketID);
                    break;
                case "In Progress":
                    NotifyGroup(userIDList, 1, $"Ticket {TicketID} In Progress", $"Your ticket has been assigned to {chatroomDTO.Ticket!.Assigned!.FirstName}.", TicketID);
                    break;
                case "Unresolved":
                    NotifyGroup(userIDList, 1, $"Ticket {TicketID} Unresolved", $"Your ticket has been mark as Unresolved.", TicketID);
                    break;
                case "Postponed":
                    NotifyGroup(userIDList, 1, $"Ticket {TicketID} In Progress", $"Your ticket has been Postponed.", TicketID);
                    break;
                default:
                    NotifyGroup(userIDList, 1, $"Ticket updated!", $"Your ticket has been updated by {EditorName}", TicketID);
                    break;
            }
            
        }
        #region -   OpenTicket
        #endregion
        public async Task OpenTicket(int TicketID)
        {
            var ticketDTO = new TicketDTO(DBUtil.GetTicket(TicketID)!);
            await Clients.Caller.SendAsync("TicketUpdate", new {ticket = ticketDTO});
        }
        #region -   CloseMessage
        #endregion
        public async Task CloseMessage(int ChatroomID) {
            string message = "Your ticket has been resolved! Thank you for your patience! It would really help us if you rate your experience, your feedback would really be appreciated!";
            await SendMessage(AIUtil.GetChatbotID(), ChatroomID, message);
        }
        #endregion 
        #region Rating




        #region -   GetRating
        #endregion
        public async Task GetRating(int ChatroomID)
        {
            var ratingDTO = DBUtil.GetRating(ChatroomID);
            await Clients.Caller.SendAsync("RatingReceived", new { rating = ratingDTO });
        }
        #region -   AddOrUpdateRating
        #endregion
        public async Task AddOrUpdateRating(int ChatroomID, int Score, string? Feedback)
        {
            var existingRating = DBUtil.GetRating(ChatroomID);
            var rating = new Rating();
            if(existingRating != null)
            {
                rating = await DBUtil.UpdateRating(ChatroomID, Score, Feedback);
            }
            else
            {
                rating = await DBUtil.AddRating(ChatroomID, Score, Feedback);
            }
            
            var ratingDTO = new RatingDTO(DBUtil.GetRating(rating!.ChatroomID)!);
            var adminUser = DBUtil.GetAdminUsers();
            foreach (var user in adminUser)
            {
                if (user.Role == "Admin" || user.Role == "Staff")
                {
                    if (_connections.TryGetValue(user.UserID, out var connectionIds))
                    {
                        foreach (var connectionId in connectionIds)
                        {
                            await Clients.Client(connectionId).SendAsync("RatingReceived", new { rating = ratingDTO });
                        }
                    }
                }
            }
            await Clients.Caller.SendAsync("RatingReceived", new { rating = ratingDTO });
            if(ratingDTO.Chatroom.Ticket != null)
            {
                NotifyUser(ratingDTO.Chatroom.Ticket.Assigned!.UserID, 2, $"{ratingDTO.Chatroom.Author!.FirstName} has rated you {ratingDTO.Score}/5", $"{ratingDTO.Chatroom.Author!.FirstName} has rated your performance at Ticket ID: {ratingDTO.Chatroom.Ticket.TicketID}", ratingDTO.Chatroom.ChatroomID);
            }
        }
        #endregion 
        #region Notification




        #region -   NotifyGroup
        #endregion
        public async void NotifyGroup (List<int> userList, int notifType, string title, string description, int? referenceID)
        {
            var notifications = await DBUtil.NotifyGroup(userList, notifType, title, description, referenceID);
            var notifList = notifications.Select(n => n.Value.NotificationID).ToList();
            var notificationDTOs = await DBUtil.GetNotification(notifList);
            foreach(var userID in userList)
            {
                var newNotif = notifications.Where(n => n.Key == userID).FirstOrDefault().Value;
                if (_connections.TryGetValue(userID, out var connectionIds))
                {
                    foreach (var connectionId in connectionIds)
                    {
                        await Clients.Client(connectionId).SendAsync("NotificationReceived", new { notification =  new NotificationDTO(notificationDTOs[userID])} );
                    }
                }
            }
        }
        #region -   NotifyUser
        #endregion
        public async void NotifyUser (int userID, int notifType, string title, string description, int? referenceID)
        {
            var newNotif = await DBUtil.NotifyUser(userID, notifType, title, description, referenceID);
            var notification = await DBUtil.GetNotification(newNotif.NotificationID);
            if (notification == null)
            {
                Console.WriteLine($"[GTHub] Notification with ID {newNotif.NotificationID} not found.");
                return;
            }
            var newNotifDTO = new NotificationDTO(notification);
            if (_connections.TryGetValue(userID, out var connectionIds))
            {
                foreach (var connectionId in connectionIds)
                {
                    await Clients.Client(connectionId).SendAsync("NotificationReceived", new { notification = newNotifDTO} );
                }
            }
        }
        #region -   ReadNotification
        #endregion
        public async void ReadNotification(List<int> NotificationID, int UserID)
        {
            await DBUtil.ReadNotification(NotificationID);
            List<NotificationDTO> newNotifDTO = await DBUtil.GetNotifications(UserID);
            if (_connections.TryGetValue(UserID, out var connectionIds))
            {
                foreach (var connectionId in connectionIds)
                {
                    await Clients.Client(connectionId).SendAsync("NotificationListReceived", new { notification = newNotifDTO} );
                }
            }
            
        }
        #region -   DeleteNotification
        #endregion
        public async void DeleteNotification(List<int> NotificationID, int UserID)
        {
            await DBUtil.DeleteNotification(NotificationID);
            if (_connections.TryGetValue(UserID, out var connectionIds))
            {
                foreach (var connectionId in connectionIds)
                {
                    await Clients.Client(connectionId).SendAsync("NotificationListRemoved", new { notification = NotificationID } );
                }
            }
        }
        #endregion
    }
}
