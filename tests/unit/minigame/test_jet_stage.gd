extends GdUnitTestSuite
## Màn chơi Bay Nguyên Tố trong khung Event nguyên liệu.

const SCENE := "res://scenes/main/minigame/jet_stage.tscn"
const DT := 1.0 / 120.0


func _stage(params: Dictionary, stage_id := "jet_mat_01") -> JetStage:
	var s := (load(SCENE) as PackedScene).instantiate() as JetStage
	var ctx := MinigameContext.new()
	ctx.mode_id = "jet"
	ctx.stage_id = stage_id
	ctx.params = params
	ctx.party = PackedStringArray(["char_wind_01"])
	ctx.is_first_play = true
	s.setup(ctx)
	s.manual_clock = true
	add_child(s)
	auto_free(s)
	s.start()
	return s


func test_countdown_then_play_and_bot_clears() -> void:
	var s := _stage({"level": {"id": "jet_mat_02"}, "guide": {"intro_key": "JET_N2_INTRO"}}, "jet_mat_02")
	var started := [0]
	var got: Array = []
	s.play_started.connect(func() -> void: started[0] += 1)
	s.finished.connect(func(r: MinigameResult) -> void: got.append(r))
	assert_str(s.phase).is_equal("countdown")
	assert_str(s._intro.text).is_not_empty()
	s.advance(3.1)
	assert_int(started[0]).is_equal(1)
	var bot := JetBot.new(s.sim)
	var guard := 0
	while got.is_empty() and guard < 120 * 200:
		s.forced_hold = bot.hold()
		s.advance(DT)
		guard += 1
	assert_int(got.size()).is_equal(1)
	var r: MinigameResult = got[0]
	assert_bool(r.cleared).is_true()
	assert_int(r.stats["hits_taken"]).is_equal(0)
	assert_int(r.stats["zones_passed"]).is_equal(1)
	assert_int(r.score).is_greater(1200)


func test_hold_input_keys_and_touch() -> void:
	var s := _stage({"level": {"id": "jet_mat_01"}})
	s.advance(3.1)
	s.touch(0, Vector2(900, 600), true)
	assert_bool(s.holding()).is_true()
	s.touch(1, Vector2(1200, 300), true)
	s.touch(0, Vector2(900, 600), false)
	assert_bool(s.holding()).is_true()
	s.touch(1, Vector2(1200, 300), false)
	assert_bool(s.holding()).is_false()
	# Chạm nút tạm dừng không tính là giữ.
	s.touch(2, HudTheme.ACTIVE_CARD_POS + Vector2(20, 20), true)
	assert_bool(s.holding()).is_false()


func test_pause_clears_hold_and_resume_counts_down() -> void:
	var s := _stage({"level": {"id": "jet_mat_01"}})
	s.advance(3.1)
	s.touch(0, Vector2(900, 600), true)
	s.advance(0.5)
	var t := s.sim.t
	s.set_paused(true)
	s.advance(1.0)
	assert_float(s.sim.t).is_equal(t)
	s.set_paused(false)
	assert_bool(s.holding()).is_false()
	assert_str(s.phase).is_equal("resume")
	s.advance(1.6)
	s.advance(0.5)
	assert_float(s.sim.t).is_greater(t)


func test_boss_stage_and_endless_params() -> void:
	var b := _stage({"level": {"id": "jet_mat_05"}}, "jet_mat_05")
	assert_object(b._boss).is_not_null()
	var e := _stage({"endless": {"zone": "wind", "scroll_base": 520}, "seed": 12345}, "endless:zone_2")
	assert_bool(e.level.is_endless()).is_true()
	assert_str(e.sim.zone).is_equal("wind")
	assert_object(e._boss).is_null()
	e.advance(3.1)
	for i in 120 * 5:
		e.advance(DT)
	assert_bool(e.sim.finished).is_false()


func test_quit_and_bad_level() -> void:
	var s := _stage({"level": {"id": "jet_mat_01"}})
	var asked := [0]
	s.quit_requested.connect(func() -> void: asked[0] += 1)
	s.quit()
	assert_int(asked[0]).is_equal(1)
	var bad := _stage({"level": {"id": "jet_missing"}})
	assert_str(bad.phase).is_equal("error")


# ---------- Ghép ảnh thật (JetArt + JetStage) ----------

func test_art_files_all_load() -> void:
	for rel in ["jet_pack.png", "jet_icon_dragon.png", "jet_icon_robo.png", "jet_beam_body_v2.png", "jet_gate_block.png",
			"jet_wind_arrow.png", "jet_card.png"]:
		assert_object(JetArt.tex(rel)).override_failure_message(rel).is_not_null()
	for z in ["ash", "wind", "thunder"]:
		for kind in ["far", "mid", "floor", "ceiling"]:
			assert_object(JetArt.zone_tex(kind, z)).override_failure_message("%s %s" % [z, kind]).is_not_null()
	assert_int(JetArt.seq("jet_core", "jet_core_idle", 6).size()).is_equal(6)
	assert_int(JetArt.seq("jet_orb", "jet_orb_idle", 4).size()).is_equal(4)
	assert_int(JetArt.seq("jet_box", "jet_box_idle", 6).size()).is_equal(6)
	assert_int(JetArt.seq("jet_box", "jet_box_open", 6).size()).is_equal(6)
	assert_int(JetArt.seq("jet_beam_node/pulse", "jet_beam_node_pulse", 4).size()).is_equal(4)
	assert_int(JetArt.seq("jet_sweep/hum", "jet_sweep_hum", 3).size()).is_equal(3)
	assert_int(JetArt.seq("jet_gate_lip/spark", "jet_gate_lip_spark", 3).size()).is_equal(3)
	assert_int(JetArt.seq("jet_missile/fly_v2", "jet_missile_fly_v2", 4).size()).is_equal(4)
	assert_int(JetArt.seq("jet_missile_warn/blink", "jet_missile_warn_blink", 2).size()).is_equal(2)
	var dragon := JetArt.form_frames("dragon")
	assert_int(dragon.get_frame_count(&"fly")).is_equal(6)
	assert_int(dragon.get_frame_count(&"break")).is_equal(6)
	var robo := JetArt.form_frames("robo")
	assert_int(robo.get_frame_count(&"walk")).is_equal(6)
	assert_int(robo.get_frame_count(&"jump")).is_equal(3)
	assert_int(robo.get_frame_count(&"crush")).is_equal(4)
	assert_int(robo.get_frame_count(&"break")).is_equal(6)


func test_flame_is_neutral_and_gate_column_scaled() -> void:
	var flames := JetArt.flame()
	assert_int(flames.size()).is_equal(4)
	var img := flames[0].get_image()
	var checked := 0
	for y in range(0, img.get_height(), 7):
		for x in range(0, img.get_width(), 7):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				checked += 1
				assert_float(absf(c.r - c.g) + absf(c.g - c.b)).is_less(0.02)
	assert_int(checked).is_greater(10)
	var col := JetArt.gate_column(70.0)
	assert_object(col).is_not_null()
	assert_int(col.get_width()).is_between(77, 79)


func test_card_art_in_event_data_exists() -> void:
	var reg := MinigameRegistry.load_from()
	var card: Dictionary = reg.mode("evt_material", "jet").get("card", {})
	var path := str(card["art"][0]["path"])
	assert_str(path).is_equal("res://assets/jet/jet_card.png")
	assert_bool(ResourceLoader.exists(path)).is_true()


func test_dragon_sprite_and_rider_seat() -> void:
	var s := _stage({"level": {"id": "jet_mat_02"}}, "jet_mat_02")
	s.advance(3.1)
	s.sim._take_box("dragon")
	s.advance(0.05)
	assert_bool(s._form_sprite.visible).is_true()
	assert_str(str(s._form_sprite.animation)).is_equal("fly")
	var i: int = s._form_sprite.frame
	var want := Vector2(s.rules.player_x, s.sim.y) + Vector2(JetStage.DRAGON_SEAT_X - JetStage.DRAGON_CENTER.x,
			float(JetStage.DRAGON_SEAT_Y[i]) - JetStage.DRAGON_CENTER.y) * JetStage.DRAGON_SCALE
	assert_vector(s._sprite.position).is_equal_approx(want, Vector2(0.5, 0.5))
	assert_str(str(s._sprite.animation)).is_equal("idle")


func test_robo_sprite_feet_on_floor_and_rider_seat() -> void:
	var s := _stage({"level": {"id": "jet_mat_03"}}, "jet_mat_03")
	s.advance(3.1)
	s.sim._take_box("robo")
	for k in 120:
		s.advance(1.0 / 120.0)
	assert_bool(s._form_sprite.visible).is_true()
	assert_bool(s.sim.on_ground).is_true()
	# Chân Robo chạm mặt sàn vẽ.
	assert_float(s._form_sprite.position.y).is_equal_approx(s.rules.floor_y + JetStage.VISUAL_FLOOR, 0.5)
	var want: Vector2 = s._robo_origin() + (JetStage.ROBO_SEAT - JetStage.ROBO_FEET) * JetStage.ROBO_SCALE
	assert_vector(s._sprite.position).is_equal_approx(want, Vector2(0.5, 0.5))
	# Hết hình: sprite ẩn, người đứng lại.
	s.sim.form = ""
	s.advance(0.02)
	assert_bool(s._form_sprite.visible).is_false()
	assert_float(s._sprite.position.y).is_equal_approx(s.sim.y + JetStage.FEET_BELOW, 0.5)


func test_form_break_spawns_one_shot_fx_and_cleans_up() -> void:
	var s := _stage({"level": {"id": "jet_mat_02"}}, "jet_mat_02")
	s.advance(3.1)
	s._spawn_form_break("dragon")
	s._spawn_form_break("robo")
	assert_int(s._fx.size()).is_equal(2)
	for k in 40:
		await get_tree().process_frame
		s.advance(1.0 / 60.0)
	assert_int(s._fx.size()).is_equal(0)
