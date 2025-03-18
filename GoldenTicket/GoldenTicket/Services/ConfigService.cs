using Microsoft.Extensions.Options;
using GoldenTicket.Models;

namespace GoldenTicket.Services;

public class ConfigService
{
    public AppSettings AppSettings { get; }
    public CorsSettings CorsSettings { get; }
    public VoiceSettings VoiceSettings { get; }
    public OpenAISettings OpenAISettings { get; }

    public ConfigService(IOptionsMonitor<AppConfig> config)
    {
        var currentConfig = config.CurrentValue;
        AppSettings = currentConfig.AppSettings;
        CorsSettings = currentConfig.CorsSettings;
        VoiceSettings = currentConfig.VoiceSettings;
        OpenAISettings = currentConfig.OpenAISettings;
    }

}
