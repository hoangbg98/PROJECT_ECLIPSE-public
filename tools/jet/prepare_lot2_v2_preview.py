"""Prepare Jet lot 2 v2 review images; never writes into assets/jet."""
from pathlib import Path
from PIL import Image
import math

ROOT = Path.cwd()
OUT = ROOT / "art_review/jet/lot2_v2"
RAW = OUT / "raw"
PREVIEW = OUT / "_preview"
RAW.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)

# Preserve the source image used for this v2 iteration in the review folder.
generated = Path(r"C:\Users\<user>\.codex\generated_images\01a1fd59-14c0-7ad3-93a4-94dd6f3c0b6e\exec-e85c6956-745b-4ccd-882f-67dcea5e50b0.png")
source_raw = RAW / "jet_beam_body_v2_key_green_source.png"
if generated.exists():
    Image.open(generated).save(source_raw)

def remove_key(im, key=(0, 255, 0)):
    im = im.convert("RGB")
    out = Image.new("RGBA", im.size)
    src, dst = im.load(), out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b = src[x, y]
            d = math.dist((r, g, b), key)
            a = max(0, min(255, round((d - 28) * 255 / 34)))
            if g > r + 24 and g > b + 24 and d < 60:
                a = 0
            if 0 < a < 255:
                # Remove the green key tint from antialiased edge pixels.
                g = min(g, max(r, b))
            dst[x, y] = (r, g, b, a)
    return out

def find_bbox(image, threshold=8):
    return image.getchannel("A").point(lambda a: 255 if a > threshold else 0).getbbox()

def make_beam_v2():
    keyed = remove_key(Image.open(source_raw))
    bbox = find_bbox(keyed, 8)
    subject = keyed.crop(bbox)
    # Crop a centered horizontal section with 128:28 aspect, then resize to the
    # exact body thickness required by the 128x40 texture frame.
    crop_width = min(subject.width, round(subject.height * 128 / 28))
    left = (subject.width - crop_width) // 2
    subject = subject.crop((left, 0, left + crop_width, subject.height))
    subject = subject.resize((128, 28), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (128, 40), (0, 0, 0, 0))
    frame.alpha_composite(subject, (0, 6))
    # Crossfade edge neighborhoods, then force the tile's outer columns equal.
    px = frame.load()
    for y in range(frame.height):
        left_edge, right_edge = px[4, y], px[123, y]
        seam = tuple((left_edge[k] + right_edge[k]) // 2 for k in range(4))
        for x in range(5):
            t = (x + 1) / 6
            lc, rc = px[x, y], px[127 - x, y]
            px[x, y] = tuple(round(lc[k] * (1 - t) + seam[k] * t) for k in range(4))
            px[127 - x, y] = tuple(round(rc[k] * (1 - t) + seam[k] * t) for k in range(4))
        px[0, y] = px[127, y] = seam
    result = RAW / "jet_beam_body_v2.png"
    frame.save(result)
    return frame

def clean_missile_frames():
    source_dir = ROOT / "assets/jet/jet_missile/fly"
    dest_dir = RAW / "fly_v2"
    dest_dir.mkdir(parents=True, exist_ok=True)
    frames = []
    for i in range(4):
        src = Image.open(source_dir / f"jet_missile_fly_{i:03}.png").convert("RGBA")
        p = src.load()
        before = 0
        # The two known chroma-key remnants are exactly at rows 12 and 115.
        # Clear only the dark green fringe pixels there; preserve all artwork.
        for y in (12, 115):
            for x in range(src.width):
                r, g, b, a = p[x, y]
                if a and g > r + 8 and g > b + 8 and r < 12 and b < 12 and a < 160:
                    p[x, y] = (r, g, b, 0)
                    before += 1
        out = dest_dir / f"jet_missile_fly_v2_{i:03}.png"
        src.save(out)
        frames.append(src)
        print(f"missile_{i:03}: cleared {before} green-fringe pixels")
    return frames

def bbox_measure(frame):
    x0, y0, x1, y1 = find_bbox(frame, 8)
    a = frame.getchannel("A")
    edges = ([a.getpixel((x0, y)) for y in range(y0, y1)],
             [a.getpixel((x1 - 1, y)) for y in range(y0, y1)],
             [a.getpixel((x, y0)) for x in range(x0, x1)],
             [a.getpixel((x, y1 - 1)) for x in range(x0, x1)])
    pct = [round(100 * sum(v > 40 for v in edge) / len(edge), 2) for edge in edges]
    full_rows = sum(all(a.getpixel((x, y)) > 40 for x in range(x0, x1)) for y in range(y0, y1))
    full_cols = sum(all(a.getpixel((x, y)) > 40 for y in range(y0, y1)) for x in range(x0, x1))
    return (x0, y0, x1, y1), pct, full_rows, full_cols

def make_previews(beam, missiles):
    node = Image.open(ROOT / "assets/jet/jet_beam_node/pulse/jet_beam_node_pulse_001.png").convert("RGBA")
    node = node.resize((28, 28), Image.Resampling.LANCZOS)
    wind = Image.open(ROOT / "assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png").convert("RGBA")
    wind = wind.crop(wind.getchannel("A").getbbox())
    wind.thumbnail((88, 135), Image.Resampling.LANCZOS)
    tiled = Image.new("RGBA", (384, 40), (0, 0, 0, 0))
    for x in range(0, 384, 128):
        tiled.alpha_composite(beam, (x, 0))
    # 3-tile seam check artifact before rotation.
    tiled.save(PREVIEW / "jet_beam_body_v2_three_tiles.png")
    rotated = tiled.rotate(45, expand=True, resample=Image.Resampling.BICUBIC)
    assembled = Image.new("RGBA", (rotated.width + 28, rotated.height + 28), (0, 0, 0, 0))
    assembled.alpha_composite(rotated, (14, 14))
    # Circular caps at the visual ends of the 45-degree bar.
    assembled.alpha_composite(node, (8, assembled.height - 36))
    assembled.alpha_composite(node, (assembled.width - 36, 8))

    for label, color in (("dark", (18, 16, 42, 255)), ("light", (235, 235, 235, 255))):
        canvas = Image.new("RGBA", (1100, 610), color)
        canvas.alpha_composite(wind, (38, 48))
        canvas.alpha_composite(assembled, (170, 180))
        for i, frame in enumerate(missiles):
            shown = frame.resize((100, 67), Image.Resampling.LANCZOS)
            canvas.alpha_composite(shown, (570 + i * 125, 72))
        canvas.save(PREVIEW / f"jet_lot2_v2_preview_{label}.png")

beam = make_beam_v2()
missiles = clean_missile_frames()
make_previews(beam, missiles)

bb = find_bbox(beam, 8)
left, right = list(beam.crop((0, 0, 1, 40)).getdata()), list(beam.crop((127, 0, 128, 40)).getdata())
edge_delta = sum(abs(a[k] - b[k]) for a, b in zip(left, right) for k in range(4)) / (40 * 4)
print(f"beam: size={beam.size}, bbox={bb}, thickness={bb[3]-bb[1]}px, center_y={(bb[1]+bb[3])/2:.1f}, edge_delta_mean_rgba={edge_delta:.3f}")
for i, frame in enumerate(missiles):
    bb, pct, full_rows, full_cols = bbox_measure(frame)
    print(f"missile_{i:03}: size={frame.size}, bbox={bb}, edge_gt40_percent_LRTB={pct}, full_alpha_rows={full_rows}, full_alpha_cols={full_cols}")
