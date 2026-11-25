"""Install owner-approved Jet art lot 2 from art_review into game assets."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art_review/jet/lot2/raw"
targets = {
    "jet_icon_dragon.png": "assets/jet/jet_icon_dragon.png",
    "jet_icon_robo.png": "assets/jet/jet_icon_robo.png",
    "jet_beam_body.png": "assets/jet/jet_beam_body.png",
}
for animation, frames in (("pulse", 4), ("fly", 4), ("blink", 2)):
    asset_id = {"pulse": "jet_beam_node", "fly": "jet_missile", "blink": "jet_missile_warn"}[animation]
    for i in range(frames):
        targets[f"{asset_id}_{i:03}.png"] = f"assets/jet/{asset_id}/{animation}/{asset_id}_{animation}_{i:03}.png"

missing = [name for name in targets if not (RAW / name).is_file()]
existing = [dest for dest in targets.values() if (ROOT / dest).exists()]
if missing or existing:
    raise SystemExit(f"Missing sources: {missing}; refusing to overwrite: {existing}")

for name, dest in targets.items():
    target = ROOT / dest
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(RAW / name, target)

licenses = ROOT / "docs/ASSET_LICENSES.md"
content = licenses.read_text(encoding="utf-8")
marker = "### 2.2 Icon tự vẽ bằng mã"
if marker not in content:
    raise SystemExit("Could not find section 2.2 in ASSET_LICENSES.md")
if "assets/jet/jet_icon_dragon.png" in content:
    raise SystemExit("Lot 2 license entries already exist; refusing to duplicate")

tool = "Codex imagegen / Built-in image_gen (model ID không được cung cấp); hậu kỳ Pillow bằng `tools/jet/prepare_lot2_preview.py`"
refs = "`assets/rhythm/rh_slime/run/rh_slime_run_000.png`, `assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png`"
dragon_robo = refs + ", `assets/jet/jet_dragon/fly/jet_dragon_fly_000.png`, `assets/jet/jet_robo.png`"
sludge = refs + ", `assets/rhythm/rh_bat/fly/rh_bat_fly_000.png`"
rows = []
def row(file, prompt, reference):
    rows.append(f"| `{file}` | {tool} | {prompt} | {reference} | Codex | 2026-11-21 |")

row("assets/jet/jet_icon_dragon.png (128×128)", "Icon HUD huy hiệu tròn, đầu Rồng sương xanh ngọc quay phải; nền magenta #FF00FF được key và despill.", dragon_robo)
row("assets/jet/jet_icon_robo.png (128×128)", "Icon HUD huy hiệu tròn, đầu Robo đá với ba vòng đá; nền magenta #FF00FF được key và despill.", dragon_robo)
row("assets/jet/jet_beam_body.png (128×40)", "Thanh nhầy tím lặp ngang; nền xanh lá #00FF00 được key/despill, khớp chính xác hai cạnh bằng hậu kỳ.", sludge)
for i in range(4):
    row(f"assets/jet/jet_beam_node/pulse/jet_beam_node_pulse_{i:03}.png (96×96)", f"Nút Cặn tròn có mắt cam, frame pulse {i+1}/4; nền xanh lá #00FF00 được key/despill.", sludge)
for i in range(4):
    row(f"assets/jet/jet_missile/fly/jet_missile_fly_{i:03}.png (192×128)", f"Cặn Phóng thuôn quay trái, đuôi mảng Cặn tím; frame fly {i+1}/4; nền xanh lá #00FF00 được key/despill.", sludge)
for i in range(2):
    row(f"assets/jet/jet_missile_warn/blink/jet_missile_warn_blink_{i:03}.png (128×128)", f"Tam giác cảnh báo đỏ có vệt Cặn, frame blink {i+1}/2; chỉ đổi độ sáng; nền xanh lá #00FF00 được key/despill.", sludge)

content = content.replace(marker, "\n".join(rows) + "\n\n" + marker, 1)
licenses.write_text(content, encoding="utf-8", newline="\n")
print(f"Installed {len(targets)} approved files and added {len(rows)} license records.")
