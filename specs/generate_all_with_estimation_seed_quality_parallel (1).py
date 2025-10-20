import os
import json
import random
import sys
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
from diffusers import StableDiffusionPipeline
import torch
from PIL import Image, ImageFilter

# === CONFIG ===
JSON_FILE = "seasonal_db_complete_story_cards__WITH_3x_stories.json"
OUTPUT_DIR_ICONS = Path("images_icons")
OUTPUT_DIR_SCENES = Path("images_story_scenes_random")
OUTPUT_DIR_RECIPES = Path("images_recipes")
MAPPING_FILE = "images_mapping.json"

OUTPUT_DIR_ICONS.mkdir(exist_ok=True)
OUTPUT_DIR_SCENES.mkdir(exist_ok=True)
OUTPUT_DIR_RECIPES.mkdir(exist_ok=True)

ICON_SIZE = (512, 512)
SCENE_SIZE = (768, 768)
RECIPE_SIZE = (640, 640)
NUM_INFERENCE_STEPS = 45
GUIDANCE_SCALE = 9.0

DEFAULT_SHARPNESS_THRESHOLD = 10.0
SHARPNESS_THRESHOLD = DEFAULT_SHARPNESS_THRESHOLD

AVG_GEN_TIME = 10
AVG_IMG_SIZE_MB = 1.5

MODEL_ID = "nitrosocke/Ghibli-Diffusion"

ICON_STYLE = (
    "charming illustration, Studio Ghibli style, "
    "simple background, centered subject, minimal details, "
    "soft warm colors, family-friendly, clean composition"
)

SCENE_STYLE = (
    "beautiful whimsical illustration, Studio Ghibli style, "
    "Disney magic, Tolkien fantasy atmosphere, "
    "lush landscapes, enchanted forest, warm natural light, "
    "highly detailed, family-friendly, soft yet vibrant colors"
)

RECIPE_STYLE = (
    "beautiful cooking illustration, Studio Ghibli style, "
    "storybook recipe art, cozy kitchen background, "
    "warm lighting, soft textures, whimsical and inviting, "
    "family-friendly, vibrant natural food colors"
)

VARIATIONS = [
    "sunset lighting",
    "early morning mist",
    "sparkles of magic in the air",
    "colorful market background",
    "forest clearing with flowers",
    "small animals watching curiously",
    "ancient ruins in the distance"
]

stats = {
    "total_images": 0,
    "icons": 0,
    "stories": 0,
    "recipes": 0,
    "time_start": 0,
    "time_end": 0
}

def estimate_generation(products, num_variations):
    total_icons = len(products)
    total_stories = 0
    total_recipes = 0
    for p in products:
        total_stories += len(p.get("story", {}).get("it", [])) * num_variations
        total_recipes += len(p.get("recipes", {}).get("it", []))
    total_images = total_icons + total_stories + total_recipes
    est_time = total_images * AVG_GEN_TIME
    est_size_mb = total_images * AVG_IMG_SIZE_MB
    est_size_gb = est_size_mb / 1024

    print("\\n📊 STIMA GENERAZIONE")
    print(f"Prodotti: {len(products)}")
    print(f" - Icone: {total_icons}")
    print(f" - Scene (varianti={num_variations}): {total_stories}")
    print(f" - Ricette: {total_recipes}")
    print(f"Totale immagini: {total_images}")
    print(f"Tempo stimato: {est_time/60:.1f} minuti (~{est_time/3600:.2f} ore)")
    print(f"Spazio stimato: {est_size_mb:.1f} MB (~{est_size_gb:.2f} GB)")
    print(f"VRAM consigliata: almeno 6 GB (GTX 1660 OK)")
    print(f"RAM consigliata: almeno 8 GB\\n")

    return total_images

def calculate_sharpness(image_path):
    img = Image.open(image_path)
    sharpness = img.filter(ImageFilter.FIND_EDGES).getextrema()[1]
    return sharpness

def save_and_check(image, filename, category):
    attempts = 0
    while attempts < 2:
        image.save(filename)
        sharpness = calculate_sharpness(filename)
        print(f"🔍 Nitidezza: {sharpness}")
        if sharpness >= SHARPNESS_THRESHOLD:
            print(f"✅ Salvata: {filename}")
            stats["total_images"] += 1
            stats[category] += 1
            return True
        else:
            print("⚠️ Bassa nitidezza, rigenero...")
            attempts += 1
    return False

def generate_image(pipe, prompt, filename, size, category, generator, executor):
    print(f"🎨 Generazione: {filename}")
    image = pipe(
        prompt=prompt,
        height=size[0],
        width=size[1],
        guidance_scale=GUIDANCE_SCALE,
        num_inference_steps=NUM_INFERENCE_STEPS,
        generator=generator
    ).images[0]
    executor.submit(save_and_check, image, filename, category)

def main():
    global SHARPNESS_THRESHOLD
    args = sys.argv[1:]
    num_variations = 1
    product_filter = None
    resume_mode = False
    preview_mode = False

    for arg in args:
        if arg.isdigit():
            num_variations = int(arg)
        elif arg.lower() == "--resume":
            resume_mode = True
        elif arg.lower() == "--preview":
            preview_mode = True
        elif arg.startswith("--min-sharpness"):
            try:
                SHARPNESS_THRESHOLD = float(arg.split("=")[1])
            except:
                print("⚠️ Valore --min-sharpness non valido, uso default:", DEFAULT_SHARPNESS_THRESHOLD)
                SHARPNESS_THRESHOLD = DEFAULT_SHARPNESS_THRESHOLD
        else:
            product_filter = arg.lower()

    with open(JSON_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    products = data.get("products", data)

    if product_filter:
        products = [p for p in products if product_filter in p.get("name_it", "").lower() or product_filter in p.get("name_en", "").lower()]

    estimate_generation(products, num_variations)
    if not preview_mode:
        proceed = input("Vuoi procedere con la generazione? (s/n): ").strip().lower()
        if proceed != "s":
            print("❌ Generazione annullata.")
            return

    mapping = {}
    if resume_mode and Path(MAPPING_FILE).exists():
        with open(MAPPING_FILE, "r", encoding="utf-8") as mf:
            mapping = json.load(mf)

    pipe = StableDiffusionPipeline.from_pretrained(MODEL_ID, torch_dtype=torch.float16).to("cuda")
    stats["time_start"] = time.time()

    with ThreadPoolExecutor(max_workers=2) as executor:
        for p in products:
            name_it = p.get("name_it", "Prodotto")
            name_en = p.get("name_en", "Product")
            seed = abs(hash(name_en)) % (2**32)
            generator = torch.Generator("cuda").manual_seed(seed)

            if name_en not in mapping:
                mapping[name_en] = {"icon": "", "stories": [], "recipes": []}

            icon_filename = OUTPUT_DIR_ICONS / f"{name_en.lower().replace(' ', '_')}_icon.png"
            if not resume_mode or not Path(icon_filename).exists():
                icon_prompt = f"{ICON_STYLE}, main focus on {name_en} ({name_it})"
                generate_image(pipe, icon_prompt, icon_filename, ICON_SIZE, "icons", generator, executor)
                mapping[name_en]["icon"] = str(icon_filename)

            stories_it = p.get("story", {}).get("it", [])
            for idx, story_text in enumerate(stories_it, start=1):
                for _ in range(num_variations):
                    random_variation = random.choice(VARIATIONS)
                    scene_filename = OUTPUT_DIR_SCENES / f"{name_en.lower().replace(' ', '_')}_story{idx}_{random_variation.replace(' ', '_')}.png"
                    if not resume_mode or not Path(scene_filename).exists():
                        scene_prompt = f"{SCENE_STYLE}, {random_variation}, scene depicting: {story_text}, main focus on {name_en} ({name_it})"
                        generate_image(pipe, scene_prompt, scene_filename, SCENE_SIZE, "stories", generator, executor)
                        mapping[name_en]["stories"].append(str(scene_filename))
                    if preview_mode:
                        break
                if preview_mode:
                    break

            recipes_it = p.get("recipes", {}).get("it", [])
            for ridx, recipe_text in enumerate(recipes_it, start=1):
                recipe_filename = OUTPUT_DIR_RECIPES / f"{name_en.lower().replace(' ', '_')}_recipe{ridx}.png"
                if not resume_mode or not Path(recipe_filename).exists():
                    recipe_prompt = f"{RECIPE_STYLE}, illustration of recipe: {recipe_text}, featuring {name_en} ({name_it}) as main ingredient"
                    generate_image(pipe, recipe_prompt, recipe_filename, RECIPE_SIZE, "recipes", generator, executor)
                    mapping[name_en]["recipes"].append(str(recipe_filename))
                if preview_mode:
                    break

            if preview_mode:
                break

        executor.shutdown(wait=True)

    stats["time_end"] = time.time()
    with open(MAPPING_FILE, "w", encoding="utf-8") as mf:
        json.dump(mapping, mf, indent=2, ensure_ascii=False)

    elapsed = stats["time_end"] - stats["time_start"]
    avg_time = elapsed / stats["total_images"] if stats["total_images"] else 0
    print("\\n📊 STATISTICHE FINALI")
    print(f"Tempo totale: {elapsed:.2f} sec")
    print(f"Immagini totali: {stats['total_images']}")
    print(f" - Icone: {stats['icons']}")
    print(f" - Storie: {stats['stories']}")
    print(f" - Ricette: {stats['recipes']}")
    print(f"Tempo medio per immagine: {avg_time:.2f} sec")

if __name__ == "__main__":
    main()
