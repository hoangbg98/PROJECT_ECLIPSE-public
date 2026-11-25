"""Dựng trang theo dõi ảnh cốt truyện Chương 1 (HTML một file, ảnh nhỏ nhúng sẵn) từ dữ liệu trong repo.

Chạy ở thư mục gốc:  python -X utf8 -I tools/story/build_story_tracker.py . build/story_tracker.html
Đọc: data/story/*.json, docs/prompts/story/CH01_PANELS.md, docs/prompts/ART_MASTER.md (prompt chính + bảng lô),
localization/vi.po, ảnh trong assets/. Mẫu trang: tools/story/story_tracker_tpl.html. Claude đăng lên claude.ai
(artifact "Ảnh truyện Chương 1") sau mỗi lô ảnh được duyệt."""
import base64, html, io, json, os, re, sys
from PIL import Image

ROOT, OUT = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(ROOT, "tools", "prompts"))
os.chdir(ROOT)
import build_art_master as B  # noqa: E402

def ex(p): return os.path.isfile(os.path.join(ROOT, p))
def rd(p): return open(os.path.join(ROOT, p), encoding="utf-8").read()
def esc(s): return html.escape(str(s), quote=True)

def po(path):
    d, k = {}, None
    for line in rd(path).split("\n"):
        m = re.match(r'msgid "(.*)"$', line)
        if m: k = m.group(1); continue
        m = re.match(r'msgstr "(.*)"$', line)
        if m and k is not None: d[k] = m.group(1).replace('\\"', '"'); k = None
    return d
VI = po("localization/vi.po")

def thumb(path, maxw, maxh, bg=(214, 210, 205)):
    im = Image.open(os.path.join(ROOT, path)).convert("RGBA")
    im.thumbnail((maxw, maxh))
    base = Image.new("RGB", im.size, bg); base.paste(im, mask=im.getchannel("A"))
    b = io.BytesIO(); base.save(b, "JPEG", quality=72)
    return "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()

# ---- prompt chính + lô ----
am = rd("docs/prompts/ART_MASTER.md")
master = re.search(r"\*\*Prompt chính gửi Codex\*\*.*?```text\n(.*?)```", am, re.S).group(1).strip()
lots = re.findall(r"^\| (\d) \| (.*?) \| (.*?) \| (.*?) \|$", am.split("**Prompt chính")[0], re.M)

# ---- ô truyện ----
panels_md = rd("docs/prompts/story/CH01_PANELS.md") + "\n" + (rd("docs/prompts/story/CH02_PANELS.md") if ex("docs/prompts/story/CH02_PANELS.md") else "")
blocks = {}
for m in re.finditer(r"#### .*?`(ch0\d_\w+)\.png`(.*?)(?=\n#### |\n## |\Z)", panels_md, re.S):
    body = m.group(2)
    refs = re.search(r"đính kèm khi tạo:\*\* (.*)", body)
    pr = re.search(r"```text\n(.*?)```", body, re.S)
    blocks[m.group(1)] = {"refs": re.findall(r"`([^`]+)`", refs.group(1)) if refs else [], "prompt": pr.group(1).strip() if pr else ""}

CLIPS = [("ch01_open", "Mở chương", "Trước ải 1-1"), ("ch01_golem", "Cuối ải 1-1", "Sau khi hạ Golem"),
         ("ch01_end", "Kết chương", "Sau ải 1-10"),
         ("ch02_open", "Chương 2 · Mở chương", "Trước ải 2-1"), ("ch02_gate", "Chương 2 · Cổng xưởng", "Trước ải 2-6"),
         ("ch02_end", "Chương 2 · Kết chương", "Sau ải 2-12")]
clips = []
for cid, label, when in CLIPS:
    d = json.load(open(os.path.join(ROOT, "data/story/%s.json" % cid), encoding="utf-8"))
    items = []
    for pi, page in enumerate(d["pages"], 1):
        for p in page.get("panels", []):
            xs = [q[0] for q in p["poly"]]; ys = [q[1] for q in p["poly"]]
            w, h = max(xs) - min(xs), max(ys) - min(ys)
            f = "assets/story/%s/%s.png" % (cid[:4], p["image"])
            done = ex(f)
            src = f if done else "assets/placeholders/story/placeholder_%s.png" % p["image"]
            items.append({"id": p["image"], "page": pi, "file": f, "done": done, "w": w, "h": h, "desc": p["desc"],
                          "lines": [(l["speaker"], VI.get(l["text"], l["text"])) for l in p.get("lines", [])],
                          "thumb": thumb(src, 360, 200) if ex(src) else "", **blocks.get(p["image"], {"refs": [], "prompt": ""})})
    clips.append({"id": cid, "label": label, "when": when, "summary": VI.get(d["summary"], d["summary"]), "items": items})

# ---- ảnh tham chiếu ----
REFS = [("Enkiba", "assets/characters/char_fire_01/splash/char_fire_01_splash_overview.png"),
        ("Kazeyumi", "assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png"),
        ("Raikiba", "assets/characters/char_lightning_01/rig_parts/source/refs/char_lightning_01_ref_01_toan_than.png"),
        ("Kẻ Đeo Mặt Nạ (v1)", "assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png"),
        ("Golem Đá Cổ", "assets/enemies/boss_golem_01/design/boss_golem_01_sheet.png"),
        ("Cặn tro", "assets/enemies/enemy_slime_01/design/enemy_slime_01_sheet.png"),
        ("Cặn lớn", "assets/enemies/enemy_slime_02/design/enemy_slime_02_sheet.png"),
        ("Iwagane", "assets/characters/char_earth_01/splash/char_earth_01_splash_overview.png"),
        ("Thợ Cả Ishiro", "assets/characters/npc_ishiro_01/design/npc_ishiro_01_sheet.png"),
        ("Zero (Quản lý)", "assets/characters/npc_zero_01/design/npc_zero_01_sheet.png")]
refs = [{"name": n, "file": f, "thumb": thumb(f, 300, 200) if ex(f) else ""} for n, f in REFS]

# ---- chương / màn / lô ----
chap = json.load(open(os.path.join(ROOT, "data/story/chapters.json"), encoding="utf-8"))
chapters = []
for c in chap["chapters"]:
    st = [s for p in c["parts"] for s in p.get("stages", [])]
    chapters.append({"num": c["num"], "title": VI.get(c["title"], c["title"]), "stages": len(st),
                     "built": sum(1 for s in st if s.get("stage_id")),
                     "clips": sum(1 for s in st if s.get("clip")),
                     "map": ex("%s/%s.png" % (chap["art_dir"].replace("res://", ""), c["map_image"])),
                     "card": ex("%s/%s.png" % (chap["art_dir"].replace("res://", ""), c["card_image"]))})
stages = B.stage_rows()
def stage_done(codes):
    rows = [r for r in stages if r[0] in codes]; return sum(1 for r in rows if r[3].startswith("✅")), len(rows)
hm = [("assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png"), ("assets/characters/boss_henchman_01/portrait/boss_henchman_01_portrait.png")]
def clip_done(cid):
    it = next(c for c in clips if c["id"] == cid)["items"]; return sum(1 for i in it if i["done"]), len(it)
ch1_art = sum(1 for k in ("map", "card") if chapters[0][k])
lot_prog = {"1": (sum(ex(f) for f in hm), 2), "2": stage_done({"1-1", "1-2"}), "3": clip_done("ch01_open"),
            "4": clip_done("ch01_golem"), "5": stage_done({"1-%d" % i for i in range(3, 10)}),
            "6": tuple(a + b for a, b in zip(stage_done({"1-10"}), clip_done("ch01_end"))), "7": (ch1_art, 2)}
lot_prog["8"] = tuple(sum(x) for x in zip(*(clip_done(c) for c in ("ch02_open", "ch02_gate", "ch02_end"))))
lots = list(lots) + [("8", "Ô truyện Chương 2 (28 ô: mở chương, cổng xưởng, kết chương)",
                      "Chương 2 chơi thử được; ô đang là placeholder có diễn biến. Cần bảng thiết kế Ishiro, Tượng gác nhỏ, Thủ Vệ Cổng trước",
                      "duyệt ô Chương 2")]
lot_list = [{"n": n, "what": w.replace("`", ""), "why": y, "key": k.replace("`", ""), "done": lot_prog[n][0], "total": lot_prog[n][1]}
            for n, w, y, k in lots]

total = sum(len(c["items"]) for c in clips); done = sum(i["done"] for c in clips for i in c["items"])
DATA = {"clips": clips, "refs": refs, "chapters": chapters, "lots": lot_list, "master": master,
        "panels_done": done, "panels_total": total, "built": __import__("datetime").date.today().isoformat()}
tpl = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "story_tracker_tpl.html"), encoding="utf-8").read()
html_out = tpl.replace("/*__DATA__*/null", json.dumps(DATA, ensure_ascii=False).replace("</", "<\\/"))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, "w", encoding="utf-8", newline="\n").write(html_out)
print(OUT, len(html_out) // 1024, "KB;", done, "/", total, "ô;", [(l["n"], l["done"], l["total"]) for l in lot_list])
