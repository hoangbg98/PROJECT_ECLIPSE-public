class_name JetSim
extends RefCounted
## Logic Bay Nguyên Tố (docs/design/JET_MODE.md mục 1–7), không đồ họa, bước cố định: bot / validator / màn chơi cho
## cùng kết quả. Màn chơi (`JetStage`) chỉ gửi "đang giữ" và vẽ theo state.
##
##   var sim := JetSim.new(rules, level)
##   sim.step(1.0 / 120.0, holding)
##   for ev in sim.take_events(): ...
##
## Toạ độ: vật ở x thế giới X (px); người bay ở x thế giới = `dist`, trên màn ở `player_x`. y hướng xuống.

var rules: JetRules
var level: JetLevel

var t := 0.0
## Quãng đã bay (px thế giới) = x thế giới của người bay.
var dist := 0.0
var y := 0.0
var vy := 0.0
var on_ground := true
var energy := 100.0
var lives := 3
var invuln := 0.0
var hurt_timer := 0.0
## "" | "dragon" | "robo"
var form := ""
var form_time := 0.0
var holding := false
var zone := ""
var zone_t := 0.0
var finished := false
var cleared := false
var fail_reason := ""

var orbs_taken := 0
var bonus_orbs := 0
var cores := 0
var forms_used := 0
var hits_taken := 0
var zones_passed := 0
var crushed := 0

## Cặn Phóng đang cảnh báo / bay: {ev, phase "warn" | "fly", t0, sx (x trên màn)}.
var missiles: Array[Dictionary] = []

var _first := 0
var _prev_hold := false
var _events: Array[Dictionary] = []


func _init(rules_: JetRules, level_: JetLevel) -> void:
	rules = rules_
	level = level_
	lives = rules.lives
	energy = rules.energy_max
	y = rules.floor_y - rules.body_radius("")
	zone = level.zone_at_px(0.0)


func meters() -> float:
	return dist / JetLevel.PX_PER_M


func scroll() -> float:
	return level.scroll_at_px(dist)


func progress_ratio() -> float:
	if level.is_endless():
		return clampf(meters() / rules.endless_clear_m, 0.0, 1.0)
	return clampf(meters() / level.length_m, 0.0, 1.0)


func radius() -> float:
	return rules.body_radius(form)


func hit_r() -> float:
	return rules.hit_radius(form)


func screen_x(world_x: float) -> float:
	return rules.player_x + world_x - dist


# ---------------------------------------------------------------- hình học (tĩnh, validator dùng chung)

static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


static func beam_ends(e: Dictionary) -> PackedVector2Array:
	var L := float(e.get("len", 150.0))
	var a := deg_to_rad(float(e.get("ang", 0.0)))
	var c := Vector2(float(e["x"]), float(e["y"]))
	var d := Vector2(cos(a), -sin(a)) * L
	return PackedVector2Array([c - d, c + d])


## Tâm thanh Tia Quét khi người bay ở x thế giới `at_dist` (dao động theo quãng đường).
static func sweep_y(e: Dictionary, at_dist: float) -> float:
	return float(e["y"]) + float(e.get("amp", 200.0)) * sin(float(e.get("ph", 0.0)) + TAU * at_dist / float(e.get("wl", 1400.0)))


## Khoảng cách từ điểm p (toạ độ thế giới, người bay ở x = at_dist) tới vật cản tĩnh (đã trừ độ dày); INF nếu không áp dụng.
static func obstacle_clearance(e: Dictionary, p: Vector2, at_dist: float, r: JetRules) -> float:
	match str(e["type"]):
		"beam":
			var ends := beam_ends(e)
			return seg_dist(p, ends[0], ends[1]) - r.obstacle_thickness
		"swp":
			var sy := sweep_y(e, at_dist)
			var X := float(e["x"])
			return seg_dist(p, Vector2(X, sy - r.sweep_half), Vector2(X, sy + r.sweep_half)) - r.obstacle_thickness
		"gate":
			var X2 := float(e["x"])
			var g := float(e["y"])
			var hw := r.gate_width * 0.5
			var top := Rect2(X2 - hw, r.ceiling_y - 400.0, r.gate_width, g - r.gate_gap * 0.5 - (r.ceiling_y - 400.0))
			var bot := Rect2(X2 - hw, g + r.gate_gap * 0.5, r.gate_width, r.floor_y + 400.0 - (g + r.gate_gap * 0.5))
			return minf(_rect_dist(p, top), _rect_dist(p, bot))
	return INF


static func _rect_dist(p: Vector2, rc: Rect2) -> float:
	var q := Vector2(clampf(p.x, rc.position.x, rc.end.x), clampf(p.y, rc.position.y, rc.end.y))
	return p.distance_to(q)


static func orb_pos(e: Dictionary, k: int, r: JetRules) -> Vector2:
	var oy := float(e["y"])
	if bool(e.get("wave", false)):
		oy += r.orb_wave * sin(k * PI / 2.5)
	return Vector2(float(e["x"]) + k * r.orb_spacing, oy)


# ---------------------------------------------------------------- bước

func step(dt: float, hold: bool) -> void:
	if finished:
		return
	t += dt
	var sc := scroll()
	dist += sc * dt
	if level.is_endless():
		level.ensure(meters() + 80.0)
	invuln = maxf(invuln - dt, 0.0)
	hurt_timer = maxf(hurt_timer - dt, 0.0)
	holding = hold
	_zone(dt)
	_form_timer(dt)
	_physics(dt, hold)
	_prev_hold = hold
	_objects(dt, sc)
	_missiles(dt, sc)
	if lives <= 0:
		_finish(level.is_endless() and meters() >= rules.endless_clear_m, "hp_zero")
	elif not level.is_endless() and meters() >= level.length_m:
		_finish(true, "")


func _zone(dt: float) -> void:
	zone_t += dt
	var z := level.zone_at_px(dist)
	if z != zone:
		zone = z
		zone_t = 0.0
		zones_passed += 1
		_emit("zone", {"zone": z})


func _form_timer(dt: float) -> void:
	if form == "":
		return
	form_time -= dt
	if form_time <= 0.0:
		_emit("form_end", {"form": form})
		form = ""
		vy = clampf(vy, -rules.vy_up_max, rules.vy_down_max)


func _physics(dt: float, hold: bool) -> void:
	var wind := 0.0 if form == "robo" else level.wind_at_px(dist, rules)
	var a := 0.0
	match form:
		"dragon":
			a = (-rules.dragon_up if hold else rules.dragon_down) + wind
			vy = clampf(vy + a * dt, -rules.dragon_vy_up, rules.dragon_vy_down)
		"robo":
			if hold and not _prev_hold and on_ground:
				vy = -rules.robo_jump
				_emit("jump")
			vy += rules.robo_gravity * dt
		_:
			a = rules.gravity + wind
			if hold and energy > 0.0:
				a -= rules.thrust
				energy = maxf(energy - rules.energy_drain * dt, 0.0)
			vy = clampf(vy + a * dt, -rules.vy_up_max, rules.vy_down_max)
	y += vy * dt
	var r := radius()
	var bottom := rules.floor_y - r
	var top := rules.ceiling_y + r
	var was_ground := on_ground
	on_ground = false
	if y >= bottom:
		y = bottom
		if vy > 0.0:
			vy = 0.0
		on_ground = true
		if not was_ground:
			_emit("land")
	elif y <= top:
		y = top
		vy = maxf(vy, 0.0)
	if on_ground and form == "" and not hold:
		energy = minf(energy + rules.energy_regen_ground * dt, rules.energy_max)


func _objects(_dt: float, _sc: float) -> void:
	var p := Vector2(dist, y)
	var hr := hit_r()
	var pick_r := rules.hurt_radius + rules.pickup_pad if form == "" else radius() + rules.pickup_pad * 0.5
	var view := rules.spawn_x - rules.player_x
	var i := _first
	while i < level.events.size():
		var e: Dictionary = level.events[i]
		var X := float(e["x"])
		if X - dist > view + 200.0:
			break
		var type := str(e["type"])
		if bool(e.get("_done", false)):
			if i == _first:
				_first += 1
			i += 1
			continue
		match type:
			"mis":
				if dist >= X:
					e["_done"] = true
					missiles.append({"ev": e, "phase": "warn", "t0": t, "sx": rules.spawn_x})
					_emit("warn", {"y": float(e["y"])})
			"orbs":
				var n := int(e.get("n", 6))
				var mask := int(e.get("_taken", 0))
				for k in n:
					if mask & (1 << k):
						continue
					if p.distance_to(orb_pos(e, k, rules)) <= pick_r:
						mask |= 1 << k
						orbs_taken += 1
						_emit("orb")
				e["_taken"] = mask
				if X + n * rules.orb_spacing < dist - 200.0:
					e["_done"] = true
			"core":
				if p.distance_to(Vector2(X, float(e["y"]))) <= pick_r:
					e["_done"] = true
					cores += 1
					energy = minf(energy + rules.core_gain, rules.energy_max)
					_emit("core")
				elif X < dist - 200.0:
					e["_done"] = true
			"box":
				if p.distance_to(Vector2(X, float(e["y"]))) <= pick_r:
					e["_done"] = true
					_take_box(str(e.get("form", "dragon")))
				elif X < dist - 200.0:
					e["_done"] = true
			_:
				if absf(X - dist) < 260.0 and obstacle_clearance(e, p, dist, rules) < hr:
					_hit(e)
				elif X < dist - 300.0:
					e["_done"] = true
		i += 1


func _missiles(dt: float, sc: float) -> void:
	var hr := hit_r()
	for m in missiles:
		var e: Dictionary = m["ev"]
		if m["phase"] == "warn":
			if t - float(m["t0"]) >= rules.missile_warn:
				m["phase"] = "fly"
				_emit("launch", {"from_boss": bool(e.get("from_boss", false))})
			continue
		m["sx"] = float(m["sx"]) - (sc + rules.missile_speed) * dt
		if not bool(e.get("_crushed", false)) and not bool(e.get("_hit", false)):
			var d := Vector2(float(m["sx"]) - rules.player_x, float(e["y"]) - y).length()
			if d < rules.missile_radius + hr:
				_hit(e)
	missiles = missiles.filter(func(m: Dictionary) -> bool:
		return m["phase"] == "warn" or (float(m["sx"]) > -200.0 and not bool(m["ev"].get("_crushed", false))))


func _take_box(f: String) -> void:
	bonus_orbs += rules.box_orbs
	if form != "":
		form_time = rules.dragon_time if form == "dragon" else rules.robo_time
		_emit("form_refresh", {"form": form})
		return
	form = f
	form_time = rules.dragon_time if f == "dragon" else rules.robo_time
	forms_used += 1
	if f == "robo":
		vy = maxf(vy, 0.0)
	_emit("form", {"form": f})


func _hit(e: Dictionary) -> void:
	if form == "robo":
		e["_crushed"] = true
		e["_done"] = true
		crushed += 1
		bonus_orbs += rules.robo_crush_orbs
		_emit("crush", {"type": str(e["type"])})
		return
	if invuln > 0.0 or bool(e.get("_hit", false)):
		return
	e["_hit"] = true
	hits_taken += 1
	hurt_timer = 0.35
	if form == "dragon":
		_emit("form_break", {"form": form})
		form = ""
		form_time = 0.0
		invuln = rules.invuln_form_break
		vy = clampf(vy, -rules.vy_up_max, rules.vy_down_max)
		return
	lives -= 1
	invuln = rules.invuln_hit
	_emit("hit", {"type": str(e["type"])})


func _finish(ok: bool, reason: String) -> void:
	finished = true
	cleared = ok
	fail_reason = "" if ok else reason
	_emit("finish", {"cleared": ok})


func _emit(kind: String, data: Dictionary = {}) -> void:
	var e := data.duplicate()
	e["kind"] = kind
	e["t"] = t
	_events.append(e)


func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


# ---------------------------------------------------------------- kết quả

func orb_total() -> int:
	return level.orbs_before(dist, rules) if level.is_endless() else level.orbs_before(INF, rules)


func orb_ratio() -> float:
	var n := orb_total()
	return 1.0 if n == 0 else clampf(float(orbs_taken) / n, 0.0, 1.0)


func accuracy() -> float:
	return 0.6 * orb_ratio() + 0.4 * float(maxi(lives, 0)) / rules.lives


func score() -> int:
	return int(meters()) + rules.score_per_orb * (orbs_taken + bonus_orbs)


func stats() -> Dictionary:
	return {
		"accuracy": accuracy(),
		"distance_m": snappedf(meters(), 0.1),
		"distance_ratio": progress_ratio(),
		"hits_taken": hits_taken,
		"hp_left_ratio": float(maxi(lives, 0)) / rules.lives,
		"orb_ratio": orb_ratio(),
		"cores_collected": cores,
		"forms_used": forms_used,
		"zones_passed": zones_passed,
	}


func result() -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = cleared
	# Vô tận: kỷ lục = mét (mục 7).
	r.score = int(meters()) if level.is_endless() else score()
	if not cleared:
		r.rank = "D"
	elif level.is_endless():
		r.rank = rules.endless_rank(meters())
	else:
		r.rank = rules.rank_of(accuracy())
	r.stats = stats()
	r.duration_sec = t
	r.fail_reason = fail_reason
	return r
