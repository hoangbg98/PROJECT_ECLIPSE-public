extends GdUnitTestSuite
## Bụi chân: chỉ phát khi đứng trên đất và chạy đủ nhanh; gắn sẵn vào PlayerController.

const PLAYER_SCENE := preload("res://scenes/player/player_character.tscn")


func test_should_emit_rule() -> void:
	assert_bool(FootDust.should_emit(true, 200.0)).is_true()
	assert_bool(FootDust.should_emit(true, -200.0)).is_true()
	assert_bool(FootDust.should_emit(true, 10.0)).is_false()      # đứng yên / đi rất chậm
	assert_bool(FootDust.should_emit(false, 300.0)).is_false()    # trên không


func test_player_has_foot_dust_child() -> void:
	var p: PlayerController = auto_free(PLAYER_SCENE.instantiate())
	add_child(p)
	var dust := p.get_node_or_null("FootDust") as FootDust
	assert_object(dust).is_not_null()
	assert_bool(dust.emitting).is_false()
