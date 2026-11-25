extends SceneTree
## Chụp màn Nạp với máy chủ thật (cần cửa sổ + máy chủ chạy + bảng giá đã đẩy lên): <godot> --path . -s tools/screenshot_topup.gd
## Tạo một tài khoản tạm, chụp: chưa nạp (gói còn thưởng lần đầu), chọn gói 1.400.000đ. Ảnh ra build/screenshots/topup_<n>.png.
## Ngoài ra lưu mã QR gói đang chọn ra build/screenshots/topup_qr.png để quét thử bằng điện thoại.

var _screen: Control
var _service: Node


func _initialize() -> void:
	_run.call_deferred()


func _frames(n := 6) -> void:
	for i in n:
		await process_frame
	await create_timer(0.2).timeout


func _shot(name_: String) -> void:
	var out := "res://build/screenshots/topup_%s.png" % name_
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	root.get_texture().get_image().save_png(out)
	print("saved ", out)


func _run() -> void:
	var stamp := str(int(Time.get_unix_time_from_system()) % 1000000)
	_service = root.get_node("OnlineService")
	_service.session_file = "user://shot_topup_session.cfg"
	_service.cloud_root = "user://shot_topup_cloud"
	_service.chat_auto_start = false
	_service.connection_guard = false
	var saves: Node = root.get_node("SaveService")
	saves.offline_dir = "user://shot_topup_offline"
	saves.use_store(saves.offline_store())
	await _service.register("nap%s" % stamp, "nap%s@example.com" % stamp, "matkhau123", "matkhau123", false)
	await _service.open_cloud_world()
	saves.new_game()
	_screen = (load("res://scenes/main/topup_screen.tscn") as PackedScene).instantiate()
	root.add_child(_screen)
	await _frames(14)
	_shot("0_start")
	_screen.select_pack("gems_660")
	await _frames(6)
	_shot("1_gems_660")
	_screen.get_child(0).get_parent().find_child("Packs", true, false).get_parent().get_parent().scroll_vertical = 2000
	await _frames(6)
	_shot("2_card")
	var ov := ConnectionOverlay.new()
	ov.pause_game = false
	ov.navigate = false
	ov.service = _service
	root.add_child(ov)
	ov.show_lost()
	await _frames(4)
	_shot("3_conn_lost")
	ov.queue_free()
	var pay: Dictionary = _screen.payment_for("gems_6600")
	print("QR payload: ", pay["payload"])
	QrCode.encode_text(str(pay["payload"]), QrCode.Ecc.MEDIUM).to_image(10, 4).save_png(
			ProjectSettings.globalize_path("res://build/screenshots/topup_qr.png"))
	_service.logout()
	quit()
