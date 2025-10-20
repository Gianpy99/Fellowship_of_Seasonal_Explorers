# 🎨 AI Image Generation Feature

## Overview
The Seasonal Quest app now supports **on-demand AI image generation** using Google's **Gemini 2.5 Flash** model. Users can generate custom illustrations for seasonal products directly from the quest detail screen.

## 🚀 Features Implemented

### 1. **Generate Product Icons** 
- **Location**: Quest Detail Screen → Below product description
- **Button**: "Generate Product Icon" (outlined, blue)
- **Style**: Centered, Studio Ghibli-style illustration (512x512)
- **Use case**: Create beautiful icons for each seasonal product

### 2. **Generate Story Scene Illustrations**
- **Location**: Quest Detail Screen → Story section (purple card)
- **Button**: "Generate AI Illustration" (purple, at bottom of story card)
- **Style**: Whimsical narrative scenes with Lina, Taro, and seasonal products
- **Variations**: Each story index gets a unique lighting/atmosphere variation
- **Use case**: Bring educational stories to life with custom artwork

### 3. **Auto-Download Generated Images**
- Images are automatically downloaded to browser's Downloads folder
- **Filename format**: `{product_name}_{type}_{variation}.png`
  - Example: `bergamot_story_0.png`, `orange_icon.png`

## 🎭 Image Styles

### Icon Style
```
Charming illustration, Studio Ghibli style
Simple clean background with soft pastel colors
Centered subject, watercolor texture
Educational children's content aesthetic
```

### Story Scene Style
```
Studio Ghibli + Disney magic + Tolkien fantasy
Watercolor texture, pastel colors
Variations: sunset, morning mist, magical sparkles, market, forest
Characters: Lina (Calabrian girl), Taro (elf)
Child-friendly, storybook quality
```

### Recipe Style (TODO)
```
Beautiful cooking illustration
Storybook recipe art
Traditional Calabrian elements
Warm kitchen atmosphere
```

## 💰 Cost Analysis

| Metric | Value |
|--------|-------|
| **Model** | gemini-2.5-flash-image |
| **Cost per image** | ~$0.04 (1290 tokens) |
| **56 products × 4 images** | 224 images = **$8.96** |
| **Monthly free tier** | N/A (pay-as-you-go) |

### Comparison with Imagen
- **Imagen 4**: $0.02-$0.12/image (better photorealism)
- **Gemini 2.5 Flash**: $0.04/image (better conversational editing)

**Why Gemini?**
- ✅ Better for narrative/story-based prompts
- ✅ Multi-turn conversational refinement
- ✅ Excellent text rendering in images
- ✅ Natural language understanding

## 🔐 Security

### API Key Protection
1. **api_keys.dart**: Gitignored, contains real keys
2. **api_keys.dart.template**: Committed, shows structure
3. **.gitignore**: Blocks both `api_keys.dart` and `web/index.html`

### Current Keys (SECURED)
- **Gemini API**: `**********************` (in api_keys.dart, NOT in Git)
- **Google Maps API**: `***********` (in web/index.html, NOT in Git)

## 📁 File Structure

```
seasonal_quest_app/
├── lib/
│   ├── config/
│   │   ├── api_keys.dart          # ❌ Gitignored (real keys)
│   │   └── api_keys.dart.template # ✅ Committed (template)
│   ├── services/
│   │   └── gemini_image_service.dart  # AI generation logic
│   └── screens/
│       └── quest_detail_screen.dart   # UI with generation buttons
├── API_KEYS_SETUP.md              # Setup instructions
└── .gitignore                     # Security config
```

## 🛠️ Technical Implementation

### GeminiImageService
**Location**: `lib/services/gemini_image_service.dart`

**Methods**:
- `generateIconImage(Quest)` → Base64 PNG
- `generateStoryImage(Quest, story, variation)` → Base64 PNG
- `generateRecipeImage(Quest)` → Base64 PNG (TODO)

**API Endpoint**:
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=API_KEY
```

**Request Body**:
```json
{
  "contents": [{
    "parts": [{"text": "Beautiful Ghibli-style illustration..."}]
  }],
  "generationConfig": {
    "temperature": 0.9,
    "topK": 40,
    "topP": 0.95,
    "maxOutputTokens": 2048
  }
}
```

### QuestDetailScreen Updates
**New UI Elements**:
1. "Generate Product Icon" button (after description)
2. "Generate AI Illustration" button (in story card)

**New Methods**:
- `_generateIconImage()` - Handles icon generation workflow
- `_generateAIImage()` - Handles story scene generation workflow
- `_downloadImage()` - Browser download via Blob API

**User Flow**:
1. User clicks generation button
2. Loading dialog appears (with progress info)
3. API call to Gemini (10-30 seconds)
4. Success: Auto-download + green snackbar
5. Failure: Error dialog with retry option

## 🧪 Testing Checklist

### Manual Testing
- [ ] Click "Generate Product Icon" → Downloads PNG
- [ ] Click "Generate AI Illustration" → Downloads story PNG with variation
- [ ] Navigate between stories → Variation index changes
- [ ] Check filename format: `{product}_icon.png`, `{product}_story_0.png`
- [ ] Test error handling (invalid API key)
- [ ] Test loading state (30s timeout)
- [ ] Verify images have SynthID watermark

### Edge Cases
- [ ] Multiple rapid clicks (should be blocked by `_isGeneratingImage` flag)
- [ ] App closed during generation (browser cancels request)
- [ ] No API key configured (should show error dialog)
- [ ] Network failure (should show error dialog)

## 📊 Usage Tracking

To monitor costs, check:
1. [Google AI Studio](https://aistudio.google.com/apikey) → Usage tab
2. [Google Cloud Console](https://console.cloud.google.com/) → Billing

**Recommended quotas**:
- Development: Unlimited (monitor daily)
- Production: Set daily limit (e.g., 100 images/day = $4/day)

## 🔮 Future Enhancements

### Phase 1 (Current)
- ✅ Icon generation
- ✅ Story scene generation
- ✅ Auto-download to browser

### Phase 2 (Planned)
- [ ] Recipe illustration generation
- [ ] Batch generation (all 56 products)
- [ ] Image gallery in HomeScreen
- [ ] Save generated images to JSON (update `imageIconPath`, `imageStoryPath`)

### Phase 3 (Advanced)
- [ ] Conversational refinement ("Make it warmer", "Add more colors")
- [ ] Multiple variations per story (generate 3 versions)
- [ ] User voting on favorite illustrations
- [ ] Cloud storage integration (Firebase Storage)

### Phase 4 (Production)
- [ ] Server-side generation (to hide API key)
- [ ] Pre-generate all images during build
- [ ] CDN hosting for generated images
- [ ] Admin panel for bulk operations

## 🐛 Known Issues

1. **Badge overflow warning** (8px) - Cosmetic, non-blocking
2. **Google Maps Marker deprecation** - Update to AdvancedMarkerElement in Phase 3
3. **Gemini API language support** - Italian prompts may have lower quality (use EN prompts for best results)

## 📝 Notes

- **SynthID Watermark**: All Gemini-generated images include invisible watermark for AI detection
- **Model Version**: Using `gemini-2.0-flash-exp` (experimental, subject to change)
- **Rate Limits**: Default 60 requests/minute (plenty for this use case)
- **Image Size**: All images 1024x1024px or smaller (1290 tokens)

## 📞 Support Resources

- **Gemini API Docs**: https://ai.google.dev/gemini-api/docs/image-generation
- **API Studio**: https://aistudio.google.com/
- **Pricing**: https://ai.google.dev/gemini-api/docs/pricing
- **API Keys Setup**: See `API_KEYS_SETUP.md`
