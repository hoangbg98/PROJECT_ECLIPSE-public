extends SceneTree
## Bake 5 ải Bay Nguyên Tố từ data/jet/baked_levels.json (docs/design/JET_MODE.md mục 10, 11):
##   <godot> --headless --path . -s tools/jet/bake_levels.gd                 (bỏ qua level boss đã có)
##   <godot> --headless --path . -s tools/jet/bake_levels.gd -- --force-boss (ghi đè cả level boss)
## Mỗi level: thử seed, seed+1… (tối đa 50) tới khi JetValidator đạt và bot bay qua với 0 lần trúng, ghi
## data/jet/levels/<level_id>.json. Mã thoát 1 nếu có level không sinh được.

const CONFIG := "res://data/jet/baked_levels.json"
const RULES := "res://data/jet/jet_rules.tres"
const TRIES := 50


func _init() -> void:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var rules := load(RULES) as JetRules
	var force_boss := OS.get_cmdline_user_args().has("--force-boss")
	var failed := 0
	for entry: Dictionary in (cfg as Dictionary).get("levels", []):
		var id := str(entry["level_id"])
		var path := JetLevel.DIR + id + ".json"
		if entry.get("boss") != null and FileAccess.file_exists(path) and not force_boss:
			print("bỏ qua %s (level boss đã có; dùng --force-boss để ghi đè)" % id)
			continue
		var seed := int(entry.get("seed", 1))
		var done := false
		for k in TRIES:
			var lv := JetGenerator.generate(seed + k, entry)
			var text := JetGenerator.to_json_text(lv)
			# Kiểm bản đọc lại từ JSON (đúng thứ game sẽ chạy).
			var why := check(JetLevel.from_dict(JSON.parse_string(text)), rules, float(entry.get("max_core_gap_m", 1200.0)))
			if why == "":
				var f := FileAccess.open(path, FileAccess.WRITE)
				f.store_string(text)
				f.close()
				print("ghi %s (seed %d, %d vật)" % [path, seed + k, lv.events.size()])
				done = true
				break
			print("  %s seed %d: %s" % [id, seed + k, why])
		if not done:
			push_error("không sinh được " + id)
			failed += 1
	quit(1 if failed > 0 else 0)


## Rỗng = đạt.
static func check(lv: JetLevel, rules: JetRules, max_core_gap_m: float) -> String:
	if not lv.is_valid():
		return "; ".join(lv.errors)
	var errs := JetValidator.check(lv, rules, max_core_gap_m)
	if not errs.is_empty():
		return errs[0]
	var sim := JetBot.play(rules, lv)
	if not sim.cleared or sim.hits_taken > 0:
		return "bot: về đích %s, trúng %d" % [sim.cleared, sim.hits_taken]
	return ""
