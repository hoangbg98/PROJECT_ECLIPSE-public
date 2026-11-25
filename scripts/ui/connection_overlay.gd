class_name ConnectionOverlay
extends CanvasLayer
## Lớp phủ "Mất kết nối" (owner 2026-11-21: game chỉ chơi online). OnlineService hiện lớp này khi máy chủ không trả lời trong lúc
## đang chơi: tạm dừng game (get_tree().paused), tự thử lại mỗi `RETRY_SEC` giây; kết nối lại được thì ẩn và chơi tiếp.
## Phiên hết hạn / người chơi bấm "Về đăng nhập" thì đăng xuất và về màn Đăng nhập. Không chứa luật gameplay.

const RETRY_SEC := 5.0

var service: Node
## false: không tạm dừng cây scene (test).
var pause_game := true
## false: không đổi scene thật (test).
var navigate := true
var retries := 0

var _status: Label
var _title: Label
var _retry: Button
var _back: Button
var _ok: Button
var _timer: Timer
var _was_paused := false
## true khi đang hiện thông báo (không phải mất kết nối).
var notice_mode := false


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.04, 0.07, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := UiKit.vbox(24)
	box.custom_minimum_size.x = 900
	center.add_child(box)
	_title = UiKit.label(tr("CONN_LOST_TITLE"), 52, HORIZONTAL_ALIGNMENT_CENTER)
	_title.name = "Title"
	box.add_child(_title)
	_status = UiKit.label(tr("CONN_LOST_RETRYING"), 30, HORIZONTAL_ALIGNMENT_CENTER)
	_status.name = "Status"
	box.add_child(_status)
	_retry = UiKit.button(tr("CONN_RETRY_NOW"), 420.0, 32)
	_retry.name = "RetryButton"
	_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_retry.pressed.connect(func() -> void: try_reconnect())
	box.add_child(_retry)
	_back = UiKit.button(tr("CONN_BACK_TO_LOGIN"), 420.0, 28)
	_back.name = "LoginButton"
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(back_to_login)
	box.add_child(_back)
	_ok = UiKit.button(tr("UI_OK"), 420.0, 32)
	_ok.name = "OkButton"
	_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ok.pressed.connect(acknowledge_notice)
	_ok.visible = false
	box.add_child(_ok)
	_timer = Timer.new()
	_timer.wait_time = RETRY_SEC
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.timeout.connect(func() -> void: try_reconnect())
	add_child(_timer)
	visible = false


func is_showing() -> bool:
	return visible


func show_lost() -> void:
	if visible:
		return
	_set_mode(false)
	visible = true
	retries = 0
	_status.text = tr("CONN_LOST_RETRYING")
	if pause_game and is_inside_tree():
		_was_paused = get_tree().paused
		get_tree().paused = true
	_timer.start()


## Thông báo một nút (vd máy chủ từ chối save): tạm dừng game; bấm OK thì về màn Title (dữ liệu vừa được tải lại).
func show_notice(title: String, text: String) -> void:
	_set_mode(true)
	_title.text = title
	_status.text = text
	_timer.stop()
	if not visible and pause_game and is_inside_tree():
		_was_paused = get_tree().paused
		get_tree().paused = true
	visible = true


func acknowledge_notice() -> void:
	hide_overlay()
	var router := UiKit.autoload("SceneRouter")
	if navigate and router:
		router.replace(GameConfig.SCENE_TITLE)


func _set_mode(notice: bool) -> void:
	notice_mode = notice
	_retry.visible = not notice
	_back.visible = not notice
	_ok.visible = notice
	if not notice:
		_title.text = tr("CONN_LOST_TITLE")


func hide_overlay() -> void:
	if not visible:
		return
	visible = false
	_timer.stop()
	if pause_game and is_inside_tree():
		get_tree().paused = _was_paused


## Thử kết nối lại. Trả về true nếu đã có kết nối (lớp phủ ẩn).
func try_reconnect() -> bool:
	if service == null:
		return false
	retries += 1
	_status.text = tr("CONN_TRYING")
	var ok: bool = await service.check_connection(false)
	if ok:
		hide_overlay()
		return true
	if service.last_error == "ONLINE_ERR_SESSION_EXPIRED" or service.last_error == "ONLINE_ERR_AUTH":
		back_to_login()
		return false
	_status.text = tr("CONN_LOST_RETRY_N") % retries
	return false


func back_to_login() -> void:
	hide_overlay()
	if service:
		service.logout()
	var router := UiKit.autoload("SceneRouter")
	if navigate and router:
		router.replace(GameConfig.SCENE_LOGIN)
