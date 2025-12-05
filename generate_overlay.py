import numpy as np
from PIL import Image

def generate_paper_overlay(width, height, output_filename="oled_paper_overlay.png"):
    print(f"Generating {width}x{height} OLED Paper Overlay...")

    # --- CONFIGURATION (Specific Values) ---
    # 1. The Illuminant: Warm D50 White
    PAPER_RGB = (248, 242, 230) 
    
    # 2. Base Opacity: 10% (0.10)
    # This ensures black pixels become dark grey (Ink) 
    # and white pixels become off-white (Paper).
    BASE_OPACITY = 0.10
    
    # 3. Texture Strength: +/- 3%
    # Alpha will drift between 0.07 and 0.13
    NOISE_VARIANCE = 0.03 

    # --- PROCESSING ---

    # 1. Generate "Tooth" (High Frequency Noise)
    # Pixel-by-pixel roughness
    noise_tooth = np.random.normal(0, 1, (height, width))

    # 2. Generate "Pulp" (Low Frequency Noise)
    # Simulates fiber clumping by generating small noise and scaling it up
    scale_factor = 4
    low_res_h, low_res_w = height // scale_factor, width // scale_factor
    noise_pulp_raw = np.random.normal(0, 1, (low_res_h, low_res_w))
    
    # Upscale pulp noise using Bicubic interpolation for smoothness
    img_pulp = Image.fromarray(noise_pulp_raw).resize((width, height), resample=Image.BICUBIC)
    noise_pulp = np.array(img_pulp)

    # 3. Combine Noises (70% Tooth, 30% Pulp)
    combined_noise = (noise_tooth * 0.7) + (noise_pulp * 0.3)

    # Normalize noise to be between -1 and 1
    combined_noise = (combined_noise - combined_noise.min()) / (combined_noise.max() - combined_noise.min())
    combined_noise = (combined_noise * 2) - 1

    # 4. Create the Density Map (Alpha Channel)
    # Formula: Base + (Noise * Variance)
    alpha_map = BASE_OPACITY + (combined_noise * NOISE_VARIANCE)
    
    # Convert to 0-255 integer range
    alpha_map = (alpha_map * 255).clip(0, 255).astype(np.uint8)

    # 5. Build the Final Image
    # Create constant R, G, B layers
    r = np.full((height, width), PAPER_RGB[0], dtype=np.uint8)
    g = np.full((height, width), PAPER_RGB[1], dtype=np.uint8)
    b = np.full((height, width), PAPER_RGB[2], dtype=np.uint8)

    # Stack into RGBA
    final_image = np.dstack((r, g, b, alpha_map))
    
    # Save
    img = Image.fromarray(final_image, 'RGBA')
    img.save(output_filename)
    print(f"Done. Saved to {output_filename}")

# --- EXECUTION ---
# Change these dimensions to match your target screen
generate_paper_overlay(1920, 1080)
