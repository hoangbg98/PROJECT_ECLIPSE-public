class_name MinigameHost
extends Control
## Màn chạy một lượt Event nguyên liệu (docs/design/MATERIAL_EVENT.md mục 2, 5): dựng scene chơi của chế độ từ dữ liệu,
## tiêu lượt khi chơi thật bắt đầu, ghi kết quả (MinigameProgress), phát thưởng, hiện MinigameResultScreen.
## Lượt chơi lấy từ GameConfig.minigame_launch = {event_id, mode_id, stage (ải đầy đủ)} hoặc gán `launch` (test).

const BACK_GROUP := &"back_interceptor"

var launch: Dictionary = {}
var registry: MinigameRegistry
var progress: MinigameProgress
var profile: PlayerProfile
## false: không ghi file save / không đổi scene (test).
var save_enabled := true
var navigate_enabled := true
## Test: được gọi với scene chơi vừa tạo, trước start().
var configure_stage: Callable

var stage_node: MinigameStage
var result_screen: MinigameResultScreen
## Lượt hiện tại: đã bắt đầu chơi thật / có thưởng.
var played := false
var rewarded := false
var last_outcome: Dictionary = {}
var last_result: MinigameResult
var left := false


func _ready() -> void:
	add_to_group(BACK_GROUP)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var gc := UiKit.autoload("GameConfig")
	if launch.is_empty() and gc:
		launch = gc.minigame_launch.duplicate(true)
	if registry == null:
		registry = MinigameRegistry.load_from()
	if profile == null:
		var save := UiKit.autoload("SaveService")
		profile = PlayerProfile.new(save.data if save else SaveSchema.default_data())
	if progress == null:
		progress = MinigameProgress.new(profile)
	launch_stage()


func _event_id() -> String:
	return str(launch.get("event_id", ""))


func _mode_id() -> String:
	return str(launch.get("mode_id", ""))


func _stage() -> Dictionary:
	return launch.get("stage", {})


## Khóa hướng dẫn: Vô tận dùng chung với chế độ gốc ("rhythm_endless" → "rhythm").
func tutorial_mode() -> String:
	return _mode_id().trim_suffix("_endless")


func launch_stage() -> void:
	played = false
	rewarded = false
	var mode := registry.mode(_event_id(), _mode_id())
	var scene_path := str(mode.get("scene", ""))
	if not ResourceLoader.exists(scene_path):
		push_error("MinigameHost: không có scene " + scene_path)
		leave()
		return
	var ctx := MinigameContext.new()
	ctx.event_id = _event_id()
	ctx.mode_id = _mode_id()
	ctx.stage_id = str(_stage().get("id", ""))
	ctx.params = _stage().get("params", {}).duplicate(true)
	ctx.seed = hash(ctx.stage_id)
	ctx.is_first_play = not progress.tutorial_seen(tutorial_mode(), ctx.stage_id)
	ctx.party = profile.party_ids()
	var lim := registry.limit_for(_event_id(), _mode_id())
	ctx.practice = progress.remaining(lim["key"], lim["limit"]) == 0 or bool(_stage().get("practice", false))
	stage_node = (load(scene_path) as PackedScene).instantiate() as MinigameStage
	stage_node.name = "Stage"
	stage_node.setup(ctx)
	stage_node.play_started.connect(_on_play_started)
	stage_node.finished.connect(_on_finished)
	stage_node.quit_requested.connect(leave)
	stage_node.retry_requested.connect(retry)
	if configure_stage.is_valid():
		configure_stage.call(stage_node)
	add_child(stage_node)
	stage_node.start()


func _on_play_started() -> void:
	if played:
		return
	played = true
	var lim := registry.limit_for(_event_id(), _mode_id())
	# Ải luyện (vd luyện vùng Bay Nguyên Tố): không tốn lượt, không thưởng.
	rewarded = false if bool(_stage().get("practice", false)) else progress.begin_play(lim["key"], lim["limit"])
	progress.mark_tutorial(tutorial_mode(), str(_stage().get("id", "")))
	_save()


func _on_finished(result: MinigameResult) -> void:
	if not played:
		_on_play_started()
	last_result = result
	last_outcome = progress.submit(_mode_id(), _stage(), result, rewarded)
	_save()
	if result.fail_reason == "quit":
		leave()
		return
	# Ẩn và dừng scene chơi phía sau màn kết quả.
	stage_node.hide()
	stage_node.process_mode = Node.PROCESS_MODE_DISABLED
	result_screen = MinigameResultScreen.new()
	result_screen.name = "Result"
	add_child(result_screen)
	result_screen.show_result(result, last_outcome, _stage(), registry.mode(_event_id(), _mode_id()), rewarded)
	result_screen.retry_pressed.connect(retry)
	result_screen.back_pressed.connect(leave)


func retry() -> void:
	for n in [stage_node, result_screen]:
		if n and is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	stage_node = null
	result_screen = null
	launch_stage()


func intercept_back() -> bool:
	# Esc trong lúc chơi do scene chơi tự xử lý (tạm dừng, cũng nằm trong nhóm back_interceptor); ở màn kết quả thì về
	# chọn ải.
	if result_screen:
		leave()
		return true
	return false


func leave() -> void:
	if left:
		return
	left = true
	if not navigate_enabled:
		return
	var router := UiKit.autoload("SceneRouter")
	var gc := UiKit.autoload("GameConfig")
	if router and router.can_go_back():
		router.go_back()
	elif router and gc:
		router.replace(gc.SCENE_HUB)


func _save() -> void:
	var save := UiKit.autoload("SaveService")
	if save_enabled and save and is_same(save.data, profile.data):
		save.save_game()
