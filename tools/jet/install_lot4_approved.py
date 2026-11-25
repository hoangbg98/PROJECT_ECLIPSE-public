"""Install approved Jet ash backgrounds without replacing any existing asset."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art_review/jet/lot4/raw"
targets = {
    "jet_bg_ash_far.png": "assets/jet/jet_bg_ash_far.png",
    "jet_bg_ash_mid.png": "assets/jet/jet_bg_ash_mid.png",
    "jet_floor_ash.png": "assets/jet/jet_floor_ash.png",
    "jet_ceiling_ash.png": "assets/jet/jet_ceiling_ash.png",
}
missing = [src for src in targets if not (RAW / src).is_file()]
existing = [dst for dst in targets.values() if (ROOT / dst).exists()]
if missing or existing:
    raise SystemExit(f"Missing sources: {missing}; refusing to overwrite: {existing}")

license_path = ROOT / "docs/ASSET_LICENSES.md"
content = license_path.read_text(encoding="utf-8")
marker = "### 2.2 Icon tự vẽ bằng mã"
if marker not in content:
    raise SystemExit("Could not find section 2.2 in ASSET_LICENSES.md")
if "assets/jet/jet_bg_ash_far.png" in content:
    raise SystemExit("Lot 4 license entries already exist; refusing to duplicate")

for src, dest in targets.items():
    target = ROOT / dest
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(RAW / src, target)

tool = "Codex imagegen / Built-in image_gen (model ID không được cung cấp); hậu kỳ Pillow bằng `tools/jet/prepare_lot4_preview.py`"
refs = "`assets/backgrounds/stages/stage_01/bg_stage_01_far.png`, `build/screenshots/jet_3_n1_flying.png`, `art_review/jet/lot3/_preview/jet_lot3_preview_dark.png`"
rows = [
    f"| `assets/jet/jet_bg_ash_far.png` (1920×1080) | {tool} | Lớp trời xa Ống Tro, ống khói đá nhỏ và dải tro ngang; nền đặc tối, nối tile ngang bằng crossfade 160 px, giới hạn độ sáng và bão hòa theo brief. | {refs} | Codex | 2026-11-21 |",
    f"| `assets/jet/jet_bg_ash_mid.png` (1920×1080) | {tool} | Cột đá và mỏm đá trôi trong hai dải, chừa dải giữa và lề lặp ngang; key xanh lá #00FF00 được tách, despill và giảm sáng hậu kỳ. | {refs} | Codex | 2026-11-21 |",
    f"| `assets/jet/jet_floor_ash.png` (1920×200) | {tool} | Sàn đá tro lặp ngang, mặt sàn phẳng ở hàng 6; key xanh lá #00FF00 được tách, despill và khớp mép bằng crossfade. | {refs} | Codex | 2026-11-21 |",
    f"| `assets/jet/jet_ceiling_ash.png` (1920×120) | {tool} | Trần đá tro lặp ngang, thân đặc đến hàng 100, nhũ đá ngắn; key xanh lá #00FF00 được tách, despill, chuẩn hóa alpha và khớp mép. | {refs} | Codex | 2026-11-21 |",
]
content = content.replace(marker, "\n".join(rows) + "\n\n" + marker, 1)
license_path.write_text(content, encoding="utf-8", newline="\n")
print(f"Installed {len(targets)} approved backgrounds and added {len(rows)} license entries.")
