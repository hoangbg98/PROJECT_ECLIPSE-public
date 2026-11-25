extends Control
## Màn Boot: logo, thanh tiến độ, phiên bản. Chưa có tài nguyên nặng để nạp,
## nên tiến độ chạy theo thời gian rồi chuyển sang Đăng nhập (game chỉ chơi online; dev: bản debug + `--offline` vào Title).

const BOOT_TIME := 1.0

@onready var _progress: ProgressBar = %Progress
@onready var _version: Label = %Version


func _ready() -> void:
	_version.text = "v%s" % GameConfig.get_version()
	_progress.value = 0.0
	var tween := create_tween()
	tween.tween_property(_progress, "value", 100.0, BOOT_TIME)
	await tween.finished
	SceneRouter.replace(GameConfig.SCENE_LOGIN if show_login() else GameConfig.SCENE_TITLE)


## Luôn qua màn Đăng nhập (owner 2026-11-21: không có chơi ngoại tuyến), trừ chế độ dev OnlineConfig.dev_offline().
static func show_login() -> bool:
	return not OnlineConfig.dev_offline()
