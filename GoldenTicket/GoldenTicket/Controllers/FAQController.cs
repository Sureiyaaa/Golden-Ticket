using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Models;
using GoldenTicket.Utilities;
using GoldenTracker.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Controllers
{
     [Route("api/[controller]")]
    public class FAQController : Controller
    {
        [HttpGet("GetFAQs")]
        public IActionResult GetFAQs()
        {
            using(var context = new ApplicationDbContext()){
                
                var faqs = context.Faq.Include(f => f.MainTag).ThenInclude(m => m!.ChildTags).Select(f => new {
                    faqID = f.FaqID,
                    ticketTitle = f.TicketTitle,
                    description = f.Description,
                    createdAt = f.CreatedAt,
                    isArchived = f.IsArchived,
                    mainTag = f.MainTag,
                    subTag = f.SubTag
                }).ToList();

                return Ok(new {status = 200, message = "Processed successfully.", body = new { faqs =  faqs}}); 
            }
        }
        [HttpPost("AddFAQ")]
        public async Task<IActionResult> AddFAQ([FromBody] FAQ faq)
        {
            if (faq == null)
                return BadRequest("Invalid JSON");
            using(var _context = new ApplicationDbContext())
            {
                var newFAQ = new FAQ
                {
                    TicketTitle = faq.TicketTitle,
                    Description = faq.Description,
                    CreatedAt = DateTime.Now,
                    IsArchived = false,
                    MainTag = faq.MainTag,
                    SubTag = faq.SubTag
                };
                _context.Faq.Add(newFAQ);
                await _context.SaveChangesAsync();
                return Ok("FAQ added successfully");
            }
        }
    }
}