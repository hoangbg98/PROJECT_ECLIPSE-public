extends GdUnitTestSuite
## Khung Event nguyên liệu (M11-1): dữ liệu event, tiến trình + sao + thưởng, hạn mức qua tiến trình, di trú save.

const EVT := "evt_material"
const MON_0400 := 1794801600   # thứ Hai 2026-11-16 04:00 UTC

var reg: MinigameRegistry


func before_test() -> void:
	reg = MinigameRegistry.load_from()


func _prog(p: PlayerProfile = null) -> MinigameProgress:
	var g := MinigameProgress.new(p if p else PlayerProfile.new(SaveSchema.default_data()))
	g.clock = func() -> int: return MON_0400
	g.tz_offset = 0
	return g


func _result(cleared := true, rank := "A", stats := {"accuracy": 0.95, "miss": 0, "max_combo": 80}) -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = cleared
	r.rank = rank
	r.score = 5000
	r.stats = stats
	return r


func test_registry_data_matches_items_and_layouts() -> void:
	assert_array(reg.errors).is_empty()
	var rhythm := reg.mode(EVT, "rhythm")
	assert_str(str(rhythm["layout"])).is_equal("graph")
	assert_int(rhythm["stages"].size()).is_equal(5)
	assert_bool(bool(reg.stage(EVT, "rhythm", "rhythm_mat_05")["params"]["boss"])).is_true()
	var lim: Dictionary = reg.limit_for(EVT, "rhythm")["limit"]
	assert_str(str(lim["period"])).is_equal("weekly")
	assert_int(int(lim["max"])).is_equal(50)
	assert_int(int(lim["reset_hour"])).is_equal(4)
	assert_str(str(reg.limit_for(EVT, "rhythm_endless")["key"])).is_equal("evt_material:rhythm")   # dùng chung lượt
	var es := reg.endless_stage(EVT, "rhythm_endless", "song_x", "hard")
	assert_str(str(es["id"])).is_equal("endless:song_x:hard")
	assert_float(float(es["params"]["speed"]["note_speed"])).is_equal(1000.0)
	assert_str(str(es["params"]["music"]["song"])).is_equal("song_x")
	assert_float(float(MinigameRegistry.param(es["params"], "spawn.density", 0.0))).is_equal(1.0)
	assert_str(str(MinigameRegistry.param(es["params"], "khong.co", "mac_dinh"))).is_equal("mac_dinh")
	assert_dict(es["rewards"]["base"]).is_not_empty()
	assert_array(MinigameRegistry.stats_keys("rhythm_endless")).contains(["holds_broken"])


func test_reward_compute_rank_first_clear_and_star_bonus() -> void:
	var rewards: Dictionary = reg.stage(EVT, "rhythm", "rhythm_mat_01")["rewards"]
	var r := RewardService.compute(rewards, "S", true, [2, 3])
	assert_int(int(r["gold"])).is_equal(2250)                          # 1500 × 1.5
	assert_int(int(r["captain_exp"])).is_equal(300)                    # không nhân
	assert_int(int(r["materials"]["mat_exp_small"])).is_equal(12 + 3)  # 8 × 1.5 + sao 2
	assert_int(int(r["materials"]["mat_exp_medium"])).is_equal(1 + 3 + 2)   # 1 × 1.5 (giữ 1) + lần đầu + sao 3
	assert_int(int(r["gems"])).is_equal(50)
	var plain := RewardService.compute(rewards, "B", false, [])
	assert_int(int(plain["gold"])).is_equal(1500)
	assert_bool(plain.has("gems")).is_false()
	assert_bool(RewardService.is_empty({"materials": {"x": 0}})).is_true()


func test_submit_stars_only_grow_and_rewards_once() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var g := _prog(p)
	var stage := reg.stage(EVT, "rhythm", "rhythm_mat_01")
	assert_bool(g.stage_unlocked("rhythm", reg.stage(EVT, "rhythm", "rhythm_mat_02"))).is_false()
	# Thua: không sao, không thưởng, vẫn đếm lượt chơi.
	var lost := g.submit("rhythm", stage, _result(false), true)
	assert_bool(lost["rewarded"]).is_false()
	assert_int(int(g.record("rhythm", "rhythm_mat_01")["plays"])).is_equal(1)
	assert_bool(g.is_cleared("rhythm", "rhythm_mat_01")).is_false()
	# Qua, đủ 3 sao, có thưởng lần đầu.
	var won := g.submit("rhythm", stage, _result(), true)
	assert_bool(won["first_clear"]).is_true()
	assert_array(won["new_stars"]).is_equal([1, 2, 3])
	assert_int(int(won["rewards"]["gems"])).is_equal(50)
	assert_int(g.star_count("rhythm", "rhythm_mat_01")).is_equal(3)
	assert_bool(g.stage_unlocked("rhythm", reg.stage(EVT, "rhythm", "rhythm_mat_02"))).is_true()
	# Lần sau tệ hơn: sao không mất, không còn thưởng lần đầu / sao.
	var again := g.submit("rhythm", stage, _result(true, "C", {"accuracy": 0.7, "miss": 9}), true)
	assert_bool(again["first_clear"]).is_false()
	assert_array(again["new_stars"]).is_empty()
	assert_int(g.star_count("rhythm", "rhythm_mat_01")).is_equal(3)
	assert_str(str(g.record("rhythm", "rhythm_mat_01")["best_rank"])).is_equal("A")
	assert_int(int(again["rewards"]["gems"])).is_equal(0)
	assert_int(int(again["rewards"]["gold"])).is_equal(1500)


func test_unrewarded_run_records_but_gives_nothing() -> void:
	var p := PlayerProfile.new(SaveSchema.default_data())
	var g := _prog(p)
	var stage := reg.stage(EVT, "rhythm", "rhythm_mat_01")
	var gold0 := p.inventory.currency("gold")
	var out := g.submit("rhythm", stage, _result(), false)
	assert_bool(out["rewarded"]).is_false()
	assert_dict(out["rewards"]).is_empty()
	assert_int(p.inventory.currency("gold")).is_equal(gold0)
	assert_bool(g.is_cleared("rhythm", "rhythm_mat_01")).is_true()      # vẫn tính đã qua (mở ải sau)
	assert_int(g.star_count("rhythm", "rhythm_mat_01")).is_equal(0)      # không ghi sao
	assert_bool(bool(g.record("rhythm", "rhythm_mat_01")["first_clear_claimed"])).is_false()   # thưởng lần đầu còn chờ


func test_limit_through_progress_and_shared_key() -> void:
	var g := _prog()
	var lim: Dictionary = reg.limit_for(EVT, "rhythm")
	var shared: Dictionary = reg.limit_for(EVT, "rhythm_endless")
	assert_int(g.remaining(lim["key"], lim["limit"])).is_equal(50)
	for i in 49:
		assert_bool(g.begin_play(lim["key"], lim["limit"])).is_true()
	assert_bool(g.begin_play(shared["key"], shared["limit"])).is_true()   # lượt Vô tận trừ chung
	assert_int(g.remaining(lim["key"], lim["limit"])).is_equal(0)
	assert_bool(g.begin_play(lim["key"], lim["limit"])).is_false()
	g.clock = func() -> int: return MON_0400 + 7 * 86400
	assert_int(g.remaining(lim["key"], lim["limit"])).is_equal(50)


func test_mode_unlock_tutorials_favorites() -> void:
	var g := _prog()
	var endless := reg.mode(EVT, "rhythm_endless")
	assert_bool(g.mode_unlocked(endless)).is_false()
	assert_bool(g.mode_unlocked(reg.mode(EVT, "rhythm"))).is_true()
	for i in range(1, 6):
		g.submit("rhythm", reg.stage(EVT, "rhythm", "rhythm_mat_0%d" % i), _result(), true)
	assert_bool(g.mode_unlocked(endless)).is_true()
	assert_bool(g.tutorial_seen("rhythm", "rhythm_mat_01")).is_false()
	g.mark_tutorial("rhythm", "rhythm_mat_01")
	assert_bool(g.tutorial_seen("rhythm", "rhythm_mat_01")).is_true()
	assert_bool(g.toggle_favorite("rhythm_endless", "song_a")).is_true()
	assert_bool(g.is_favorite("rhythm_endless", "song_a")).is_true()
	assert_bool(g.toggle_favorite("rhythm_endless", "song_a")).is_false()


func test_save_migrates_rhythm_once_and_keeps_old_data() -> void:
	var old := SaveSchema.default_data()
	old.erase("minigames")
	old["rhythm"] = {"records": {
		"rhythm_mat_01": {"cleared": true, "best_score": 900, "best_rank": "A", "plays": 4, "best_accuracy": 0.93},
		"rhythm_mat_02": {"cleared": false, "plays": 2},
		"endless:song_a:hard": {"cleared": true, "best_score": 77, "best_rank": "S"},
	}, "favorites": ["song_a"]}
	var once := SaveSchema.sanitize(old)
	var mg: Dictionary = once["minigames"]
	assert_bool(bool(mg["records"]["rhythm"]["rhythm_mat_01"]["cleared"])).is_true()
	assert_array(mg["records"]["rhythm"]["rhythm_mat_01"]["stars"]).is_equal([true, false, false])
	assert_bool(bool(mg["records"]["rhythm"]["rhythm_mat_01"]["first_clear_claimed"])).is_true()
	assert_int(int(mg["records"]["rhythm"]["rhythm_mat_02"]["plays"])).is_equal(2)
	assert_int(int(mg["records"]["rhythm_endless"]["endless:song_a:hard"]["best_score"])).is_equal(77)
	assert_array(mg["favorites"]["rhythm_endless"]).is_equal(["song_a"])
	assert_bool(bool(mg["tutorials"]["rhythm"]["rhythm_mat_01"])).is_true()
	assert_bool(mg["tutorials"]["rhythm"].has("rhythm_mat_02")).is_false()
	assert_dict(once["rhythm"]["records"]).is_not_empty()   # không xóa dữ liệu cũ
	# Chạy lại (save đã có minigames): giữ nguyên, kể cả tiến trình mới.
	once["minigames"]["records"]["rhythm"]["rhythm_mat_02"]["cleared"] = true
	var twice := SaveSchema.sanitize(once)
	assert_bool(bool(twice["minigames"]["records"]["rhythm"]["rhythm_mat_02"]["cleared"])).is_true()
	assert_dict(twice["minigames"]).is_equal(once["minigames"])
	# Save không có rhythm: không lỗi.
	var plain := SaveSchema.default_data()
	plain.erase("rhythm")
	plain.erase("minigames")
	assert_dict(SaveSchema.sanitize(plain)["minigames"]["records"]).is_empty()
