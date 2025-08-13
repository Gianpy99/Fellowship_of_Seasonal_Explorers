import os
import json
from pathlib import Path
from diffusers import StableDiffusionPipeline
import torch

# === CONFIGURAZIONE ===
JSON_FILE = "seasonal_db_complete_story_cards__WITH_3x_stories.json"
OUTPUT_DIR = Path("images_story_scenes")
OUTPUT_DIR.mkdir(exist_ok=True)

# Parametri di generazione
IMAGE_SIZE = (768, 768)       # adatto a GTX1660
NUM_INFERENCE_STEPS = 45      # dettagli alti
GUIDANCE_SCALE = 9.0          # più alto = più aderente al prompt

# Modello base Ghibli
MODEL_ID = "nitrosocke/Ghibli-Diffusion"

# Stile visivo mixato
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
).to("cuda")  # usa GPU NVIDIA

def generate_image(prompt, filename):
    """Genera immagine e salva in cartella"""
    print(f"Generazione: {filename}")
    image = pipe(
        prompt=prompt,
        height=IMAGE_SIZE[0],
        width=IMAGE_SIZE[1],
        guidance_scale=GUIDANCE_SCALE,
        num_inference_steps=NUM_INFERENCE_STEPS
    ).images[0]
    image.save(OUTPUT_DIR / filename)
    print(f"Salvata: {OUTPUT_DIR / filename}")

def main():
    with open(JSON_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    products = data.get("products", data)

    for p in products:
        name_it = p.get("name_it", "Prodotto")
        name_en = p.get("name_en", "Product")
        stories_it = p.get("story", {}).get("it", [])

        for idx, story_text in enumerate(stories_it, start=1):
            filename = f"{name_en.lower().replace(' ', '_')}_story{idx}.png"

            # Prompt personalizzato con il testo della storia
            prompt = (
                f"{STYLE_DESCRIPTION}, "
                f"scene depicting: {story_text}, "
                f"main focus on {name_en} ({name_it})"
            )

            generate_image(prompt, filename)

if __name__ == "__main__":
    main()
