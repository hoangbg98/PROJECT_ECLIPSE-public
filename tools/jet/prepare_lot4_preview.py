"""Key and tile Jet lot 4 ash backgrounds, measure them, and compose previews."""
from pathlib import Path
import math
from PIL import Image, ImageChops, ImageOps

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "art_review/jet/lot4"
RAW = BASE / "raw"
PREVIEW = BASE / "_preview"
PREVIEW.mkdir(parents=True, exist_ok=True)
GREEN = (0, 255, 0)
SIZE = (1920, 1080)


def key_green(image):
    image = image.convert("RGB")
    out = Image.new("RGBA", image.size)
    src, dst = image.load(), out.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b = src[x, y]
            d = math.dist((r, g, b), GREEN)
            a = max(0, min(255, round((d - 14) * 255 / 54)))
            if g > r + 18 and g > b + 18 and d < 75:
                a = 0
            if 0 < a < 255:
                g = min(g, max(r, b))
            dst[x, y] = (r, g, b, a)
    return out


def despill_green(image):
    p = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = p[x, y]
            if a and g > r + 18 and g > b + 18:
                p[x, y] = (r, g, b, 0)
            elif a and 0 < a < 255:
                p[x, y] = (r, min(g, max(r, b)), b, a)
    return image


def tile_x(image, band=160):
    """Crossfade matching edge bands so the first and last columns meet exactly."""
    w, h = image.size
    src = image.copy()
    dst = image.load()
    sp = src.load()
    n = min(band, w // 2)
    for i in range(n):
        t = i / max(1, n - 1)
        left_x, right_x = i, w - 1 - i
        edge = [tuple((sp[0, y][k] + sp[w - 1, y][k]) / 2 for k in range(4)) for y in range(h)]
        for y in range(h):
            for x in (left_x, right_x):
                original = sp[x, y]
                dst[x, y] = tuple(round(edge[y][k] * (1 - t) + original[k] * t) for k in range(4))
    return image


def key_residue(image):
    return sum(1 for r, g, b, a in image.getdata() if a and math.dist((r, g, b), GREEN) < 7)


def edge_stats(image):
    rgb = image.convert("RGB")
    p = rgb.load()
    w, h = rgb.size
    edge = sum(abs(p[0, y][c] - p[w - 1, y][c]) for y in range(h) for c in range(3)) / (h * 3)
    neighbor = sum(abs(p[x, y][c] - p[x - 1, y][c]) for x in (1, w - 1) for y in range(h) for c in range(3)) / (h * 3 * 2)
    return round(edge, 4), round(neighbor, 4), round(edge / max(neighbor, 1e-9), 4)


def alpha_mask_stats(image):
    a = image.getchannel("A")
    xs = [x for x in range(image.width) if any(a.getpixel((x, y)) > 8 for y in range(image.height))]
    ys = [y for y in range(image.height) if any(a.getpixel((x, y)) > 8 for x in range(image.width))]
    if not xs or not ys:
        return {"bbox": None}
    x0, x1, y0, y1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
    box_area = (x1 - x0) * (y1 - y0)
    transparent = sum(a.getpixel((x, y)) <= 8 for y in range(y0, y1) for x in range(x0, x1))
    haze = sum(1 for y in range(y0, y1) for x in range(x0, x1) if 9 <= a.getpixel((x, y)) <= 40)
    full_rows = sum(all(a.getpixel((x, y)) > 40 for x in range(x0, x1)) for y in range(y0, y1))
    full_cols = sum(all(a.getpixel((x, y)) > 40 for y in range(y0, y1)) for x in range(x0, x1))
    return {"bbox": (x0, y0, x1, y1), "transparent_pct": round(100 * transparent / box_area, 3), "haze_pct": round(100 * haze / box_area, 3), "full_rows": full_rows, "full_cols": full_cols}


def rgba_luma(rgb):
    return 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]


def make_far():
    im = Image.open(RAW / "jet_bg_ash_far_generated.png").convert("RGB").resize(SIZE, Image.Resampling.LANCZOS)
    # Bring any stray bright ember down into the approved dark range without changing hue.
    p = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b = p[x, y]
            lum = rgba_luma((r, g, b))
            if lum > 185:
                scale = 185 / lum
                p[x, y] = (round(r * scale), round(g * scale), round(b * scale))
    out = tile_x(im.convert("RGBA"), 160).convert("RGB")
    out.save(RAW / "jet_bg_ash_far.png")
    return out.convert("RGBA")


def make_mid():
    im = key_green(Image.open(RAW / "jet_bg_ash_mid_generated.png")).resize(SIZE, Image.Resampling.LANCZOS)
    im = despill_green(im)
    a = im.getchannel("A")
    ap = a.load()
    for y in range(im.height):
        for x in range(im.width):
            if x < 60 or x >= 1860 or y < 120 or 420 <= y < 620 or y >= 900:
                ap[x, y] = 0
    im.putalpha(a)
    p = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, alpha = p[x, y]
            if alpha:
                p[x, y] = (round(r * 0.72), round(g * 0.72), round(b * 0.72), alpha)
    im.save(RAW / "jet_bg_ash_mid.png")
    return im


def first_opaque_rows(im, threshold=40):
    a = im.getchannel("A")
    return [next((y for y in range(im.height) if a.getpixel((x, y)) > threshold), im.height) for x in range(im.width)]


def make_floor():
    keyed = despill_green(key_green(Image.open(RAW / "jet_floor_ash_generated.png")))
    rows = first_opaque_rows(keyed)
    y_top = sorted(rows)[len(rows) // 2]
    source = keyed.crop((0, y_top, keyed.width, keyed.height)).resize((1920, 194), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (1920, 200), (0, 0, 0, 0))
    out.alpha_composite(source, (0, 6))
    # The design specifies a flat walking surface exactly six pixels below the frame top.
    p = out.load()
    sp = source.load()
    for x in range(1920):
        r, g, b, _ = sp[x, 0]
        p[x, 6] = (r, g, b, 255)
    out = tile_x(out, 160)
    a = out.getchannel("A")
    for x in range(1920):
        for y in range(6): a.putpixel((x, y), 0)
        a.putpixel((x, 6), 255)
    out.putalpha(a)
    out.save(RAW / "jet_floor_ash.png")
    return out, y_top


def make_ceiling():
    keyed = despill_green(key_green(Image.open(RAW / "jet_ceiling_ash_generated.png")))
    # Crop the painted ceiling and its short teeth, removing the unused key field above/below.
    band = keyed.crop((0, 200, keyed.width, 690)).resize((1920, 120), Image.Resampling.LANCZOS)
    a = band.getchannel("A")
    p, ap = band.load(), a.load()
    # Guarantee a continuous solid ceiling through row 100; fill only key holes from nearby stone.
    for x in range(1920):
        for y in range(101):
            if ap[x, y] <= 40:
                candidates = [yy for yy in range(max(0, y - 8), min(120, y + 9)) if ap[x, yy] > 40]
                if candidates:
                    yy = min(candidates, key=lambda v: abs(v - y))
                    p[x, y] = (*p[x, yy][:3], 255)
                else:
                    xx = next((xx for d in range(1, 30) for xx in (x - d, x + d) if 0 <= xx < 1920 and ap[xx, y] > 40), None)
                    color = p[xx, y][:3] if xx is not None else (49, 37, 36)
                    p[x, y] = (*color, 255)
            else:
                r, g, b, _ = p[x, y]
                p[x, y] = (r, g, b, 255)
        for y in range(120):
            if y > 100 and ap[x, y] <= 8:
                continue
    # No stalactite may exceed the tile; clear chroma/key fringe beyond row 119 by construction.
    band.putalpha(a)
    band = tile_x(band, 120)
    band = despill_green(band)
    a = band.getchannel("A")
    for x in range(1920):
        for y in range(101):
            if a.getpixel((x, y)) <= 40:
                a.putpixel((x, y), 255)
    band.putalpha(a)
    band.save(RAW / "jet_ceiling_ash.png")
    return band


def get_lumas(image, alpha_only=False):
    rgb = image.convert("RGB")
    ap = image.getchannel("A") if image.mode == "RGBA" else None
    values = [rgba_luma(rgb.getpixel((x, y))) for y in range(image.height) for x in range(image.width) if not alpha_only or ap.getpixel((x, y)) > 40]
    return sorted(values)


def pct(values, q):
    return values[min(len(values) - 1, round((len(values) - 1) * q))]


def tiled(image, name):
    pair = Image.new("RGBA", (image.width * 2, image.height), (18, 16, 42, 255))
    pair.alpha_composite(image.convert("RGBA"), (0, 0))
    pair.alpha_composite(image.convert("RGBA"), (image.width, 0))
    pair.save(PREVIEW / name)


def load_obstacle(rel, size=None):
    im = Image.open(ROOT / rel).convert("RGBA")
    if size:
        im = im.resize(size, Image.Resampling.LANCZOS)
    return im


def composite_scene(far, mid, floor, ceiling, grayscale=False):
    canvas = far.copy().convert("RGBA")
    canvas.alpha_composite(mid)
    canvas.alpha_composite(ceiling, (0, 70 - 100))
    canvas.alpha_composite(floor, (0, 916 - 6))

    # Kazeyumi is displayed at the requested ~135 px and stands on the floor.
    wind = load_obstacle("assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png")
    wind = wind.crop(wind.getchannel("A").getbbox())
    wind.thumbnail((160, 135), Image.Resampling.LANCZOS)
    canvas.alpha_composite(wind, (420, 781))

    beam = load_obstacle("assets/jet/jet_beam_body_v2.png", (360, 26)).rotate(45, expand=True, resample=Image.Resampling.BICUBIC)
    node = load_obstacle("assets/jet/jet_beam_node/pulse/jet_beam_node_pulse_000.png", (42, 42))
    beam_x, beam_y = 660, 325
    canvas.alpha_composite(beam, (beam_x, beam_y))
    projected_half = 360 * math.sqrt(2) / 4
    mid_x, mid_y = beam_x + beam.width / 2, beam_y + beam.height / 2
    node_centers = ((mid_x - projected_half, mid_y + projected_half), (mid_x + projected_half, mid_y - projected_half))
    for cx, cy in node_centers:
        canvas.alpha_composite(node, (round(cx - node.width / 2), round(cy - node.height / 2)))

    block = load_obstacle("assets/jet/jet_gate_block.png", (70, 256))
    lip = load_obstacle("assets/jet/jet_gate_lip/spark/jet_gate_lip_spark_000.png", (96, 36))
    x = 1190
    canvas.alpha_composite(block, (x, 70))
    canvas.alpha_composite(lip, (x - 13, 326))
    canvas.alpha_composite(lip.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (x - 13, 626))
    canvas.alpha_composite(block, (x, 662))

    sweep = load_obstacle("assets/jet/jet_sweep/hum/jet_sweep_hum_000.png", (48, 288))
    canvas.alpha_composite(sweep, (1050, 360))
    missile = load_obstacle("assets/jet/jet_missile/fly_v2/jet_missile_fly_v2_000.png", (100, 67))
    canvas.alpha_composite(missile, (1515, 500))
    core = load_obstacle("assets/jet/jet_core/jet_core_idle_000.png", (70, 70))
    canvas.alpha_composite(core, (1600, 380))
    orb = load_obstacle("assets/jet/jet_orb/jet_orb_idle_000.png", (32, 32))
    for i in range(6): canvas.alpha_composite(orb, (1500 + i * 42, 590))

    out = canvas.convert("RGB")
    if grayscale:
        out = ImageOps.grayscale(out).convert("RGB")
    out.save(PREVIEW / ("jet_lot4_preview_grayscale.png" if grayscale else "jet_lot4_preview_dark.png"))


far = make_far()
mid = make_mid()
floor, floor_y = make_floor()
ceiling = make_ceiling()
for im, name in ((far, "jet_bg_ash_far_two_tiles.png"), (mid, "jet_bg_ash_mid_two_tiles.png"), (floor, "jet_floor_ash_two_tiles.png"), (ceiling, "jet_ceiling_ash_two_tiles.png")):
    tiled(im, name)
composite_scene(far, mid, floor, ceiling)
composite_scene(far, mid, floor, ceiling, grayscale=True)

far_luma = get_lumas(far)
far_hsv = far.convert("RGB").convert("HSV")
sat = [v[1] / 255 for v in far_hsv.getdata()]
print("far", far.size, "Y_mean", round(sum(far_luma) / len(far_luma), 3), "Y_p99", round(pct(far_luma, .99), 3), "Y_max", round(max(far_luma), 3), "saturation_mean", round(sum(sat) / len(sat), 4), "alpha_opaque", set(far.getchannel("A").getdata()) == {255}, "green_key_exact_pixels", sum(1 for r, g, b, a in far.getdata() if (r, g, b) == GREEN), "edge_ratio", edge_stats(far))
mid_alpha = mid.getchannel("A")
mid_opaque = sum(1 for v in mid_alpha.getdata() if v > 40)
mid_luma = get_lumas(mid, True)
center_area = mid.width * 200
center_opaque = sum(1 for y in range(420, 620) for x in range(1920) if mid_alpha.getpixel((x, y)) > 40)
print("mid", mid.size, alpha_mask_stats(mid), "edge_alpha_max", max(mid_alpha.crop((0, 0, 60, 1080)).getdata()), max(mid_alpha.crop((1860, 0, 1920, 1080)).getdata()), "opaque_pct", round(100 * mid_opaque / (1920 * 1080), 3), "Y_p99_opaque", round(pct(mid_luma, .99), 3), "middle_opaque_pct", round(100 * center_opaque / center_area, 3), "green_key_pixels", key_residue(mid), "edge_ratio", edge_stats(mid))
floor_alpha = floor.getchannel("A")
floor_rows = [next((y for y in range(200) if floor_alpha.getpixel((x, y)) > 40), 200) for x in range(1920)]
floor_contiguous = sum(all(floor_alpha.getpixel((x, y)) > 40 for y in range(y, 200)) for x, y in enumerate(floor_rows))
print("floor", floor.size, alpha_mask_stats(floor), "source_surface_median", floor_y, "surface_min_max", min(floor_rows), max(floor_rows), "surface_median", sorted(floor_rows)[960], "continuous_columns_pct", round(100 * floor_contiguous / 1920, 3), "opaque_pixels_above_row6", sum(1 for x in range(1920) for y in range(6) if floor_alpha.getpixel((x, y)) > 8), "green_key_pixels", key_residue(floor), "edge_ratio", edge_stats(floor))
ceil_alpha = ceiling.getchannel("A")
ceil_ends = [max((y for y in range(120) if ceil_alpha.getpixel((x, y)) > 40), default=-1) for x in range(1920)]
ceil_solid100 = sum(all(ceil_alpha.getpixel((x, y)) > 40 for y in range(101)) for x in range(1920))
print("ceiling", ceiling.size, alpha_mask_stats(ceiling), "solid_0_100_columns_pct", round(100 * ceil_solid100 / 1920, 3), "last_opaque_min_max", min(ceil_ends), max(ceil_ends), "stalactite_columns_pct", round(100 * sum(y > 104 for y in ceil_ends) / 1920, 3), "green_key_pixels", key_residue(ceiling), "edge_ratio", edge_stats(ceiling))
