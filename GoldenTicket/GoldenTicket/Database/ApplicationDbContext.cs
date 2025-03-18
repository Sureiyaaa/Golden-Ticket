using GoldenTicket.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace GoldenTicket.Database {
    /// <summary>
    ///     Database Context for MySQL
    /// </summary>
    /// <param name="configuration">Configuraion JSON files</param>
    
    public class ApplicationDbContext() : DbContext{
        public IConfiguration config = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("Config/secret.json", optional: false, reloadOnChange: true).Build();
        public static string? ConnectionString {get; private set;}

        public DbSet<User> Users { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            ConnectionString = config["ConnectionString"] ?? throw new Exception("Connection String is Invalid");

            optionsBuilder.UseMySql(ConnectionString, ServerVersion.Parse("8.0.37-mysql"),
                options => options.EnableRetryOnFailure());                
        }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>()
                .Property(u => u.UserID)
                .ValueGeneratedOnAdd();
            // Run SQL command when migrating
            modelBuilder.Entity<User>().HasData(
                new User { UserID = 100000000, Username = config["AdminUsername"], Password = config["AdminUsername"], FirstName = "admin", MiddleInitial = 'a', LastName = "admin" }
            );

        }
        
    }
}