extends SceneTree
## Chụp Event nguyên liệu / Nhịp điệu (M11) với máy chủ thật (cổng vào server/gateway.mjs đang chạy, đã build_catalog):
##   <godot> --path . -s tools/screenshot_rhythm.gd
## Bước: hub event → chọn ải → lượt N-1 qua MinigameHost (hướng dẫn, rồi tự chơi bằng đồng hồ tay) → màn kết quả chung
## → chọn ải có sao → lượt boss N-5 → danh sách Vô tận. Hồ sơ thử riêng, không ghi save.
## Ảnh ra build/screenshots/rhythm_<n>.png.

const EVT := "evt_material"

var _frames := 0
var _step := 0
var _screen: Node
var _profile: PlayerProfile
var _reg: MinigameRegistry


func _process(_delta: float) -> bool:
	_frames += 1
	match _step:
		0:
			if _frames < 3:
				return false
			_profile = PlayerProfile.new(SaveSchema.default_data())
			_reg = MinigameRegistry.load_from()
			_screen = _open("res://scenes/main/minigame/event_hub_screen.tscn")
			_next(1)
		1:
			if _frames < 4:
				return false
			_shot("0_event_hub")
			_screen.queue_free()
			root.get_node("GameConfig").event_mode_id = "rhythm"
			_screen = _open("res://scenes/main/minigame/stage_select_screen.tscn")
			_next(2)
		2:
			if _frames < 4:
				return false
			_shot("1_stage_select")
			_screen.queue_free()
			_screen = _host("rhythm", "rhythm_mat_01")
			_next(3)
		3:
			# Chờ adapter tải danh mục / bài rồi dựng RhythmStage.
			var stage: RhythmStage = _rhythm_stage()
			if stage == null or _frames < 5:
				return _frames > 1200
			stage.advance(3.6)
			_next(4)
		4:
			if _frames < 2:
				return false
			_shot("2_tutorial")
			var stage: RhythmStage = _rhythm_stage()
			stage.skip_tutorial()
			stage.advance(22.05)
			_next(5)
		5:
			if _frames < 2:
				return false
			_shot("3_stage")
			_rhythm_stage().advance(200.0)
			_next(6)
		6:
			if _frames < 3:
				return false
			print("kết quả: ", _screen.last_outcome)
			_shot("4_result")
			_screen.queue_free()
			var prog := MinigameProgress.new(_profile)
			for i in range(2, 5):
				prog.submit("rhythm", _reg.stage(EVT, "rhythm", "rhythm_mat_0%d" % i), _fake_result("A"), true)
			_screen = _open("res://scenes/main/minigame/stage_select_screen.tscn")
			_next(7)
		7:
			if _frames < 4:
				return false
			_shot("5_stage_select_stars")
			_screen.queue_free()
			_screen = _host("rhythm", "rhythm_mat_05")
			_next(8)
		8:
			var stage: RhythmStage = _rhythm_stage()
			if stage == null or _frames < 5:
				return _frames > 1200
			stage.advance(5.0 + 30.1)
			_next(9)
		9:
			if _frames < 2:
				return false
			_shot("6_boss")
			_screen.queue_free()
			MinigameProgress.new(_profile).submit("rhythm", _reg.stage(EVT, "rhythm", "rhythm_mat_05"), _fake_result("S"), true)
			root.get_node("GameConfig").event_mode_id = "rhythm_endless"
			_screen = _open("res://scenes/main/minigame/event_hub_screen.tscn")
			_next(10)
		10:
			if _frames < 4:
				return false
			_shot("7_event_hub_open")
			_screen.queue_free()
			_screen = _open("res://scenes/main/rhythm_song_list_screen.tscn")
			_next(11)
		11:
			if _screen.catalog_state == "loading" or _frames < 5:
				return false
			_shot("8_endless")
			return true
	return false


func _next(step: int) -> void:
	_step = step
	_frames = 0


func _open(path: String) -> Node:
	var s := (load(path) as PackedScene).instantiate()
	s.profile = _profile
	s.save_enabled = false
	s.navigate_enabled = false
	root.add_child(s)
	return s


func _host(mode_id: String, stage_id: String) -> MinigameHost:
	var h := (load("res://scenes/main/minigame/minigame_host.tscn") as PackedScene).instantiate() as MinigameHost
	h.profile = _profile
	h.registry = _reg
	h.save_enabled = false
	h.navigate_enabled = false
	h.launch = {"event_id": EVT, "mode_id": mode_id, "stage": _reg.stage(EVT, mode_id, stage_id)}
	h.configure_stage = func(st: MinigameStage) -> void:
		st.manual_clock = true
		st.autoplay = true
		st.profile = _profile
	root.add_child(h)
	return h


func _rhythm_stage() -> RhythmStage:
	var a: RhythmMinigameAdapter = _screen.stage_node if _screen is MinigameHost else null
	return a.stage if a and a.stage and a.stage.is_inside_tree() else null


func _fake_result(rank: String) -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = true
	r.rank = rank
	r.score = 30000
	r.stats = {"accuracy": 0.96, "miss": 1, "max_combo": 200, "holds_broken": 0, "hp_left_ratio": 0.9, "perfect_ratio": 0.8}
	return r


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/rhythm_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
