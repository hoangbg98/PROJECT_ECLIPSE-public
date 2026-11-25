class_name RhythmMinigameAdapter
extends MinigameStage
## Bọc RhythmStage vào khung Event nguyên liệu (docs/design/MATERIAL_EVENT.md mục 9.2). Luật Nhịp điệu không đổi:
## adapter tải bài (nếu chưa có), đặt tham số từ `ctx.params`, chạy RhythmStage ở chế độ nhúng (không ghi save, không
## thưởng, không màn kết quả riêng) rồi đổi kết quả sang MinigameResult.
##
## params (data/events/material_events.json, docs/design/EVENT_DATA_GUIDE.md): music.song, music.chart,
## speed.note_speed, speed.song_speed, spawn.density, spawn.min_gap_sec, spawn.kinds, guide.tutorial, guide.intro_key, boss.
## Hướng dẫn / giới thiệu chỉ hiện khi `ctx.is_first_play`.

const STAGE_SCENE := "res://scenes/main/rhythm_stage.tscn"

var stage: RhythmStage
var library: RhythmLibrary
## Test: chạy RhythmStage bằng đồng hồ tay / tự chơi, hồ sơ riêng.
var manual_clock := false
var autoplay := false
var profile: PlayerProfile

var _status: Label
var _play_emitted := false
var _done := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func start() -> void:
	_status = Label.new()
	_status.name = "Status"
	_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 40)
	add_child(_status)
	var bg := ColorRect.new()
	bg.color = Color("#141029")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	_status.add_child(bg)
	if library == null:
		library = RhythmLibrary.create(self)
	var song := str(_p("music.song", ""))
	var chart := str(_p("music.chart", ""))
	_status.text = tr("RHYTHM_CATALOG_LOADING")
	await library.refresh_catalog()
	if not is_inside_tree():
		return
	if library.song(song).is_empty():
		_fail(tr("RHYTHM_CATALOG_NONE"))
		return
	if not library.is_cached(song, chart):
		_status.text = tr("RHYTHM_DOWNLOADING") % (float(library.missing_bytes(song, chart)) / 1048576.0)
		var res: Dictionary = await library.ensure(song, chart)
		if not is_inside_tree():
			return
		if not bool(res.get("ok", false)):
			_fail(tr("RHYTHM_DOWNLOAD_FAILED") % str(res.get("error", "")))
			return
	_launch()


func _p(path: String, def: Variant) -> Variant:
	return MinigameRegistry.param(ctx.params, path, def)


func _fail(text: String) -> void:
	_status.text = text + "\n\n" + tr("EVENT_BACK_HINT")
	var b := Button.new()
	b.name = "QuitButton"
	b.text = tr("RHYTHM_QUIT")
	b.position = Vector2(780, 760)
	b.size = Vector2(360, 128)
	b.add_theme_font_size_override("font_size", 38)
	b.pressed.connect(func() -> void: quit_requested.emit())
	add_child(b)


func _launch() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.rhythm_song_id = str(_p("music.song", ""))
		gc.rhythm_chart_key = str(_p("music.chart", ""))
		gc.rhythm_record_key = ""
		gc.rhythm_boss = bool(_p("boss", false))
		gc.rhythm_note_speed = float(_p("speed.note_speed", 0.0))
		gc.rhythm_song_speed = float(_p("speed.song_speed", 1.0))
		gc.rhythm_density = float(_p("spawn.density", 1.0))
		gc.rhythm_min_gap = float(_p("spawn.min_gap_sec", 0.0))
		gc.rhythm_tutorial = ctx.is_first_play and bool(_p("guide.tutorial", false))
		gc.rhythm_intro_key = str(_p("guide.intro_key", "")) if ctx.is_first_play else ""
		gc.rhythm_kinds = (_p("spawn.kinds", []) as Array).duplicate()
	if _status:
		_status.queue_free()
		_status = null
	attach((load(STAGE_SCENE) as PackedScene).instantiate() as RhythmStage)


## Gắn một RhythmStage (chưa vào cây) ở chế độ nhúng. Test gọi trực tiếp với màn đã `setup()`.
func attach(s: RhythmStage) -> void:
	stage = s
	stage.embedded = true
	stage.save_enabled = false
	stage.manual_clock = stage.manual_clock or manual_clock
	stage.autoplay = stage.autoplay or autoplay
	if profile:
		stage.profile = profile
	stage.finished.connect(_on_stage_finished)
	stage.retry_requested.connect(func() -> void: retry_requested.emit())
	stage.quit_requested.connect(_on_stage_quit)
	add_child(stage)


func _process(_delta: float) -> void:
	poll()


## Phát `play_started` khi bài thật bắt đầu (qua hướng dẫn và đếm ngược).
func poll() -> void:
	if _play_emitted or stage == null or stage.load_error != "":
		return
	if stage.phase == "play" and stage.now >= 0.0:
		_play_emitted = true
		play_started.emit()


func _on_stage_finished(r: Dictionary) -> void:
	if _done:
		return
	poll()
	_done = true
	finished.emit(to_result(r, stage))


func _on_stage_quit() -> void:
	if _done:
		return
	if _play_emitted and stage and stage.result.is_empty():
		_done = true
		finished.emit(MinigameResult.quit_result(maxf(stage.now, 0.0)))
	else:
		quit_requested.emit()


func pause_game() -> void:
	if stage:
		stage.set_paused(true)


func resume_game() -> void:
	if stage:
		stage.set_paused(false)


## Đổi kết quả RhythmStage sang MinigameResult (khóa stats: MinigameRegistry.STATS_KEYS["rhythm"]).
static func to_result(r: Dictionary, s: RhythmStage = null) -> MinigameResult:
	var m := MinigameResult.new()
	m.cleared = bool(r.get("cleared", false))
	m.score = int(r.get("score", 0))
	m.rank = str(r.get("rank", "D"))
	m.fail_reason = "" if m.cleared else "hp_zero"
	m.duration_sec = maxf(s.now, 0.0) if s else 0.0
	var c: Dictionary = r.get("counts", {})
	var units := maxi(int(r.get("units", 0)), 1)
	m.stats = {
		"accuracy": float(r.get("accuracy", 0.0)),
		"max_combo": int(r.get("max_combo", 0)),
		"perfect_ratio": float(c.get(RhythmJudge.PERFECT, 0)) / float(units),
		"miss": int(c.get(RhythmJudge.MISS, 0)) + int(c.get(RhythmJudge.WRONG, 0)),
		"hp_left_ratio": float(r.get("hp", 0)) / float(maxi(int(r.get("max_hp", 1)), 1)),
		"holds_broken": int(r.get("holds_broken", 0)),
	}
	return m
