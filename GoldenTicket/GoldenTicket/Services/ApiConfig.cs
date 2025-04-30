using GoldenTicket.Entities;
using GoldenTicket.Utilities;
namespace GoldenTicket.Services;

public class ApiConfig
{
    public static List<APIKeyDTO>? OpenAIKeys;

    public async Task<APIKeyDTO> GetOpenAIKey(int ID = 0)
    {
        OpenAIKeys = await DBUtil.GetAPIKeys();
        if (ID == 0)
            ID = await GetLeastUsedAPI();

        if (OpenAIKeys == null || OpenAIKeys.Count == 0)
            throw new InvalidOperationException($"[ApiConfig] [ERROR] OpenAIKeys is not initialized or is empty. (ID = {ID})");

        return OpenAIKeys.FirstOrDefault(api => api.APIKeyID == ID)!;
    }
    public async Task<int> GetLeastUsedAPI(int lastID = 0)
    {
        OpenAIKeys = await DBUtil.GetAPIKeys();
        APIKeyDTO leastUsedKeyEntity;

        if (OpenAIKeys == null || OpenAIKeys.Count == 0)
            throw new InvalidOperationException("[ApiConfig] [ERROR] OpenAIKeys is not initialized or is empty.");
        if (lastID != 0)
            leastUsedKeyEntity = OpenAIKeys.OrderBy(key => key.LastRateLimit).FirstOrDefault(key => key.APIKeyID != lastID)!;
        else
            leastUsedKeyEntity = OpenAIKeys.OrderBy(key => key.LastRateLimit).FirstOrDefault()!;

        if (leastUsedKeyEntity == null || !leastUsedKeyEntity.APIKeyID.HasValue)
            throw new InvalidOperationException("[ApiConfig] [ERROR] Unable to determine the least used API key.");

        int leastUsedKey = leastUsedKeyEntity.APIKeyID.Value;
        return leastUsedKey;
    }
    public async Task<int> GetApiID(string _apiCredential)
    {
        OpenAIKeys = await DBUtil.GetAPIKeys();

        if (OpenAIKeys == null || OpenAIKeys.Count == 0)
            throw new InvalidOperationException("[ApiConfig] [ERROR] OpenAIKeys is not initialized or is empty.");

        var apiKey = OpenAIKeys.FirstOrDefault(a => a.APIKey == _apiCredential);

        if (apiKey == null || !apiKey.APIKeyID.HasValue)
            throw new InvalidOperationException("[ApiConfig] [ERROR] API key not found or APIKeyID is null.");

        int apiID = apiKey.APIKeyID.Value;
        return apiID;
    }
}
