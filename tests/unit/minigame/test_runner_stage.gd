extends GdUnitTestSuite
## Màn chơi Chạy Nguyên Tố trong khung Event nguyên liệu.

const SCENE := "res://scenes/main/minigame/runner_stage.tscn"
const DT := 1.0 / 120.0


func _stage(level_id := "runner_mat_01", party := PackedStringArray(["char_fire_01"])) -> RunnerStage:
	var s := (load(SCENE) as PackedScene).instantiate() as RunnerStage
	var ctx := MinigameContext.new()
	ctx.mode_id = "runner"
	ctx.stage_id = level_id
	ctx.params = {"level": {"id": level_id}, "speed": {"multiplier": 1.0}, "guide": {"intro_key": "RUNNER_N1_INTRO"}}
	ctx.party = party
	ctx.is_first_play = true
	s.setup(ctx)
	s.manual_clock = true
	add_child(s)
	auto_free(s)
	s.start()
	return s


func test_countdown_then_play_started() -> void:
	var s := _stage()
	var started := [0]
	s.play_started.connect(func() -> void: started[0] += 1)
	assert_str(s.phase).is_equal("countdown")
	assert_str(s._intro.text).is_not_empty()
	s.advance(1.0)
	assert_int(started[0]).is_equal(0)
	s.advance(2.1)
	assert_str(s.phase).is_equal("play")
	assert_int(started[0]).is_equal(1)


func test_bot_clears_through_stage_and_emits_result() -> void:
	var s := _stage("runner_mat_02", PackedStringArray(["char_fire_01", "char_wind_01"]))
	var got: Array = []
	s.finished.connect(func(r: MinigameResult) -> void: got.append(r))
	s.advance(3.1)
	var bot := RunnerBot.new(s.sim)
	var guard := 0
	while got.is_empty() and guard < 120 * 90:
		s._pending = bot.input(DT)
		s.advance(DT)
		guard += 1
	assert_int(got.size()).is_equal(1)
	var r: MinigameResult = got[0]
	assert_bool(r.cleared).is_true()
	assert_int(r.stats["hits_taken"]).is_equal(0)
	assert_str(r.rank).is_equal("S")
	assert_int(r.score).is_greater(0)
	# Không phát lần hai.
	s.advance(1.0)
	assert_int(got.size()).is_equal(1)


func test_quit_before_play_requests_quit_and_after_play_fails() -> void:
	var s := _stage()
	var asked := [0]
	s.quit_requested.connect(func() -> void: asked[0] += 1)
	s.quit()
	assert_int(asked[0]).is_equal(1)
	var s2 := _stage()
	var got: Array = []
	s2.finished.connect(func(r: MinigameResult) -> void: got.append(r))
	s2.advance(3.1)
	s2.advance(1.0)
	s2.quit()
	assert_int(got.size()).is_equal(1)
	assert_str((got[0] as MinigameResult).fail_reason).is_equal("quit")


func test_pause_freezes_and_resume_counts_down() -> void:
	var s := _stage()
	s.advance(3.1)
	s.advance(0.5)
	var t := s.sim.t
	s.set_paused(true)
	s.advance(1.0)
	assert_float(s.sim.t).is_equal(t)
	assert_object(s.find_child("PauseLayer", true, false)).is_not_null()
	s.set_paused(false)
	assert_str(s.phase).is_equal("resume")
	s.advance(1.0)
	assert_float(s.sim.t).is_equal(t)
	s.advance(0.6)
	s.advance(0.5)
	assert_float(s.sim.t).is_greater(t)


func test_touch_halves_and_slot_icons() -> void:
	var s := _stage("runner_mat_03", PackedStringArray(["char_fire_01", "char_wind_01", "char_lightning_01"]))
	s.advance(3.1)
	s.touch(Vector2(300, 700))
	assert_bool(s._pending["jump"]).is_true()
	s.touch(Vector2(1500, 700))
	assert_bool(s._pending["swap"]).is_true()
	s.touch(s.slot_rect(2).get_center())
	assert_int(s._pending["slot"]).is_equal(2)
	s.advance(DT * 2)
	assert_int(s.sim.slot).is_equal(2)


func test_bad_level_shows_error_and_back_quits() -> void:
	var s := _stage("runner_missing")
	assert_str(s.phase).is_equal("error")
	var asked := [0]
	s.quit_requested.connect(func() -> void: asked[0] += 1)
	assert_bool(s.intercept_back()).is_true()
	assert_int(asked[0]).is_equal(1)


## Ảnh cả đội nạp trước khi chạy (lần đầu đổi người không phải nạp ~1.3 s giữa lúc chạy).
func test_party_frames_preloaded_before_play() -> void:
	var s := _stage("runner_mat_03", PackedStringArray(["char_fire_01", "char_wind_01", "char_lightning_01"]))
	assert_array(s._frames.keys()).contains_exactly_in_any_order(["char_fire_01", "char_wind_01", "char_lightning_01"])


func test_real_clock_waits_for_preload_then_counts_down() -> void:
	var s := (load(SCENE) as PackedScene).instantiate() as RunnerStage
	var ctx := MinigameContext.new()
	ctx.params = {"level": {"id": "runner_mat_02"}}
	ctx.party = PackedStringArray(["char_fire_01", "char_wind_01"])
	s.setup(ctx)
	add_child(s)
	auto_free(s)
	s.start()
	var guard := 0
	while s.phase == "preload" and guard < 600:
		await get_tree().process_frame
		guard += 1
	assert_str(s.phase).is_equal("countdown")
	assert_bool(s._frames.has("char_wind_01")).is_true()
	assert_float(s.timer).is_greater(2.5)


func test_boss_stage_throws_and_shows_boss() -> void:
	var s := _stage("runner_mat_05", PackedStringArray(["char_fire_01", "char_wind_01", "char_lightning_01"]))
	assert_object(s._boss).is_not_null()
	assert_float(s._throw_x).is_equal(1750.0)
	s.advance(3.1)
	var bot := RunnerBot.new(s.sim)
	var thrown := false
	for i in 120 * 4:
		s._pending = bot.input(DT)
		s.advance(DT)
		thrown = thrown or s._boss.animation == &"throw"
	assert_bool(thrown).is_true()
	assert_int(s.sim.hits_taken).is_equal(0)


func test_endless_stage_builds_level_from_generator() -> void:
	var s := (load(SCENE) as PackedScene).instantiate() as RunnerStage
	var ctx := MinigameContext.new()
	ctx.stage_id = "endless:route_drift:normal"
	ctx.params = {"gen": {"speed": 850, "length_sec": 150, "gate_gap": 0.8, "overlap": true}, "route": {"id": "route_drift", "seed": 41011}}
	ctx.party = PackedStringArray(["char_fire_01", "char_wind_01", "char_lightning_01"])
	s.setup(ctx)
	s.manual_clock = true
	add_child(s)
	auto_free(s)
	s.start()
	assert_str(s.phase).is_equal("countdown")
	assert_float(s.level.speed).is_equal(850.0)
	assert_float(s.level.length_sec).is_equal(150.0)
	assert_int(s.level.count("gate")).is_greater(10)
	assert_object(s._boss).is_null()
