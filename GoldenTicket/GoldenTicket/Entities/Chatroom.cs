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
        public List<MessageDTO>? Messages { get; set; } = [];
        public List<GroupMemberDTO> GroupMembers  { get; set; } = [];
        public LastMessageDTO? LastMessage { get; set; } = null;
        public DateTime? CreatedAt  { get; set; }

        public ChatroomDTO(Chatroom chatroom, bool IncludeMessages = false)
        {
            this.ChatroomID = chatroom.ChatroomID;
            this.ChatroomName = chatroom.ChatroomName;
            this.Author = chatroom.Author != null ? new UserDTO(chatroom.Author) : null;

            this.Ticket = chatroom.Ticket != null ? new TicketDTO(chatroom.Ticket) : null;

            // Sort messages from latest to earliest
            
            this.Messages = chatroom.Messages
                .OrderByDescending(m => m.CreatedAt)
                .Select(m => new MessageDTO(m))
                .ToList();
            // Assign the last message if available
            var lastMessage = chatroom.Messages.OrderByDescending(m => m.CreatedAt).FirstOrDefault();
            this.LastMessage = lastMessage != null ? new LastMessageDTO(lastMessage) : null;
            if(!IncludeMessages) this.Messages = [];
            this.GroupMembers = chatroom.Members
                .Select(member => new GroupMemberDTO(member))
                .ToList();

            this.CreatedAt = chatroom.CreatedAt;
        }
    }

    public class LastMessageDTO{
        public string? LastMessage { get; set; } = "";
        public UserDTO? Sender { get; set; }
        public DateTime CreatedAt { get; set;}

        public LastMessageDTO(Message message){
            this.LastMessage = message.MessageContent;
            this.Sender = new UserDTO(message.Sender!);
            this.CreatedAt = message.CreatedAt;
        }
    }
}
