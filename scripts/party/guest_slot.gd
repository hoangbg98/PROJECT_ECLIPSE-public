class_name GuestSlot
extends RefCounted
## Ô khách của màn cốt truyện (owner 2026-11-21): ải khai báo `"guest": {"char": "<Data ID>"}` trong data/stages/*.json thì
## nhân vật đó chiếm MỘT slot bắt buộc trong đội (2 slot còn lại tự chọn). Slot dùng:
## - giáp THỬ (ai cũng có, hiện nhãn "Chơi thử"): hạng gốc của giáp, mặc đủ món đề cử trong data/config/guest_trials.json,
##   cấp = cấp tối đa theo cấp quản lý; dựng trong bộ nhớ, KHÔNG ghi vào save;
## - hoặc giáp ĐÃ CÓ của người chơi (nếu sở hữu): cấp, trang bị, vết thánh thật.
## Lớp chỉ chọn đội và dựng hồ sơ thử; mọi con số cân bằng nằm trong data/.

const TRIALS_PATH := "res://data/config/guest_trials.json"
const SLOT_COUNT := 3


## Data ID nhân vật khách của ải ("" nếu ải không có khách).
static func of_stage(stage_data: Dictionary) -> String:
	var g: Variant = stage_data.get("guest")
	return str(g.get("char", "")) if g is Dictionary else ""


## Đội thực tế khi vào ải có khách: tối đa 2 người tự chọn (bỏ giáp cùng nhân vật với khách) rồi khách ở slot cuối.
static func effective_party(profile: PlayerProfile, guest_char: String) -> PackedStringArray:
	var out := PackedStringArray()
	if guest_char == "":
		return profile.party_ids()
	var person := profile.person_of(guest_char)
	for id in profile.party_ids():
		if out.size() >= SLOT_COUNT - 1:
			break
		if id != guest_char and profile.person_of(id) != person:
			out.append(id)
	out.append(guest_char)
	return out


## Có dùng giáp thử không: chưa sở hữu thì luôn thử; sở hữu thì theo lựa chọn của người chơi (`prefer_owned`).
static func uses_trial(profile: PlayerProfile, guest_char: String, prefer_owned: bool) -> bool:
	if guest_char == "":
		return false
	return not (prefer_owned and profile.progression.owns(guest_char))


## Món đề cử của giáp thử (rỗng nếu chưa khai báo).
static func trial_equipment(guest_char: String) -> Array:
	if not FileAccess.file_exists(TRIALS_PATH):
		return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(TRIALS_PATH))
	if not (d is Dictionary) or not (d.get(guest_char) is Dictionary):
		return []
	return Array(d[guest_char].get("equipment", []))


## Hồ sơ riêng cho giáp thử: nhân vật + món đề cử trên một bản save tạm, cấp = cấp tối đa theo cấp quản lý của `real`.
static func trial_profile(real: PlayerProfile, guest_char: String) -> PlayerProfile:
	var save := SaveSchema.default_data()
	save["characters"] = {guest_char: SaveSchema.default_character()}
	save["party"] = [guest_char]
	save["account"]["level"] = real.progression.captain_level()
	var prof := PlayerProfile.new(save)
	save["characters"][guest_char]["level"] = prof.progression.level_cap()
	for def_id in trial_equipment(guest_char):
		var uid := prof.inventory.add_equipment(str(def_id))
		if uid == "":
			continue
		save["inventory"]["equipment"][uid].erase("affixes")   # không ngẫu nhiên: cùng thử cho cùng kết quả
		prof.inventory.equip(guest_char, uid)
	return prof


## Cấp của giáp thử (để hiện ở thẻ).
static func trial_level(real: PlayerProfile) -> int:
	return mini(real.rules.max_level, real.progression.captain_level())
