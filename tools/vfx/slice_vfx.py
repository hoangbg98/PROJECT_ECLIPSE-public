"""Slice a single-row VFX strip into centered, equally sized RGBA frames.

Usage:
  python -I tools/vfx/slice_vfx.py --layer phoenix --frames 5 --strip phoenix.png --out-dir art_review/char_fire_01/ultimate_vfx --chroma FF00FF
"""
import argparse
import os

from PIL import Image, ImageColor


def remove_chroma(image, color_hex, tolerance):
    image = image.convert("RGBA")
    key = ImageColor.getrgb("#" + color_hex.lstrip("#")) if color_hex else (255, 0, 255)
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            distance = max(abs(r - key[0]), abs(g - key[1]), abs(b - key[2]))
            magenta_spill = (r > 100 and b > 90 and g < 100 and b > g + 35 and b > r * 0.40)
            if distance == 0 or (color_hex and distance <= tolerance) or (color_hex and key == (255, 0, 255) and magenta_spill):
                pixels[x, y] = (0, 0, 0, 0)
            elif distance < tolerance * 2:
                pixels[x, y] = (r, g, b, round(a * (distance - tolerance) / tolerance))
    return image


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--layer", required=True)
    parser.add_argument("--frames", required=True, type=int)
    parser.add_argument("--strip", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--chroma", default=None)
    parser.add_argument("--tolerance", type=int, default=48)
    args = parser.parse_args()

    strip = remove_chroma(Image.open(args.strip), args.chroma, args.tolerance)
    if strip.width < args.frames or strip.height < 1:
        raise SystemExit("Strip dimensions are too small for the requested frame count.")
    cells = []
    for index in range(args.frames):
        x0 = round(index * strip.width / args.frames)
        x1 = round((index + 1) * strip.width / args.frames)
        cell = strip.crop((x0, 0, x1, strip.height))
        bounds = cell.getchannel("A").getbbox()
        cells.append(cell.crop(bounds) if bounds else Image.new("RGBA", (1, 1)))

    canvas_size = (max(cell.width for cell in cells), max(cell.height for cell in cells))
    os.makedirs(args.out_dir, exist_ok=True)
    layer_dir = os.path.join(args.out_dir, args.layer)
    os.makedirs(layer_dir, exist_ok=True)
    for index, cell in enumerate(cells):
        canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
        canvas.alpha_composite(cell, ((canvas_size[0] - cell.width) // 2,
                                     (canvas_size[1] - cell.height) // 2))
        canvas.save(os.path.join(layer_dir, "%s_%03d.png" % (args.layer, index)))
    print("Wrote %d %s frames at %dx%d." % (args.frames, args.layer, *canvas_size))


if __name__ == "__main__":
    main()
