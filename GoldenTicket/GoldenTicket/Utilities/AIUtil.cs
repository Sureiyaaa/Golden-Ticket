using GoldenTicket.Services;
using GoldenTicket.Models;
using OpenAIApp.Services;
using OpenAI.Chat;
using GoldenTicket.Database;
using GoldenTicket.Entities;
using Microsoft.EntityFrameworkCore;

namespace GoldenTicket.Utilities
{
    public class AIUtil
    {
        private static OpenAIService? _openAIService;
        private static PromptService? _promptService;
        private static ILogger<AIUtil>? _logger;

        public static void Initialize(OpenAIService openAIService, PromptService promptService, ILogger<AIUtil> logger)
        {
            _openAIService = openAIService ?? throw new ArgumentNullException(nameof(openAIService));
            _promptService = promptService ?? throw new ArgumentNullException(nameof(promptService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public static async Task<string> GetAIResponseAsync(string _id, string _message, string _promptType = "GoldenTicket", string _additional = "")
        {
            if (_openAIService == null || _promptService == null || _logger == null)
                throw new InvalidOperationException("AIUtil is not initialized.");

            if (_message == null || _promptType == null || _id == null)
                return "";

            string additional = _additional ?? "";
            string requestPrompt = _promptService.GetPrompt(_promptType, additional);
            string aiResponse = await _openAIService.GetAIResponse(_id, _message, requestPrompt);

            _logger.LogInformation($"\n[AI-AR Input]: {_message}");
            _logger.LogInformation($"[AI-AR Response]: {aiResponse}");

            return aiResponse;
        }

        public static async Task<AIResponse?> GetJsonResponseAsync(string _id, string _message, string _promptType = "GoldenTicket", string _additional = "")
        {
            try
            {
                if (_openAIService == null || _promptService == null || _logger == null)
                    throw new InvalidOperationException("AIUtil is not initialized.");

                if (_message == null || _promptType == null)
                {
                    _logger.LogError("[AIUtil]: Message cant be empty");
                    return AIResponse.Unavailable();
                }
                    
                string additional = _additional + FAQData() ?? "";
                string requestPrompt = _promptService.GetPrompt(_promptType, additional);

                string aiResponse = await _openAIService.GetAIResponse(_id, _message, requestPrompt);
                var parsedResponse = AIResponse.Parse(aiResponse);

                // _logger.LogInformation($"\n[AI-AR Input]: {_message}");
                // _logger.LogInformation($"[AI-AR Response]: {aiResponse}");

                return string.IsNullOrWhiteSpace(parsedResponse.Message) ? parsedResponse : AIResponse.Unavailable();
            }
            catch (Exception ex)
            {
                _logger!.LogError(ex, "Error in ProcessJsonResponseAsync");
                return null;
            }
        }

        private static string FAQData()
        {
            string tagList = "";
            string faqList = "";

            var mainTags = DBUtil.GetTags();
            foreach (var mainTag in mainTags)
            {
                tagList += $"MainTag: {mainTag.MainTagName}\n";
                foreach (var subTag in mainTag.SubTags!)
                {
                    tagList += $"    - SubTag: {subTag.SubTagName}\n";
                }
            }

            var faqData = DBUtil.GetFAQs();
            foreach (var faq in faqData)
            {
                faqList += $"FAQ: {faq.Title}\nDescription: {faq.Description}\nSolution: {faq.Solution}\nMainTag: {faq.MainTag!.MainTagName}\n>{faq.SubTag!.SubTagName}\n\n";
            }

            return $"\n[FAQ DATA] \nTag List:\n{tagList}--------------------------------------------\n{faqList}";
        }

        public static Dictionary<string, List<ChatMessage>> PopulateID()
        {
            Dictionary<string, List<ChatMessage>> MessageList = new();

            using (var context = new ApplicationDbContext())
            {
                List<ChatroomDTO> dtos = new();
                List<Chatroom> chatrooms = context.Chatrooms
                    .Include(c => c.Members)
                        .ThenInclude(m => m.Member)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Messages)
                        .ThenInclude(m => m.Sender)
                            .ThenInclude(u => u!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Author)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Assigned)
                            .ThenInclude(t => t!.Role)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.ticketHistories)
                            .ThenInclude(t => t!.Action)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.MainTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.SubTag)
                    .Include(c => c.Ticket)
                        .ThenInclude(t => t!.Status)
                    .Include(c => c.Author)
                        .ThenInclude(t => t!.Role)
                    .ToList();

                foreach (var chatroom in chatrooms.Where(c => c.TicketID != 99))
                {
                    dtos.Add(new ChatroomDTO(chatroom, true));
                }

                foreach (var chatroom in dtos)
                {
                    List<ChatMessage> chatMessages = new();

                    foreach (var message in chatroom.Messages!)
                    {
                        if (message.Sender!.UserID != 100000001)
                        {
                            chatMessages.Add(new UserChatMessage(message.MessageContent));
                        }
                    }
                    if (!MessageList.ContainsKey(chatroom.ChatroomID.ToString()!))
                    {
                        MessageList[chatroom.ChatroomID.ToString()!] = chatMessages;
                        Console.WriteLine($"[AIUtil] added chatroom {chatroom.ChatroomID} to chat history");
                    }
                }
            }
            return MessageList;
        }
















        private string ManualFAQData() {
            return @"FAQ 1: The MaxHub Sharescreen code is not showing, how do i fix this?
Solution: Turn off Maxhub for 2 mins and restart.
Tags: MaxHub
>Code not showing

FAQ 2: How do i change the printer's paper size?
Solution: Click change paper size and find the appropriate paper size
Tags: Printer
>Wrong paper size

FAQ 3: My MaxHub is lagging when using wireless screen share. How can I fix this?
Solution: Ensure your MaxHub and the device you're sharing from are on the same Wi-Fi network. Reduce background applications and try using a wired connection for better performance.
Tags: MaxHub
>Lagging

FAQ 4: My MaxHub is not turning on even after pressing the power button. What should I do?
Solution: Check if the power cable is securely connected. Try a different power outlet. If the issue persists, hold the power button for 10 seconds to force restart.
Tags: MaxHub
>Not turning on

FAQ 5: MaxHub screen is frozen and unresponsive. How do I fix this?
Solution: Perform a soft reset by unplugging the power cable for 2 minutes, then reconnecting and powering it on. If the issue continues, check for firmware updates.
Tags: MaxHub
>Lagging

FAQ 6: The MaxHub touchscreen is not responding. What should I do?
Solution: Clean the screen to remove any dirt or oil. Restart the device and ensure no external devices are interfering with touch sensitivity. If the problem persists, recalibrate the touch settings in the MaxHub menu.
Tags: MaxHub
>Not turning on

FAQ 7: MaxHub is displaying a black screen when turned on. How do I fix this?
Solution: Try switching input sources using the remote. If the problem remains, disconnect all external devices and restart the MaxHub. If there is still no display, perform a factory reset.
Tags: MaxHub
>Not turning on

FAQ 8: My printer is constantly jamming. How do I prevent this?
Solution: Remove any stuck paper carefully. Ensure you are using the correct paper type and loading it properly. Regularly clean the rollers to prevent future jams.
Tags: Printer
>Jamming

FAQ 9: The printer is not showing up on my computer. What should I do?
Solution: Ensure the printer is powered on and connected to the same network as your computer. Try reinstalling the printer drivers and restarting both the printer and the computer.
Tags: Printer
>Printer not listed in computer

FAQ 10: My printer is saying 'Not Connected' even though it's plugged in. How can I fix this?
Solution: Check all cable connections and try a different USB port. If using a wireless printer, restart the router and reconnect the printer to Wi-Fi.
Tags: Printer
>Not connected

FAQ 11: The printer is printing faded or blurry text. How do I improve print quality?
Solution: Check the ink or toner levels and replace if necessary. Clean the printhead and ensure you are using the correct print settings for your paper type.
Tags: Printer
>Print quality issue

FAQ 12: My printer is printing blank pages. What should I do?
Solution: Ensure there is enough ink or toner. Perform a nozzle check and clean the printhead using the printer’s maintenance settings. Try using a different document to rule out software issues.
Tags: Printer
>Print quality issue";
        }
    }
}