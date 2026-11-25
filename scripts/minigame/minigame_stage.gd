class_name MinigameStage
extends Control
## Lớp cơ sở cho scene chơi của Event nguyên liệu (docs/design/MATERIAL_EVENT.md mục 5).
##
## Quy ước: scene chơi tự lo tạm dừng, đếm ngược, hướng dẫn, tải tài nguyên; phát `play_started` đúng lúc chơi thật bắt
## đầu (sau hướng dẫn, sau đếm ngược: khung tiêu một lượt lúc này); phát `finished` đúng một lần. Thoát giữa chừng =
## `finished` với `MinigameResult.quit_result()`; thoát trước khi chơi thật = `quit_requested`. Scene chơi không ghi
## save, không phát thưởng, không đọc hạn mức.

signal finished(result: MinigameResult)
signal play_started
## Thoát khi chưa chơi thật (đang tải, hướng dẫn, đếm ngược, lỗi tải): khung không tốn lượt.
signal quit_requested
## Người chơi bấm Chơi lại trong menu tạm dừng: khung dựng lại scene.
signal retry_requested

var ctx: MinigameContext


func setup(ctx_: MinigameContext) -> void:
	ctx = ctx_


## Bắt đầu (lớp con ghi đè). Gọi sau khi đã thêm vào cây.
func start() -> void:
	pass


func pause_game() -> void:
	pass


func resume_game() -> void:
	pass
