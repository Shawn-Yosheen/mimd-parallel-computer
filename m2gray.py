import re
import numpy as np
from PIL import Image

# Load the memory dump file content
with open('/mnt/data/memory.txt', 'r') as file:
    memory_dump = file.read()

# Extract the nibble values from memory dump, reading each word from right to left
nibble_values = []
for match in re.finditer(r'/([0-9A-Fa-f]{8})', memory_dump):
    word = match.group(1)
    # Reverse the word to read from right to left
    nibble_values.extend(int(nibble, 16) for nibble in reversed(word))

# Convert nibbles to grayscale values (0-255)
grayscale_values = [nibble * 17 for nibble in nibble_values]

# Define image dimensions
k_VGA_WIDTH, k_VGA_HEIGHT = 160, 120
image_data = np.array(grayscale_values[:k_VGA_WIDTH * k_VGA_HEIGHT], dtype=np.uint8).reshape(k_VGA_HEIGHT, k_VGA_WIDTH)

# Save the grayscale image
final_image_path = '/mnt/data/final_output_image_simplified.png'
Image.fromarray(image_data, mode='L').save(final_image_path)

# Save the binary grayscale data to a text file
output_path = '/mnt/data/simplified_binary_grayscale_data.txt'
with open(output_path, 'w') as f:
    f.writelines(f'{value:08b}\n' for value in grayscale_values[:k_VGA_WIDTH * k_VGA_HEIGHT])

# Return the paths for downloading the simplified results
output_path, final_image_path
