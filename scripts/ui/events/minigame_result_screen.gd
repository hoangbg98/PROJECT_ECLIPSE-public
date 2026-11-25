class_name MinigameResultScreen
extends Control
## Màn kết quả dùng chung mọi chế độ Event nguyên liệu (docs/design/MATERIAL_EVENT.md mục 10): hạng, điểm, 3 sao (sao
## mới đạt ghi "Mới!"), thống kê riêng của chế độ (nhãn STAT_<KHÓA>), thưởng thực nhận, kỷ lục mới.

signal retry_pressed
signal back_pressed

const GOLD := Color("#FFD84D")


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Mô tả một điều kiện sao bằng chữ.
static func describe_star(cond: String) -> String:
	var p := StarEvaluator.parse(cond)
	if p.has("error"):
		return cond
	match str(p["kind"]):
		"clear":
			return TranslationServer.translate("STAR_CLEAR")
		"rank":
			return TranslationServer.translate("STAR_RANK") % str(p["value"])
		"score":
			return TranslationServer.translate("STAR_SCORE") % int(p["value"])
	var key := str(p["key"])
	var op: String = {">=": "≥", "<=": "≤", "==": "="}[p["op"]]
	return "%s %s %s" % [TranslationServer.translate("STAT_" + key.to_upper()), op, format_stat(key, float(p["value"]))]


## Giá trị thống kê: tỉ lệ (accuracy, *_ratio) hiện %, còn lại số.
static func format_stat(key: String, v: float) -> String:
	if key == "accuracy" or key.ends_with("_ratio"):
		return "%d%%" % roundi(v * 100.0)
	if is_equal_approx(v, roundf(v)):
		return "%d" % roundi(v)
	return "%.1f" % v


## Tóm tắt gói thưởng đã nhận (dạng PlayerProfile.grant).
static func reward_text(got: Dictionary) -> String:
	var parts := PackedStringArray()
	if int(got.get("gold", 0)) > 0:
		parts.append("%s ×%d" % [TranslationServer.translate("CURRENCY_GOLD"), int(got["gold"])])
	if int(got.get("gems", 0)) > 0:
		parts.append("%s ×%d" % [TranslationServer.translate("CURRENCY_GEMS"), int(got["gems"])])
	var mats: Dictionary = got.get("materials", {}) if got.get("materials") is Dictionary else {}
	var items := PlayerProfile.item_defs()
	for id in mats:
		if int(mats[id]) <= 0:
			continue
		var d: Resource = items.get_def(str(id)) if items else null
		parts.append("%s ×%d" % [TranslationServer.translate(str(d.get("name_key"))) if d else str(id), int(mats[id])])
	var cexp := int(got.get("captain_exp", 0))
	if cexp > 0:
		parts.append("%s +%d" % [TranslationServer.translate("EVENT_CAPTAIN_EXP"), cexp])
	return ", ".join(parts)


func show_result(result: MinigameResult, outcome: Dictionary, stage: Dictionary, mode: Dictionary, rewarded: bool) -> void:
	for c in get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color("#141029")
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var cleared := result.cleared
	_label("Title", tr("EVENT_RESULT_CLEAR") if cleared else tr("EVENT_RESULT_FAIL"), Rect2(360, 40, 1200, 110), 84,
			GOLD if cleared else Color("#FF7A7A"), HORIZONTAL_ALIGNMENT_CENTER)
	if cleared:
		_label("Rank", result.rank, Rect2(140, 200, 420, 320), 260, Color("#FF6FD8"), HORIZONTAL_ALIGNMENT_CENTER)
		_label("RankLine", tr("EVT_RESULT_" + result.rank), Rect2(100, 520, 500, 90), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_label("RankLine", tr("EVT_RESULT_FAIL"), Rect2(100, 300, 500, 120), 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	# Sao.
	var stars: Array = outcome.get("stars", [false, false, false])
	var new_stars: Array = outcome.get("new_stars", [])
	var conds: Array = stage.get("stars", [])
	for i in mini(conds.size(), 3):
		var got := i < stars.size() and bool(stars[i])
		var text := ("★ " if got else "☆ ") + describe_star(str(conds[i]))
		if (i + 1) in new_stars:
			text += "   " + tr("EVENT_NEW")
		_label("Star_%d" % (i + 1), text, Rect2(640, 190 + i * 56, 1180, 52), 32, GOLD if got else Color(1, 1, 1, 0.5))
	# Điểm + thống kê.
	var lines := PackedStringArray([tr("EVENT_RESULT_SCORE") % result.score])
	if bool(outcome.get("new_best", false)):
		lines[0] += "   " + tr("RHYTHM_NEW_BEST")
	for key in MinigameRegistry.stats_keys(str(mode.get("id", ""))):
		if result.stats.has(key):
			lines.append("%s: %s" % [tr("STAT_" + str(key).to_upper()), format_stat(str(key), float(result.stats[key]))])
	# Dài hơn 6 dòng (vd Chạy Nguyên Tố 9 dòng) thì chia hai cột để không đè dòng thưởng.
	if lines.size() <= 6:
		_label("Stats", "\n".join(lines), Rect2(640, 370, 1180, 330), 30, Color.WHITE)
	else:
		var half := ceili(lines.size() / 2.0)
		_label("Stats", "\n".join(lines.slice(0, half)), Rect2(640, 370, 580, 330), 30, Color.WHITE)
		_label("Stats2", "\n".join(lines.slice(half)), Rect2(1230, 370, 600, 330), 30, Color.WHITE)
	# Thưởng.
	var rew := reward_text(outcome.get("rewards", {}))
	var reward_line := ""
	if rew != "":
		reward_line = tr("RESULT_REWARDS") + ": " + rew
	elif cleared and not rewarded:
		reward_line = tr("EVENT_NO_REWARD_LIMIT")
	if bool(outcome.get("first_clear", false)):
		reward_line += "\n" + tr("EVENT_FIRST_CLEAR_DONE")
	_label("Rewards", reward_line, Rect2(640, 710, 1180, 110), 28, Color("#7DFFB0"))
	_button("RetryButton", tr("RESULT_RETRY"), Rect2(560, 880, 360, 128), func() -> void: retry_pressed.emit())
	_button("BackButton", tr("EVENT_BACK_TO_SELECT"), Rect2(1000, 880, 360, 128), func() -> void: back_pressed.emit())


func _label(name_: String, text: String, r: Rect2, size_: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.name = name_
	l.text = text
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size_)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.1, 0.02, 0.2))
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l


func _button(name_: String, text: String, r: Rect2, cb: Callable) -> Button:
	var b := Button.new()
	b.name = name_
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	b.add_theme_font_size_override("font_size", 36)
	for st in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		var bg := Color("#FF4FA3") if name_ == "RetryButton" else Color("#3B2A6B")
		sb.bg_color = bg.lightened(0.1) if st == "hover" else (bg.darkened(0.15) if st == "pressed" else bg)
		sb.set_corner_radius_all(64)
		sb.border_color = Color(1, 1, 1, 0.8)
		sb.set_border_width_all(3)
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(cb)
	add_child(b)
	return b
