using GoldenTicket.Extensions;
using GoldenTicket.Hubs;
using GoldenTicket.Models;
using GoldenTicket.Services;
using OpenAIApp.Services;

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
builder.Services.Configure<AppConfig>(builder.Configuration.GetSection("AppConfig"));

builder.Services.AddApplicationServices(builder.Configuration);

var app = builder.Build();
app.UseCors("GoldenTracker");

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

// app.UseHttpsRedirection();
//app.UseStaticFiles();
app.MapControllers();
app.UseRouting();

app.MapHub<GTHub>("/GTHub");
app.UseAuthorization();

// app.MapControllerRoute(
//     name: "default",
//     pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
