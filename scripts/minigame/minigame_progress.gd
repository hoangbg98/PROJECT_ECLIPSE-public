class_name MinigameProgress
extends RefCounted
## Tiến trình Event nguyên liệu trong save (`data["minigames"]`, docs/design/MATERIAL_EVENT.md mục 9): bản ghi từng ải,
## 3 sao, hạn mức lượt có thưởng, bài yêu thích, cờ đã xem hướng dẫn. Chỉ lớp này ghi `data["minigames"]`.
##
## Thời gian lấy qua `clock` (Callable trả unix giây) và `tz_offset` để test.

const STAR_COUNT := 3

var profile: PlayerProfile
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())
var tz_offset := LimitTracker.system_tz_offset()


func _init(profile_: PlayerProfile) -> void:
	profile = profile_


static func empty_root() -> Dictionary:
	return {"records": {}, "limits": {}, "favorites": {}, "tutorials": {}}


func root() -> Dictionary:
	if not (profile.data.get("minigames") is Dictionary):
		profile.data["minigames"] = empty_root()
	var r: Dictionary = profile.data["minigames"]
	for k in ["records", "limits", "favorites", "tutorials"]:
		if not (r.get(k) is Dictionary):
			r[k] = {}
	return r


func _sub(group: String, key: String) -> Dictionary:
	var g: Dictionary = root()[group]
	if not (g.get(key) is Dictionary):
		g[key] = {}
	return g[key]


static func empty_record() -> Dictionary:
	return {"cleared": false, "stars": [false, false, false], "best_score": 0, "best_rank": "", "best_combo": 0,
			"best_accuracy": 0.0, "plays": 0, "first_clear_claimed": false}


## Bản ghi một ải (rỗng nếu chưa chơi).
func record(mode_id: String, stage_id: String) -> Dictionary:
	var rec: Variant = root()["records"].get(mode_id, {}).get(stage_id) if root()["records"].get(mode_id) is Dictionary else null
	return rec if rec is Dictionary else {}


func is_cleared(mode_id: String, stage_id: String) -> bool:
	return bool(record(mode_id, stage_id).get("cleared", false))


func stars(mode_id: String, stage_id: String) -> Array:
	var s: Variant = record(mode_id, stage_id).get("stars")
	return s if s is Array and s.size() == STAR_COUNT else [false, false, false]


func star_count(mode_id: String, stage_id: String) -> int:
	var n := 0
	for b in stars(mode_id, stage_id):
		if b:
			n += 1
	return n


## Ải mở khi mọi ải trong `requires` (cùng chế độ) đã qua.
func stage_unlocked(mode_id: String, stage: Dictionary) -> bool:
	for req in stage.get("requires", []):
		if not is_cleared(mode_id, str(req)):
			return false
	return true


## Chế độ mở theo `unlock.requires_stage_cleared` ("<mode>/<stage>").
func mode_unlocked(mode: Dictionary) -> bool:
	var need := str(mode.get("unlock", {}).get("requires_stage_cleared", ""))
	if need == "":
		return true
	var parts := need.split("/")
	return parts.size() == 2 and is_cleared(parts[0], parts[1])


# ---------- Hạn mức ----------

func remaining(limit_key: String, limit: Dictionary) -> int:
	return LimitTracker.remaining(_sub("limits", limit_key), limit, int(clock.call()), tz_offset)


func next_reset_unix(limit: Dictionary) -> int:
	return LimitTracker.next_reset_unix(limit, int(clock.call()), tz_offset)


## Chơi thật bắt đầu: dùng một lượt nếu còn. Trả về true nếu lượt này có thưởng.
func begin_play(limit_key: String, limit: Dictionary) -> bool:
	return LimitTracker.consume(_sub("limits", limit_key), limit, int(clock.call()), tz_offset)


# ---------- Kết quả ----------

## Ghi kết quả một lượt; nếu `rewarded` và qua ải thì chấm sao, phát thưởng (lần đầu, theo hạng, sao mới).
## Trả về {cleared, rewarded, new_best, first_clear, stars, new_stars: [số sao 1..3], rewards (đã nhận thật)}.
func submit(mode_id: String, stage: Dictionary, result: MinigameResult, rewarded: bool) -> Dictionary:
	var recs := _sub("records", mode_id)
	var sid := str(stage.get("id", ""))
	var rec: Dictionary = recs.get(sid, {}) if recs.get(sid) is Dictionary else {}
	var base := empty_record()
	for k in base:
		if not rec.has(k):
			rec[k] = base[k]
	rec["plays"] = int(rec["plays"]) + 1
	var out := {"cleared": result.cleared, "rewarded": rewarded and result.cleared, "new_best": false,
			"first_clear": false, "stars": rec["stars"], "new_stars": [], "rewards": {}}
	if result.cleared:
		rec["cleared"] = true
		if result.score > int(rec["best_score"]):
			rec["best_score"] = result.score
			out["new_best"] = true
		if MinigameResult.rank_value(result.rank) > MinigameResult.rank_value(str(rec["best_rank"])):
			rec["best_rank"] = result.rank
		rec["best_combo"] = maxi(int(rec["best_combo"]), int(result.stats.get("max_combo", 0)))
		rec["best_accuracy"] = maxf(float(rec["best_accuracy"]), float(result.stats.get("accuracy", 0.0)))
		if rewarded:
			var got := StarEvaluator.evaluate(stage.get("stars", []), result)
			var st: Array = rec["stars"].duplicate()
			while st.size() < STAR_COUNT:
				st.append(false)
			var new_stars: Array = []
			for i in mini(got.size(), STAR_COUNT):
				if got[i] and not bool(st[i]):
					st[i] = true
					new_stars.append(i + 1)
			rec["stars"] = st
			var first := not bool(rec["first_clear_claimed"])
			rec["first_clear_claimed"] = true
			out["first_clear"] = first
			out["stars"] = st
			out["new_stars"] = new_stars
			var reward := RewardService.compute(stage.get("rewards", {}), result.rank, first, new_stars)
			out["rewards"] = profile.grant(reward)
	recs[sid] = rec
	return out


# ---------- Hướng dẫn, yêu thích ----------

func tutorial_seen(mode_id: String, step_id: String) -> bool:
	return bool(_sub("tutorials", mode_id).get(step_id, false))


func mark_tutorial(mode_id: String, step_id: String) -> void:
	_sub("tutorials", mode_id)[step_id] = true


func favorites(mode_id: String) -> Array:
	var f: Variant = root()["favorites"].get(mode_id)
	if not (f is Array):
		f = []
		root()["favorites"][mode_id] = f
	return f


func is_favorite(mode_id: String, id: String) -> bool:
	return id in favorites(mode_id)


func toggle_favorite(mode_id: String, id: String) -> bool:
	var f := favorites(mode_id)
	if id in f:
		f.erase(id)
		return false
	f.append(id)
	return true


# ---------- Công cụ thử nghiệm (DebugGift, chỉ bản debug) ----------

## Đánh dấu ải đã qua để mở ải sau / chế độ sau. Không cho sao, không nhận thưởng lần đầu (chơi thật vẫn nhận đủ).
func debug_mark_cleared(mode_id: String, stage_id: String) -> void:
	var recs := _sub("records", mode_id)
	var rec: Dictionary = recs.get(stage_id, {}) if recs.get(stage_id) is Dictionary else {}
	var base := empty_record()
	for k in base:
		if not rec.has(k):
			rec[k] = base[k]
	rec["cleared"] = true
	recs[stage_id] = rec


## Đặt lại lượt có thưởng của mọi chế độ.
func debug_reset_limits() -> void:
	root()["limits"] = {}


# ---------- Di trú save ----------

## Chuyển `data["rhythm"]` (M10) sang `data["minigames"]` một lần. Chạy lại an toàn: đã có bản ghi minigames từ save
## gốc thì không làm gì. Giữ nguyên `data["rhythm"]` (dọn ở bản phát hành sau).
static func migrate_rhythm(out: Dictionary, src: Variant) -> void:
	if not (src is Dictionary) or src.get("minigames") is Dictionary or not (src.get("rhythm") is Dictionary):
		return
	var rh: Dictionary = src["rhythm"]
	var mg: Dictionary = out["minigames"]
	var recs: Dictionary = rh.get("records", {}) if rh.get("records") is Dictionary else {}
	for key in recs:
		var old: Variant = recs[key]
		if not (old is Dictionary):
			continue
		var mode_id := "rhythm_endless" if str(key).begins_with("endless:") else "rhythm"
		var cleared := bool(old.get("cleared", false))
		var rec := empty_record()
		rec["cleared"] = cleared
		rec["stars"] = [cleared, false, false]
		rec["best_score"] = int(old.get("best_score", 0))
		rec["best_rank"] = str(old.get("best_rank", ""))
		rec["best_combo"] = int(old.get("best_combo", 0))
		rec["best_accuracy"] = float(old.get("best_accuracy", 0.0))
		rec["plays"] = int(old.get("plays", 0))
		rec["first_clear_claimed"] = cleared
		if not (mg["records"].get(mode_id) is Dictionary):
			mg["records"][mode_id] = {}
		mg["records"][mode_id][str(key)] = rec
		# Đã qua ải có hướng dẫn / giới thiệu thì không hiện lại.
		if mode_id == "rhythm" and cleared:
			if not (mg["tutorials"].get("rhythm") is Dictionary):
				mg["tutorials"]["rhythm"] = {}
			mg["tutorials"]["rhythm"][str(key)] = true
	if rh.get("favorites") is Array and not rh["favorites"].is_empty():
		mg["favorites"]["rhythm_endless"] = rh["favorites"].duplicate()
