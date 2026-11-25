extends SceneTree
## Chụp Chạy Nguyên Tố (M11-4): <godot> --path . -s tools/screenshot_runner.gd
## Hub event → chọn ải Chạy → lượt N-1 (đếm ngược, đang chạy) → N-3 (đội 3 người, cổng) → màn kết quả → đồ thị 5
## ải có sao → boss N-5 → danh sách tuyến Vô tận.
## Bot chơi; hồ sơ thử riêng, không ghi save. Ảnh ra build/screenshots/runner_<n>.png.

const EVT := "evt_material"

var _frames := 0
var _step := 0
var _screen: Node
var _profile: PlayerProfile
var _reg: MinigameRegistry
var _bot: RunnerBot


func _process(_delta: float) -> bool:
	_frames += 1
	match _step:
		0:
			if _frames < 3:
				return false
			_profile = PlayerProfile.new(SaveSchema.default_data())
			_profile.data["party"] = ["char_fire_01", "char_wind_01", "char_lightning_01"]
			_reg = MinigameRegistry.load_from()
			_screen = _open("res://scenes/main/minigame/event_hub_screen.tscn")
			_next(1)
		1:
			if _frames < 4:
				return false
			_shot("0_event_hub")
			_screen.queue_free()
			root.get_node("GameConfig").event_mode_id = "runner"
			_screen = _open("res://scenes/main/minigame/stage_select_screen.tscn")
			_next(2)
		2:
			if _frames < 4:
				return false
			_shot("1_stage_select")
			_screen.queue_free()
			_screen = _host("runner_mat_01")
			_next(3)
		3:
			if _frames < 4:
				return false
			_stage().advance(1.2)
			_next(4)
		4:
			if _frames < 2:
				return false
			_shot("2_countdown")
			_play_until(_stage(), 2.0 + 9.85)
			_next(5)
		5:
			if _frames < 2:
				return false
			_shot("3_n1_run")
			_screen.queue_free()
			_screen = _host("runner_mat_03")
			_next(6)
		6:
			if _frames < 4:
				return false
			var s := _stage()
			s.advance(3.1)
			_bot = RunnerBot.new(s.sim)
			_play_until(s, _first_gate_t(s) - 0.12)
			_next(7)
		7:
			if _frames < 2:
				return false
			_shot("4_n3_gate")
			_play_until(_stage(), 200.0)
			_next(8)
		8:
			if _frames < 4:
				return false
			_shot("5_result")
			_screen.queue_free()
			var prog := MinigameProgress.new(_profile)
			for i in range(1, 5):
				prog.submit("runner", _reg.stage(EVT, "runner", "runner_mat_0%d" % i), _fake_result(), true)
			root.get_node("GameConfig").event_mode_id = "runner"
			_screen = _open("res://scenes/main/minigame/stage_select_screen.tscn")
			_next(9)
		9:
			if _frames < 4:
				return false
			_shot("6_stage_select_all")
			_screen.queue_free()
			_screen = _host("runner_mat_05")
			_next(10)
		10:
			if _frames < 4:
				return false
			var s := _stage()
			s.advance(3.1)
			_bot = RunnerBot.new(s.sim)
			_play_until(s, 31.0)
			_next(11)
		11:
			if _frames < 2:
				return false
			_shot("7_boss")
			_screen.queue_free()
			MinigameProgress.new(_profile).submit("runner", _reg.stage(EVT, "runner", "runner_mat_05"), _fake_result(), true)
			root.get_node("GameConfig").event_mode_id = "runner_endless"
			_screen = _open("res://scenes/main/minigame/runner_route_list_screen.tscn")
			_next(12)
		12:
			if _frames < 4:
				return false
			_shot("8_endless_routes")
			return true
	return false


func _fake_result() -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = true
	r.rank = "A"
	r.score = 9000
	r.stats = {"accuracy": 0.92, "max_combo": 40, "hits_taken": 0, "collect_ratio": 0.9, "perfect_swaps": 8,
			"perfect_swap_ratio": 0.6, "distance_ratio": 1.0, "hp_left_ratio": 1.0}
	return r


func _first_gate_t(s: RunnerStage) -> float:
	for o in s.level.obstacles:
		if o["type"] == "gate" and float(o["t"]) > 20.0:
			return float(o["t"])
	return 20.0


func _play_until(s: RunnerStage, t_end: float) -> void:
	if s == null:
		return
	if _bot == null or _bot.sim != s.sim:
		_bot = RunnerBot.new(s.sim)
	var dt := 1.0 / 120.0
	while s.sim and s.sim.t < t_end and not s.sim.finished and s.phase != "done":
		s._pending = _bot.input(dt)
		s.advance(dt)


func _stage() -> RunnerStage:
	return (_screen as MinigameHost).stage_node as RunnerStage if _screen is MinigameHost else null


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


func _host(stage_id: String) -> MinigameHost:
	var h := (load("res://scenes/main/minigame/minigame_host.tscn") as PackedScene).instantiate() as MinigameHost
	h.profile = _profile
	h.registry = _reg
	h.save_enabled = false
	h.navigate_enabled = false
	h.launch = {"event_id": EVT, "mode_id": "runner", "stage": _reg.stage(EVT, "runner", stage_id)}
	h.configure_stage = func(st: MinigameStage) -> void:
		st.manual_clock = true
	root.add_child(h)
	return h


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/runner_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
