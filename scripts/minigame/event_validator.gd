class_name EventValidator
extends RefCounted
## Kiểm tra data/events/material_events.json lúc nạp (docs/design/MATERIAL_EVENT.md mục 12).
## Trả về {errors: [...], warnings: [...]}: lỗi nặng thì không nên hiện chế độ đó; cảnh báo chỉ ghi log.

const REWARD_CURRENCIES: Array[String] = ["gold", "gems", "captain_exp", "exp"]


static func validate(data: Dictionary, item_ids := PackedStringArray(), check_scenes := true) -> Dictionary:
	var errors := PackedStringArray()
	var warnings := PackedStringArray()
	if int(data.get("format", 0)) != 1 or not (data.get("events") is Array):
		errors.append("format phải là 1 và có mảng events")
		return {"errors": errors, "warnings": warnings}
	var event_ids := {}
	for e in data["events"]:
		var eid := str(e.get("id", ""))
		if eid == "" or event_ids.has(eid):
			errors.append("id event trống hoặc trùng: '%s'" % eid)
		event_ids[eid] = true
		_check_key(e, "title_key", "event " + eid, warnings)
		var mode_ids := {}
		for m in e.get("modes", []):
			var mid := str(m.get("id", ""))
			var where := "%s/%s" % [eid, mid]
			if mid == "" or mode_ids.has(mid):
				errors.append("id chế độ trống hoặc trùng: " + where)
			mode_ids[mid] = true
			_check_key(m, "title_key", where, warnings)
			_check_card(m.get("card", {}), where, errors, warnings)
			if MinigameRegistry.is_soon(m):
				continue   # thẻ "Sắp ra mắt": chưa có scene / ải
			var scene := str(m.get("scene", ""))
			if check_scenes and not ResourceLoader.exists(scene):
				errors.append("%s: không có scene %s" % [where, scene])
			var layout := str(m.get("layout", "graph"))
			if not layout in ["graph", "list"]:
				errors.append("%s: layout lạ '%s'" % [where, layout])
			if layout == "list" and check_scenes and not ResourceLoader.exists(str(m.get("list_scene", ""))):
				errors.append("%s: thiếu list_scene" % where)
			_check_stages(m, where, item_ids, errors, warnings)
		for m in e.get("modes", []):
			var lim: Dictionary = m.get("limit", {})
			if lim.has("share_with") and not mode_ids.has(str(lim["share_with"])):
				errors.append("%s/%s: share_with trỏ tới chế độ không có" % [eid, str(m.get("id", ""))])
			var parent := str(m.get("parent", ""))
			if parent != "" and not mode_ids.has(parent):
				errors.append("%s/%s: parent trỏ tới chế độ không có '%s'" % [eid, str(m.get("id", "")), parent])
			var need := str(m.get("unlock", {}).get("requires_stage_cleared", ""))
			if need != "":
				var parts := need.split("/")
				if parts.size() != 2 or not mode_ids.has(parts[0]):
					errors.append("%s/%s: unlock trỏ sai '%s'" % [eid, str(m.get("id", "")), need])
	return {"errors": errors, "warnings": warnings}


static func _check_stages(m: Dictionary, where: String, item_ids: PackedStringArray, errors: PackedStringArray,
		warnings: PackedStringArray) -> void:
	var stages: Array = m.get("stages", [])
	var ids := {}
	for s in stages:
		var sid := str(s.get("id", ""))
		if sid == "" or ids.has(sid):
			errors.append("%s: id ải trống hoặc trùng '%s'" % [where, sid])
		ids[sid] = s
	var allowed := MinigameRegistry.stats_keys(str(m.get("id", "")))
	for s in stages:
		var w := "%s/%s" % [where, str(s.get("id", ""))]
		_check_key(s, "title_key", w, warnings)
		for req in s.get("requires", []):
			if not ids.has(str(req)):
				errors.append("%s: requires trỏ tới ải không có '%s'" % [w, str(req)])
		var pos: Variant = s.get("pos")
		if m.get("layout", "graph") == "graph" and not (pos is Array and pos.size() == 2
				and float(pos[0]) >= 0.0 and float(pos[0]) <= 1.0 and float(pos[1]) >= 0.0 and float(pos[1]) <= 1.0):
			errors.append("%s: pos phải là [x, y] trong 0..1" % w)
		_check_stars(s.get("stars", []), allowed, w, errors, warnings)
		_check_params(s.get("params", {}), str(m.get("id", "")), w, errors)
		var rew: Dictionary = s.get("rewards", {})
		for part in ["base", "first_clear"]:
			_check_reward(rew.get(part, {}), item_ids, "%s %s" % [w, part], errors)
		for n in rew.get("star_bonus", {}):
			_check_reward(rew["star_bonus"][n], item_ids, "%s star_bonus %s" % [w, n], errors)
		var rm: Dictionary = rew.get("rank_mult", {})
		if not rm.is_empty():
			for r in MinigameResult.RANKS:
				if not rm.has(r):
					errors.append("%s: rank_mult thiếu hạng %s" % [w, r])
	# Vòng phụ thuộc + ải không tới được (mọi ải phải đi về được một ải gốc không có requires).
	for sid in ids:
		var seen := {}
		var stack: Array = [sid]
		var reaches_root := false
		while not stack.is_empty():
			var cur: String = stack.pop_back()
			if seen.has(cur):
				continue
			seen[cur] = true
			var reqs: Array = ids.get(cur, {}).get("requires", [])
			if reqs.is_empty():
				reaches_root = true
			for r in reqs:
				if str(r) == sid:
					errors.append("%s/%s: vòng phụ thuộc" % [where, sid])
				stack.append(str(r))
		if not reaches_root:
			errors.append("%s/%s: không tới được từ ải gốc" % [where, sid])
	if m.get("endless") is Dictionary:
		if m.get("stages_provider", "") == "entries":
			var es: Array = m["endless"].get("entries", [])
			if es.is_empty():
				errors.append(where + " endless: thiếu entries")
			for it in es:
				var z := str(it.get("zone", "")) if it is Dictionary else "?"
				if not (it is Dictionary) or str(it.get("id", "")) == "" or (z != "" and JetLevel.zone_def(z).is_empty()):
					errors.append(where + " endless: mục cần id, zone rỗng hoặc có trong data/jet/zones.json")
				else:
					_check_key(it, "title_key", where + " mục " + str(it["id"]), warnings)
			_check_params(m["endless"].get("params", {}), str(m.get("id", "")), where + " endless", errors)
			_check_reward(m["endless"].get("rewards", {}).get("base", {}), item_ids, where + " endless base", errors)
		if m.get("stages_provider", "") == "routes":
			var rs: Array = m["endless"].get("routes", [])
			if rs.is_empty():
				errors.append(where + " endless: thiếu routes")
			for r in rs:
				if not (r is Dictionary) or str(r.get("id", "")) == "" or not (r.get("seed") is float or r.get("seed") is int):
					errors.append(where + " endless: mỗi tuyến cần id + seed")
				else:
					_check_key(r, "title_key", where + " tuyến " + str(r["id"]), warnings)
		_check_stars(m["endless"].get("stars", []), allowed, where + " endless", errors, warnings)
		var byd: Dictionary = m["endless"].get("by_difficulty", {})
		for diff in m["endless"].get("difficulties", []):
			if not byd.has(diff):
				errors.append("%s endless: thiếu by_difficulty.%s" % [where, str(diff)])
				continue
			_check_params(byd[diff].get("params", {}), str(m.get("id", "")), "%s endless %s" % [where, str(diff)], errors)
			var r: Dictionary = byd[diff].get("rewards", {})
			_check_reward(r.get("base", {}), item_ids, "%s endless %s base" % [where, str(diff)], errors)


## Tham số ải: số trong khoảng an toàn, chữ trong danh sách cho phép (MinigameRegistry.PARAM_RANGES / PARAM_CHOICES).
static func _check_params(params: Dictionary, mode_id: String, w: String, errors: PackedStringArray) -> void:
	var ranges := MinigameRegistry.param_ranges(mode_id)
	for path in ranges:
		var v: Variant = MinigameRegistry.param(params, path)
		if v == null:
			continue
		if not (v is float or v is int):
			errors.append("%s: params.%s phải là số" % [w, path])
		elif float(v) < float(ranges[path][0]) or float(v) > float(ranges[path][1]):
			errors.append("%s: params.%s = %s ngoài khoảng %s–%s" % [w, path, str(v), str(ranges[path][0]), str(ranges[path][1])])
	if mode_id.trim_suffix("_endless") == "jet" and not params.has("endless"):
		var jid := str(MinigameRegistry.param(params, "level.id", ""))
		var jl := JetLevel.load_id(jid)
		if not jl.is_valid():
			errors.append("%s: params.level.id '%s': %s" % [w, jid, "; ".join(jl.errors)])
	if mode_id.trim_suffix("_endless") == "runner" and not params.has("gen"):
		var level_id := str(MinigameRegistry.param(params, "level.id", ""))
		var lv := RunnerLevel.load_id(level_id)
		if not lv.is_valid():
			errors.append("%s: params.level.id '%s': %s" % [w, level_id, "; ".join(lv.errors)])
	var choices := MinigameRegistry.param_choices(mode_id)
	for path in choices:
		var v: Variant = MinigameRegistry.param(params, path)
		if v != null and not str(v) in choices[path]:
			errors.append("%s: params.%s = '%s' không hợp lệ (%s)" % [w, path, str(v), ", ".join(PackedStringArray(choices[path]))])


static func _check_card(card: Variant, w: String, errors: PackedStringArray, warnings: PackedStringArray) -> void:
	if not (card is Dictionary):
		errors.append("%s: card phải là object" % w)
		return
	_check_key(card, "drops_key", w + " card", warnings)
	for layer in card.get("art", []):
		var path := str(layer.get("path", "")) if layer is Dictionary else ""
		if path == "" or not ResourceLoader.exists(path):
			warnings.append("%s card: không có ảnh '%s' (thẻ vẽ nền màu thay thế)" % [w, path])
		var r: Variant = layer.get("rect", [0, 0, 1, 1]) if layer is Dictionary else null
		if not (r is Array and r.size() == 4):
			errors.append("%s card: rect phải là [x, y, rộng, cao]" % w)
		if layer is Dictionary and not str(layer.get("fit", "fit")) in ["fit", "cover", "cover_top"]:
			errors.append("%s card: fit phải là fit / cover / cover_top" % w)


static func _check_stars(stars: Array, allowed: Array, w: String, errors: PackedStringArray,
		warnings: PackedStringArray) -> void:
	if stars.size() != 3:
		errors.append("%s: cần đúng 3 điều kiện sao" % w)
	for c in stars:
		var p := StarEvaluator.parse(str(c))
		if p.has("error"):
			errors.append("%s: %s" % [w, p["error"]])
		elif str(p["kind"]) == "stat" and not allowed.has(p["key"]):
			warnings.append("%s: khóa stat lạ '%s'" % [w, p["key"]])


static func _check_reward(r: Variant, item_ids: PackedStringArray, w: String, errors: PackedStringArray) -> void:
	if not (r is Dictionary):
		errors.append("%s: thưởng phải là object" % w)
		return
	for k in r:
		if k == "materials":
			for id in r[k]:
				if not item_ids.is_empty() and not item_ids.has(str(id)):
					errors.append("%s: vật phẩm không có '%s'" % [w, str(id)])
				if int(r[k][id]) < 0:
					errors.append("%s: số âm" % w)
		elif not REWARD_CURRENCIES.has(str(k)):
			errors.append("%s: loại thưởng lạ '%s'" % [w, str(k)])


static func _check_key(d: Dictionary, field: String, where: String, warnings: PackedStringArray) -> void:
	var key := str(d.get(field, ""))
	if key == "":
		return
	if TranslationServer.translate(key) == key:
		warnings.append("%s: thiếu bản dịch %s" % [where, key])
