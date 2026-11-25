class_name StageSelectScreen
extends HubScreen
## Chọn ải của một chế độ Event nguyên liệu, dạng đồ thị (docs/design/MATERIAL_EVENT.md mục 10): nút theo `pos`, đường
## nối theo `requires`, nút đã qua hiện sao, nút khóa mờ. Bảng bên phải: điều kiện sao, Có thể rơi, kỷ lục, lượt còn,
## yêu cầu đội, nút Chơi. Không đọc `params` (chỉ scene chơi hiểu).

const GRAPH := Rect2(60, 150, 1250, 760)
const PANEL := Rect2(1340, 150, 530, 760)
const NODE := 150.0

var registry: MinigameRegistry
var progress: MinigameProgress
var event_id := "evt_material"
var mode_id := "rhythm"
var selected := ""
var node_buttons: Dictionary = {}


func screen_title() -> String:
	return tr(str(_mode().get("title_key", mode_id))) if registry else ""


func _ready() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		if str(gc.event_id) != "":
			event_id = str(gc.event_id)
		if str(gc.event_mode_id) != "":
			mode_id = str(gc.event_mode_id)
	if registry == null:
		registry = MinigameRegistry.load_from()
	super._ready()


func _mode() -> Dictionary:
	return registry.mode(event_id, mode_id)


func _progress() -> MinigameProgress:
	if progress == null or progress.profile != profile:
		progress = MinigameProgress.new(profile)
	return progress


func stages() -> Array:
	return _mode().get("stages", [])


func _default_selection() -> String:
	var last := ""
	for s in stages():
		var id := str(s["id"])
		if _progress().stage_unlocked(mode_id, s):
			last = id
			if not _progress().is_cleared(mode_id, id):
				return id
	return last


func _center(s: Dictionary) -> Vector2:
	var pos: Array = s.get("pos", [0.5, 0.5])
	return GRAPH.position + Vector2(float(pos[0]) * GRAPH.size.x, float(pos[1]) * GRAPH.size.y)


func _build_body() -> void:
	node_buttons.clear()
	if selected == "" or registry.stage(event_id, mode_id, selected).is_empty():
		selected = _default_selection()
	var area := _panel(GRAPH, Color("#151229", 0.9), "Graph")
	area.add_theme_stylebox_override("panel", _style(Color("#151229", 0.9), Color(1, 1, 1, 0.12), 18))
	var col := Color.from_string(str(_mode().get("color", "#7FD4FF")), Color("#7FD4FF"))
	var lines := Control.new()
	lines.name = "Links"
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(lines, Rect2(Vector2.ZERO, layout.view_size))
	lines.draw.connect(func() -> void:
		for s in stages():
			for req in s.get("requires", []):
				var from := registry.stage(event_id, mode_id, str(req))
				if not from.is_empty():
					var done := _progress().is_cleared(mode_id, str(req))
					lines.draw_line(_center(from), _center(s), Color(col, 0.9) if done else Color(1, 1, 1, 0.2), 8.0 if done else 4.0))
	for s in stages():
		_node(s, col)
	_child_mode_buttons()
	_side_panel(registry.stage(event_id, mode_id, selected), col)


## Nút chế độ con (vd "Vô tận" của Nhịp điệu) ở góc dưới trái đồ thị; khóa thì ghi điều kiện mở.
func _child_mode_buttons() -> void:
	var children := registry.child_modes(event_id, mode_id)
	for i in children.size():
		var m: Dictionary = children[i]
		var cid := str(m.get("id", ""))
		var open := _progress().mode_unlocked(m)
		var r := Rect2(GRAPH.position + Vector2(24 + i * 340, GRAPH.size.y - 112), Vector2(320, 92))
		var text := tr(str(m.get("title_key", cid)))
		if not open:
			text += "  🔒"
		var b := _button(r, text, 32, open_child.bind(cid), false, "Child_" + cid)
		var c := Color.from_string(str(m.get("color", "#9C6BFF")), Color("#9C6BFF"))
		b.add_theme_stylebox_override("normal", _style(c if open else c.darkened(0.6), Color.WHITE if open else Color(1, 1, 1, 0.3), 46))
		b.add_theme_stylebox_override("hover", _style(c.lightened(0.1), Color.WHITE, 46))


func open_child(child_id: String) -> void:
	var m := registry.mode(event_id, child_id)
	if not _progress().mode_unlocked(m):
		var need := str(m.get("unlock", {}).get("requires_stage_cleared", "")).split("/")
		var code := str(registry.stage(event_id, need[0], need[1]).get("code", "")) if need.size() == 2 else ""
		say(tr("EVENT_LOCKED_NEED") % code)
		return
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.event_mode_id = child_id
	last_target = str(m.get("list_scene", ""))
	var router := UiKit.autoload("SceneRouter")
	if navigate_enabled and router and last_target != "":
		router.push(last_target)


func _node(s: Dictionary, col: Color) -> void:
	var id := str(s["id"])
	var open := _progress().stage_unlocked(mode_id, s)
	var c := _center(s)
	var r := Rect2(c - Vector2(NODE, NODE) * 0.5, Vector2(NODE, NODE))
	var b := _button(r, "", 30, select.bind(id), false, "Node_" + id)
	var bg := Color("#2A1B4A") if open else Color("#1A1626")
	var border := Color.WHITE if id == selected else (col if open else Color(1, 1, 1, 0.2))
	var sb := _style(bg, border, int(NODE * 0.5))
	sb.set_border_width_all(6 if id == selected else 3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.1), border, int(NODE * 0.5)))
	node_buttons[id] = b
	_label(Rect2(r.position + Vector2(0, 30), Vector2(NODE, 60)), str(s.get("code", id)), 44,
			col if open else Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
	_label(Rect2(r.position + Vector2(0, 88), Vector2(NODE, 40)), star_text(id) if open else tr("EVENT_LOCK"), 28,
			Color("#FFD84D") if open else Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_CENTER)
	_label(Rect2(c + Vector2(-140, NODE * 0.5 + 6), Vector2(280, 70)), tr(str(s.get("title_key", id))), 24,
			Color(1, 1, 1, 0.85) if open else Color(1, 1, 1, 0.4), HORIZONTAL_ALIGNMENT_CENTER)


func star_text(stage_id: String) -> String:
	var t := ""
	for b in _progress().stars(mode_id, stage_id):
		t += "★" if b else "☆"
	return t


func _side_panel(s: Dictionary, col: Color) -> void:
	_panel(PANEL, Color("#1E1A33", 0.95), "Info").add_theme_stylebox_override("panel",
			_style(Color("#1E1A33", 0.95), Color(col, 0.6), 18))
	if s.is_empty():
		return
	var id := str(s["id"])
	var p := PANEL.position + Vector2(28, 20)
	var w := PANEL.size.x - 56
	_label(Rect2(p, Vector2(w, 60)), "%s  %s" % [str(s.get("code", "")), tr(str(s.get("title_key", id)))], 34, col)
	var info := PackedStringArray()
	info.append(tr("EVENT_STAR_CONDITIONS"))
	var st := _progress().stars(mode_id, id)
	var conds: Array = s.get("stars", [])
	for i in conds.size():
		info.append(("★ " if i < st.size() and st[i] else "☆ ") + MinigameResultScreen.describe_star(str(conds[i])))
	var rew: Dictionary = s.get("rewards", {})
	info.append("")
	info.append(tr("EVENT_DROPS") + ": " + MinigameResultScreen.reward_text(rew.get("base", {})))
	var rec := _progress().record(mode_id, id)
	if not bool(rec.get("first_clear_claimed", false)) and not RewardService.is_empty(rew.get("first_clear", {})):
		info.append(tr("EVENT_FIRST_CLEAR") + ": " + MinigameResultScreen.reward_text(rew.get("first_clear", {})))
	if int(rec.get("best_score", 0)) > 0:
		info.append(tr("EVENT_BEST") % [int(rec["best_score"]), str(rec.get("best_rank", ""))])
	var need := int(s.get("party_min", 1))
	if need > 1:
		info.append(tr("EVENT_PARTY_MIN") % need)
	_label(Rect2(p + Vector2(0, 74), Vector2(w, 420)), "\n".join(info), 24, Color.WHITE).name = "InfoText"
	_label(Rect2(p + Vector2(0, 500), Vector2(w, 76)), _plays_line(), 24, Color("#FFD84D")).name = "Plays"
	var lim := registry.limit_for(event_id, mode_id)
	var no_reward := _progress().remaining(lim["key"], lim["limit"]) == 0
	var play := _yellow_button(Rect2(PANEL.position + Vector2(28, PANEL.size.y - 150), Vector2(w, 128)),
			tr("EVENT_PLAY_NO_REWARD") if no_reward else tr("EVENT_PLAY"), 40, play_selected, "PlayButton")
	play.disabled = not _progress().stage_unlocked(mode_id, s)


func _plays_line() -> String:
	var lim := registry.limit_for(event_id, mode_id)
	var left := _progress().remaining(lim["key"], lim["limit"])
	if left < 0:
		return tr("EVENT_PLAYS_UNLIMITED")
	var secs := _progress().next_reset_unix(lim["limit"]) - int(_progress().clock.call())
	return (tr("EVENT_PLAYS_LEFT") % [left, int(lim["limit"].get("max", 0))]) + "\n" + \
			(tr("EVENT_RESET_IN") % EventHubScreen.duration_text(secs))


func select(stage_id: String) -> void:
	selected = stage_id
	notice = ""
	refresh()


## Lý do không vào được ải (rỗng = vào được).
func block_reason(s: Dictionary) -> String:
	if not _progress().stage_unlocked(mode_id, s):
		return tr("EVENT_STAGE_LOCKED")
	var need := int(s.get("party_min", 1))
	var have := profile.party_ids().size()
	if have < need:
		return tr("EVENT_PARTY_TOO_SMALL") % [have, need]
	return ""


func play_selected() -> void:
	var s := registry.stage(event_id, mode_id, selected)
	if s.is_empty():
		return
	var why := block_reason(s)
	if why != "":
		say(why)
		return
	launch(event_id, mode_id, s, self)


## Mở màn chạy một lượt (dùng chung cho màn danh sách bài).
static func launch(event_id_: String, mode_id_: String, stage: Dictionary, screen: HubScreen) -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.minigame_launch = {"event_id": event_id_, "mode_id": mode_id_, "stage": stage.duplicate(true)}
	screen.open_scene("SCENE_MINIGAME_HOST")
