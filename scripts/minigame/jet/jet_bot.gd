class_name JetBot
extends RefCounted
## Bot Bay Nguyên Tố cho kiểm thử (docs/design/JET_MODE.md mục 13): bám đường giữa hành lang (`level.path`) bằng giữ /
## thả có dự đoán. Level bot không qua được với 0 lần trúng là level sai (hành lang hẹp, chuyển hướng quá gắt, thiếu
## năng lượng).
##
##   var bot := JetBot.new(sim)
##   while not sim.finished: sim.step(dt, bot.hold())

## Nhìn trước (giây) trên đường bay.
const LOOK := 0.12
## Trễ phản ứng bù (giây): quyết định theo vị trí sau chừng này.
const LAG := 0.03

var sim: JetSim


func _init(sim_: JetSim) -> void:
	sim = sim_


func target_y() -> float:
	var look := sim.dist + sim.scroll() * LOOK
	return sim.level.path_y(look)


func hold() -> bool:
	match sim.form:
		"robo":
			return false
		_:
			var ty := target_y()
			# Đường xuống sát sàn: thả để chạy đất, hồi năng lượng.
			if sim.form == "" and ty >= sim.rules.floor_y - 60.0:
				return false
			# Chuyển theo quãng hãm (đúng cả khi gia tốc lệch một chiều vì gió): đang lên thì thả nếu thả ra vẫn
			# dừng kịp ở đích; đang rơi thì giữ nếu giữ mới dừng kịp ở đích.
			var r := sim.rules
			var wind := sim.level.wind_at_px(sim.dist, r)
			var a_hold := (-r.dragon_up if sim.form == "dragon" else r.gravity - r.thrust) + wind
			var a_rel := (r.dragon_down if sim.form == "dragon" else r.gravity) + wind
			var y := sim.y + sim.vy * LAG
			var vy := sim.vy
			if vy < 0.0:
				if a_rel <= 0.0:
					return false
				return y - vy * vy / (2.0 * a_rel) > ty
			if vy > 0.0:
				if a_hold >= 0.0:
					return true
				return y + vy * vy / (2.0 * -a_hold) >= ty
			return y > ty


## Chạy hết level (Vô tận: tới `max_m` mét).
static func play(rules: JetRules, level: JetLevel, max_m := 0.0) -> JetSim:
	var s := JetSim.new(rules, level)
	var bot := JetBot.new(s)
	var dt := 1.0 / 120.0
	var cap_m := max_m if max_m > 0.0 else level.length_m
	var guard := 0
	while not s.finished and s.meters() < cap_m and guard < 120 * 1200:
		s.step(dt, bot.hold())
		guard += 1
	return s
