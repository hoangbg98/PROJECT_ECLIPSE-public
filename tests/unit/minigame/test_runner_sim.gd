extends GdUnitTestSuite
## Chạy Nguyên Tố: vật lý, vật cản, cổng, điểm, level dựng sẵn (docs/design/RUNNER_MODE.md mục 13).

const DT := 1.0 / 120.0
const LEVELS := ["runner_mat_01", "runner_mat_02", "runner_mat_03", "runner_mat_04", "runner_mat_05"]


func _rules() -> RunnerRules:
	return load("res://data/runner/runner_rules.tres") as RunnerRules


func _level(events: Array, slots := [0, 1, 2], speed := 600.0, length := 20.0) -> RunnerLevel:
	return RunnerLevel.from_dict({"format": 1, "level_id": "t", "speed": speed, "length_sec": length,
			"slots_used": slots, "events": events})


func _run_until(sim: RunnerSim, until: float, inputs: Dictionary = {}) -> void:
	# inputs: {thời điểm (làm tròn bước): input}
	while sim.t < until and not sim.finished:
		var k := snappedf(sim.t + DT, DT)
		var inp: Dictionary = {}
		for at in inputs:
			if absf(float(at) - k) < DT * 0.5:
				inp = inputs[at]
		sim.step(DT, inp)


func test_rules_data_matches_design() -> void:
	var r := _rules()
	assert_float(r.peak_height()).is_equal_approx(211.25, 0.01)
	assert_float(r.airtime()).is_equal_approx(0.65, 0.001)
	assert_str(r.rank_of(0.96)).is_equal("S")
	assert_str(r.rank_of(0.5)).is_equal("D")


func test_jump_peak_and_airtime() -> void:
	var sim := RunnerSim.new(_rules(), _level([]))
	sim.step(DT, {"jump": true})
	var peak := 0.0
	var start := sim.t - DT
	while not sim.grounded:
		sim.step(DT)
		peak = maxf(peak, sim.h)
	assert_float(peak).is_equal_approx(211.25, 1.0)
	assert_float(sim.t - start).is_equal_approx(0.65, 0.01)


func test_holding_jump_does_not_rejump_but_buffer_works() -> void:
	var sim := RunnerSim.new(_rules(), _level([]))
	sim.step(DT, {"jump": true})
	while not sim.grounded:
		sim.step(DT)
	# Đứng yên, không bấm: không nhảy lại.
	for i in 30:
		sim.step(DT)
	assert_bool(sim.grounded).is_true()
	# Bấm 0.1 s trước khi chạm đất: vẫn nhảy ngay khi chạm đất (bộ đệm 0.12 s).
	sim.step(DT, {"jump": true})
	var pressed_again := false
	while sim.h > 0.0 or not pressed_again:
		if not pressed_again and sim.vy < 0.0 and sim.h < 1300.0 * 0.1:
			sim.step(DT, {"jump": true})
			pressed_again = true
		else:
			sim.step(DT)
	for i in 3:
		sim.step(DT)
	var jumps := sim.take_events().filter(func(e: Dictionary) -> bool: return e["kind"] == "jump")
	assert_int(jumps.size()).is_equal(2)


func test_hurdle_hits_when_not_jumping_and_passes_when_jumping() -> void:
	var lv := _level([{"t": 3.0, "type": "hurdle", "h": 110, "w": 120}])
	var stay := RunnerSim.new(_rules(), lv)
	_run_until(stay, 4.0)
	assert_int(stay.hits_taken).is_equal(1)
	assert_int(stay.hp).is_equal(80)
	assert_int(stay.combo).is_equal(0)
	var jump := RunnerSim.new(_rules(), lv)
	_run_until(jump, 4.0, {snappedf(3.0 - 0.325, DT): {"jump": true}})
	assert_int(jump.hits_taken).is_equal(0)
	assert_int(jump.safe_passes).is_equal(1)
	assert_int(jump.score).is_equal(50)


func test_flyer_hits_only_when_jumping() -> void:
	var lv := _level([{"t": 3.0, "type": "flyer"}])
	var stay := RunnerSim.new(_rules(), lv)
	_run_until(stay, 4.0)
	assert_int(stay.hits_taken).is_equal(0)
	assert_int(stay.safe_passes).is_equal(1)
	var jump := RunnerSim.new(_rules(), lv)
	_run_until(jump, 4.0, {snappedf(2.8, DT): {"jump": true}})
	assert_int(jump.hits_taken).is_equal(1)


func test_pit_fall_costs_hp_and_grants_long_invuln() -> void:
	var lv := _level([{"t": 3.0, "type": "pit", "w": 180}])
	var sim := RunnerSim.new(_rules(), lv)
	_run_until(sim, 3.3)
	assert_int(sim.hits_taken).is_equal(1)
	assert_float(sim.invuln).is_greater(1.0)
	_run_until(sim, 5.0)
	assert_bool(sim.grounded).is_true()
	assert_float(sim.h).is_equal(0.0)
	assert_int(sim.safe_passes).is_equal(0)


func test_coyote_allows_late_jump_at_pit_edge() -> void:
	var lv := _level([{"t": 3.0, "type": "pit", "w": 180}])
	var sim := RunnerSim.new(_rules(), lv)
	# Mép hố tới người chạy lúc 3.0 − 0.15 = 2.85; bấm trễ 0.05 s vẫn nhảy được.
	_run_until(sim, 4.0, {snappedf(2.9, DT): {"jump": true}})
	assert_int(sim.hits_taken).is_equal(0)


func test_gate_right_slot_perfect_and_normal_and_wrong() -> void:
	var lv := _level([{"t": 3.0, "type": "gate", "slot": 1}, {"t": 5.0, "type": "gate", "slot": 1},
			{"t": 7.0, "type": "gate", "slot": 0}], [0, 1], 600.0)
	var sim := RunnerSim.new(_rules(), lv, 2)
	_run_until(sim, 8.0, {snappedf(2.8, DT): {"swap": true}})
	assert_int(sim.gates_perfect).is_equal(1)
	assert_int(sim.gates_normal).is_equal(1)
	assert_int(sim.gates_wrong).is_equal(1)
	assert_int(sim.hp).is_equal(75)


func test_gate_swap_too_early_is_not_perfect() -> void:
	var lv := _level([{"t": 3.0, "type": "gate", "slot": 1}], [0, 1])
	var sim := RunnerSim.new(_rules(), lv, 2)
	_run_until(sim, 4.0, {snappedf(2.6, DT): {"slot": 1}})
	assert_int(sim.gates_perfect).is_equal(0)
	assert_int(sim.gates_normal).is_equal(1)


func test_swap_cooldown_and_party_size() -> void:
	var sim := RunnerSim.new(_rules(), _level([]), 3)
	sim.step(DT, {"swap": true})
	sim.step(DT, {"swap": true})
	assert_int(sim.slot).is_equal(1)
	for i in 15:
		sim.step(DT)
	sim.step(DT, {"swap": true})
	assert_int(sim.slot).is_equal(2)
	var solo := RunnerSim.new(_rules(), _level([]), 1)
	solo.step(DT, {"swap": true})
	solo.step(DT, {"slot": 2})
	assert_int(solo.slot).is_equal(0)


func test_orbs_ground_line_collected_and_match_bonus() -> void:
	var lv := _level([{"t": 3.0, "type": "orbs", "pattern": "line", "n": 4, "y": "ground", "slot": 0},
			{"t": 5.0, "type": "orbs", "pattern": "line", "n": 2, "y": "ground", "slot": null}])
	var sim := RunnerSim.new(_rules(), lv, 2)
	_run_until(sim, 6.0)
	assert_int(sim.orbs_taken).is_equal(6)
	assert_int(sim.score).is_equal(4 * 20 + 2 * 10)


func test_hp_zero_fails() -> void:
	var ev := []
	for i in 6:
		ev.append({"t": 3.0 + i * 2.0, "type": "gate", "slot": 1})
	var sim := RunnerSim.new(_rules(), _level(ev, [0, 1]), 2)
	_run_until(sim, 20.0)
	assert_bool(sim.finished).is_true()
	assert_bool(sim.cleared).is_false()
	var r := sim.result()
	assert_str(r.fail_reason).is_equal("hp_zero")
	assert_str(r.rank).is_equal("D")


func test_level_validation_errors() -> void:
	assert_bool(_level([{"t": 1.0, "type": "hurdle"}]).is_valid()).is_false()
	assert_bool(_level([{"t": 3.0, "type": "boulder"}]).is_valid()).is_false()
	assert_bool(_level([{"t": 3.0, "type": "gate", "slot": 2}], [0, 1]).is_valid()).is_false()
	assert_bool(_level([{"t": 3.0, "type": "gate", "slot": 1}], [0, 1]).is_valid()).is_true()


func test_shipped_levels_valid_and_bot_clears_with_zero_hits() -> void:
	for id in LEVELS:
		var lv := RunnerLevel.load_id(id)
		assert_bool(lv.is_valid()).override_failure_message("%s: %s" % [id, lv.errors]).is_true()
		var size := lv.slots_used.size()
		for mode in ["next", "direct"]:
			var sim := RunnerBot.play(_rules(), lv, size, mode)
			assert_bool(sim.cleared).override_failure_message("%s %s không về đích" % [id, mode]).is_true()
			assert_int(sim.hits_taken).override_failure_message("%s %s trúng %d" % [id, mode, sim.hits_taken]).is_equal(0)
			assert_int(sim.gates_wrong).is_equal(0)
			assert_int(sim.gates_perfect + sim.gates_normal).is_equal(sim.total_gates())
			assert_str(sim.result().rank).is_equal("S")
			assert_float(sim.stats()["collect_ratio"]).override_failure_message("%s nhặt %s" % [id, sim.stats()["collect_ratio"]]).is_greater_equal(0.8)


func test_stats_keys_match_registry() -> void:
	var sim := RunnerBot.play(_rules(), RunnerLevel.load_id("runner_mat_01"), 1)
	var keys: Array = sim.result().stats.keys()
	for k in MinigameRegistry.STATS_KEYS["runner"]:
		assert_bool(keys.has(k)).override_failure_message(k).is_true()


# ---------- Bộ sinh (N-4, N-5, Vô tận) ----------

func test_generator_is_deterministic() -> void:
	var cfg := {"speed": 850, "length_sec": 60, "slots_used": [0, 1, 2], "gate_gap": 0.8, "overlap": true}
	var a := RunnerGenerator.to_json_text(RunnerGenerator.generate(77, cfg))
	var b := RunnerGenerator.to_json_text(RunnerGenerator.generate(77, cfg))
	var c := RunnerGenerator.to_json_text(RunnerGenerator.generate(78, cfg))
	assert_str(a).is_equal(b)
	assert_str(a).is_not_equal(c)


func test_generator_respects_constraints() -> void:
	for gap in [1.0, 0.6]:
		var d := RunnerGenerator.generate(5, {"speed": 1000, "length_sec": 120, "slots_used": [0, 1], "gate_gap": gap, "overlap": false})
		var lv := RunnerLevel.from_dict(d)
		assert_bool(lv.is_valid()).override_failure_message(str(lv.errors)).is_true()
		var last_gate := -100.0
		for o in lv.obstacles:
			if o["type"] == "gate":
				assert_float(float(o["t"]) - last_gate).is_greater_equal(gap - 0.001)
				assert_int(int(o["slot"])).is_less(2)
				last_gate = float(o["t"])
			elif o["type"] == "hurdle":
				# Không chồng cổng khi overlap = false.
				assert_bool(lv.obstacles.any(func(g: Dictionary) -> bool: return g["type"] == "gate" and absf(float(g["t"]) - float(o["t"])) < 0.3)).is_false()
	# Một người: không có cổng.
	var solo := RunnerLevel.from_dict(RunnerGenerator.generate(9, {"speed": 700, "length_sec": 60, "slots_used": [0]}))
	assert_int(solo.count("gate")).is_equal(0)


func test_boss_level_has_boss_and_fast_throws() -> void:
	var lv := RunnerLevel.load_id("runner_mat_05")
	assert_bool(lv.boss is Dictionary).is_true()
	# Thời gian phản ứng từ chỗ ném (mục 7): (1750 − 480) / 1000 ≈ 1.27 s.
	assert_float((float(lv.boss["throw_x"]) - _rules().player_x) / lv.speed).is_equal_approx(1.27, 0.01)
	assert_float(lv.length_sec).is_equal(120.0)


func test_endless_routes_cleared_by_bot_every_difficulty() -> void:
	var reg := MinigameRegistry.load_from()
	var routes := reg.routes("evt_material", "runner_endless")
	assert_int(routes.size()).is_greater_equal(3)
	var seeds := {}
	for r in routes:
		for diff in ["easy", "normal", "hard"]:
			var st := reg.route_stage("evt_material", "runner_endless", str(r["id"]), diff)
			assert_str(str(st["id"])).is_equal("endless:%s:%s" % [r["id"], diff])
			assert_int(int(st["party_min"])).is_equal(3)
			var seed := int(st["params"]["route"]["seed"])
			assert_bool(seeds.has(seed)).is_false()
			seeds[seed] = true
			var lv := RunnerLevel.from_dict(RunnerGenerator.generate(seed, st["params"]["gen"]))
			assert_bool(lv.is_valid()).override_failure_message(str(lv.errors)).is_true()
			var sim := RunnerBot.play(_rules(), lv, 3, "next")
			assert_bool(sim.cleared).is_true()
			assert_int(sim.hits_taken).override_failure_message("%s %s trúng %d" % [r["id"], diff, sim.hits_taken]).is_equal(0)
