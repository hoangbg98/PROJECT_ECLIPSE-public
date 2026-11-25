extends GdUnitTestSuite
## Khung Event nguyên liệu (M11-2, M11-3): kiểm tra dữ liệu, màn chạy lượt (host) với scene chơi giả, adapter Nhịp điệu,
## hub event, chọn ải, danh sách bài Vô tận.

const EVT := "evt_material"
const FAKE_SCENE := "res://tests/unit/minigame/support/fake_minigame.tscn"
const HOST_SCENE := preload("res://scenes/main/minigame/minigame_host.tscn")
const HUB_SCENE := preload("res://scenes/main/minigame/event_hub_screen.tscn")
const SELECT_SCENE := preload("res://scenes/main/minigame/stage_select_screen.tscn")
const SONGS_SCENE := preload("res://scenes/main/rhythm_song_list_screen.tscn")
const MON_0400 := 1794801600

var _servers: Array = []


func after_test() -> void:
	GameConfig.minigame_launch = {}
	GameConfig.event_mode_id = ""


func _item_ids() -> PackedStringArray:
	return PlayerProfile.item_defs().ids()


func _result(cleared := true, rank := "S") -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = cleared
	r.rank = rank
	r.score = 7777
	r.stats = {"accuracy": 0.97, "miss": 0, "max_combo": 120, "holds_broken": 0, "hp_left_ratio": 1.0, "perfect_ratio": 0.9}
	return r


# ---------- EventValidator ----------

func test_shipped_event_data_is_valid() -> void:
	var reg := MinigameRegistry.load_from()
	var v := EventValidator.validate(reg.data, _item_ids())
	assert_array(v["errors"]).is_empty()
	assert_array(v["warnings"]).is_empty()


func test_validator_catches_bad_data() -> void:
	var stage := func(id: String, req: Array, stars: Array, pos := [0.5, 0.5], mats := {"mat_exp_small": 1}) -> Dictionary:
		return {"id": id, "title_key": "", "pos": pos, "requires": req, "stars": stars,
				"rewards": {"base": {"gold": 1, "materials": mats}, "rank_mult": {"S": 1, "A": 1}}}
	var data := {"format": 1, "events": [{"id": "e", "modes": [
		{"id": "rhythm", "scene": "res://khong_co.tscn", "layout": "graph", "stages": [
			stage.call("a", [], ["clear", "rank>=A", "stat:miss==0"]),
			stage.call("a", [], ["clear"]),                                          # trùng id + thiếu sao
			stage.call("b", ["x"], ["clear", "rank>=Z", "stat:khoa_la>=1"], [1.5, 0.2], {"vat_la": 1}),
			stage.call("c", ["d"], ["clear", "rank>=A", "rank>=S"]),
			stage.call("d", ["c"], ["clear", "rank>=A", "rank>=S"]),                 # vòng c <-> d
		]},
		{"id": "rhythm", "scene": FAKE_SCENE, "layout": "weird", "limit": {"share_with": "zzz"}, "stages": []},
	]}]}
	var v := EventValidator.validate(data, _item_ids())
	var all := "\n".join(v["errors"])
	for frag in ["không có scene", "trùng", "đúng 3 điều kiện", "requires trỏ tới ải không có", "hạng sai", "pos",
			"vật phẩm không có", "rank_mult thiếu hạng", "vòng phụ thuộc", "không tới được", "layout lạ", "share_with"]:
		assert_bool(all.contains(frag)).override_failure_message("thiếu lỗi: " + frag + "\n" + all).is_true()
	assert_bool("\n".join(v["warnings"]).contains("khoa_la")).is_true()
	# Tham số ải ngoài khoảng an toàn / chữ không hợp lệ.
	var good: Dictionary = MinigameRegistry.load_from().data.duplicate(true)
	var p: Dictionary = good["events"][0]["modes"][0]["stages"][0]["params"]
	p["speed"]["note_speed"] = 9000
	p["spawn"]["density"] = 0.0
	p["music"]["chart"] = "insane"
	good["events"][0]["modes"][1]["endless"]["by_difficulty"].erase("hard")
	var bad := "\n".join(EventValidator.validate(good, _item_ids())["errors"])
	for frag in ["speed.note_speed", "spawn.density", "music.chart", "by_difficulty.hard"]:
		assert_bool(bad.contains(frag)).override_failure_message("thiếu lỗi: " + frag + "\n" + bad).is_true()


# ---------- MinigameHost ----------

func _registry() -> MinigameRegistry:
	var reg := MinigameRegistry.load_from()
	var data: Dictionary = reg.data.duplicate(true)
	for m in data["events"][0]["modes"]:
		m["scene"] = FAKE_SCENE
	data["events"][0]["modes"][0]["limit"] = {"period": "weekly", "max": 2, "reset_hour": 4}
	reg.data = data
	return reg


func _host(p: PlayerProfile, reg: MinigameRegistry, stage_id := "rhythm_mat_01", mode := "rhythm") -> MinigameHost:
	var h := HOST_SCENE.instantiate() as MinigameHost
	h.registry = reg
	h.profile = p
	h.progress = MinigameProgress.new(p)
	h.progress.clock = func() -> int: return MON_0400
	h.progress.tz_offset = 0
	h.save_enabled = false
	h.navigate_enabled = false
	h.launch = {"event_id": EVT, "mode_id": mode, "stage": reg.stage(EVT, mode, stage_id)}
	add_child(auto_free(h))
	return h


func test_host_play_finish_rewards_and_retry() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var reg := _registry()
	var h := _host(p, reg)
	var st := h.stage_node
	assert_bool(st.started).is_true()
	assert_bool(st.ctx.is_first_play).is_true()
	assert_str(str(st.ctx.params["music"]["song"])).is_equal("song_ember_steps")
	assert_array(Array(st.ctx.party)).is_equal(["char_fire_01"])
	st.play_started.emit()
	assert_bool(h.rewarded).is_true()
	assert_bool(h.progress.tutorial_seen("rhythm", "rhythm_mat_01")).is_true()
	var gold0 := p.inventory.currency("gold")
	st.finished.emit(_result())
	assert_object(h.result_screen).is_not_null()
	assert_bool(h.last_outcome["first_clear"]).is_true()
	assert_array(h.last_outcome["new_stars"]).is_equal([1, 2, 3])
	assert_int(p.inventory.currency("gold") - gold0).is_equal(2250)
	assert_object(h.result_screen.find_child("Star_3", true, false)).is_not_null()
	assert_bool((h.result_screen.find_child("Rewards", true, false) as Label).text.contains("×")).is_true()
	# Chơi lại: scene chơi mới, hướng dẫn không hiện nữa.
	h.result_screen.retry_pressed.emit()
	assert_object(h.result_screen).is_null()
	assert_bool(h.stage_node.ctx.is_first_play).is_false()
	assert_bool(h.played).is_false()


func test_host_limit_exhausted_plays_without_reward() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var reg := _registry()
	var h := _host(p, reg)
	for i in 2:
		h.stage_node.play_started.emit()
		h.stage_node.finished.emit(_result(false))
		h.retry()
	assert_bool(h.stage_node.ctx.practice).is_true()   # hết 2 lượt có thưởng
	h.stage_node.play_started.emit()
	assert_bool(h.rewarded).is_false()
	var gold0 := p.inventory.currency("gold")
	h.stage_node.finished.emit(_result())
	assert_int(p.inventory.currency("gold")).is_equal(gold0)
	assert_str((h.result_screen.find_child("Rewards", true, false) as Label).text).contains(tr("EVENT_NO_REWARD_LIMIT"))
	assert_bool(h.progress.is_cleared("rhythm", "rhythm_mat_01")).is_true()
	assert_int(h.progress.star_count("rhythm", "rhythm_mat_01")).is_equal(0)


func test_host_quit_before_and_after_start() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var reg := _registry()
	var h := _host(p, reg)
	h.stage_node.quit_requested.emit()   # thoát lúc tải / hướng dẫn: không tốn lượt
	assert_bool(h.left).is_true()
	var lim := reg.limit_for(EVT, "rhythm")
	assert_int(h.progress.remaining(lim["key"], lim["limit"])).is_equal(2)
	var h2 := _host(p, reg)
	h2.stage_node.play_started.emit()
	h2.stage_node.finished.emit(MinigameResult.quit_result(3.0))   # thoát giữa chừng: tốn lượt, không màn kết quả
	assert_bool(h2.left).is_true()
	assert_object(h2.result_screen).is_null()
	assert_int(h2.progress.remaining(lim["key"], lim["limit"])).is_equal(1)
	assert_int(int(h2.progress.record("rhythm", "rhythm_mat_01")["plays"])).is_equal(1)


func test_host_endless_stage_and_shared_limit() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var reg := _registry()
	var h := HOST_SCENE.instantiate() as MinigameHost
	h.registry = reg
	h.profile = p
	h.progress = MinigameProgress.new(p)
	h.progress.clock = func() -> int: return MON_0400
	h.progress.tz_offset = 0
	h.save_enabled = false
	h.navigate_enabled = false
	h.launch = {"event_id": EVT, "mode_id": "rhythm_endless", "stage": reg.endless_stage(EVT, "rhythm_endless", "song_a", "hard")}
	add_child(auto_free(h))
	assert_str(h.tutorial_mode()).is_equal("rhythm")
	h.stage_node.play_started.emit()
	h.stage_node.finished.emit(_result(true, "A"))
	assert_bool(h.progress.is_cleared("rhythm_endless", "endless:song_a:hard")).is_true()
	var lim := reg.limit_for(EVT, "rhythm")
	assert_int(h.progress.remaining(lim["key"], lim["limit"])).is_equal(1)   # trừ chung lượt với ải


# ---------- Adapter Nhịp điệu ----------

func test_rhythm_adapter_embedded_stage_to_result() -> void:
	var a := (load("res://scenes/main/minigame/rhythm_minigame.tscn") as PackedScene).instantiate() as RhythmMinigameAdapter
	var ctx := MinigameContext.new()
	ctx.params = {"music": {"song": "x", "chart": "easy"}}
	a.setup(ctx)
	add_child(auto_free(a))
	var got: Array = []
	var started := [false]
	a.finished.connect(func(r: MinigameResult) -> void: got.append(r))
	a.play_started.connect(func() -> void: started[0] = true)
	var s := (load("res://scenes/main/rhythm_stage.tscn") as PackedScene).instantiate() as RhythmStage
	s.setup(RhythmChart.from_dict({"format": 1, "notes": [{"t": 0.5, "lane": "up"}, {"t": 1.0, "lane": "down", "kind": "hold", "dur": 0.5}]}),
			null, "", "T")
	s.manual_clock = true
	s.autoplay = true
	s.profile = PlayerProfile.new(SaveSchema.default_data())
	a.attach(s)
	assert_bool(s.embedded).is_true()
	s.advance(1.0)
	a.poll()
	assert_bool(started[0]).is_false()   # còn đếm ngược
	s.advance(1.1)
	a.poll()
	assert_bool(started[0]).is_true()
	s.advance(6.0)
	assert_int(got.size()).is_equal(1)
	var r: MinigameResult = got[0]
	assert_bool(r.cleared).is_true()
	assert_str(r.rank).is_equal("S")
	assert_float(float(r.stats["accuracy"])).is_equal(1.0)
	assert_int(int(r.stats["miss"])).is_equal(0)
	assert_float(float(r.stats["hp_left_ratio"])).is_equal(1.0)
	assert_int(int(r.stats["holds_broken"])).is_equal(0)
	assert_float(float(r.stats["perfect_ratio"])).is_equal(1.0)
	assert_object(s.find_child("ResultLayer", true, false)).is_null()   # không màn kết quả riêng


func test_rhythm_adapter_quit_paths() -> void:
	var a := (load("res://scenes/main/minigame/rhythm_minigame.tscn") as PackedScene).instantiate() as RhythmMinigameAdapter
	a.setup(MinigameContext.new())
	add_child(auto_free(a))
	var quits := [0]
	var got: Array = []
	a.quit_requested.connect(func() -> void: quits[0] += 1)
	a.finished.connect(func(r: MinigameResult) -> void: got.append(r))
	var s := (load("res://scenes/main/rhythm_stage.tscn") as PackedScene).instantiate() as RhythmStage
	s.setup(RhythmChart.from_dict({"format": 1, "notes": [{"t": 3.0, "lane": "up"}]}), null, "", "T")
	s.manual_clock = true
	s.profile = PlayerProfile.new(SaveSchema.default_data())
	a.attach(s)
	s.quit()                       # đang đếm ngược: không tính lượt
	assert_int(quits[0]).is_equal(1)
	s.advance(2.5)
	a.poll()
	s.quit()                       # đang chơi: kết quả "quit"
	assert_int(got.size()).is_equal(1)
	assert_str((got[0] as MinigameResult).fail_reason).is_equal("quit")


# ---------- Hub, chọn ải, danh sách bài ----------

func _screen(scene: PackedScene, p: PlayerProfile) -> HubScreen:
	var s := scene.instantiate() as HubScreen
	s.profile = p
	s.save_enabled = false
	s.navigate_enabled = false
	add_child(auto_free(s))
	return s


func test_event_hub_cards_and_navigation() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var hub := _screen(HUB_SCENE, p) as EventHubScreen
	# Thẻ chế độ: Nhịp điệu, Chạy, Bay (Vô tận là chế độ con, không có thẻ riêng).
	assert_array(hub.card_buttons.keys()).contains_exactly(["rhythm", "runner", "jet"])
	assert_str((hub.find_child("Drops_rhythm", true, false) as Label).text).is_equal(tr("MODE_RHYTHM_DROPS"))
	assert_str((hub.find_child("Plays_rhythm", true, false) as Label).text).is_equal("50/50")
	assert_object(hub.find_child("Tag_runner", true, false)).is_null()   # Chạy Nguyên Tố đã mở (M11-4)
	assert_object(hub.find_child("Tag_jet", true, false)).is_null()   # Bay Nguyên Tố đã mở (M11-5)
	assert_object(hub.find_child("Art_rhythm", true, false).get_child(1)).is_not_null()   # có lớp ảnh
	hub.activate("jet")
	assert_str(hub.last_target).is_equal(GameConfig.SCENE_STAGE_SELECT)
	assert_str(GameConfig.event_mode_id).is_equal("jet")
	hub.activate("runner")
	assert_str(hub.last_target).is_equal(GameConfig.SCENE_STAGE_SELECT)
	assert_str(GameConfig.event_mode_id).is_equal("runner")
	hub.activate("rhythm")
	assert_str(hub.last_target).is_equal(GameConfig.SCENE_STAGE_SELECT)
	assert_str(GameConfig.event_mode_id).is_equal("rhythm")
	# Vô tận: nút trong màn chọn ải Nhịp điệu, khóa tới khi qua N-5.
	var sel := _screen(SELECT_SCENE, p) as StageSelectScreen
	assert_object(sel.find_child("Child_rhythm_endless", true, false)).is_not_null()
	sel.open_child("rhythm_endless")
	assert_str(sel.notice).is_equal(tr("EVENT_LOCKED_NEED") % "N-5")
	var prog := MinigameProgress.new(p)
	var reg := MinigameRegistry.load_from()
	for i in range(1, 6):
		prog.submit("rhythm", reg.stage(EVT, "rhythm", "rhythm_mat_0%d" % i), _result(), true)
	sel.refresh()
	sel.open_child("rhythm_endless")
	assert_str(sel.last_target).is_equal("res://scenes/main/rhythm_song_list_screen.tscn")
	assert_str(GameConfig.event_mode_id).is_equal("rhythm_endless")
	assert_str(EventHubScreen.duration_text(3 * 86400 + 2 * 3600 + 59)).is_equal(tr("EVENT_TIME_DH") % [3, 2])


func test_stage_select_graph_lock_party_and_launch() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	GameConfig.event_mode_id = "rhythm"
	var s := _screen(SELECT_SCENE, p) as StageSelectScreen
	assert_int(s.node_buttons.size()).is_equal(5)
	assert_str(s.selected).is_equal("rhythm_mat_01")
	assert_object(s.find_child("InfoText", true, false)).is_not_null()
	s.select("rhythm_mat_03")
	s.play_selected()
	assert_str(s.notice).is_equal(tr("EVENT_STAGE_LOCKED"))
	assert_str(s.last_target).is_equal("")
	# Ải đòi đội 2 người, đội chỉ có Enkiba.
	var st: Dictionary = s.registry.stage(EVT, "rhythm", "rhythm_mat_01").duplicate(true)
	st["party_min"] = 2
	assert_str(s.block_reason(st)).is_equal(tr("EVENT_PARTY_TOO_SMALL") % [1, 2])
	s.select("rhythm_mat_01")
	s.play_selected()
	assert_str(s.last_target).is_equal(GameConfig.SCENE_MINIGAME_HOST)
	assert_str(str(GameConfig.minigame_launch["mode_id"])).is_equal("rhythm")
	assert_str(str(GameConfig.minigame_launch["stage"]["id"])).is_equal("rhythm_mat_01")
	assert_str(s.star_text("rhythm_mat_01")).is_equal("☆☆☆")


class Srv:
	var catalog: Dictionary

	func fetch(url: String) -> Dictionary:
		await Engine.get_main_loop().process_frame
		if url.ends_with("catalog.json"):
			return {"ok": true, "code": 200, "body": JSON.stringify(catalog).to_utf8_buffer(), "error": ""}
		return {"ok": false, "code": 404, "body": PackedByteArray(), "error": "http_404"}


func test_song_list_uses_framework_records_and_launch() -> void:
	var srv := Srv.new()
	_servers.append(srv)
	var songs: Array = []
	for id in ["song_a", "song_b"]:
		var charts := {}
		for k in ["easy", "normal", "hard"]:
			charts[k] = {"file": "%s_%s.json" % [id, k], "sha256": "x", "bytes": 10, "level": 3}
		songs.append({"id": id, "title": id.to_upper(), "artist": "T", "audio": {"file": id + ".wav", "sha256": "x", "bytes": 1}, "charts": charts})
	srv.catalog = {"format": 1, "songs": songs}
	var p := PlayerProfile.new(SaveSchema.default_data())
	var prog := MinigameProgress.new(p)
	prog.submit("rhythm_endless", {"id": "endless:song_b:normal", "stars": []}, _result(true, "A"), false)
	var s := SONGS_SCENE.instantiate() as RhythmSongListScreen
	s.profile = p
	s.save_enabled = false
	s.navigate_enabled = false
	s.library = RhythmLibrary.new("http://h/music/", srv.fetch, "user://test_minigame_songs_cache")
	add_child(auto_free(s))
	for i in 300:
		if s.catalog_state != "loading" and s.catalog_state != "":
			break
		await get_tree().process_frame
	assert_int(s.row_buttons.size()).is_equal(2)
	var row := s.find_child("Row_song_b", true, false)
	var texts: Array = []
	for c in row.get_children():
		if c is Label:
			texts.append((c as Label).text)
	assert_bool(texts.has("♛♛♔")).is_true()   # hạng A
	s.toggle_favorite("song_a")
	assert_bool(MinigameProgress.new(p).is_favorite("rhythm_endless", "song_a")).is_true()
	s.play_song("song_a")
	assert_str(s.last_target).is_equal(GameConfig.SCENE_MINIGAME_HOST)
	assert_str(str(GameConfig.minigame_launch["stage"]["id"])).is_equal("endless:song_a:normal")
	assert_float(float(GameConfig.minigame_launch["stage"]["params"]["speed"]["note_speed"])).is_equal(850.0)
	assert_str(str(GameConfig.minigame_launch["stage"]["params"]["music"]["chart"])).is_equal("normal")


func test_runner_route_list_and_endless_button() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	GameConfig.event_mode_id = "runner"
	var sel := _screen(SELECT_SCENE, p) as StageSelectScreen
	assert_int(sel.stages().size()).is_equal(5)
	assert_object(sel.find_child("Child_runner_endless", true, false)).is_not_null()
	GameConfig.event_mode_id = "runner_endless"
	var scr := _screen(load("res://scenes/main/minigame/runner_route_list_screen.tscn"), p) as RunnerRouteListScreen
	assert_int(scr.row_buttons.size()).is_equal(3)
	scr.select_difficulty("hard")
	assert_str((scr.find_child("Info", true, false) as Label).text).contains("1000")
	# Đội 1 người: chặn (cần 3).
	scr.play_route("route_drift")
	assert_str(scr.notice).is_equal(tr("EVENT_PARTY_TOO_SMALL") % [1, 3])
	p.data["party"] = ["char_fire_01", "char_wind_01", "char_lightning_01"]
	scr.play_route("route_drift")
	assert_str(str(GameConfig.minigame_launch["stage"]["id"])).is_equal("endless:route_drift:hard")
	assert_str(str(GameConfig.minigame_launch["mode_id"])).is_equal("runner_endless")


func test_jet_endless_screen_entries_and_practice() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	GameConfig.event_mode_id = "jet"
	var sel := _screen(SELECT_SCENE, p) as StageSelectScreen
	assert_int(sel.stages().size()).is_equal(5)
	assert_object(sel.find_child("Child_jet_endless", true, false)).is_not_null()
	GameConfig.event_mode_id = "jet_endless"
	var scr := _screen(load("res://scenes/main/minigame/jet_endless_screen.tscn"), p) as JetEndlessScreen
	scr.seed_override = 777
	assert_array(scr.row_buttons.keys()).contains_exactly(["all", "zone_1", "zone_2", "zone_3"])
	scr.play_entry("zone_2")
	var st: Dictionary = GameConfig.minigame_launch["stage"]
	assert_str(str(st["id"])).is_equal("endless:zone_2")
	assert_bool(bool(st["practice"])).is_true()
	assert_bool(RewardService.is_empty(st["rewards"].get("base", {}))).is_true()
	assert_int(int(st["params"]["seed"])).is_equal(777)
	assert_str(str(st["params"]["endless"]["zone"])).is_equal("wind")
	scr.play_entry("all")
	st = GameConfig.minigame_launch["stage"]
	assert_bool(bool(st["practice"])).is_false()
	assert_str(str(st["params"]["endless"]["zone"])).is_equal("")
