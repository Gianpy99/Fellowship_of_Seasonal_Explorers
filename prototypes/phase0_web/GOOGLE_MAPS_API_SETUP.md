# 🗺️ Google Maps API Key Setup - REQUIRED

**Status**: ⚠️ Prototype 1 (Google Maps) requires a valid API key  
**Time to setup**: ~5 minutes

---

## Quick Setup Steps

### 1. Go to Google Cloud Console
👉 https://console.cloud.google.com/

### 2. Create New Project
- Click "Select a project" → "New Project"
- Name: **"Seasonal Quest Prototypes"**
- Click "Create"

### 3. Enable Required APIs
Navigate to **APIs & Services > Library**, then enable:
- ✅ **Maps JavaScript API**
- ✅ **Street View Static API** (optional, for better performance)
- ✅ **Geolocation API** (optional, for Prototype 2)

### 4. Create API Key
- Go to **APIs & Services > Credentials**
- Click **"Create Credentials"** → **"API Key"**
- Copy the generated key (looks like: `AIzaSyBxxxxxxxxxxxxxxxxxxxxxxx`)

### 5. Restrict API Key (Security)
Click **"Restrict Key"** on your new API key:

**Application restrictions**:
- Select: **HTTP referrers (websites)**
- Add referrers:
  ```
  http://localhost:*
  http://127.0.0.1:*
  ```

**API restrictions**:
- Select: **Restrict key**
- Choose: 
  - ✅ Maps JavaScript API
  - ✅ Street View Static API
  - ✅ Geolocation API

Click **Save**.

---

## 6. Add Key to Project

Edit `web/index.html` and replace **`YOUR_API_KEY_HERE`** with your actual key:

```html
<script>
  window.GOOGLE_MAPS_API_KEY = "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxx";
</script>
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBxxxxxxxxxxxxxxxxxxxxxxx&libraries=places,geometry" defer></script>
```

**⚠️ IMPORTANT**: Do NOT commit your API key to Git! Add it to `.gitignore`:
```
web/index.html
```

---

## 7. Verify Setup

```powershell
# Run Prototype 1 to test Google Maps
flutter run -d chrome lib/prototype_1_google_maps.dart
```

**Expected**:
- ✅ Map loads with 3 quest markers
- ✅ No "InvalidKeyMapError" in browser console

**If errors**:
- ❌ "InvalidKeyMapError" → Check API key restrictions
- ❌ "RefererNotAllowedMapError" → Add localhost to HTTP referrers
- ❌ Map grey with "For development purposes only" watermark → API key not restricted (OK for dev)

---

## Free Tier Limits (Google Maps)

**You have 28,000 FREE map loads per month**, which equals:
- ~933 loads/day
- More than enough for family prototyping

**Cost after free tier**: $7 per 1,000 map loads (you won't hit this during development)

**Billing**: You can set up billing alerts at $0 (will notify before charges)

---

## Alternative: Skip Google Maps for Now

If you don't want to set up Google Maps API key right now:

1. **Test Prototype 2 instead** (Geolocation doesn't require API key):
   ```powershell
   flutter run -d chrome lib/prototype_2_geolocation.dart
   ```

2. **Create prototypes 3-5** (webcam, localstorage, keyboard nav - no API keys needed)

3. **Come back to Google Maps later** when ready to test virtual exploration feature

---

## Need Help?

- **Google Maps API Docs**: https://developers.google.com/maps/documentation/javascript
- **Flutter Web Setup**: https://docs.flutter.dev/platform-integration/web
- **Cost Calculator**: https://mapsplatform.google.com/pricing/

---

## Quick Reference

| Prototype | Requires Google Maps API? | Can Test Now? |
|-----------|---------------------------|---------------|
| 1. Google Maps + Street View | ✅ YES | ❌ Need API key |
| 2. Browser Geolocation | ❌ NO | ✅ Ready! |
| 3. Webcam Capture | ❌ NO | ⏳ To create |
| 4. LocalStorage Performance | ❌ NO | ⏳ To create |
| 5. Keyboard Navigation | ❌ NO | ⏳ To create |

**Recommendation**: Get API key now (5 min) to unlock full prototype testing!
