class_name RunnerBot
extends RefCounted
## Bot chơi Chạy Nguyên Tố cho kiểm thử (docs/design/RUNNER_MODE.md mục 13): lên lịch nhảy giữa mỗi Cặn Thấp / Vết Thực
## và đổi người trước mỗi cổng. Level nào bot không qua được với 0 lần trúng là level sai (vật quá dày / chồng nhau).
##
##   var bot := RunnerBot.new(sim)              # "next": chỉ dùng Đổi kế tiếp; "direct": chọn thẳng ô
##   while not sim.finished: sim.step(dt, bot.input(dt))

## Đổi người lúc này trước khi cổng chạm người chạy (trong cửa sổ Perfect 0.30 s).
const SWAP_LEAD := 0.26

var sim: RunnerSim
var mode := "next"
var _jumps: PackedFloat64Array = []
var _gates: Array[Dictionary] = []
var _ji := 0
var _gi := 0


func _init(sim_: RunnerSim, mode_ := "next") -> void:
	sim = sim_
	mode = mode_
	var half_air := sim.rules.airtime() * 0.5
	for o in sim.level.obstacles:
		match str(o["type"]):
			"hurdle", "pit":
				_jumps.append(float(o["t"]) - half_air)
			"gate":
				_gates.append(o)


## Input cho bước kế tiếp (dài dt).
func input(dt: float) -> Dictionary:
	var now := sim.t + dt
	var inp := {"jump": false, "swap": false, "slot": -1}
	while _ji < _jumps.size() and _jumps[_ji] <= now - dt * 0.5:
		inp["jump"] = true
		_ji += 1
	while _gi < _gates.size() and float(_gates[_gi]["t"]) + sim.rules.gate_grace < now:
		_gi += 1
	if _gi < _gates.size():
		var g: Dictionary = _gates[_gi]
		var want := int(g["slot"])
		if now >= float(g["t"]) - SWAP_LEAD and sim.slot != want:
			if mode == "direct":
				inp["slot"] = want
			else:
				inp["swap"] = true
	return inp


## Chạy hết level, trả về sim (đã xong).
static func play(rules: RunnerRules, level: RunnerLevel, party_size: int, mode_ := "next") -> RunnerSim:
	var s := RunnerSim.new(rules, level, party_size)
	var bot := RunnerBot.new(s, mode_)
	var dt := 1.0 / 120.0
	var guard := int((level.length_sec + 5.0) / dt)
	while not s.finished and guard > 0:
		s.step(dt, bot.input(dt))
		guard -= 1
	return s
