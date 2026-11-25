extends GdUnitTestSuite
## Ô khách của màn cốt truyện (GuestSlot, owner 2026-11-21): slot bắt buộc, giáp thử (S, đủ món đề cử, cấp theo cấp quản lý) hoặc giáp đã có.

const GUEST := "char_earth_01"


func _profile(captain_level := 30, owned: Array = ["char_fire_01", "char_wind_01", "char_lightning_01"]) -> PlayerProfile:
	var save := SaveSchema.default_data()
	save["account"]["level"] = captain_level
	save["characters"] = {}
	for id in owned:
		save["characters"][id] = SaveSchema.default_character()
	save["party"] = Array(owned).slice(0, 3)
	return PlayerProfile.new(save)


func test_of_stage() -> void:
	assert_str(GuestSlot.of_stage({"guest": {"char": GUEST}})).is_equal(GUEST)
	assert_str(GuestSlot.of_stage({})).is_equal("")
	assert_str(GuestSlot.of_stage({"guest": "bad"})).is_equal("")


func test_effective_party_puts_guest_last_and_keeps_two() -> void:
	var p := _profile()
	var party := GuestSlot.effective_party(p, GUEST)
	assert_int(party.size()).is_equal(3)
	assert_str(party[2]).is_equal(GUEST)
	assert_str(party[0]).is_equal("char_fire_01")
	assert_str(party[1]).is_equal("char_wind_01")


func test_effective_party_without_guest_is_unchanged() -> void:
	var p := _profile()
	assert_array(Array(GuestSlot.effective_party(p, ""))).is_equal(Array(p.party_ids()))


func test_owned_guest_not_duplicated() -> void:
	var p := _profile(30, ["char_earth_01", "char_fire_01"])
	var party := GuestSlot.effective_party(p, GUEST)
	assert_int(Array(party).count(GUEST)).is_equal(1)
	assert_str(party[party.size() - 1]).is_equal(GUEST)


func test_uses_trial_rules() -> void:
	var none := _profile()
	assert_bool(GuestSlot.uses_trial(none, GUEST, true)).is_true()     # chưa sở hữu: luôn thử
	var has := _profile(30, ["char_fire_01", "char_earth_01"])
	assert_bool(GuestSlot.uses_trial(has, GUEST, false)).is_true()     # sở hữu nhưng chọn thử
	assert_bool(GuestSlot.uses_trial(has, GUEST, true)).is_false()     # sở hữu và chọn giáp đã có
	assert_bool(GuestSlot.uses_trial(has, "", false)).is_false()


func test_trial_profile_rank_level_and_gear() -> void:
	var real := _profile(25)
	var before := real.data.duplicate(true)
	var trial := GuestSlot.trial_profile(real, GUEST)
	assert_bool(trial.progression.owns(GUEST)).is_true()
	assert_int(trial.progression.level_of(GUEST)).is_equal(mini(real.rules.max_level, 25))
	assert_int(trial.inventory.equipped_defs(GUEST).size()).is_equal(4)
	var def := load(PlayerProfile.CHARACTER_DATA % GUEST) as CharacterDef
	assert_str(trial.progression.rank_label(def)).is_equal("S")
	assert_float(trial.stats_of(GUEST).atk).is_greater(def.stats.atk)
	assert_dict(real.data).is_equal(before)           # hồ sơ thật không bị đổi
	assert_bool(real.progression.owns(GUEST)).is_false()


func test_trial_level_follows_captain_level() -> void:
	var low := GuestSlot.trial_profile(_profile(10), GUEST)
	var high := GuestSlot.trial_profile(_profile(40), GUEST)
	assert_int(low.progression.level_of(GUEST)).is_less(high.progression.level_of(GUEST))
	assert_int(GuestSlot.trial_level(_profile(10))).is_equal(10)


func _labels(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_labels(c, out)


func test_party_prep_never_shows_guest_twice() -> void:
	var save := SaveSchema.default_data()
	save["characters"][GUEST] = SaveSchema.default_character()
	save["party"] = ["char_fire_01", GUEST]
	var gc := get_tree().root.get_node("GameConfig")
	var old_stage: String = gc.selected_stage_id
	var old_launch: bool = gc.prep_launch_stage
	gc.selected_stage_id = "stage_02_07"
	gc.prep_launch_stage = true
	var scr := PartyPrepScreen.new()
	scr.profile = PlayerProfile.new(save)
	add_child(auto_free(scr))
	await get_tree().process_frame
	var texts := []
	_labels(scr, texts)
	var name := tr("CHAR_EARTH_01")
	var named := texts.filter(func(t: String) -> bool: return name != "" and t.begins_with(name))
	gc.selected_stage_id = old_stage
	gc.prep_launch_stage = old_launch
	assert_str(scr.guest_char).is_equal(GUEST)
	assert_int(named.size()).is_equal(1)
	assert_int(texts.count(tr("SORTIE_GUEST_TRIAL"))).is_equal(1)
