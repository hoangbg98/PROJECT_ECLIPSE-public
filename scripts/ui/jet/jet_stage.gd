class_name JetStage
extends MinigameStage
## Màn chơi Bay Nguyên Tố (M11-5, docs/design/JET_MODE.md). Luật ở `JetSim` (bước cố định 1/120 s qua `FixedStep`);
## màn này đọc nút giữ, vẽ theo state, HUD, biểu ngữ vùng, đếm ngược, tạm dừng rồi trả `MinigameResult`.
##
## params (data/events/material_events.json): level.id (ải), guide.intro_key; Vô tận: endless {zone, scroll_base,
## scroll_ramp} + seed. Level có `boss`: Vầng Khuyết mép phải, Van Sét / Cặn Phóng của boss hiện khi bị ném ra.
## Phím: giữ Space / W / ↑ (InputRouter `jet_hold`); cảm ứng: giữ bất kỳ đâu trừ nút tạm dừng.
## Hình: ảnh trong assets/jet/ qua `JetArt` (nền 4 lớp theo vùng, Bộ Phụt + lửa, Rồng, Robo, vật cản, vật phẩm).

const BACK_GROUP := &"back_interceptor"
const RULES_PATH := "res://data/jet/jet_rules.tres"
const VIEW := Vector2(1920, 1080)
const OBSTACLE := Color("#B48CFF")
const OBSTACLE_GLOW := Color("#7C5CFF")
const ORB := Color("#BFF3FF")
const CORE := Color("#6FD3FF")
const BOX := Color("#FF9BD8")
const WARN := Color("#FF6A6A")
const CHAR_SCALE := 0.45
## Chân nhân vật vẽ thấp hơn tâm vòng va chạm chừng này (px) để thân hình trùng chỗ va chạm thật; sàn / trần vẽ dịch
## theo (VISUAL_FLOOR / VISUAL_CEIL) để lúc chạy đất chân vẫn chạm sàn.
const FEET_BELOW := 48.0
const VISUAL_FLOOR := 16.0
const VISUAL_CEIL := -40.0
const RESUME_SEC := 1.5
const POPUP_SEC := 0.8
const BOSS_DIR := "res://assets/rhythm/rh_boss_eclipse/%s/rh_boss_eclipse_%s_%03d.png"
const BOSS_ANIMS := [["idle", 8, 10.0, true], ["throw", 6, 14.0, false], ["hurt", 3, 12.0, false], ["defeat", 10, 16.0, false]]
## Vành boss tô cyan (phân biệt với bản Nhịp điệu, mục 8).
const BOSS_TINT := Color("#9FF0FF")

# --- Nền theo vùng (ảnh 1920 px, lặp ngang): tốc độ cuộn so với quãng bay, mặt sàn ở hàng 6, đường trần ở hàng 100.
const FAR_SCROLL := 0.2
const MID_SCROLL := 0.4
## Lớp mid làm tối để đảo / trụ đá nền không bị nhầm là bệ đứng được.
const MID_TINT := Color(0.78, 0.78, 0.78, 1.0)
const FLOOR_SURFACE_ROW := 6.0
const CEILING_LINE_ROW := 100.0
const ZONE_FADE_SEC := 1.2

# --- Bộ Phụt (ảnh 128x128): tâm hai bình, vòi phụt, khe đo mức nạp.
const PACK_SCALE := 0.5
const PACK_ANCHOR := Vector2(48, 60)
const PACK_ON_BACK := Vector2(-32, 4)
const PACK_NOZZLE := Vector2(44, 112)
const PACK_GAUGE := Rect2(41, 48, 8, 35)
const FLAME_SCALE := 0.6
const FLAME_TOP := Vector2(32, 0)

# --- Rồng (ảnh 512x384, tâm khung = tâm va chạm) và Robo (ảnh 384x384, chân ở hàng 346, tâm ngang giữa khung).
const DRAGON_SCALE := 0.58
const DRAGON_CENTER := Vector2(256, 192)
const DRAGON_SEAT_X := 288.0
## Đỉnh yên theo từng frame bay (đo từ ảnh): người ngồi ở đây.
const DRAGON_SEAT_Y := [206.0, 200.0, 177.0, 169.0, 182.0, 203.0]
const ROBO_SCALE := 0.66
const ROBO_FEET := Vector2(192, 346)
const ROBO_SEAT := Vector2(186, 146)

# --- Vật cản, vật phẩm.
const NODE_SCALE := 0.6
const BEAM_THICK_ART := 40.0
const SWEEP_ART := Vector2(48, 288)
const LIP_ART := Vector2(128, 48)
## Thân nắp mép (hàng 0–34 của ảnh) nằm trên cột; tia lửa (hàng 34–46) nhô ra phía khe.
const LIP_BODY_ROWS := 34.0
const ORB_SCALE := 0.8
const ORB_CENTER_ART := Vector2(35, 29.5)
const CORE_SCALE := 0.55
const BOX_SCALE := 0.65
const BOX_CENTER_ART := Vector2(64.5, 68)
const MISSILE_SCALE := 1.15
const WARN_SCALE := 0.55
const WIND_ARROW_SCALE := 0.8

var rules: JetRules
var level: JetLevel
var sim: JetSim
var fixed := FixedStep.new()
## "load" | "countdown" | "play" | "resume" | "done" | "error"
var phase := "load"
var paused := false
var timer := 0.0
var manual_clock := false
var load_error := ""
var element_color := Color.WHITE
## Test: ép trạng thái giữ (bỏ qua bàn phím / chạm).
var forced_hold: Variant = null

var _world: Control
var _hud: Control
var _sprite: AnimatedSprite2D
var _boss: AnimatedSprite2D
var _throw_x := INF
var _boss_next := 0
var _pause_layer: Control
var _intro: Label
var _hold_keys := 0
var _touches: Dictionary = {}
var _play_emitted := false
var _done := false
var _popups: Array[Dictionary] = []
var _anim_t := 0.0
var _banner_t := 0.0
var _banner_zone := ""
var _sky_from: Array = [Color("#1E1416"), Color("#4A2A24")]
var _sky_to: Array = [Color("#1E1416"), Color("#4A2A24")]
var _sky_k := 1.0
var _zone_from := ""
var _zone_to := ""
var _form_sprite: AnimatedSprite2D
var _form_shown := ""
var _robo_jump_at := -10.0
var _robo_land_at := -10.0
var _robo_crush_at := -10.0
var _fx: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(BACK_GROUP)


func _p(path: String, def: Variant) -> Variant:
	return MinigameRegistry.param(ctx.params, path, def) if ctx else def


func start() -> void:
	rules = load(RULES_PATH) as JetRules
	var endless: Variant = _p("endless", null)
	if endless is Dictionary:
		var cfg: Dictionary = (endless as Dictionary).duplicate(true)
		cfg["level_id"] = ctx.stage_id if ctx else "endless"
		level = JetLevel.endless(int(_p("seed", 1)), cfg, str(cfg.get("zone", "")))
	else:
		level = JetLevel.load_id(str(_p("level.id", "jet_mat_01")))
	if rules == null or not level.is_valid():
		load_error = "; ".join(level.errors) if level else "rules"
		push_error("JetStage: " + load_error)
		_build_error()
		return
	var party := ctx.party if ctx and not ctx.party.is_empty() else PackedStringArray(["char_fire_01"])
	var def := CharacterArt.def_of(party[0])
	element_color = HudTheme.ring_color(def.element if def else "")
	sim = JetSim.new(rules, level)
	_build(party[0])
	_set_sky(sim.zone, true)
	phase = "countdown"
	timer = rules.countdown_sec
	var intro_key := str(_p("guide.intro_key", ""))
	if intro_key != "" and ctx and ctx.is_first_play:
		_intro.text = tr(intro_key)
	_show_banner(sim.zone)


# ---------------------------------------------------------------- dựng

func _build(char_id: String) -> void:
	_world = Control.new()
	_world.name = "World"
	_world.set_anchors_preset(Control.PRESET_FULL_RECT)
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.draw.connect(_draw_world)
	add_child(_world)
	if level.boss is Dictionary:
		_build_boss(level.boss)
	_form_sprite = AnimatedSprite2D.new()
	_form_sprite.name = "FormSprite"
	_form_sprite.visible = false
	add_child(_form_sprite)
	var built := AnimationSetBuilder.build_for_character(char_id)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Character"
	_sprite.sprite_frames = built.sprite_frames
	_sprite.offset = built.sprite_offset
	_sprite.scale = Vector2.ONE * CHAR_SCALE
	add_child(_sprite)
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
	_intro.position = Vector2(260, 640)
	_intro.size = Vector2(1400, 160)
	_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_intro.add_theme_font_size_override("font_size", 36)
	_intro.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.12))
	_intro.add_theme_constant_override("outline_size", 8)
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intro)
	_update_character()


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
	_boss.position = Vector2(_throw_x + 110.0, 470.0)
	_boss.scale = Vector2.ONE * 0.6
	_boss.animation_finished.connect(func() -> void:
		if _boss.animation != &"defeat":
			_boss.play(&"idle"))
	add_child(_boss)
	_boss.play(&"idle")


func _build_error() -> void:
	phase = "error"
	var bg := ColorRect.new()
	bg.color = Color("#12102A")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var l := Label.new()
	l.text = tr("JET_LOAD_ERROR") + "\n\n" + tr("EVENT_BACK_HINT")
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 40)
	add_child(l)


# ---------------------------------------------------------------- vòng lặp

func _process(delta: float) -> void:
	if not manual_clock:
		advance(delta)


func holding() -> bool:
	if forced_hold != null:
		return bool(forced_hold)
	return _hold_keys > 0 or not _touches.is_empty()


## Chạy màn thêm `delta` giây (test gọi trực tiếp với manual_clock = true).
func advance(delta: float) -> void:
	if sim == null or paused or phase in ["done", "error", "load"]:
		return
	_anim_t += delta
	match phase:
		"countdown", "resume":
			timer -= delta
			if timer <= 0.0:
				_begin_play()
		"play":
			var n := fixed.advance(delta)
			var h := holding()
			for i in n:
				sim.step(fixed.step, h)
				_handle_events(sim.take_events())
				if sim.finished:
					break
	_banner_t = maxf(_banner_t - delta, 0.0)
	_sky_k = minf(_sky_k + delta / ZONE_FADE_SEC, 1.0)
	_tick_popups(delta)
	_update_form()
	_update_character()
	_update_fx()
	_update_boss()
	_world.queue_redraw()
	_hud.queue_redraw()
	if sim.finished and phase == "play":
		_finish()


func _begin_play() -> void:
	phase = "play"
	_intro.text = ""
	fixed.reset()
	if not _play_emitted:
		_play_emitted = true
		play_started.emit()


func _handle_events(evs: Array[Dictionary]) -> void:
	var px := Vector2(rules.player_x, sim.y - 120.0)
	for e in evs:
		match str(e["kind"]):
			"zone":
				_set_sky(str(e["zone"]), false)
				_show_banner(str(e["zone"]))
			"form":
				_popup(tr("JET_FORM_%s_PICK" % str(e["form"]).to_upper()), BOX, px, 40)
			"form_break":
				_spawn_form_break(str(e["form"]))
				_popup(tr("JET_FORM_%s_BREAK" % str(e["form"]).to_upper()), WARN, px, 40)
			"form_end":
				_spawn_form_break(str(e["form"]))
				_popup(tr("JET_FORM_END"), Color.WHITE, px, 32)
			"hit":
				_popup("-1 ♥", WARN, px + Vector2(120, 0), 44)
			"core":
				_popup("+%d" % int(rules.core_gain), CORE, px + Vector2(80, 0), 34)
			"crush":
				_robo_crush_at = _anim_t
				_popup("+%d" % rules.robo_crush_orbs, ORB, px + Vector2(120, -20), 32)
			"jump":
				_robo_jump_at = _anim_t
			"land":
				_robo_land_at = _anim_t
			"launch":
				if _boss and bool(e.get("from_boss", false)):
					_boss.play(&"throw")


func _finish() -> void:
	if _done:
		return
	_done = true
	phase = "done"
	finished.emit(sim.result())


func _set_sky(zone_id: String, instant: bool) -> void:
	var z := JetLevel.zone_def(zone_id)
	var sky: Array = z.get("sky", ["#1E1416", "#4A2A24"])
	_sky_from = [_sky_color(0), _sky_color(1)] if not instant else [Color(sky[0]), Color(sky[1])]
	_sky_to = [Color(sky[0]), Color(sky[1])]
	_sky_k = 1.0 if instant else 0.0
	_zone_from = zone_id if instant else _zone_to
	_zone_to = zone_id


func _sky_color(i: int) -> Color:
	return (_sky_from[i] as Color).lerp(_sky_to[i] as Color, _sky_k)


func _show_banner(zone_id: String) -> void:
	_banner_zone = zone_id
	_banner_t = rules.zone_banner_sec


# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
	if sim == null or phase in ["done", "error"] or event.is_echo():
		return
	if event.is_action_pressed(&"pause"):
		set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"jet_hold"):
		_hold_keys += 1
	elif event.is_action_released(&"jet_hold"):
		_hold_keys = maxi(_hold_keys - 1, 0)
	elif event is InputEventScreenTouch:
		touch((event as InputEventScreenTouch).index, (event as InputEventScreenTouch).position,
				(event as InputEventScreenTouch).pressed)


## Chạm (khung 1920×1080): giữ bất kỳ đâu trừ nút tạm dừng.
func touch(index: int, pos: Vector2, pressed: bool) -> void:
	if not pressed:
		_touches.erase(index)
		return
	var pause_rect := Rect2(HudTheme.ACTIVE_CARD_POS, Vector2.ONE * HudTheme.PAUSE_BUTTON_SIZE)
	if pause_rect.grow(10).has_point(pos):
		return
	_touches[index] = true


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
	# Bỏ trạng thái giữ cũ (mục 2).
	_hold_keys = 0
	_touches.clear()
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


func _update_character() -> void:
	var rider := "idle" if phase == "countdown" else ""
	if sim.form != "":
		rider = "idle"
	if rider != "":
		_play_anim(rider)
	elif sim.hurt_timer > 0.0:
		_play_anim("hurt")
	elif sim.on_ground:
		_play_anim("run")
	else:
		_play_anim("jump_up" if sim.vy < 0.0 else "fall", "jump_up")
	_sprite.position = _rider_position()
	var blink := sim.invuln > 0.0 and fmod(sim.invuln, 0.16) < 0.08
	_sprite.modulate = Color(1, 1, 1, 0.45 if blink else 1.0)


## Chân người bay: đứng sàn / giữa không trung; ngồi yên Rồng; ngồi buồng lái Robo.
func _rider_position() -> Vector2:
	match sim.form:
		"dragon":
			var i := clampi(_form_sprite.frame, 0, DRAGON_SEAT_Y.size() - 1) if _form_sprite.animation == &"fly" else 0
			return Vector2(rules.player_x, sim.y) + Vector2(DRAGON_SEAT_X - DRAGON_CENTER.x, float(DRAGON_SEAT_Y[i]) - DRAGON_CENTER.y) * DRAGON_SCALE
		"robo":
			return _robo_origin() + (ROBO_SEAT - ROBO_FEET) * ROBO_SCALE
	return Vector2(rules.player_x, sim.y + FEET_BELOW)


## Gốc (bàn chân, giữa khung) của sprite Robo: chân chạm mặt sàn vẽ khi Robo đứng đất.
func _robo_origin() -> Vector2:
	return Vector2(rules.player_x, sim.y + rules.robo_radius + VISUAL_FLOOR)


## Sprite Rồng / Robo theo hình đang mang; chọn animation theo trạng thái.
func _update_form() -> void:
	if _form_sprite == null:
		return
	var f := sim.form
	_form_sprite.visible = f != ""
	if f == "":
		_form_shown = ""
		return
	if f != _form_shown:
		_form_shown = f
		_form_sprite.sprite_frames = JetArt.form_frames(f)
		if f == "dragon":
			_form_sprite.centered = true
			_form_sprite.offset = Vector2.ZERO
			_form_sprite.scale = Vector2.ONE * DRAGON_SCALE
			_form_sprite.animation = &"fly"
			_form_sprite.play(&"fly")
		else:
			_form_sprite.centered = false
			_form_sprite.offset = -ROBO_FEET
			_form_sprite.scale = Vector2.ONE * ROBO_SCALE
			_form_sprite.animation = &"walk"
			_form_sprite.play(&"walk")
	if f == "dragon":
		_form_sprite.position = Vector2(rules.player_x, sim.y)
		if not _form_sprite.is_playing():
			_form_sprite.play(&"fly")
	else:
		_form_sprite.position = _robo_origin()
		var since_crush := _anim_t - _robo_crush_at
		if since_crush < 0.2:
			_set_robo_pose("crush", clampi(int(since_crush * 20.0), 0, 3))
		elif not sim.on_ground:
			_set_robo_pose("jump", 0 if _anim_t - _robo_jump_at < 0.08 else 1)
		elif _anim_t - _robo_land_at < 0.1:
			_set_robo_pose("jump", 2)
		elif _form_sprite.animation != &"walk" or not _form_sprite.is_playing():
			_form_sprite.play(&"walk")
	var blink := sim.invuln > 0.0 and fmod(sim.invuln, 0.16) < 0.08
	_form_sprite.modulate = Color(1, 1, 1, 0.55 if blink else 1.0)


func _set_robo_pose(anim: String, idx: int) -> void:
	if _form_sprite.animation != StringName(anim):
		_form_sprite.animation = StringName(anim)
	_form_sprite.pause()
	_form_sprite.frame = idx


## Hiệu ứng một lần gắn với toạ độ thế giới (trôi trái theo cuộn): Rồng / Robo vỡ, Hộp Ký Ức mở.
func _spawn_fx(sf: SpriteFrames, anim: String, world_x: float, pos_y: float, scale_: float, centered_: bool, off: Vector2) -> void:
	if sf == null or not sf.has_animation(anim):
		return
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.centered = centered_
	s.offset = off
	s.scale = Vector2.ONE * scale_
	add_child(s)
	if _sprite:
		move_child(s, _sprite.get_index())
	s.animation_finished.connect(func() -> void: s.queue_free())
	s.play(anim)
	_fx.append({"node": s, "wx": world_x, "y": pos_y})
	_update_fx()


func _spawn_form_break(form: String) -> void:
	if form == "dragon":
		_spawn_fx(JetArt.form_frames("dragon"), "break", sim.dist, sim.y, DRAGON_SCALE, true, Vector2.ZERO)
	elif form == "robo":
		_spawn_fx(JetArt.form_frames("robo"), "break", sim.dist, sim.y + rules.robo_radius + VISUAL_FLOOR, ROBO_SCALE, false, -ROBO_FEET)


func _update_fx() -> void:
	var keep: Array[Dictionary] = []
	for f in _fx:
		var n: Variant = f["node"]
		if not is_instance_valid(n) or (n as Node).is_queued_for_deletion():
			continue
		(n as AnimatedSprite2D).position = Vector2(rules.player_x + float(f["wx"]) - sim.dist, float(f["y"]))
		keep.append(f)
	_fx = keep


func _update_boss() -> void:
	if _boss == null:
		return
	# Van Sét của boss: vung tay khi van đi qua chỗ ném.
	while _boss_next < level.events.size() and sim.screen_x(float(level.events[_boss_next]["x"])) <= _throw_x:
		var e: Dictionary = level.events[_boss_next]
		if e["type"] == "gate" and bool(e.get("from_boss", false)) and _boss.animation != &"defeat":
			_boss.play(&"throw")
		_boss_next += 1
	if sim.finished and sim.cleared and _boss.animation != &"defeat":
		_boss.play(&"defeat")


func _popup(text: String, col: Color, pos: Vector2, size: int) -> void:
	_popups.append({"text": text, "color": col, "pos": pos, "size": size, "t": POPUP_SEC})


func _tick_popups(delta: float) -> void:
	for p in _popups:
		p["t"] = float(p["t"]) - delta
		p["pos"] = (p["pos"] as Vector2) + Vector2(0, -60 * delta)
	_popups = _popups.filter(func(p: Dictionary) -> bool: return float(p["t"]) > 0.0)


func _draw_world() -> void:
	var w := _world
	var top := _sky_color(0)
	var bot := _sky_color(1)
	for i in 12:
		w.draw_rect(Rect2(0, VIEW.y * i / 12.0, VIEW.x, VIEW.y / 12.0 + 1), top.lerp(bot, i / 11.0))
	var ceil_y := rules.ceiling_y + VISUAL_CEIL
	var floor_y := rules.floor_y + VISUAL_FLOOR
	_draw_zone_layer(w, "far", 0.0, sim.dist * FAR_SCROLL, Color.WHITE)
	_draw_zone_layer(w, "mid", 0.0, sim.dist * MID_SCROLL, MID_TINT)
	_draw_zone_layer(w, "ceiling", ceil_y - CEILING_LINE_ROW, sim.dist, Color.WHITE)
	_draw_zone_layer(w, "floor", floor_y - FLOOR_SURFACE_ROW, sim.dist, Color.WHITE)
	if _boss:
		# Vành cyan quanh Vầng Khuyết (phân biệt bản Nhịp điệu, mục 8).
		var bc := _boss.position
		w.draw_arc(bc, 230.0 + sin(_anim_t * 3.0) * 8.0, 0, TAU, 64, Color(BOSS_TINT, 0.55), 14.0)
		w.draw_arc(bc, 260.0, 0, TAU, 64, Color(BOSS_TINT, 0.18), 30.0)
	_draw_wind(w)
	_draw_events(w)
	_draw_missiles(w)
	_draw_player_layer(w)


## Một lớp nền của vùng hiện tại; khi đang chuyển vùng thì vẽ vùng cũ rồi phủ vùng mới với độ mờ tăng dần.
func _draw_zone_layer(w: Control, kind: String, y: float, scroll: float, tint: Color) -> void:
	if _sky_k < 1.0 and _zone_from != "" and _zone_from != _zone_to:
		_draw_tiled(w, JetArt.zone_tex(kind, _zone_from), y, scroll, tint)
		_draw_tiled(w, JetArt.zone_tex(kind, _zone_to), y, scroll, Color(tint, _sky_k * tint.a))
	else:
		_draw_tiled(w, JetArt.zone_tex(kind, _zone_to), y, scroll, tint)


func _draw_tiled(w: Control, t: Texture2D, y: float, scroll: float, tint: Color) -> void:
	if t == null:
		return
	var tw := float(t.get_width())
	var x := -fposmod(scroll, tw)
	while x < VIEW.x:
		w.draw_texture(t, Vector2(x, y), tint)
		x += tw


func _draw_wind(w: Control) -> void:
	var wind := level.wind_soon_px(sim.dist, 0.2 * sim.scroll(), rules)
	var t := JetArt.tex("jet_wind_arrow.png")
	if wind == 0.0 or t == null:
		return
	var active := level.wind_at_px(sim.dist, rules) != 0.0
	var down := wind > 0.0
	var tint := Color(1, 1, 1, 0.6 if active else 0.28)
	var half := Vector2(t.get_width(), t.get_height()) * 0.5
	for i in 5:
		var x := 360.0 + i * 340.0 - fmod(sim.dist * 0.5, 340.0)
		var y0 := 500.0 + sin(_anim_t * 3.0 + i) * 40.0
		# Ảnh mũi tên chỉ LÊN; gió xuống thì xoay 180 độ.
		w.draw_set_transform(Vector2(x, y0), PI if down else 0.0, Vector2.ONE * WIND_ARROW_SCALE)
		w.draw_texture(t, -half, tint)
	w.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_events(w: Control) -> void:
	for e in level.events:
		var X := float(e["x"])
		var sx := sim.screen_x(X)
		if sx > VIEW.x + 600.0:
			break
		if sx < -600.0 or bool(e.get("_crushed", false)):
			continue
		var type := str(e["type"])
		if bool(e.get("from_boss", false)) and type == "gate" and sx > _throw_x:
			continue
		match type:
			"beam":
				_draw_beam(w, e, sx - X)
			"swp":
				_draw_sweep(w, e, sx)
			"gate":
				_draw_gate(w, sx, float(e["y"]))
			"orbs":
				var orbs := JetArt.seq("jet_orb", "jet_orb_idle", 4)
				var mask := int(e.get("_taken", 0))
				for k in int(e.get("n", 6)):
					if mask & (1 << k):
						continue
					var p2 := JetSim.orb_pos(e, k, rules) + Vector2(sx - X, 0)
					var ot := JetArt.frame(orbs, 8.0, _anim_t, float(k) * 0.7)
					if ot:
						w.draw_texture_rect(ot, Rect2(p2 - ORB_CENTER_ART * ORB_SCALE, ot.get_size() * ORB_SCALE), false)
			"core":
				if not bool(e.get("_done", false)):
					var ct := JetArt.frame(JetArt.seq("jet_core", "jet_core_idle", 6), 10.0, _anim_t)
					if ct:
						var c := Vector2(sx, float(e["y"]) + sin(_anim_t * 4.0) * 6.0)
						w.draw_texture_rect(ct, Rect2(c - ct.get_size() * 0.5 * CORE_SCALE, ct.get_size() * CORE_SCALE), false)
			"box":
				var bpos := Vector2(sx, float(e["y"]) + sin(_anim_t * 3.0) * 8.0)
				if not bool(e.get("_done", false)):
					var bt := JetArt.frame(JetArt.seq("jet_box", "jet_box_idle", 6), 10.0, _anim_t)
					if bt:
						w.draw_texture_rect(bt, Rect2(bpos - BOX_CENTER_ART * BOX_SCALE, bt.get_size() * BOX_SCALE), false)
				elif not e.has("_fx") and absf(sx - rules.player_x) < 160.0:
					# Vừa nhặt: hộp mở ra một lần.
					e["_fx"] = true
					var sf := SpriteFrames.new()
					sf.remove_animation(&"default")
					sf.add_animation("open")
					sf.set_animation_speed("open", 20.0)
					sf.set_animation_loop("open", false)
					for t in JetArt.seq("jet_box", "jet_box_open", 6):
						sf.add_frame("open", t)
					_spawn_fx(sf, "open", X, float(e["y"]), BOX_SCALE, false, -BOX_CENTER_ART)


## Thanh Cặn: thân lặp dọc theo đoạn (xoay theo góc) + hai nút Cặn ở hai đầu.
func _draw_beam(w: Control, e: Dictionary, shift_x: float) -> void:
	var ends := JetSim.beam_ends(e)
	var a: Vector2 = ends[0] + Vector2(shift_x, 0)
	var b: Vector2 = ends[1] + Vector2(shift_x, 0)
	var body := JetArt.tex("jet_beam_body_v2.png")
	if body:
		var length := a.distance_to(b)
		# beam_ends dùng hướng (cos, -sin) của góc, nên xoay màn hình = -góc.
		w.draw_set_transform((a + b) * 0.5, -deg_to_rad(float(e.get("ang", 0.0))), Vector2.ONE)
		w.draw_texture_rect(body, Rect2(-length * 0.5, -BEAM_THICK_ART * 0.5, length, BEAM_THICK_ART), true)
		w.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var nodes := JetArt.seq("jet_beam_node/pulse", "jet_beam_node_pulse", 4)
	for p in [a, b]:
		var nt := JetArt.frame(nodes, 10.0, _anim_t, float(e.get("y", 0)) * 0.01)
		if nt:
			w.draw_texture_rect(nt, Rect2(p - nt.get_size() * 0.5 * NODE_SCALE, nt.get_size() * NODE_SCALE), false)


## Tia Quét: đường chỉ lối biên độ + quầng vàng + ảnh tia (3 frame rung).
func _draw_sweep(w: Control, e: Dictionary, sx: float) -> void:
	var sy := JetSim.sweep_y(e, sim.dist)
	var amp := float(e.get("amp", 200.0))
	w.draw_line(Vector2(sx, float(e["y"]) - amp - rules.sweep_half), Vector2(sx, float(e["y"]) + amp + rules.sweep_half),
			Color(1, 0.95, 0.4, 0.12), 4.0)
	w.draw_line(Vector2(sx, sy - rules.sweep_half), Vector2(sx, sy + rules.sweep_half), Color("#FFE066", 0.14), rules.obstacle_thickness * 2.8)
	var st := JetArt.frame(JetArt.seq("jet_sweep/hum", "jet_sweep_hum", 3), 18.0, _anim_t, float(e["x"]) * 0.01)
	if st:
		w.draw_texture(st, Vector2(sx, sy) - SWEEP_ART * 0.5)


## Van Sét: hai cột đá tím co về bề rộng thân `gate_width` + nắp mép có tia lửa ở cạnh sát khe.
func _draw_gate(w: Control, sx: float, g: float) -> void:
	var col := JetArt.gate_column(rules.gate_width)
	var lips := JetArt.seq("jet_gate_lip/spark", "jet_gate_lip_spark", 3)
	var lt := JetArt.frame(lips, 18.0, _anim_t, sx * 0.02)
	var k := rules.gate_width / JetArt.GATE_BODY_ART_W
	var lip_w := LIP_ART.x * k
	var lip_h := LIP_ART.y * k
	var body := LIP_BODY_ROWS * k
	var edge_top := g - rules.gate_gap * 0.5
	var edge_bot := g + rules.gate_gap * 0.5
	var ceil_y := rules.ceiling_y + VISUAL_CEIL
	var floor_y := rules.floor_y + VISUAL_FLOOR
	if col:
		var cw := float(col.get_width())
		w.draw_texture_rect(col, Rect2(sx - cw * 0.5, ceil_y, cw, edge_top - body + 4.0 - ceil_y), true)
		w.draw_texture_rect(col, Rect2(sx - cw * 0.5, edge_bot + body - 4.0, cw, floor_y - (edge_bot + body - 4.0)), true)
	if lt:
		w.draw_texture_rect(lt, Rect2(sx - lip_w * 0.5, edge_top - body, lip_w, lip_h), false)
		# Van dưới: lật dọc quanh đường mép khe (tia lửa vẫn hướng ra khe).
		w.draw_set_transform(Vector2(0, 2.0 * edge_bot), 0.0, Vector2(1, -1))
		w.draw_texture_rect(lt, Rect2(sx - lip_w * 0.5, edge_bot - body, lip_w, lip_h), false)
		w.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_missiles(w: Control) -> void:
	var fly := JetArt.seq("jet_missile/fly_v2", "jet_missile_fly_v2", 4)
	var warn := JetArt.seq("jet_missile_warn/blink", "jet_missile_warn_blink", 2)
	for m in sim.missiles:
		var e: Dictionary = m["ev"]
		var my := float(e["y"])
		if m["phase"] == "warn":
			var wt := JetArt.frame(warn, 8.0, _anim_t)
			if wt:
				var c := Vector2(VIEW.x - 70, my)
				w.draw_texture_rect(wt, Rect2(c - wt.get_size() * 0.5 * WARN_SCALE, wt.get_size() * WARN_SCALE), false)
		else:
			var mt := JetArt.frame(fly, 16.0, _anim_t, my * 0.05)
			if mt:
				var sx := float(m["sx"])
				w.draw_texture_rect(mt, Rect2(Vector2(sx, my) - mt.get_size() * 0.5 * MISSILE_SCALE, mt.get_size() * MISSILE_SCALE), false)


## Bộ Phụt sau lưng + khe đo mức nạp + lửa (người thường). Rồng / Robo là sprite riêng nên không vẽ gì ở đây.
func _draw_player_layer(w: Control) -> void:
	if sim.form != "":
		return
	var pack := JetArt.tex("jet_pack.png")
	if pack == null:
		return
	var c := Vector2(rules.player_x, sim.y) + PACK_ON_BACK
	var origin := c - PACK_ANCHOR * PACK_SCALE
	var nozzle := origin + PACK_NOZZLE * PACK_SCALE
	# Lửa sau Bộ Phụt, đầu lửa gắn vào vòi phụt; tô màu nguyên tố của người bay.
	if sim.holding and sim.energy > 0.0:
		var flames := JetArt.flame()
		var ft := JetArt.frame(flames, 24.0, _anim_t)
		if ft:
			var tint := element_color.lerp(Color.WHITE, 0.25)
			w.draw_texture_rect(ft, Rect2(nozzle - FLAME_TOP * FLAME_SCALE, ft.get_size() * FLAME_SCALE), false, tint)
	w.draw_texture_rect(pack, Rect2(origin, pack.get_size() * PACK_SCALE), false)
	# Mức nạp: đổ đầy khe đo từ dưới lên.
	var k := clampf(sim.energy / rules.energy_max, 0.0, 1.0)
	var gauge := PACK_GAUGE
	var fill_h := gauge.size.y * k
	var fill := Rect2(origin + (gauge.position + Vector2(0, gauge.size.y - fill_h)) * PACK_SCALE, Vector2(gauge.size.x, fill_h) * PACK_SCALE)
	w.draw_rect(fill, WARN if k < 0.25 else CORE)


func _draw_hud() -> void:
	var h := _hud
	var font := ThemeDB.fallback_font
	# Tim.
	for i in rules.lives:
		var col := Color("#FF5F7A") if i < sim.lives else Color(1, 1, 1, 0.2)
		_text(h, font, Vector2(200 + i * 56, 92), "♥", 52, col, 56)
	# Năng lượng.
	var bar := Rect2(200, 112, 420, 22)
	h.draw_rect(bar, HudTheme.COLOR_BAR_BACK)
	var ek := sim.energy / rules.energy_max
	h.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ek, bar.size.y)), WARN if ek < 0.25 else CORE)
	h.draw_string(font, bar.position + Vector2(bar.size.x + 12, 20), tr("JET_ENERGY"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.7))
	# Hình + thời gian.
	if sim.form != "":
		var dur := rules.dragon_time if sim.form == "dragon" else rules.robo_time
		var fb := Rect2(262, 146, 358, 14)
		var icon := JetArt.tex("jet_icon_%s.png" % sim.form)
		if icon:
			h.draw_texture_rect(icon, Rect2(200, 126, 52, 52), false)
		h.draw_rect(fb, HudTheme.COLOR_BAR_BACK)
		h.draw_rect(Rect2(fb.position, Vector2(fb.size.x * sim.form_time / dur, fb.size.y)), BOX)
		h.draw_string(font, fb.position + Vector2(fb.size.x + 12, 14), tr("JET_FORM_" + sim.form.to_upper()), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, BOX)
	# Gợi ý thao tác.
	var hint := tr("JET_HINT_TAP") if sim.form == "robo" else tr("JET_HINT_HOLD")
	h.draw_string(font, Vector2(200, 194), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.55))
	# Mét, hạt, tiến độ / thanh boss.
	_text(h, font, Vector2(760, 112), "%d m" % int(sim.meters()), 52, Color.WHITE, 400)
	_text(h, font, Vector2(1160, 112), "◆ %d" % (sim.orbs_taken + sim.bonus_orbs), 40, ORB, 260)
	var pr := Rect2(760, 136, 400, 14)
	h.draw_rect(pr, HudTheme.COLOR_BAR_BACK)
	if _boss:
		var left := 1.0 - sim.progress_ratio()
		h.draw_rect(Rect2(pr.position + Vector2(pr.size.x * (1.0 - left), 0), Vector2(pr.size.x * left, pr.size.y)), Color("#FF5F7A"))
		_text(h, font, pr.position + Vector2(0, 46), tr("RUNNER_BOSS_NAME"), 24, Color("#FFB3C1"), pr.size.x)
	elif level.is_endless():
		var zm := fmod(sim.meters(), level.zone_length_m) / level.zone_length_m
		h.draw_rect(Rect2(pr.position, Vector2(pr.size.x * zm, pr.size.y)), Color(str(JetLevel.zone_def(sim.zone).get("accent", "#FFFFFF"))))
		_text(h, font, pr.position + Vector2(0, 46), tr(str(JetLevel.zone_def(sim.zone).get("title_key", ""))), 24, Color(1, 1, 1, 0.75), pr.size.x)
	else:
		h.draw_rect(Rect2(pr.position, Vector2(pr.size.x * sim.progress_ratio(), pr.size.y)), Color("#7FE8FF"))
	# Biểu ngữ vùng.
	if _banner_t > 0.0:
		var z := JetLevel.zone_def(_banner_zone)
		var a := clampf(minf(_banner_t, rules.zone_banner_sec - _banner_t) * 3.0, 0.0, 1.0)
		var ac := Color(str(z.get("accent", "#FFFFFF")))
		h.draw_rect(Rect2(0, 300, VIEW.x, 150), Color(0, 0, 0, 0.45 * a))
		_text(h, font, Vector2(0, 372), tr(str(z.get("title_key", ""))), 64, Color(ac, a), VIEW.x)
		_text(h, font, Vector2(0, 424), tr(str(z.get("rule_key", ""))), 30, Color(1, 1, 1, a), VIEW.x)
	if phase in ["countdown", "resume"]:
		_text(h, font, Vector2(0, 600), str(ceili(timer)), 160, Color.WHITE, VIEW.x)
	for p in _popups:
		var k := float(p["t"]) / POPUP_SEC
		_text(h, font, (p["pos"] as Vector2) - Vector2(300, 0), str(p["text"]), int(p["size"]), Color(p["color"], clampf(k * 2.0, 0.0, 1.0)), 600)


func _text(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, col: Color, width: float) -> void:
	ci.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, maxi(size / 7, 4), Color(0.05, 0.02, 0.12, col.a))
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, col)
