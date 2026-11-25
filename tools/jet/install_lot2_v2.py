"""Install owner-approved Jet lot 2 v2 assets without replacing committed originals."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art_review/jet/lot2_v2/raw"
mapping = {
    "jet_beam_body_v2.png": "assets/jet/jet_beam_body_v2.png",
}
for i in range(4):
    name = f"jet_missile_fly_v2_{i:03}.png"
    mapping[f"fly_v2/{name}"] = f"assets/jet/jet_missile/fly_v2/{name}"

missing = [src for src in mapping if not (RAW / src).is_file()]
existing = [dst for dst in mapping.values() if (ROOT / dst).exists()]
if missing or existing:
    raise SystemExit(f"Missing sources: {missing}; refusing to overwrite: {existing}")

for src, dest in mapping.items():
    target = ROOT / dest
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(RAW / src, target)

license_path = ROOT / "docs/ASSET_LICENSES.md"
text = license_path.read_text(encoding="utf-8")
marker = "### 2.2 Icon tự vẽ bằng mã"
if marker not in text:
    raise SystemExit("Could not find section 2.2 in ASSET_LICENSES.md")
if "assets/jet/jet_beam_body_v2.png" in text:
    raise SystemExit("v2 license entries already exist; refusing to duplicate")

tool = "Codex imagegen / Built-in image_gen (model ID không được cung cấp); hậu kỳ Pillow bằng `tools/jet/prepare_lot2_v2_preview.py`"
refs = "`assets/rhythm/rh_slime/run/rh_slime_run_000.png`, `assets/rhythm/rh_bat/fly/rh_bat_fly_000.png`, `assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png`, `assets/jet/jet_beam_node/pulse/jet_beam_node_pulse_001.png`"
rows = [
    f"| `assets/jet/jet_beam_body_v2.png` (128×40) | {tool} | Thanh nhầy tím thân dày 28 px, tâm khung, lặp ngang; nền key #00FF00, hậu kỳ khớp hai cạnh chính xác. | {refs} | Codex | 2026-11-21 |",
]
for i in range(4):
    rows.append(f"| `assets/jet/jet_missile/fly_v2/jet_missile_fly_v2_{i:03}.png` (192×128) | {tool} | Cặn Phóng frame {i+1}/4 giữ hình đã duyệt; hậu kỳ xóa hai hàng viền key còn sót và kiểm tra hàng/cột alpha bbox. | `assets/jet/jet_missile/fly/jet_missile_fly_{i:03}.png`, {refs} | Codex | 2026-11-21 |")
text = text.replace(marker, "\n".join(rows) + "\n\n" + marker, 1)
license_path.write_text(text, encoding="utf-8", newline="\n")
print(f"Installed {len(mapping)} v2 files and added {len(rows)} license entries.")
