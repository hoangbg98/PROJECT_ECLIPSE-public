class_name JetArt
extends RefCounted
## Ảnh Bay Nguyên Tố (assets/jet/, docs/design/JET_ART_BRIEF.md): nạp một lần, nhớ trong bộ đệm tĩnh. Chỉ UI dùng
## (JetStage); logic (JetSim) không biết ảnh. Thiếu ảnh thì trả null và cảnh báo một lần, màn chơi bỏ qua phần đó.

const DIR := "res://assets/jet/"
## Bề rộng thân cột Van Sét trong ảnh gốc (x 5–91 của 96); game co về `gate_width`.
const GATE_BODY_ART_W := 86.0
const GATE_ART_SIZE := Vector2(96, 256)

static var _tex: Dictionary = {}
static var _seq: Dictionary = {}
static var _frames: Dictionary = {}
static var _gate: Dictionary = {}
static var _flame: Array[Texture2D] = []


static func tex(rel: String) -> Texture2D:
	if not _tex.has(rel):
		var p := DIR + rel
		var t: Texture2D = load(p) as Texture2D if ResourceLoader.exists(p) else null
		if t == null:
			push_warning("JetArt: thiếu " + p)
		_tex[rel] = t
	return _tex[rel]


## Dãy frame `dir/id_000.png` … (n frame).
static func seq(dir: String, id: String, n: int) -> Array[Texture2D]:
	var key := "%s|%s" % [dir, id]
	if not _seq.has(key):
		var out: Array[Texture2D] = []
		for i in n:
			var t := tex("%s/%s_%03d.png" % [dir, id, i])
			if t:
				out.append(t)
		_seq[key] = out
	return _seq[key]


## Frame theo thời gian: `fps` khung/giây, `phase` lệch pha (đơn vị frame).
static func frame(arr: Array[Texture2D], fps: float, t: float, phase := 0.0) -> Texture2D:
	if arr.is_empty():
		return null
	return arr[int(floorf(t * fps + phase)) % arr.size()]


## Cột Van Sét co về bề rộng thân `body_w` px (lặp dọc liền mạch, nên chỉ co đều hai chiều).
static func gate_column(body_w: float) -> Texture2D:
	var key := int(roundf(body_w))
	if not _gate.has(key):
		var src := tex("jet_gate_block.png")
		var out: Texture2D = null
		if src:
			var k := body_w / GATE_BODY_ART_W
			var img := src.get_image()
			if img:
				img.resize(maxi(int(roundf(GATE_ART_SIZE.x * k)), 1), maxi(int(roundf(GATE_ART_SIZE.y * k)), 1), Image.INTERPOLATE_LANCZOS)
				out = ImageTexture.create_from_image(img)
		_gate[key] = out
	return _gate[key]


## Lửa phụt: ảnh gốc xanh ngọc (Kazeyumi), đổi sang thang xám sáng để nhân màu nguyên tố khi vẽ.
static func flame() -> Array[Texture2D]:
	if _flame.is_empty():
		for t in seq("jet_flame", "jet_flame_burn", 4):
			var img := t.get_image()
			if img == null:
				continue
			img.convert(Image.FORMAT_RGBA8)
			var peak := 0.01
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a > 0.02:
						peak = maxf(peak, c.r * 0.299 + c.g * 0.587 + c.b * 0.114)
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a > 0.0:
						var l := clampf((c.r * 0.299 + c.g * 0.587 + c.b * 0.114) / peak, 0.0, 1.0)
						l = lerpf(0.55, 1.0, l)
						img.set_pixel(x, y, Color(l, l, l, c.a))
			_flame.append(ImageTexture.create_from_image(img))
	return _flame


## SpriteFrames của hình biến hình: "dragon" (fly, break) hoặc "robo" (walk, jump, crush, break).
static func form_frames(form: String) -> SpriteFrames:
	if _frames.has(form):
		return _frames[form]
	var sf := SpriteFrames.new()
	sf.remove_animation(&"default")
	var specs: Array = []
	if form == "dragon":
		specs = [["fly", "jet_dragon/fly", "jet_dragon_fly", 6, 12.0, true], ["break", "jet_dragon/break", "jet_dragon_break", 6, 18.0, false]]
	elif form == "robo":
		specs = [["walk", "jet_robo/walk", "jet_robo_walk", 6, 14.0, true], ["jump", "jet_robo/jump", "jet_robo_jump", 3, 10.0, false],
				["crush", "jet_robo/crush", "jet_robo_crush", 4, 20.0, false], ["break", "jet_robo/break", "jet_robo_break", 6, 14.0, false]]
	for s in specs:
		sf.add_animation(s[0])
		sf.set_animation_speed(s[0], float(s[4]))
		sf.set_animation_loop(s[0], bool(s[5]))
		for t in seq(str(s[1]), str(s[2]), int(s[3])):
			sf.add_frame(s[0], t)
	_frames[form] = sf
	return sf


static func zone_tex(kind: String, zone: String) -> Texture2D:
	if zone == "thunder":
		if kind == "mid":
			return tex("jet_bg_thunder_mid_v2.png")
		if kind == "floor":
			return tex("jet_floor_thunder_v2.png")
	match kind:
		"far":
			return tex("jet_bg_%s_far.png" % zone)
		"mid":
			return tex("jet_bg_%s_mid.png" % zone)
		"floor":
			return tex("jet_floor_%s.png" % zone)
		"ceiling":
			return tex("jet_ceiling_%s.png" % zone)
	return null
