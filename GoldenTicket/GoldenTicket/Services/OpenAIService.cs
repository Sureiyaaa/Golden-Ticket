using OpenAI;
using OpenAI.Chat;
using System.ClientModel;
using TiktokenSharp;
using GoldenTicket.Services;
using GoldenTicket.Models;

namespace OpenAIApp.Services;

public class OpenAIService
{
    private ChatClient _client;
    private ApiKeyCredential _apiCredential;
    private OpenAIClientOptions _options;
    private int _apiKeyIndex;
    private readonly List<ChatMessage> messages = new();
    private readonly ILogger<OpenAIService> _logger;
    private readonly ApiConfig _apiConfig;

    public static int TokenCountUsed { get; private set; } = 0;
    public static int TotalCharactersUsed { get; private set; } = 0;

    public OpenAIService(ConfigService config, ILogger<OpenAIService> logger, ApiConfig apiConfig)
    {
        _logger = logger;
        _apiConfig = apiConfig;
        _apiKeyIndex = 0;
        string baseUrl = config.OpenAISettings.BaseUrl;

        _options = new OpenAIClientOptions()
        {
            Endpoint = new Uri(baseUrl)
        };

        _logger.LogInformation("[OpenAIService] Using Base URL: {BaseUrl}", baseUrl);

        _apiCredential = new ApiKeyCredential("Bearer " + _apiConfig.GetOpenAIKey(_apiKeyIndex));
        _client = new ChatClient("gpt-4o", _apiCredential, _options);
    }

    public async Task<string> GetAIResponse(string userInput, string Prompt, bool isDirect = false)
    {
        List<ChatMessage> directMsg = new();
        _logger.LogInformation($"[OpenAIService] Prompt Received: {Prompt}");
        if (!isDirect)
        {
            await CheckHistoryAsync(Prompt);
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

        var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));

        try
        {
            var response = await _client.CompleteChatAsync(!isDirect ? messages : directMsg, requestOptions, cts.Token);

            if (response == null || response.Value == null || response.Value.Content.Count == 0)
            {
                _logger.LogWarning("[OpenAIService] OpenAI API returned an empty or invalid response.");
                return "OpenAI API returned an empty or invalid response.";
            }

            string content = response.Value.Content[0].Text;
            TotalCharactersUsed += content.Length;
            messages.Add(new AssistantChatMessage(content));
            GetTotalTokenUsed();

            return content;
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("[OpenAIService] Request timeout detected. Possible rate limit reached.");
            return await HandleRateLimit(userInput, Prompt, isDirect);
        }
        catch (HttpRequestException httpEx) when (httpEx.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
        {
            _logger.LogWarning("[OpenAIService] Rate Limit Exceeded: Too many requests.");
            return "I'm currently at my request limit. Please try again later.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[OpenAIService] Error processing OpenAI request.");
            return "I'm having trouble thinking right now...";
        }
    }

    private async Task<string> HandleRateLimit(string userInput, string Prompt, bool isDirect)
    {
        if (_apiKeyIndex < ApiConfig.OpenAIKeys!.Count - 1)
        {
            _apiKeyIndex++;
            _logger.LogWarning("[OpenAIService] Switching API key from API_{OldIndex} to API_{NewIndex}", _apiKeyIndex - 1, _apiKeyIndex);
            _apiCredential = new ApiKeyCredential("Bearer " + _apiConfig.GetOpenAIKey(_apiKeyIndex));
            _client = new ChatClient("gpt-4o", _apiCredential, _options);
            return await GetAIResponse(userInput, Prompt, isDirect);
        }
        else
        {
            _logger.LogError("[OpenAIService] All API keys exhausted. Delays expected.");
            return "[ERROR (OpenAIService)] I'm currently experiencing delays. Please try again later.";
        }
    }

    private void GetTotalTokenUsed()
    {
        var encoding = TikToken.EncodingForModel("gpt-4");
        string allMessagesText = string.Join("\n", messages.Select(m => string.Join("", m.Content.Select(c => c.Text))));
        TokenCountUsed += encoding.Encode(allMessagesText).Count;

        _logger.LogInformation("[OpenAIService] Total Tokens Used: {TokenCount}", TokenCountUsed);
    }

    private async Task<string> SummarizeMessages(List<ChatMessage> oldMessages)
    {
        if (!oldMessages.Any())
        {
            _logger.LogWarning("[OpenAIService] oldMessages in SummarizeMessages() is empty.");
            return string.Empty;
        }

        string combinedText = string.Join("\n", oldMessages.Select(m => m.Content.FirstOrDefault()?.Text ?? ""));
        string prompt = "Summarize this conversation briefly, keeping key details:";
        string response = await GetAIResponse(combinedText, prompt, true);

        _logger.LogDebug("[OpenAIService] Summary Generated: {Summary}", response);
        return $"\nChat History Summary: {response}";
    }

    private async Task CheckHistoryAsync(string Prompt)
    {
        if (messages.Count == 0 || !(messages[0] is SystemChatMessage))
        {
            messages.Insert(0, new SystemChatMessage(Prompt));
        }
        else
        {
            if (((SystemChatMessage)messages[0]).Content.First().Text != Prompt)
            {
                _logger.LogInformation($"[OpenAIService] Changing prompt to {Prompt} ...");
                messages[0] = new SystemChatMessage(Prompt);
            }
        }

        if (messages.Count > 30)
        {
            var systemMessages = messages.Where(m => m is SystemChatMessage).ToList();
            string summary = await SummarizeMessages(messages.GetRange(systemMessages.Count, 10).ToList());
            messages.RemoveRange(systemMessages.Count, 20);

            string newPrompt = string.Join("\n", Prompt, summary);
            messages[0] = new SystemChatMessage(newPrompt);
        }
    }

    private async Task<AIResponse> GetFormattedResponse(string userInput, string prompt, bool isDirect = false)
    {
        string response = await GetAIResponse(userInput, prompt, isDirect);
        AIResponse aIResponse = AIResponse.Parse(response);
        return aIResponse;
    }
}
