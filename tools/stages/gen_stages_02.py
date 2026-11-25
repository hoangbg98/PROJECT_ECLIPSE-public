"""Sinh màn Chương 2 "Xưởng Đá Ngủ" (2-1 → 2-12) để CHƠI THỬ ĐƯỢC trước khi có ảnh (owner 2026-11-21, thứ tự làm ở
docs/design/CH02_STORY.md mục 8c): dữ liệu màn, quái mới, boss, thoại trong trận, chữ vi / en.

Chạy (thư mục gốc dự án):  python -X utf8 -I tools/stages/gen_stages_02.py

Sinh / cập nhật:
  data/stages/stage_02_01.json … stage_02_12.json   (2-7 → 2-12 có "guest": {"char": "char_earth_01"} = ô khách chơi thử)
  data/enemies/enemy_statue_01.tres, enemy_slime_03.tres            — Tượng gác nhỏ, Cặn đá (khuôn Slime tro lớn)
  data/enemies/boss_minion_*.tres, boss_iwagane_01.tres, boss_gate_01.tres — 4 tay sai cấp thấp, giáp Iwagane, Thủ Vệ Cổng
                                                                       (khuôn boss Shokuhai, số liệu riêng; chưa có ảnh: Polygon2D tạm)
  data/tutorial/battle_barks.json                                   — thoại ch02_*
  localization/vi.po, en.po                                         — STAGE_02_XX_*, ENEMY_*, BOSS_*, BARK_CH02_*
Nền và đất mượn tạm của Chương 1 (`backdrop_from`) tới khi có ảnh riêng. Số cân bằng là số Claude đặt (tự chủ chi tiết
nhỏ), chỉnh ở đây rồi chạy lại. Cốt truyện: docs/design/CH02_STORY.md.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))   # chạy với -I vẫn tìm thấy stage_gen
import stage_gen as sg  # noqa: E402
import gen_stages_01_05_10 as g1  # noqa: E402  (lấy khuôn boss Shokuhai)

GEN = "gen_stages_02.py"
S1, S2, ST, S3 = "enemy_slime_01", "enemy_slime_02", "enemy_statue_01", "enemy_slime_03"
E, K, R, I = "char_fire_01", "char_wind_01", "char_lightning_01", "char_earth_01"
GUEST = {"char": I}

# ---------------------------------------------------------------- quái và boss mới
ENEMIES = {   # id: (khóa chữ, vi, en, hp, atk, def, speed, màu tạm, ghi chú)
    ST: ("ENEMY_STATUE_01", "Tượng gác nhỏ", "Small Guard Statue", 22000, 600, 420, 130, (0.55, 0.53, 0.48),
         "thủ vệ non bị ép thức, cận chiến, chậm"),
    S3: ("ENEMY_SLIME_03", "Cặn đá", "Stone Dreg", 30000, 700, 520, 95, (0.44, 0.42, 0.40),
         "Cặn nhiễm bụi đá, rất trâu, rất chậm"),
}
BOSSES = {   # id: (khóa chữ, vi, en, hp, atk, def, speed, hệ số thời gian đòn, màu tạm, ghi chú)
    "boss_minion_cutter": ("BOSS_MINION_CUTTER", "Kẻ Cắt Dây", "The Rope-Cutter", 70000, 640, 380, 250, 0.75,
                           (0.30, 0.32, 0.36), "nhanh, đòn báo hiệu ngắn (2-2)"),
    "boss_minion_miner": ("BOSS_MINION_MINER", "Kẻ Gõ Đá", "The Rock-Knocker", 110000, 760, 520, 120, 1.3,
                          (0.40, 0.36, 0.32), "chậm, nặng, đòn báo hiệu dài (2-3)"),
    "boss_minion_filer": ("BOSS_MINION_FILER", "Kẻ Mài Mặt Nạ", "The Mask-Filer", 90000, 700, 440, 200, 0.9,
                          (0.78, 0.78, 0.74), "nhiều đòn mồi, báo hiệu ngắn (2-9)"),
    "boss_minion_carrier": ("BOSS_MINION_CARRIER", "Kẻ Gánh Lõi", "The Core-Carrier", 120000, 720, 460, 190, 1.0,
                            (0.34, 0.33, 0.30), "vừa phải, trâu, bỏ chạy khi thua (2-11)"),
    "boss_iwagane_01": ("BOSS_IWAGANE_01", "Iwagane (đấu tập)", "Iwagane (Sparring)", 130000, 700, 600, 140, 1.15,
                        (0.50, 0.40, 0.30), "giáp Iwagane đấu tập, chắc, đòn rõ (2-6)"),
    "boss_gate_01": ("BOSS_GATE_01", "Thủ Vệ Cổng", "The Gate Guardian", 180000, 800, 560, 120, 1.25,
                     (0.46, 0.46, 0.50), "thủ vệ lớn nhất cao nguyên, đang bị cắm lõi lạ (2-12)"),
}
BOSS_SCENE = {"boss_gate_01": "boss_golem"}   # còn lại dùng khung boss_henchman

ENEMY_TEXT = {}
for _k, _v in ENEMIES.items():
    ENEMY_TEXT[_v[0]] = (_v[1], _v[2])
for _k, _v in BOSSES.items():
    ENEMY_TEXT[_v[0]] = (_v[1], _v[2])


def write(rel, text):
    with open(os.path.join(sg.ROOT, rel), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def color(c):
    return "Color(%.2f, %.2f, %.2f, 1)" % c


def build_enemy(eid, spec):
    key, vi, _en, hp, atk, df, speed, col, note = spec
    t = open(os.path.join(sg.ROOT, "data/enemies/enemy_slime_02.tres"), encoding="utf-8").read()
    t = t.replace("enemy_slime_02", eid).replace("ENEMY_SLIME_02", key)
    t = re.sub(r"max_hp = [\d.]+\natk = [\d.]+\ndef = [\d.]+", "max_hp = %d.0\natk = %d.0\ndef = %d.0" % (hp, atk, df), t)
    t = re.sub(r"move_speed = [\d.]+", "move_speed = %d.0" % speed, t)
    t = re.sub(r"placeholder_color = Color\([^)]*\)", "placeholder_color = " + color(col), t)
    t = re.sub(r'metadata/source = "[^"]*"\n$', 'metadata/source = "Claude đặt (Chương 2, tools/stages/%s): %s, HP %d, ATK %d, DEF %d"\n' % (GEN, note, hp, atk, df), t)
    write("data/enemies/%s.tres" % eid, t)


def scaled(t, f):
    def r(m):
        return "%s = %.1f" % (m.group(1), float(m.group(2)) * f)
    return re.sub(r"(startup_ms|recovery_ms|at_ms) = ([\d.]+)", r, t)


def build_boss(bid, spec):
    key, _vi, _en, hp, atk, df, speed, tf, col, note = spec
    t = g1.BOSS_TRES
    t = scaled(t, tf)
    t = t.replace("boss_henchman_01", bid).replace('name_key = "BOSS_HENCHMAN_01"', 'name_key = "%s"' % key)
    t = re.sub(r"max_hp = [\d.]+\natk = [\d.]+\ndef = [\d.]+", "max_hp = %d.0\natk = %d.0\ndef = %d.0" % (hp, atk, df), t)
    t = re.sub(r"(\nmove_speed = )[\d.]+", r"\g<1>%d.0" % speed, t)
    t = re.sub(r"placeholder_color = Color\([^)]*\)", "placeholder_color = " + color(col), t)
    t = re.sub(r'metadata/source = "[^"]*"\n$', 'metadata/source = "Boss Chương 2 (Claude đặt, tools/stages/%s): %s, HP %d, ATK %d, DEF %d, hệ số thời gian đòn %.2f; khuôn Shokuhai"\n' % (GEN, note, hp, atk, df, tf), t)
    write("data/enemies/%s.tres" % bid, t)


# ---------------------------------------------------------------- bố cục màn tự động
def wave(t, lock, *enemies):
    return {"trigger_col": t, "lock_cols": list(lock), "enemies": list(enemies)}


def layout(roster, counts, boss=None, pits_per_gap=1, ceiling=False):
    """Dựng đợt, hố, platform, checkpoint từ danh sách quái. counts: số quái mỗi đợt; roster xoay vòng theo đợt."""
    x = 12
    waves, pits, plats, cps, blocks = [], [], [], [], []
    for i, n in enumerate(counts):
        lock = (x, x + 12 + 5 * n)
        en = []
        for j in range(n):
            en.append((roster[(i + j) % len(roster)], lock[0] + 6 + j * ((lock[1] - lock[0] - 12) // max(n - 1, 1))))
        waves.append(wave(lock[0] + 6, lock, *en))
        base = lock[1] + 8
        for k in range(pits_per_gap):
            a = base + k * 9
            pits.append((a, a + 3))
            plats.append((11, a + 1, a + 2))
        cps.append(base + pits_per_gap * 9 + 1)
        if i % 2 == 1:
            blocks.append((base - 3, base - 3, 1))
        x = base + pits_per_gap * 9 + 10
    out = {"pits": pits, "blocks": blocks, "platforms": plats, "checkpoints": cps, "waves": waves}
    if boss:
        w = x + 66
        out["w"] = w
        out["boss"] = {"id": boss, "trigger_col": w - 52, "lock_cols": [w - 58, w - 4], "col": w - 20}
        cps.append(w - 62)
    else:
        out["w"] = x + 14
        out["goal_col"] = x + 6
    if ceiling:
        out["ceiling"] = [(1, out["w"] - 2, 3)]
    return out


def barks(n, lines):
    """lines: (sự kiện, arg, người nói, khóa đuôi, vi, en, neo_vi, neo_en, delay)."""
    out, text = [], {}
    for on, arg, spk, tail, vi, en, nvi, nen, delay in lines:
        key = "BARK_CH02_%d_%s" % (n, tail)
        b = {"id": "ch02_%d_%s" % (n, tail.lower()), "on": on}
        if arg is not None:
            b["arg"] = arg
        if delay:
            b["delay"] = delay
        b["speaker"], b["text"] = spk, key
        text[key] = (vi, en)
        if spk != "neo":
            b["neo_text"] = key + "_NEO"
            text[key + "_NEO"] = (nvi, nen)
        out.append(b)
    return out, text


def rew(gold, cexp, exp, small, ore, asc=1, reroll=0):
    mats = {"mat_exp_small": small, "mat_enhance_ore": ore, "mat_weapon_ascend": asc}
    if reroll:
        mats["mat_affix_reroll"] = reroll
    return {"gold": gold, "captain_exp": cexp, "exp": exp, "materials": mats}


def first(gems, medium, ore, asc=1, reroll=1):
    return {"gems": gems, "materials": {"mat_exp_medium": medium, "mat_enhance_ore": ore, "mat_weapon_ascend": asc,
                                        "mat_affix_reroll": reroll}}


N = "neo"
STAGES = [
    {"code": "2-1", "name": ("Chân Dốc Thủ Vệ", "Guardian Slope"), "level": 24, "back": "stage_01_04", "open_clip": "ch02_open",
     "desc": ("Đội lên chân dốc cao nguyên theo dấu ba vòng đá. Dấu bánh chở đá và tro lạ hằn trên đường, một Tượng gác nhỏ "
              "mắt đục loạng choạng chặn lối.",
              "The team reaches the foot of the plateau, following the three stone rings. Strange wheel tracks cut the road, "
              "and a small guard statue with clouded eyes lurches into the way."),
     "roster": [ST, S1], "counts": [3, 4, 5], "pits_per_gap": 1, "obj": (300, 22),
     "rew": rew(2600, 1100, 1300, 8, 6), "first": first(100, 3, 4),
     "barks": [("stage_start", None, N, "START", "Tọa độ khớp: Cao Nguyên Thủ Vệ. Mật độ nguyên tố Địa 18%, đang giảm.",
                "Coordinates match: Guardian Highlands. Earth element density 18% and falling.", "", "", 0),
               ("wave_started", 0, R, "WAVE1", "Yên quá. Xưởng làm thủ vệ mà không có tiếng búa nào.",
                "Too quiet. A guardian workshop and not one hammer ringing.", "Chưa thấy ai ở trạm gác đầu dốc.",
                "No one at the first guard post.", 0),
               ("wave_started", 1, K, "WAVE2", "Mắt chúng đục như bị ép thức. Đừng xuống tay nặng quá.",
                "Their eyes are clouded, they've been forced awake. Don't strike harder than you must.",
                "Tượng gác nhỏ: thủ vệ non, mất ca nghỉ.", "Small guard statues: young guardians, robbed of their rest.", 0),
               ("wave_cleared", 2, E, "CLEAR", "Tớ vừa đập một con như vậy ở nhà tớ. Giờ tớ thấy khó chịu.",
                "I smashed one of these back home. Now I feel sick about it.", "Dốc đã thông. Ra cuối dốc để hoàn tất.",
                "The slope is clear. Reach the top to finish.", 0)]},
    {"code": "2-2", "name": ("Cầu Đá Gãy", "Broken Stone Bridge"), "level": 26, "back": "stage_01_06",
     "desc": ("Cầu qua vực bị đục sập một nửa. Kazeyumi đọc vết đục: đục từ trong ra. Một tay sai mặt nạ, Kẻ Cắt Dây, đang cắt nốt "
              "dây cầu.",
              "The bridge across the chasm is half collapsed. Kazeyumi reads the chisel marks: cut from the inside. A masked "
              "henchman, the Rope-Cutter, is cutting the last cables."),
     "roster": [ST, S2], "counts": [3, 5], "boss": "boss_minion_cutter", "pits_per_gap": 2, "obj": (330, 22),
     "rew": rew(2700, 1150, 1350, 8, 6), "first": first(100, 3, 4),
     "barks": [("stage_start", None, N, "START", "Cầu sập từng nhịp. Vết đục đều và sạch, không phải thủ vệ phá.",
                "The bridge is falling span by span. The cuts are clean and even, not guardian work.", "", "", 0),
               ("wave_started", 0, R, "WAVE1", "Để tớ chạy trước dò nhịp nào còn chịu được.",
                "Let me run ahead and test which spans still hold.", "Nhịp 3 và 5 còn chịu tải.", "Spans 3 and 5 still hold.", 0),
               ("boss_started", None, K, "BOSS", "Dây cầu bị cắt từ trong ra. Hắn mặc giáp có vòng 00!",
                "The cables were cut from the inside. He wears armor with a 00 ring!",
                "Mục tiêu: Kẻ Cắt Dây. Rất nhanh, báo hiệu đòn ngắn.", "Target: the Rope-Cutter. Very fast, short telegraphs.", 0.4)]},
    {"code": "2-3", "name": ("Mỏ Đá Câm", "Silent Quarry"), "level": 28, "back": "stage_01_07",
     "desc": ("Mỏ ngừng làm. Công nhân bỏ chạy, nói đá thức dậy trong đêm. Kẻ Gõ Đá canh cửa hầm, búa to đập đất rung cả vách.",
              "The quarry has stopped. Miners fled saying the stone woke in the night. The Rock-Knocker guards the shaft, his "
              "hammer shaking the walls."),
     "roster": [S3, ST, S2], "counts": [4, 5, 6], "boss": "boss_minion_miner", "pits_per_gap": 1, "obj": (360, 24),
     "rew": rew(2800, 1200, 1400, 9, 7), "first": first(100, 3, 4),
     "barks": [("stage_start", None, N, "START", "Mỏ đá cổ. Bụi đá dày, nguyên tố Địa loãng không đều.",
                "An old quarry. Thick stone dust, Earth density uneven.", "", "", 0),
               ("wave_started", 0, E, "WAVE1", "Cặn nhiễm bụi đá, cứng quá. Đánh vào chỗ sáng của nó.",
                "These Dregs are caked with stone dust, tough. Hit where it glows.", "Cặn đá: rất trâu, rất chậm.",
                "Stone Dregs: very tanky, very slow.", 0),
               ("boss_started", None, R, "BOSS", "Búa to ghê. Chậm nhưng đừng đứng gần!",
                "Huge hammer. Slow, but don't stand close!", "Mục tiêu: Kẻ Gõ Đá. Đòn nặng, báo hiệu dài.",
                "Target: the Rock-Knocker. Heavy hits, long telegraph.", 0.4)]},
    {"code": "2-4", "name": ("Nhà Đá Của Dân", "The Stone Houses"), "level": 30, "back": "stage_01_08",
     "desc": ("Làng nhỏ ven cao nguyên bị tượng non quấy phá. Dân ngờ đội: có người lạ lên là đá nổi điên. Giữ làng, đừng để ai gục.",
              "A small village on the plateau is harassed by young statues. The villagers suspect the team: strangers arrive "
              "and the stone goes wild. Defend them, let no one fall."),
     "roster": [ST, S3], "counts": [3, 4, 4, 5], "pits_per_gap": 1, "obj": (400, 18),
     "rew": rew(2900, 1250, 1450, 9, 7), "first": first(100, 3, 4),
     "barks": [("stage_start", None, N, "START", "Dân trong làng nhìn chúng ta. Đừng để họ thấy ai gục.",
                "The villagers are watching us. Don't let them see anyone fall.", "", "", 0),
               ("wave_started", 1, K, "WAVE2", "Họ có lý do sợ. Cứ làm cho họ thấy mình là người bảo vệ.",
                "They have reason to be afraid. Just show them we're here to protect.", "Mục tiêu phụ: không ai gục.",
                "Bonus goal: nobody goes down.", 0),
               ("wave_cleared", 3, R, "CLEAR", "Bà cụ kia vừa đưa nước cho tớ! Xem ra xong rồi nhé.",
                "That old lady just handed me water! Looks like we're good.", "Làng an toàn. Ra cuối làng để hoàn tất.",
                "Village safe. Reach the end to finish.", 0)]},
    {"code": "2-5", "name": ("Hành Lang Tượng", "Hall of Statues"), "level": 32, "back": "stage_01_04",
     "desc": ("Hành lang xưởng đầy tượng ngủ im. Kazeyumi nhận ra mỗi tượng có hốc ngực trống: lõi của chúng đã bị lấy đi.",
              "A workshop hall lined with silent sleeping statues. Kazeyumi notices every one has an empty chest hollow: "
              "their cores have been taken."),
     "roster": [ST, S3, S2], "counts": [4, 5, 6], "pits_per_gap": 1, "obj": (400, 22), "ceiling": True,
     "rew": rew(3000, 1300, 1500, 10, 8), "first": first(100, 3, 5),
     "barks": [("stage_start", None, N, "START", "Hành lang tượng. Không có tiếng gì, ngoài tiếng bước chân của chúng ta.",
                "The statue hall. No sound but our own footsteps.", "", "", 0),
               ("checkpoint", 0, K, "CP1", "Nhìn ngực chúng đi. Hốc trống. Lõi của chúng đã bị tháo.",
                "Look at their chests. Empty hollows. Their cores were taken.", "Đã ghi: hốc lõi trống.",
                "Logged: empty core hollows.", 0),
               ("wave_cleared", 2, E, "CLEAR", "Ai làm thế này không muốn chúng ngủ. Muốn chúng thức mà không có lõi.",
                "Whoever did this didn't want them sleeping. They wanted them awake and coreless.",
                "Cổng xưởng ở cuối hành lang.", "The workshop gate is at the end of the hall.", 0)]},
    {"code": "2-6", "name": ("Cửa Xưởng", "The Workshop Gate"), "level": 34, "back": "stage_01_10", "open_clip": "ch02_gate",
     "desc": ("Iwagane chặn cổng xưởng, đòi đội trả lõi. Một ca đấu tập thử người: qua được thì được vào.",
              "Iwagane blocks the workshop gate, demanding the cores back. A sparring trial: pass it and you may enter."),
     "roster": [ST, S3], "counts": [4], "boss": "boss_iwagane_01", "pits_per_gap": 1, "obj": (420, 22),
     "rew": rew(3200, 1400, 1600, 10, 8, 2, 1), "first": first(150, 4, 5, 2),
     "barks": [("stage_start", None, N, "START", "Cổng xưởng. Một người đứng chặn, đại kiếm cắm xuống đất.",
                "The workshop gate. One person stands in the way, greatsword planted in the ground.", "", "", 0),
               ("boss_started", None, E, "BOSS", "Tụi em không lấy lõi. Nếu chị không tin lời, thì tin trận đánh.",
                "We didn't take the cores. If you won't trust words, trust the fight.",
                "Mục tiêu: Iwagane (đấu tập). Chắc, đòn rõ. Đây không phải kẻ thù.",
                "Target: Iwagane (sparring). Sturdy, clear attacks. This is not an enemy.", 0.4),
               ("boss_phase", 2, K, "PHASE2", "Chị ấy nghiêm túc rồi. Đỡ cho khéo.",
                "She's getting serious now. Block carefully.", "Iwagane vào pha hai. Đòn nhanh hơn.",
                "Iwagane enters phase two. Faster attacks.", 0)]},
    {"code": "2-7", "name": ("Sân Rèn Nguội", "The Cold Forge"), "level": 36, "back": "stage_01_07", "guest": True,
     "desc": ("Iwagane cho vào xưởng. Thợ Cả bị thương, lò nguội vì lõi bị lấy. Chị đi cùng đội giữ sân rèn trước đợt tượng thức giấc.",
              "Iwagane lets the team into the workshop. The Master is wounded and the forge is cold, its cores stolen. She "
              "joins the team to hold the forge yard against waking statues."),
     "roster": [ST, S3], "counts": [4, 5], "pits_per_gap": 1, "obj": (380, 20),
     "rew": rew(3300, 1450, 1650, 10, 8), "first": first(100, 4, 5),
     "barks": [("stage_start", None, N, "START", "Iwagane vào kênh. Slot khách: chơi thử. Mỗi lõi trống là một ca gác bị bỏ.",
                "Iwagane joins the channel. Guest slot: trial. Every empty core is a watch left unmanned.", "", "", 0),
               ("wave_started", 0, I, "WAVE1", "Sân này chị giữ nhiều năm. Để chị đứng trước.",
                "I've held this yard for years. Let me stand in front.", "Iwagane: tank, khiêu khích kẻ địch.",
                "Iwagane: tank, taunts enemies.", 0),
               ("wave_cleared", 1, R, "CLEAR", "Lò nguội quá. Cái này không phải lò hỏng, là bị bỏ trống.",
                "The forge is so cold. It's not broken, it's been abandoned.", "Lối vào kho lõi đã mở.",
                "The way to the core vault is open.", 0)]},
    {"code": "2-8", "name": ("Kho Lõi", "The Core Vault"), "level": 38, "back": "stage_01_07", "guest": True,
     "desc": ("Trong kho lõi có hơn chục hốc trống. Mảnh ấn mã 00 của Raikiba rung theo lõi còn lại: cùng một nguồn. Dọn tượng thức giấc "
              "trong kho.",
              "The core vault holds over a dozen empty hollows. Raikiba's 00 seal shard hums with the remaining cores: same "
              "source. Clear the awakened statues inside."),
     "roster": [ST, S3, S2], "counts": [4, 5, 6], "pits_per_gap": 1, "obj": (420, 22), "ceiling": True,
     "rew": rew(3400, 1500, 1700, 11, 9), "first": first(100, 4, 5),
     "barks": [("stage_start", None, N, "START", "Kho lõi. Mười bốn hốc trống. Mảnh ấn mã 00 đang rung.",
                "The core vault. Fourteen empty hollows. The 00 seal shard is vibrating.", "", "", 0),
               ("checkpoint", 1, R, "CP2", "Cái này sáng lên mỗi lần tớ lại gần lõi. Nó nhận ra nhau!",
                "This lights up whenever I get close to a core. They recognize each other!",
                "Tần số trùng. Lõi thủ vệ và Neo có cùng cấu trúc vật liệu.",
                "Frequencies match. Guardian cores and the Neo share a material structure.", 0),
               ("wave_cleared", 2, I, "CLEAR", "Vậy Neo của các em và lõi của xưởng là họ hàng.",
                "So your Neo and the workshop's cores are kin.", "Hoàn tất khu kho.", "Vault area complete.", 0)]},
    {"code": "2-9", "name": ("Đêm Đổi Ca", "The Night Shift"), "level": 40, "back": "stage_01_09", "guest": True,
     "desc": ("Đêm đầu giữ ca cùng Iwagane: tượng thức giấc từng đợt, và Kẻ Mài Mặt Nạ chặn đúng lúc đổi ca. Đội hiểu ca gác đôi.",
              "The first night standing watch with Iwagane: statues wake in waves, and the Mask-Filer strikes right at the "
              "shift change. The team understands the paired watch."),
     "roster": [ST, S3, S1], "counts": [4, 5, 6], "boss": "boss_minion_filer", "pits_per_gap": 1, "obj": (440, 22),
     "rew": rew(3500, 1550, 1750, 11, 9, 2), "first": first(100, 4, 5, 2),
     "barks": [("stage_start", None, I, "START", "Họ Gác không đánh thức thủ vệ. Bọn chị đổi ca cho chúng.",
                "The Gác don't wake guardians. We change their shifts.", "Đêm đổi ca bắt đầu. Iwagane đang chơi thử.",
                "The night shift begins. Iwagane is on trial.", 0),
               ("wave_started", 1, E, "WAVE2", "Chị từng gác một mình chưa?", "Have you ever stood watch alone?",
                "Chưa có phản hồi.", "No answer yet.", 0),
               ("boss_started", None, K, "BOSS", "Hắn chặn đúng lúc đổi ca. Hắn biết lịch gác!",
                "He struck right at the shift change. He knows the watch schedule!",
                "Mục tiêu: Kẻ Mài Mặt Nạ. Nhiều đòn mồi, đừng nhảy sớm.",
                "Target: the Mask-Filer. Lots of feints, don't jump early.", 0.4)]},
    {"code": "2-10", "name": ("Đường Mật Chở Lõi", "The Core Smugglers' Trail"), "level": 42, "back": "stage_01_08", "guest": True,
     "desc": ("Lần theo vết kẻ trộm: kênh xe chở đá bí mật dưới vách, nhiều hố và bẫy. Vết bánh dẫn về phía bắc.",
              "Following the thieves' trail: a hidden cart channel under the cliff, full of pits and traps. The tracks lead north."),
     "roster": [ST, S3, S2, S1], "counts": [5, 5, 6], "pits_per_gap": 2, "obj": (460, 24),
     "rew": rew(3600, 1600, 1800, 12, 10), "first": first(100, 4, 6),
     "barks": [("stage_start", None, N, "START", "Ba vệt chở, cùng một hướng: phía bắc.",
                "Three cart tracks, same direction: north.", "", "", 0),
               ("wave_started", 0, R, "WAVE1", "Vết bánh mới. Chúng chưa đi xa!",
                "Fresh wheel marks. They can't be far!", "Nhiều hố phía trước, cẩn thận.", "Many pits ahead, careful.", 0),
               ("wave_cleared", 2, I, "CLEAR", "Thủ vệ ở đây bị cắm lõi lạ. Chị không muốn nghĩ ra ai làm.",
                "The guardians here have foreign cores. I don't want to think who did it.",
                "Đường mật dẫn ra dốc phía bắc.", "The trail exits onto the north slope.", 0)]},
    {"code": "2-11", "name": ("Dốc Đổ Sét", "Thunder-Spill Slope"), "level": 44, "back": "stage_01_05", "guest": True,
     "desc": ("Gặp Kẻ Gánh Lõi cùng hai lõi đang chở. Hắn thả tượng chặn đường. Hạ hắn, giữ lại lõi hắn bỏ chạy.",
              "The team meets the Core-Carrier hauling two cores. He releases statues to block the way. Bring him down and keep "
              "the core he drops fleeing."),
     "roster": [ST, S3], "counts": [5, 5], "boss": "boss_minion_carrier", "pits_per_gap": 1, "obj": (460, 22),
     "rew": rew(3700, 1650, 1850, 12, 10, 2), "first": first(100, 4, 6, 2),
     "barks": [("stage_start", None, N, "START", "Tín hiệu mã 00 ngay phía trước. Có người đang chở lõi.",
                "00 signal dead ahead. Someone is hauling cores.", "", "", 0),
               ("boss_started", None, R, "BOSS", "Nặng thế mà chạy nhanh! Đừng để hắn thoát!",
                "Loaded like that and still fast! Don't let him escape!",
                "Mục tiêu: Kẻ Gánh Lõi. Đánh tới khi hắn bỏ chạy.", "Target: the Core-Carrier. Fight until he flees.", 0.4),
               ("boss_phase", 2, I, "PHASE2", "Nó đang gồng cả hai lõi. Chị đỡ, các em đánh!",
                "He's straining both cores. I'll hold, you strike!", "Pha hai: hắn dồn cả hai lõi.",
                "Phase two: he's channeling both cores.", 0)]},
    {"code": "2-12", "name": ("Cổng Thủ Vệ", "The Guardian Gate"), "level": 46, "back": "stage_01_10", "guest": True, "end_clip": "ch02_end",
     "desc": ("Thủ vệ lớn nhất cao nguyên, bị cắm lõi lạ, nổi điên chắn cổng. Iwagane đứng ra giữ cửa, cả đội chia ca với chị.",
              "The plateau's greatest guardian, fitted with a foreign core, rages across the gate. Iwagane steps up to hold it, "
              "and the team shares the watch with her."),
     "roster": [ST, S3], "counts": [5, 6], "boss": "boss_gate_01", "pits_per_gap": 1, "obj": (500, 24),
     "rew": rew(4000, 1800, 2000, 14, 12, 3, 2), "first": first(300, 5, 8, 3, 2),
     "barks": [("stage_start", None, N, "START", "Thủ vệ Cổng. Lõi lạ trong ngực nó mang vòng 00.",
                "The Gate Guardian. The foreign core in its chest carries a 00 ring.", "", "", 0),
               ("boss_started", None, I, "BOSS", "Cổng này chị giữ. Nhưng chị không giữ một mình.",
                "This gate is mine to hold. But I won't hold it alone.", "Mục tiêu: Thủ Vệ Cổng. Rất trâu, đòn lớn.",
                "Target: the Gate Guardian. Very sturdy, big attacks.", 0.4),
               ("boss_phase", 2, K, "PHASE2", "Vòng 00 lộ ra trên ngực nó! Đánh vỡ lõi lạ!",
                "The 00 ring is showing on its chest! Break the foreign core!",
                "Lõi lạ quá tải. Pha hai.", "The foreign core is overloading. Phase two.", 0)]},
]


def main():
    text = dict(ENEMY_TEXT)
    for eid, spec in ENEMIES.items():
        build_enemy(eid, spec)
    for bid, spec in BOSSES.items():
        build_boss(bid, spec)
    for s in STAGES:
        n = int(s["code"].split("-")[1])
        sid = "stage_02_%02d" % n
        lay = layout(s["roster"], s["counts"], s.get("boss"), s.get("pits_per_gap", 1), s.get("ceiling", False))
        spec = {"id": sid, "code": s["code"], "name_vi": s["name"][0], "generator": GEN, "level": s["level"],
                "objectives": s["obj"], "backdrop_from": s["back"],
                "design": "Chương 2, %d đợt%s%s; nền / đất mượn tạm của %s." % (
                    len(lay["waves"]), " + boss " + s["boss"] if s.get("boss") else ", không boss: tới đích",
                    ", có ô khách Iwagane" if s.get("guest") else "", s["back"]),
                "rewards": s["rew"], "first_clear": s["first"]}
        spec.update(lay)
        if s.get("guest"):
            spec["guest"] = GUEST
        for ck in ("open_clip", "end_clip"):
            if s.get(ck):
                spec[ck] = s[ck]
        up = sid.upper()
        text["%s_NAME" % up] = s["name"]
        text["%s_DESC" % up] = s["desc"]
        bk, bt = barks(n, s["barks"])
        text.update(bt)
        sg.write_json("data/stages/%s.json" % sid, sg.build_stage(spec))
        sg.merge_barks(sid, bk)
        print("%s %-26s %3d cột, %d đợt%s%s" % (s["code"], s["name"][0], lay["w"], len(lay["waves"]),
                                              " + boss" if s.get("boss") else "", " + khách" if s.get("guest") else ""))
    sg.write_text(text)


if __name__ == "__main__":
    main()
