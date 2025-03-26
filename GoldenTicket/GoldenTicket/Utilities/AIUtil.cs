using GoldenTicket.Database;
using GoldenTicket.Entities;
using GoldenTicket.Utilities;
using GoldenTicket.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using GoldenTicket.Models;
using OpenAIApp.Services;
using GoldenTicket.Controllers;

namespace GoldenTicket.Utilities
{
    public class AIUtil
    {
        
        private static OpenAIService? _openAIService;
        private static PromptService? _promptService;
        private static ILogger<AIController>? _logger;
        //private readonly UnrealSpeechService _unrealSpeechService;

        public AIUtil(OpenAIService openAIService, PromptService promptService, ILogger<AIController> logger)
        {
            _openAIService = openAIService;
            _promptService = promptService;
            _logger = logger;
            //_unrealSpeechService = unrealSpeechService;
        }
        public static async Task<string> GetAIResponseAsync(AIRequest requestData)
        {
            if (requestData?.Message == null || requestData.PromptType == null || requestData.id == null)
                return "";
            string additional = requestData.Additional ?? "";

            //if (!string.IsNullOrEmpty(additional)) _logger.LogInformation($"Additional: {additional}");

            string requestPrompt = _promptService!.GetPrompt(requestData.PromptType, additional);
            // _logger.LogInformation($"[PromptConfigService] Prompt Type: {requestData.PromptType}");
            // _logger.LogInformation($"[AI-AR] POST RECEIVED");

            string aiResponse = await _openAIService!.GetAIResponse(requestData.id, requestData.Message, requestPrompt);
            // _logger.LogInformation($"[AI-AR] RESPONSE RECEIVED");

            _logger!.LogInformation($"\n[AI-AR Input]: {requestData.Message}");
            _logger!.LogInformation($"[AI-AR Response]: {aiResponse}");

            //await _unrealSpeechService.GenerateSpeech(aiResponse);

            return aiResponse;
        }
        public static async Task<AIResponse?> GetJsonResponseAsync(AIRequest requestData) 
        {
            var unavailableResponse = AIResponse.Unavailable();
            try
            {
                string FAQList = FAQData();
                if (requestData?.Message == null || requestData.PromptType == null )
                {
                    return null;
                }

                string additional = requestData.Additional+FAQList ?? "";
                string requestPrompt = _promptService!.GetPrompt(requestData.PromptType, additional);

                string aiResponse = await _openAIService!.GetAIResponse(requestData.id, requestData.Message, requestPrompt);
                var parsedResponse = AIResponse.Parse(aiResponse);
                _logger!.LogInformation($"\n[AI-AR Input]: {requestData.Message}");
                _logger!.LogInformation($"[AI-AR Response]: {aiResponse}");
                
                if (!string.IsNullOrWhiteSpace(parsedResponse.Message))
                    return parsedResponse; 
                else
                    return null;
            }
            catch (Exception ex)
            {
                _logger!.LogError(ex, "Error in ProcessJsonResponseAsync");
                return null;
            }
        }
        private static string FAQData()
        {
            string TagList = "";
            string faqList = "";

            // Fetch all MainTags with their related SubTags
            var mainTags = DBUtil.GetTags();
            foreach (var mainTag in mainTags)
            {
                TagList += "MainTag: "+mainTag.MainTagName + "\n";
                foreach (var subTag in mainTag.SubTags!)
                {
                    TagList += "    - SubTab: "+subTag.SubTagName + "\n";
                }
            }
            // Fetch all FAQ data
            var faqData = DBUtil.GetFAQ();
            Console.WriteLine("FAQ DATA!!!!!!1:" + faqData);
            foreach (var faq in faqData)
            {
                faqList += "FAQ: "+faq.Title + "\n";
                faqList += "Description: "+faq.Description + "\n";
                faqList += "Solution: "+faq.Solution + "\n";
                faqList += "MainTag: "+faq.MainTag!.MainTagID + "\n";
                faqList += ">"+faq.SubTag!.SubTagName + "\n\n";
            }
            return $"\n[FAQ DATA] \nTag List:\n{TagList}--------------------------------------------\n{faqList}";
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