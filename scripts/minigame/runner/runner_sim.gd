class_name RunnerSim
extends RefCounted
## Logic Chạy Nguyên Tố (docs/design/RUNNER_MODE.md mục 4–6), không đồ họa: chạy theo bước cố định, nên bot kiểm thử và
## màn chơi cho cùng một kết quả. Màn chơi (`RunnerStage`) chỉ gửi input và vẽ theo state.
##
##   var sim := RunnerSim.new(rules, level, party_size)
##   sim.step(1.0 / 120.0, {"jump": true, "swap": false, "slot": -1})
##   for ev in sim.take_events(): ...   # hiệu ứng / âm thanh
##
## Quy ước va chạm: vật ở x = player_x + (t_vật − t) × speed. `w` của vật cản là bề rộng VA CHẠM đã gộp thân người
## chạy (chạm khi |x_vật − player_x| < w / 2); hình vẽ có thể to hơn. Cặn Thấp chạm khi chân thấp hơn `h`; Vết Thực
## làm rơi khi đứng trên hố; Cặn Bay chiếm độ cao 250..340, đứng dưới đất thì lọt.

const FLYER_BOTTOM := 250.0
const FLYER_TOP := 340.0
## Rơi xuống hố sâu chừng này thì tính trúng (rồi bật lên).
const PIT_FALL_DEPTH := 60.0
## Vật đi qua người chạy chừng này giây sau t của nó thì chốt kết quả (vượt an toàn / đã trúng).
const RESOLVE_PAD := 0.02

var rules: RunnerRules
var level: RunnerLevel
var party_size := 1

# --- trạng thái ---
var t := 0.0
## Độ cao chân so với mặt đường (âm = đang rơi xuống hố).
var h := 0.0
var vy := 0.0
var grounded := true
var hp := 100
var slot := 0
var finished := false
var cleared := false
var fail_reason := ""
var invuln := 0.0
var hurt_timer := 0.0
var swap_flash := 0.0

var score := 0
var combo := 0
var max_combo := 0
var fever := 0.0
var fever_time := 0.0

var hits_taken := 0
var safe_passes := 0
var gates_perfect := 0
var gates_normal := 0
var gates_wrong := 0
var orbs_taken := 0

## Trạng thái từng vật cản / cổng theo chỉ số trong level.obstacles: 0 chưa tới, 1 đã chốt.
var ob_done: PackedByteArray
## Vật đã chạm người chạy (trúng, hoặc chạm lúc bất tử).
var ob_touched: PackedByteArray
var orb_taken: PackedByteArray

var _first_ob := 0
var _first_orb := 0
var _last_ground_t := 0.0
var _jump_press_t := -100.0
var _jumped_since_ground := false
var _swap_cd := 0.0
var _last_swap_t := -100.0
var _events: Array[Dictionary] = []
var _fall_pit := -1


func _init(rules_: RunnerRules, level_: RunnerLevel, party_size_ := 1) -> void:
	rules = rules_
	level = level_
	party_size = clampi(party_size_, 1, 3)
	hp = rules.hp_max
	ob_done.resize(level.obstacles.size())
	ob_touched.resize(level.obstacles.size())
	orb_taken.resize(level.orbs.size())


# ---------------------------------------------------------------- vị trí

func x_of(event_t: float) -> float:
	return rules.player_x + (event_t - t) * level.speed


func progress_ratio() -> float:
	return clampf(t / level.length_sec, 0.0, 1.0)


func fever_active() -> bool:
	return fever_time > 0.0


# ---------------------------------------------------------------- bước

## input: {"jump": bấm nhảy (cạnh lên), "swap": đổi kế tiếp, "slot": chọn thẳng ô 0..2 hoặc -1}.
func step(dt: float, input: Dictionary = {}) -> void:
	if finished:
		return
	t += dt
	invuln = maxf(invuln - dt, 0.0)
	hurt_timer = maxf(hurt_timer - dt, 0.0)
	swap_flash = maxf(swap_flash - dt, 0.0)
	_swap_cd = maxf(_swap_cd - dt, 0.0)
	if fever_time > 0.0:
		fever_time = maxf(fever_time - dt, 0.0)
		if fever_time == 0.0:
			_emit("fever_end")
	_handle_swap(input)
	if bool(input.get("jump", false)):
		_jump_press_t = t
	_physics(dt)
	_obstacles()
	_orbs()
	if hp <= 0:
		_finish(false, "hp_zero")
	elif t >= level.length_sec:
		_finish(true, "")


func _handle_swap(input: Dictionary) -> void:
	var want := int(input.get("slot", -1))
	if want < 0 and bool(input.get("swap", false)):
		want = (slot + 1) % party_size
	if want < 0 or want >= party_size or want == slot or _swap_cd > 0.0:
		return
	slot = want
	_swap_cd = rules.swap_cooldown
	_last_swap_t = t
	swap_flash = rules.swap_cooldown
	_emit("swap", {"slot": slot})


## Chỉ số hố dưới chân (-1 = không có).
func _pit_under() -> int:
	for i in range(_first_ob, level.obstacles.size()):
		var o: Dictionary = level.obstacles[i]
		var dx := x_of(float(o["t"])) - rules.player_x
		if dx > 400.0:
			break
		if o["type"] == "pit" and absf(dx) < float(o["w"]) * 0.5:
			return i
	return -1


func _physics(dt: float) -> void:
	var can_jump := grounded or (not _jumped_since_ground and t - _last_ground_t <= rules.coyote_time and h > -PIT_FALL_DEPTH * 0.5)
	if can_jump and t - _jump_press_t <= rules.jump_buffer:
		vy = rules.jump_velocity
		grounded = false
		_jumped_since_ground = true
		_jump_press_t = -100.0
		_emit("jump")
	if grounded:
		var pit := _pit_under()
		if pit >= 0 and invuln <= 0.0:
			grounded = false
			vy = 0.0
			_fall_pit = pit
		else:
			_last_ground_t = t
			return
	# Chuyển động đều có gia tốc: chính xác theo công thức, không lệch theo bước.
	h += vy * dt - 0.5 * rules.gravity * dt * dt
	vy -= rules.gravity * dt
	if h <= 0.0 and vy <= 0.0:
		if h > -PIT_FALL_DEPTH * 0.5 and (invuln > 0.0 or _pit_under() < 0):
			_land()
		elif h <= -PIT_FALL_DEPTH:
			_pit_fall()


func _land() -> void:
	h = 0.0
	vy = 0.0
	grounded = true
	_jumped_since_ground = false
	_last_ground_t = t
	_emit("land")


## Rơi hố: mất HP, bất tử lâu hơn, bật lên lại mặt đường.
func _pit_fall() -> void:
	_take_hit(rules.hit_damage, rules.pit_invuln_time, "pit")
	h = 0.0
	vy = rules.jump_velocity * 0.6
	grounded = false
	_jumped_since_ground = true
	if _fall_pit >= 0:
		ob_touched[_fall_pit] = 1
	_fall_pit = -1


func _obstacles() -> void:
	var foot := h
	var head := h + rules.hurt_height
	for i in range(_first_ob, level.obstacles.size()):
		if ob_done[i] == 1:
			if i == _first_ob:
				_first_ob += 1
			continue
		var o: Dictionary = level.obstacles[i]
		var ot := float(o["t"])
		if ot - t > 1.0:
			break
		var type := str(o["type"])
		if type == "gate":
			if t >= ot + rules.gate_grace:
				_gate(i, o)
			continue
		var half := float(o["w"]) * 0.5
		var dx := x_of(ot) - rules.player_x
		if absf(dx) < half and ob_touched[i] == 0:
			var hit := false
			if type == "hurdle":
				hit = foot < float(o["h"])
			elif type == "flyer":
				hit = head > FLYER_BOTTOM and foot < FLYER_TOP
			elif type == "pit" and grounded:
				# Chỉ xảy ra khi đang bất tử (đi trên hố): không mất HP nhưng không tính vượt an toàn.
				ob_touched[i] = 1
			if hit:
				ob_touched[i] = 1
				if invuln <= 0.0:
					_take_hit(rules.hit_damage, rules.invuln_time, type)
		if t > ot + half / level.speed + RESOLVE_PAD:
			ob_done[i] = 1
			if ob_touched[i] == 0:
				safe_passes += 1
				_combo_up()
				_add_score(rules.score_pass)
				_add_fever(rules.fever_pass)
				_emit("pass", {"index": i})


func _gate(i: int, o: Dictionary) -> void:
	ob_done[i] = 1
	var gate_slot := int(o["slot"])
	if gate_slot == slot:
		var perfect := t - _last_swap_t <= rules.perfect_swap_window + rules.gate_grace
		if perfect:
			gates_perfect += 1
			_combo_up()
			_add_score(rules.score_gate_perfect)
			_add_fever(rules.fever_gate_perfect)
		else:
			gates_normal += 1
			_combo_up()
			_add_score(rules.score_gate)
			_add_fever(rules.fever_pass)
		_emit("gate", {"index": i, "perfect": perfect, "slot": gate_slot})
	else:
		gates_wrong += 1
		ob_touched[i] = 1
		_take_hit(rules.gate_damage, rules.invuln_time, "gate")
		_emit("gate_wrong", {"index": i, "slot": gate_slot})


func _orbs() -> void:
	var cx := rules.player_x
	var cy := h + rules.hurt_height * 0.5
	var r := rules.fever_magnet_radius if fever_active() else rules.pickup_radius
	for i in range(_first_orb, level.orbs.size()):
		var o: Dictionary = level.orbs[i]
		var ox := x_of(float(o["t"]))
		if ox < cx - r - 10.0:
			if i == _first_orb:
				_first_orb += 1
			continue
		if ox > cx + r + 10.0:
			break
		if orb_taken[i] == 1:
			continue
		if Vector2(ox - cx, float(o["h"]) - cy).length() <= r:
			orb_taken[i] = 1
			orbs_taken += 1
			var match_ := int(o["slot"]) >= 0 and int(o["slot"]) == slot
			_add_score(rules.score_orb_match if match_ else rules.score_orb)
			_add_fever(rules.fever_orb)
			_emit("orb", {"index": i, "match": match_})


func _take_hit(damage: int, inv: float, kind: String) -> void:
	hp = maxi(hp - damage, 0)
	invuln = inv
	hurt_timer = 0.35
	hits_taken += 1
	combo = 0
	fever = maxf(fever + rules.fever_hit, 0.0)
	_emit("hit", {"cause": kind})


func _combo_up() -> void:
	combo += 1
	max_combo = maxi(max_combo, combo)


func _add_score(base: int) -> void:
	var mult := 1.0 + minf(float(combo), float(rules.combo_bonus_cap)) * rules.combo_bonus_step
	if fever_active():
		mult *= rules.fever_multiplier
	score += roundi(base * mult)


func _add_fever(amount: float) -> void:
	if fever_active():
		return
	fever = clampf(fever + amount, 0.0, rules.fever_max)
	if fever >= rules.fever_max:
		fever = 0.0
		fever_time = rules.fever_duration
		_emit("fever")


func _finish(ok: bool, reason: String) -> void:
	finished = true
	cleared = ok
	fail_reason = reason
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

func total_gates() -> int:
	return level.count("gate")


func total_obstacles() -> int:
	return level.obstacles.size() - total_gates()


func accuracy() -> float:
	var total := level.obstacles.size()
	if total == 0:
		return 1.0
	return (gates_perfect + gates_normal * rules.gate_normal_weight + safe_passes) / float(total)


func stats() -> Dictionary:
	var gates := total_gates()
	return {
		"accuracy": accuracy(),
		"max_combo": max_combo,
		"hits_taken": hits_taken,
		"collect_ratio": 1.0 if level.orbs.is_empty() else float(orbs_taken) / level.orbs.size(),
		"perfect_swaps": gates_perfect,
		"perfect_swap_ratio": 1.0 if gates == 0 else float(gates_perfect) / gates,
		"distance_ratio": progress_ratio(),
		"hp_left_ratio": float(hp) / float(rules.hp_max),
	}


func result() -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = cleared
	r.score = score
	r.rank = rules.rank_of(accuracy()) if cleared else "D"
	r.stats = stats()
	r.duration_sec = t
	r.fail_reason = fail_reason
	return r
