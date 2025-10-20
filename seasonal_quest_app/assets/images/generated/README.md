# Generated AI Images

This folder contains AI-generated images from Gemini 2.5 Flash Image.

## Workflow to add generated images:

### 1. Generate image in the app
- Open a product detail page
- Click "Generate Product Icon" or "Generate AI Illustration"
- Wait for generation (10-30 seconds)
- Image will be shown in a popup dialog
- Click "Download" to save the PNG file

### 2. Move file to this folder
Copy the downloaded PNG file from your Downloads folder to:
```
seasonal_quest_app/assets/images/generated/
```

### 3. Update the JSON
Edit `assets/seasonal_data.json` and add the path:

**For product icon:**
```json
{
  "id": "bergamotto_calabria",
  "generated_icon_path": "assets/images/generated/bergamot_icon.png",
  ...
}
```

**For story images:**
```json
{
  "id": "bergamotto_calabria",
  "generated_story_paths": [
    "assets/images/generated/bergamot_story_0.png",
    "assets/images/generated/bergamot_story_1.png",
    "assets/images/generated/bergamot_story_2.png"
  ],
  ...
}
```

### 4. Hot reload
Press `r` in the Flutter terminal to hot reload the app.
The new images will appear immediately in:
- Home screen (quest cards)
- Detail page (hero image)
- Story section (above story text)

## Naming convention:
- **Icons**: `{product_name_en}_icon.png`
- **Stories**: `{product_name_en}_story_{index}.png`
- **Recipes**: `{product_name_en}_recipe.png`

Example:
- `bergamot_icon.png`
- `bergamot_story_0.png`
- `red_onion_icon.png`

## Storage benefits:
- ✅ Images bundled with app (no runtime download)
- ✅ Works offline
- ✅ Fast loading (compiled assets)
- ✅ Version controlled in Git
- ✅ No LocalStorage size limits
