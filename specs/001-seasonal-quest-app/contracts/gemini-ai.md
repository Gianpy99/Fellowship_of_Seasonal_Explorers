# API Contract: Gemini AI Integration

**Service**: Google Generative AI (Gemini 1.5 Flash)  
**Purpose**: Generate personalized quest recommendations based on family context  
**Protocol**: HTTPS REST API  
**Authentication**: API Key (free tier)

## Endpoint

### Generate Quest Recommendations

**Method**: POST  
**URL**: `https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent`  
**Headers**:
```http
Content-Type: application/json
x-goog-api-key: {API_KEY}
```

**Request Body**:
```json
{
  "contents": [{
    "parts": [{
      "text": "{PERSONALIZED_PROMPT}"
    }]
  }],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 500,
    "topP": 0.9
  }
}
```

**Prompt Template**:
```
You are a family educator helping children explore seasonal foods and nature.

Family Context:
- Total quests completed: {total_completed}
- Recent completions: {last_5_quests}
- Category breakdown: Fruits({fruit_count}), Vegetables({veg_count}), Flowers({flower_count}), Animal Products({animal_count})
- Current season: {season}
- Region: {region}
- Weather: {weather_condition}
- Language: {language}

Goal: Recommend 3-5 new quests that:
1. Diversify learning (suggest underrepresented categories)
2. Match current weather ({weather_condition})
3. Are seasonally appropriate for {season} in {region}
4. Build on previous learning with related topics
5. Are age-appropriate for children 5-12

Available uncompleted quests:
{uncompleted_quests_json}

Return ONLY a JSON array of quest IDs, nothing else:
["quest_id_1", "quest_id_2", "quest_id_3"]
```

**Response (Success - 200 OK)**:
```json
{
  "candidates": [{
    "content": {
      "parts": [{
        "text": "[\"bergamotto_calabria\", \"cipolla_rossa_calabria\", \"finocchio_calabria\"]"
      }]
    },
    "finishReason": "STOP"
  }],
  "usageMetadata": {
    "promptTokenCount": 450,
    "candidatesTokenCount": 25,
    "totalTokenCount": 475
  }
}
```

**Response (Error - 4xx/5xx)**:
```json
{
  "error": {
    "code": 429,
    "message": "Resource has been exhausted (e.g. check quota).",
    "status": "RESOURCE_EXHAUSTED"
  }
}
```

## Client Implementation (Flutter)

### Service Interface

```dart
class AIService {
  final GoogleGenerativeAI _ai;
  final StorageService _storage;
  
  AIService(String apiKey) : _ai = GoogleGenerativeAI(apiKey);
  
  /// Generate personalized quest recommendations
  /// Returns list of Quest IDs or empty list on failure
  Future<List<String>> getRecommendations({
    required String season,
    required String region,
    String? weatherCondition,
    required String language,
  }) async {
    try {
      // Check cache first (24-hour expiry)
      final cached = await _storage.getCachedRecommendations();
      if (cached != null && !cached.isExpired) {
        return cached.questIds;
      }
      
      // Build context from user progress
      final progress = await _storage.getUserProgress();
      final completedQuests = await _storage.getRecentCompletions(limit: 5);
      final uncompletedQuests = await _storage.getUncompletedQuests();
      
      // Construct prompt
      final prompt = _buildPrompt(
        progress: progress,
        recentQuests: completedQuests,
        uncompleted: uncompletedQuests,
        season: season,
        region: region,
        weather: weatherCondition,
        language: language,
      );
      
      // Call Gemini API
      final model = _ai.getGenerativeModel(modelName: 'gemini-1.5-flash');
      final response = await model.generateContent([Content.text(prompt)]);
      
      // Parse response
      final text = response.text ?? '[]';
      final questIds = _parseQuestIds(text);
      
      // Cache for 24 hours
      await _storage.cacheRecommendations(
        questIds: questIds,
        expiresAt: DateTime.now().add(Duration(hours: 24)),
      );
      
      return questIds;
      
    } catch (e) {
      // Fallback to rule-based recommendations
      return _getFallbackRecommendations(season, region);
    }
  }
  
  /// Fallback: Simple rule-based filtering when AI unavailable
  List<String> _getFallbackRecommendations(String season, String region) {
    // Return top 3 uncompleted quests matching season and region
    // Prioritize underrepresented categories
    // Simple logic, no AI needed
  }
}
```

## Error Handling

### Rate Limiting (429 Too Many Requests)
- **Free Tier Limit**: 15 requests per minute
- **Strategy**: Cache recommendations for 24 hours
- **Fallback**: Use rule-based recommendations if quota exceeded

### Network Errors
- **Offline**: Skip AI call, use fallback immediately
- **Timeout**: 10-second timeout, then fallback
- **Invalid Response**: Parse failure → fallback

### Privacy Controls
- **Opt-In Required**: AI recommendations disabled by default in AppSettings
- **No Personal Data**: Prompt contains only quest completion counts, no names/photos
- **Local Fallback**: App fully functional without AI

## Rate Limit Management

### Caching Strategy
- **Cache Duration**: 24 hours per recommendation set
- **Cache Key**: Season + Region + Weather + Completion Count
- **Invalidation**: Manual "Refresh Recommendations" button (user-initiated)

### Request Throttling
- **Minimum Interval**: 1 minute between API calls (enforced client-side)
- **User Feedback**: "Recommendations refresh once per day" message
- **Background Refresh**: Optional daily update (requires parent opt-in)

## Data Privacy

### Information Sent to Gemini
- ✅ **Allowed**: Quest completion counts, categories, seasons, regions
- ✅ **Allowed**: Quest IDs and titles (from bundled data, no user-generated content)
- ❌ **NOT Sent**: User names, photos, journal entries, location coordinates
- ❌ **NOT Sent**: Any personally identifiable information

### COPPA Compliance
- Parental consent required to enable AI recommendations (AppSettings toggle)
- Clear explanation of what data is processed
- Option to disable and delete cached recommendations

## Testing Contract

### Unit Tests
```dart
test('getRecommendations returns cached data when valid', () async {
  // Mock cached recommendations within 24-hour window
  // Verify no API call made
  // Assert cached quest IDs returned
});

test('getRecommendations calls API when cache expired', () async {
  // Mock expired cache
  // Mock successful API response
  // Verify API called once
  // Assert new recommendations cached
});

test('getRecommendations falls back on API error', () async {
  // Mock API 429 rate limit error
  // Verify fallback recommendations returned
  // Assert fallback uses season/region filtering
});
```

### Integration Tests
```dart
testWidgets('AI recommendations appear in UI when enabled', (tester) async {
  // Enable AI in settings
  // Tap "Get Recommendations" button
  // Verify loading indicator shown
  // Verify 3-5 quest cards displayed
  // Verify quest titles match returned IDs
});

testWidgets('Fallback works when AI disabled', (tester) async {
  // Disable AI in settings
  // Tap "Get Recommendations" button
  // Verify no API call (mock verification)
  // Verify rule-based quests shown
});
```

## API Key Management

### Development
- Store in `.env` file (not committed to git)
- Load via `flutter_dotenv` package
- Example: `GEMINI_API_KEY=your_api_key_here`

### Production (Family Use)
- Embed in app build (obfuscated)
- Or: First-run setup wizard asks parent to enter their own API key
- Free tier sufficient for family use (15 req/min = ~600 req/hour)

## Monitoring & Logging

### Success Metrics
- Track recommendation acceptance rate (how many are actually completed)
- Log cache hit rate (to optimize refresh interval)
- Monitor API error frequency

### Error Logging
```dart
if (apiResponse.statusCode != 200) {
  logger.warning('Gemini API failed: ${apiResponse.statusCode}');
  // Don't log response body (may contain sensitive data)
  // Increment fallback counter
}
```

## Future Enhancements

### Phase 2 Potential
- **Weather Integration**: Fetch current weather, enhance AI context
- **Learning Path**: AI suggests progressive quest sequences
- **Difficulty Adaptation**: AI adjusts recommendations based on completion speed

### Phase 3 Potential
- **Custom Quest Generation**: AI creates new quests from user's uploaded photos
- **Story Integration**: AI generates personalized educational stories for completed quests
