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
        public string? Title { get; set; }
        [Required]
        public string? Description { get; set; }
        [Required]
        public string? Solution { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public bool IsArchived { get; set; }
        [Required]
        public int? MainTagID { get; set;}
        [ForeignKey("MainTagID")]
        public MainTag? MainTag { get; set; }

        [Required]
        public int? SubTagID { get; set;}
        [ForeignKey("SubTagID")]
        public SubTag? SubTag { get; set; }

    }
}
