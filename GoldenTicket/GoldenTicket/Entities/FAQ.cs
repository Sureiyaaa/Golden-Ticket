using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace GoldenTicket.Entities
{
    [Table("tblFAQ")]
    public class FAQ
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int FaqID { get; set; }
        
        [Required]
        public string? TicketTitle { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsForced { get; set; }
        public int? TicketID { get; set; }

        [ForeignKey("TicketID")]
        public Tickets? ReferenceTicket { get; set; } = null;
        
    }
}
