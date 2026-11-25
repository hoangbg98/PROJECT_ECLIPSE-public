extends GdUnitTestSuite
## Bản nốt (RhythmChart), thư viện bài tải từ máy chủ (RhythmLibrary, máy chủ giả) và tham số ải trong dữ liệu event (M11).

const CACHE := "user://test_rhythm_cache"


func after_test() -> void:
	_rm(CACHE)


func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)


# ---------- RhythmChart ----------

func test_chart_parse_sort_and_drop_overlaps() -> void:
	var c := RhythmChart.from_json_text(JSON.stringify({"format": 1, "song_id": "s", "difficulty": "easy", "level": 3,
		"bpm": 128, "notes": [
			{"t": 3.0, "lane": "down"},
			{"t": 1.0, "lane": "up", "kind": "hold", "dur": 1.5},
			{"t": 2.0, "lane": "up"},                          # nằm trong nốt giữ => bỏ
			{"t": 4.0, "lane": "sideways"},                    # làn sai => bỏ
			{"t": 5.0, "lane": "both", "kind": "mash", "dur": 1.0},
			{"t": 7.0, "lane": "up", "kind": "hold", "dur": 0},  # giữ không có độ dài => bỏ
		]}))
	assert_bool(c.is_valid()).is_true()
	assert_int(c.notes.size()).is_equal(3)
	assert_int(c.dropped).is_equal(3)
	assert_float(float(c.notes[0]["t"])).is_equal(1.0)
	assert_int(int(c.notes[2]["hits"])).is_greater(0)
	assert_int(c.judgment_units()).is_equal(4)
	assert_float(c.last_note_end()).is_equal(6.0)
	assert_str(RhythmChart.lane_name(RhythmChart.LANE_BOTH)).is_equal("both")


func test_chart_rejects_bad_input() -> void:
	assert_bool(RhythmChart.from_json_text("not json").is_valid()).is_false()
	assert_bool(RhythmChart.from_dict({"format": 99, "notes": []}).is_valid()).is_false()
	assert_bool(RhythmChart.load_file("user://khong_co.json").is_valid()).is_false()


# ---------- RhythmLibrary (máy chủ giả) ----------

class FakeServer:
	var files: Dictionary = {}   # url -> PackedByteArray
	var down := false
	var requests: Array = []

	func fetch(url: String) -> Dictionary:
		requests.append(url)
		await Engine.get_main_loop().process_frame
		if down:
			return {"ok": false, "code": 0, "body": PackedByteArray(), "error": "network"}
		if not files.has(url):
			return {"ok": false, "code": 404, "body": PackedByteArray(), "error": "http_404"}
		return {"ok": true, "code": 200, "body": files[url], "error": ""}


func _sha(b: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(b)
	return h.finish().hex_encode()


func _server() -> FakeServer:
	var srv := FakeServer.new()
	var chart := JSON.stringify({"format": 1, "song_id": "song_a", "difficulty": "easy", "notes": [{"t": 1.0, "lane": "up"}]}).to_utf8_buffer()
	var audio := PackedByteArray([1, 2, 3, 4, 5])
	srv.files["http://h/music/song_a_easy.json"] = chart
	srv.files["http://h/music/song_a.wav"] = audio
	srv.files["http://h/music/catalog.json"] = JSON.stringify({"format": 1, "songs": [
		{"id": "song_a", "title": "A", "audio": {"file": "song_a.wav", "sha256": _sha(audio), "bytes": 5},
			"charts": {"easy": {"file": "song_a_easy.json", "sha256": _sha(chart), "bytes": chart.size(), "level": 2}}},
		{"id": "evil", "title": "E", "audio": {"file": "../x.wav"}, "charts": {}},
	]}).to_utf8_buffer()
	return srv


func test_library_download_cache_and_offline() -> void:
	var srv := _server()
	var lib := RhythmLibrary.new("http://h/music", srv.fetch, CACHE)
	assert_bool(await lib.refresh_catalog()).is_true()
	assert_bool(lib.from_cache).is_false()
	assert_int(lib.songs().size()).is_equal(1)       # bài có tên file nguy hiểm bị bỏ
	assert_bool(lib.is_cached("song_a", "easy")).is_false()
	assert_int(lib.missing_bytes("song_a", "easy")).is_greater(5)
	var res: Dictionary = await lib.ensure("song_a", "easy")
	assert_bool(res["ok"]).is_true()
	assert_bool(lib.is_cached("song_a", "easy")).is_true()
	assert_int(lib.load_chart("song_a", "easy").notes.size()).is_equal(1)
	# Mất mạng: danh mục lấy từ bản đã lưu, bài đã tải vẫn chơi được, không tải lại.
	srv.down = true
	var off := RhythmLibrary.new("http://h/music/", srv.fetch, CACHE)
	assert_bool(await off.refresh_catalog()).is_true()
	assert_bool(off.from_cache).is_true()
	assert_bool(off.is_cached("song_a", "easy")).is_true()
	var n := srv.requests.size()
	assert_bool((await off.ensure("song_a", "easy"))["ok"]).is_true()
	assert_int(srv.requests.size()).is_equal(n)


func test_library_checksum_and_errors() -> void:
	var srv := _server()
	srv.files["http://h/music/song_a.wav"] = PackedByteArray([9, 9, 9])   # khác sha256 trong danh mục
	var lib := RhythmLibrary.new("http://h/music/", srv.fetch, CACHE)
	await lib.refresh_catalog()
	var res: Dictionary = await lib.ensure("song_a", "easy")
	assert_bool(res["ok"]).is_false()
	assert_str(res["error"]).is_equal("checksum")
	assert_bool(lib.is_cached("song_a", "easy")).is_false()
	assert_str((await lib.ensure("khong_co", "easy"))["error"]).is_equal("unknown_song")
	srv.down = true
	var none := RhythmLibrary.new("http://h/music/", srv.fetch, CACHE + "_empty")
	assert_bool(await none.refresh_catalog()).is_false()
	assert_bool(RhythmLibrary.safe_name("a/b.wav")).is_false()
	assert_bool(RhythmLibrary.safe_name("..")).is_false()
	assert_bool(RhythmLibrary.safe_name("song_a-1.ogg")).is_true()


## Tham số ải Nhịp điệu nằm trong data/events/material_events.json (M11): tốc độ tăng dần tới boss, ải đầu chỉ có nốt
## ấn + hướng dẫn, ải 2 giới thiệu Rắn Ngân, Vô tận nhanh dần theo độ khó.
func test_stage_speeds_increase_to_boss() -> void:
	var reg := MinigameRegistry.load_from()
	var prev := 0.0
	for s in reg.mode("evt_material", "rhythm")["stages"]:
		var sp := float(s["params"]["speed"]["note_speed"])
		assert_float(sp).is_greater(prev)
		prev = sp
	var st1 := reg.stage("evt_material", "rhythm", "rhythm_mat_01")
	assert_array(st1["params"]["spawn"]["kinds"]).is_equal(["tap"])
	assert_bool(bool(st1["params"]["guide"]["tutorial"])).is_true()
	assert_str(str(reg.stage("evt_material", "rhythm", "rhythm_mat_02")["params"]["guide"]["intro_key"])).is_not_empty()
	assert_float(float(reg.endless_stage("evt_material", "rhythm_endless", "x", "hard")["params"]["speed"]["note_speed"])).is_greater(
			float(reg.endless_stage("evt_material", "rhythm_endless", "x", "easy")["params"]["speed"]["note_speed"]))


## Tốc độ bài (tốc độ vượt ải) và mật độ quái chỉnh trong dữ liệu.
func test_chart_song_speed_and_density() -> void:
	var notes: Array = []
	for i in 10:
		notes.append({"t": 2.0 + i * 0.5, "lane": "up" if i % 2 == 0 else "down"})
	notes.append({"t": 8.0, "lane": "up", "kind": "hold", "dur": 1.0})
	var c := RhythmChart.from_dict({"format": 1, "bpm": 120, "duration_sec": 10.0, "notes": notes})
	c.scale_time(2.0)
	assert_float(float(c.notes[0]["t"])).is_equal(1.0)
	assert_float(float(c.notes[10]["dur"])).is_equal(0.5)
	assert_float(c.duration_sec).is_equal(5.0)
	assert_float(c.bpm).is_equal(240.0)
	assert_int(c.thin(0.5)).is_equal(6)        # giữ 5 / 11, rải đều
	assert_int(c.notes.size()).is_equal(5)
	var d := RhythmChart.from_dict({"format": 1, "notes": notes})
	d.thin(1.0, 0.9)                            # nốt cách nhau 0.5 s, tối thiểu 0.9 s => cách 1 giữ 1
	for i in range(1, d.notes.size()):
		assert_float(float(d.notes[i]["t"]) - float(d.notes[i - 1]["t"]) - float(d.notes[i - 1]["dur"])).is_greater_equal(0.9)
	var same := RhythmChart.from_dict({"format": 1, "notes": notes})
	assert_int(same.thin(1.0, 0.0)).is_equal(0)


func test_stage_applies_song_speed_and_density() -> void:
	var notes: Array = []
	for i in 8:
		notes.append({"t": 4.0 + i * 1.0, "lane": "up"})
	var s := (load("res://scenes/main/rhythm_stage.tscn") as PackedScene).instantiate() as RhythmStage
	s.setup(RhythmChart.from_dict({"format": 1, "notes": notes}), null, "", "T")
	s.song_speed = 2.0
	s.density = 0.5
	s.manual_clock = true
	s.save_enabled = false
	s.profile = PlayerProfile.new(SaveSchema.default_data())
	add_child(auto_free(s))
	assert_int(s.chart.notes.size()).is_equal(4)
	assert_float(float(s.chart.notes[0]["t"])).is_equal(2.5)   # nốt thứ 2 (5.0 s) / 2
	assert_float(s.player.pitch_scale).is_equal(2.0)
	var tut: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/rhythm/tutorial.json"))
	assert_bool(tut is Dictionary and tut["steps"].size() >= 3).is_true()
