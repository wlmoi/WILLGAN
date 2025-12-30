import numpy as np
from PIL import Image

# Path to output.mem (adjust if needed)
mem_path = '../../hardware/layers/output.mem'
# Output image path
out_img_path = 'output_layer3.png'

# Read output.mem (784 values, Q5.10 signed hex)
with open(mem_path, 'r') as f:
    lines = f.readlines()

# Convert hex to signed int16
vals = [int(x.strip(), 16) for x in lines]
vals = np.array([x if x < 0x8000 else x - 0x10000 for x in vals], dtype=np.int16)

# Q5.10 to float
floats = vals / 1024.0

# Normalize to 0-255 for image
minv, maxv = floats.min(), floats.max()
if maxv - minv < 1e-6:
    norm = np.zeros_like(floats)
else:
    norm = (floats - minv) / (maxv - minv)
img = (norm * 255).astype(np.uint8).reshape(28, 28)

# Save as PNG
Image.fromarray(img, mode='L').save(out_img_path)
print(f'Saved image to {out_img_path}')
