using GoldenTicket.Database;
using System.Collections.Concurrent;
using GoldenTracker.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using GoldenTicket.Entities;


namespace GoldenTicket.Hubs
{
    public class GTHub : Hub
    {
        private static readonly ConcurrentDictionary<string, int> _connections = new ConcurrentDictionary<string, int>();
        public async Task Connect(int userId)
        {
            _connections[Context.ConnectionId] = userId;
            await Clients.All.SendAsync("UserConnected", _connections.Keys);
        }
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
            bool isEmployee = role == "Employee"; 
            await Clients.Caller.SendAsync("Online", new {tags = DBUtil.GetTags(), faq = DBUtil.GetFAQ(), users = DBUtil.GetUsersByRole(), chatrooms = DBUtil.GetChatrooms(userID, isEmployee)});
        }
        public async Task RequestChat(int AuthorID) {
            var chatroom = await DBUtil.AddChatroom(AuthorID);
            var adminUser = DBUtil.GetAdminUsers();
            var chatroomDTO = new ChatroomDTO(DBUtil.GetChatroom(chatroom.ChatroomID)!);
            foreach(var user in adminUser){
                if(user.Role == "Admin"){
                    var receiverConnectionId = _connections.FirstOrDefault(x => x.Value == user.UserID).Key; 
                    if(receiverConnectionId != null)
                    {
                        await Clients.Client(receiverConnectionId).SendAsync("ChatroomUpdate", new {chatroom = chatroomDTO});
                    }
                }
            }
            await Clients.Caller.SendAsync("ChatroomUpdate", new {chatroom =  chatroomDTO});
        }
        
    }
}
