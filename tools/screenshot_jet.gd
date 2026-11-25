extends SceneTree
## Chụp Bay Nguyên Tố (M11-5): <godot> --path . -s tools/screenshot_jet.gd
## Hub event → chọn ải Bay → N-1 (đếm ngược + biểu ngữ vùng, đang bay) → N-2 (Rồng, gió) → N-3 (Hang Sét Câm: Tia Quét,
## Van Sét) → kết quả → boss N-5 → danh sách Vô tận. Bot bay; hồ sơ thử riêng, không ghi save.
## Ảnh ra build/screenshots/jet_<n>.png.

const EVT := "evt_material"

var _frames := 0
var _step := 0
var _screen: Node
var _profile: PlayerProfile
var _reg: MinigameRegistry
var _bot: JetBot


func _process(_delta: float) -> bool:
	_frames += 1
	match _step:
		0:
			if _frames < 3:
				return false
			_profile = PlayerProfile.new(SaveSchema.default_data())
			_profile.data["party"] = ["char_wind_01", "char_fire_01", "char_lightning_01"]
			_reg = MinigameRegistry.load_from()
			_screen = _open("res://scenes/main/minigame/event_hub_screen.tscn")
			_next(1)
		1:
			if _frames < 4:
				return false
			_shot("0_event_hub")
			_screen.queue_free()
			root.get_node("GameConfig").event_mode_id = "jet"
			_screen = _open("res://scenes/main/minigame/stage_select_screen.tscn")
			_next(2)
		2:
			if _frames < 4:
				return false
			_shot("1_stage_select")
			_screen.queue_free()
			_screen = _host("jet_mat_01")
			_next(3)
		3:
			if _frames < 4:
				return false
			_stage().advance(1.0)
			_next(4)
		4:
			if _frames < 2:
				return false
			_shot("2_countdown_banner")
			_fly_until(_stage(), 260.0)
			_next(5)
		5:
			if _frames < 2:
				return false
			_shot("3_n1_flying")
			_screen.queue_free()
			_screen = _host("jet_mat_02")
			_next(6)
		6:
			if _frames < 4:
				return false
			_fly_until_form(_stage(), "dragon", 700.0)
			_next(7)
		7:
			if _frames < 2:
				return false
			_shot("4_n2_dragon_wind")
			_screen.queue_free()
			_screen = _host("jet_mat_03")
			_next(8)
		8:
			if _frames < 4:
				return false
			_fly_until(_stage(), 1290.0)
			_next(9)
		9:
			if _frames < 2:
				return false
			_shot("5_n3_thunder")
			_fly_until(_stage(), 99999.0)
			_next(10)
		10:
			if _frames < 4:
				return false
			_shot("6_result")
			_screen.queue_free()
			_screen = _host("jet_mat_05")
			_next(11)
		11:
			if _frames < 4:
				return false
			_fly_until(_stage(), 1350.0)
			_next(12)
		12:
			if _frames < 2:
				return false
			_shot("7_boss")
			_screen.queue_free()
			var prog := MinigameProgress.new(_profile)
			for i in range(1, 6):
				prog.submit("jet", _reg.stage(EVT, "jet", "jet_mat_0%d" % i), _fake_result(), true)
			root.get_node("GameConfig").event_mode_id = "jet_endless"
			_screen = _open("res://scenes/main/minigame/jet_endless_screen.tscn")
			_next(13)
		13:
			if _frames < 4:
				return false
			_shot("8_endless")
			return true
	return false


func _fake_result() -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = true
	r.rank = "A"
	r.score = 2000
	r.stats = {"accuracy": 0.92, "distance_m": 800.0, "distance_ratio": 1.0, "hits_taken": 0, "hp_left_ratio": 1.0,
			"orb_ratio": 0.9, "cores_collected": 5, "forms_used": 1, "zones_passed": 1}
	return r


func _fly_until(s: JetStage, m: float) -> void:
	if s == null:
		return
	if s.phase == "countdown":
		s.advance(3.1)
	if _bot == null or _bot.sim != s.sim:
		_bot = JetBot.new(s.sim)
	var dt := 1.0 / 120.0
	while s.sim and s.sim.meters() < m and not s.sim.finished and s.phase != "done":
		s.forced_hold = _bot.hold()
		s.advance(dt)


func _fly_until_form(s: JetStage, form: String, max_m: float) -> void:
	if s.phase == "countdown":
		s.advance(3.1)
	_bot = JetBot.new(s.sim)
	var dt := 1.0 / 120.0
	var seen := 0.0
	while s.sim.meters() < max_m and not s.sim.finished:
		s.forced_hold = _bot.hold()
		s.advance(dt)
		if s.sim.form == form:
			seen += dt
			if seen > 1.5 and s.level.wind_at_px(s.sim.dist, s.rules) != 0.0:
				return
			if seen > 9.0:
				return


func _stage() -> JetStage:
	return (_screen as MinigameHost).stage_node as JetStage if _screen is MinigameHost else null


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
	h.launch = {"event_id": EVT, "mode_id": "jet", "stage": _reg.stage(EVT, "jet", stage_id)}
	h.configure_stage = func(st: MinigameStage) -> void:
		st.manual_clock = true
	root.add_child(h)
	return h


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/jet_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
