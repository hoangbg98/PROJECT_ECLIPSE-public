extends SceneTree
## Sinh level Chạy Nguyên Tố từ data/runner/generated_levels.json (docs/design/RUNNER_MODE.md mục 9, 10):
##   <godot> --headless --path . -s tools/runner/build_levels.gd                 (bỏ qua level boss đã có)
##   <godot> --headless --path . -s tools/runner/build_levels.gd -- --force-boss (ghi đè cả level boss)
## Mỗi level: thử seed, seed+1… (tối đa 50) tới khi hợp lệ và bot qua với 0 lần trúng theo cả hai cách đổi người,
## rồi ghi data/runner/levels/<level_id>.json. Mã thoát 1 nếu có level không sinh được.

const CONFIG := "res://data/runner/generated_levels.json"
const RULES := "res://data/runner/runner_rules.tres"
const TRIES := 50


func _init() -> void:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var rules := load(RULES) as RunnerRules
	var force_boss := OS.get_cmdline_user_args().has("--force-boss")
	var failed := 0
	for entry: Dictionary in (cfg as Dictionary).get("levels", []):
		var id := str(entry["level_id"])
		var path := RunnerLevel.DIR + id + ".json"
		if entry.get("boss") != null and FileAccess.file_exists(path) and not force_boss:
			print("bỏ qua %s (level boss đã có; dùng --force-boss để ghi đè)" % id)
			continue
		var seed := int(entry.get("seed", 1))
		var done := false
		for k in TRIES:
			var d := RunnerGenerator.generate(seed + k, entry)
			var why := check(d, rules)
			if why == "":
				var f := FileAccess.open(path, FileAccess.WRITE)
				f.store_string(RunnerGenerator.to_json_text(d))
				f.close()
				print("ghi %s (seed %d, %d vật)" % [path, seed + k, (d["events"] as Array).size()])
				done = true
				break
			print("  %s seed %d: %s" % [id, seed + k, why])
		if not done:
			push_error("không sinh được " + id)
			failed += 1
	quit(1 if failed > 0 else 0)


## Rỗng = đạt: level hợp lệ, bot qua 0 lần trúng (cả "next" và "direct").
static func check(d: Dictionary, rules: RunnerRules) -> String:
	var lv := RunnerLevel.from_dict(d)
	if not lv.is_valid():
		return "; ".join(lv.errors)
	for mode in ["next", "direct"]:
		var sim := RunnerBot.play(rules, lv, lv.slots_used.size(), mode)
		if not sim.cleared or sim.hits_taken > 0 or sim.gates_wrong > 0:
			return "bot %s: về đích %s, trúng %d" % [mode, sim.cleared, sim.hits_taken]
	return ""
