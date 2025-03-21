using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
namespace GoldenTicket.Entities
{
    [Table("tblMainTag")]
    public class MainTag
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int TagID { get; set; }
        [Required]
        public string? TagName { get; set; }
        public ICollection<SubTag> ChildTags { get; set; } = new List<SubTag>();
    }
}
