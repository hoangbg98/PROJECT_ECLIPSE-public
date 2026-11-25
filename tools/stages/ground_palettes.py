"""Chọn bảng màu mặt đất cho từng màn từ ảnh nền xa của màn đó, ghi khối `ground` vào data/stages/stage_*.json.

Chạy ở thư mục gốc:  python -X utf8 -I tools/stages/ground_palettes.py [--dry-run]
Với mỗi màn có `backdrop` (lớp xa đầu tiên): lấy màu trung bình dải đáy 18% của ảnh xa (phần bị nền đất che trong game),
rồi tối đi / ấm lên để làm đất; sáng hơn cho mép trên. Kết quả (ví dụ):
  "ground": {"base": "#4a3f4b", "light": "#675a66", "dark": "#322a33", "lip": "#8b7886", "seed": 5},
Khi đã có ảnh đất vẽ tay của chủ đề (THEMES), khối còn có `atlas`; thiếu ảnh thì GroundSkin vẽ bằng mã theo màu.
Khối này do GroundSkin (scripts/world/ground_skin.gd) đọc; màn không có khối `ground` vẫn dùng ô lưới tạm.
Chạy lại an toàn: khối cũ bị thay. Chỉnh màu tay: sửa thẳng khối `ground` trong JSON rồi không chạy lại cho màn đó.
"""
import colorsys
import glob
import json
import os
import re
import sys

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
# Chủ đề ảnh đất vẽ tay của từng màn (assets/stages/ground/ground_<chủ_đề>.png, dựng bằng tools/stages/build_ground_atlas.py).
THEMES = {
    "stage_01": "ash_road", "stage_01_02": "ash_road", "stage_01_03": "coal_mine", "stage_01_04": "cliff_stone",
    "stage_01_05": "dead_forest", "stage_01_06": "cliff_stone", "stage_01_07": "stone_floor", "stage_01_08": "ash_road",
    "stage_01_09": "dead_forest", "stage_01_10": "stone_floor",
    # Chương 2 (nền mượn tạm của Chương 1; đất đá của cao nguyên)
    "stage_02_01": "cliff_stone", "stage_02_02": "cliff_stone", "stage_02_03": "stone_floor", "stage_02_04": "ash_road",
    "stage_02_05": "stone_floor", "stage_02_06": "stone_floor", "stage_02_07": "stone_floor", "stage_02_08": "stone_floor",
    "stage_02_09": "stone_floor", "stage_02_10": "cliff_stone", "stage_02_11": "cliff_stone", "stage_02_12": "stone_floor",
}
WARM = (112, 86, 72)   # nâu đất, pha vào để mặt đất không xám lạnh như nền


def avg_bottom(path: str) -> tuple:
    im = Image.open(path).convert("RGB")
    band = im.crop((0, int(im.height * 0.82), im.width, im.height)).resize((32, 8))
    px = list(band.getdata()) if not hasattr(band, "get_flattened_data") else list(band.get_flattened_data())
    n = len(px)
    return tuple(sum(p[i] for p in px) / n for i in range(3))


def tone(rgb: tuple, v_mul: float, warm: float, s_mul: float = 1.0) -> str:
    mixed = tuple(rgb[i] * (1 - warm) + WARM[i] * warm for i in range(3))
    h, s, v = colorsys.rgb_to_hsv(*(c / 255.0 for c in mixed))
    r, g, b = colorsys.hsv_to_rgb(h, min(1.0, s * s_mul), min(1.0, v * v_mul))
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def palette(rgb: tuple, seed: int) -> dict:
    return {"base": tone(rgb, 0.78, 0.30), "light": tone(rgb, 1.02, 0.28), "dark": tone(rgb, 0.52, 0.30),
            "lip": tone(rgb, 1.32, 0.18, 0.9), "seed": seed}


def atlas_of(stage_id: str) -> str:
    """Đường dẫn atlas vẽ tay của màn nếu đã dựng; không có thì "" (màn dùng bản vẽ bằng mã)."""
    theme = THEMES.get(stage_id)
    if theme and os.path.exists(os.path.join(ROOT, "assets", "stages", "ground", "ground_%s.png" % theme)):
        return "res://assets/stages/ground/ground_%s.png" % theme
    return ""


def main() -> None:
    dry = "--dry-run" in sys.argv
    files = sorted(glob.glob(os.path.join(ROOT, "data", "stages", "stage_*.json")))
    for i, path in enumerate(files):
        text = open(path, encoding="utf-8").read()
        data = json.loads(text)
        back = data.get("backdrop") or []
        if not back:
            continue
        img = back[0]["image"].replace("res://", "")
        far = os.path.join(ROOT, img)
        if not os.path.exists(far):
            continue
        pal = palette(avg_bottom(far), 3 + i)
        atlas = atlas_of(data.get("id", ""))
        if atlas:
            pal = {"atlas": atlas, **pal}
        line = '\t"ground": %s,\n' % json.dumps(pal, ensure_ascii=False)
        if re.search(r'^\t"ground": \{.*\},\n', text, re.M):
            new = re.sub(r'^\t"ground": \{.*\},\n', line.replace("\\", "\\\\"), text, count=1, flags=re.M)
        else:
            anchor = '\t"backdrop": ['
            assert text.count(anchor) == 1, path
            new = text.replace(anchor, line + anchor)
        json.loads(new)   # còn là JSON hợp lệ
        print(os.path.basename(path), pal)
        if not dry:
            open(path, "w", encoding="utf-8", newline="").write(new)


if __name__ == "__main__":
    main()
