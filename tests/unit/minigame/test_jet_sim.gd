extends GdUnitTestSuite
## Bay Nguyên Tố: vật lý, năng lượng, hình, vùng, vật cản, bộ sinh, bộ kiểm hành lang, level dựng sẵn
## (docs/design/JET_MODE.md mục 13).

const DT := 1.0 / 120.0
const LEVELS := ["jet_mat_01", "jet_mat_02", "jet_mat_03", "jet_mat_04", "jet_mat_05"]


func _rules() -> JetRules:
	return load("res://data/jet/jet_rules.tres") as JetRules


func _level(events: Array, zones := [{"from_m": 0, "id": "ash"}], length := 300.0, scroll := 520.0) -> JetLevel:
	return JetLevel.from_dict({"format": 1, "level_id": "t", "length_m": length, "scroll_base": scroll, "scroll_ramp": 0.0,
			"zones": zones, "forms": ["dragon", "robo"], "events": events})


func _run(sim: JetSim, sec: float, hold := false) -> void:
	var n := roundi(sec / DT)
	for i in n:
		sim.step(DT, hold)


func test_climb_matches_reach_table_and_caps() -> void:
	var r := _rules()
	var sim := JetSim.new(r, _level([]))
	var y0 := sim.y
	_run(sim, 0.5, true)
	# Lên thực 1400 px/s² từ nghỉ: 175 px sau 0.5 s (bảng mục 4).
	assert_float(y0 - sim.y).is_equal_approx(175.0, 3.0)
	_run(sim, 0.5, true)
	assert_float(sim.vy).is_equal_approx(-r.vy_up_max, 0.01)


func test_energy_drains_while_holding_and_regens_only_on_ground() -> void:
	var r := _rules()
	var sim := JetSim.new(r, _level([]))
	_run(sim, 1.0, true)
	assert_float(sim.energy).is_equal_approx(76.0, 0.5)
	# Đang rơi (trên không, không giữ): không hồi.
	var e := sim.energy
	_run(sim, 0.2, false)
	assert_float(sim.energy).is_equal_approx(e, 0.01)
	_run(sim, 2.0, false)
	assert_bool(sim.on_ground).is_true()
	var e2 := sim.energy
	_run(sim, 1.0, false)
	assert_float(sim.energy - e2).is_equal_approx(10.0, 0.2)
	# Hết năng lượng: giữ cũng rơi, không kẹt.
	sim.energy = 0.0
	_run(sim, 0.5, true)
	assert_bool(sim.on_ground).is_true()


func test_hover_lasts_about_6_8_seconds() -> void:
	var r := _rules()
	var sim := JetSim.new(r, _level([], [{"from_m": 0, "id": "ash"}], 2000.0))
	_run(sim, 0.6, true)
	var target := sim.y
	sim.energy = _rules().energy_max
	var start := sim.t
	while sim.energy > 0.0 and sim.t - start < 20.0:
		sim.step(DT, sim.y + sim.vy * 0.05 > target)
	# Lý thuyết 6.8 s (giữ 61 % thời gian); bộ điều khiển giữ / thả theo bước 1/120 s đo được ~7.2 s.
	assert_float(sim.t - start).is_equal_approx(6.8, 0.5)


func test_ceiling_blocks_without_damage() -> void:
	var sim := JetSim.new(_rules(), _level([]))
	_run(sim, 2.5, true)
	assert_float(sim.y).is_equal_approx(_rules().ceiling_y + _rules().hurt_radius, 0.01)
	assert_int(sim.lives).is_equal(3)


func test_beam_hit_costs_life_and_invuln_blocks_second() -> void:
	var ev := [{"d": 40, "type": "beam", "y": 868, "len": 150, "ang": 0}, {"d": 42, "type": "beam", "y": 868, "len": 150, "ang": 0}]
	var sim := JetSim.new(_rules(), _level(ev))
	_run(sim, 6.0)
	assert_int(sim.hits_taken).is_equal(1)
	assert_int(sim.lives).is_equal(2)


func test_lives_zero_fails_level() -> void:
	var ev := []
	for i in 3:
		ev.append({"d": 40 + i * 30, "type": "beam", "y": 868, "len": 150, "ang": 0})
	var sim := JetSim.new(_rules(), _level(ev))
	_run(sim, 20.0)
	assert_bool(sim.finished).is_true()
	assert_bool(sim.cleared).is_false()
	assert_str(sim.result().fail_reason).is_equal("hp_zero")
	assert_str(sim.result().rank).is_equal("D")


func test_dragon_absorbs_one_hit_and_controls() -> void:
	var r := _rules()
	var ev := [{"d": 25, "type": "box", "y": 868, "form": "dragon"}, {"d": 45, "type": "beam", "y": 868, "len": 150, "ang": 0}]
	var sim := JetSim.new(r, _level(ev))
	_run(sim, 3.2)
	assert_str(sim.form).is_equal("dragon")
	assert_int(sim.forms_used).is_equal(1)
	assert_int(sim.bonus_orbs).is_equal(r.box_orbs)
	var e := sim.energy
	_run(sim, 0.3, true)
	assert_float(sim.energy).is_equal(e)   # Rồng không tốn năng lượng
	assert_float(sim.vy).is_less(0.0)
	_run(sim, 3.0, false)
	assert_str(sim.form).is_equal("")
	# Vỡ hình thay vì mất tim.
	assert_int(sim.lives).is_equal(3)
	assert_int(sim.hits_taken).is_equal(1)


func test_dragon_expires_after_time() -> void:
	var r := _rules()
	var sim := JetSim.new(r, _level([{"d": 25, "type": "box", "y": 868, "form": "dragon"}], [{"from_m": 0, "id": "ash"}], 900.0))
	_run(sim, 3.2)
	assert_str(sim.form).is_equal("dragon")
	_run(sim, r.dragon_time + 0.1)
	assert_str(sim.form).is_equal("")


func test_robo_jumps_on_tap_and_crushes() -> void:
	var r := _rules()
	var ev := [{"d": 25, "type": "box", "y": 868, "form": "robo"}, {"d": 45, "type": "beam", "y": 860, "len": 150, "ang": 0}]
	var sim := JetSim.new(r, _level(ev, [{"from_m": 0, "id": "wind"}]))
	_run(sim, 3.2)
	assert_str(sim.form).is_equal("robo")
	_run(sim, 0.3)
	var y0 := sim.y
	sim.step(DT, true)
	var top := sim.y
	while sim.vy < 0.0:
		sim.step(DT, true)   # giữ không nhảy lại
		top = minf(top, sim.y)
	assert_float(y0 - top).is_equal_approx(248.5, 6.0)
	_run(sim, 3.0)
	assert_int(sim.crushed).is_equal(1)
	assert_int(sim.lives).is_equal(3)
	assert_int(sim.bonus_orbs).is_equal(r.box_orbs + r.robo_crush_orbs)


func test_wind_cycle_by_distance_and_not_on_robo() -> void:
	var r := _rules()
	var lv := _level([], [{"from_m": 0, "id": "wind"}], 600.0, 600.0)
	var cyc := r.wind_cycle * 600.0
	assert_float(lv.wind_at_px(0.5 * 600.0, r)).is_equal(0.0)
	assert_float(lv.wind_at_px(2.0 * 600.0, r)).is_equal(-r.wind_accel)
	assert_float(lv.wind_at_px(cyc + 2.0 * 600.0, r)).is_equal(r.wind_accel)
	assert_float(lv.wind_at_px(4.0 * 600.0, r)).is_equal(0.0)
	assert_float(_level([], [{"from_m": 0, "id": "ash"}]).wind_at_px(1200.0, r)).is_equal(0.0)


func test_missile_warns_one_second_then_flies() -> void:
	var r := _rules()
	var sim := JetSim.new(r, _level([{"d": 40, "type": "mis", "y": 868}]))
	_run(sim, 40.0 * 60.0 / 520.0 + 0.05)
	assert_int(sim.missiles.size()).is_equal(1)
	assert_str(sim.missiles[0]["phase"]).is_equal("warn")
	_run(sim, 1.0)
	assert_str(sim.missiles[0]["phase"]).is_equal("fly")
	_run(sim, 3.0)
	assert_int(sim.hits_taken).is_equal(1)


func test_orbs_and_cores_score() -> void:
	var r := _rules()
	var sim := JetSim.new(r, _level([{"d": 30, "type": "orbs", "y": 868, "n": 6}, {"d": 45, "type": "core", "y": 868}]))
	sim.energy = 50.0
	_run(sim, 7.0)
	assert_int(sim.orbs_taken).is_equal(6)
	assert_int(sim.cores).is_equal(1)
	assert_float(sim.orb_ratio()).is_equal(1.0)
	assert_int(sim.score()).is_equal(int(sim.meters()) + 30)


func test_level_validation_errors() -> void:
	assert_bool(_level([{"d": 5, "type": "beam", "y": 500}]).is_valid()).is_false()
	assert_bool(_level([{"d": 40, "type": "laser", "y": 500}]).is_valid()).is_false()
	assert_bool(_level([{"d": 40, "type": "box", "y": 500, "form": "cat"}]).is_valid()).is_false()
	assert_bool(_level([{"d": 40, "type": "beam", "y": 1500}]).is_valid()).is_false()
	assert_bool(_level([{"d": 40, "type": "beam", "y": 500}]).is_valid()).is_true()
	assert_bool(_level([], [{"from_m": 0, "id": "lava"}]).is_valid()).is_false()


func test_generator_deterministic() -> void:
	var cfg := {"level_id": "x", "length_m": 600, "scroll_base": 600, "zones": [{"from_m": 0, "id": "thunder"}], "forms": ["dragon"]}
	var a := JetGenerator.to_json_text(JetGenerator.generate(9, cfg))
	assert_str(a).is_equal(JetGenerator.to_json_text(JetGenerator.generate(9, cfg)))
	assert_str(a).is_not_equal(JetGenerator.to_json_text(JetGenerator.generate(10, cfg)))


func test_validator_catches_beam_on_path() -> void:
	var r := _rules()
	var lv := JetGenerator.generate(3, {"level_id": "x", "length_m": 600, "scroll_base": 600, "zones": [{"from_m": 0, "id": "ash"}]})
	assert_array(JetValidator.check(lv, r)).is_empty()
	var px := lv.path[lv.path.size() / 2]
	lv.events.append({"x": px.x, "d": px.x / 60.0, "type": "beam", "y": px.y, "len": 150, "ang": 0.0})
	lv.events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["x"]) < float(b["x"]))
	assert_array(JetValidator.check(lv, r)).is_not_empty()


func test_shipped_levels_valid_and_bot_clears_with_zero_hits() -> void:
	var r := _rules()
	for id in LEVELS:
		var lv := JetLevel.load_id(id)
		assert_bool(lv.is_valid()).override_failure_message("%s: %s" % [id, lv.errors]).is_true()
		assert_array(JetValidator.check(lv, r)).override_failure_message(id).is_empty()
		var sim := JetBot.play(r, JetLevel.load_id(id))
		assert_bool(sim.cleared).override_failure_message(id + " không về đích").is_true()
		assert_int(sim.hits_taken).override_failure_message("%s trúng %d" % [id, sim.hits_taken]).is_equal(0)
	assert_bool(JetLevel.load_id("jet_mat_05").boss is Dictionary).is_true()
	assert_int(JetLevel.load_id("jet_mat_01").count("box")).is_equal(0)
	assert_int(JetLevel.load_id("jet_mat_01").count("mis")).is_equal(0)


func test_endless_bot_and_validator_several_seeds() -> void:
	var r := _rules()
	for seed in [1, 2, 3]:
		var lv := JetLevel.endless(seed, {"scroll_base": 520, "scroll_ramp": 0.15})
		var sim := JetBot.play(r, lv, 3200.0)
		assert_int(sim.hits_taken).override_failure_message("seed %d trúng %d" % [seed, sim.hits_taken]).is_equal(0)
		assert_int(sim.zones_passed).is_greater_equal(5)
		assert_array(JetValidator.check(lv, r, 1200.0, 3100.0)).is_empty()
		var res := sim.result()
		assert_int(res.score).is_equal(int(sim.meters()))
	# Luyện một vùng: chỉ vùng đó.
	var z := JetLevel.endless(5, {"scroll_base": 520}, "thunder")
	var s2 := JetBot.play(r, z, 1500.0)
	assert_int(s2.zones_passed).is_equal(0)
	assert_str(s2.zone).is_equal("thunder")


func test_endless_rank_by_distance() -> void:
	var r := _rules()
	assert_str(r.endless_rank(1400.0)).is_equal("D")
	assert_str(r.endless_rank(1500.0)).is_equal("C")
	assert_str(r.endless_rank(1800.0)).is_equal("B")
	assert_str(r.endless_rank(2250.0)).is_equal("A")
	assert_str(r.endless_rank(3000.0)).is_equal("S")


func test_stats_keys_match_registry() -> void:
	var sim := JetBot.play(_rules(), JetLevel.load_id("jet_mat_01"))
	var keys: Array = sim.result().stats.keys()
	for k in MinigameRegistry.STATS_KEYS["jet"]:
		assert_bool(keys.has(k)).override_failure_message(k).is_true()
