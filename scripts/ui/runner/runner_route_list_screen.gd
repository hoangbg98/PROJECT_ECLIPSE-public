class_name RunnerRouteListScreen
extends HubScreen
## Vô tận Chạy Nguyên Tố (chế độ dạng danh sách `runner_endless`, docs/design/RUNNER_MODE.md mục 7): chọn độ khó
## (Dễ / Thường / Khó), mỗi dòng một tuyến (seed cố định): số thứ tự, tên tuyến, tốc độ + độ dài, vương miện theo hạng
## tốt nhất, kỷ lục, nút Chơi. Bấm Chơi dựng ải từ dữ liệu event (MinigameRegistry.route_stage) rồi mở MinigameHost.

const ROW_H := 200.0

var registry: MinigameRegistry
var progress: MinigameProgress
var event_id := "evt_material"
var mode_id := "runner_endless"
var difficulty := "normal"
var row_buttons: Dictionary = {}


func screen_title() -> String:
	return tr("RUNNER_ENDLESS_TITLE")


func _ready() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		if str(gc.event_id) != "":
			event_id = str(gc.event_id)
		if str(gc.event_mode_id) == "runner_endless":
			mode_id = str(gc.event_mode_id)
	if registry == null:
		registry = MinigameRegistry.load_from()
	super._ready()


func _progress() -> MinigameProgress:
	if progress == null or progress.profile != profile:
		progress = MinigameProgress.new(profile)
	return progress


func _endless() -> Dictionary:
	return registry.mode(event_id, mode_id).get("endless", {})


func _build_body() -> void:
	row_buttons.clear()
	var diffs: Array = _endless().get("difficulties", ["easy", "normal", "hard"])
	var tw := 260.0
	var tx := (layout.view_size.x - tw * diffs.size()) * 0.5
	for i in diffs.size():
		var key := str(diffs[i])
		_button(Rect2(tx + i * tw, 104, tw - 10, 70), tr("RHYTHM_DIFF_" + key.to_upper()), 28, select_difficulty.bind(key),
				key == difficulty, "Tab_" + key)
	_label(Rect2(1300, 104, 560, 70), _plays_text(), 24, Color("#FFD84D"), HORIZONTAL_ALIGNMENT_RIGHT).name = "Plays"
	var gen: Dictionary = _endless().get("by_difficulty", {}).get(difficulty, {}).get("params", {}).get("gen", {})
	var info := tr("RUNNER_ENDLESS_INFO") % [int(gen.get("speed", 0)), int(gen.get("length_sec", 0)), int(_endless().get("party_min", 1))]
	_label(Rect2(40, 104, 520, 70), info, 22, Color(1, 1, 1, 0.75)).name = "Info"
	var list_rect := Rect2(140, 190, layout.view_size.x - 280, layout.view_size.y - 210)
	var scroll := ScrollContainer.new()
	scroll.name = "RouteScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(scroll, list_rect)
	var content := Control.new()
	content.name = "Rows"
	var routes := registry.routes(event_id, mode_id)
	content.custom_minimum_size = Vector2(list_rect.size.x - 24, maxf(routes.size() * ROW_H, 10.0))
	scroll.add_child(content)
	for i in routes.size():
		_row(content, Rect2(0, i * ROW_H, content.custom_minimum_size.x, ROW_H - 18), routes[i], i + 1)


func select_difficulty(key: String) -> void:
	difficulty = key
	refresh()


func _plays_text() -> String:
	var lim := registry.limit_for(event_id, mode_id)
	var left := _progress().remaining(lim["key"], lim["limit"])
	if left < 0:
		return tr("EVENT_PLAYS_UNLIMITED")
	return tr("EVENT_PLAYS_LEFT") % [left, int(lim["limit"].get("max", 0))]


func _row_style(bg: Color) -> StyleBoxFlat:
	var st := _style(bg, Color(0, 0, 0, 0), 18)
	st.shadow_color = Color(0, 0, 0, 0.25)
	st.shadow_size = 6
	return st


func _row(parent: Control, r: Rect2, route: Dictionary, number: int) -> void:
	var id := str(route.get("id", ""))
	var key := MinigameRegistry.endless_id(id, difficulty)
	var rec := _progress().record(mode_id, key)
	var row := Panel.new()
	row.name = "Row_" + id
	row.position = r.position
	row.size = r.size
	row.add_theme_stylebox_override("panel", _row_style(Color("#FFFFFF")))
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(row)
	var badge := Panel.new()
	badge.size = Vector2(170, r.size.y)
	var bs := _row_style(Color("#3FA9FF"))
	bs.corner_radius_top_right = 0
	bs.corner_radius_bottom_right = 0
	bs.shadow_size = 0
	badge.add_theme_stylebox_override("panel", bs)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(badge)
	_row_label(row, "»", Vector2(30, 30), Vector2(150, 150), 120, Color(1, 1, 1, 0.3))
	_row_label(row, "%d" % number, Vector2(16, 6), Vector2(100, 64), 46, Color.WHITE)
	_row_label(row, tr(str(route.get("title_key", id))), Vector2(200, 8), Vector2(r.size.x - 760, 66), 46, Color("#3B4A63"))
	_row_label(row, tr("RUNNER_ROUTE_SEED") % int(route.get("seed", 0)), Vector2(200, 72), Vector2(r.size.x - 760, 44), 26,
			Color("#8FA0BC"))
	var crowns := RhythmJudge.crowns_of(str(rec.get("best_rank", "")))
	var crown_text := ""
	for c in 3:
		crown_text += "♛" if c < crowns else "♔"
	_row_label(row, crown_text, Vector2(200, 116), Vector2(260, 60), 48, Color("#3FA9FF") if crowns > 0 else Color("#D5DCE8"))
	var best := int(rec.get("best_score", 0))
	if best > 0:
		_row_label(row, tr("RHYTHM_BEST_SCORE") % best, Vector2(480, 128), Vector2(400, 44), 26, Color("#8FA0BC"))
	var play := Button.new()
	play.name = "Play_" + id
	play.text = tr("RHYTHM_PLAY")
	play.focus_mode = Control.FOCUS_NONE
	play.position = Vector2(r.size.x - 360, 34)
	play.size = Vector2(320, 128)
	play.add_theme_font_size_override("font_size", 52)
	var blue := Color("#1DA1E2")
	play.add_theme_stylebox_override("normal", _style(blue, Color(0, 0, 0, 0), 64))
	play.add_theme_stylebox_override("hover", _style(blue.lightened(0.1), Color(0, 0, 0, 0), 64))
	play.add_theme_stylebox_override("pressed", _style(blue.darkened(0.15), Color(0, 0, 0, 0), 64))
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		play.add_theme_color_override(k, Color.WHITE)
	play.pressed.connect(play_route.bind(id))
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


## Mở lượt chơi một tuyến ở độ khó đang chọn; đội thiếu người thì báo.
func play_route(route_id: String) -> void:
	var st := registry.route_stage(event_id, mode_id, route_id, difficulty)
	var need := int(st.get("party_min", 1))
	var have := profile.party_ids().size()
	if have < need:
		say(tr("EVENT_PARTY_TOO_SMALL") % [have, need])
		return
	StageSelectScreen.launch(event_id, mode_id, st, self)
