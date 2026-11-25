extends GdUnitTestSuite
## Clip truyện Chương 2 (tools/story/gen_story_clips_02.py): dữ liệu hợp lệ, mỗi ô có placeholder, chữ đã dịch, người nói
## nhận ra được, và nối đúng vào ải (open_clip 2-1 / 2-6, end_clip 2-12).

const CLIPS := ["ch02_open", "ch02_gate", "ch02_end"]


func test_clips_are_valid_and_translated() -> void:
	for id: String in CLIPS:
		var d := StoryClip.load_clip(id)
		assert_bool(d.is_empty()).is_false()
		assert_str(tr(str(d["summary"]))).is_not_equal(str(d["summary"]))
		var panels := 0
		for pg: Dictionary in d["pages"]:
			if pg.has("card"):
				assert_str(tr(str(pg["card"]["title"]))).is_not_equal(str(pg["card"]["title"]))
				continue
			for p: Dictionary in pg["panels"]:
				panels += 1
				assert_bool(ResourceLoader.exists("res://assets/placeholders/story/placeholder_%s.png" % p["image"]) \
						or ResourceLoader.exists("res://assets/story/ch02/%s.png" % p["image"])).is_true()
				for l: Dictionary in p["lines"]:
					assert_str(tr(str(l["text"]))).is_not_equal(str(l["text"]))
					var spk := str(l["speaker"])
					if spk not in ["narration", "unknown"]:
						assert_str(StoryClip.speaker_name(spk)).is_not_equal(spk)
		assert_int(panels).is_greater(1)


func test_clips_are_wired_to_stages() -> void:
	assert_str(str(StageInfoScreen.stage_data_of("stage_02_01").get("open_clip", ""))).is_equal("ch02_open")
	assert_str(str(StageInfoScreen.stage_data_of("stage_02_06").get("open_clip", ""))).is_equal("ch02_gate")
	assert_str(str(StageInfoScreen.stage_data_of("stage_02_12").get("end_clip", ""))).is_equal("ch02_end")
	var fresh := SaveSchema.default_data()
	for id in CLIPS:
		assert_bool(StoryClip.should_play(id, fresh)).is_true()


func test_ishiro_has_a_name() -> void:
	assert_str(StoryClip.speaker_name("ishiro")).is_not_equal("ishiro")
	assert_str(StoryClip.speaker_name("ishiro")).is_not_equal("")
