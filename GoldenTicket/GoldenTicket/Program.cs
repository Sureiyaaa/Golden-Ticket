using GoldenTicket.Database;
using GoldenTicket.Hubs;

var builder = WebApplication.CreateBuilder(args);

// Add json file to the Configuration Cointainer
builder.Configuration
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("Config/appconfig.json", optional: false, reloadOnChange: true)
    .AddJsonFile("Config/prompt.json", optional: false, reloadOnChange: true)
    .AddJsonFile("Config/secret.json", optional: false, reloadOnChange: true)
    .AddJsonFile("Config/config.json", optional: false, reloadOnChange: true)
    .AddEnvironmentVariables();

// Add services to the container.
builder.Services.AddDbContext<ApplicationDbContext>();
builder.Services.AddControllersWithViews();
builder.Services.AddSignalR();
builder.Services.AddSignalR().AddHubOptions<GTHub>(options =>
{
    options.EnableDetailedErrors = true;
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(10);
    options.KeepAliveInterval = TimeSpan.FromSeconds(5);
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.MapHub<GTHub>("/GTHub");
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
