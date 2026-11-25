extends GdUnitTestSuite
## Test gacha chạy trên máy chủ (M9-2c) phía game: OnlineService.gacha_pull (gửi save trước, nạp save máy chủ trả về, lỗi luật /
## mạng / xung đột) và màn Chiêu mộ quay qua máy chủ. Máy chủ giả dùng chính GachaService (logic máy chủ thật kiểm bằng
## server/tests/gacha_smoke.mjs).

const SERVICE_SCRIPT := preload("res://scripts/online/online_service.gd")
const SAVE_SCRIPT := preload("res://scripts/save/save_service.gd")
const SCREEN_SCENE := preload("res://scenes/main/recruit_screen.tscn")
const ROOT := "user://test_server_gacha"
const CHAR_BANNER := "banner_char_terra"

var fake: FakeNakama


func before_test() -> void:
	fake = FakeNakama.new()
	fake.accounts["tester1"]["wallet"] = {}
	OnlineTestKit.remove_tree(ROOT)


func after_test() -> void:
	OnlineTestKit.remove_tree(ROOT)


func _device(name_ := "a") -> Node:
	var saves: Node = auto_free(SAVE_SCRIPT.new())
	add_child(saves)
	saves.offline_dir = ROOT.path_join(name_ + "_offline")
	saves.use_store(SaveStore.new(saves.offline_dir))
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join(name_ + ".cfg"))
	s.config.server_key = FakeNakama.SERVER_KEY
	s.device_file = ROOT.path_join(name_ + "_device.cfg")
	s.session_file = ROOT.path_join(name_ + "_session.cfg")
	s.cloud_root = ROOT.path_join(name_ + "_cloud")
	s.save_service = saves
	s.push_delay = 60.0
	s.chat_auto_start = false
	s.connection_guard = false
	s.transport = fake.handle
	add_child(s)
	assert_bool(await s.login_account("tester1", "matkhau123", false)).is_true()
	assert_str(await s.open_cloud_world()).is_equal("ok")
	return s


func _new_world(s: Node, gems: int) -> void:
	s.save_service.new_game()
	s.save_service.data["currencies"]["gems"] = gems
	s.save_service.save_game()   # bản đệm có tiến độ chưa gửi (push_delay dài)


func _gems(s: Node) -> int:
	return int(s.save_service.data["currencies"]["gems"])


func _server_data() -> Dictionary:
	return JSON.parse_string(str(fake.saves["uid-tester1"]["envelope"]["data"]))


func test_not_in_world_refuses() -> void:
	var s: Node = auto_free(SERVICE_SCRIPT.new())
	s.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join("x.cfg"))
	s.chat_auto_start = false
	s.transport = fake.handle
	add_child(s)
	assert_bool(s.in_cloud_world()).is_false()
	var r: Dictionary = await s.gacha_pull(CHAR_BANNER, 1)
	assert_bool(r["ok"]).is_false()
	assert_str(r["error"]).is_equal("ONLINE_ERR_NOT_LOGGED_IN")


func test_pull_pushes_first_then_loads_server_save() -> void:
	var s := await _device()
	assert_bool(s.in_cloud_world()).is_true()
	await _new_world(s, 3000)
	assert_bool(CloudSave.read_meta(s._cloud_dir)["dirty"]).is_true()
	var r: Dictionary = await s.gacha_pull(CHAR_BANNER, 1)
	assert_bool(r["ok"]).is_true()
	assert_int(r["results"].size()).is_equal(1)
	assert_bool(r["results"][0]["rarity"] is int).is_true()               # số JSON đã đổi về đúng kiểu
	assert_bool(r["results"][0]["duplicate"] is bool).is_true()
	assert_int(_gems(s)).is_equal(3000 - 280)                              # save trên máy đã là save của máy chủ
	assert_int((s.save_service.data["gacha"]["history"] as Array).size()).is_equal(1)
	assert_int(int(_server_data()["currencies"]["gems"])).is_equal(3000 - 280)
	assert_bool(CloudSave.read_meta(s._cloud_dir)["dirty"]).is_false()
	assert_str(CloudSave.read_meta(s._cloud_dir)["version"]).is_equal(fake.saves["uid-tester1"]["version"])
	# x10
	s.save_service.data["currencies"]["gems"] = 2520
	s.save_service.save_game()
	r = await s.gacha_pull(CHAR_BANNER, 10)
	assert_bool(r["ok"]).is_true()
	assert_int(r["results"].size()).is_equal(10)
	assert_int(_gems(s)).is_equal(0)
	assert_int(fake.gacha_calls).is_equal(2)


func test_rule_errors_keep_save() -> void:
	var s := await _device()
	await _new_world(s, 100)
	var r: Dictionary = await s.gacha_pull(CHAR_BANNER, 1)
	assert_bool(r["ok"]).is_false()
	assert_str(r["reason"]).is_equal(GachaService.REASON_NOT_ENOUGH)
	assert_int(_gems(s)).is_equal(100)
	r = await s.gacha_pull(CHAR_BANNER, 3)
	assert_str(r["reason"]).is_equal(GachaService.REASON_BAD_COUNT)
	r = await s.gacha_pull("banner_khong_co", 1)
	assert_str(r["reason"]).is_equal(GachaService.REASON_INVALID)


func test_starter_pull_on_server() -> void:
	var s := await _device()
	await _new_world(s, 0)
	var r: Dictionary = await s.gacha_pull("starter_pull", 10, true)
	assert_str(r["reason"]).is_equal(GachaService.REASON_NO_TICKET)
	s.save_service.data["inventory"]["materials"]["ticket_starter_x10"] = 1
	s.save_service.save_game()
	r = await s.gacha_pull("starter_pull", 10, true)
	assert_bool(r["ok"]).is_true()
	assert_int(r["results"].size()).is_equal(10)
	assert_bool("starter_pull" in s.save_service.data["gacha"]["starter_used"]).is_true()
	r = await s.gacha_pull("starter_pull", 10, true)
	assert_str(r["reason"]).is_equal(GachaService.REASON_STARTER_USED)


func test_unreachable_and_conflict() -> void:
	var s := await _device()
	await _new_world(s, 3000)
	fake.down = true
	var r: Dictionary = await s.gacha_pull(CHAR_BANNER, 1)
	assert_bool(r["ok"]).is_false()
	assert_str(r["error"]).is_equal("ONLINE_ERR_UNREACHABLE")
	assert_int(_gems(s)).is_equal(3000)
	fake.down = false
	assert_bool(await s.push_now()).is_true()
	# thiết bị khác vừa ghi: máy này không quay trên bản cũ
	var other := SaveSchema.default_data()
	other["currencies"]["gems"] = 50000
	fake.write_from_other_device("tester1", SaveStore.envelope_of(other))
	r = await s.gacha_pull(CHAR_BANNER, 1)
	assert_bool(r["ok"]).is_false()
	assert_str(r["error"]).is_equal("CLOUD_ERR_CONFLICT")
	assert_int(fake.gacha_calls).is_equal(0)


func test_recruit_screen_pulls_through_server() -> void:
	var s := await _device()
	await _new_world(s, 3000)
	var screen: RecruitScreen = SCREEN_SCENE.instantiate()
	screen.online = s
	screen.profile = PlayerProfile.new(s.save_service.data)
	screen.save_enabled = false
	add_child(auto_free(screen))
	assert_bool(screen.remote_gacha()).is_true()
	var char_index := -1
	for i in screen.banners.size():
		if screen.banners[i].id == CHAR_BANNER:
			char_index = i
	screen.selected = char_index
	await screen.request_pull(1)
	assert_int(fake.gacha_calls).is_equal(1)
	assert_int(screen.overlay).is_equal(RecruitScreen.Overlay.RESULTS)
	assert_int(screen.last_results.size()).is_equal(1)
	assert_str(screen.last_reason).is_empty()
	assert_bool(is_same(screen.profile.data, s.save_service.data)).is_true()   # màn dùng save máy chủ vừa nạp
	assert_int(screen.profile.inventory.currency("gems")).is_equal(3000 - 280)
	assert_bool(screen.busy).is_false()
	# thiếu Ngọc: máy chủ báo lỗi, màn hiện lý do, không quay
	s.save_service.data["currencies"]["gems"] = 10
	s.save_service.save_game()
	screen.overlay = RecruitScreen.Overlay.NONE
	await screen.request_pull(10)
	assert_str(screen.last_reason).is_equal(GachaService.REASON_NOT_ENOUGH)
	assert_str(screen.notice).is_equal(tr("REASON_NOT_ENOUGH_CURRENCY"))
	assert_int(screen.overlay).is_equal(RecruitScreen.Overlay.NONE)
	assert_int((_server_data()["gacha"]["history"] as Array).size()).is_equal(1)   # không có lượt mới


func test_recruit_screen_offline_uses_local_gacha() -> void:
	var off: Node = auto_free(SERVICE_SCRIPT.new())
	off.config = OnlineConfig.load_from(OnlineConfig.DATA_PATH, ROOT.path_join("off.cfg"))
	off.chat_auto_start = false
	off.transport = fake.handle
	add_child(off)
	var data := SaveSchema.default_data()
	data["currencies"]["gems"] = 3000
	var screen: RecruitScreen = SCREEN_SCENE.instantiate()
	screen.online = off
	screen.profile = PlayerProfile.new(data)
	screen.save_enabled = false
	add_child(auto_free(screen))
	assert_bool(screen.remote_gacha()).is_false()
	await screen.request_pull(1)
	assert_int(fake.gacha_calls).is_equal(0)
	assert_int(screen.last_results.size()).is_equal(1)
