"""Chroma-key, seam-check and preview Jet lot 3; does not modify assets/jet."""
from pathlib import Path
from PIL import Image, ImageChops
import math

ROOT = Path.cwd()
OUT = ROOT / "art_review/jet/lot3"
RAW = OUT / "raw"
PREVIEW = OUT / "_preview"
RAW.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)
GEN = Path(r"C:\Users\<user>\.codex\generated_images\01a1fd59-14c0-7ad3-93a4-94dd6f3c0b6e")
sources = {
    "jet_sweep": GEN / "exec-56c3ebc5-1a26-4a50-a524-a62291e9b823.png",
    "jet_gate_block": GEN / "exec-73397d37-3f63-42c9-bc4a-99369be2dbc6.png",
    "jet_gate_lip": GEN / "exec-7ece6f2b-ae3b-4bfa-9f29-4124f5a2dfd6.png",
    "jet_wind_arrow": GEN / "exec-7fdf0c22-4ccf-45de-a662-470dcc0a1126.png",
}
for key, path in sources.items():
    Image.open(path).save(RAW / f"{key}_generated.png")

MAGENTA = (255, 0, 255)
GREEN = (0, 255, 0)

def key_image(image, key):
    image = image.convert("RGB")
    out = Image.new("RGBA", image.size)
    src, dst = image.load(), out.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b = src[x, y]
            dist = math.dist((r, g, b), key)
            alpha = max(0, min(255, round((dist - 20) * 255 / 45)))
            if key == GREEN and g > r + 20 and g > b + 20 and dist < 60:
                alpha = 0
            if key == MAGENTA and r > g + 20 and b > g + 20 and dist < 60:
                alpha = 0
            if 0 < alpha < 255:
                if key == GREEN:
                    g = min(g, max(r, b))
                else:
                    neutral = max(g, min(r, b))
                    r = min(r, neutral)
                    b = min(b, neutral)
            dst[x, y] = (r, g, b, alpha)
    return out

def bbox_alpha(im, threshold=8):
    return im.getchannel("A").point(lambda a: 255 if a > threshold else 0).getbbox()

def fit_frame(subject, size, pad=(4, 4)):
    bb = bbox_alpha(subject, 8)
    subject = subject.crop(bb)
    target = (size[0] - 2 * pad[0], size[1] - 2 * pad[1])
    subject.thumbnail(target, Image.Resampling.LANCZOS)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(subject, ((size[0] - subject.width) // 2, (size[1] - subject.height) // 2))
    return out

def scrub_key(im, key):
    if key is None: return im
    p = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = p[x, y]
            if a and math.dist((r, g, b), key) < 7:
                p[x, y] = (r, g, b, 0)
            elif a and key == MAGENTA and r > g + 20 and b > g + 20:
                # This batch reserves all magenta/purple hues for the key; remove dark fringe lines too.
                p[x, y] = (r, g, b, 0)
            elif a and key == GREEN and g > r + 20 and g > b + 20:
                # Green is reserved for the key on the gate assets.
                p[x, y] = (r, g, b, 0)
    return im

def panel_frames(path, count, key, size, pad, inset=0):
    im = Image.open(path).convert("RGB")
    cuts = [round(im.width * i / count) for i in range(count + 1)]
    frames = []
    for i in range(count):
        x0, x1 = cuts[i] + inset, cuts[i + 1] - inset
        cell = im.crop((x0, 0, x1, im.height))
        keyed = key_image(cell, key)
        frame = fit_frame(keyed, size, pad)
        frames.append(scrub_key(frame, key))
    return frames

def make_sweep():
    source = Image.open(RAW / "jet_sweep_generated.png").convert("RGB")
    cuts = [round(source.width * i / 3) for i in range(4)]
    frames = []
    for i in range(3):
        cell = source.crop((cuts[i] + 5, 0, cuts[i + 1] - 5, source.height))
        keyed = key_image(cell, MAGENTA)
        bb = bbox_alpha(keyed, 8)
        subject = keyed.crop(bb).resize((32, 280), Image.Resampling.LANCZOS)
        frame = Image.new("RGBA", (48, 288), (0, 0, 0, 0))
        frame.alpha_composite(subject, (8, 4))
        frames.append(scrub_key(frame, MAGENTA))
    # Keep both electrode assemblies exactly identical across all frames.
    for f in frames[1:]:
        f.paste(frames[0].crop((0, 0, 48, 28)), (0, 0))
        f.paste(frames[0].crop((0, 260, 48, 288)), (0, 260))
    for i, f in enumerate(frames): f.save(RAW / f"jet_sweep_hum_{i:03}.png")
    return frames

def seamless_vertical(im, band=8):
    p = im.load()
    for x in range(im.width):
        seam = tuple((p[x, 0][k] + p[x, im.height - 1][k]) // 2 for k in range(4))
        top = [p[x, y] for y in range(band)]
        bottom = [p[x, im.height - band + y] for y in range(band)]
        for y in range(band):
            t = (y + 1) / band
            p[x, y] = tuple(round(top[y][k] * (1 - t) + seam[k] * t) for k in range(4))
            p[x, im.height - band + y] = tuple(round(bottom[y][k] * (1 - t) + seam[k] * t) for k in range(4))
        p[x, 0] = p[x, im.height - 1] = seam
    return im

def make_gate_block():
    keyed = key_image(Image.open(RAW / "jet_gate_block_generated.png"), GREEN)
    bb = bbox_alpha(keyed, 8)
    subject = keyed.crop(bb)
    # Crop around the middle body, avoiding the original's decorative end caps.
    wanted_h = round(subject.width * 256 / 88)
    if wanted_h < subject.height:
        y0 = (subject.height - wanted_h) // 2
        subject = subject.crop((0, y0, subject.width, y0 + wanted_h))
    subject = subject.resize((88, 256), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (96, 256), (0, 0, 0, 0))
    out.alpha_composite(subject, (4, 0))
    out = scrub_key(seamless_vertical(out), GREEN)
    # Keep a continuous, full-width stone-metal column on every row.
    p = out.load()
    for y in range(out.height):
        occupied = [x for x in range(out.width) if p[x, y][3] > 8]
        if occupied:
            left, right = min(occupied), max(occupied)
            if right - left + 1 < 84:
                left_color, right_color = p[left, y], p[right, y]
                for x in range(5, 91):
                    if x < left: p[x, y] = (*left_color[:3], 255)
                    elif x > right: p[x, y] = (*right_color[:3], 255)
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = p[x, y]
            if 9 <= a <= 40:
                p[x, y] = (r, g, b, 0)
    # Reassert exact vertical seam after hard removal of faint key fringe.
    for x in range(out.width):
        seam = p[x, 0]
        p[x, out.height - 1] = seam
    for y in range(out.height):
        candidates = [p[x, y] for x in range(20, 76) if p[x, y][3] > 40]
        if candidates:
            # Extend the column silhouette with a clean stone pixel from its interior.
            color = min(candidates, key=lambda c: max(0, c[1] - max(c[0], c[2])))
            for x in range(5, 91):
                if p[x, y][3] <= 8:
                    p[x, y] = (*color[:3], 255)
    out.save(RAW / "jet_gate_block.png")
    return out

def make_lips():
    im = Image.open(RAW / "jet_gate_lip_generated.png").convert("RGB")
    cuts = [round(im.width * i / 3) for i in range(4)]
    keyed_cells = [key_image(im.crop((cuts[i] + 8, 0, cuts[i + 1] - 8, im.height)), GREEN) for i in range(3)]
    # Use a shared union crop so all panels scale identically before forcing the static cap region equal.
    boxes = [bbox_alpha(cell, 8) for cell in keyed_cells]
    union = (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))
    frames = []
    for cell in keyed_cells:
        content = cell.crop(union)
        content.thumbnail((128, 48), Image.Resampling.LANCZOS)
        out = Image.new("RGBA", (128, 48), (0, 0, 0, 0))
        out.alpha_composite(content, ((128 - content.width) // 2, (48 - content.height) // 2))
        frames.append(scrub_key(out, GREEN))
    for f in frames[1:]: f.paste(frames[0].crop((0, 0, 128, 34)), (0, 0))
    for i, f in enumerate(frames): f.save(RAW / f"jet_gate_lip_spark_{i:03}.png")
    return frames

def make_arrow():
    keyed = key_image(Image.open(RAW / "jet_wind_arrow_generated.png"), MAGENTA)
    out = fit_frame(keyed, (96, 160), (12, 12))
    out = scrub_key(out, MAGENTA)
    out.save(RAW / "jet_wind_arrow.png")
    return out

def metrics(im, key):
    bb = bbox_alpha(im, 8)
    x0, y0, x1, y1 = bb
    alpha = im.getchannel("A")
    area = max(1, (x1 - x0) * (y1 - y0))
    haze = sum(1 for y in range(y0, y1) for x in range(x0, x1) if 9 <= alpha.getpixel((x, y)) <= 40)
    residue = sum(1 for r, g, b, a in im.getdata() if a and math.dist((r, g, b), key) < 7)
    full_rows = sum(all(alpha.getpixel((x, y)) > 40 for x in range(x0, x1)) for y in range(y0, y1))
    full_cols = sum(all(alpha.getpixel((x, y)) > 40 for y in range(y0, y1)) for x in range(x0, x1))
    row_pixels = [[x for x in range(im.width) if alpha.getpixel((x, y)) > 8] for y in range(im.height)]
    row_widths = [len(xs) for xs in row_pixels]
    row_spans = [max(xs) - min(xs) + 1 if xs else 0 for xs in row_pixels]
    margins = (x0, y0, im.width - x1, im.height - y1)
    return {"size": im.size, "bbox": bb, "margins": margins, "haze_pct": round(haze * 100 / area, 3), "key_residue": residue, "full_rows": full_rows, "full_cols": full_cols, "min_row_width_alpha_gt8": min(row_widths[y0:y1]), "min_row_span_alpha_gt8": min(row_spans[y0:y1])}

def mean_diff(a, b):
    return sum(abs(x - y) for p, q in zip(a.getdata(), b.getdata()) for x, y in zip(p, q)) / (a.width * a.height * 4)

def center(bb): return ((bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2)

def make_previews(sweep, block, lips, arrow):
    wind = Image.open(ROOT / "assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png").convert("RGBA")
    wind = wind.crop(wind.getchannel("A").getbbox())
    wind.thumbnail((88, 135), Image.Resampling.LANCZOS)
    arrow_shown = arrow.resize((36, 60), Image.Resampling.LANCZOS)
    arrow_down = arrow_shown.transpose(Image.Transpose.ROTATE_180)

    for label, bg in (("dark", (18, 16, 42, 255)), ("light", (235, 235, 235, 255))):
        canvas = Image.new("RGBA", (1500, 1120), bg)
        canvas.alpha_composite(wind, (32, 28))
        for i, f in enumerate(sweep): canvas.alpha_composite(f, (160 + i * 58, 24))
        canvas.alpha_composite(arrow_shown, (360, 75))
        canvas.alpha_composite(arrow_down, (410, 75))

        # Three gate previews, each showing a different spark frame. World gap = 300 px.
        xs = (650, 920, 1190)
        for idx, x in enumerate(xs):
            shown_block = block.resize((70, 256), Image.Resampling.LANCZOS)
            canvas.alpha_composite(shown_block, (x, 80))
            lip = lips[idx]
            canvas.alpha_composite(lip, (x - 29, 336))
            canvas.alpha_composite(lip.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (x - 29, 684))
            canvas.alpha_composite(shown_block, (x, 732))
        # Separate native-size lip row makes all three spark silhouettes inspectable.
        for i, f in enumerate(lips): canvas.alpha_composite(f, (650 + i * 140, 1010))
        canvas.save(PREVIEW / f"jet_lot3_preview_{label}.png")

    stacked = Image.new("RGBA", (96, 256 * 3), (18, 16, 42, 255))
    for i in range(3): stacked.alpha_composite(block, (0, i * 256))
    stacked.save(PREVIEW / "jet_gate_block_three_tiles.png")

sweep = make_sweep()
block = make_gate_block()
lips = make_lips()
arrow = make_arrow()
make_previews(sweep, block, lips, arrow)

for i, frame in enumerate(sweep): print("sweep", i, metrics(frame, MAGENTA))
centers = [center(bbox_alpha(f, 8)) for f in sweep]
print("sweep_center_positions", centers, "max_dx", max(c[0] for c in centers) - min(c[0] for c in centers), "max_dy", max(c[1] for c in centers) - min(c[1] for c in centers))
print("sweep_cap_diffs", [mean_diff(sweep[0].crop((0,0,48,28)), f.crop((0,0,48,28))) + mean_diff(sweep[0].crop((0,260,48,288)), f.crop((0,260,48,288))) for f in sweep])
print("gate_block", metrics(block, GREEN), "seam_first_last_mean_rgba", mean_diff(block.crop((0,0,96,1)), block.crop((0,255,96,256))))
for i, frame in enumerate(lips): print("gate_lip", i, metrics(frame, GREEN), "top34_diff_from_0", mean_diff(lips[0].crop((0,0,128,34)), frame.crop((0,0,128,34))))
print("wind_arrow", metrics(arrow, MAGENTA))
for y in range(arrow.height):
    n = sum(arrow.getchannel("A").getpixel((x,y)) > 8 for x in range(arrow.width))
    if y < 18: print("arrow_top_row_widths", y, n)
