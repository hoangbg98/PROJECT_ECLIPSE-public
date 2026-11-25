class_name StageMap
extends RefCounted
## Đọc bản đồ ký tự (data/stages/*.json) và dựng TileMapLayer.
## Ký hiệu: `#` khối đặc, `=` platform một chiều, `P` điểm xuất phát, `D` hình nộm tập, `E` quái,
## `C` checkpoint, `.` trống. Màn thật (M6) còn có `waves`, `boss`, `rewards` trong cùng file (xem StageController).
## Đổi layout: sửa file JSON, không sửa code.

const TILES_TEXTURE := "res://assets/placeholders/placeholder_tiles_64.png"
const ATLAS_SOLID := Vector2i(0, 0)
const ATLAS_ONE_WAY := Vector2i(1, 0)
## Đất đặc có mép trên (chỉ dùng khi màn có khối `ground`, xem GroundSkin).
const ATLAS_SURFACE := Vector2i(2, 0)
## Va chạm thế giới ở layer 1 (người chơi mask 1).
const WORLD_LAYER := 1
## Độ dày phần va chạm của platform một chiều (px, tính từ mép trên ô).
const ONE_WAY_THICKNESS := 16.0

var name := ""
var tile_size := 64
var rows: PackedStringArray = []
var spawn_cell := Vector2i(-1, -1)
var dummy_cells: Array[Vector2i] = []
var enemy_cells: Array[Vector2i] = []
var checkpoint_cells: Array[Vector2i] = []
## Toàn bộ nội dung file (id, waves, boss, rewards…).
var data: Dictionary = {}
var errors := PackedStringArray()


static func load_from(path: String) -> StageMap:
	var m := StageMap.new()
	if not FileAccess.file_exists(path):
		m.errors.append("không có file bản đồ: %s" % path)
		return m
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("rows")) != TYPE_ARRAY:
		m.errors.append("bản đồ sai định dạng (cần object có 'rows'): %s" % path)
		return m
	m.data = data
	m.name = str(data.get("name", path.get_file().get_basename()))
	m.tile_size = int(data.get("tile_size", 64))
	for r in data["rows"]:
		m.rows.append(str(r))
	m._validate()
	return m


func _validate() -> void:
	if rows.is_empty():
		errors.append("bản đồ rỗng")
		return
	var w := rows[0].length()
	var spawns := 0
	for y in rows.size():
		if rows[y].length() != w:
			errors.append("hàng %d dài %d, cần %d" % [y, rows[y].length(), w])
		for x in rows[y].length():
			var ch := rows[y][x]
			if ch not in ["#", "=", "P", "D", "E", "C", "."]:
				errors.append("ký tự lạ '%s' ở (%d, %d)" % [ch, x, y])
			elif ch == "P":
				spawn_cell = Vector2i(x, y)
				spawns += 1
			elif ch == "D":
				dummy_cells.append(Vector2i(x, y))
			elif ch == "E":
				enemy_cells.append(Vector2i(x, y))
			elif ch == "C":
				checkpoint_cells.append(Vector2i(x, y))
	if spawns != 1:
		errors.append("cần đúng 1 điểm 'P', có %d" % spawns)


func size_cells() -> Vector2i:
	return Vector2i(rows[0].length() if not rows.is_empty() else 0, rows.size())


## Biên bản đồ theo pixel (dùng cho giới hạn camera).
func bounds_px() -> Rect2i:
	return Rect2i(Vector2i.ZERO, size_cells() * tile_size)


## Điểm xuất phát: giữa đáy ô `P` (chân nhân vật).
func spawn_position() -> Vector2:
	return cell_feet(spawn_cell)


## Vị trí chân trên mặt đất của một cột: ô trống thấp nhất nằm ngay trên khối đặc (tính từ trên xuống,
## bỏ qua platform). Không có đất (hố) thì trả về đáy bản đồ.
func ground_feet(col: int) -> Vector2:
	col = clampi(col, 0, size_cells().x - 1)
	for y in range(1, rows.size()):
		if rows[y][col] == "#" and rows[y - 1][col] != "#":
			return cell_feet(Vector2i(col, y - 1))
	return cell_feet(Vector2i(col, rows.size() - 1))


## Tọa độ x (px) của mép trái một cột.
func col_x(col: int) -> float:
	return float(col * tile_size)


## Giữa đáy một ô (vị trí chân).
func cell_feet(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * tile_size, (cell.y + 1) * tile_size)


## Dựng TileSet + TileMapLayer từ bản đồ.
func build_layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Tiles"
	var ground := ground_theme()
	layer.tile_set = make_tileset(tile_size, ground)
	for y in rows.size():
		for x in rows[y].length():
			match rows[y][x]:
				"#":
					var depth := _solid_depth(x, y)
					if ground.has("atlas"):
						layer.set_cell(Vector2i(x, y), 0, textured_coords(x, depth))
					else:
						layer.set_cell(Vector2i(x, y), 0, ATLAS_SURFACE if (not ground.is_empty() and depth == 0) else ATLAS_SOLID)
				"=":
					layer.set_cell(Vector2i(x, y), 0, Vector2i(x % GroundSkin.ATLAS_COLS, GroundSkin.PLANK_ROW) if ground.has("atlas") else ATLAS_ONE_WAY)
	return layer


## Số ô "#" liên tiếp ngay phía trên ô (x, y); 0 = hở phía trên (mép đất).
func _solid_depth(x: int, y: int) -> int:
	var d := 0
	var yy := y - 1
	while yy >= 0 and x < rows[yy].length() and rows[yy][x] == "#":
		d += 1
		yy -= 1
	return d


## Ô trong atlas vẽ tay (GroundSkin): hàng 0 = mép trên, hàng 1..SOIL_ROWS = thân đất theo độ sâu; cột theo toạ độ thế giới.
static func textured_coords(x: int, depth: int) -> Vector2i:
	var col := posmod(x, GroundSkin.ATLAS_COLS)
	if depth <= 0:
		return Vector2i(col, 0)
	return Vector2i(col, 1 + (depth - 1) % GroundSkin.SOIL_ROWS)


## Khối `ground` của màn ({base, light, dark, lip, seed}); rỗng = dùng ô lưới tạm.
func ground_theme() -> Dictionary:
	var g: Variant = data.get("ground")
	if not (g is Dictionary):
		return {}
	var theme: Dictionary = g
	if theme.has("atlas"):
		var path := str(theme["atlas"])
		if not (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
			theme = theme.duplicate()
			theme.erase("atlas")      # thiếu ảnh vẽ tay: lùi về bản vẽ bằng mã
	return theme


static func make_tileset(size: int, ground := {}) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(size, size)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, WORLD_LAYER)
	ts.set_physics_layer_collision_mask(0, 0)

	var src := TileSetAtlasSource.new()
	var textured := ground.has("atlas")
	var tex: Texture2D = GroundSkin.load_atlas(ground, size) if textured else null
	if textured and tex == null:
		textured = false      # không nạp được ảnh: lùi về bản vẽ bằng mã
		ground = ground.duplicate()
		ground.erase("atlas")
	var skinned := not ground.is_empty()
	src.texture = tex if textured else (GroundSkin.build_atlas(ground, size) if skinned else load(TILES_TEXTURE))
	src.texture_region_size = Vector2i(size, size)
	if textured:
		for cx in GroundSkin.ATLAS_COLS:
			for cy in GroundSkin.ATLAS_ROWS:
				src.create_tile(Vector2i(cx, cy))
	else:
		src.create_tile(ATLAS_SOLID)
		src.create_tile(ATLAS_ONE_WAY)
		if skinned:
			src.create_tile(ATLAS_SURFACE)
	ts.add_source(src, 0)

	var h := size * 0.5
	var box := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	var ledge := PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + ONE_WAY_THICKNESS), Vector2(-h, -h + ONE_WAY_THICKNESS)])
	if textured:
		for cx in GroundSkin.ATLAS_COLS:
			for cy in GroundSkin.ATLAS_ROWS:
				var td := src.get_tile_data(Vector2i(cx, cy), 0)
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, box if cy < GroundSkin.PLANK_ROW else ledge)
				if cy == GroundSkin.PLANK_ROW:
					td.set_collision_polygon_one_way(0, 0, true)
		return ts

	var solid := src.get_tile_data(ATLAS_SOLID, 0)
	solid.add_collision_polygon(0)
	solid.set_collision_polygon_points(0, 0, box)

	if skinned:
		var surface := src.get_tile_data(ATLAS_SURFACE, 0)
		surface.add_collision_polygon(0)
		surface.set_collision_polygon_points(0, 0, box)

	var plat := src.get_tile_data(ATLAS_ONE_WAY, 0)
	plat.add_collision_polygon(0)
	plat.set_collision_polygon_points(0, 0, ledge)
	plat.set_collision_polygon_one_way(0, 0, true)
	return ts
