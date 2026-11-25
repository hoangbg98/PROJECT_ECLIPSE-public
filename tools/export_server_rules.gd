extends SceneTree
## Sinh server/rules/game_rules.json từ dữ liệu game (M9-2b) cho bộ kiểm save phía máy chủ: giá các banner gacha, trần cấp,
## danh sách nhân vật có thể nhận từ phần thưởng (không qua gacha). Chạy lại mỗi khi đổi banner / phần thưởng / trần cấp:
##   <godot> --headless --path . --script res://tools/export_server_rules.gd
## rồi đẩy lên máy chủ: powershell -ExecutionPolicy Bypass -File server\audit.ps1 -SyncRules

const OUT := "res://server/rules/game_rules.json"
const BANNER_FILES := ["res://data/tutorial/starter_pull.tres"]


func _initialize() -> void:
	var banners := {}
	var gacha := {}
	var files: Array = BANNER_FILES.duplicate()
	for f in DirAccess.get_files_at("res://data/banners"):
		if f.ends_with(".tres"):
			files.append("res://data/banners/" + f)
	for path: String in files:
		var b := load(path) as BannerDef
		if b == null:
			continue
		banners[b.id] = {"currency": b.cost_currency, "cost_single": b.cost_single, "cost_multi": b.cost_multi,
				"multi_count": b.multi_count, "free": b.starter_free_multi}
		gacha[b.id] = _banner_full(b)
	var rules := load("res://data/config/progression.tres") as ProgressionRules
	var chars := {}
	_scan_rewards("res://data", chars)
	var out := {
		"_comment": "SINH TỰ ĐỘNG bởi tools/export_server_rules.gd — không sửa tay.",
		"banners": banners,
		"gacha_banners": gacha,
		"max_level": rules.max_level, "captain_max_level": rules.captain_max_level, "skill_max_level": rules.skill_max_level,
		"reward_characters": chars.keys(),
		"history_limit": SaveSchema.HISTORY_LIMIT,
	}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ") + "\n")
	f.close()
	print("saved %s: %d banner, %d nhân vật từ phần thưởng" % [OUT, banners.size(), chars.size()])
	quit()


## Cấu hình đầy đủ của banner cho gacha chạy trên máy chủ (M9-2c, server/modules/index.js mục Gacha) — cùng trường với BannerDef / GachaTierDef.
func _banner_full(b: BannerDef) -> Dictionary:
	var tiers: Array = []
	for t: GachaTierDef in b.tiers:
		tiers.append({"key": t.key(), "rarity": t.rarity, "base_rate": t.base_rate, "hard_pity": t.hard_pity,
				"soft_pity_start": t.soft_pity_start, "soft_pity_step": t.soft_pity_step, "soft_pity_mode": t.soft_pity_mode,
				"pool": Array(t.pool), "featured": Array(t.featured), "featured_rate": t.featured_rate,
				"guarantee_after_miss": t.guarantee_after_miss, "rate_per_item": t.rate_per_item,
				"exclude_owned_until_complete": t.exclude_owned_until_complete, "duplicate_item": t.duplicate_item,
				"duplicate_count": t.duplicate_count, "duplicate_fragments": t.duplicate_fragments})
	return {"id": b.id, "group": b.group(), "cost_currency": b.cost_currency, "cost_single": b.cost_single,
			"multi_count": b.multi_count, "cost_multi": b.cost_multi, "multi_guarantee_tiers": Array(b.multi_guarantee_tiers),
			"multi_guarantee_pick": Array(b.multi_guarantee_pick), "starter_free_multi": b.starter_free_multi,
			"ticket_item": b.ticket_item, "tiers": tiers, "valid": b.validate().is_empty()}


## Mọi mảng "characters" trong file JSON dữ liệu (phần thưởng màn, event, truyện...).
func _scan_rewards(dir: String, out: Dictionary) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_scan_rewards(dir.path_join(sub), out)
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
			_walk(d, out)


func _walk(v: Variant, out: Dictionary) -> void:
	if v is Dictionary:
		for k in v:
			if str(k) == "characters" and v[k] is Array:
				for c in v[k]:
					if c is String and str(c).begins_with("char_"):
						out[c] = true
			_walk(v[k], out)
	elif v is Array:
		for x in v:
			_walk(x, out)
