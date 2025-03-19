using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace GoldenTicket.Entities
{
    [Table("tblNotification")]
    public class Notification
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int NotificationID { get; set; }
        [Required]
        public int UserID { get; set; }
        [ForeignKey("UserID")]
        public User? User { get; set; } = null;
        public DateTime CreatedAt { get; set; }
        [Required]
        public int NotificationTypeID { get; set; }
        [ForeignKey("NotificationTypeID")]
        public NotificationType? NotificationType { get; set; } = null;
        public int? ReferenceID { get; set; }
        
    }
}
