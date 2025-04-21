using System.Diagnostics;
using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Utilities
{
    public class ContextUtil 
    {
        public async static Task<List<Chatroom>> Chatrooms(ApplicationDbContext context, bool includeMessages = false)
        {
            return await context.Chatrooms
                .BuildBaseChatroomQuery(includeMessages)
                .ToListAsync();
        }
        public static Chatroom? Chatroom(int ChatroomID, ApplicationDbContext context, bool includeMessages = false)
        {
            return context.Chatrooms
                .BuildBaseChatroomQuery(includeMessages)
                .Where(c => c.ChatroomID == ChatroomID)
                .FirstOrDefault();
        }
        public static Chatroom? ChatroomByTicketID(int? ticketID, ApplicationDbContext context, bool includeMessages = false)
        {
            return context.Chatrooms
                .BuildBaseChatroomQuery(includeMessages)
                .Where(c => ticketID == null ? c.TicketID == null : c.TicketID == ticketID)
                .FirstOrDefault();
        }
        public static Message? Message (int MessageID, ApplicationDbContext context) 
        {
            return context.Messages
                    .BuildBaseMessageQuery()
                    .Where(m => m.MessageID == MessageID)
                    .FirstOrDefault();
        }
        public async static Task<List<Rating>> Ratings(ApplicationDbContext context)
        {
            return await context.Rating
                .BuildBaseRatingQuery()
                .ToListAsync();
        }

        public static Rating? Rating(int ChatroomID, ApplicationDbContext context)
        {
            return context.Rating
                .BuildBaseRatingQuery()
                .Where(r => r.ChatroomID == ChatroomID)
                .FirstOrDefault();
        }

        public async static Task<List<Notification>> Notifications (int userID, ApplicationDbContext context)
        {
            return await context.Notifications
                .BuildBaseNotificationQuery()
                .Where(n => n.UserID == userID)
                .ToListAsync();
        }
        public async static Task<List<Notification>> Notifications (List<int> userIDs, ApplicationDbContext context)
        {
            return await context.Notifications
            .BuildBaseNotificationQuery()
            .Where(n => userIDs.Contains(n.UserID))
            .ToListAsync();
        }
    }
}