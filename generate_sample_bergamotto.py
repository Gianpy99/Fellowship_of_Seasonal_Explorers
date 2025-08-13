import os
import json
from pathlib import Path
from diffusers import StableDiffusionPipeline
import torch

# === CONFIGURAZIONE ===
JSON_FILE = "seasonal_db_complete_story_cards__WITH_3x_stories.json"
OUTPUT_DIR = Path("sample_image")
OUTPUT_DIR.mkdir(exist_ok=True)

# Parametri
IMAGE_SIZE = (768, 768)       
NUM_INFERENCE_STEPS = 45      
GUIDANCE_SCALE = 9.0          

# Modello base
MODEL_ID = "nitrosocke/Ghibli-Diffusion"

# Stile
STYLE_DESCRIPTION = (
    "beautiful whimsical illustration, Studio Ghibli style, "
    "Disney magic, Tolkien fantasy atmosphere, "
    "lush landscapes, enchanted forest, warm natural light, "
    "highly detailed, family-friendly, soft yet vibrant colors"
)

# === CARICA MODELLO ===
pipe = StableDiffusionPipeline.from_pretrained(
    MODEL_ID,
    torch_dtype=torch.float16
).to("cuda")

def main():
    with open(JSON_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    products = data.get("products", data)

    bergamotto = next(
        (p for p in products if p.get("name_it", "").lower() == "bergamotto"),
        None
    )

    if not bergamotto:
        print("❌ Bergamotto non trovato nel JSON.")
        return

    story_text = bergamotto.get("story", {}).get("it", [""])[0]
    name_it = bergamotto.get("name_it", "Prodotto")
    name_en = bergamotto.get("name_en", "Product")

    filename = OUTPUT_DIR / f"{name_en.lower().replace(' ', '_')}_sample.png"

    prompt = (
        f"{STYLE_DESCRIPTION}, "
        f"scene depicting: {story_text}, "
        f"main focus on {name_en} ({name_it})"
    )

    print(f"🎨 Generazione immagine di esempio per {name_it}...")
    image = pipe(
        prompt=prompt,
        height=IMAGE_SIZE[0],
        width=IMAGE_SIZE[1],
        guidance_scale=GUIDANCE_SCALE,
        num_inference_steps=NUM_INFERENCE_STEPS
    ).images[0]

    image.save(filename)
    print(f"✅ Immagine salvata in: {filename}")

if __name__ == "__main__":
    main()
