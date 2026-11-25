class_name LimitTracker
extends RefCounted
## Hạn mức lượt có thưởng của một chế độ (docs/design/MATERIAL_EVENT.md mục 7).
## Cấu hình `limit`: {"period": "daily" | "weekly" | "none", "max": n, "reset_hour": 0..23} (thiếu = không giới hạn).
## Trạng thái lưu: {"used": n, "period_key": "...", "last_seen_unix": t}. Thời gian truyền vào (unix, giây) để test.
## Chống lùi giờ: thời điểm nhỏ hơn mốc đã thấy thì coi như đang ở mốc đó (không reset, không cộng lượt).

const DAY := 86400


## Chênh múi giờ của máy (giây), cộng vào unix để ra giờ địa phương.
static func system_tz_offset() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


static func is_limited(limit: Dictionary) -> bool:
	return str(limit.get("period", "none")) in ["daily", "weekly"] and int(limit.get("max", 0)) > 0


## Khóa chu kỳ: ngày logic "YYYY-MM-DD" (đổi lúc reset_hour) hoặc tuần "W:<ngày thứ Hai>".
static func period_key(limit: Dictionary, unix: int, tz_offset: int) -> String:
	var period := str(limit.get("period", "none"))
	if period == "none":
		return ""
	var local := unix + tz_offset - int(limit.get("reset_hour", 4)) * 3600
	var days := floori(float(local) / DAY)
	if period == "weekly":
		var weekday := posmod(days + 3, 7)   # 1970-01-01 là thứ Năm; thứ Hai = 0
		days -= weekday
	var d := Time.get_date_dict_from_unix_time(days * DAY)
	var key := "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]
	return ("W:" + key) if period == "weekly" else key


## Thời điểm (unix) chu kỳ kế bắt đầu.
static func next_reset_unix(limit: Dictionary, unix: int, tz_offset: int) -> int:
	var period := str(limit.get("period", "none"))
	if period == "none":
		return 0
	var shift := tz_offset - int(limit.get("reset_hour", 4)) * 3600
	var days := floori(float(unix + shift) / DAY)
	var add := 1
	if period == "weekly":
		add = 7 - posmod(days + 3, 7)
	return (days + add) * DAY - shift


## Cập nhật trạng thái theo thời điểm hiện tại (reset khi sang chu kỳ mới). Trả về thời điểm đã dùng.
static func refresh(state: Dictionary, limit: Dictionary, now_unix: int, tz_offset: int) -> int:
	var seen := int(state.get("last_seen_unix", 0))
	var t := maxi(now_unix, seen)
	var key := period_key(limit, t, tz_offset)
	if str(state.get("period_key", "")) != key:
		state["period_key"] = key
		state["used"] = 0
	state["used"] = maxi(int(state.get("used", 0)), 0)
	state["last_seen_unix"] = t
	return t


## Lượt có thưởng còn lại; -1 = không giới hạn.
static func remaining(state: Dictionary, limit: Dictionary, now_unix: int, tz_offset: int) -> int:
	if not is_limited(limit):
		return -1
	refresh(state, limit, now_unix, tz_offset)
	return maxi(int(limit["max"]) - int(state["used"]), 0)


## Dùng một lượt nếu còn. Trả về true nếu lượt này có thưởng.
static func consume(state: Dictionary, limit: Dictionary, now_unix: int, tz_offset: int) -> bool:
	if not is_limited(limit):
		return true
	if remaining(state, limit, now_unix, tz_offset) <= 0:
		return false
	state["used"] = int(state["used"]) + 1
	return true
