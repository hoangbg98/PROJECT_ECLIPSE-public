extends GdUnitTestSuite
## Test công cụ gửi quà thử nghiệm (owner 2026-11-14): cú pháp, gói quà mẫu, kiểm tra trước khi áp (không áp nửa chừng),
## áp vào tài khoản, lệnh dòng lệnh (run_args) và bảng "Quà thử nghiệm" trong game.

const SAVE_DIR := "user://test_saves_gift"
const CLI_DIR := "user://test_saves_gift_cli"
const SCREEN_SCENE := preload("res://scenes/main/debug_gift_screen.tscn")
const HUB_SCENE := preload("res://scenes/main/hub.tscn")

var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_old_store = _save.store
	_old_data = _save.data
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = SaveSchema.default_data()
	SaveStore.new(CLI_DIR).delete_all()
	DebugGiftScreen.force_available = null


func after_test() -> void:
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	SaveStore.new(CLI_DIR).delete_all()
	DirAccess.remove_absolute(CLI_DIR)
	_save.store = _old_store
	_save.data = _old_data
	DebugGiftScreen.force_available = null


func _profile() -> PlayerProfile:
	return PlayerProfile.new(SaveSchema.default_data())


func _gift(text: String) -> Dictionary:
	var p := DebugGift.parse(text)
	assert_array(Array(p["errors"])).override_failure_message("lỗi cú pháp: %s" % str(p["errors"])).is_empty()
	return p["gift"]


# ---------- Cú pháp ----------

func test_parse_all_kinds() -> void:
	var g := _gift("gems=5000 gold=100 item:mat_exp_small=5 equip:eq_weapon_flame=2 char:char_earth_01 frag:char_fire_01=30 captain=40 captain_exp=7")
	assert_int(g["gems"]).is_equal(5000)
	assert_int(g["gold"]).is_equal(100)
	assert_int(g["materials"]["mat_exp_small"]).is_equal(5)
	assert_int(g["equipment"]["eq_weapon_flame"]).is_equal(2)
	assert_array(g["characters"]).is_equal(["char_earth_01"])
	assert_int(g["fragments"]["char_fire_01"]).is_equal(30)
	assert_int(g["captain_level"]).is_equal(40)
	assert_int(g["captain_exp"]).is_equal(7)


func test_parse_accepts_commas_newlines_and_default_count_one() -> void:
	var g := _gift("gems=10,gold=20\nitem:mat_exp_small equip:eq_weapon_iron")
	assert_array([g["gems"], g["gold"]]).is_equal([10, 20])
	assert_int(g["materials"]["mat_exp_small"]).is_equal(1)
	assert_int(g["equipment"]["eq_weapon_iron"]).is_equal(1)
	assert_bool(DebugGift.is_empty(DebugGift.empty())).is_true()
	assert_bool(DebugGift.is_empty(g)).is_false()


func test_parse_reports_errors() -> void:
	for bad in ["gems=abc", "gems", "gems=0", "gems=-5", "foo", "item:", "item:x=0", "preset:", "preset:khong_co_goi"]:
		var p := DebugGift.parse(bad)
		assert_bool((p["errors"] as PackedStringArray).size() > 0).override_failure_message("'%s' phải báo lỗi" % bad).is_true()
	var mixed := DebugGift.parse("gems=100 oops gold=5")
	assert_int(mixed["gift"]["gems"]).is_equal(100)                   # phần đúng vẫn đọc được
	assert_int(mixed["gift"]["gold"]).is_equal(5)
	assert_int((mixed["errors"] as PackedStringArray).size()).is_equal(1)


func test_all_expands_to_every_id() -> void:
	var g := _gift("item:all=3 equip:all char:all frag:all=10")
	assert_int((g["materials"] as Dictionary).size()).is_equal(DebugGift.item_ids().size())
	assert_int(g["materials"]["mat_exp_large"]).is_equal(3)
	assert_int((g["equipment"] as Dictionary).size()).is_equal(DebugGift.equipment_ids().size())
	assert_int((g["characters"] as Array).size()).is_equal(DebugGift.character_ids().size())
	assert_int(DebugGift.character_ids().size()).is_equal(6)
	assert_bool("char_fire_01_kit" in DebugGift.character_ids()).is_false()          # không lẫn file kit
	assert_int(g["fragments"]["char_wind_01"]).is_equal(10)


func test_preset_nesting_has_depth_guard() -> void:
	var p := DebugGift.parse("preset:rich", DebugGift.MAX_PRESET_DEPTH)
	assert_str(str(p["errors"])).contains("quá sâu")
	assert_int(_gift("preset:rich")["gems"]).is_equal(50000)
	assert_int(_gift("preset:rich gems=1")["gems"]).is_equal(50001)               # gói + mục lẻ cộng dồn


func test_merge_adds_and_keeps_highest_captain() -> void:
	var a := _gift("gems=10 item:mat_exp_small=2 char:char_earth_01 captain=20")
	var b := _gift("gems=5 item:mat_exp_small=3 char:char_earth_01 char:char_dark_01 captain=10")
	var m := DebugGift.merge(a, b)
	assert_int(m["gems"]).is_equal(15)
	assert_int(m["materials"]["mat_exp_small"]).is_equal(5)
	assert_int(m["captain_level"]).is_equal(20)
	assert_array(m["characters"]).is_equal(["char_earth_01", "char_dark_01"])
	assert_int(a["gems"]).is_equal(10)                                                # không sửa bản gốc


# ---------- Gói quà mẫu trong data ----------

func test_shipped_presets_are_valid() -> void:
	var presets := DebugGift.load_presets()
	assert_int(presets.size()).is_greater_equal(6)
	for name_: String in presets:
		var info: Dictionary = presets[name_]
		assert_str(str(info.get("title", ""))).override_failure_message("gói %s thiếu title" % name_).is_not_empty()
		var p := DebugGift.parse(str(info.get("gift", "")))
		assert_array(Array(p["errors"])).override_failure_message("gói %s: %s" % [name_, p["errors"]]).is_empty()
		assert_bool(DebugGift.is_empty(p["gift"])).override_failure_message("gói %s rỗng" % name_).is_false()
		assert_array(Array(DebugGift.validate(p["gift"]))).override_failure_message("gói %s có ID lạ" % name_).is_empty()


func test_everything_preset_applies_full_account() -> void:
	var p := _profile()
	var res := DebugGift.apply(p, _gift("preset:everything"))
	assert_bool(res["ok"]).is_true()
	assert_int(p.inventory.currency("gems")).is_equal(50000)
	assert_int(p.inventory.currency("gold")).is_equal(1100000)                        # rich + level_up + enhance + upgrade
	assert_int(p.inventory.material_count("mat_weapon_ascend")).is_equal(30)
	assert_int(p.inventory.material_count("mat_affix_reroll")).is_equal(30)
	assert_int(p.inventory.material_count("mat_exp_small")).is_equal(50)
	assert_int(p.inventory.material_count("mat_enhance_ore")).is_equal(100)
	assert_int(p.inventory.equipment_uids().size()).is_equal(DebugGift.equipment_ids().size())
	for id in DebugGift.character_ids():
		assert_bool(p.progression.owns(id)).override_failure_message(id).is_true()
		assert_int(p.progression.fragments_of(id)).is_equal(100)
	assert_int(p.progression.captain_level()).is_equal(50)


# ---------- Kiểm tra và áp dụng ----------

func test_validate_finds_unknown_ids_and_level_over_max() -> void:
	var g := DebugGift.empty()
	g["materials"]["mat_khong_co"] = 1
	g["equipment"]["eq_khong_co"] = 1
	g["characters"].append("char_khong_co")
	g["fragments"]["char_khac"] = 5
	g["captain_level"] = 9999
	assert_int(DebugGift.validate(g).size()).is_equal(5)
	assert_array(Array(DebugGift.validate(_gift("gems=1 equip:all char:all")))).is_empty()


func test_apply_is_all_or_nothing() -> void:
	var p := _profile()
	var before := p.data.duplicate(true)
	var g := _gift("gems=999 item:mat_exp_small=9 equip:eq_khong_co")
	var res := DebugGift.apply(p, g)
	assert_bool(res["ok"]).is_false()
	assert_str(str(res["errors"])).contains("eq_khong_co")
	assert_dict(p.data).is_equal(before)                                              # không đổi gì, kể cả phần hợp lệ


func test_apply_grants_everything_asked() -> void:
	var p := _profile()
	var res := DebugGift.apply(p, _gift("gems=5000 gold=100 item:mat_exp_small=5 equip:eq_weapon_flame=2 char:char_earth_01 frag:char_dark_01=30 captain=40"))
	assert_bool(res["ok"]).is_true()
	assert_int(p.inventory.currency("gems")).is_equal(5000)
	assert_int(p.inventory.currency("gold")).is_equal(100)
	assert_int(p.inventory.material_count("mat_exp_small")).is_equal(5)
	assert_int(p.inventory.equipment_uids().size()).is_equal(2)
	assert_bool(p.progression.owns("char_earth_01")).is_true()
	assert_bool(p.progression.owns("char_dark_01")).is_true()                         # mảnh tự mở khóa nhân vật chưa có
	assert_int(p.progression.fragments_of("char_dark_01")).is_equal(30)
	assert_int(p.progression.captain_level()).is_equal(40)
	assert_int((res["lines"] as PackedStringArray).size()).is_equal(7)


func test_gift_adds_to_existing_and_never_lowers_captain_level() -> void:
	var p := _profile()
	p.inventory.add_currency("gems", 100)
	assert_bool(DebugGift.apply(p, _gift("gems=100 captain=30"))["ok"]).is_true()
	assert_int(p.inventory.currency("gems")).is_equal(200)
	assert_bool(DebugGift.apply(p, _gift("captain=10"))["ok"]).is_true()
	assert_int(p.progression.captain_level()).is_equal(30)


func test_captain_exp_levels_up_player() -> void:
	var p := _profile()
	var need := p.rules.captain_exp_to_next(1)
	assert_bool(DebugGift.apply(p, _gift("captain_exp=%d" % need))["ok"]).is_true()
	assert_int(p.progression.captain_level()).is_equal(2)


func test_summary_uses_display_names() -> void:
	var lines := "\n".join(DebugGift.summary_lines(_gift("gems=1 gold=2 item:mat_exp_small=3 equip:eq_weapon_flame char:char_earth_01 frag:char_fire_01=4 captain=5 captain_exp=6")))
	assert_bool(lines.contains(tr("CURRENCY_GEMS")) and lines.contains(tr("ITEM_MAT_EXP_SMALL")) and lines.contains(tr("EQUIP_EQ_WEAPON_FLAME"))).is_true()
	assert_bool(lines.contains(tr("CHAR_EARTH_01")) and lines.contains(tr("CHAR_FIRE_01"))).is_true()
	assert_str(DebugGift.short_summary(_gift("equip:all"), 40)).has_length(40, Comparator.LESS_EQUAL)


# ---------- Dòng lệnh ----------

func test_cli_list_help_and_no_args() -> void:
	var l := DebugGift.run_args(PackedStringArray(["--list"]), CLI_DIR)
	assert_int(l["code"]).is_equal(0)
	assert_str("\n".join(l["lines"])).contains("preset:rich").contains("char_earth_01").contains("eq_weapon_flame")
	assert_int(DebugGift.run_args(PackedStringArray(["--help"]), CLI_DIR)["code"]).is_equal(0)
	assert_int(DebugGift.run_args(PackedStringArray(), CLI_DIR)["code"]).is_equal(1)


func test_cli_errors_write_nothing() -> void:
	for args in [["gems=abc"], ["gems=1", "equip:eq_khong_co"], ["khong_hieu"]]:
		var r := DebugGift.run_args(PackedStringArray(args), CLI_DIR)
		assert_int(r["code"]).is_equal(1)
	assert_bool(SaveStore.new(CLI_DIR).has_save()).is_false()


func test_cli_dry_run_does_not_write() -> void:
	var r := DebugGift.run_args(PackedStringArray(["gems=500", "--dry-run"]), CLI_DIR)
	assert_int(r["code"]).is_equal(0)
	assert_str("\n".join(r["lines"])).contains("KHÔNG ghi")
	assert_bool(SaveStore.new(CLI_DIR).has_save()).is_false()


func test_cli_writes_and_accumulates_in_save() -> void:
	assert_int(DebugGift.run_args(PackedStringArray(["gems=100", "char:char_earth_01", "captain=20"]), CLI_DIR)["code"]).is_equal(0)
	var d := SaveStore.new(CLI_DIR).read()
	assert_int(d["currencies"]["gems"]).is_equal(100)
	assert_bool(d["characters"].has("char_earth_01")).is_true()
	assert_int(d["account"]["level"]).is_equal(20)
	# Lần hai cộng thêm vào save đã có; --save-dir= ghi đè thư mục mặc định.
	var r := DebugGift.run_args(PackedStringArray(["gems=100", "--save-dir=" + CLI_DIR]), "user://khong_dung_toi")
	assert_int(r["code"]).is_equal(0)
	assert_int(SaveStore.new(CLI_DIR).read()["currencies"]["gems"]).is_equal(200)
	assert_bool(SaveStore.new("user://khong_dung_toi").has_save()).is_false()


# ---------- Bảng trong game ----------

func _screen() -> DebugGiftScreen:
	var s: DebugGiftScreen = auto_free(SCREEN_SCENE.instantiate())
	add_child(s)
	s.set_anchors_preset(Control.PRESET_TOP_LEFT)
	s.size = Vector2(1920, 1080)
	return s


func _node(n: Node, name_: String) -> Control:
	return n.find_child(name_, true, false) as Control


func test_screen_shows_presets_and_status() -> void:
	var s := _screen()
	for name_ in DebugGift.load_presets():
		assert_object(_node(s, "Preset_" + name_)).override_failure_message(name_).is_not_null()
	assert_object(_node(s, "GiftInput")).is_not_null()
	assert_object(_node(s, "SendButton")).is_not_null()
	assert_str((_node(s, "Status") as Label).text).is_equal(s.status_text())


func test_screen_preset_button_sends_and_saves() -> void:
	var s := _screen()
	(_node(s, "Preset_rich") as Button).pressed.emit()
	assert_int(s.profile.inventory.currency("gems")).is_equal(50000)
	assert_str((_node(s, "Result") as Label).text).contains(tr("DEBUG_GIFT_OK")).contains(tr("CURRENCY_GEMS"))
	assert_str((_node(s, "Status") as Label).text).contains("50000")
	assert_int(SaveStore.new(SAVE_DIR).read()["currencies"]["gems"]).is_equal(50000)   # đã lưu file


func test_screen_custom_text_and_errors() -> void:
	var s := _screen()
	assert_bool(s.send("gold=250 equip:eq_weapon_iron=3")).is_true()
	assert_int(s.profile.inventory.currency("gold")).is_equal(250)
	assert_int(s.profile.inventory.equipment_uids().size()).is_equal(3)
	assert_bool(s.send("gems=10 equip:eq_khong_co")).is_false()
	assert_int(s.profile.inventory.currency("gems")).is_equal(0)                       # không áp nửa chừng
	assert_str(s.result_text).contains(tr("DEBUG_GIFT_ERRORS")).contains("eq_khong_co")
	assert_bool(s.send("gems=abc")).is_false()
	assert_bool(s.send("   ")).is_false()
	assert_str(s.result_text).contains(tr("DEBUG_GIFT_EMPTY"))
	# Ô nhập giữ lại nội dung vừa gửi để sửa tiếp.
	s.send("gems=oops")
	assert_str((_node(s, "GiftInput") as LineEdit).text).is_equal("gems=oops")
	(_node(s, "GiftInput") as LineEdit).text = "gems=7"
	(_node(s, "SendButton") as Button).pressed.emit()
	assert_int(s.profile.inventory.currency("gems")).is_equal(7)


func test_screen_available_only_in_debug_and_hub_button_follows() -> void:
	DebugGiftScreen.force_available = false
	assert_bool(DebugGiftScreen.available()).is_false()
	var hub: Control = auto_free(HUB_SCENE.instantiate())
	add_child(hub)
	hub.show_tab("SettingsTab")
	assert_object(hub.find_child("DebugGiftButton", true, false)).is_null()           # bản Release: không có nút
	DebugGiftScreen.force_available = true
	hub.show_tab("HomeTab")
	hub.show_tab("SettingsTab")
	assert_object(hub.find_child("DebugGiftButton", true, false)).is_not_null()
	DebugGiftScreen.force_available = null
	assert_bool(DebugGiftScreen.available()).is_equal(OS.is_debug_build())


## Event nguyên liệu: mở sẵn ải (không sao, không nhận thưởng lần đầu), đặt lại lượt có thưởng.
func test_event_unlock_and_reset_tokens() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var mg := MinigameProgress.new(p)
	var reg := MinigameRegistry.load_from()
	var lim := reg.limit_for("evt_material", "rhythm")
	mg.begin_play(lim["key"], lim["limit"])
	var parsed := DebugGift.parse("event:rhythm/all event_reset")
	assert_array(parsed["errors"]).is_empty()
	assert_int((parsed["gift"]["event_clear"] as Array).size()).is_equal(5)
	assert_bool(DebugGift.is_empty(parsed["gift"])).is_false()
	var res := DebugGift.apply(p, parsed["gift"])
	assert_bool(res["ok"]).is_true()
	assert_bool(mg.is_cleared("rhythm", "rhythm_mat_05")).is_true()
	assert_bool(mg.mode_unlocked(reg.mode("evt_material", "rhythm_endless"))).is_true()
	assert_int(mg.star_count("rhythm", "rhythm_mat_01")).is_equal(0)
	assert_bool(bool(mg.record("rhythm", "rhythm_mat_01")["first_clear_claimed"])).is_false()
	assert_int(mg.remaining(lim["key"], lim["limit"])).is_equal(50)
	assert_bool(" ".join(res["lines"]).contains("rhythm/rhythm_mat_05")).is_true()
	# event:all và gói mẫu.
	assert_int((DebugGift.parse("event:all")["gift"]["event_clear"] as Array).size()).is_equal(15)   # 5 Nhịp điệu + 5 Chạy + 5 Bay
	assert_int((DebugGift.parse("preset:event_open_to_boss")["gift"]["event_clear"] as Array).size()).is_equal(4)
	# Ải / chế độ lạ: từ chối cả gói.
	var bad := DebugGift.parse("gems=10 event:rhythm/khong_co")
	assert_bool(DebugGift.apply(PlayerProfile.new(SaveSchema.default_data()), bad["gift"])["ok"]).is_false()
	assert_bool(DebugGift.validate(DebugGift.parse("event:zzz/all")["gift"]).is_empty()).is_false()
	assert_array(DebugGift.parse("event:")["errors"]).is_not_empty()


## Cốt truyện chính: stage:all mở mọi ải trừ ải cuối (ải cuối vẫn mở để chơi), đặt hướng dẫn người mới là xong.
func test_stage_unlock_token() -> void:
	var all := DebugGift.story_stage_ids()
	assert_int(all.size()).is_greater_equal(10)
	var parsed := DebugGift.parse("stage:all")
	assert_array(parsed["errors"]).is_empty()
	var picked: Array = parsed["gift"]["stage_clear"]
	assert_int(picked.size()).is_equal(all.size() - 1)
	assert_bool(all[all.size() - 1] in picked).is_false()
	assert_bool(DebugGift.is_empty(parsed["gift"])).is_false()
	var p := PlayerProfile.new(SaveSchema.default_data())
	assert_bool(bool(p.data["tutorial"]["done"])).is_false()
	var res := DebugGift.apply(p, parsed["gift"])
	assert_bool(res["ok"]).is_true()
	var book := ChapterBook.new(p.data)
	var last := ChapterBook.all_stages().filter(func(s: Dictionary) -> bool: return str(s.get("stage_id", "")) == all[all.size() - 1])
	assert_int(last.size()).is_equal(1)
	assert_str(book.state_of(last[0])).is_equal(ChapterBook.STATE_OPEN)
	assert_bool(book.is_cleared(book.stages_of(1)[0])).is_true()
	assert_bool(bool(p.data["tutorial"]["done"])).is_true()
	assert_bool(" ".join(res["lines"]).contains(str(picked.size()))).is_true()
	# Danh sách đã xem (clip, bark) không bị xóa.
	var w := PlayerProfile.new(SaveSchema.default_data())
	TutorialFlow.mark_seen(w.data, "clip:ch01_end")
	DebugGift.apply(w, parsed["gift"])
	assert_bool(TutorialFlow.has_seen(w.data, "clip:ch01_end")).is_true()
	# Một ải riêng lẻ; không ghi đè tiến độ ải đã qua (huy chương giữ nguyên).
	var q := PlayerProfile.new(SaveSchema.default_data())
	q.data["progress"]["stages"]["stage_01"] = {"cleared": true, "best_time_sec": 61.0, "objectives": ["time"]}
	assert_bool(DebugGift.apply(q, DebugGift.parse("stage:stage_01 stage:stage_01_02")["gift"])["ok"]).is_true()
	assert_float(float(q.data["progress"]["stages"]["stage_01"]["best_time_sec"])).is_equal(61.0)
	assert_int((q.data["progress"]["stages"]["stage_01"]["objectives"] as Array).size()).is_equal(1)
	assert_bool(bool(q.data["progress"]["stages"]["stage_01_02"]["cleared"])).is_true()
	# Gói mẫu, ải lạ và thiếu ải bị từ chối.
	assert_int((DebugGift.parse("preset:open_stages")["gift"]["stage_clear"] as Array).size()).is_equal(all.size() - 1)
	var bad := DebugGift.parse("gems=10 stage:khong_co")
	assert_bool(DebugGift.apply(PlayerProfile.new(SaveSchema.default_data()), bad["gift"])["ok"]).is_false()
	assert_array(DebugGift.parse("stage:")["errors"]).is_not_empty()


## clips_reset: xóa chỉ các clip đã xem, giữ hướng dẫn / bark; gói open_stages có kèm.
func test_clips_reset_token() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	TutorialFlow.mark_seen(p.data, "clip:ch01_end")
	TutorialFlow.mark_seen(p.data, "clip:ch01_golem")
	TutorialFlow.mark_seen(p.data, "bark:abc")
	var parsed := DebugGift.parse("clips_reset")
	assert_array(parsed["errors"]).is_empty()
	assert_bool(DebugGift.is_empty(parsed["gift"])).is_false()
	var res := DebugGift.apply(p, parsed["gift"])
	assert_bool(res["ok"]).is_true()
	assert_bool(TutorialFlow.has_seen(p.data, "clip:ch01_end")).is_false()
	assert_bool(TutorialFlow.has_seen(p.data, "clip:ch01_golem")).is_false()
	assert_bool(TutorialFlow.has_seen(p.data, "bark:abc")).is_true()
	assert_int((res["lines"] as PackedStringArray).size()).is_equal(1)
	assert_bool(bool(DebugGift.parse("preset:open_stages")["gift"]["clips_reset"])).is_true()
