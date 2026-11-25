class_name StarEvaluator
extends RefCounted
## Chấm điều kiện sao (docs/design/MATERIAL_EVENT.md mục 6). Tự phân tích chuỗi, không dùng Expression.
## Cú pháp: `clear` | `rank>=<S|A|B|C|D>` | `score>=<số>` | `stat:<khóa><toán tử><số>`; toán tử `>=`, `<=`, `==`.

const OPS: Array[String] = [">=", "<=", "=="]


## Phân tích một điều kiện: {kind, key, op, value} hoặc {error}.
static func parse(cond: String) -> Dictionary:
	var c := cond.strip_edges()
	if c == "clear":
		return {"kind": "clear"}
	var kind := ""
	var body := ""
	if c.begins_with("rank"):
		kind = "rank"
		body = c.substr(4)
	elif c.begins_with("score"):
		kind = "score"
		body = c.substr(5)
	elif c.begins_with("stat:"):
		kind = "stat"
		body = c.substr(5)
	else:
		return {"error": "không hiểu điều kiện: " + cond}
	for op in OPS:
		var i := body.find(op)
		if i < 0:
			continue
		var key := body.substr(0, i).strip_edges()
		var raw := body.substr(i + op.length()).strip_edges()
		if kind == "rank":
			if key != "" or op != ">=" or MinigameResult.rank_value(raw) < 0:
				return {"error": "hạng sai: " + cond}
			return {"kind": kind, "op": op, "value": raw}
		if not raw.is_valid_float():
			return {"error": "giá trị không phải số: " + cond}
		if kind == "stat" and (key == "" or not key.is_valid_identifier()):
			return {"error": "khóa stat sai: " + cond}
		if kind == "score" and key != "":
			return {"error": "điều kiện điểm sai: " + cond}
		return {"kind": kind, "key": key, "op": op, "value": float(raw)}
	return {"error": "thiếu toán tử: " + cond}


static func check(cond: String, result: MinigameResult) -> bool:
	if result == null or not result.cleared:
		return false
	var p := parse(cond)
	if p.has("error"):
		return false
	match str(p["kind"]):
		"clear":
			return true
		"rank":
			return MinigameResult.rank_value(result.rank) >= MinigameResult.rank_value(str(p["value"]))
		"score":
			return _compare(float(result.score), str(p["op"]), float(p["value"]))
		"stat":
			if not result.stats.has(p["key"]):
				return false
			return _compare(float(result.stats[p["key"]]), str(p["op"]), float(p["value"]))
	return false


## Kết quả 3 sao (ải thua: tất cả false).
static func evaluate(stars: Array, result: MinigameResult) -> Array[bool]:
	var out: Array[bool] = []
	for s in stars:
		out.append(check(str(s), result))
	return out


static func _compare(a: float, op: String, b: float) -> bool:
	match op:
		">=":
			return a >= b - 0.000001
		"<=":
			return a <= b + 0.000001
		"==":
			return absf(a - b) < 0.000001
	return false
