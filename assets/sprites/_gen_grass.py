"""Generate a seamless (tileable) pixel-art grass tile for the demo background.

Pure-procedural so it tiles perfectly: low-frequency wrapped value-noise selects
between a small green palette (soft patches), then sparse blades + flowers are
scattered with modulo wrap so partial features appear on both edges.
"""
import numpy as np
from PIL import Image

SIZE = 128
rng = np.random.default_rng(7)

# Grass palette (top-down), tuned around the old flat clear color (92,140,71).
# Low contrast between shades so the tiling repeat stays subtle.
PALETTE = np.array([
    [84, 126, 66],    # dark
    [93, 138, 72],    # base-dark
    [102, 150, 80],   # base-light
    [112, 162, 90],   # light
], dtype=np.float32)


def tileable_noise(size, cells):
    """Smooth value noise that wraps at the edges (bilinear upsample of a grid)."""
    grid = rng.random((cells, cells)).astype(np.float32)
    out = np.zeros((size, size), dtype=np.float32)
    step = size / cells
    for y in range(size):
        gy = y / step
        y0 = int(gy) % cells
        y1 = (y0 + 1) % cells
        fy = gy - int(gy)
        for x in range(size):
            gx = x / step
            x0 = int(gx) % cells
            x1 = (x0 + 1) % cells
            fx = gx - int(gx)
            top = grid[y0, x0] * (1 - fx) + grid[y0, x1] * fx
            bot = grid[y1, x0] * (1 - fx) + grid[y1, x1] * fx
            out[y, x] = top * (1 - fy) + bot * fy
    return out


# Two octaves of wrapped noise for soft, organic patches (lower freq -> gentler).
noise = 0.7 * tileable_noise(SIZE, 5) + 0.3 * tileable_noise(SIZE, 11)
noise += 0.05 * rng.random((SIZE, SIZE)).astype(np.float32)  # fine grain
noise = (noise - noise.min()) / (noise.max() - noise.min())

# Map noise -> palette index.
idx = np.clip((noise * len(PALETTE)).astype(int), 0, len(PALETTE) - 1)
img = PALETTE[idx]

# Sparse vertical grass blades (1px wide, 2-3px tall), wrapped.
for _ in range(340):
    bx, by = rng.integers(0, SIZE, 2)
    h = int(rng.integers(2, 4))
    shade = PALETTE[0] if rng.random() < 0.5 else PALETTE[-1]
    for k in range(h):
        img[(by + k) % SIZE, bx] = shade

# Sparse tiny flowers (1px), wrapped.
FLOWERS = np.array([[238, 238, 230], [240, 222, 96], [226, 150, 200]], dtype=np.float32)
for _ in range(22):
    fx, fy = rng.integers(0, SIZE, 2)
    img[fy % SIZE, fx % SIZE] = FLOWERS[rng.integers(0, len(FLOWERS))]

Image.fromarray(img.astype(np.uint8), "RGB").save("assets/sprites/grass_bg.png")
print("wrote assets/sprites/grass_bg.png", SIZE, "x", SIZE)
