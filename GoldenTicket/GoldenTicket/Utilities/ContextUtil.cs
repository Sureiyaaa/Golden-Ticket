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
    }
}