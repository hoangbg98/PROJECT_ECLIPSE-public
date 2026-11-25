"""Sinh clip truyện tranh Chương 2 "Xưởng Đá Ngủ" (placeholder trước, ảnh sau; owner 2026-11-21, docs/design/CH02_STORY.md mục 5 / 7).

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/story/gen_story_clips_02.py

Sinh ra (giống gen_story_clips.py của Chương 1, dùng lại bố cục, ô placeholder và cách ghi chữ):
  data/story/ch02_open.json  — mở chương (phát trước thông tin ải 2-1: open_clip của stage_02_01)
  data/story/ch02_gate.json  — gặp Iwagane ở cổng xưởng (phát trước ải 2-6: open_clip của stage_02_06)
  data/story/ch02_end.json   — kết chương (sau ải 2-12: end_clip của stage_02_12)
  localization/vi.po, en.po  — khóa STORY_CH02_*; NPC_ISHIRO
  assets/placeholders/story/placeholder_ch02_*.png — ô tạm đúng kích thước, đánh số, ghi diễn biến
  docs/prompts/story/CH02_PANELS.md — prompt ChatGPT / Codex cho từng ô
Ảnh thật đặt ở assets/story/ch02/<ảnh>.png (đúng tên); game tìm ảnh thật, rồi placeholder, rồi tự vẽ ô xám.
Người nói: Data ID, "neo", "narration", "unknown" (???), "ishiro" (Thợ Cả Ishiro), "boss_henchman_01" (Shokuhai).
"""
import io
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_story_clips as g  # noqa: E402  (dùng lại bố cục, placeholder, mô tả nhân vật)

ROOT = g.ROOT
W, H = g.W, g.H
E, K, R, N, HM, HM_ID = g.E, g.K, g.R, g.N, g.HM, g.HM_ID
I = "char_earth_01"
ISH = "ishiro"
GS = "guard_statue"
GATE = "gate_guardian"
IMAGE_DIR = "res://assets/story/ch02"
CLIP_LABEL = {"ch02_open": "Mở chương (trước ải 2-1)", "ch02_gate": "Cổng xưởng (trước ải 2-6)", "ch02_end": "Kết chương (sau ải 2-12)"}

CHAR_DESC = dict(g.CHAR_DESC)
CHAR_DESC.update({
    I: "Iwagane — tall adult woman (clearly the oldest of the team), strong build, thick brown hair in a long side braid, "
       "stern brown eyes, bronze and moss-green plate armor with gold rune lines and a heavy tabard with a vertical stone "
       "pattern, carries a huge stone-hewn greatsword with glowing gold glyphs",
    ISH: "Master Ishiro — elderly master smith, messy grey hair, short grey beard, stern scarred face, broad shoulders, slightly "
         "stooped, bronze-and-moss-green shoulder plates with stone patterns, brown smock and a thick leather apron embroidered "
         "with a stone motif, belt pouches and a small hammer, leather gloves, iron-toed boots, left arm bandaged in a white sling, "
         "a small stone pendant of three stacked rings on a leather cord",
    GS: "a small guard statue — a human-sized young stone guardian with clouded pale eyes, chipped grey plates and an empty "
        "hollow in its chest where a glowing core should be",
    GATE: "the Gate Guardian — a colossal ancient stone guardian taller than the gate, cracked grey-brown stone armor, a "
          "foreign black-and-white ring seal glowing in its chest",
})
CHAR_REF = dict(g.CHAR_REF)
CHAR_REF[I] = "assets/characters/char_earth_01/splash/char_earth_01_splash_overview.png"
CHAR_REF[ISH] = "assets/characters/npc_ishiro_01/design/npc_ishiro_01_sheet.png"


def panel(chars, vi, en, *lines):
    return {"chars": list(chars), "vi": vi, "en": en, "lines": list(lines)}


CLIPS = {
    "ch02_open": {
        "summary": ("Theo dấu ba vòng đá, đội lên Cao Nguyên Thủ Vệ nơi chế tạo thủ vệ. Xưởng im lặng, vệt bánh chở đá và tro lạ "
                    "hằn trên đường, và những thủ vệ non mắt đục đang bị ép thức. Đích: tìm ra ai đã lấy lõi thủ vệ.",
                    "Following the three stone rings, the team climbs the Guardian Highlands where guardians are made. The workshop "
                    "is silent, strange wheel tracks cut the road, and young guardians with clouded eyes are being forced awake. "
                    "Goal: find out who took the guardian cores."),
        "pages": [
            {"layout": "A", "panels": [
                panel([N], "Cao nguyên đá xa, vách xẻ thành xưởng, Mặt Trời Khuyết lệch hẳn về một phía; Neo lơ lửng trước ống kính.",
                      "Wide establishing shot: a high stone plateau with workshops carved into its cliffs, giant dormant guardian "
                      "statues in the haze, the Eclipsed Sun leaning low to one side; NEO's glowing ring floats in the foreground.",
                      (N, "Tọa độ khớp: Cao Nguyên Thủ Vệ. Mật độ nguyên tố Địa 18%, đang giảm.",
                       "Coordinates match: the Guardian Highlands. Earth element density 18% and falling.")),
                panel([R], "Raikiba nhìn quanh con dốc im lặng, tay gõ lên chuôi dao.",
                      "Raikiba looks around the silent slope, tapping a dagger hilt, uneasy.",
                      (R, "Yên quá. Xưởng làm thủ vệ mà không có tiếng búa nào.",
                       "Too quiet. A guardian workshop and not one hammer ringing.")),
                panel([K], "Kazeyumi cúi xuống nhìn vệt bánh xe nặng hằn trên đá.",
                      "Kazeyumi crouches over deep, heavy cart-wheel tracks pressed into the stone road, ash dust at the edges.",
                      (K, "Có người chở đồ nặng đi. Mới thôi.", "Someone hauled something heavy through here. Recently.")),
            ]},
            {"layout": "B", "panels": [
                panel([GS], "Một Tượng gác nhỏ mắt đục loạng choạng giữa đường, hốc ngực trống.",
                      "A small guard statue with clouded pale eyes staggers into the road ahead, the hollow in its chest empty.",
                      (N, "Tượng gác nhỏ: thủ vệ non. Lõi trong ngực không phát hiện.",
                       "Small guard statue: a young guardian. No core detected in its chest.")),
                panel([E, K], "Enkiba rút kiếm; Kazeyumi đặt tay chặn lại.",
                      "Enkiba draws his flaming sword; Kazeyumi lays a hand on his arm to stop him.",
                      (K, "Chờ đã. Mắt nó… không đứng được. Nó đang bị ép thức.",
                       "Wait. Its eyes… it can't even stand properly. It's being forced awake.")),
                panel([E], "Enkiba nghiến răng, hạ mũi kiếm xuống.",
                      "Enkiba grits his teeth and lowers his sword tip, shadow over his face.",
                      (E, "Tớ vừa đập một con như vậy ở nhà tớ.", "I just smashed one of these back in my village.")),
            ]},
            {"layout": "C", "panels": [
                panel([N], "Neo chiếu bản đồ: ba vệt chở kéo dài về phía bắc.",
                      "NEO projects a holographic map: three cart tracks stretching away toward the north.",
                      (N, "Ghi nhận ba vệt chở. Chưa thấy điểm đến.", "Three haul tracks logged. Destination unknown.")),
                panel([E, K, R], "Ba người đứng trước vách xưởng tối, quyết định đi tiếp.",
                      "The three stand before the dark workshop cliff, resolved, wind pulling at their clothes.",
                      (E, "Đi thôi. Phải biết ai lấy lõi.", "Let's go. We need to know who took the cores.")),
            ]},
            {"card": ("Chương 2 — Xưởng Đá Ngủ", "Chapter 2 — The Sleeping Stone Workshop",
                      "Cao Nguyên Thủ Vệ", "The Guardian Highlands")},
        ],
    },
    "ch02_gate": {
        "summary": ("Iwagane giữ cổng xưởng và nghi đội là kẻ trộm lõi, vì đội cầm mảnh ấn gỡ từ ngực một thủ vệ. Chị đề nghị một ca "
                    "đấu tập để thử người: qua được thì được vào.",
                    "Iwagane guards the workshop gate and suspects the team of stealing cores, since they carry a seal taken from a "
                    "guardian's chest. She offers a sparring trial: pass it and you may enter."),
        "pages": [
            {"layout": "G", "panels": [
                panel([I], "Cổng xưởng; bóng một người cao lớn ngược sáng, đại kiếm cắm xuống đất chặn lối.",
                      "The workshop gate: the backlit silhouette of a tall armored woman stands in the way, greatsword planted "
                      "point-down in the stone, low sun behind her.",
                      (I, "Dừng ở đó.", "Stop right there.")),
                panel([I], "Iwagane nhìn chằm chằm vào túi Raikiba, nơi lộ ra mảnh ấn mã 00.",
                      "Close-up on Iwagane's stern eyes, looking down at the half-white half-black seal shard peeking from a pocket.",
                      (I, "Các cậu mang mảnh ấn gỡ từ ngực một thủ vệ.", "You carry a seal pulled from a guardian's chest.")),
                panel([R], "Raikiba giơ hai tay, cười gượng.",
                      "Raikiba raises both hands, an awkward grin, shard half hidden behind him.",
                      (R, "Khoan! Tụi tớ nhặt nó dưới chân golem, không phải…",
                       "Hold on! We picked it up at the golem's feet, we didn't…")),
                panel([I], "Iwagane nhìn qua vai vào xưởng trống: hơn chục hốc lõi trống trong bóng tối.",
                      "Iwagane glances over her shoulder at the workshop interior: rows of empty core hollows in the dark.",
                      (I, "Xưởng mất mười bốn lõi trong một đêm. Rồi các cậu tới, cầm đúng loại ấn đó.",
                       "The workshop lost fourteen cores in a single night. Then you show up carrying exactly that seal.")),
            ]},
            {"layout": "C", "panels": [
                panel([E], "Enkiba bước lên trước, thu kiếm về vai.",
                      "Enkiba steps forward and rests his sword on his shoulder, calm and direct.",
                      (E, "Chị không tin lời tụi em thì tin trận đánh.", "If you won't trust our words, trust a fight.")),
                panel([I], "Iwagane nhấc đại kiếm lên, khí thế đè xuống.",
                      "Iwagane lifts the huge greatsword in both hands, dust shaking from the ground around her.",
                      (I, "Một ca thử người. Qua được thì vào.", "A trial. Pass it and you may enter.")),
            ]},
        ],
    },
    "ch02_end": {
        "summary": ("Thủ Vệ Cổng gục, lõi lạ vỡ. Hiểu lầm được gỡ: golem ở Thung Lũng Tro Tàn phải canh một mình vì bạn gác đôi của nó "
                    "đã bị lấy lõi. Vệt chở lõi dẫn về Thành Tháp Sét, quê Raikiba. Iwagane ở lại giữ xưởng; một bóng đeo mặt "
                    "nạ thu những lõi sót lại.",
                    "The Gate Guardian falls and the foreign core shatters. The misunderstanding clears: the golem in the Ashen "
                    "Valley had to stand watch alone because its paired watcher's core was taken. The haul tracks lead to the "
                    "City of Silent Towers, Raikiba's home. Iwagane stays to guard the workshop; a masked figure gathers "
                    "the leftover cores."),
        "pages": [
            {"layout": "A", "panels": [
                panel([I], "Thủ Vệ Cổng gục, vòng 00 nứt vỡ trên ngực; Iwagane chống đại kiếm thở dốc dưới bình minh.",
                      "Dawn at the gate: the colossal Gate Guardian lies collapsed, the black-and-white ring seal on its chest "
                      "cracked open; Iwagane leans on her greatsword, breathing hard.",
                      (I, "Cổng này vẫn đứng.", "The gate still stands.")),
                panel([R, I], "Raikiba xoa vai, nhìn Iwagane ngưỡng mộ.",
                      "Raikiba rubs his shoulder, looking up at Iwagane with open admiration.",
                      (R, "Chị giữ cửa kiểu gì mà nó không đẩy chị đi được vậy?", "How do you hold a door that doesn't budge?"),
                      (I, "Chị đứng đủ lâu thì đất tự biết.", "Stand long enough and the ground learns your name.")),
                panel([K], "Kazeyumi nâng mảnh lõi lạ vỡ vụn trong tay.",
                      "Kazeyumi holds up the shattered foreign core fragments in her palm, a faint 00 ring glimmering.",
                      (K, "Lõi này không phải của xưởng. Có thứ khác bị ép vào trong.",
                       "This core isn't the workshop's. Something else was forced into it.")),
            ]},
            {"layout": "B", "panels": [
                panel([I], "Iwagane quay sang đội, cúi đầu thật sâu.",
                      "Iwagane turns to the team and bows deeply, braid falling over her shoulder.",
                      (I, "Chị đã nghi nhầm các em.", "I wrongly suspected you.")),
                panel([E], "Enkiba vẫy tay, cười.",
                      "Enkiba waves it off with a warm grin.",
                      (E, "Không sao. Em cũng suýt đập nhầm mấy con tượng non.", "It's fine. I almost smashed those young statues by mistake.")),
                panel([I, E], "Iwagane nhìn xuống đất; Enkiba siết chặt tay.",
                      "Iwagane looks down at the ground, quiet; Enkiba clenches his fist beside her.",
                      (I, "Golem ở thung lũng… bạn gác của nó nằm trong kho. Nó đã chờ ca thay hơn một mùa.",
                       "The golem in your valley… its paired watcher lies in our vault. It waited over a season for a relief that never came.")),
            ]},
            {"layout": "F", "panels": [
                panel([N], "Neo chiếu bản đồ: vệt chở lõi kéo về một thành có những cột sét cao.",
                      "NEO projects a map: the core haul tracks run north to a city of tall lightning-rod towers.",
                      (N, "Điểm đến khả dĩ: Thành Tháp Sét Câm.", "Probable destination: the City of Silent Towers.")),
                panel([R], "Raikiba tái mặt, ngẩng lên.",
                      "Raikiba goes pale and looks up, the usual grin gone.",
                      (R, "Nhà tớ ở đó.", "My home is there.")),
            ]},
            {"layout": "D", "panels": [
                panel([ISH, I], "Thợ Cả Ishiro, được dìu ra, đặt một vòng đá ba vòng chồng nhau vào tay Iwagane.",
                      "Master Ishiro, supported by an apprentice, places a small stone ring engraved with three stacked rings into "
                      "Iwagane's hand.",
                      (ISH, "Ca gác này chuyển cho con. Không phải một mình.", "This watch passes to you, child. Not alone.")),
                panel([I, N], "Iwagane nhìn Neo rồi nhìn xưởng.",
                      "Iwagane looks at NEO's ring, then back at the workshop, resolve in her eyes.",
                      (I, "Chị phải ở lại giữ cổng. Nhưng nếu kênh của em còn chỗ trống thì cứ gọi chị.",
                       "I have to stay and hold the gate. But if your channel has room, call me."),
                      (N, "Ghi nhận. Kênh Iwagane: đóng, mở khi được gọi.", "Noted. Iwagane channel: closed, opens when called.")),
                panel([K, E, R], "Ba người cười, vẫy tay chào.",
                      "The three smile and wave goodbye, Iwagane small but steady at the gate behind them.",
                      (K, "Hẹn gặp lại chị. Bọn em đi trước.", "See you again, Iwagane. We'll go ahead.")),
            ]},
            {"layout": "E", "panels": [
                panel([E, K, R], "Cả đội đi xuống bậc đá về phía bắc; Mặt Trời Khuyết nhô lên.",
                      "The team walks down the stone steps toward the north, the Eclipsed Sun rising over the plateau.",
                      (N, "Đã ghi tọa độ. Chờ lệnh của Quản lý.", "Coordinates logged. Awaiting the Manager's orders.")),
            ]},
            {"card": ("Chương 2 — Hoàn thành", "Chapter 2 — Complete",
                      "Chương 3: Thành Tháp Sét Câm — sắp ra mắt", "Chapter 3: The City of Silent Towers — coming soon")},
            {"layout": "C", "panels": [
                panel([HM], "Dưới chân cổng bình minh, Shokuhai giáp vá lại bước qua thân Thủ Vệ Cổng, nhặt các lõi nhỏ rơi vãi.",
                      "Dawn below the gate: the masked henchman (Shokuhai) in patched-up armor steps over the fallen Gate Guardian "
                      "and picks up small glowing cores scattered on the ground, black visor never showing a face.",
                      ("unknown", "Thu đủ chưa? Sét sẽ lo phần sau.", "Is that all of them? The lightning will handle the rest.")),
                panel([HM], "Shokuhai hấp thụ lõi vào giáp: vòng 00 lóe lên, vết nứt trên mặt nạ liền lại một phần.",
                      "Shokuhai absorbs the cores into his armor: the half-white half-black ring flares and a crack in his visor "
                      "seals partially; he turns north."),
            ]},
        ],
    },
}


def main():
    keys = {"NPC_ISHIRO": ("Thợ Cả Ishiro", "Master Ishiro")}
    doc = []
    num = 0
    os.makedirs(os.path.join(ROOT, "data/story"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "assets/placeholders/story"), exist_ok=True)
    shape_names = {3: "tam giác", 4: "tứ giác (thang / bình hành)", 6: "lục giác (dải chéo)"}
    for clip_id, clip in CLIPS.items():
        up = clip_id.upper()
        out = {"_comment": "Sinh bởi tools/story/gen_story_clips_02.py — sửa ở đó rồi chạy lại.",
               "id": clip_id, "design_size": [W, H], "image_dir": IMAGE_DIR,
               "placeholder_dir": "res://assets/placeholders/story",
               "summary": "STORY_%s_SUMMARY" % up, "pages": []}
        keys["STORY_%s_SUMMARY" % up] = clip["summary"]
        doc.append("\n## %s — %s\n" % (clip_id, CLIP_LABEL[clip_id]))
        pn = 0
        for page in clip["pages"]:
            if "card" in page:
                t_vi, t_en, s_vi, s_en = page["card"]
                k = "STORY_%s_CARD" % up
                keys[k + "_TITLE"] = (t_vi, t_en)
                keys[k + "_SUB"] = (s_vi, s_en)
                out["pages"].append({"card": {"title": k + "_TITLE", "sub": k + "_SUB"}})
                continue
            pn += 1
            polys = g.LAYOUTS[page["layout"]]
            assert len(polys) == len(page["panels"]), (clip_id, pn)
            pg = {"layout": page["layout"], "panels": []}
            doc.append("\n### Trang %d (bố cục %s)\n" % (pn, page["layout"]))
            for poly, p in zip(polys, page["panels"]):
                num += 1
                idx = sum(len(x.get("panels", [])) for x in out["pages"]) + len(pg["panels"]) + 1
                name = "%s_%02d" % (clip_id, idx)
                x0, y0, x1, y1 = g.bbox(poly)
                w, h = x1 - x0, y1 - y0
                lines = []
                for j, (spk, vi, en) in enumerate(p["lines"], 1):
                    k = "STORY_%s_%s_%d" % (up, name.split("_")[-1], j)
                    keys[k] = (vi, en)
                    lines.append({"speaker": spk, "text": k})
                pg["panels"].append({"image": name, "poly": [list(q) for q in poly],
                                     "enter": g.ENTER[(num - 1) % len(g.ENTER)], "desc": p["vi"], "lines": lines})
                shape = shape_names.get(len(poly), "đa giác")
                g.placeholder(os.path.join(ROOT, "assets/placeholders/story/placeholder_%s.png" % name), idx, name, poly,
                              w, h, shape, p["vi"])
                chars = [c for c in p["chars"] if c in CHAR_DESC]
                refs = [CHAR_REF[c] for c in chars if c in CHAR_REF]
                prompt = "%s\n\nScene: %s" % (g.STYLE, p["en"])
                if chars:
                    prompt += "\n\nCharacters:\n" + "\n".join("- " + CHAR_DESC[c] for c in chars)
                prompt += ("\n\nComposition: final image %dx%d px (aspect %.2f:1). The visible area is a %s panel; keep the "
                           "main subject inside it (see the numbered placeholder)." % (
                               w, h, w / h, {3: "triangular", 4: "slanted quadrilateral", 6: "diagonal band"}.get(len(poly), "polygon")))
                doc.append("\n#### %s — ô %02d — `%s.png`\n" % (CLIP_LABEL[clip_id], idx, name))
                doc.append("- **Kích thước ảnh:** %d × %d px (1×; khuyến nghị 2× = %d × %d). Tạo ở %s rồi cắt / co đúng tỉ lệ.\n"
                           % (w, h, w * 2, h * 2, g.gen_size(w, h)))
                doc.append("- **Hình ô:** %s. Placeholder: `assets/placeholders/story/placeholder_%s.png`.\n" % (shape, name))
                doc.append("- **Cảnh:** %s\n" % p["vi"])
                if p["lines"]:
                    doc.append("- **Thoại (game tự hiện, không vẽ vào ảnh):** " + " / ".join(
                        "%s: “%s”" % (sp, vi) for (sp, vi, _en) in p["lines"]) + "\n")
                if refs:
                    doc.append("- **Ảnh tham chiếu đính kèm:** " + ", ".join("`%s`" % r for r in refs) + "\n")
                doc.append("- **Lưu thành:** `assets/story/ch02/%s.png`\n\n```text\n%s\n```\n" % (name, prompt))
            out["pages"].append(pg)
        with io.open(os.path.join(ROOT, "data/story/%s.json" % clip_id), "w", encoding="utf-8", newline="\n") as f:
            f.write(json.dumps(out, ensure_ascii=False, indent="\t") + "\n")

    head = """# Prompt ảnh truyện tranh Chương 2 "Xưởng Đá Ngủ" (mở chương, cổng xưởng, kết chương)

> Sinh bởi `tools/story/gen_story_clips_02.py`; kịch bản gốc ở `docs/design/CH02_STORY.md`. Thứ tự làm (owner 2026-11-21):
> bản chơi thử, rồi placeholder (xong), **ảnh vẽ sau cùng**. Cách làm và quy tắc giấy phép giống `CH01_PANELS.md`: mỗi ô một ảnh,
> lưu PNG đúng tên vào `assets/story/ch02/`, ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1, không vẽ chữ vào ảnh.
> Nhân vật mới: Thợ Cả Ishiro đã có bảng thiết kế (`assets/characters/npc_ishiro_01/design/`, owner duyệt phương án A 2026-11-21);
> Tượng gác nhỏ và Thủ Vệ Cổng chưa có bảng riêng, nên dựng bảng tham chiếu trước (Iwagane có splash trong `assets/characters/char_earth_01/splash/`).
"""
    with io.open(os.path.join(ROOT, "docs/prompts/story/CH02_PANELS.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write(head + "".join(doc))

    for path, idx in (("localization/vi.po", 0), ("localization/en.po", 1)):
        full = os.path.join(ROOT, path)
        s = io.open(full, encoding="utf-8").read()
        add = []
        for k, v in keys.items():
            val = g.esc(v[idx])
            pat = re.compile(r'(msgid "%s"\nmsgstr ")[^\n]*(")\n' % re.escape(k))
            if pat.search(s):
                s = pat.sub(lambda m: m.group(1) + val + m.group(2) + "\n", s)
            else:
                add.append('msgid "%s"\nmsgstr "%s"\n' % (k, val))
        if add:
            s = s.rstrip("\n") + "\n\n" + "\n".join(add)
        io.open(full, "w", encoding="utf-8", newline="\n").write(s)
    print("ô:", num, "khóa chữ:", len(keys))


if __name__ == "__main__":
    main()
