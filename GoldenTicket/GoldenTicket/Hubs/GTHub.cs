using GoldenTicket.Database;
using System.Collections.Concurrent;
using GoldenTicket.Utilities;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using GoldenTicket.Entities;


namespace GoldenTicket.Hubs
{
    public class GTHub : Hub
    {
        private static readonly ConcurrentDictionary<string, int> _connections = new ConcurrentDictionary<string, int>();
        public override Task OnDisconnectedAsync(Exception? exception)
        {
            _connections.TryRemove(Context.ConnectionId, out int userId);
            return base.OnDisconnectedAsync(exception);
        }
        public async Task AddMainTag(string TagName)
        {
            DBUtil.AddMainTag(TagName);
            await Clients.All.SendAsync("TagUpdate", new {tags = DBUtil.GetTags()});
        }
        public async Task AddSubTag(string TagName, string MainTagName)
        {
            DBUtil.AddSubTag(TagName, MainTagName);
            await Clients.All.SendAsync("TagUpdate", new {tags = DBUtil.GetTags()}); 
        }
        
        public async Task Broadcast(string message)
        {
            await Clients.All.SendAsync("Announce", message);
        }

        public async Task Online(int userID, string role){
            _connections[Context.ConnectionId] = userID;
            bool isEmployee = role == "Employee"; 
            await Clients.Caller.SendAsync("Online", new {tags = DBUtil.GetTags(), faq = DBUtil.GetFAQ(), users = DBUtil.GetUsersByRole(), chatrooms = DBUtil.GetChatrooms(userID, isEmployee)});
        }
        public async Task RequestChat(int AuthorID) {
            int openChatroomsCount = DBUtil.GetChatrooms(AuthorID, true).Count(c => c.Ticket == null);
            if (openChatroomsCount >= 3)
            {
                await Clients.Caller.SendAsync("MaximumChatroom");
                return;
            }

            var chatroom = await DBUtil.AddChatroom(AuthorID);
            var adminUser = DBUtil.GetAdminUsers();
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(chatroom.ChatroomID)!, true);
            var chatroomDTOAdmin = new ChatroomDTO(DBUtil.GetChatroom(chatroom.ChatroomID)!);

            foreach(var user in adminUser){
                if(user.Role == "Admin" || user.Role == "Staff"){
                    var receiverConnectionId = _connections.FirstOrDefault(x => x.Value == user.UserID).Key; 
                    if(receiverConnectionId != null)
                    {
                        await Clients.Client(receiverConnectionId).SendAsync("ChatroomUpdate", new {chatroom = chatroomDTOAdmin});
                    }
                }
            }
            await Clients.Caller.SendAsync("ReceiveSupport", new {chatroom =  chatroomDTO});
        }
        public async Task OpenChatroom(int UserID, int ChatroomID) 
        {
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(ChatroomID)!, true);
            await UserSeen(UserID, ChatroomID);
            await Clients.Caller.SendAsync("ReceiveMessages", new {chatroom = chatroomDTO});
        }
        public async Task UserSeen(int UserID, int ChatroomID) 
        {
            var chatroomDTO = DBUtil.GetChatroom(ChatroomID);
            DBUtil.UpdateLastSeen(UserID, ChatroomID);
            foreach(var member in chatroomDTO!.Members){
                var receiverConnectionId = _connections.FirstOrDefault(x => x.Value == member.MemberID).Key; 
                if(receiverConnectionId != null)
                {
                    await Clients.Client(receiverConnectionId).SendAsync("UserSeen", new {UserID = UserID, ChatroomID = ChatroomID});
                }
            }
        }
        public async Task SendMessage(int SenderID, int ChatroomID, string Message) 
        {
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(ChatroomID)!);
            var message = await DBUtil.SendMessage(SenderID, ChatroomID, Message);
            var messageDTO = new MessageDTO(message);
            foreach(var member in chatroomDTO.GroupMembers){
                var receiverConnectionId = _connections.FirstOrDefault(x => x.Value == member.User.UserID).Key; 
                if(receiverConnectionId != null)
                {
                    await Clients.Client(receiverConnectionId).SendAsync("ReceiveMessage", new {chatroom = chatroomDTO, message = messageDTO});
                }
            }
            await UserSeen(SenderID, ChatroomID);
        }
        //MaximumChatroom
    }
}
