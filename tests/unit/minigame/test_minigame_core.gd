extends GdUnitTestSuite
## Khung Event nguyên liệu (M11-0): chấm sao, hạn mức lượt, bước cố định.

# Mốc thời gian UTC (múi giờ 0 trong test): thứ Hai 2026-11-16 03:59 / 04:00, Chủ nhật 22/11 23:00, thứ Hai 23/11.
const MON_0359 := 1794801540
const MON_0400 := 1794801600
const SUN_2300 := 1795388400
const NEXT_MON_0359 := 1795406340
const NEXT_MON_0400 := 1795406400


func _result(cleared := true, rank := "A", score := 1000, stats := {}) -> MinigameResult:
	var r := MinigameResult.new()
	r.cleared = cleared
	r.rank = rank
	r.score = score
	r.stats = stats
	return r


# ---------- StarEvaluator ----------

func test_star_parse_and_errors() -> void:
	assert_str(StarEvaluator.parse("clear")["kind"]).is_equal("clear")
	assert_dict(StarEvaluator.parse("rank>=A")).is_equal({"kind": "rank", "op": ">=", "value": "A"})
	assert_dict(StarEvaluator.parse("stat:accuracy>=0.9")).is_equal({"kind": "stat", "key": "accuracy", "op": ">=", "value": 0.9})
	assert_float(float(StarEvaluator.parse("score>=5000")["value"])).is_equal(5000.0)
	for bad in ["", "win", "rank>=X", "rank<=A", "stat:>=1", "stat:acc>=abc", "stat:accuracy", "score>=x", "stat:a b>=1"]:
		assert_bool(StarEvaluator.parse(bad).has("error")).override_failure_message(bad).is_true()


func test_star_check_operators_and_rank_order() -> void:
	var r := _result(true, "A", 4200, {"accuracy": 0.93, "miss": 0, "hits": 3})
	assert_bool(StarEvaluator.check("clear", r)).is_true()
	assert_bool(StarEvaluator.check("rank>=A", r)).is_true()
	assert_bool(StarEvaluator.check("rank>=B", r)).is_true()
	assert_bool(StarEvaluator.check("rank>=S", r)).is_false()
	assert_bool(StarEvaluator.check("score>=4200", r)).is_true()
	assert_bool(StarEvaluator.check("score>=4201", r)).is_false()
	assert_bool(StarEvaluator.check("stat:accuracy>=0.90", r)).is_true()
	assert_bool(StarEvaluator.check("stat:miss==0", r)).is_true()
	assert_bool(StarEvaluator.check("stat:hits<=2", r)).is_false()
	assert_bool(StarEvaluator.check("stat:khong_co>=0", r)).is_false()   # khóa thiếu = không đạt


func test_star_failed_run_gets_nothing() -> void:
	var lost := _result(false, "S", 99999, {"miss": 0})
	assert_array(StarEvaluator.evaluate(["clear", "rank>=D", "stat:miss==0"], lost)).is_equal([false, false, false])
	assert_array(StarEvaluator.evaluate(["clear", "rank>=S", "stat:miss==0"], _result(true, "A", 1, {"miss": 0}))).is_equal([true, false, true])


# ---------- LimitTracker ----------

func test_limit_weekly_reset_boundary() -> void:
	var limit := {"period": "weekly", "max": 2, "reset_hour": 4}
	var st := {}
	# Trước 4 giờ thứ Hai vẫn thuộc tuần trước.
	assert_str(LimitTracker.period_key(limit, MON_0359, 0)).is_not_equal(LimitTracker.period_key(limit, MON_0400, 0))
	assert_str(LimitTracker.period_key(limit, MON_0400, 0)).is_equal(LimitTracker.period_key(limit, SUN_2300, 0))
	assert_str(LimitTracker.period_key(limit, SUN_2300, 0)).is_equal(LimitTracker.period_key(limit, NEXT_MON_0359, 0))
	assert_bool(LimitTracker.consume(st, limit, MON_0400, 0)).is_true()
	assert_bool(LimitTracker.consume(st, limit, SUN_2300, 0)).is_true()
	assert_bool(LimitTracker.consume(st, limit, NEXT_MON_0359, 0)).is_false()   # hết lượt
	assert_int(LimitTracker.remaining(st, limit, NEXT_MON_0400, 0)).is_equal(2)  # tuần mới
	assert_int(LimitTracker.next_reset_unix(limit, MON_0400, 0)).is_equal(NEXT_MON_0400)
	assert_int(LimitTracker.next_reset_unix(limit, MON_0359, 0)).is_equal(MON_0400)


func test_limit_daily_and_timezone() -> void:
	var limit := {"period": "daily", "max": 1, "reset_hour": 4}
	assert_str(LimitTracker.period_key(limit, MON_0400, 0)).is_equal("2026-11-16")
	assert_str(LimitTracker.period_key(limit, MON_0359, 0)).is_equal("2026-11-15")
	# UTC+7: 03:59 UTC là 10:59 giờ địa phương => đã sang ngày 16.
	assert_str(LimitTracker.period_key(limit, MON_0359, 7 * 3600)).is_equal("2026-11-16")
	assert_int(LimitTracker.next_reset_unix(limit, MON_0400, 0)).is_equal(MON_0400 + 86400)


func test_limit_clock_rewind_does_not_reset() -> void:
	var limit := {"period": "weekly", "max": 1, "reset_hour": 4}
	var st := {}
	assert_bool(LimitTracker.consume(st, limit, NEXT_MON_0400, 0)).is_true()
	# Lùi đồng hồ về tuần trước: không được thêm lượt.
	assert_int(LimitTracker.remaining(st, limit, MON_0400, 0)).is_equal(0)
	assert_bool(LimitTracker.consume(st, limit, MON_0400, 0)).is_false()
	assert_int(int(st["last_seen_unix"])).is_equal(NEXT_MON_0400)


func test_limit_none_is_unlimited() -> void:
	var st := {}
	assert_bool(LimitTracker.is_limited({})).is_false()
	assert_int(LimitTracker.remaining(st, {"period": "none"}, MON_0400, 0)).is_equal(-1)
	for i in 100:
		assert_bool(LimitTracker.consume(st, {}, MON_0400, 0)).is_true()


# ---------- FixedStep ----------

func test_fixed_step_accumulates_and_caps() -> void:
	var f := FixedStep.new(1.0 / 120.0, 12)
	var total := 0
	for i in 60:
		total += f.advance(1.0 / 60.0)
	assert_int(total).is_equal(120)   # 1 giây = 120 bước dù frame 60 Hz
	f.reset()
	assert_int(f.advance(0.004)).is_equal(0)
	assert_float(f.alpha()).is_between(0.47, 0.49)
	assert_int(f.advance(0.005)).is_equal(1)
	assert_int(f.advance(5.0)).is_equal(12)   # máy khựng: chặn trần, bỏ phần dư
	assert_int(f.advance(0.0)).is_equal(0)
