using GoldenTicket.Hubs;
using Microsoft.Extensions.FileProviders;
namespace GoldenTicket.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services, IConfiguration config)
    {
        services.AddControllers();

        services.AddSignalR();
        services.AddSignalR().AddHubOptions<GTHub>(options =>
        {
            options.EnableDetailedErrors = true;
            options.ClientTimeoutInterval = TimeSpan.FromSeconds(10);
            options.KeepAliveInterval = TimeSpan.FromSeconds(5);
        });

        // Add Database Context HERE
        // services.AddDbContext<DataContext>(opt =>
        // {
        //     opt.UseSqlite(config.GetConnectionString("DefaultConnection"));
        // });

        services.AddCors((opt) => opt.AddPolicy(
            "GoldenTracker",
            (policy) => policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()
        ));

        // // Define flutter web build file provider
        // string flutterWebPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "app");
        // services.AddSingleton<IFileProvider>(new PhysicalFileProvider(flutterWebPath));

        return services;
    }
}