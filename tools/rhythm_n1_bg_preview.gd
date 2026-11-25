extends Node
## Mở trực tiếp màn RhythmStage với ảnh nền far N-1 chưa duyệt.


func _ready() -> void:
	var chart := RhythmChart.from_dict({"format": 1, "song_id": "n1_preview", "bpm": 100, "notes": [
		{"t": 2.2, "lane": "up"}, {"t": 3.2, "lane": "down"}, {"t": 4.0, "lane": "up"},
	]})
	var stage := (load("res://scenes/main/rhythm_stage.tscn") as PackedScene).instantiate() as RhythmStage
	stage.setup(chart, null, "", "N-1 FAR PREVIEW")
	stage.manual_clock = true
	stage.background_preview = true
	stage.save_enabled = false
	stage.profile = PlayerProfile.new(SaveSchema.default_data())
	add_child(stage)
	stage.advance(2.5)
