class_name RunnerStage
extends MinigameStage
## Màn chơi Chạy Nguyên Tố (M11-4, docs/design/RUNNER_MODE.md). Luật ở `RunnerSim` (bước cố định 1/120 s qua
## `FixedStep`); màn này chỉ đọc input, vẽ theo state, hiện HUD, đếm ngược, tạm dừng rồi trả `MinigameResult`.
##
## params (data/events/material_events.json): level.id, speed.multiplier, guide.intro_key; Vô tận: gen (cấu hình
## RunnerGenerator) + route.seed thay cho level.id. Level có `boss` ({"id", "throw_x"}): Vầng Khuyết đứng mép phải,
## vật cản chỉ hiện khi bị ném ra ở throw_x (thời gian phản ứng ngắn hơn), thanh HP boss = quãng đường còn lại.
## Phím: nhảy = Space / W / ↑, đổi kế tiếp = E / Shift / →, chọn thẳng = 1 / 2 / 3 (InputRouter `runner_*`);
## cảm ứng: nửa trái = nhảy, nửa phải = đổi, biểu tượng đội góc trên phải = chọn thẳng.

const BACK_GROUP := &"back_interceptor"
const RULES_PATH := "res://data/runner/runner_rules.tres"
const VIEW := Vector2(1920, 1080)
## Vật cản luôn tím trung tính (mục 5); màu nguyên tố chỉ cho cổng, hạt khớp, biểu tượng đội.
const OBSTACLE_TINT := Color("#B48CFF")
const ORB_NEUTRAL := Color("#BFF3FF")
const SKY_TOP := Color("#120E2A")
const SKY_BOTTOM := Color("#2B1F55")
const GROUND := Color("#231A3D")
const GROUND_EDGE := Color("#7C5CFF")
const CHAR_SCALE := 0.85
const SLOT_ICON := 140.0
const SLOT_GAP := 18.0
const RESUME_SEC := 1.5
const POPUP_SEC := 0.7
const BOSS_DIR := "res://assets/rhythm/rh_boss_eclipse/%s/rh_boss_eclipse_%s_%03d.png"
## [animation, số frame, fps, lặp]
const BOSS_ANIMS := [["idle", 8, 10.0, true], ["throw", 6, 14.0, false], ["hurt", 3, 12.0, false], ["defeat", 10, 16.0, false]]
## Vật vừa ném bay vòng cung trong đoạn này (px) trước khi chạm đất.
const THROW_ARC := 220.0

var rules: RunnerRules
var level: RunnerLevel
var sim: RunnerSim
var fixed := FixedStep.new()
## "load" | "preload" (nạp frame cả đội) | "countdown" | "play" | "resume" | "done" | "error"
var phase := "load"
var paused := false
var timer := 0.0
## Test: không tự chạy theo khung hình, gọi `advance()` bằng tay.
var manual_clock := false
var party := PackedStringArray()
var party_colors: Array[Color] = []
## Ảnh ô đội: splash cắt phần mặt (thiếu thì chân dung / frame idle).
var party_faces: Array[Texture2D] = []
var load_error := ""

var _world: Control
var _hud: Control
var _sprite: AnimatedSprite2D
var _frames: Dictionary = {}
var _preload_paths := PackedStringArray()
var _pause_layer: Control
var _intro: Label
var _pending := {"jump": false, "swap": false, "slot": -1}
var _play_emitted := false
var _done := false
var _slime: Array[Texture2D] = []
var _bat: Array[Texture2D] = []
var _popups: Array[Dictionary] = []
var _land_timer := 0.0
var _anim_t := 0.0
var _boss: AnimatedSprite2D
var _throw_x := INF
var _boss_next := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(BACK_GROUP)


func _p(path: String, def: Variant) -> Variant:
	return MinigameRegistry.param(ctx.params, path, def) if ctx else def


func start() -> void:
	rules = load(RULES_PATH) as RunnerRules
	var gen: Variant = _p("gen", null)
	if gen is Dictionary:
		var cfg: Dictionary = (gen as Dictionary).duplicate(true)
		cfg["level_id"] = ctx.stage_id if ctx else ""
		level = RunnerLevel.from_dict(RunnerGenerator.generate(int(_p("route.seed", 1)), cfg))
	else:
		level = RunnerLevel.load_id(str(_p("level.id", "runner_mat_01")))
	if rules == null or not level.is_valid():
		load_error = "; ".join(level.errors) if level else "rules"
		push_error("RunnerStage: " + load_error)
		_build_error()
		return
	level.speed *= clampf(float(_p("speed.multiplier", 1.0)), 0.5, 2.0)
	party = ctx.party if ctx and not ctx.party.is_empty() else PackedStringArray(["char_fire_01"])
	if party.size() > 3:
		party = party.slice(0, 3)
	for id in party:
		var def := CharacterArt.def_of(id)
		party_colors.append(HudTheme.ring_color(def.element if def else ""))
		party_faces.append(CharacterArt.top_crop(CharacterArt.splash(id), 1.0))
	sim = RunnerSim.new(rules, level, party.size())
	_load_textures()
	_build()
	_start_preload()
	phase = "preload"
	if manual_clock and _preload_done(true):
		phase = "countdown"
	timer = rules.countdown_sec
	var intro_key := str(_p("guide.intro_key", ""))
	if intro_key != "" and ctx and ctx.is_first_play:
		_intro.text = tr(intro_key)


# ---------------------------------------------------------------- dựng

func _load_textures() -> void:
	for i in 6:
		var a := load("res://assets/rhythm/rh_slime/run/rh_slime_run_%03d.png" % i) as Texture2D
		if a:
			_slime.append(a)
		var b := load("res://assets/rhythm/rh_bat/fly/rh_bat_fly_%03d.png" % i) as Texture2D
		if b:
			_bat.append(b)


func _build() -> void:
	_world = Control.new()
	_world.name = "World"
	_world.set_anchors_preset(Control.PRESET_FULL_RECT)
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.draw.connect(_draw_world)
	add_child(_world)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Character"
	_sprite.scale = Vector2.ONE * CHAR_SCALE
	add_child(_sprite)
	if level.boss is Dictionary:
		_build_boss(level.boss)
	_apply_slot_frames()
	_hud = Control.new()
	_hud.name = "Hud"
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.draw.connect(_draw_hud)
	add_child(_hud)
	var pause_btn := Button.new()
	pause_btn.name = "PauseButton"
	pause_btn.text = "II"
	pause_btn.position = HudTheme.ACTIVE_CARD_POS
	pause_btn.size = Vector2.ONE * HudTheme.PAUSE_BUTTON_SIZE
	pause_btn.add_theme_font_size_override("font_size", 48)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(set_paused.bind(true))
	add_child(pause_btn)
	_intro = Label.new()
	_intro.name = "Intro"
	_intro.position = Vector2(260, 620)
	_intro.size = Vector2(1400, 160)
	_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro.add_theme_font_size_override("font_size", 36)
	_intro.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.12))
	_intro.add_theme_constant_override("outline_size", 8)
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intro)
	_place_sprite()


func _build_boss(b: Dictionary) -> void:
	_throw_x = float(b.get("throw_x", 1750.0))
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for spec in BOSS_ANIMS:
		var a: String = spec[0]
		frames.add_animation(a)
		frames.set_animation_speed(a, float(spec[2]))
		frames.set_animation_loop(a, bool(spec[3]))
		for i in int(spec[1]):
			var tex := load(BOSS_DIR % [a, a, i]) as Texture2D
			if tex:
				frames.add_frame(a, tex)
	_boss = AnimatedSprite2D.new()
	_boss.name = "Boss"
	_boss.sprite_frames = frames
	_boss.position = Vector2(_throw_x + 110.0, rules.ground_y - 360.0)
	_boss.scale = Vector2.ONE * 0.6
	_boss.animation_finished.connect(func() -> void:
		if _boss.animation != &"defeat":
			_boss.play(&"idle"))
	add_child(_boss)
	move_child(_boss, _world.get_index() + 1)
	_boss.play(&"idle")


## Boss ném: mỗi Cặn Thấp / Cặn Bay đi qua throw_x thì boss vung tay.
func _update_boss() -> void:
	if _boss == null:
		return
	while _boss_next < level.obstacles.size() and sim.x_of(float(level.obstacles[_boss_next]["t"])) <= _throw_x:
		if str(level.obstacles[_boss_next]["type"]) in ["hurdle", "flyer"] and _boss.animation != &"defeat":
			_boss.play(&"throw")
		_boss_next += 1
	if sim.finished and sim.cleared and _boss.animation != &"defeat":
		_boss.play(&"defeat")


func _build_error() -> void:
	phase = "error"
	var bg := ColorRect.new()
	bg.color = SKY_TOP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var l := Label.new()
	l.text = tr("RUNNER_LOAD_ERROR") + "\n\n" + tr("EVENT_BACK_HINT")
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 40)
	add_child(l)


## Nạp nền frame của các người còn lại trong đội (mỗi người ~1.3 s nếu nạp ngay lúc đổi: khựng lần đầu đổi người).
## Chỉ nạp animation màn này dùng; xong mới đếm ngược.
func _start_preload() -> void:
	_preload_paths.clear()
	for i in range(1, party.size()):
		var dir := AnimationSetBuilder.CHARACTERS_DIR.path_join(party[i])
		var anims: Dictionary = AnimationSetBuilder.load_manifest(dir).get("animations", {})
		for a in anims:
			for k in int(anims[a].get("frames", 0)):
				var p := AnimationSetBuilder.frame_path(dir, party[i], str(a), k)
				if ResourceLoader.exists(p) and not ResourceLoader.has_cached(p):
					if ResourceLoader.load_threaded_request(p, "", true) == OK:
						_preload_paths.append(p)


## Đã nạp xong chưa (block = chờ hết, cho test đồng hồ tay). Xong thì dựng SpriteFrames từ bộ nhớ đệm (nhanh).
func _preload_done(block := false) -> bool:
	for p in _preload_paths:
		if not block and ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return false
	for p in _preload_paths:
		ResourceLoader.load_threaded_get(p)
	_preload_paths.clear()
	for id in party:
		_frames_for(id)
	return true


func _frames_for(id: String) -> AnimationSetBuilder.Result:
	if not _frames.has(id):
		_frames[id] = AnimationSetBuilder.build_for_character(id)
	return _frames[id]


func _apply_slot_frames() -> void:
	var built := _frames_for(party[sim.slot])
	_sprite.sprite_frames = built.sprite_frames
	_sprite.offset = built.sprite_offset
	_play_anim("idle" if phase in ["preload", "countdown"] else "run")


func _play_anim(n: String, fallback := "run") -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var a := StringName(n)
	if not _sprite.sprite_frames.has_animation(a):
		a = StringName(fallback)
	if not _sprite.sprite_frames.has_animation(a):
		return
	if _sprite.animation != a or not _sprite.is_playing():
		_sprite.play(a)


func _place_sprite() -> void:
	_sprite.position = Vector2(rules.player_x, rules.ground_y - sim.h)
	var blink := sim.invuln > 0.0 and fmod(sim.invuln, 0.16) < 0.08
	_sprite.modulate = Color(1, 1, 1, 0.45 if blink else 1.0)


# ---------------------------------------------------------------- vòng lặp

func _process(delta: float) -> void:
	if not manual_clock:
		advance(delta)


## Chạy màn thêm `delta` giây (test gọi trực tiếp với manual_clock = true).
func advance(delta: float) -> void:
	if sim == null or paused or phase in ["done", "error", "load"]:
		return
	_anim_t += delta
	match phase:
		"preload":
			if _preload_done(manual_clock):
				phase = "countdown"
				timer = rules.countdown_sec
		"countdown", "resume":
			timer -= delta
			if timer <= 0.0:
				_begin_play()
		"play":
			var n := fixed.advance(delta)
			for i in n:
				sim.step(fixed.step, _pending if i == 0 else {})
				if i == 0:
					_clear_pending()
				_handle_events(sim.take_events())
				if sim.finished:
					break
	_tick_popups(delta)
	_update_character(delta)
	_update_boss()
	_world.queue_redraw()
	_hud.queue_redraw()
	if sim.finished and phase == "play":
		_finish()


func _begin_play() -> void:
	phase = "play"
	_intro.text = ""
	fixed.reset()
	_clear_pending()
	if not _play_emitted:
		_play_emitted = true
		play_started.emit()


func _clear_pending() -> void:
	_pending = {"jump": false, "swap": false, "slot": -1}


func _handle_events(evs: Array[Dictionary]) -> void:
	var px := Vector2(rules.player_x, rules.ground_y - sim.h - 280)
	for e in evs:
		match str(e["kind"]):
			"swap":
				_apply_slot_frames()
			"land":
				_land_timer = 0.15
			"gate":
				if bool(e["perfect"]):
					_popup(tr("RUNNER_PERFECT"), Color("#FFD84D"), px, 64)
				else:
					_popup(tr("RUNNER_GOOD"), Color("#7FE8FF"), px, 48)
			"gate_wrong":
				_popup(tr("RUNNER_WRONG_GATE"), Color("#FF6A6A"), px, 52)
			"hit":
				_popup("-%d" % (rules.gate_damage if str(e["cause"]) == "gate" else rules.hit_damage), Color("#FF6A6A"), px + Vector2(120, 40), 40)
			"fever":
				_popup(tr("RUNNER_FEVER"), Color("#FF5FA8"), Vector2(960, 300), 72)


func _finish() -> void:
	if _done:
		return
	_done = true
	phase = "done"
	finished.emit(sim.result())


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if sim == null or phase in ["done", "error"] or event.is_echo():
		return
	if event.is_action_pressed(&"pause"):
		set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if paused or phase != "play":
		return
	if event.is_action_pressed(&"runner_jump"):
		_pending["jump"] = true
	elif event.is_action_pressed(&"runner_swap"):
		_pending["swap"] = true
	else:
		for i in 3:
			if event.is_action_pressed(StringName("runner_slot_%d" % (i + 1))):
				_pending["slot"] = i
				return
		if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			touch((event as InputEventScreenTouch).position)


## Chạm màn hình (đã đổi về khung 1920×1080): biểu tượng đội trước, rồi nửa trái / nửa phải.
func touch(pos: Vector2) -> void:
	for i in party.size():
		if slot_rect(i).grow(10).has_point(pos):
			_pending["slot"] = i
			return
	var pause_rect := Rect2(HudTheme.ACTIVE_CARD_POS, Vector2.ONE * HudTheme.PAUSE_BUTTON_SIZE)
	if pause_rect.grow(10).has_point(pos):
		return
	if pos.x < VIEW.x * 0.5:
		_pending["jump"] = true
	else:
		_pending["swap"] = true


## Test / bot: đặt input cho bước kế tiếp.
func press(action: String, slot_index := -1) -> void:
	match action:
		"jump":
			_pending["jump"] = true
		"swap":
			_pending["swap"] = true
		"slot":
			_pending["slot"] = slot_index


func intercept_back() -> bool:
	if phase in ["done", "error"]:
		if phase == "error":
			quit()
		return phase == "error"
	set_paused(not paused)
	return true


func set_paused(p: bool) -> void:
	if paused == p or phase in ["done", "error", "load"]:
		return
	paused = p
	if p:
		_show_pause()
		return
	if _pause_layer:
		_pause_layer.queue_free()
		_pause_layer = null
	_clear_pending()
	if phase == "play":
		phase = "resume"
		timer = RESUME_SEC


func pause_game() -> void:
	set_paused(true)


func resume_game() -> void:
	set_paused(false)


func retry() -> void:
	retry_requested.emit()


func quit() -> void:
	if _done:
		return
	if _play_emitted:
		_done = true
		phase = "done"
		finished.emit(MinigameResult.quit_result(sim.t if sim else 0.0))
	else:
		quit_requested.emit()


func _show_pause() -> void:
	_pause_layer = Control.new()
	_pause_layer.name = "PauseLayer"
	_pause_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_pause_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_layer.add_child(dim)
	var title := Label.new()
	title.text = tr("RHYTHM_PAUSED")
	title.position = Vector2(560, 240)
	title.size = Vector2(800, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	_pause_layer.add_child(title)
	var specs := [["ResumeButton", "RHYTHM_RESUME", set_paused.bind(false)], ["RetryButton", "RESULT_RETRY", retry],
			["QuitButton", "RHYTHM_QUIT", quit]]
	for i in specs.size():
		var b := Button.new()
		b.name = specs[i][0]
		b.text = tr(specs[i][1])
		b.position = Vector2(760, 400 + i * 150)
		b.size = Vector2(400, 120)
		b.add_theme_font_size_override("font_size", 40)
		b.pressed.connect(specs[i][2])
		_pause_layer.add_child(b)


# ---------------------------------------------------------------- hình

func _update_character(delta: float) -> void:
	_land_timer = maxf(_land_timer - delta, 0.0)
	if phase in ["preload", "countdown"]:
		_play_anim("idle")
	elif sim.hurt_timer > 0.0:
		_play_anim("hurt")
	elif not sim.grounded:
		_play_anim("jump_up" if sim.vy > 0.0 else "fall", "jump_up")
	elif _land_timer > 0.0:
		_play_anim("land")
	else:
		_play_anim("run")
	_place_sprite()


func _popup(text: String, col: Color, pos: Vector2, size: int) -> void:
	_popups.append({"text": text, "color": col, "pos": pos, "size": size, "t": POPUP_SEC})


func _tick_popups(delta: float) -> void:
	for p in _popups:
		p["t"] = float(p["t"]) - delta
		p["pos"] = (p["pos"] as Vector2) + Vector2(0, -60 * delta)
	_popups = _popups.filter(func(p: Dictionary) -> bool: return float(p["t"]) > 0.0)


func _frame(arr: Array[Texture2D], fps: float) -> Texture2D:
	return arr[int(_anim_t * fps) % arr.size()] if not arr.is_empty() else null


func _draw_world() -> void:
	var w := _world
	var gy := rules.ground_y
	# Trời: dải chuyển màu theo hàng.
	for i in 12:
		var r := Rect2(0, gy * i / 12.0, VIEW.x, gy / 12.0 + 1)
		w.draw_rect(r, SKY_TOP.lerp(SKY_BOTTOM, i / 11.0))
	var scroll := sim.t * level.speed
	# Lớp xa: đỉnh núi tím chạy chậm.
	var far := fmod(scroll * 0.15, 480.0)
	for i in 6:
		var x0 := i * 480.0 - far
		w.draw_colored_polygon(PackedVector2Array([Vector2(x0 - 60, gy), Vector2(x0 + 180, gy - 300), Vector2(x0 + 420, gy)]),
				Color("#3A2A6E", 0.7))
	# Lớp giữa: cột đá.
	var mid := fmod(scroll * 0.4, 360.0)
	for i in 7:
		var x1 := i * 360.0 - mid
		w.draw_rect(Rect2(x1, gy - 170, 46, 170), Color("#2E2258", 0.9))
		w.draw_rect(Rect2(x1 - 10, gy - 186, 66, 20), Color("#4A3A88", 0.9))
	# Mặt đường.
	w.draw_rect(Rect2(0, gy, VIEW.x, VIEW.y - gy), GROUND)
	w.draw_rect(Rect2(0, gy, VIEW.x, 6), GROUND_EDGE)
	var tile := fmod(scroll, 160.0)
	for i in 14:
		var tx := i * 160.0 - tile
		w.draw_line(Vector2(tx, gy + 6), Vector2(tx - 60, VIEW.y), Color(1, 1, 1, 0.06), 3.0)
	_draw_obstacles(w)
	_draw_orbs(w)
	if sim.swap_flash > 0.0:
		var c := party_colors[sim.slot]
		var k := sim.swap_flash / rules.swap_cooldown
		w.draw_arc(Vector2(rules.player_x, gy - sim.h - 115), 150.0 + (1.0 - k) * 60.0, 0, TAU, 48, Color(c, k), 10.0)
	if sim.fever_active():
		w.draw_rect(Rect2(Vector2.ZERO, VIEW), Color("#FF5FA8", 0.08 + 0.04 * sin(_anim_t * 8.0)))


func _draw_obstacles(w: Control) -> void:
	var gy := rules.ground_y
	for i in level.obstacles.size():
		var o: Dictionary = level.obstacles[i]
		var x := sim.x_of(float(o["t"]))
		if x > VIEW.x + 300.0:
			break
		if x < -300.0:
			continue
		var ow := float(o["w"])
		var thrown := str(o["type"]) in ["hurdle", "flyer"]
		if thrown and x > _throw_x:
			continue
		var lift := 0.0
		if thrown and x > _throw_x - THROW_ARC:
			var k := (x - (_throw_x - THROW_ARC)) / THROW_ARC
			lift = -sin(k * PI * 0.5) * 260.0
		gy = rules.ground_y + lift
		match str(o["type"]):
			"pit":
				w.draw_rect(Rect2(x - ow * 0.5, gy - 2, ow, VIEW.y - gy + 2), Color("#07040F"))
				w.draw_rect(Rect2(x - ow * 0.5 - 8, gy, 8, VIEW.y - gy), Color(OBSTACLE_TINT, 0.7))
				w.draw_rect(Rect2(x + ow * 0.5, gy, 8, VIEW.y - gy), Color(OBSTACLE_TINT, 0.7))
			"hurdle":
				var oh := float(o["h"])
				var s := oh * 1.6
				var tex := _frame(_slime, 10.0)
				if tex:
					w.draw_texture_rect(tex, Rect2(x - s * 0.5, gy - s * 222.0 / 256.0, s, s), false, OBSTACLE_TINT)
				else:
					w.draw_rect(Rect2(x - ow * 0.5, gy - oh, ow, oh), OBSTACLE_TINT)
			"flyer":
				var s2 := 190.0
				var cy := gy - (RunnerSim.FLYER_BOTTOM + RunnerSim.FLYER_TOP) * 0.5
				var tex2 := _frame(_bat, 12.0)
				if tex2:
					w.draw_texture_rect(tex2, Rect2(x - s2 * 0.5, cy - s2 * 0.5, s2, s2), false, OBSTACLE_TINT)
				else:
					w.draw_rect(Rect2(x - 60, cy - 45, 120, 90), OBSTACLE_TINT)
			"gate":
				_draw_gate(w, x, int(o["slot"]), sim.ob_done[i] == 1, sim.ob_touched[i] == 1)


func _draw_gate(w: Control, x: float, slot: int, done: bool, wrong: bool) -> void:
	var c: Color = party_colors[slot] if slot < party_colors.size() else Color(0.6, 0.6, 0.6)
	var a := 0.35 if done else 1.0
	if wrong:
		c = Color("#FF4D4D")
	var gy := rules.ground_y
	w.draw_rect(Rect2(x - 70, 0, 140, gy), Color(c, 0.12 * a))
	w.draw_rect(Rect2(x - 22, 0, 44, gy), Color(c, 0.45 * a))
	w.draw_rect(Rect2(x - 6, 0, 12, gy), Color(1, 1, 1, 0.8 * a))
	for y in [290.0, gy - 400.0]:
		w.draw_circle(Vector2(x, y), 62, Color(0.05, 0.03, 0.12, 0.85 * a))
		w.draw_arc(Vector2(x, y), 62, 0, TAU, 40, Color(c, a), 6.0)
		draw_slot_symbol(w, slot, Vector2(x, y), 34.0, Color(1, 1, 1, a))


## Ký hiệu ô (trợ năng, mục 1): ○ ô 1, △ ô 2, □ ô 3.
static func draw_slot_symbol(ci: CanvasItem, slot: int, c: Vector2, r: float, col: Color, width := 7.0) -> void:
	match slot:
		0:
			ci.draw_arc(c, r, 0, TAU, 32, col, width)
		1:
			var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.95, r * 0.75), c + Vector2(-r * 0.95, r * 0.75), c + Vector2(0, -r)])
			ci.draw_polyline(pts, col, width)
		_:
			ci.draw_rect(Rect2(c - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), col, false, width)


func _draw_orbs(w: Control) -> void:
	var gy := rules.ground_y
	for i in level.orbs.size():
		if sim.orb_taken[i] == 1:
			continue
		var o: Dictionary = level.orbs[i]
		var x := sim.x_of(float(o["t"]))
		if x > VIEW.x + 40.0:
			break
		if x < -40.0:
			continue
		var s := int(o["slot"])
		var c: Color = party_colors[s] if s >= 0 and s < party_colors.size() else ORB_NEUTRAL
		var pos := Vector2(x, gy - float(o["h"]) + sin(_anim_t * 6.0 + i) * 4.0)
		w.draw_circle(pos, 24, Color(c, 0.25))
		w.draw_circle(pos, 15, c)
		w.draw_circle(pos + Vector2(-4, -4), 5, Color(1, 1, 1, 0.8))


func slot_rect(i: int) -> Rect2:
	var n := party.size()
	var x0 := VIEW.x - 40.0 - n * SLOT_ICON - (n - 1) * SLOT_GAP
	return Rect2(x0 + i * (SLOT_ICON + SLOT_GAP), 36, SLOT_ICON, SLOT_ICON)


func _draw_hud() -> void:
	var h := _hud
	var font := ThemeDB.fallback_font
	# HP + Fever (góc trên trái, cạnh nút tạm dừng).
	var bar := Rect2(200, 44, 560, 36)
	h.draw_rect(bar, HudTheme.COLOR_BAR_BACK)
	var hp_k := float(sim.hp) / rules.hp_max
	h.draw_rect(Rect2(bar.position, Vector2(bar.size.x * hp_k, bar.size.y)), HudTheme.COLOR_HP if hp_k > 0.3 else HudTheme.COLOR_HP_LOW)
	h.draw_string_outline(font, bar.position + Vector2(12, 28), "HP %d" % sim.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color.BLACK)
	h.draw_string(font, bar.position + Vector2(12, 28), "HP %d" % sim.hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	var fb := Rect2(200, 92, 560, 18)
	h.draw_rect(fb, HudTheme.COLOR_BAR_BACK)
	var fk := sim.fever_time / rules.fever_duration if sim.fever_active() else sim.fever / rules.fever_max
	h.draw_rect(Rect2(fb.position, Vector2(fb.size.x * fk, fb.size.y)), Color("#FF5FA8"))
	h.draw_string(font, fb.position + Vector2(0, 50), tr("RUNNER_FEVER_LABEL"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.7))
	# Quãng đường (giữa trên) + điểm + combo.
	var pr := Rect2(800, 52, 420, 16)
	h.draw_rect(pr, HudTheme.COLOR_BAR_BACK)
	if _boss:
		# Thanh HP boss = quãng đường còn lại.
		var left := 1.0 - sim.progress_ratio()
		h.draw_rect(Rect2(pr.position + Vector2(pr.size.x * (1.0 - left), 0), Vector2(pr.size.x * left, pr.size.y)), Color("#FF5F7A"))
		_text(h, font, pr.position + Vector2(0, -8), tr("RUNNER_BOSS_NAME"), 24, Color("#FFB3C1"), pr.size.x)
	else:
		h.draw_rect(Rect2(pr.position, Vector2(pr.size.x * sim.progress_ratio(), pr.size.y)), Color("#7FE8FF"))
		h.draw_circle(pr.position + Vector2(pr.size.x * sim.progress_ratio(), 8), 14, Color.WHITE)
	_text(h, font, Vector2(800, 128), "%d" % sim.score, 48, Color.WHITE, 420)
	if sim.combo >= 3:
		_text(h, font, Vector2(800, 182), tr("RUNNER_COMBO") % sim.combo, 34, Color("#FFD84D"), 420)
	# Biểu tượng đội (góc trên phải).
	for i in party.size():
		var r := slot_rect(i)
		var active := i == sim.slot
		h.draw_rect(r, Color(0.05, 0.04, 0.12, 0.85))
		var tex := party_faces[i]
		if tex:
			h.draw_texture_rect(tex, r.grow(-8), false, Color(1, 1, 1, 1.0 if active else 0.45))
		h.draw_rect(r, party_colors[i] if active else Color(party_colors[i], 0.5), false, 8.0 if active else 3.0)
		h.draw_circle(r.position + Vector2(r.size.x - 24, 24), 22, Color(0.05, 0.03, 0.12, 0.9))
		draw_slot_symbol(h, i, r.position + Vector2(r.size.x - 24, 24), 12.0, Color.WHITE, 4.0)
		_text(h, font, r.position + Vector2(0, r.size.y + 30), str(i + 1), 26, Color(1, 1, 1, 0.7), r.size.x)
	# Đếm ngược.
	if phase in ["countdown", "resume"]:
		_text(h, font, Vector2(0, 520), str(ceili(timer)), 160, Color.WHITE, VIEW.x)
	for p in _popups:
		var k := float(p["t"]) / POPUP_SEC
		var pos := p["pos"] as Vector2
		_text(h, font, pos - Vector2(300, 0), str(p["text"]), int(p["size"]), Color(p["color"], clampf(k * 2.0, 0.0, 1.0)), 600)


func _text(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, col: Color, width: float) -> void:
	ci.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, maxi(size / 7, 4), Color(0.05, 0.02, 0.12, col.a))
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)
