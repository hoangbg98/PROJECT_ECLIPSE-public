extends GdUnitTestSuite

const ENEMY_SCENE := preload("res://scenes/enemies/enemy_slime.tscn")

var _enemy: EnemyController
var _large_slime: EnemyController


func before_test() -> void:
	_enemy = ENEMY_SCENE.instantiate()
	add_child(_enemy)


func after_test() -> void:
	if is_instance_valid(_enemy):
		_enemy.queue_free()
	if is_instance_valid(_large_slime):
		_large_slime.queue_free()


func test_enemy_visual_and_footprint_scale_is_data_driven() -> void:
	# Cặn tro (_enemy) cỡ thường 1.0; Cặn lớn (enemy_slime_02) gấp đôi 2.0 — số trong data/enemies/*.tres.
	_large_slime = ENEMY_SCENE.instantiate()
	_large_slime.enemy_id = "enemy_slime_02"
	add_child(_large_slime)
	assert_float(_enemy.sprite.scale.y).is_equal(1.0)
	assert_float(_enemy.sprite.scale.x).is_equal(float(_enemy.facing))
	assert_float(absf(_large_slime.sprite.scale.x)).is_equal(2.0)
	assert_float(_large_slime.sprite.scale.y).is_equal(2.0)
	assert_int(signi(int(_large_slime.sprite.scale.x))).is_equal(_large_slime.facing)
	var small_body := _enemy.get_node("Shape") as CollisionShape2D
	var large_body := _large_slime.get_node("Shape") as CollisionShape2D
	var small_hurt := _enemy.get_node("Hurtbox/Shape") as CollisionShape2D
	var large_hurt := _large_slime.get_node("Hurtbox/Shape") as CollisionShape2D
	assert_float((small_body.shape as RectangleShape2D).size.x).is_equal(110.0)
	assert_float((small_hurt.shape as RectangleShape2D).size.x).is_equal(110.0)
	assert_float((large_body.shape as RectangleShape2D).size.x).is_equal(220.0)
	assert_float((large_hurt.shape as RectangleShape2D).size.y).is_greater((small_hurt.shape as RectangleShape2D).size.y)
	assert_bool(_enemy.runner.run("attack", _enemy.facing)).is_true()
	assert_bool(_large_slime.runner.run("attack", _large_slime.facing)).is_true()
	assert_float(_enemy.runner._attached.scale.y).is_equal(1.0)
	assert_float(absf(_large_slime.runner._attached.scale.x)).is_equal(2.0)


func test_slime_uses_approved_sprite_and_has_six_animations() -> void:
	assert_bool(_enemy.sprite.visible).is_true()
	assert_bool(_enemy.body.visible).is_false()
	for animation in ["idle", "move", "attack", "hurt", "stun", "death"]:
		assert_bool(_enemy.sprite.sprite_frames.has_animation(animation)).is_true()


func test_state_selects_sprite_animation() -> void:
	_enemy.state = EnemyController.State.PATROL
	_enemy.velocity.x = 30.0
	_enemy._update_look()
	assert_str(_enemy.sprite.animation).is_equal("move")
	_enemy.velocity.x = 0.0
	_enemy._update_look()
	assert_str(_enemy.sprite.animation).is_equal("idle")

	_enemy.runner.current = _enemy.def.attack
	_enemy.state = EnemyController.State.ATTACK
	_enemy._update_look()
	assert_str(_enemy.sprite.animation).is_equal("attack")
	assert_int(_enemy.sprite.frame).is_equal(0)
	_enemy.state = EnemyController.State.STAGGER
	_enemy._update_look()
	assert_str(_enemy.sprite.animation).is_equal("hurt")
	_enemy.state = EnemyController.State.STUNNED
	_enemy._update_look()
	assert_str(_enemy.sprite.animation).is_equal("stun")
	_enemy.state = EnemyController.State.DEAD
	_enemy._update_look()
	assert_str(_enemy.sprite.animation).is_equal("death")


func test_enemy_without_sprite_frames_keeps_polygon_body() -> void:
	_enemy._using_sprite = false
	_enemy.sprite.visible = false
	_enemy.body.visible = true
	assert_bool(_enemy._try_load_sprite_frames("missing_manifest_test")).is_false()
	assert_bool(_enemy.body.visible).is_true()
	assert_bool(_enemy.sprite.visible).is_false()
