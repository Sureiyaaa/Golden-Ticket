namespace GoldenTicket.Services;

public class ApiConfig
{
    public static List<string>? OpenAIKeys { get; private set; }
    public ApiConfig(IConfiguration configuration)
    {
        // Load API keys from "Config/secret.json"
        OpenAIKeys = configuration.GetSection("OpenAIKey").Get<List<string>>() ?? throw new Exception("[ERROR] Missing OpenAIKey in secret.json");

        if (OpenAIKeys.Count == 0)
            throw new Exception("[ERROR] OpenAIKey array is empty in secret.json");
    }

    public string GetOpenAIKey(int index = 0)
    {
        if (OpenAIKeys == null || OpenAIKeys.Count == 0)
            throw new InvalidOperationException("[ApiConfig] [ERROR] OpenAIKeys is not initialized or is empty.");

        if (index < 0 || index >= OpenAIKeys.Count)
            throw new IndexOutOfRangeException($"[ApiConfig] [ERROR] Invalid OpenAIKey index: {index}");

        return OpenAIKeys[index];
    }
}
