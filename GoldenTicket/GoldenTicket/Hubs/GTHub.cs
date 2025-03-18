using Microsoft.AspNetCore.SignalR;

namespace GoldenTicket.Hubs
{
    public class GTHub : Hub
    {
        public async Task Broadcast(string message)
        {
            await Clients.All.SendAsync("Announce", message);
        }
    }
}
