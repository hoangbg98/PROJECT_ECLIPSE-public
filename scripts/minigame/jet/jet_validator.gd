class_name JetValidator
extends RefCounted
## Kiểm công bằng một level Bay Nguyên Tố (docs/design/JET_MODE.md mục 11) bằng hình học, độc lập với bot:
## - đường giữa hành lang (`level.path`) cách mọi vật cản ≥ bán kính Rồng (lớn nhất) + biên;
## - chuyển hướng giữa hai điểm đường ≤ 0.7 × tầm bay tới được trong Δt (bảng mục 4);
## - Cặn Phóng cách đường ở lúc lao tới người bay; Van Sét cách nhau ≥ 1.2 s; không Cặn Phóng trong 1.0 s quanh van;
## - không vật trước 2.0 s; Tinh Lõi cách nhau ≤ `max_core_gap_m`; ≤ 30 vật trên màn.
## Trả về danh sách lỗi (rỗng = đạt).

const MARGIN := 12.0
const SAMPLE := 16.0
const MAX_ACTIVE := 30


static func check(level: JetLevel, rules: JetRules, max_core_gap_m := 1200.0, until_m := 0.0) -> PackedStringArray:
	var errs := PackedStringArray()
	if level.path.size() < 2:
		errs.append("thiếu path")
		return errs
	var end_x := (until_m if until_m > 0.0 else level.length_m) * JetLevel.PX_PER_M
	var need := rules.hit_radius("dragon") + MARGIN
	# 1. Chuyển hướng.
	for i in range(1, level.path.size()):
		var a := level.path[i - 1]
		var b := level.path[i]
		if b.x < a.x - 0.01:
			errs.append("path lùi ở %.0f m" % (b.x / JetLevel.PX_PER_M))
			continue
		if a.x > end_x:
			break
		var dy := b.y - a.y
		if absf(dy) < 1.0:
			continue
		var dt := (b.x - a.x) / maxf(level.scroll_at_px(a.x), 1.0)
		var lim := JetGenerator.reach(dt, dy < 0.0) * JetGenerator.REACH_SAFE + 2.0
		if absf(dy) > lim:
			errs.append("chuyển hướng gắt ở %.0f m: %.0f px trong %.2f s (tối đa %.0f)" % [a.x / JetLevel.PX_PER_M, dy, dt, lim])
	# 2. Hành lang cách vật cản tĩnh.
	var statics: Array[Dictionary] = []
	var first_x := JetLevel.FIRST_EVENT_SEC * level.scroll_base
	var last_gate := -1e9
	var last_core := 0.0
	var gates: Array[float] = []
	for e in level.events:
		var X := float(e["x"])
		if X > end_x:
			break
		if X < first_x - 1.0:
			errs.append("vật '%s' trước %.1f s" % [e["type"], JetLevel.FIRST_EVENT_SEC])
		match str(e["type"]):
			"beam", "swp", "gate":
				statics.append(e)
				if e["type"] == "gate":
					var sc := level.scroll_at_px(X)
					if X - last_gate < 1.2 * sc - 1.0:
						errs.append("hai Van Sét gần nhau ở %.0f m" % (X / JetLevel.PX_PER_M))
					last_gate = X
					gates.append(X)
			"core":
				if X - last_core > max_core_gap_m * JetLevel.PX_PER_M:
					errs.append("Tinh Lõi cách quá %.0f m ở %.0f m" % [max_core_gap_m, X / JetLevel.PX_PER_M])
				last_core = X
	for e in statics:
		var X := float(e["x"])
		var p := X - 160.0
		while p <= X + 160.0:
			var c := Vector2(p, level.path_y(p))
			var cl := JetSim.obstacle_clearance(e, c, p, rules)
			if cl < need:
				errs.append("hành lang chạm '%s' ở %.0f m (cách %.0f px, cần %.0f)" % [e["type"], X / JetLevel.PX_PER_M, cl, need])
				break
			p += SAMPLE
	# 3. Cặn Phóng.
	for e in level.events:
		if e["type"] != "mis" or float(e["x"]) > end_x:
			continue
		var hx := float(e["x"]) + JetGenerator.missile_lead(level, float(e["x"]), rules)
		var p2 := hx - 150.0
		while p2 <= hx + 150.0:
			if absf(float(e["y"]) - level.path_y(p2)) < rules.missile_radius + need:
				errs.append("Cặn Phóng cắt hành lang ở %.0f m" % (hx / JetLevel.PX_PER_M))
				break
			p2 += SAMPLE
		for g in gates:
			if absf(g - hx) < 1.0 * level.scroll_at_px(hx) - 1.0:
				errs.append("Cặn Phóng sát Van Sét ở %.0f m" % (hx / JetLevel.PX_PER_M))
				break
	# 4. Số vật trên màn.
	var view := rules.spawn_x
	var j := 0
	for i in level.events.size():
		var xi := float(level.events[i]["x"])
		while j < level.events.size() and float(level.events[j]["x"]) < xi + view:
			j += 1
		if j - i > MAX_ACTIVE:
			errs.append("quá %d vật trên màn ở %.0f m" % [MAX_ACTIVE, xi / JetLevel.PX_PER_M])
			break
	return errs
