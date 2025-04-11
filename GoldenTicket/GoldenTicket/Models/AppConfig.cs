namespace GoldenTicket.Models;

public class AppConfig
{
    public AppSettings AppSettings { get; set; } = new();
    public CorsSettings CorsSettings { get; set; } = new();
    public VoiceSettings VoiceSettings { get; set; } = new();
    public OpenAISettings OpenAISettings { get; set; } = new();
}

public class AppSettings
{
    public bool UseDynamicIP { get; set; }
    public string DirectIp { get; set; } = "0.0.0.0";
    public int Port { get; set; }
    public bool UseWebSocket { get; set; }
    public string PromptConfigPath { get; set; } = string.Empty;
}

public class CorsSettings
{
    public string AllowedOrigins { get; set; } = "*";
}

public class VoiceSettings
{
    public bool UseTTS { get; set; }
    public string VoiceID { get; set; } = "Hannah";
    public float Pitch { get; set; } = 1;
    public float Speed { get; set; } = 0f;
    public string Bitrate { get; set; } = "320k";
}

public class OpenAISettings
{
    public string BaseUrl { get; set; } = "https://models.inference.ai.azure.com/";
    public int ChatbotID { get; set; } = 100000001;
}
