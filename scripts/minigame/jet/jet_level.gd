class_name JetLevel
extends RefCounted
## Một level Bay Nguyên Tố (docs/design/JET_MODE.md mục 10): data/jet/levels/<level_id>.json, hoặc sinh dần lúc chơi
## (Vô tận: `generator` != null, `length_m` = 0).
##   {"format": 1, "level_id", "length_m", "scroll_base", "scroll_ramp", "zones": [{"from_m", "id"}], "forms": [...],
##    "bpm", "bgm", "boss", "path": [[m, y], ...], "events": [{"d": mét, "type", ...}]}
## Vật: beam {y, len (nửa dài), ang (độ)} · mis {y (độ cao lúc lao tới người bay); d = lúc hiện cảnh báo} ·
##      swp {y (tâm), amp, wl (bước sóng px), ph (pha)} · gate {y (tâm khe)} · orbs {y, n, wave} · core {y} · box {y, form}.
## `path`: đường giữa hành lang an toàn mà bộ sinh chừa ra (bot và validator dùng; người chơi không thấy).

const FORMAT := 1
const DIR := "res://data/jet/levels/"
const ZONES_PATH := "res://data/jet/zones.json"
const TYPES: Array[String] = ["beam", "mis", "swp", "gate", "orbs", "core", "box"]
const FORMS: Array[String] = ["dragon", "robo"]
## Không vật nào tới người bay trước giây này.
const FIRST_EVENT_SEC := 2.0
const PX_PER_M := 60.0

var level_id := ""
## 0 = Vô tận (không đích).
var length_m := 800.0
var scroll_base := 520.0
var scroll_ramp := 0.15
var scroll_cap := 1000.0
var zones: Array = []
## Vô tận: vòng vùng, mỗi vùng `zone_length_m` mét.
var zone_cycle: Array = []
var zone_length_m := 600.0
var forms: Array = []
var bpm := 128.0
var bgm := ""
var boss: Variant = null
## Vật (dict, có thêm "x" = vị trí thế giới px), sắp theo x. JetSim ghi trạng thái vào chính các dict này.
var events: Array[Dictionary] = []
## Đường giữa hành lang: Vector2(x thế giới px, y), tăng dần theo x.
var path := PackedVector2Array()
var errors := PackedStringArray()
var generator: JetGenerator

static var _zone_defs: Dictionary = {}


static func zone_defs() -> Dictionary:
	if _zone_defs.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ZONES_PATH))
		_zone_defs = d if d is Dictionary else {"zones": {}, "endless_cycle": []}
	return _zone_defs


static func zone_def(id: String) -> Dictionary:
	return zone_defs().get("zones", {}).get(id, {})


static func load_id(id: String) -> JetLevel:
	var path_ := DIR + id + ".json"
	if not FileAccess.file_exists(path_):
		var bad := JetLevel.new()
		bad.errors.append("không có level " + path_)
		return bad
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_))
	if not (d is Dictionary):
		var bad2 := JetLevel.new()
		bad2.errors.append("không đọc được JSON " + path_)
		return bad2
	return from_dict(d)


static func from_dict(d: Dictionary) -> JetLevel:
	var lv := JetLevel.new()
	lv._read(d)
	return lv


## Level Vô tận: sinh dần theo seed; `zone_id` rỗng = vòng vùng, có = luyện một vùng.
static func endless(seed_: int, cfg: Dictionary, zone_id := "") -> JetLevel:
	var lv := JetLevel.new()
	lv.level_id = str(cfg.get("level_id", "endless"))
	lv.length_m = 0.0
	lv.scroll_base = float(cfg.get("scroll_base", 520.0))
	lv.scroll_ramp = float(cfg.get("scroll_ramp", 0.15))
	lv.zone_length_m = float(cfg.get("zone_length_m", 600.0))
	lv.zone_cycle = [zone_id] if zone_id != "" else zone_defs().get("endless_cycle", ["ash"]).duplicate()
	lv.forms = cfg.get("forms", FORMS.duplicate())
	lv.generator = JetGenerator.new(seed_, cfg)
	lv.ensure(0.0)
	return lv


func is_valid() -> bool:
	return errors.is_empty()


func is_endless() -> bool:
	return length_m <= 0.0


func length_px() -> float:
	return length_m * PX_PER_M


## Sinh thêm (Vô tận) tới mét `m`.
func ensure(m: float) -> void:
	if generator:
		generator.fill(self, m)


func scroll_at_px(x: float) -> float:
	return minf(scroll_base + scroll_ramp * x / PX_PER_M, scroll_cap)


func zone_at_px(x: float) -> String:
	var m := x / PX_PER_M
	if not zone_cycle.is_empty():
		return str(zone_cycle[int(floorf(m / zone_length_m)) % zone_cycle.size()])
	var id := "ash"
	for z in zones:
		if m >= float(z.get("from_m", 0.0)):
			id = str(z.get("id", id))
	return id


## Mốc bắt đầu (px) của vùng đang chứa x.
func zone_start_px(x: float) -> float:
	var m := x / PX_PER_M
	if not zone_cycle.is_empty():
		return floorf(m / zone_length_m) * zone_length_m * PX_PER_M
	var s := 0.0
	for z in zones:
		if m >= float(z.get("from_m", 0.0)):
			s = float(z.get("from_m", 0.0)) * PX_PER_M
	return s


## Gió tại vị trí x (px/s², dương = đẩy xuống). Chu kỳ quy ra quãng đường theo tốc độ cuộn ở đầu vùng, nên bộ sinh
## biết trước chỗ nào gió thổi. Lẻ: xuống, chẵn: lên.
func wind_at_px(x: float, rules: JetRules) -> float:
	if not bool(zone_def(zone_at_px(x)).get("wind", false)):
		return 0.0
	var s0 := zone_start_px(x)
	var cycle_px := rules.wind_cycle * scroll_at_px(s0)
	var k := floori((x - s0) / cycle_px)
	var phase := fmod(x - s0, cycle_px) / cycle_px * rules.wind_cycle
	if phase < rules.wind_on or phase >= rules.wind_off:
		return 0.0
	return rules.wind_accel if k % 2 == 1 else -rules.wind_accel


## Gió sắp thổi trong `lead_px` tới (để vẽ mũi tên báo trước): 0 nếu không.
func wind_soon_px(x: float, lead_px: float, rules: JetRules) -> float:
	var w := wind_at_px(x, rules)
	return w if w != 0.0 else wind_at_px(x + lead_px, rules)


func path_y(x: float) -> float:
	if path.is_empty():
		return 600.0
	if x <= path[0].x:
		return path[0].y
	var lo := 0
	var hi := path.size() - 1
	if x >= path[hi].x:
		return path[hi].y
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if path[mid].x <= x:
			lo = mid
		else:
			hi = mid
	var a := path[lo]
	var b := path[hi]
	return lerpf(a.y, b.y, (x - a.x) / maxf(b.x - a.x, 0.001))


## Số Hạt Tinh (hàng hạt) có x ≤ `x`.
func orbs_before(x: float, rules: JetRules) -> int:
	var n := 0
	for e in events:
		if float(e["x"]) > x:
			break
		if e["type"] == "orbs":
			for k in int(e.get("n", 6)):
				if float(e["x"]) + k * rules.orb_spacing <= x:
					n += 1
	return n


func count(type: String) -> int:
	var n := 0
	for e in events:
		if e["type"] == type:
			n += 1
	return n


func _read(d: Dictionary) -> void:
	if int(d.get("format", 0)) != FORMAT:
		errors.append("format phải là %d" % FORMAT)
		return
	level_id = str(d.get("level_id", ""))
	length_m = float(d.get("length_m", 800.0))
	scroll_base = float(d.get("scroll_base", 520.0))
	scroll_ramp = float(d.get("scroll_ramp", 0.15))
	zones = d.get("zones", [{"from_m": 0, "id": "ash"}])
	forms = d.get("forms", [])
	bpm = float(d.get("bpm", 128.0))
	bgm = str(d.get("bgm", ""))
	boss = d.get("boss")
	if length_m <= 0.0 or scroll_base <= 0.0:
		errors.append("length_m và scroll_base phải > 0")
	for z in zones:
		if not (z is Dictionary) or zone_def(str(z.get("id", ""))).is_empty():
			errors.append("vùng lạ: %s" % str(z))
	for f in forms:
		if not str(f) in FORMS:
			errors.append("hình lạ '%s'" % str(f))
	for p in d.get("path", []):
		if p is Array and p.size() == 2:
			path.append(Vector2(float(p[0]) * PX_PER_M, float(p[1])))
	var first_x := FIRST_EVENT_SEC * scroll_base
	for e in d.get("events", []):
		if not (e is Dictionary):
			continue
		var type := str(e.get("type", ""))
		if not type in TYPES:
			errors.append("loại vật lạ '%s'" % type)
			continue
		var ev: Dictionary = (e as Dictionary).duplicate(true)
		ev["x"] = float(e.get("d", -1.0)) * PX_PER_M
		if float(ev["x"]) < first_x:
			errors.append("vật '%s' ở %.1f m: phải sau %.1f s (%.0f m)" % [type, float(e.get("d", -1)), FIRST_EVENT_SEC, first_x / PX_PER_M])
			continue
		if float(e.get("d", 0.0)) > length_m:
			errors.append("vật '%s' ở %.1f m: sau vạch đích" % [type, float(e.get("d", 0))])
			continue
		var y := float(e.get("y", -1.0))
		if y < 100.0 or y > 910.0:
			errors.append("vật '%s' ở %.1f m: y = %.0f ngoài sân" % [type, float(e.get("d", 0)), y])
			continue
		if type == "box" and not str(e.get("form", "")) in FORMS:
			errors.append("hộp ở %.1f m: form phải là dragon / robo" % float(e.get("d", 0)))
			continue
		events.append(ev)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["x"]) < float(b["x"]))
