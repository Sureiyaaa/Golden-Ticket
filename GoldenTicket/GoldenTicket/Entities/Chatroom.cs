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
        public string? ChatroomName { get; set; } = "New Chatroom";
        [Required]
        public int AuthorID { get; set; }

        [ForeignKey("AuthorID")]
        public User? Author { get; set; } = null;
        public int? TicketID { get; set; }

        [ForeignKey("TicketID")]
        public Tickets? Ticket { get; set; } = null;
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        public ICollection<GroupMember> Members { get; set; } = new List<GroupMember>();

        public ICollection<Message> Messages { get; set; } = new List<Message>();
    }
    public class ChatroomDTO {
        public int? ChatroomID { get; set; }
        public string? ChatroomName { get; set; }
        public UserDTO? Author { get; set; }
        public TicketDTO? Ticket { get; set; }
        public List<Message>? Messages { get; set; } = [];
        public List<GroupMemberDTO> GroupMembers  { get; set; } = [];
        public DateTime? CreatedAt  { get; set; }

        public ChatroomDTO(Chatroom chatroom){
            this.ChatroomID = chatroom.ChatroomID;
            this.ChatroomName = chatroom.ChatroomName;
            this.Author = chatroom.Author != null ? new UserDTO(chatroom.Author) : null;

            this.Ticket = chatroom.Ticket != null ? new TicketDTO(chatroom.Ticket) : null;

            this.Messages = [];
            foreach(var member in chatroom.Members){
                this.GroupMembers!.Add(new GroupMemberDTO(member));
            }
            this.CreatedAt = chatroom.CreatedAt;
        }

    }
}
