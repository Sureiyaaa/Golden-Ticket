using System.Collections.Concurrent;
using GoldenTracker.Models;
using Microsoft.AspNetCore.SignalR;

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
        
        public async Task Broadcast(string message)
        {
            await Clients.All.SendAsync("Announce", message);
        }

        public async Task Online(){
           await Clients.Caller.SendAsync("Online", new {tags = DBUtil.GetTags(), faq = DBUtil.GetFAQ()});
        }
    }
}
