extends SceneTree
## Kiểm tra thật chống gian lận (M9-2b): game ↔ máy chủ Nakama đang chạy, luật đã đẩy (server\audit.ps1 -SyncRules). Chạy:
##   <godot> --headless --path . --script res://tools/audit_e2e.gd [-- --server=<địa chỉ>]
## Tài khoản tạm au<số>, thư mục save riêng. Các bước: save hợp lệ được nhận → sửa Ngọc vượt trần / khai khống Ngọc đã nạp /
## sửa lịch sử gacha → máy chủ từ chối, game tải lại bản hợp lệ → chơi tiếp bình thường. Cần secrets.json (xem đánh dấu).

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")

var _fails := 0
var _svc: Node
var _saves: Node
var _rejected: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String, detail := "") -> void:
	print(("  ĐẠT  " if ok else "  LỖI  ") + what + ("" if ok else "  (" + detail + ")"))
	if not ok:
		_fails += 1


func _gems() -> int:
	return int(_saves.data["currencies"]["gems"])


func _server_gems() -> int:
	var r: Dictionary = await _svc.call_rpc("save_get", {})
	return int(JSON.parse_string(str(r["data"]["envelope"]["data"]))["currencies"]["gems"])


func _cheat(what: String, edit: Callable) -> void:
	var before := _rejected.size()
	edit.call(_saves.data)
	_saves.save_game()
	await _svc.push_now()
	await create_timer(0.3).timeout
	_check(_rejected.size() == before + 1, what + ": máy chủ từ chối", str(_rejected))


func _run() -> void:
	var server := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			server = a.trim_prefix("--server=")
	_svc = SERVICE_SCRIPT.new()
	_svc.config = OnlineConfig.load_from()
	if not server.is_empty():
		_svc.config.server_url = NakamaApi.normalize_url(server)
	_svc.session_file = "user://audit_e2e_session.cfg"
	_svc.cloud_root = "user://audit_e2e_cloud"
	_svc.chat_auto_start = false
	_svc.connection_guard = false
	_svc.push_delay = 60.0   # tự gọi push_now
	root.add_child(_svc)
	_saves = root.get_node("SaveService")
	_saves.offline_dir = "user://audit_e2e_offline"
	_saves.use_store(_saves.offline_store())
	_svc.save_service = _saves
	_svc.save_rejected.connect(func(r: String) -> void: _rejected.append(r))
	print("Máy chủ: ", _svc.config.server_url)

	var name_ := "au%d" % (int(Time.get_unix_time_from_system()) % 1000000)
	_check(await _svc.register(name_, name_ + "@example.com", "matkhau123", "matkhau123", false), "tạo tài khoản " + name_)
	_check(await _svc.open_cloud_world() == "ok", "mở thế giới")
	_saves.new_game()
	_saves.data["currencies"]["gems"] = 500
	_saves.save_game()
	_check(await _svc.push_now(), "save hợp lệ (500 Ngọc) được nhận")

	await _cheat("Ngọc vượt trần (99 999 999)", func(d: Dictionary) -> void: d["currencies"]["gems"] = 99999999)
	_check(_gems() == 500 and await _server_gems() == 500, "game tải lại bản hợp lệ: 500 Ngọc", str(_gems()))
	# Khai khống Ngọc đã nạp: chính game tự trừ lại theo ví máy chủ trước khi gửi (máy chủ cũng chặn: server/tests/audit_smoke.mjs).
	_saves.data["online"]["applied"]["gems"] = 6600
	_saves.data["currencies"]["gems"] = 7100
	_saves.save_game()
	await _svc.push_now()
	_check(_gems() == 500 and int(_saves.data["online"]["applied"]["gems"]) == 0 and await _server_gems() == 500,
			"khai khống Ngọc đã nạp: game tự trừ lại theo ví máy chủ (500 Ngọc)", str(_gems()))
	await _cheat("cấp nhân vật 999", func(d: Dictionary) -> void: d["characters"]["char_fire_01"]["level"] = 999)
	_check(int(_saves.data["characters"]["char_fire_01"]["level"]) == 1, "cấp nhân vật về 1")
	_check(_rejected.size() == 2 and _rejected[0].contains("currency_over_cap:gems") and _rejected[1].contains("char_level:char_fire_01"),
			"lý do từ chối đúng", str(_rejected))
	# chơi tiếp hợp lệ
	_saves.data["currencies"]["gold"] = 1234
	_saves.save_game()
	_check(await _svc.push_now(), "chơi tiếp: save hợp lệ được nhận")
	_check(_svc.cloud_state == _svc.Cloud.SYNCED, "trạng thái đồng bộ bình thường")
	print("  mã người chơi để xem đánh dấu: ", _svc.profile.get("code", ""))
	_svc.logout()
	print("ĐẠT" if _fails == 0 else "CÓ %d BƯỚC LỖI" % _fails)
	quit(0 if _fails == 0 else 1)
