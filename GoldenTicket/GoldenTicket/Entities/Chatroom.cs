using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using GoldenTicket.Entities;

namespace GoldenTicket.Entities
{
    [Table("tblChatroom")]
    public class Chatroom
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ChatroomID { get; set; }
        
        [Required]
        public string? ChatroomName { get; set; }
        [Required]
        public int AuthorID { get; set; }

        [ForeignKey("AuthorID")]
        public User? Author { get; set; } = null;
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public ICollection<GroupMember> Members { get; set; } = new List<GroupMember>();

        public ICollection<Message> Messages { get; set; } = new List<Message>();
    }
}
