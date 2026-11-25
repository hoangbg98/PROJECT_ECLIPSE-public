class_name RunnerLevel
extends RefCounted
## Một level Chạy Nguyên Tố (docs/design/RUNNER_MODE.md mục 9.2): data/runner/levels/<level_id>.json.
##   {"format": 1, "level_id", "speed", "length_sec", "slots_used": [0, 1], "theme", "bpm", "bgm", "boss",
##    "events": [{"t": giây vật chạm người chạy, "type": "hurdle" | "pit" | "flyer" | "gate" | "orbs", ...}]}
## hurdle: h (110 | 140), w (px). pit: w (px). flyer: (đáy 250, cao 90). gate: slot (0..2).
## orbs: pattern "line" | "arc", n, y "ground" | "air", slot (null = trung tính).

const FORMAT := 1
const DIR := "res://data/runner/levels/"
const TYPES: Array[String] = ["hurdle", "pit", "flyer", "gate", "orbs"]
## Không vật nào trước giây này (người chơi kịp nhìn sau đếm ngược).
const FIRST_EVENT_SEC := 2.0
## Hạt Tinh: khoảng cách thời gian giữa hai hạt liền nhau trên hàng thẳng; độ cao TÂM hạt (từ mặt đường) của hàng đất /
## hàng trên không. Tâm người chạy ở độ cao chân + 115 (nửa hurtbox).
const ORB_LINE_STEP := 0.12
const ORB_GROUND_H := 100.0
const ORB_AIR_H := 300.0
## Hàng hạt "arc" vẽ theo đường nhảy chuẩn (RunnerRules mặc định) của tâm người chạy.
const ARC_JUMP_V := 1300.0
const ARC_GRAVITY := 4000.0
const ARC_CENTER := 115.0

var level_id := ""
var speed := 600.0
var length_sec := 60.0
var slots_used: Array = []
var theme := ""
var bpm := 120.0
var bgm := ""
var boss: Variant = null
## Vật cản + cổng (không gồm hạt), sắp theo t: {t, type, h, w, slot}.
var obstacles: Array[Dictionary] = []
## Hạt Tinh đã trải ra: {t, h, slot (-1 = trung tính)}.
var orbs: Array[Dictionary] = []
var errors := PackedStringArray()


static func load_id(level_id_: String) -> RunnerLevel:
	var path := DIR + level_id_ + ".json"
	if not FileAccess.file_exists(path):
		var bad := RunnerLevel.new()
		bad.errors.append("không có level " + path)
		return bad
	return from_text(FileAccess.get_file_as_string(path))


static func from_text(text: String) -> RunnerLevel:
	var d: Variant = JSON.parse_string(text)
	var lv := RunnerLevel.new()
	if not (d is Dictionary):
		lv.errors.append("không đọc được JSON")
		return lv
	lv._read(d)
	return lv


static func from_dict(d: Dictionary) -> RunnerLevel:
	var lv := RunnerLevel.new()
	lv._read(d)
	return lv


func is_valid() -> bool:
	return errors.is_empty()


func count(type: String) -> int:
	var n := 0
	for o in obstacles:
		if o["type"] == type:
			n += 1
	return n


func _read(d: Dictionary) -> void:
	if int(d.get("format", 0)) != FORMAT:
		errors.append("format phải là %d" % FORMAT)
		return
	level_id = str(d.get("level_id", ""))
	speed = float(d.get("speed", 600.0))
	length_sec = float(d.get("length_sec", 60.0))
	slots_used = d.get("slots_used", [])
	theme = str(d.get("theme", ""))
	bpm = float(d.get("bpm", 120.0))
	bgm = str(d.get("bgm", ""))
	boss = d.get("boss")
	if speed <= 0.0 or length_sec <= 0.0:
		errors.append("speed và length_sec phải > 0")
	for s in slots_used:
		if int(s) < 0 or int(s) > 2:
			errors.append("slots_used chỉ gồm 0, 1, 2")
	for e in d.get("events", []):
		if not (e is Dictionary):
			continue
		var type := str(e.get("type", ""))
		var t := float(e.get("t", -1.0))
		if not type in TYPES:
			errors.append("loại vật lạ '%s'" % type)
			continue
		if t < FIRST_EVENT_SEC:
			errors.append("vật '%s' ở %.2f s: không được trước %.1f s" % [type, t, FIRST_EVENT_SEC])
			continue
		if t > length_sec:
			errors.append("vật '%s' ở %.2f s: sau vạch đích" % [type, t])
			continue
		match type:
			"orbs":
				_expand_orbs(e, t)
			"gate":
				var slot := int(e.get("slot", 0))
				if not slots_used.has(float(slot)) and not slots_used.has(slot):
					errors.append("cổng ở %.2f s dùng ô %d ngoài slots_used" % [t, slot])
				obstacles.append({"t": t, "type": type, "h": 0.0, "w": 40.0, "slot": slot})
			"hurdle":
				obstacles.append({"t": t, "type": type, "h": float(e.get("h", 110.0)), "w": float(e.get("w", 120.0)), "slot": -1})
			"pit":
				obstacles.append({"t": t, "type": type, "h": 0.0, "w": float(e.get("w", 180.0)), "slot": -1})
			"flyer":
				obstacles.append({"t": t, "type": type, "h": 0.0, "w": float(e.get("w", 120.0)), "slot": -1})
	obstacles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	orbs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))


## Hạt "arc": cú nhảy bắt đầu ở t sẽ đi xuyên qua cả hàng (dạy người chơi nhảy để nhặt).
func _expand_orbs(e: Dictionary, t: float) -> void:
	var n := maxi(int(e.get("n", 5)), 1)
	var slot_v: Variant = e.get("slot")
	var slot := -1 if slot_v == null else int(slot_v)
	if str(e.get("pattern", "line")) == "arc":
		var air := 2.0 * ARC_JUMP_V / ARC_GRAVITY
		for i in n:
			var tau := air * (float(i) + 0.5) / float(n)
			var hh := ARC_JUMP_V * tau - 0.5 * ARC_GRAVITY * tau * tau + ARC_CENTER
			orbs.append({"t": t + tau, "h": hh, "slot": slot})
	else:
		var hh := ORB_AIR_H if str(e.get("y", "ground")) == "air" else ORB_GROUND_H
		for i in n:
			orbs.append({"t": t + i * ORB_LINE_STEP, "h": hh, "slot": slot})
