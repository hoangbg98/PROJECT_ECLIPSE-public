extends GdUnitTestSuite
## Mặt đất của màn: bản vẽ bằng mã (khối `ground` có màu) và bản vẽ tay (khối `ground.atlas`, ô lấy theo toạ độ thế giới).

const ATLAS_PATH := "user://test_ground_atlas.png"


func after_test() -> void:
	if FileAccess.file_exists(ATLAS_PATH):
		DirAccess.remove_absolute(ATLAS_PATH)


func _synthetic_atlas() -> void:
	var img := Image.create(64 * 16, 64 * 13, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.3, 0.3, 1.0))
	img.save_png(ATLAS_PATH)


func _map(ground: Dictionary) -> StageMap:
	var m := StageMap.new()
	m.tile_size = 64
	m.rows = PackedStringArray(["..=.", "####", "####", "####"])
	m.data = {"ground": ground}
	return m


func test_textured_coords_follow_world_column_and_depth() -> void:
	assert_vector(StageMap.textured_coords(0, 0)).is_equal(Vector2i(0, 0))        # mép trên
	assert_vector(StageMap.textured_coords(3, 1)).is_equal(Vector2i(3, 1))        # hàng đất đầu
	assert_vector(StageMap.textured_coords(17, 2)).is_equal(Vector2i(1, 2))       # cột lặp mỗi 16
	assert_vector(StageMap.textured_coords(5, 13)).is_equal(Vector2i(5, 1))       # độ sâu lặp mỗi 12 hàng
	assert_vector(StageMap.textured_coords(5, 12)).is_equal(Vector2i(5, 12))


func test_painted_ground_layer_uses_atlas_cells() -> void:
	_synthetic_atlas()
	var m := _map({"atlas": ATLAS_PATH, "base": "#50434d", "seed": 3})
	var layer: TileMapLayer = auto_free(m.build_layer())
	assert_vector(layer.get_cell_atlas_coords(Vector2i(1, 1))).is_equal(Vector2i(1, 0))   # mép trên
	assert_vector(layer.get_cell_atlas_coords(Vector2i(1, 2))).is_equal(Vector2i(1, 1))   # dưới mép 1 hàng
	assert_vector(layer.get_cell_atlas_coords(Vector2i(2, 3))).is_equal(Vector2i(2, 2))
	assert_vector(layer.get_cell_atlas_coords(Vector2i(2, 0))).is_equal(Vector2i(2, GroundSkin.PLANK_ROW))   # platform
	var src := layer.tile_set.get_source(0) as TileSetAtlasSource
	assert_int(src.get_tiles_count()).is_equal(GroundSkin.ATLAS_COLS * GroundSkin.ATLAS_ROWS)
	assert_int(src.texture.get_height()).is_equal(64 * GroundSkin.ATLAS_ROWS)
	# ván là platform một chiều, đất đặc va chạm trọn ô
	var plank := src.get_tile_data(Vector2i(2, GroundSkin.PLANK_ROW), 0)
	assert_bool(plank.is_collision_polygon_one_way(0, 0)).is_true()
	var soil := src.get_tile_data(Vector2i(2, 1), 0)
	assert_bool(soil.is_collision_polygon_one_way(0, 0)).is_false()


func test_missing_atlas_falls_back_to_code_painted_ground() -> void:
	var m := _map({"atlas": "user://khong_co.png", "base": "#50434d", "seed": 3})
	var layer: TileMapLayer = auto_free(m.build_layer())
	var src := layer.tile_set.get_source(0) as TileSetAtlasSource
	assert_int(src.get_tiles_count()).is_equal(3)                                  # solid, one-way, surface
	assert_vector(layer.get_cell_atlas_coords(Vector2i(1, 1))).is_equal(StageMap.ATLAS_SURFACE)
	assert_vector(layer.get_cell_atlas_coords(Vector2i(1, 2))).is_equal(StageMap.ATLAS_SOLID)


func test_no_ground_block_keeps_placeholder_tiles() -> void:
	var m := _map({})
	var layer: TileMapLayer = auto_free(m.build_layer())
	assert_vector(layer.get_cell_atlas_coords(Vector2i(1, 1))).is_equal(StageMap.ATLAS_SOLID)
	assert_vector(layer.get_cell_atlas_coords(Vector2i(2, 0))).is_equal(StageMap.ATLAS_ONE_WAY)
