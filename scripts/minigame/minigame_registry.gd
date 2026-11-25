class_name MinigameRegistry
extends RefCounted
## Đọc data/events/material_events.json (docs/design/MATERIAL_EVENT.md mục 4): event → chế độ → ải. Khai báo khóa
## `stats` hợp lệ của từng chế độ (mục 13) và dựng ải cho chế độ dạng danh sách (provider).

const EVENTS_PATH := "res://data/events/material_events.json"

## Khóa `stats` hợp lệ theo chế độ (EventValidator cảnh báo khóa lạ trong điều kiện sao).
const STATS_KEYS := {
	"rhythm": ["accuracy", "max_combo", "perfect_ratio", "miss", "hp_left_ratio", "holds_broken"],
	"rhythm_endless": ["accuracy", "max_combo", "perfect_ratio", "miss", "hp_left_ratio", "holds_broken"],
	"runner": ["accuracy", "max_combo", "hits_taken", "collect_ratio", "perfect_swaps", "perfect_swap_ratio",
			"distance_ratio", "hp_left_ratio"],
	"jet": ["accuracy", "distance_m", "distance_ratio", "hits_taken", "hp_left_ratio", "orb_ratio", "cores_collected",
			"forms_used", "zones_passed"],
}

## Khoảng giá trị an toàn của tham số ải theo chế độ (đường dẫn trong `params`): EventValidator báo lỗi nếu vượt.
const PARAM_RANGES := {
	"rhythm": {"speed.note_speed": [300.0, 2000.0], "speed.song_speed": [0.5, 2.0], "spawn.density": [0.1, 1.0],
			"spawn.min_gap_sec": [0.0, 2.0]},
	"runner": {"speed.multiplier": [0.5, 2.0], "gen.speed": [300.0, 1500.0], "gen.length_sec": [30.0, 300.0],
			"gen.gate_gap": [0.5, 3.0]},
	"jet": {"endless.scroll_base": [300.0, 1000.0], "endless.scroll_ramp": [0.0, 1.0], "endless.zone_length_m": [100.0, 3000.0]},
}
## Giá trị cho phép của tham số dạng chữ.
const PARAM_CHOICES := {
	"rhythm": {"music.chart": ["easy", "normal", "hard", "boss"]},
}

var data: Dictionary = {}
var errors := PackedStringArray()


static func load_from(path := EVENTS_PATH) -> MinigameRegistry:
	var r := MinigameRegistry.new()
	if not FileAccess.file_exists(path):
		r.errors.append("không có file " + path)
		return r
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (d is Dictionary) or int(d.get("format", 0)) != 1 or not (d.get("events") is Array):
		r.errors.append("sai định dạng " + path)
		return r
	r.data = d
	return r


## Đọc tham số theo đường dẫn "a.b.c" (thiếu = `def`).
static func param(params: Dictionary, path: String, def: Variant = null) -> Variant:
	var cur: Variant = params
	for k in path.split("."):
		if not (cur is Dictionary) or not cur.has(k):
			return def
		cur = cur[k]
	return cur


static func param_ranges(mode_id: String) -> Dictionary:
	return PARAM_RANGES.get(mode_id.trim_suffix("_endless"), {})


static func param_choices(mode_id: String) -> Dictionary:
	return PARAM_CHOICES.get(mode_id.trim_suffix("_endless"), {})


static func stats_keys(mode_id: String) -> Array:
	var base := mode_id.trim_suffix("_endless")
	return STATS_KEYS.get(mode_id, STATS_KEYS.get(base, []))


func events() -> Array:
	return data.get("events", [])


func event(event_id: String) -> Dictionary:
	for e in events():
		if str(e.get("id", "")) == event_id:
			return e
	return {}


func modes(event_id: String) -> Array:
	return event(event_id).get("modes", [])


## Chế độ hiện thẻ ở màn chọn chế độ (bỏ chế độ con có `parent`, vd Vô tận nằm trong Nhịp điệu).
func hub_modes(event_id: String) -> Array:
	var out: Array = []
	for m in modes(event_id):
		if str(m.get("parent", "")) == "":
			out.append(m)
	return out


## Chế độ con của một chế độ (nút trong màn chọn ải, vd "Vô tận").
func child_modes(event_id: String, parent_id: String) -> Array:
	var out: Array = []
	for m in modes(event_id):
		if str(m.get("parent", "")) == parent_id:
			out.append(m)
	return out


static func is_soon(m: Dictionary) -> bool:
	return str(m.get("status", "")) == "soon"


func mode(event_id: String, mode_id: String) -> Dictionary:
	for m in modes(event_id):
		if str(m.get("id", "")) == mode_id:
			return m
	return {}


func stage(event_id: String, mode_id: String, stage_id: String) -> Dictionary:
	for s in mode(event_id, mode_id).get("stages", []):
		if str(s.get("id", "")) == stage_id:
			return s
	return {}


## Khóa và cấu hình hạn mức của một chế độ (theo `share_with` nếu có).
func limit_for(event_id: String, mode_id: String) -> Dictionary:
	var m := mode(event_id, mode_id)
	var lim: Dictionary = m.get("limit", {})
	var owner := mode_id
	if lim.has("share_with"):
		owner = str(lim["share_with"])
		lim = mode(event_id, owner).get("limit", {})
	return {"key": "%s:%s" % [event_id, owner], "limit": lim}


## Ải Vô tận của chế độ dạng danh sách Nhịp điệu: một bài + một độ khó.
func endless_stage(event_id: String, mode_id: String, song_id: String, difficulty: String) -> Dictionary:
	var e: Dictionary = mode(event_id, mode_id).get("endless", {})
	var d: Dictionary = e.get("by_difficulty", {}).get(difficulty, {})
	var params: Dictionary = d.get("params", {}).duplicate(true)
	params["music"] = {"song": song_id, "chart": difficulty}
	return {
		"id": endless_id(song_id, difficulty),
		"stars": e.get("stars", ["clear", "rank>=A", "rank>=S"]),
		"rewards": d.get("rewards", {}).duplicate(true),
		"params": params,
	}


## Tuyến Vô tận của Chạy Nguyên Tố (mode.endless.routes: {id, title_key, seed}).
func routes(event_id: String, mode_id: String) -> Array:
	return mode(event_id, mode_id).get("endless", {}).get("routes", [])


## Ải Vô tận dạng tuyến: một tuyến + một độ khó. Level sinh lúc chơi từ params.gen + params.route.seed (seed tuyến × 10
## + chỉ số độ khó: mỗi độ khó một level riêng, cố định).
func route_stage(event_id: String, mode_id: String, route_id: String, difficulty: String) -> Dictionary:
	var e: Dictionary = mode(event_id, mode_id).get("endless", {})
	var d: Dictionary = e.get("by_difficulty", {}).get(difficulty, {})
	var params: Dictionary = d.get("params", {}).duplicate(true)
	var seed := 1
	for r in routes(event_id, mode_id):
		if str(r.get("id", "")) == route_id:
			seed = int(r.get("seed", 1))
	params["route"] = {"id": route_id, "seed": seed * 10 + maxi(e.get("difficulties", []).find(difficulty), 0)}
	return {
		"id": endless_id(route_id, difficulty),
		"party_min": int(e.get("party_min", 1)),
		"stars": e.get("stars", ["clear", "rank>=A", "rank>=S"]),
		"rewards": d.get("rewards", {}).duplicate(true),
		"params": params,
	}


## Mục Vô tận của Bay Nguyên Tố (mode.endless.entries: {id, title_key, sub_key, zone, practice}).
func endless_entries(event_id: String, mode_id: String) -> Array:
	return mode(event_id, mode_id).get("endless", {}).get("entries", [])


## Ải Vô tận dạng mục (Bay): "all" = đổi vùng, "zone_<n>" = luyện một vùng (practice: không tốn lượt, không thưởng).
## Level sinh lúc chơi từ params.endless + params.seed (theo ngày: cùng ngày cùng đường bay).
func entry_stage(event_id: String, mode_id: String, entry_id: String, seed: int) -> Dictionary:
	var e: Dictionary = mode(event_id, mode_id).get("endless", {})
	var entry := {}
	for it in endless_entries(event_id, mode_id):
		if str(it.get("id", "")) == entry_id:
			entry = it
	var params: Dictionary = e.get("params", {}).duplicate(true)
	var en: Dictionary = params.get("endless", {})
	en["zone"] = str(entry.get("zone", ""))
	params["endless"] = en
	params["seed"] = seed
	var practice := bool(entry.get("practice", false))
	return {
		"id": "endless:" + entry_id,
		"practice": practice,
		"stars": e.get("stars", ["clear", "rank>=A", "rank>=S"]),
		"rewards": {} if practice else e.get("rewards", {}).duplicate(true),
		"params": params,
	}


static func endless_id(song_id: String, difficulty: String) -> String:
	return "endless:%s:%s" % [song_id, difficulty]
