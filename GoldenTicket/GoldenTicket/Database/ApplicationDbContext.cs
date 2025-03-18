using GoldenTicket.Entities;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Database
{
    /// <summary>
    /// Database Context for MySQL
    /// </summary>
    /// <param name="configuration">Configuraion JSON files</param>

    public class ApplicationDbContext : DbContext
    {
        private readonly IConfiguration _config;

        public ApplicationDbContext(IConfiguration configuration)
        {
            _config = configuration;
        }

        public DbSet<User> Users { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            string? connectionString = _config["ConnectionString"] 
                ?? throw new Exception("Connection String is Invalid");

            optionsBuilder.UseMySql(connectionString, ServerVersion.Parse("8.0.37-mysql"),
                options => options.EnableRetryOnFailure());
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>()
                .Property(u => u.UserID)
                .ValueGeneratedOnAdd();

            modelBuilder.Entity<User>().HasData(
                new User
                {
                    UserID = 100000000,
                    Username = _config["AdminUsername"],
                    Password = _config["AdminPassword"],
                    FirstName = "admin",
                    MiddleInitial = 'A',
                    LastName = "admin"
                }
            );
        }
    }
}
