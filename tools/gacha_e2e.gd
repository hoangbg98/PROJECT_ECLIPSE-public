extends SceneTree
## Kiểm tra thật gacha trên máy chủ (M9-2c): game ↔ Nakama đang chạy, luật đã đẩy (audit.ps1 -SyncRules, server_gacha = true).
##   <godot> --headless --path . --script res://tools/gacha_e2e.gd [-- --server=<địa chỉ>]
## Tài khoản tạm ga<số>, thư mục save riêng. Bước: quay đơn / x10 / lượt miễn phí qua máy chủ → game chơi tiếp và gửi save
## (save máy chủ ghi, Godot đọc rồi ghi lại vẫn hợp luật) → game tự thêm lượt 5★ / sửa pity bị từ chối và tải lại.

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


func _hist() -> int:
	return (_saves.data["gacha"]["history"] as Array).size()


func _run() -> void:
	var server := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			server = a.trim_prefix("--server=")
	_svc = SERVICE_SCRIPT.new()
	_svc.config = OnlineConfig.load_from()
	if not server.is_empty():
		_svc.config.server_url = NakamaApi.normalize_url(server)
	_svc.session_file = "user://gacha_e2e_session.cfg"
	_svc.cloud_root = "user://gacha_e2e_cloud"
	_svc.chat_auto_start = false
	_svc.connection_guard = false
	_svc.push_delay = 60.0
	root.add_child(_svc)
	_saves = root.get_node("SaveService")
	_saves.offline_dir = "user://gacha_e2e_offline"
	_saves.use_store(_saves.offline_store())
	_svc.save_service = _saves
	_svc.save_rejected.connect(func(r: String) -> void: _rejected.append(r))
	print("Máy chủ: ", _svc.config.server_url)

	var name_ := "ga%d" % (int(Time.get_unix_time_from_system()) % 1000000)
	_check(await _svc.register(name_, name_ + "@example.com", "matkhau123", "matkhau123", false), "tạo tài khoản " + name_)
	_check(await _svc.open_cloud_world() == "ok", "mở thế giới")
	_saves.new_game()
	_saves.data["currencies"]["gems"] = 3000
	_saves.data["inventory"]["materials"]["ticket_starter_x10"] = 1
	_saves.save_game()

	var t := Time.get_ticks_msec()
	var r: Dictionary = await _svc.gacha_pull("banner_char_terra", 1)
	_check(r["ok"] and r["results"].size() == 1, "quay đơn trên máy chủ (%d ms, gồm gửi save trước)" % (Time.get_ticks_msec() - t), str(r))
	_check(_gems() == 3000 - 280 and _hist() == 1, "save trên máy = save máy chủ (2720 Ngọc, 1 lượt)", "%d / %d" % [_gems(), _hist()])
	t = Time.get_ticks_msec()
	r = await _svc.gacha_pull("banner_char_terra", 10)
	_check(r["ok"] and r["results"].size() == 10 and _gems() == 2720 - 2520, "quay x10 (%d ms), còn 200 Ngọc" % (Time.get_ticks_msec() - t), str(_gems()))
	r = await _svc.gacha_pull("starter_pull", 10, true)
	_check(r["ok"] and r["results"].size() == 10, "lượt miễn phí người mới trên máy chủ", str(r))
	_check(not _saves.data["inventory"]["materials"].has("ticket_starter_x10"), "vé đã bị trừ")
	r = await _svc.gacha_pull("starter_pull", 10, true)
	_check(r["reason"] == GachaService.REASON_STARTER_USED, "lượt miễn phí lần hai bị từ chối")
	r = await _svc.gacha_pull("banner_char_terra", 10)
	_check(r["reason"] == GachaService.REASON_NOT_ENOUGH, "hết Ngọc: máy chủ từ chối", str(r))

	# Godot đọc save máy chủ ghi (khóa không sắp xếp, số nguyên) rồi ghi lại: phải vẫn hợp luật.
	var profile := PlayerProfile.new(_saves.data)   # như các màn: gieo phụ tố cho trang bị mới
	profile.inventory.add_currency("gold", 77)
	_saves.save_game()
	_check(await _svc.push_now() and _rejected.is_empty(), "game chơi tiếp, gửi save sau khi quay: được nhận", str(_rejected))
	var hist_before := _hist()
	# Gian lận: tự thêm lượt 5★ trong save
	_saves.data["gacha"]["history"].append({"banner": "banner_char_terra", "item": "char:char_earth_01", "rarity": 5, "tier": "S",
			"featured": true, "duplicate": false, "pity": 1, "forced": false, "time": "2026-11-21T00:00:00"})
	_saves.data["characters"]["char_earth_01"] = SaveSchema.default_character()
	_saves.save_game()
	await _svc.push_now()
	await create_timer(0.3).timeout
	_check(_rejected.size() == 1 and _rejected[0].contains("gacha_client_pull"), "tự thêm lượt 5★: máy chủ từ chối", str(_rejected))
	_check(_hist() == hist_before and not _saves.data["characters"].has("char_earth_01"), "game tải lại bản hợp lệ (không có nhân vật gian lận)")
	# Gian lận: sửa pity sát pity cứng
	var pity: Dictionary = _saves.data["gacha"]["pity"]
	pity["char"] = {"S": 99, "A": 9, "B": 1, "MAT": 1}
	_saves.save_game()
	await _svc.push_now()
	await create_timer(0.3).timeout
	_check(_rejected.size() == 2 and _rejected[1].contains("gacha_state_edited"), "sửa pity: máy chủ từ chối", str(_rejected))
	_saves.data["currencies"]["gold"] = int(_saves.data["currencies"]["gold"]) + 1
	_saves.save_game()
	_check(await _svc.push_now(), "chơi tiếp bình thường sau khi bị từ chối")
	print("  mã người chơi: ", _svc.profile.get("code", ""))
	_svc.logout()
	print("ĐẠT" if _fails == 0 else "CÓ %d BƯỚC LỖI" % _fails)
	quit(0 if _fails == 0 else 1)
