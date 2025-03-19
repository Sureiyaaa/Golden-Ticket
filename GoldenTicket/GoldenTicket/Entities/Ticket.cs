using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblTickets")]
    public class Tickets
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TicketID { get; set; }
        
        [Required]
        public string? TicketTitle { get; set; }
        [Required]
        public int AuthorID { get; set; }

        [ForeignKey("AuthorID")]
        public User? Author { get; set; } = null;
        
        [Required]
        public int AssignedID { get; set; }

        [ForeignKey("AssignedID")]
        public User? Assigned { get; set; } = null;
        [Required]
        public int ChatroomID { get; set; }

        [ForeignKey("ChatroomID")]
        public Chatroom? Chatroom { get; set; } = null;
        [Required]
        public int StatusID { get; set; }

        [ForeignKey("StatusID")]
        public Status? Status { get; set; } = null;
        [Required]
        public int MainTagID { get; set; }

        [ForeignKey("MainTagID")]
        public MainTag? MainTag { get; set; } = null;
        [Required]
        public int SubTagID { get; set; }

        [ForeignKey("SubTagID")]
        public SubTag? SubTag { get; set; } = null;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? DeadlineAt {get;set;}
        public ICollection<GroupMember> Members { get; set; } = new List<GroupMember>();

        public ICollection<Message> Messages { get; set; } = new List<Message>();
    }
}
