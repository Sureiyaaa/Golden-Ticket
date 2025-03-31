using GoldenTicket.Database;
using GoldenTicket.Hubs;
using GoldenTicket.Utilities;
using Hangfire;
using Microsoft.EntityFrameworkCore;
namespace GoldenTicket.Extensions
{
    public class HangFireService
    {
        private readonly IRecurringJobManager _recurringJobManager;
        private readonly IServiceScopeFactory _serviceScopeFactory;

        public HangFireService(IRecurringJobManager recurringJobManager, IServiceScopeFactory serviceScopeFactory)
        {
            _recurringJobManager = recurringJobManager;
            _serviceScopeFactory = serviceScopeFactory;
        }
        public void InitializeRecurringJobs()
        {
            RecurringJob.AddOrUpdate(
                "Resolve-Chats",
                () => ExecuteChatResolveAsync(),
                Cron.Daily // Runs once per day
            );
        }

       
        public async Task ExecuteChatResolveAsync()
        {
            DateTime threeDaysAgo = DateTime.UtcNow.AddDays(-3);
            using(var context = new ApplicationDbContext()){
                var filter = DBUtil.GetChatrooms();
                var chatrooms = filter
                    .Where(c => c.Messages!.Any()) // Only chatrooms that have messages
                    .Select(c => new
                    {
                        Chatroom = c,
                        LatestMessage = c.Messages!.OrderByDescending(m => m.CreatedAt).FirstOrDefault()
                    })
                    .Where(c => c.LatestMessage != null && c.LatestMessage.CreatedAt <= threeDaysAgo && c.Chatroom.Ticket == null)
                    .Select(c => c.Chatroom)
                    .ToList();
                
                using (var hub = new GTHub()){
                    await hub.ResolveTickets(chatrooms);
                }
            }
        }
    }
}
