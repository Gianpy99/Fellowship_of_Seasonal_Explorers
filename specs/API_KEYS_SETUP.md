# 🔐 API Keys Configuration

This project uses secure API keys that are **NOT** committed to Git.

## 📋 Required API Keys

1. **Gemini API Key** - For AI image generation
2. **Google Maps API Key** - For map and Street View features

## ⚙️ Setup Instructions

### Step 1: Get Your API Keys

#### Gemini API Key
1. Visit [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click "Get API Key" or "Create API Key"
4. Copy your new API key

#### Google Maps API Key
1. Visit [Google Cloud Console](https://console.cloud.google.com/google/maps-apis)
2. Create a new project or select existing one
3. Enable these APIs:
   - Maps JavaScript API
   - Places API (optional)
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy your API key
6. **Important**: Restrict your key to specific URLs in production!

### Step 2: Configure API Keys

1. Copy the template file:
   ```powershell
   Copy-Item "lib\config\api_keys.dart.template" "lib\config\api_keys.dart"
   ```

2. Open `lib/config/api_keys.dart` and replace the placeholders:
   ```dart
   static const String geminiApiKey = 'YOUR_ACTUAL_GEMINI_KEY_HERE';
   static const String googleMapsApiKey = 'YOUR_ACTUAL_MAPS_KEY_HERE';
   ```

3. Save the file. It's already in `.gitignore` so it won't be committed.

### Step 3: Update web/index.html

Open `web/index.html` and update the Google Maps script tag:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_MAPS_API_KEY"></script>
```

**Note**: `web/index.html` is also gitignored for security.

## 💰 Cost Estimation

### Gemini Image Generation
- **Model**: gemini-2.5-flash-image
- **Cost**: $30 per 1M tokens
- **Per image**: ~$0.04 (1290 tokens)
- **Project estimate**: 168 images = ~$6.72

### Google Maps API
- **Maps JavaScript API**: $7 per 1,000 loads
- **Street View**: $7 per 1,000 panorama loads
- **Free tier**: $200/month credit (= ~28,500 map loads)

## 🔒 Security Best Practices

1. ✅ **Never commit API keys** - They're gitignored
2. ✅ **Use API restrictions** - Restrict keys to specific domains in production
3. ✅ **Monitor usage** - Check Google Cloud Console regularly
4. ✅ **Rotate keys** - Change keys if exposed
5. ✅ **Use environment variables** - For production deployments

## 🧪 Testing Without Real Keys

If you don't have API keys yet, the app will:
- Show error dialogs when trying to generate images
- Still work for all other features (map, quests, stories)

## 📝 Files Protected from Git

These files contain sensitive data and are in `.gitignore`:

- `lib/config/api_keys.dart` - Your actual API keys
- `web/index.html` - Contains Google Maps API key

Keep the template files:
- `lib/config/api_keys.dart.template` ✅ Committed
- Share with team members for setup

## 🆘 Troubleshooting

### "API keys not configured" error
- Check that `api_keys.dart` exists (not just the template)
- Verify keys are not empty strings
- Ensure no quotes or whitespace in keys

### "Failed to generate image" error
- Check Gemini API key is valid
- Verify you have API quota remaining
- Check browser console for detailed errors

### Maps not loading
- Verify Google Maps API key in `web/index.html`
- Check that Maps JavaScript API is enabled in Google Cloud Console
- Verify domain restrictions (use `localhost` for development)

## 📞 Support

For API key issues:
- **Gemini**: [Google AI Studio Support](https://ai.google.dev/support)
- **Google Maps**: [Google Maps Platform Support](https://developers.google.com/maps/support)
