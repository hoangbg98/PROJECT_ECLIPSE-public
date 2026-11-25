class_name GroundSkin
extends RefCounted
## Da mặt đất vẽ bằng mã cho màn chơi (thay ô lưới tạm của placeholder_tiles_64): đất có vân và đá nhỏ, viền mép trên
## ("môi") nhấp nhô để nhìn như đường đất trên nền map, platform một chiều là tấm ván dày. Màu lấy từ khối `ground`
## trong data/stages/<id>.json (sinh bằng tools/stages/ground_palettes.py từ nền xa của ải); không có khối `ground`
## thì StageMap giữ ô lưới tạm. Mọi con số cân bằng không nằm ở đây, chỉ có hình dáng.
##
## Atlas ngang gồm 3 ô vuông `size` px: [0] đất đặc, [1] platform một chiều, [2] đất đặc mép trên (có "môi").
##
## Bản vẽ tay (khối `ground.atlas` trỏ tới ảnh do tools/stages/build_ground_atlas.py ghép từ ảnh Codex): atlas 16 cột x 14 hàng ô
## `size` px; hàng 0 = mép trên, hàng 1..12 = thân đất (chọn theo độ sâu), hàng 13 = ván platform (vẽ bằng mã ở đây).
## StageMap lấy ô theo toạ độ thế giới (cột % ATLAS_COLS) nên đất liền mạch như một bức tranh dài.

const TILE_COUNT := 3
const ATLAS_COLS := 16
const SOIL_ROWS := 12
const PLANK_ROW := 13
const ATLAS_ROWS := 14
const DEFAULT_BASE := "#50434d"
const DEFAULT_LIGHT := "#6d5e68"
const DEFAULT_DARK := "#352c36"
const DEFAULT_LIP := "#8a7685"


static func _color(theme: Dictionary, key: String, fallback: String) -> Color:
	return Color.html(str(theme.get(key, fallback)))


## Dựng atlas 3 ô (ImageTexture). Cùng `theme` cho cùng ảnh (hạt giống cố định → test và ảnh chụp lặp lại được).
static func build_atlas(theme: Dictionary, size: int) -> ImageTexture:
	var base := _color(theme, "base", DEFAULT_BASE)
	var light := _color(theme, "light", DEFAULT_LIGHT)
	var dark := _color(theme, "dark", DEFAULT_DARK)
	var lip := _color(theme, "lip", DEFAULT_LIP)
	var seed_value := int(theme.get("seed", 7))

	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.05
	var mottle := noise.get_seamless_image(size, size)
	noise.frequency = 0.22
	noise.seed = seed_value + 11
	var grain := noise.get_seamless_image(size, size)

	var img := Image.create(size * TILE_COUNT, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_paint_dirt(img, 0, size, base, light, dark, mottle, grain, seed_value)
	_paint_plank(img, size, size, base, light, dark, lip, grain)
	_paint_dirt(img, size * 2, size, base, light, dark, mottle, grain, seed_value)
	_paint_lip(img, size * 2, size, base, lip, dark, grain)
	return ImageTexture.create_from_image(img)


## Đất: màu nền loang theo nhiễu mịn, hạt nhiễu thô, vài viên đá nhỏ tối / sáng (lặp liền mạch giữa các ô kề nhau).
static func _paint_dirt(img: Image, x0: int, size: int, base: Color, light: Color, dark: Color,
		mottle: Image, grain: Image, seed_value: int) -> void:
	for y in size:
		for x in size:
			var m := mottle.get_pixel(x, y).r        # 0..1
			var g := grain.get_pixel(x, y).r
			var c := base
			if m >= 0.5:
				c = base.lerp(light, clampf((m - 0.5) * 1.1, 0.0, 1.0))
			else:
				c = base.lerp(dark, clampf((0.5 - m) * 1.1, 0.0, 1.0))
			c = c.lerp(dark, clampf((0.45 - g) * 0.5, 0.0, 0.25))
			img.set_pixel(x0 + x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 9:
		var cx := rng.randi_range(8, size - 9)
		var cy := rng.randi_range(14, size - 9)
		var rx := rng.randi_range(2, 5)
		var ry := maxi(1, rx - rng.randi_range(0, 2))
		var tone := dark if rng.randf() < 0.55 else light
		for dy in range(-ry, ry + 1):
			for dx in range(-rx, rx + 1):
				if float(dx * dx) / float(rx * rx) + float(dy * dy) / float(ry * ry) <= 1.0:
					var px := x0 + cx + dx
					var py := cy + dy
					img.set_pixel(px, py, img.get_pixel(px, py).lerp(tone, 0.55))


## Mép trên của đất ("môi"): dải sáng nhấp nhô (lặp theo chu kỳ nên liền mạch giữa các ô), vạch sáng trên cùng, bóng đổ dưới.
static func _paint_lip(img: Image, x0: int, size: int, base: Color, lip: Color, dark: Color, grain: Image) -> void:
	var hi := lip.lightened(0.25)
	for x in size:
		var phase := TAU * float(x) / float(size)
		var h := int(round(10.0 + 3.0 * sin(phase * 2.0) + 2.0 * sin(phase * 5.0 + 1.0)))
		for y in h:
			var t := float(y) / float(maxi(h, 1))
			var g := grain.get_pixel(x, y).r
			var c := lip.lerp(base, t * 0.7).lerp(dark, clampf((0.45 - g) * 0.4, 0.0, 0.2))
			if y <= 1:
				c = hi.lerp(lip, float(y) * 0.5)
			img.set_pixel(x0 + x, y, c)
		var sy := mini(h, size - 1)
		img.set_pixel(x0 + x, sy, img.get_pixel(x0 + x, sy).lerp(dark, 0.55))


## Platform một chiều: tấm ván dày ~20 px có thớ ngang, mép dưới tối, phần còn lại của ô trong suốt.
static func _paint_plank(img: Image, x0: int, size: int, base: Color, light: Color, dark: Color, lip: Color, grain: Image) -> void:
	var thick := 20
	for y in thick:
		for x in size:
			var g := grain.get_pixel(x, y).r
			var c := base.lerp(light, 0.35 + 0.3 * g)
			if y % 7 == 6:
				c = c.lerp(dark, 0.35)               # thớ gỗ / khe ghép
			if y <= 1:
				c = lip.lerp(light, 0.4)               # mép sáng phía trên
			elif y >= thick - 2:
				c = dark
			img.set_pixel(x0 + x, y, c)


## Atlas từ ảnh vẽ tay (16 cột x 13 hàng ô 64 px) + hàng ván vẽ bằng mã. Trả null nếu không nạp được ảnh.
static func load_atlas(theme: Dictionary, size: int) -> ImageTexture:
	var path := str(theme.get("atlas", ""))
	var src: Image = null
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		src = tex.get_image() if tex else null
	elif FileAccess.file_exists(path):
		src = Image.load_from_file(path)      # ảnh chưa import (vd user:// trong test)
	if src == null:
		return null
	src.convert(Image.FORMAT_RGBA8)
	var native := src.get_width() / ATLAS_COLS
	if native != size:
		src.resize(size * ATLAS_COLS, int(src.get_height() * float(size) / float(native)), Image.INTERPOLATE_LANCZOS)
	var img := Image.create(size * ATLAS_COLS, size * ATLAS_ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.blit_rect(src, Rect2i(0, 0, src.get_width(), mini(src.get_height(), size * PLANK_ROW)), Vector2i(0, 0))
	# hàng ván: vẽ một ô rồi chép ra mọi cột
	var strip := Image.create(size * TILE_COUNT, size, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	var noise := FastNoiseLite.new()
	noise.seed = int(theme.get("seed", 7)) + 11
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.22
	var grain := noise.get_seamless_image(size, size)
	_paint_plank(strip, 0, size, _color(theme, "base", DEFAULT_BASE), _color(theme, "light", DEFAULT_LIGHT),
			_color(theme, "dark", DEFAULT_DARK), _color(theme, "lip", DEFAULT_LIP), grain)
	for c in ATLAS_COLS:
		img.blit_rect(strip, Rect2i(0, 0, size, size), Vector2i(c * size, PLANK_ROW * size))
	return ImageTexture.create_from_image(img)
