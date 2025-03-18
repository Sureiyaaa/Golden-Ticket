using Microsoft.AspNetCore.Mvc;
using GoldenTicket.Services;
using GoldenTicket.Models;
using OpenAIApp.Services;

namespace GoldenTicket.Controllers
{
    [ApiController]
    [Route("api/[controller]")] // URL: /api/ai
    public class AIController : ControllerBase
    {
        private readonly OpenAIService _openAIService;
        private readonly PromptService _promptService;
        //private readonly UnrealSpeechService _unrealSpeechService;

        public AIController(OpenAIService openAIService, PromptService promptService//, UnrealSpeechService unrealSpeechService
            )
        {
            _openAIService = openAIService;
            _promptService = promptService;
            //_unrealSpeechService = unrealSpeechService;
        }

        [HttpPost]
        public async Task<IActionResult> ProcessRequestAsync([FromBody] AIRequest requestData)
        {
            if (requestData?.Message == null || requestData.PromptType == null)
            {
                return BadRequest("Invalid JSON");
            }

            string additional = requestData.Additional ?? "";
            if (!string.IsNullOrEmpty(additional))
            {
                Console.WriteLine($"Additional: {additional}");
            }

            string requestPrompt = _promptService.GetPrompt(requestData.PromptType, additional);
            Console.WriteLine($"[PromptConfigService] Prompt Type: {requestData.PromptType}");
            Console.WriteLine($"[AI-AR] POST RECEIVED");

            string aiResponse = await _openAIService.GetAIResponse(requestData.Message, requestPrompt);
            Console.WriteLine($"[AI-AR] RESPONSE RECEIVED");

            Console.WriteLine($"\n[AI-AR Input]: {requestData.Message}");
            Console.WriteLine($"[AI-AR Response]: {aiResponse}");

            //await _unrealSpeechService.GenerateSpeech(aiResponse);

            return Ok(new { response = aiResponse });
        }
    }
}
