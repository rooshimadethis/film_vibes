import numpy as np
from PIL import Image

def generate_paper_texture(width, height, output_filename="assets/paper_texture.png"):
    print(f"Generating {width}x{height} Paper Texture...")

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

    # Normalize noise to be between 0 and 1 for Alpha
    combined_noise = (combined_noise - combined_noise.min()) / (combined_noise.max() - combined_noise.min())
    
    # 4. Create the Image
    # We want a texture we can overlay. 
    # Let's make it pure White (255, 255, 255) with the Noise as the Alpha channel.
    # This allows tinting in Flutter.
    
    alpha_map = (combined_noise * 255).astype(np.uint8)
    
    r = np.full((height, width), 255, dtype=np.uint8)
    g = np.full((height, width), 255, dtype=np.uint8)
    b = np.full((height, width), 255, dtype=np.uint8)

    # Stack into RGBA
    final_image = np.dstack((r, g, b, alpha_map))
    
    # Save
    img = Image.fromarray(final_image, 'RGBA')
    img.save(output_filename)
    print(f"Done. Saved to {output_filename}")

# --- EXECUTION ---
# 1080p is usually sufficient for texture if we tile or stretch, 
# but let's match the previous resolution for quality.
generate_paper_texture(1920, 1080)
