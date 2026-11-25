extends GdUnitTestSuite
## Chương 2 "Xưởng Đá Ngủ" chơi thử được (tools/stages/gen_stages_02.py): 12 ải hợp lệ, quái / boss có data và scene,
## 2-7 → 2-12 có ô khách Iwagane (giáp thử hoặc giáp đã có), bản đồ chương mở các ải.

const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const SAVE_DIR := "user://test_saves_stage_02"
const GUEST := "char_earth_01"

var _stage: StageController
var _save: Node
var _old_store: SaveStore
var _old_data: Dictionary
var _gc: Node


func before_test() -> void:
	_save = get_tree().root.get_node("SaveService")
	_gc = get_tree().root.get_node("GameConfig")
	_old_store = _save.store
	_old_data = _save.data
	_save.store = SaveStore.new(SAVE_DIR)
	_save.store.delete_all()
	_save.data = TestTeam.three()
	_save.data["account"]["level"] = 40
	_gc.guest_use_owned = false


func after_test() -> void:
	Engine.time_scale = 1.0
	_gc.guest_use_owned = false
	_save.store.delete_all()
	DirAccess.remove_absolute(SAVE_DIR)
	_save.store = _old_store
	_save.data = _old_data


func _ids() -> Array:
	var out := []
	for i in range(1, 13):
		out.append("stage_02_%02d" % i)
	return out


func _setup(stage_id: String) -> void:
	_stage = auto_free(STAGE_SCENE.instantiate())
	_stage.use_selected_stage = false
	_stage.stage_id = stage_id
	add_child(_stage)
	_stage.party.use_player_input = false
	for m in _stage.party.members:
		m.controller.use_player_input = false
	for i in 20:
		await get_tree().physics_frame


func test_all_twelve_stages_are_valid() -> void:
	for id: String in _ids():
		var m := StageMap.load_from("res://data/stages/%s.json" % id)
		assert_array(m.errors).is_empty()
		assert_int(int(m.data["chapter"])).is_equal(2)
		assert_str(tr(m.data["name_key"])).is_not_equal(m.data["name_key"])
		assert_str(tr(m.data["desc_key"])).is_not_equal(m.data["desc_key"])
		var last := -1
		for w: Dictionary in m.data["waves"]:
			assert_int(int(w["trigger_col"])).is_greater(last)
			last = int(w["trigger_col"])
			for e: Dictionary in w["enemies"]:
				assert_bool(StageController.ENEMY_SCENES.has(e["id"])).is_true()
				assert_bool(ResourceLoader.exists("res://data/enemies/%s.tres" % e["id"])).is_true()
		if m.data.has("boss"):
			var bid := str(m.data["boss"]["id"])
			assert_bool(StageController.ENEMY_SCENES.has(bid)).is_true()
			assert_bool(load("res://data/enemies/%s.tres" % bid) is BossDef).is_true()
		else:
			assert_int(int(m.data["goal_col"])).is_greater(last)


func test_guest_only_from_2_7() -> void:
	for i in range(1, 13):
		var m := StageMap.load_from("res://data/stages/stage_02_%02d.json" % i)
		assert_str(GuestSlot.of_stage(m.data)).is_equal(GUEST if i >= 7 else "")


func test_chapter_map_opens_all_stages() -> void:
	for i in range(1, 13):
		assert_str(str(ChapterBook.stage("2-%d" % i)["stage_id"])).is_equal("stage_02_%02d" % i)


func test_new_enemies_are_tougher_and_localized() -> void:
	var slime2 := load("res://data/enemies/enemy_slime_02.tres") as EnemyDef
	var stone := load("res://data/enemies/enemy_slime_03.tres") as EnemyDef
	var statue := load("res://data/enemies/enemy_statue_01.tres") as EnemyDef
	assert_float(stone.stats.max_hp).is_greater(slime2.stats.max_hp)
	assert_float(statue.stats.atk).is_greater(slime2.stats.atk)
	for key in ["ENEMY_STATUE_01", "ENEMY_SLIME_03", "BOSS_MINION_CUTTER", "BOSS_IWAGANE_01", "BOSS_GATE_01"]:
		assert_str(tr(key)).is_not_equal(key)


func test_guest_stage_forces_guest_into_last_slot_with_trial_gear() -> void:
	await _setup("stage_02_07")
	assert_int(_stage.party_ids.size()).is_equal(3)
	assert_str(_stage.party_ids[2]).is_equal(GUEST)
	assert_bool(_stage.guest_is_trial).is_true()
	var trial_stats := GuestSlot.trial_profile(_stage.profile, GUEST).stats_of(GUEST)
	assert_float(_stage.party.members[2].controller.stats_override.max_hp).is_equal(trial_stats.max_hp)
	assert_bool(_save.data["characters"].has(GUEST)).is_false()        # save thật không bị đụng


func test_guest_stage_uses_owned_armor_when_chosen() -> void:
	_save.data["characters"][GUEST] = SaveSchema.default_character()
	_save.data["characters"][GUEST]["level"] = 3
	_gc.guest_use_owned = true
	await _setup("stage_02_07")
	assert_bool(_stage.guest_is_trial).is_false()
	var owned := _stage.profile.stats_of(GUEST)
	assert_float(_stage.party.members[2].controller.stats_override.max_hp).is_equal(owned.max_hp)


func test_non_guest_stage_keeps_player_party() -> void:
	await _setup("stage_02_01")
	assert_bool(_stage.guest_is_trial).is_false()
	assert_array(Array(_stage.party_ids)).is_equal(Array(_stage.profile.party_ids()))


func _teleport_col(col: int) -> void:
	_stage.player.global_position = _stage.map.ground_feet(col)
	_stage.player.velocity = Vector2.ZERO
	for i in 3:
		await get_tree().physics_frame


func _clear_waves() -> void:
	var waves: Array = _stage.waves()
	for i in waves.size():
		await _teleport_col(int(waves[i]["trigger_col"]))
		for e in _stage.enemies.duplicate():
			e.combatant.resources.take_damage(1e9)
		for k in 2:
			await get_tree().physics_frame
		assert_int(_stage.waves_cleared).is_equal(i + 1)


func test_every_boss_stage_spawns_its_boss_and_clears() -> void:
	for id in ["stage_02_02", "stage_02_06", "stage_02_12"]:
		await _setup(id)
		await _clear_waves()
		var b: Dictionary = _stage.boss_data()
		await _teleport_col(int(b["trigger_col"]) + 1)
		assert_int(_stage.phase).is_equal(StageController.Phase.BOSS)
		assert_str(_stage.boss.enemy_id).is_equal(str(b["id"]))
		_stage.boss.combatant.resources.take_damage(1e9)
		for k in 5:
			await get_tree().physics_frame
		assert_int(_stage.phase).is_equal(StageController.Phase.CLEARED)
		_stage.queue_free()
		await get_tree().process_frame


func test_no_boss_guest_stage_clears_at_goal() -> void:
	await _setup("stage_02_07")
	await _clear_waves()
	await _teleport_col(int(_stage.map.data["goal_col"]) + 1)
	assert_int(_stage.phase).is_equal(StageController.Phase.CLEARED)
