"""Tạo bản sao dự án để export web NHỎ HƠN: ảnh lớn (truyện, nền, trang bị) chuyển sang nén lossy WebP.
Bản gốc (desktop) không bị đổi. UI, jet, placeholder giữ lossless.
Dùng: python -X utf8 -I tools/web/lossy_copy.py <thư mục đích> [chất lượng 0..1, mặc định 0.85]"""
import os, re, shutil, sys

LOSSY_DIRS = ("assets/story/", "assets/backgrounds/", "assets/equipment/", "assets/characters/", "assets/enemies/", "assets/rhythm/")
SKIP = {".git", "build", "reports", "netlify_site", "node_modules", "pixelfx", "art_review", ".godot", "docs", "tests", "sites", "server"}

src = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
dst = os.path.abspath(sys.argv[1])
q = sys.argv[2] if len(sys.argv) > 2 else "0.85"
if os.path.exists(dst):
    shutil.rmtree(dst)
n = 0
for root, dirs, files in os.walk(src):
    dirs[:] = [d for d in dirs if d not in SKIP]
    rel = os.path.relpath(root, src).replace(os.sep, "/")
    os.makedirs(os.path.join(dst, rel), exist_ok=True)
    for f in files:
        s = os.path.join(root, f)
        d = os.path.join(dst, rel, f)
        if f.endswith(".import") and (rel + "/").startswith(LOSSY_DIRS) and f.endswith(".png.import"):
            t = open(s, encoding="utf8").read()
            t2 = t.replace("compress/mode=0", "compress/mode=1").replace("compress/lossy_quality=0.7", "compress/lossy_quality=" + q)
            if "compress/lossy_quality" not in t2:
                t2 = t2.replace("compress/mode=1", "compress/mode=1\ncompress/lossy_quality=" + q)
            open(d, "w", encoding="utf8").write(t2)
            n += 1
        else:
            shutil.copy2(s, d)
print("đã đổi", n, "file .import sang lossy ->", dst)
