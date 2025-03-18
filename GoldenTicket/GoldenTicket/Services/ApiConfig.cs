namespace GoldenTicket.Services;

public class ApiConfig
{
    public static List<string>? OpenAIKeys { get; private set; }
    public static string? UnrealSpeechKey { get; private set; }

    public ApiConfig(IConfiguration configuration)
    {
        // Load API keys from "Config/secret.json"
        OpenAIKeys = configuration.GetSection("OpenAIKey").Get<List<string>>() ?? throw new Exception("[ERROR] Missing OpenAIKey in secret.json");

        if (OpenAIKeys.Count == 0)
            throw new Exception("[ERROR] OpenAIKey array is empty in secret.json");

        // Load UnrealSpeechKey from "Config/secret.json"
        UnrealSpeechKey = configuration["UnrealSpeechKey"] ?? throw new Exception("[ERROR] Missing UnrealSpeechKey in secret.json");
    }

    public string GetOpenAIKey(int index = 0)
    {
        if (index < 0 || index >= OpenAIKeys!.Count)
            throw new IndexOutOfRangeException($"Invalid OpenAIKey index: {index}");

        return OpenAIKeys[index];
    }
}
