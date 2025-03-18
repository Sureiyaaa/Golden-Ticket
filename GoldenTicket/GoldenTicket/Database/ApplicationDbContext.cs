using GoldenTicket.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace GoldenTicket.Database {
    /// <summary>
    ///     Database Context for MySQL
    /// </summary>
    /// <param name="configuration">Configuraion JSON files</param>
    public class ApplicationDbContext(IConfiguration configuration) : DbContext{
        public static string? ConnectionString {get; private set;}


        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            ConnectionString = configuration["ConnectionString"] ?? throw new Exception("Connection String is Invalid");

            optionsBuilder.UseMySql(ConnectionString, ServerVersion.Parse("8.0.37-mysql"),
                options => options.EnableRetryOnFailure());
        }
        

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {

            modelBuilder.Entity<User>().Property(u => u.UserID).HasAnnotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn);
            modelBuilder.Entity<User>().HasData(new User { UserID = 1000000000});

            base.OnModelCreating(modelBuilder);
            // modelBuilder.Entity<Message>()
            // .Property(u => u.MessageID)
            // .HasAnnotation("SqlServer:Identity", "1000000000, 1");
            // modelBuilder.Entity<Chatroom>()
            // .Property(u => u.ChatroomID)
            // .HasAnnotation("SqlServer:Identity", "1000000000, 1");
            // modelBuilder.Entity<Roles>()
            // .Property(u => u.RoleID)
            // .HasAnnotation("SqlServer:Identity", "1000000000, 1");
        }

    }
}