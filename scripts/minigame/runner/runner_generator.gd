class_name RunnerGenerator
extends RefCounted
## Bộ sinh level Chạy Nguyên Tố (docs/design/RUNNER_MODE.md mục 10): ghép các **khối** (một Cặn Thấp, một hố, hai cổng
## liền…) nối tiếp nhau theo seed. Tất định (xorshift32 tự viết): cùng seed + cùng cấu hình ⇒ cùng level, trên mọi máy.
## Dùng cho N-4, N-5 (ghi file bằng tools/runner/build_levels.gd) và các tuyến Vô tận (sinh lúc chơi).
##
## cfg: level_id, speed (px/s), length_sec, slots_used ([0, 1, 2]), gate_gap (giây tối thiểu giữa hai cổng),
##      overlap (cổng được trùng Cặn Thấp: đổi + nhảy cùng lúc), weights ({khối: trọng số}, thiếu = bảng mặc định),
##      theme, bgm, bpm, boss (null hoặc {"id", "throw_x"}).
## Khối: H Cặn Thấp 110 · H2 Cặn Thấp 140 · HH hai Cặn Thấp · P Vết Thực · L hàng hạt · F Cặn Bay · G cổng ·
##       GG hai cổng liền · GH cổng trùng Cặn Thấp (chỉ khi overlap).

const START_T := 2.6
const END_PAD := 2.0
## Nửa thời gian trên không (1300 / 4000): đặt hàng hạt vòng cung đúng đường nhảy.
const HALF_AIR := 0.325
const DEFAULT_WEIGHTS := {"H": 3, "H2": 1, "HH": 1, "P": 2, "L": 1, "F": 1, "G": 3, "GG": 1, "GH": 2}
## Bề rộng va chạm theo thời gian (giây × tốc độ = px), trong giới hạn mục 10.
const W_HURDLE := 0.20
const W_HURDLE_HIGH := 0.16
const W_PIT := 0.30

var _s := 2463534242


func _init(seed_: int) -> void:
	_s = seed_ & 0xFFFFFFFF
	if _s == 0:
		_s = 2463534242
	for i in 4:
		_next()


func _next() -> int:
	_s ^= (_s << 13) & 0xFFFFFFFF
	_s ^= _s >> 17
	_s ^= (_s << 5) & 0xFFFFFFFF
	_s &= 0xFFFFFFFF
	return _s


func randf_() -> float:
	return float(_next()) / 4294967296.0


func pick(arr: Array) -> Variant:
	return arr[mini(int(randf_() * arr.size()), arr.size() - 1)]


func _weighted(weights: Dictionary) -> String:
	var total := 0.0
	for k in weights:
		total += float(weights[k])
	var r := randf_() * total
	for k in weights:
		r -= float(weights[k])
		if r < 0.0:
			return str(k)
	return str(weights.keys()[0])


static func generate(seed_: int, cfg: Dictionary) -> Dictionary:
	return RunnerGenerator.new(seed_)._build(cfg)


static func _r(x: float) -> float:
	return snappedf(x, 0.001)


func _build(cfg: Dictionary) -> Dictionary:
	var speed := float(cfg.get("speed", 800.0))
	var length := float(cfg.get("length_sec", 90.0))
	var slots: Array = cfg.get("slots_used", [0, 1, 2])
	var gate_gap := float(cfg.get("gate_gap", 1.0))
	var overlap := bool(cfg.get("overlap", false))
	var weights: Dictionary = cfg.get("weights", DEFAULT_WEIGHTS).duplicate()
	if slots.size() < 2:
		for k in ["G", "GG", "GH"]:
			weights.erase(k)
	if not overlap:
		weights.erase("GH")
	var w110 := roundf(W_HURDLE * speed / 10.0) * 10.0
	var w140 := roundf(W_HURDLE_HIGH * speed / 10.0) * 10.0
	var wpit := roundf(W_PIT * speed / 10.0) * 10.0
	var ev: Array = []
	var t := START_T
	var end := length - END_PAD
	var cur := 0
	var last_gate := -100.0
	var gate_slots: Array = []
	var prev := ""
	var repeat := 0
	var n := 0
	while t < end:
		var kind := "H" if n == 0 else _weighted(weights)
		n += 1
		# Không lặp một khối quá 2 lần liền.
		if kind == prev:
			repeat += 1
			if repeat >= 2:
				kind = "L" if kind != "L" else "H"
				repeat = 0
		else:
			repeat = 0
		prev = kind
		if kind in ["G", "GG", "GH"] and t - last_gate < gate_gap:
			kind = "H"
		match kind:
			"H":
				ev.append({"t": _r(t), "type": "hurdle", "h": 110, "w": w110})
				ev.append({"t": _r(t - HALF_AIR), "type": "orbs", "pattern": "arc", "n": 5, "y": "air", "slot": null})
				t += 1.3
			"H2":
				ev.append({"t": _r(t), "type": "hurdle", "h": 140, "w": w140})
				t += 1.3
			"HH":
				ev.append({"t": _r(t), "type": "hurdle", "h": 110, "w": w110})
				ev.append({"t": _r(t + 1.0), "type": "hurdle", "h": 110, "w": w110})
				t += 2.3
			"P":
				ev.append({"t": _r(t), "type": "pit", "w": wpit})
				ev.append({"t": _r(t - HALF_AIR), "type": "orbs", "pattern": "arc", "n": 5, "y": "air", "slot": null})
				t += 1.4
			"L":
				ev.append({"t": _r(t - 0.3), "type": "orbs", "pattern": "line", "n": 6, "y": "ground", "slot": null})
				t += 1.1
			"F":
				ev.append({"t": _r(t), "type": "flyer"})
				ev.append({"t": _r(t - 0.24), "type": "orbs", "pattern": "line", "n": 5, "y": "ground", "slot": null})
				t += 1.3
			"G", "GG":
				var count := 2 if kind == "GG" and t + gate_gap < end else 1
				for k in count:
					var tg := t + k * gate_gap
					cur = _next_slot(cur, slots, gate_slots)
					gate_slots.append(cur)
					ev.append({"t": _r(tg), "type": "gate", "slot": cur})
					if count == 1 or k == count - 1:
						ev.append({"t": _r(tg + 0.3), "type": "orbs", "pattern": "line", "n": 4, "y": "ground", "slot": cur})
				last_gate = t + (count - 1) * gate_gap
				t += (count - 1) * gate_gap + 1.4
			"GH":
				cur = _next_slot(cur, slots, gate_slots)
				gate_slots.append(cur)
				ev.append({"t": _r(t), "type": "gate", "slot": cur})
				ev.append({"t": _r(t), "type": "hurdle", "h": 110, "w": w110})
				ev.append({"t": _r(t - HALF_AIR), "type": "orbs", "pattern": "arc", "n": 5, "y": "air", "slot": cur})
				last_gate = t
				t += 1.4
		# Nghỉ ngẫu nhiên, ngắn dần về cuối level.
		t += randf_() * 0.6 * (1.0 - 0.6 * t / length)
	ev.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	return {"format": RunnerLevel.FORMAT, "level_id": str(cfg.get("level_id", "")), "speed": speed,
			"length_sec": length, "slots_used": slots, "theme": str(cfg.get("theme", "")), "bpm": float(cfg.get("bpm", 128)),
			"bgm": str(cfg.get("bgm", "")), "boss": cfg.get("boss"), "events": ev}


## Ô cổng kế tiếp: thường đổi sang ô khác (để có Perfect), đôi khi giữ; không quá 3 cổng liền cùng ô.
func _next_slot(cur: int, slots: Array, history: Array) -> int:
	var same3 := history.size() >= 3 and history.slice(-3).all(func(s: Variant) -> bool: return int(s) == cur)
	if randf_() < 0.75 or same3:
		var others: Array = []
		for s in slots:
			if int(s) != cur:
				others.append(int(s))
		return int(pick(others))
	return cur


## Ghi level ra JSON dễ đọc (mỗi vật một dòng) để sửa tay.
static func to_json_text(d_: Dictionary) -> String:
	var d: Dictionary = _ints(d_)
	var lines := PackedStringArray(["{"])
	for k in ["format", "level_id", "speed", "length_sec", "slots_used", "theme", "bpm", "bgm", "boss"]:
		lines.append("  %s: %s," % [JSON.stringify(k), JSON.stringify(d.get(k))])
	lines.append("  \"events\": [")
	var evs: Array = d.get("events", [])
	for i in evs.size():
		lines.append("    " + JSON.stringify(evs[i], "", false) + ("," if i < evs.size() - 1 else ""))
	lines.append("  ]")
	lines.append("}")
	return "\n".join(lines) + "\n"


## Số thực tròn (1000.0, slot 2.0 đọc từ JSON) ghi thành số nguyên cho dễ đọc.
static func _ints(v: Variant) -> Variant:
	if v is float and is_equal_approx(v, roundf(v)) and absf(v) < 1e9:
		return int(roundf(v))
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = _ints(v[k])
		return o
	if v is Array:
		return (v as Array).map(func(x: Variant) -> Variant: return _ints(x))
	return v
