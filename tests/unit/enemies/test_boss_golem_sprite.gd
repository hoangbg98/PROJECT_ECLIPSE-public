extends GdUnitTestSuite
## Phiếu 99 Golem: boss_golem_01 dùng frame đã duyệt; mỗi đòn chạy đúng animation, đòn pha 2 nhanh hơn, chuyển pha chạy `phase`.

const BOSS_SCENE := preload("res://scenes/enemies/boss_golem.tscn")

var _boss: BossController


func before_test() -> void:
	_boss = BOSS_SCENE.instantiate()
	add_child(_boss)


func after_test() -> void:
	if is_instance_valid(_boss):
		_boss.queue_free()


func _show_attack(skill: SkillDef) -> float:
	_boss.runner.current = skill
	_boss.state = EnemyController.State.ATTACK
	_boss._update_look()
	assert_str(_boss.sprite.animation).is_equal(skill.animation)
	assert_int(_boss.sprite.frame).is_equal(0)
	var speed := _boss.sprite.speed_scale
	# về idle để lần sau đổi animation lại từ đầu
	_boss.state = EnemyController.State.PATROL
	_boss.velocity.x = 0.0
	_boss._update_look()
	return speed


func test_golem_uses_sprite_with_all_animations() -> void:
	assert_bool(_boss.sprite.visible).is_true()
	assert_bool(_boss.body.visible).is_false()
	for animation in ["idle", "move", "slam", "charge", "quake", "stun", "phase", "death"]:
		assert_bool(_boss.sprite.sprite_frames.has_animation(animation)).is_true()


func test_each_attack_plays_its_animation_and_phase_two_is_faster() -> void:
	var b := _boss.boss_def()
	var speeds := {}
	for pi in b.phases.size():
		for skill: SkillDef in b.phases[pi].attacks:
			var speed := _show_attack(skill)
			assert_float(speed).is_greater(0.0)
			speeds["%d_%s" % [pi + 1, skill.animation]] = speed
	assert_float(speeds["2_slam"]).is_greater(speeds["1_slam"])


func test_phase_transition_plays_phase_then_returns() -> void:
	_boss._transition_left = 1.0
	_boss._update_look()
	assert_str(_boss.sprite.animation).is_equal("phase")
	_boss._transition_left = 0.0
	_boss.state = EnemyController.State.CHASE
	_boss.velocity.x = 50.0
	_boss._update_look()
	assert_str(_boss.sprite.animation).is_equal("move")


func test_stagger_without_hurt_animation_falls_back_to_idle() -> void:
	_boss.state = EnemyController.State.STAGGER
	_boss._update_look()
	assert_str(_boss.sprite.animation).is_equal("idle")
	_boss.state = EnemyController.State.DEAD
	_boss._update_look()
	assert_str(_boss.sprite.animation).is_equal("death")
