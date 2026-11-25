class_name JetEndlessScreen
extends HubScreen
## Vô tận Bay Nguyên Tố (chế độ dạng danh sách `jet_endless`, docs/design/JET_MODE.md mục 8): "Vô tận (đổi vùng)" và
## "Luyện vùng 1 / 2 / 3". Đường bay đổi theo ngày (seed = số ngày UTC); kỷ lục = mét. Luyện vùng không tốn lượt,
## không thưởng. Bấm Chơi dựng ải từ dữ liệu event (MinigameRegistry.entry_stage) rồi mở MinigameHost.

const ROW_H := 190.0

var registry: MinigameRegistry
var progress: MinigameProgress
var event_id := "evt_material"
var mode_id := "jet_endless"
## Test: ghi đè seed (mặc định theo ngày).
var seed_override := -1
var row_buttons: Dictionary = {}


func screen_title() -> String:
	return tr("JET_ENDLESS_TITLE")


func _ready() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		if str(gc.event_id) != "":
			event_id = str(gc.event_id)
		if str(gc.event_mode_id) == "jet_endless":
			mode_id = str(gc.event_mode_id)
	if registry == null:
		registry = MinigameRegistry.load_from()
	super._ready()


func _progress() -> MinigameProgress:
	if progress == null or progress.profile != profile:
		progress = MinigameProgress.new(profile)
	return progress


static func day_seed() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func route_seed() -> int:
	return seed_override if seed_override >= 0 else day_seed()


func _build_body() -> void:
	row_buttons.clear()
	_label(Rect2(140, 104, 1100, 70), tr("JET_ENDLESS_INFO"), 24, Color(1, 1, 1, 0.75)).name = "Info"
	_label(Rect2(1300, 104, 560, 70), _plays_text(), 24, Color("#FFD84D"), HORIZONTAL_ALIGNMENT_RIGHT).name = "Plays"
	var entries := registry.endless_entries(event_id, mode_id)
	for i in entries.size():
		_row(Rect2(140, 190 + i * ROW_H, layout.view_size.x - 280, ROW_H - 18), entries[i])


func _plays_text() -> String:
	var lim := registry.limit_for(event_id, mode_id)
	var left := _progress().remaining(lim["key"], lim["limit"])
	if left < 0:
		return tr("EVENT_PLAYS_UNLIMITED")
	return tr("EVENT_PLAYS_LEFT") % [left, int(lim["limit"].get("max", 0))]


func _row(r: Rect2, entry: Dictionary) -> void:
	var id := str(entry.get("id", ""))
	var practice := bool(entry.get("practice", false))
	var rec := _progress().record(mode_id, "endless:" + id)
	var row := Panel.new()
	row.name = "Row_" + id
	_place(row, r)
	var st := _style(Color("#FFFFFF"), Color(0, 0, 0, 0), 18)
	st.shadow_color = Color(0, 0, 0, 0.25)
	st.shadow_size = 6
	row.add_theme_stylebox_override("panel", st)
	var zone := str(entry.get("zone", ""))
	var accent := Color(str(JetLevel.zone_def(zone).get("accent", "#7DFFB0"))) if zone != "" else Color("#7DFFB0")
	var badge := Panel.new()
	badge.size = Vector2(170, r.size.y)
	var bs := _style(accent, Color(0, 0, 0, 0), 18)
	bs.corner_radius_top_right = 0
	bs.corner_radius_bottom_right = 0
	badge.add_theme_stylebox_override("panel", bs)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)
	_row_label(row, "✦" if zone == "" else "◎", Vector2(0, 20), Vector2(170, 130), 90, Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	_row_label(row, tr(str(entry.get("title_key", id))), Vector2(200, 8), Vector2(r.size.x - 760, 64), 44, Color("#3B4A63"))
	_row_label(row, tr(str(entry.get("sub_key", ""))), Vector2(200, 70), Vector2(r.size.x - 760, 44), 26, Color("#8FA0BC"))
	var best := int(rec.get("best_score", 0))
	var line := tr("JET_BEST_M") % best if best > 0 else ""
	if practice:
		line = (line + "   " if line != "" else "") + tr("JET_PRACTICE_NOTE")
	_row_label(row, line, Vector2(200, 116), Vector2(r.size.x - 600, 44), 26, Color("#1DA1E2") if not practice else Color("#8FA0BC"))
	var play := Button.new()
	play.name = "Play_" + id
	play.text = tr("RHYTHM_PLAY")
	play.focus_mode = Control.FOCUS_NONE
	play.position = Vector2(r.size.x - 360, 28)
	play.size = Vector2(320, 120)
	play.add_theme_font_size_override("font_size", 48)
	var col := Color("#20B486") if not practice else Color("#8E9BB5")
	play.add_theme_stylebox_override("normal", _style(col, Color(0, 0, 0, 0), 60))
	play.add_theme_stylebox_override("hover", _style(col.lightened(0.1), Color(0, 0, 0, 0), 60))
	play.add_theme_stylebox_override("pressed", _style(col.darkened(0.15), Color(0, 0, 0, 0), 60))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		play.add_theme_color_override(k, Color.WHITE)
	play.pressed.connect(play_entry.bind(id))
	row.add_child(play)
	row_buttons[id] = play


func _row_label(parent: Control, text: String, pos: Vector2, size_: Vector2, font_size: int, col: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size_
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.clip_text = true
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func play_entry(entry_id: String) -> void:
	StageSelectScreen.launch(event_id, mode_id, registry.entry_stage(event_id, mode_id, entry_id, route_seed()), self)
