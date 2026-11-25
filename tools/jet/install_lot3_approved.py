"""Install approved Jet lot 3 assets without overwriting existing files."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "art_review/jet/lot3/raw"
targets = {
    "jet_gate_block.png": "assets/jet/jet_gate_block.png",
    "jet_wind_arrow.png": "assets/jet/jet_wind_arrow.png",
}
for i in range(3):
    targets[f"jet_sweep_hum_{i:03}.png"] = f"assets/jet/jet_sweep/hum/jet_sweep_hum_{i:03}.png"
    targets[f"jet_gate_lip_spark_{i:03}.png"] = f"assets/jet/jet_gate_lip/spark/jet_gate_lip_spark_{i:03}.png"

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
if "assets/jet/jet_sweep/hum/" in content:
    raise SystemExit("Lot 3 license entries already exist; refusing to duplicate")

tool = "Codex imagegen / Built-in image_gen (model ID không được cung cấp); hậu kỳ Pillow bằng `tools/jet/prepare_lot3_preview.py`"
refs = "`assets/rhythm/rh_slime/run/rh_slime_run_000.png`, `assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png`"
gate_refs = refs + ", `assets/jet/jet_beam_body_v2.png`, `assets/jet/jet_beam_node/pulse/jet_beam_node_pulse_000.png`"
rows = []
for i in range(3):
    rows.append(f"| `assets/jet/jet_sweep/hum/jet_sweep_hum_{i:03}.png` (48×288) | {tool} | Tia Quét frame hum {i+1}/3: lõi sét vàng trắng, dải vàng đặc và hai cực đá cố định; key magenta #FF00FF, tách nền và despill. | {refs} | Codex | 2026-11-21 |")
rows.append(f"| `assets/jet/jet_gate_block.png` (96×256) | {tool} | Cột Van Sét đá-kim loại tím lặp dọc; key xanh lá #00FF00, nối mép và làm sạch viền bằng hậu kỳ. | {gate_refs} | Codex | 2026-11-21 |")
for i in range(3):
    rows.append(f"| `assets/jet/jet_gate_lip/spark/jet_gate_lip_spark_{i:03}.png` (128×48) | {tool} | Mép Van Sét frame spark {i+1}/3: nắp kim loại ngang, tia lửa vàng ở cạnh khe; key xanh lá #00FF00, giữ phần nắp ổn định giữa frame. | {gate_refs} | Codex | 2026-11-21 |")
rows.append(f"| `assets/jet/jet_wind_arrow.png` (96×160) | {tool} | Mũi tên gió hướng lên từ ba dải khí xanh ngọc đặc; key magenta #FF00FF, tách nền và despill. | {refs} | Codex | 2026-11-21 |")
content = content.replace(marker, "\n".join(rows) + "\n\n" + marker, 1)
licenses.write_text(content, encoding="utf-8", newline="\n")
print(f"Installed {len(targets)} approved files and added {len(rows)} license entries.")
