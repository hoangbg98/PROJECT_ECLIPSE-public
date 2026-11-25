class_name EventHubScreen
extends HubScreen
## Hub Event nguyên liệu (docs/design/MATERIAL_EVENT.md mục 10): mỗi chế độ một thẻ, ghi trạng thái (khóa và điều kiện,
## lượt có thưởng còn lại + thời gian làm mới, số sao). Không biết luật chơi: chỉ đọc data/events/material_events.json.

var registry: MinigameRegistry
var progress: MinigameProgress
var event_id := "evt_material"
var card_buttons: Dictionary = {}
## Lỗi trong data/events/material_events.json (hiện dòng đầu ở trên màn, đủ danh sách trong log).
var data_errors := PackedStringArray()


func screen_title() -> String:
	return tr(str(registry.event(event_id).get("title_key", ""))) if registry else ""


func _ready() -> void:
	var gc := UiKit.autoload("GameConfig")
	if gc and str(gc.event_id) != "":
		event_id = str(gc.event_id)
	if registry == null:
		registry = MinigameRegistry.load_from()
	data_errors = registry.errors.duplicate()
	if registry.errors.is_empty():
		data_errors.append_array(EventValidator.validate(registry.data, PlayerProfile.item_defs().ids())["errors"])
	for e in data_errors:
		push_warning("material_events.json: " + e)
	super._ready()
	if not data_errors.is_empty():
		say(tr("EVENT_DATA_ERROR") % [data_errors.size(), data_errors[0]])


func _progress() -> MinigameProgress:
	if progress == null or progress.profile != profile:
		progress = MinigameProgress.new(profile)
	return progress


const CARD_W := 420.0
const CARD_H := 660.0
const STRIP_H := 168.0


func _build_body() -> void:
	card_buttons.clear()
	var modes := registry.hub_modes(event_id)
	var gap := 44.0
	var total := CARD_W * modes.size() + gap * maxf(modes.size() - 1, 0)
	var x0 := maxf((layout.view_size.x - total) * 0.5, 40.0)
	for i in modes.size():
		_mode_card(Rect2(x0 + i * (CARD_W + gap), 150, CARD_W, CARD_H), modes[i])


## Thẻ chế độ (theo ảnh tham chiếu của owner 2026-11-20): ảnh phủ phần trên, dải trắng dưới ghi tên chế độ, "EVENT" và
## loại nguyên liệu rơi (chữ xanh). Góc trên phải: lượt có thưởng còn lại. Khóa / Sắp ra mắt: phủ tối + nhãn.
func _mode_card(r: Rect2, mode: Dictionary) -> void:
	var id := str(mode.get("id", ""))
	var card: Dictionary = mode.get("card", {})
	var soon := MinigameRegistry.is_soon(mode)
	var open := not soon and _progress().mode_unlocked(mode)
	var b := _button(r, "", 30, activate.bind(id), false, "Mode_" + id)
	var frame := _style(Color.WHITE, Color(1, 1, 1, 0.9), 6)
	frame.set_border_width_all(4)
	b.add_theme_stylebox_override("normal", frame)
	var hover := _style(Color.WHITE, Color("#FFD84D"), 6)
	hover.set_border_width_all(6)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	card_buttons[id] = b
	var art_rect := Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, r.size.y - STRIP_H - 4))
	_card_art(art_rect, card, id)
	if open:
		var plays := _plays_badge(id)
		if plays != "":
			var pill := _panel(Rect2(art_rect.end.x - 150, art_rect.position.y + 14, 136, 46), Color(0, 0, 0, 0.6))
			pill.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.6), Color(1, 1, 1, 0.3), 23))
			_label(pill.get_rect(), plays, 24, Color("#FFD84D"), HORIZONTAL_ALIGNMENT_CENTER).name = "Plays_" + id
	else:
		_panel(art_rect, Color(0.05, 0.05, 0.1, 0.62), "Dim_" + id)
		var tag := tr("HUB_BADGE_SOON") if soon else lock_reason(mode)
		var tp := _panel(Rect2(art_rect.position + Vector2(30, art_rect.size.y * 0.42), Vector2(art_rect.size.x - 60, 72)),
				Color("#FF8A3D", 0.92))
		tp.add_theme_stylebox_override("panel", _style(Color("#FF8A3D", 0.92), Color.WHITE, 36))
		_label(tp.get_rect(), tag, 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER).name = "Tag_" + id
	# Dải chữ dưới.
	var strip := Rect2(Vector2(r.position.x + 4, r.end.y - STRIP_H), Vector2(r.size.x - 8, STRIP_H - 4))
	_panel(strip, Color("#F4F6FA"))
	_label(Rect2(strip.position + Vector2(10, 14), Vector2(strip.size.x - 20, 70)), tr(str(mode.get("title_key", id))).to_upper(),
			40, Color("#2B2D36"), HORIZONTAL_ALIGNMENT_CENTER).name = "Title_" + id
	_label(Rect2(strip.position + Vector2(10, 82), Vector2(strip.size.x - 20, 22)), "EVENT", 15, Color("#9AA3B5"),
			HORIZONTAL_ALIGNMENT_CENTER)
	_label(Rect2(strip.position + Vector2(10, 104), Vector2(strip.size.x - 20, 52)), tr(str(card.get("drops_key", ""))), 28,
			Color("#1DA1E2"), HORIZONTAL_ALIGNMENT_CENTER).name = "Drops_" + id
	for c in [b]:
		c.tooltip_text = tr(str(mode.get("sub_key", "")))


## Ảnh thẻ: nền 2 màu (dọc) + các lớp ảnh trong `card.art` (rect theo tỉ lệ khung ảnh, fit / cover / cover_top),
## cắt trong khung. Thiếu ảnh thì chỉ có nền màu.
func _card_art(r: Rect2, card: Dictionary, id: String) -> void:
	var clip := Control.new()
	clip.name = "Art_" + id
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(clip, r)
	var cols: Array = card.get("bg", ["#1E1A33", "#3B2A6B"])
	var grad := Gradient.new()
	grad.set_color(0, Color.from_string(str(cols[0]), Color("#1E1A33")))
	grad.set_color(1, Color.from_string(str(cols[cols.size() - 1]), Color("#3B2A6B")))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var bg := TextureRect.new()
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.position = Vector2.ZERO
	bg.size = r.size
	bg.modulate = Color(1, 1, 1, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(bg)
	for layer in card.get("art", []):
		var path := str(layer.get("path", ""))
		if not ResourceLoader.exists(path):
			continue
		var rr: Array = layer.get("rect", [0, 0, 1, 1])
		var t := TextureRect.new()
		t.texture = load(path) as Texture2D
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		match str(layer.get("fit", "fit")):
			"cover":
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			"cover_top":
				t.stretch_mode = TextureRect.STRETCH_SCALE
			_:
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = Vector2(float(rr[0]) * r.size.x, float(rr[1]) * r.size.y)
		t.size = Vector2(float(rr[2]) * r.size.x, float(rr[3]) * r.size.y)
		if str(layer.get("fit", "")) == "cover_top" and t.texture:
			# Phủ ngang, giữ tỉ lệ, canh từ đỉnh ảnh (chân dung nhân vật cao).
			var ts := t.texture.get_size()
			var sc := t.size.x / ts.x
			t.size = Vector2(t.size.x, ts.y * sc)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.add_child(t)


## "47/50" lượt có thưởng còn lại (rỗng = không giới hạn).
func _plays_badge(mode_id: String) -> String:
	var lim := registry.limit_for(event_id, mode_id)
	var left := _progress().remaining(lim["key"], lim["limit"])
	return "" if left < 0 else "%d/%d" % [left, int(lim["limit"].get("max", 0))]


## "Qua N-5 để mở" theo unlock.requires_stage_cleared.
func lock_reason(mode: Dictionary) -> String:
	var need := str(mode.get("unlock", {}).get("requires_stage_cleared", "")).split("/")
	if need.size() != 2:
		return tr("EVENT_LOCK")
	var s := registry.stage(event_id, need[0], need[1])
	return tr("EVENT_LOCKED_NEED") % str(s.get("code", need[1]))


## "Lượt có thưởng: 47/50 · làm mới sau 3 ngày 2 giờ" hoặc "Không giới hạn lượt".
func plays_line(mode_id: String) -> String:
	var lim := registry.limit_for(event_id, mode_id)
	var limit: Dictionary = lim["limit"]
	var left := _progress().remaining(lim["key"], limit)
	if left < 0:
		return tr("EVENT_PLAYS_UNLIMITED")
	var secs := _progress().next_reset_unix(limit) - int(_progress().clock.call())
	return (tr("EVENT_PLAYS_LEFT") % [left, int(limit.get("max", 0))]) + "\n" + (tr("EVENT_RESET_IN") % duration_text(secs))


static func duration_text(secs: int) -> String:
	secs = maxi(secs, 0)
	var d := secs / 86400
	var h := (secs % 86400) / 3600
	if d > 0:
		return TranslationServer.translate("EVENT_TIME_DH") % [d, h]
	return TranslationServer.translate("EVENT_TIME_HM") % [h, (secs % 3600) / 60]


func activate(mode_id: String) -> void:
	var mode := registry.mode(event_id, mode_id)
	if MinigameRegistry.is_soon(mode):
		say(tr("UI_COMING_SOON"))
		return
	if not _progress().mode_unlocked(mode):
		say(lock_reason(mode))
		return
	var gc := UiKit.autoload("GameConfig")
	if gc:
		gc.event_id = event_id
		gc.event_mode_id = mode_id
	if str(mode.get("layout", "graph")) == "list":
		open_path(str(mode.get("list_scene", "")))
	else:
		open_scene("SCENE_STAGE_SELECT")


## Mở scene theo đường dẫn (thẻ chế độ dạng danh sách khai báo `list_scene` trong dữ liệu).
func open_path(path: String) -> void:
	last_target = path
	var router := UiKit.autoload("SceneRouter")
	if navigate_enabled and router and path != "":
		router.push(path)
