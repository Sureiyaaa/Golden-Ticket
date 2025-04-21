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
        [Required]
        public string? Title {get;set;} = "None provided";
        [Required]
        public string? Description { get; set;} = "None Provided";
        public DateTime CreatedAt { get; set; }
        [Required]
        public int NotificationTypeID { get; set; }
        [ForeignKey("NotificationTypeID")]
        public NotificationType? NotificationType { get; set; } = null;
        public int? ReferenceID { get; set; }
        public bool IsRead { get; set;} = false;
    }

    public class NotificationDTO{
        public int? NotificationID { get; set; }
        public string? Title { get; set; } = "None provided";
        public string? Description { get; set; } = "None provided";
        public string? NotificationType { get; set; } = "Default";
        public bool isRead {get;set;} = false;
        public DateTime? CreatedAt { get; set; }
        public NotificationDTO(Notification notification){
            this.NotificationID = notification.NotificationID;
            this.Title = notification.Title;
            this.Title = notification.Description;
            this.NotificationType = notification.NotificationType!.NotificationName;
            this.CreatedAt = notification.CreatedAt;
            this.isRead = notification.IsRead;
        }
    }
}
