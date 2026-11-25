class_name JetGenerator
extends RefCounted
## Bộ sinh Bay Nguyên Tố (docs/design/JET_MODE.md mục 10, 11). Tất định (xorshift32 của RunnerGenerator). Sinh từng
## **cụm** (một Thanh Cặn, một Van Sét, một hàng hạt…) quanh một **hành lang** an toàn: trước mỗi cụm chọn tâm hành lang
## mới trong tầm bay tới được (bảng mục 4 × 0.7, tính cả gió), đặt vật cản ngoài hành lang, ghi đường giữa hành lang vào
## `level.path`. Ước lượng năng lượng dọc đường: thấp thì cho chạy đất để hồi và rải Tinh Lõi.
##
## cfg: seed riêng ở `new()`; level_id, length_m (0 = Vô tận), scroll_base, scroll_ramp, zones / zone_cycle (trong
## JetLevel), forms (hình hộp được ra), kinds (loại cụm cho phép, rỗng = theo vùng), boxes (có Hộp Ký Ức), boss,
## max_core_gap_m (Tinh Lõi cách nhau tối đa), first_form (hình của hộp đầu tiên, mặc định Rồng).

## Tâm hành lang cách vật cản tối thiểu (px): đủ cho Rồng (bán kính 48) + độ dày vật 13 + sai số bay của người / bot.
const CLEAR := 100.0
## Tâm hành lang khi chạy đất (người đứng sàn có tâm ở floor − 32).
const GROUND_C := 850.0
const C_MIN := 230.0
const C_MAX := 820.0
const MIS_CLEAR := 170.0
const SWP_MOTION := 60.0
## Tầm lên / xuống từ nghỉ sau 0.25 / 0.5 / 1.0 s (mục 4), hệ số an toàn 0.7.
const REACH_T := [0.0, 0.25, 0.5, 1.0]
const REACH_UP := [0.0, 44.0, 175.0, 610.0]
const REACH_DOWN := [0.0, 69.0, 275.0, 825.0]
const REACH_SAFE := 0.7
const DEFAULT_KINDS := {"beam": 3, "mis": 2, "orb": 3, "swp": 2, "gate": 2}

var rules: JetRules
var cfg: Dictionary
var rng: RunnerGenerator

var x := 0.0
var c := GROUND_C
var energy_est := 100.0
var ground_until := 0.0
var form_until := 0.0
var form_kind := ""
var next_box_x := 0.0
var boxes := 0
var last_gate_x := -1e9
var last_mis_x := -1e9
var last_core_x := 0.0
var zone := ""
var started := false


func _init(seed_: int, cfg_: Dictionary, rules_: JetRules = null) -> void:
	cfg = cfg_
	rules = rules_ if rules_ else load("res://data/jet/jet_rules.tres") as JetRules
	rng = RunnerGenerator.new(seed_)


static func generate(seed_: int, cfg_: Dictionary) -> JetLevel:
	var lv := JetLevel.new()
	lv.level_id = str(cfg_.get("level_id", ""))
	lv.length_m = float(cfg_.get("length_m", 800.0))
	lv.scroll_base = float(cfg_.get("scroll_base", 520.0))
	lv.scroll_ramp = float(cfg_.get("scroll_ramp", 0.15))
	lv.zones = cfg_.get("zones", [{"from_m": 0, "id": "ash"}])
	lv.forms = cfg_.get("forms", [])
	lv.bpm = float(cfg_.get("bpm", 128.0))
	lv.bgm = str(cfg_.get("bgm", ""))
	lv.boss = cfg_.get("boss")
	var g := JetGenerator.new(seed_, cfg_)
	g.fill(lv, lv.length_m)
	return lv


static func reach(dt: float, up: bool) -> float:
	var tab: Array = REACH_UP if up else REACH_DOWN
	if dt >= 1.0:
		return float(tab[3]) + (900.0 if up else 1100.0) * (dt - 1.0)
	for i in range(1, 4):
		if dt <= float(REACH_T[i]):
			var k := (dt - float(REACH_T[i - 1])) / (float(REACH_T[i]) - float(REACH_T[i - 1]))
			return lerpf(float(tab[i - 1]), float(tab[i]), k)
	return float(tab[3])


## Quãng (px) từ lúc hiện cảnh báo tới lúc Cặn Phóng chạm người bay.
static func missile_lead(level: JetLevel, warn_x: float, rules_: JetRules) -> float:
	var sc := level.scroll_at_px(warn_x)
	return sc * rules_.missile_warn + sc * (rules_.spawn_x - rules_.player_x) / (sc + rules_.missile_speed)


func _rf(a: float, b: float) -> float:
	return a + rng.randf_() * (b - a)


## Sinh cụm tới khi phủ tới mét `until_m` (+ khoảng nhìn trước của màn hình).
func fill(level: JetLevel, until_m: float) -> void:
	var end_px := level.length_px() if not level.is_endless() else INF
	if not started:
		started = true
		x = maxf(JetLevel.FIRST_EVENT_SEC * level.scroll_base, 900.0)
		c = GROUND_C
		level.path.append(Vector2(-2000.0, GROUND_C))
		level.path.append(Vector2(x, GROUND_C))
		next_box_x = x + _rf(4000.0, 8000.0)
		zone = level.zone_at_px(x)
	var want := until_m * JetLevel.PX_PER_M + 4000.0
	var added: Array[Dictionary] = []
	while x < want and x < end_px - 600.0:
		_cluster(level, added)
	if x >= end_px - 600.0 and level.path[level.path.size() - 1].x < end_px + 3000.0:
		level.path.append(Vector2(end_px + 3000.0, c))
	if not level.is_endless():
		added = added.filter(func(e: Dictionary) -> bool: return float(e["x"]) <= end_px - 60.0)
	if added.is_empty():
		return
	for e in added:
		e["d"] = snappedf(float(e["x"]) / JetLevel.PX_PER_M, 0.01)
		e["x"] = float(e["d"]) * JetLevel.PX_PER_M
	level.events.append_array(added)
	level.events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["x"]) < float(b["x"]))


func _kinds(level: JetLevel, ground: bool) -> Dictionary:
	var w: Dictionary = JetLevel.zone_def(zone).get("weights", DEFAULT_KINDS).duplicate()
	var allow: Array = cfg.get("kinds", [])
	if not allow.is_empty():
		for k in w.keys():
			if not k in allow:
				w.erase(k)
	if ground:
		w.erase("gate")
	if w.is_empty():
		w = {"orb": 1}
	return w


func _weighted(w: Dictionary) -> String:
	var total := 0.0
	for k in w:
		total += float(w[k])
	var r := rng.randf_() * total
	for k in w:
		r -= float(w[k])
		if r < 0.0:
			return str(k)
	return str(w.keys()[0])


func _wind_on_span(level: JetLevel, a: float, b: float) -> float:
	## > 0 nếu có gió xuống trong đoạn, < 0 nếu gió lên, 0 nếu không gió (ưu tiên gió xuống).
	var up := false
	var s := a
	while s <= b:
		var w := level.wind_at_px(s, rules)
		if w > 0.0:
			return 1.0
		if w < 0.0:
			up = true
		s += 40.0
	return -1.0 if up else 0.0


## Tâm hành lang mới trong tầm bay tới được sau `dt` giây.
func _next_c(level: JetLevel, dt: float, a: float, b: float, lo := C_MIN, hi := C_MAX) -> float:
	var wind := _wind_on_span(level, a, b)
	var up := reach(dt, true) * REACH_SAFE
	var down := reach(dt, false) * REACH_SAFE
	var dragon := form_kind == "dragon" and b < form_until
	if wind > 0.0:
		# Gió xuống: người thường giữ chỉ còn −100 px/s² (gần như không lên được); Rồng còn −1300.
		up = up * 0.5 if dragon else minf(up, 10.0)
	elif wind < 0.0:
		# Gió lên: thả ra người thường còn rơi +900 px/s²; Rồng chỉ còn +200.
		down *= 0.12 if dragon else 0.4
	var lo2 := maxf(lo, c - up)
	var hi2 := minf(hi, c + down)
	if lo2 > hi2:
		return clampf(c, lo, hi)
	return _rf(lo2, hi2)


func _cluster(level: JetLevel, out: Array[Dictionary]) -> void:
	var sc := level.scroll_at_px(x)
	# Vùng mới: nghỉ ≥ 1000 px (biểu ngữ), hành lang giữ nguyên.
	var z := level.zone_at_px(x + sc)
	if z != zone:
		zone = z
		x = level.zone_start_px(x + sc) + 1000.0
		level.path.append(Vector2(x, c))
		return
	var grounded := x < ground_until or (energy_est < 40.0 and x >= form_until)
	if energy_est < 40.0 and x >= ground_until and x >= form_until:
		ground_until = x + sc * 4.5
	var kind := _weighted(_kinds(level, grounded))
	var gap := sc * _rf(0.9, 1.3)
	var before := 60.0
	var after := 60.0
	var c2 := c
	var X := 0.0
	match kind:
		"beam":
			before = 300.0
			after = 300.0
		"gate":
			before = 35.0 + 120.0
			after = 35.0 + 120.0
		"swp":
			before = 130.0
			after = 130.0
		"mis":
			before = 260.0
			after = 260.0
		"orb":
			before = 20.0
			after = 5.0 * rules.orb_spacing + 30.0
	X = x + maxf(gap, before + sc * 0.45)
	var trans_dt := (X - before - x) / sc
	if grounded:
		c2 = GROUND_C if c >= GROUND_C - 5.0 or reach(trans_dt, false) * REACH_SAFE >= GROUND_C - c else c + reach(trans_dt, false) * REACH_SAFE
	elif kind == "gate":
		c2 = clampf(_next_c(level, trans_dt, x, X - before, 300.0, 700.0), 300.0, 700.0)
	else:
		c2 = _next_c(level, trans_dt, x, X - before)
	if kind == "gate" and (X - last_gate_x < 1.2 * sc or absf(X - last_mis_x) < 1.0 * sc or absf(c2 - c) > reach(trans_dt, c2 < c) * REACH_SAFE + 1.0):
		kind = "orb"
		before = 20.0
		after = 5.0 * rules.orb_spacing + 30.0
	if kind == "mis" and (X - last_mis_x < 1.0 * sc or X - last_gate_x < 1.0 * sc):
		kind = "orb"
		before = 20.0
		after = 5.0 * rules.orb_spacing + 30.0
	level.path.append(Vector2(X - before, c2))
	# Tinh Lõi / Hộp Ký Ức ngay đầu đoạn phẳng, trên hành lang.
	var pick_x := X - before - 10.0
	_maybe_core(level, out, pick_x, c2, sc)
	var box_x := pick_x - 140.0
	_maybe_box(level, out, box_x, lerpf(c, c2, clampf((box_x - x) / maxf(X - before - x, 1.0), 0.0, 1.0)), sc)
	match kind:
		"beam":
			_beam(out, X, c2)
		"gate":
			out.append({"x": X, "type": "gate", "y": roundi(c2), "from_boss": level.boss != null})
			last_gate_x = X
		"swp":
			_sweep(out, X, c2)
		"mis":
			_missile(level, out, X, c2)
		"orb":
			var wave := not grounded and rng.randf_() < 0.3
			out.append({"x": X, "type": "orbs", "y": roundi(c2), "n": 6, "wave": wave})
	level.path.append(Vector2(X + after, c2))
	# Năng lượng: đoạn từ x tới hết cụm.
	var seg_dt := (X + after - x) / sc
	if x < form_until:
		pass
	elif c2 >= GROUND_C - 5.0 and c >= GROUND_C - 5.0:
		energy_est += rules.energy_regen_ground * seg_dt
	else:
		# Ước lượng thận trọng: lơ lửng giữ ~70 % thời gian (lý thuyết 61 %), leo thêm tốn theo độ cao.
		energy_est -= rules.energy_drain * 0.7 * seg_dt
		energy_est -= rules.energy_drain * maxf(c - c2, 0.0) / 500.0
		if _wind_on_span(level, x, X + after) > 0.0:
			energy_est -= 10.0 * seg_dt
	energy_est = clampf(energy_est, 0.0, rules.energy_max)
	x = X + after
	c = c2


func _maybe_core(level: JetLevel, out: Array[Dictionary], px: float, py: float, sc: float) -> void:
	# Mục 7: 0.30 sau mỗi cụm, +0.30 khi năng lượng < 40; chỉ rải khi thùng đã vơi (< 70) để Tinh Lõi có giá trị.
	var p := 0.30
	if energy_est < 40.0:
		p += 0.30
	var max_gap := float(cfg.get("max_core_gap_m", 1200.0)) * JetLevel.PX_PER_M * 0.8
	if (rng.randf_() < p and energy_est < 60.0) or px - last_core_x > max_gap:
		out.append({"x": px, "type": "core", "y": roundi(py)})
		energy_est = minf(energy_est + rules.core_gain, rules.energy_max)
		last_core_x = px


func _maybe_box(level: JetLevel, out: Array[Dictionary], px: float, py: float, sc: float) -> void:
	if not bool(cfg.get("boxes", true)) or px < next_box_x or px < form_until:
		return
	var allowed: Array = []
	for f in JetLevel.zone_def(zone).get("forms", []):
		if level.forms.has(f):
			allowed.append(f)
	if allowed.is_empty():
		return
	var first := str(cfg.get("first_form", "dragon"))
	var form := first if boxes == 0 and allowed.has(first) else str(rng.pick(allowed))
	out.append({"x": px, "type": "box", "y": roundi(py), "form": form})
	boxes += 1
	next_box_x = px + _rf(10000.0, 18000.0)
	if form == "robo":
		# Robo chạy đất: hành lang xuống sàn hết thời gian hình (+0.8 s) để lúc trở lại người thường vẫn an toàn.
		ground_until = px + (rules.robo_time + 0.8) * sc
		form_until = px + rules.robo_time * sc
		form_kind = "robo"
	else:
		form_until = px + rules.dragon_time * sc
		form_kind = "dragon"


func _beam(out: Array[Dictionary], X: float, c2: float) -> void:
	for attempt in 8:
		var L := _rf(110.0, 210.0)
		var ang: float = rng.pick([0.0, 90.0, 45.0, -45.0])
		if attempt >= 6:
			ang = 0.0
			L = 110.0
		var e := L * absf(sin(deg_to_rad(ang)))
		var opts: Array = []
		var below_lo := c2 + CLEAR + e
		if below_lo <= 740.0:
			opts.append(_rf(below_lo, 740.0))
		var above_hi := c2 - CLEAR - e
		if above_hi >= 260.0:
			opts.append(_rf(260.0, above_hi))
		if not opts.is_empty():
			out.append({"x": X, "type": "beam", "y": roundi(float(rng.pick(opts))), "len": roundi(L), "ang": ang})
			return


func _sweep(out: Array[Dictionary], X: float, c2: float) -> void:
	var A := _rf(150.0, 250.0)
	var wl := _rf(1100.0, 1700.0)
	var reach_px := CLEAR + rules.sweep_half + rules.obstacle_thickness + SWP_MOTION
	var low_cy := c2 + reach_px - A + _rf(0.0, 30.0)   # thanh ở cực dưới khi người bay đi qua
	var high_cy := c2 - reach_px + A - _rf(0.0, 30.0)  # thanh ở cực trên
	var opts: Array = []
	if low_cy <= 740.0 and low_cy >= 260.0:
		opts.append([low_cy, PI * 0.5])
	if high_cy >= 260.0 and high_cy <= 740.0:
		opts.append([high_cy, -PI * 0.5])
	if opts.is_empty():
		_beam(out, X, c2)
		return
	var o: Array = rng.pick(opts)
	var ph := fposmod(float(o[1]) - TAU * X / wl, TAU)
	out.append({"x": X, "type": "swp", "y": roundi(float(o[0])), "amp": roundi(A), "wl": roundi(wl), "ph": snappedf(ph, 0.0001)})


func _missile(level: JetLevel, out: Array[Dictionary], X: float, c2: float) -> void:
	var opts: Array = []
	if c2 - MIS_CLEAR >= 200.0:
		opts.append(_rf(200.0, c2 - MIS_CLEAR))
	if c2 + MIS_CLEAR <= 800.0:
		opts.append(_rf(c2 + MIS_CLEAR, 800.0))
	if opts.is_empty():
		return
	var warn := X - missile_lead(level, X, rules)
	warn = X - missile_lead(level, warn, rules)
	if warn < JetLevel.FIRST_EVENT_SEC * level.scroll_base + 10.0:
		return
	out.append({"x": warn, "type": "mis", "y": roundi(float(rng.pick(opts))), "from_boss": level.boss != null})
	last_mis_x = X


## Ghi level ra JSON dễ đọc (mỗi vật một dòng; bỏ toạ độ px và trạng thái lúc chơi) để sửa tay.
static func to_json_text(level: JetLevel) -> String:
	var head := {"format": JetLevel.FORMAT, "level_id": level.level_id, "length_m": level.length_m,
			"scroll_base": level.scroll_base, "scroll_ramp": level.scroll_ramp, "zones": level.zones, "forms": level.forms,
			"bpm": level.bpm, "bgm": level.bgm, "boss": level.boss}
	var lines := PackedStringArray(["{"])
	for k in head:
		lines.append("  %s: %s," % [JSON.stringify(k), JSON.stringify(RunnerGenerator._ints(head[k]), "", false)])
	var pts := PackedStringArray()
	for p in level.path:
		pts.append("[%s, %d]" % [str(snappedf(p.x / JetLevel.PX_PER_M, 0.01)), roundi(p.y)])
	lines.append("  \"path\": [" + ", ".join(pts) + "],")
	lines.append("  \"events\": [")
	var evs := level.events
	for i in evs.size():
		var e := {}
		for k in evs[i]:
			if not str(k).begins_with("_") and k != "x":
				e[k] = evs[i][k]
		var ordered := {"d": e.get("d"), "type": e.get("type")}
		for k in e:
			if not k in ["d", "type"]:
				ordered[k] = e[k]
		lines.append("    " + JSON.stringify(RunnerGenerator._ints(ordered), "", false) + ("," if i < evs.size() - 1 else ""))
	lines.append("  ]")
	lines.append("}")
	return "\n".join(lines) + "\n"
