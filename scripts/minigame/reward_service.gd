class_name RewardService
extends RefCounted
## Tính thưởng một lượt Event nguyên liệu (docs/design/MATERIAL_EVENT.md mục 8), dạng PlayerProfile.grant:
##   base × rank_mult[rank]  (làm tròn xuống, giữ tối thiểu 1 nếu gốc > 0; captain_exp không nhân)
## + first_clear (lần qua đầu tiên) + star_bonus[n] (mỗi sao n mới đạt).


static func compute(rewards: Dictionary, rank: String, first_clear: bool, new_stars: Array) -> Dictionary:
	var mult := float(rewards.get("rank_mult", {}).get(rank, 1.0))
	var total := scale(rewards.get("base", {}), mult)
	if first_clear:
		total = merge(total, rewards.get("first_clear", {}))
	var bonus: Dictionary = rewards.get("star_bonus", {})
	for n in new_stars:
		total = merge(total, bonus.get(str(n), {}))
	return total


static func scale(base: Dictionary, mult: float) -> Dictionary:
	var out := {}
	for k in base:
		if base[k] is Dictionary:
			var sub := {}
			for id in base[k]:
				var v := int(base[k][id])
				sub[id] = maxi(int(floor(v * mult)), 1 if v > 0 else 0)
			out[k] = sub
		elif k == "captain_exp":
			out[k] = int(base[k])
		else:
			out[k] = maxi(int(floor(int(base[k]) * mult)), 0)
	return out


## Cộng hai gói thưởng (số cộng số, từ điển cộng theo khóa).
static func merge(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate(true)
	for k in b:
		if b[k] is Dictionary:
			var sub: Dictionary = out.get(k, {}) if out.get(k) is Dictionary else {}
			for id in b[k]:
				sub[id] = int(sub.get(id, 0)) + int(b[k][id])
			out[k] = sub
		else:
			out[k] = int(out.get(k, 0)) + int(b[k])
	return out


## Có thưởng gì không (để hiện "Có thể rơi").
static func is_empty(reward: Dictionary) -> bool:
	for k in reward:
		if reward[k] is Dictionary:
			for id in reward[k]:
				if int(reward[k][id]) > 0:
					return false
		elif int(reward[k]) > 0:
			return false
	return true
