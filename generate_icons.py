import math
import os
from PIL import Image, ImageDraw

def render_brand_logo(size=1024):
    # Create RGBA image with transparent background
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 1. Draw rounded container (Obsidian Slate with subtle border)
    pad = int(size * 0.04) # 4% padding for clean launcher icon inset
    box = [pad, pad, size - pad, size - pad]
    radius = int(size * 0.26)
    
    # Background fill #0F172A
    draw.rounded_rectangle(box, radius=radius, fill=(15, 23, 42, 255), outline=(51, 65, 85, 255), width=max(2, int(size * 0.015)))
    
    # 2. Draw Leaf & Ledger geometry
    cx = size / 2
    cy = size / 2
    inner_w = (size - 2 * pad) * 0.68
    r = inner_w / 2 # ~320px
    
    # Helper to calculate cubic bezier points
    def cubic_bezier(p0, p1, p2, p3, n_points=50):
        points = []
        for i in range(n_points + 1):
            t = i / float(n_points)
            x = (1-t)**3 * p0[0] + 3*(1-t)**2 * t * p1[0] + 3*(1-t) * t**2 * p2[0] + t**3 * p3[0]
            y = (1-t)**3 * p0[1] + 3*(1-t)**2 * t * p1[1] + 3*(1-t) * t**2 * p2[1] + t**3 * p3[1]
            points.append((x, y))
        return points

    # Right lobe (Light Emerald: #10B981 / (16, 185, 129))
    p0 = (cx, cy - r)
    p1 = (cx + r * 0.58, cy - r)
    p2 = (cx + r, cy - r * 0.58)
    p3 = (cx + r, cy)
    p4 = (cx + r, cy + r * 0.58)
    p5 = (cx + r * 0.58, cy + r)
    p6 = (cx, cy + r)
    
    right_points = cubic_bezier(p0, p1, p2, p3) + cubic_bezier(p3, p4, p5, p6)
    right_points.append((cx, cy - r))
    draw.polygon(right_points, fill=(16, 185, 129, 255))
    
    # Left lobe (Dark Emerald: #059669 / (5, 150, 105))
    lp1 = (cx - r * 0.58, cy - r)
    lp2 = (cx - r, cy - r * 0.58)
    lp3 = (cx - r, cy)
    lp4 = (cx - r, cy + r * 0.58)
    lp5 = (cx - r * 0.58, cy + r)
    
    left_points = cubic_bezier(p0, lp1, lp2, lp3) + cubic_bezier(lp3, lp4, lp5, p6)
    left_points.append((cx, cy - r))
    draw.polygon(left_points, fill=(5, 150, 105, 255))
    
    # 3. Ledger spine down the center (#0F172A / (15, 23, 42))
    spine_w = max(3, int(r * 0.09))
    draw.line([(cx, cy - r * 0.82), (cx, cy + r * 0.82)], fill=(15, 23, 42, 255), width=spine_w)
    
    # 4. Faint tally-mark veins (#0F172A with ~45% alpha)
    vein_w = max(2, int(r * 0.06))
    for dy in [-r * 0.3, r * 0.3]:
        # Left vein
        draw.line([(cx - r * 0.5, cy + dy - r * 0.25), (cx, cy + dy)], fill=(15, 23, 42, 130), width=vein_w)
        # Right vein
        draw.line([(cx + r * 0.5, cy + dy - r * 0.25), (cx, cy + dy)], fill=(15, 23, 42, 130), width=vein_w)

    # 5. Amber harvest dot (#F59E0B / (245, 158, 11))
    dot_r = r * 0.16
    dot_cx = cx + r * 0.62
    dot_cy = cy - r * 0.62
    draw.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r], fill=(245, 158, 11, 255))
    
    return img

def main():
    base_res = r"c:\Users\SUQOON\Downloads\frontend\green_market\android\app\src\main\res"
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    
    master = render_brand_logo(1024)
    
    for folder, dim in sizes.items():
        folder_path = os.path.join(base_res, folder)
        os.makedirs(folder_path, exist_ok=True)
        icon = master.resize((dim, dim), Image.Resampling.LANCZOS)
        out_path = os.path.join(folder_path, "ic_launcher.png")
        icon.save(out_path, "PNG")
        print(f"Generated {out_path} ({dim}x{dim})")

if __name__ == "__main__":
    main()
