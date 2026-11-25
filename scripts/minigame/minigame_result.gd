class_name MinigameResult
extends RefCounted
## Kết quả scene chơi trả cho khung (docs/design/MATERIAL_EVENT.md mục 5). Khóa `stats` theo chế độ: mục 13.

const RANKS: Array[String] = ["D", "C", "B", "A", "S"]

var cleared := false
var score := 0
## "S" | "A" | "B" | "C" | "D"
var rank := "D"
var stats: Dictionary = {}
var duration_sec := 0.0
## "", "hp_zero", "quit"
var fail_reason := ""


static func quit_result(duration := 0.0) -> MinigameResult:
	var r := MinigameResult.new()
	r.fail_reason = "quit"
	r.duration_sec = duration
	return r


## Thứ tự hạng: S = 4 … D = 0; hạng lạ = -1.
static func rank_value(r: String) -> int:
	return RANKS.find(r)


func to_dict() -> Dictionary:
	return {"cleared": cleared, "score": score, "rank": rank, "stats": stats.duplicate(),
			"duration_sec": duration_sec, "fail_reason": fail_reason}
