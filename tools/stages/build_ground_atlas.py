"""Ghép atlas mặt đất từ ảnh Codex vẽ: lát cắt ngang của đất (nền magenta phía trên) → atlas ô 64 px lặp liền mạch.

Chạy ở thư mục gốc:  python -X utf8 -I tools/stages/build_ground_atlas.py [chủ_đề ...]   (không chỉ định = mọi chủ đề có ảnh gốc)
Đọc  art_review/stages/ground/raw/ground_<chủ_đề>_raw.png   (ảnh ngang ~1536x1024, nền magenta #FF00FF phía trên đường mép đất)
Ghi  assets/stages/ground/ground_<chủ_đề>.png               (atlas 1024 x 832 = 16 cột x 13 hàng ô 64 px, có kênh alpha)
  hàng 0     = mép trên (24 px trời trong suốt phía trên đường mép + 40 px đất), lặp ngang
  hàng 1..12 = thân đất (lặp dọc theo độ sâu)
Làm liền mạch ngang: cạnh phải được hòa vào cạnh trái bằng dải chồng 256 px. Hàng ván (platform) do GroundSkin vẽ bằng mã khi nạp.
StageMap lấy ô theo toạ độ thế giới (cột % 16, độ sâu), nên đất liên tục như một bức tranh dài, không lộ ô lưới.
"""
import glob
import os
import statistics
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
RAW = os.path.join(ROOT, "art_review", "stages", "ground", "raw")
OUT = os.path.join(ROOT, "assets", "stages", "ground")
TILE = 64
COLS = 16
SOIL_ROWS = 12
ABOVE = 24          # px trời giữ phía trên đường mép trong hàng 0
OVERLAP = 256


def is_magenta(p) -> bool:
    return p[0] > 170 and p[2] > 170 and p[1] < 120


def ground_line(img: Image.Image) -> int:
    """Độ cao đường mép đất: trung vị của hàng đầu tiên không phải magenta theo từng cột (bỏ cột nhiễu)."""
    px = img.convert("RGB").load()
    firsts = []
    for x in range(0, img.width, 8):
        for y in range(img.height):
            if not is_magenta(px[x, y]):
                firsts.append(y)
                break
    return int(statistics.median(firsts))


def key_magenta(img: Image.Image) -> Image.Image:
    """Nền magenta → alpha 0 (viền mềm theo độ gần magenta), khử màu hồng ở viền."""
    rgba = img.convert("RGBA")
    px = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = px[x, y]
            spill = min(r, b) - g
            if spill > 150 and min(r, b) > 170:
                px[x, y] = (r, g, b, 0)
            elif spill > 70 and min(r, b) > 120:
                a = max(0, min(255, int(255 * (150 - spill) / 80)))
                nr = max(0, r - int(spill * 0.7)); nb = max(0, b - int(spill * 0.7))
                px[x, y] = (nr, g, nb, a)
    return rgba


def seamless_width(img: Image.Image, width: int) -> Image.Image:
    """Cắt đúng `width` px và hòa cạnh phải (phần thừa) vào cạnh trái để lặp ngang liền mạch."""
    assert img.width >= width + OVERLAP, "ảnh gốc quá hẹp"
    base = img.crop((0, 0, width, img.height)).convert("RGBA")
    tail = img.crop((width, 0, width + OVERLAP, img.height)).convert("RGBA")
    head = base.crop((0, 0, OVERLAP, img.height))
    mask = Image.new("L", (OVERLAP, img.height))
    ramp = Image.new("L", (OVERLAP, 1)); ramp.putdata([int(255 * i / (OVERLAP - 1)) for i in range(OVERLAP)])
    mask = ramp.resize((OVERLAP, img.height))
    blended = Image.composite(head, tail, mask)     # x=0 → đuôi (nối liền cạnh phải), x=OVERLAP → đầu
    base.paste(blended, (0, 0))
    return base


def build(theme: str) -> str:
    src = os.path.join(RAW, "ground_%s_raw.png" % theme)
    img = Image.open(src).convert("RGB")
    y0 = ground_line(img)
    top = y0 - ABOVE
    need = top + TILE * (1 + SOIL_ROWS)
    if top < 0 or need > img.height + 120:
        raise SystemExit("%s: đường mép ở y=%d không đủ chỗ (cần %d px, ảnh cao %d)" % (theme, y0, need, img.height))
    short = max(0, need - img.height)
    band = img.crop((0, top, img.width, min(need, img.height)))
    if short:   # thiếu vài hàng đáy (thân đất đồng đều): nối thêm bằng dải đáy lật ngược
        mirror = band.crop((0, band.height - short, band.width, band.height)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        extended = Image.new("RGB", (band.width, band.height + short))
        extended.paste(band, (0, 0)); extended.paste(mirror, (0, band.height))
        band = extended
    tile = seamless_width(band, TILE * COLS)
    atlas = key_magenta(tile)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, "ground_%s.png" % theme)
    atlas.save(out, optimize=True)
    print("%s: đường mép y=%d → %s %s" % (theme, y0, os.path.relpath(out, ROOT), atlas.size))
    return out


def main() -> None:
    themes = sys.argv[1:] or sorted(os.path.basename(p)[len("ground_"):-len("_raw.png")]
                                    for p in glob.glob(os.path.join(RAW, "ground_*_raw.png")))
    if not themes:
        raise SystemExit("chưa có ảnh gốc trong %s" % RAW)
    for t in themes:
        build(t)


if __name__ == "__main__":
    main()
