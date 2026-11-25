class_name MinigameContext
extends RefCounted
## Tham số khung Event nguyên liệu đưa vào scene chơi (docs/design/MATERIAL_EVENT.md mục 5).

var event_id := ""
var mode_id := ""
var stage_id := ""
## Trích từ "params" của ải: chỉ scene chơi hiểu.
var params: Dictionary = {}
## Cho chế độ có sinh tất định.
var seed := 0
## Chưa xem hướng dẫn / giới thiệu của ải này.
var is_first_play := false
## Data ID đội hiện tại (ô 1 trước).
var party := PackedStringArray()
## Luyện tập / hết lượt: không tốn lượt, không thưởng.
var practice := false
