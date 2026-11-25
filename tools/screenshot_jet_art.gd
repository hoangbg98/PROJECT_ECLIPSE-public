extends SceneTree
## Chụp ảnh thật của Bay Nguyên Tố trong màn chơi (M11-5): <godot> --path . -s tools/screenshot_jet_art.gd
## Dựng thẳng JetStage (đồng hồ tay), dịch quãng bay tới vật cần xem rồi chụp: lửa phụt, Van Sét + Tia Quét (Hang Sét Câm),
## Rồng, Rồng vỡ, Robo đi / nghiền, Cặn Phóng + cảnh báo, Thanh Cặn, hộp mở. Ảnh ra build/screenshots/jetart_<n>.png.

const SCENE := "res://scenes/main/minigame/jet_stage.tscn"

var _frames := 0
var _step := 0
var _stage: JetStage


func _process(_delta: float) -> bool:
	_frames += 1
	match _step:
		0:
			if _frames < 3:
				return false
			_open("jet_mat_03")
			_next(1)
		1:
			if _frames < 3:
				return false
			var s := _stage
			s.advance(3.1)
			_teleport(_first_x("gate", 1250.0) - 560.0)
			s.forced_hold = true
			_run(0.6)
			_next(2)
		2:
			if _frames < 2:
				return false
			_shot("1_gate_thunder_flame")
			_teleport(_first_x("swp", 1250.0) - 520.0)
			_stage.forced_hold = false
			_run(0.4)
			_next(3)
		3:
			if _frames < 2:
				return false
			_shot("2_sweep")
			_stage.sim._take_box("robo")
			_teleport(_stage.sim.dist + 200.0)
			_stage.forced_hold = false
			_run(1.0)
			_next(4)
		4:
			if _frames < 2:
				return false
			_shot("3_robo_walk")
			_stage.sim.vy = -1000.0
			_stage.sim.on_ground = false
			_run(0.28)
			_next(5)
		5:
			if _frames < 2:
				return false
			_shot("4_robo_jump")
			_stage._robo_crush_at = _stage._anim_t
			_run(0.08)
			_next(6)
		6:
			if _frames < 2:
				return false
			_shot("5_robo_crush")
			_stage.sim.form = ""
			_stage._spawn_form_break("robo")
			_run(0.2)
			_next(7)
		7:
			if _frames < 2:
				return false
			_shot("6_robo_break")
			_stage.sim.form = ""
			_stage.sim.y = 480.0
			_stage.sim.vy = 0.0
			_stage.sim.on_ground = false
			_stage.sim._take_box("dragon")
			_run(0.5)
			_next(8)
		8:
			if _frames < 2:
				return false
			_shot("7_dragon_riding")
			_stage.sim.form = ""
			_stage._spawn_form_break("dragon")
			_run(0.15)
			_next(9)
		9:
			if _frames < 2:
				return false
			_shot("8_dragon_break")
			# Vùng ash N-2: Cặn Phóng + cảnh báo, Thanh Cặn, hộp.
			_stage.queue_free()
			_open("jet_mat_02")
			_next(10)
		10:
			if _frames < 3:
				return false
			_stage.advance(3.1)
			_teleport(_first_x("mis", 300.0) - 80.0)
			_stage.forced_hold = true
			_run(0.3)
			_next(11)
		11:
			if _frames < 2:
				return false
			_shot("9_missile_warn")
			_teleport(_first_x("box", 300.0) - 480.0)
			_run(0.45)
			_next(12)
		12:
			if _frames < 2:
				return false
			_shot("10_box")
			return true
	return false


func _open(level_id: String) -> void:
	var s := (load(SCENE) as PackedScene).instantiate() as JetStage
	var ctx := MinigameContext.new()
	ctx.mode_id = "jet"
	ctx.stage_id = level_id
	ctx.params = {"level": {"id": level_id}}
	ctx.party = PackedStringArray(["char_wind_01"])
	s.setup(ctx)
	s.manual_clock = true
	root.add_child(s)
	s.start()
	_stage = s


func _first_x(type: String, at_least_m: float) -> float:
	for e in _stage.level.events:
		if str(e["type"]) == type and float(e["x"]) >= at_least_m * JetLevel.PX_PER_M:
			return float(e["x"])
	return at_least_m * JetLevel.PX_PER_M


## Dịch quãng bay (px thế giới); bất tử và đứng giữa tầm nhìn để chụp.
func _teleport(x: float) -> void:
	var sim := _stage.sim
	sim.dist = x
	sim.invuln = 99.0
	sim.lives = 3
	sim.y = 560.0
	sim.vy = 0.0


func _run(sec: float) -> void:
	var dt := 1.0 / 120.0
	var n := int(sec / dt)
	for i in n:
		_stage.advance(dt)
		_stage.sim.invuln = 99.0


func _next(step: int) -> void:
	_step = step
	_frames = 0


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/jetart_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
