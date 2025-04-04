using OpenAI;
using OpenAI.Chat;
using System.ClientModel;
using TiktokenSharp;
using GoldenTicket.Services;
using GoldenTicket.Models;
using GoldenTicket.Database;
using GoldenTicket.Utilities;
using GoldenTicket.Entities;
using Microsoft.EntityFrameworkCore;

namespace OpenAIApp.Services;

public class OpenAIService
{
    private ChatClient _client;
    private ApiKeyCredential _apiCredential;
    private OpenAIClientOptions _options;
    private Dictionary<string, int> _apiKeyIndex = new();
    private Dictionary<string, int> _loopAmount = new();
    private readonly Dictionary<string, List<ChatMessage>> clientMessages = new(); // Per-client storage
    private readonly ILogger<OpenAIService> _logger;
    private readonly ApiConfig _apiConfig;
    private readonly Dictionary<string, int> clientTokenUsage = new();

    public static int TokenCountUsed { get; private set; } = 0;
    public static int TotalCharactersUsed { get; private set; } = 0;

    public OpenAIService(ConfigService config, ILogger<OpenAIService> logger, ApiConfig apiConfig)
    {
        _logger = logger;
        _apiConfig = apiConfig;
        string baseUrl = config.OpenAISettings.BaseUrl;

        _options = new OpenAIClientOptions()
        {
            Endpoint = new Uri(baseUrl)
        };

        _logger.LogInformation("[OpenAIService] Using Base URL: {BaseUrl}", baseUrl);
        _apiCredential = new ApiKeyCredential("Bearer " + _apiConfig.GetOpenAIKey(0));
        _client = new ChatClient("gpt-4o", _apiCredential, _options);
        
        PopulateMessages();
    }

    public async Task<string> GetAIResponse(string chatroomID, string userInput, string Prompt, bool isDirect = false)
    {
        if (!clientMessages.ContainsKey(chatroomID))
        {
            clientMessages[chatroomID] = new List<ChatMessage>(); // Initialize storage for this client
        }
        if (!_loopAmount.ContainsKey(chatroomID))
        {
            _loopAmount[chatroomID] = 0;
        }
        if (!_apiKeyIndex.ContainsKey(chatroomID))
        {
            _apiKeyIndex[chatroomID] = 0;
        }

        List<ChatMessage> messages = clientMessages[chatroomID];
        List<ChatMessage> directMsg = new();

        if (!isDirect)
        {
            messages = await CheckHistoryAsync(chatroomID, Prompt);
            messages.Add(new UserChatMessage(userInput));
        }
        else
        {
            directMsg = new()
            {
                new SystemChatMessage(Prompt),
                new UserChatMessage(userInput)
            };
        }

        var requestOptions = new ChatCompletionOptions()
        {
            Temperature = 0.7f,
            MaxOutputTokenCount = 2048,
        };

        var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));

        try
        {
            var response = await _client.CompleteChatAsync(!isDirect ? messages : directMsg, requestOptions, cts.Token);

            // DEBUG
            foreach (var message in messages)
            {
                Console.WriteLine($"Message Type: {message.GetType()}");
                Console.WriteLine($"Content Type: {message.Content.FirstOrDefault()!.Text}");
            }

            if (response == null || response.Value == null || response.Value.Content.Count == 0)
            {
                _logger.LogWarning("[OpenAIService] OpenAI API returned an empty or invalid response.");
                return "OpenAI API returned an empty or invalid response.";
            }

            string content = response.Value.Content[0].Text;
            TotalCharactersUsed += content.Length;
            messages.Add(new AssistantChatMessage(content));

            // DEBUG
            Console.WriteLine($"Message Type: {messages.LastOrDefault()!.GetType()}");
            Console.WriteLine($"Content Type: {messages.LastOrDefault()!.Content.LastOrDefault()!.Text}");

            GetTotalTokenUsed(chatroomID);
            _loopAmount[chatroomID] = 0;
            return content;
        }
        catch (OperationCanceledException ex)
        {
            _logger.LogWarning($"[OpenAIService] {ex.Message}");
            _logger.LogWarning("[OpenAIService] Request timeout detected. Possible rate limit reached. Trying to change API key...");
            return await HandleRateLimit(chatroomID, userInput, Prompt, isDirect);
        }
        catch (HttpRequestException httpEx) when (httpEx.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
        {
            _logger.LogWarning($"[OpenAIService] {httpEx.Message}");
            _logger.LogWarning("[OpenAIService] Rate Limit Exceeded: Too many requests. Trying to change API key...");
            return await HandleRateLimit(chatroomID, userInput, Prompt, isDirect);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, $"[OpenAIService] {ex.Message}");
            _logger.LogError(ex, "[OpenAIService] Error processing OpenAI request. Trying to change API key...");
            return await HandleRateLimit(chatroomID, userInput, Prompt, isDirect);
        }
    }

    private async Task<string> HandleRateLimit(string chatroomID, string userInput, string Prompt, bool isDirect)
    {
        if (_loopAmount[chatroomID] < ApiConfig.OpenAIKeys!.Count)
        {
            _loopAmount[chatroomID]++;
            int oldIndex = _apiKeyIndex[chatroomID];
            _apiKeyIndex[chatroomID]++;
            if(_apiKeyIndex[chatroomID] > ApiConfig.OpenAIKeys!.Count - 1)
            {
                _apiKeyIndex[chatroomID] = 0;
            }
            _logger.LogWarning("[OpenAIService] Switching API key from API_{OldIndex} to API_{NewIndex}", oldIndex, _apiKeyIndex[chatroomID]);
            _apiCredential = new ApiKeyCredential("Bearer " + _apiConfig.GetOpenAIKey(_apiKeyIndex[chatroomID]));
            _client = new ChatClient("gpt-4o", _apiCredential, _options);
            return await GetAIResponse(chatroomID, userInput, Prompt, isDirect);
        }
        else
        {
            _logger.LogError("[OpenAIService] All API keys exhausted. Delays expected.");
            return "[OpenAIService ERROR] I'm currently experiencing delays. Please try again later.";
        }
    }

    private void GetTotalTokenUsed(string chatroomID)
    {
        if (!clientMessages.ContainsKey(chatroomID)) return;

        var encoding = TikToken.EncodingForModel("gpt-4");
        string allMessagesText = string.Join("\n", clientMessages[chatroomID]
            .Select(m => string.Join("", m.Content.Select(c => c.Text))));

        int tokensUsed = encoding.Encode(allMessagesText).Count;

        // Update per-client token usage
        if (!clientTokenUsage.ContainsKey(chatroomID))
        {
            clientTokenUsage[chatroomID] = 0;
        }
        clientTokenUsage[chatroomID] += tokensUsed;

        // Update global token count
        TokenCountUsed += tokensUsed;

        _logger.LogInformation("[OpenAIService] Total Tokens Used for {ClientId}: {ClientTokenCount}", chatroomID, clientTokenUsage[chatroomID]);
        _logger.LogInformation("[OpenAIService] Total Tokens Used Across All Clients: {TotalTokenCount}", TokenCountUsed);
    }

    private async Task<string> SummarizeMessages(string chatroomID, List<ChatMessage> oldMessages)
    {
        if (!oldMessages.Any())
        {
            _logger.LogWarning("[OpenAIService] oldMessages in SummarizeMessages() is empty.");
            return string.Empty;
        }

        string combinedText = string.Join("\n", oldMessages.Select(m => m.Content.FirstOrDefault()?.Text ?? ""));
        string prompt = "Summarize this conversation briefly, keeping key details:";
        string response = await GetAIResponse(chatroomID, combinedText, prompt, true);

        _logger.LogDebug("[OpenAIService] Summary Generated for {ClientId}: {Summary}", chatroomID, response);
        return $"\nChat History Summary: {response}";
    }

    private async Task<List<ChatMessage>> CheckHistoryAsync(string chatroomID, string Prompt)
    {
        if (!clientMessages.ContainsKey(chatroomID))
        {
            clientMessages[chatroomID] = new List<ChatMessage>();
        }

        List<ChatMessage> messages = clientMessages[chatroomID];

        if (messages.Count == 0 || !(messages[0] is SystemChatMessage))
        {
            messages.Insert(0, new SystemChatMessage(Prompt));
        }
        else
        {
            if (((SystemChatMessage)messages[0]).Content.First().Text != Prompt)
            {
                _logger.LogInformation($"[OpenAIService] Changing prompt for {chatroomID} to {Prompt} ...");
                messages[0] = new SystemChatMessage(Prompt);
            }
        }

        if (messages.Count > 30)
        {
            var systemMessages = messages.Where(m => m is SystemChatMessage).ToList();
            string summary = await SummarizeMessages(chatroomID, messages.GetRange(systemMessages.Count, 10).ToList());
            messages.RemoveRange(systemMessages.Count, 20);

            string newPrompt = string.Join("\n", Prompt, summary);
            messages[0] = new SystemChatMessage(newPrompt);
        }
        return messages;
    }

    public void PopulateMessages() 
    {
        var populatedMessages = AIUtil.PopulateID();
        if (populatedMessages != null)
        {
            foreach (var kvp in populatedMessages)
            {
                clientMessages[kvp.Key] = kvp.Value;
            }
        }
        Console.WriteLine("[OpenAIService] Past AI Messages Restored");
    }
}
