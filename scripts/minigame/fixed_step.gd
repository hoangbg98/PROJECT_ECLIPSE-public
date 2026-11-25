class_name FixedStep
extends RefCounted
## Bộ tích lũy bước cố định cho mini game (Chạy, Bay): logic chạy đúng `step` giây mỗi bước dù frame dài ngắn, để kết
## quả giống nhau trên mọi máy và bot kiểm thử mô phỏng chính xác. Không đổi `physics_ticks_per_second` của dự án
## (docs/design/MATERIAL_EVENT.md mục 0, hàng 5).
##
##   var steps := fixed.advance(delta)
##   for i in steps: _step(fixed.step)
##   _draw_with(fixed.alpha())   # nội suy hiển thị

var step := 1.0 / 120.0
## Trần số bước mỗi frame (tránh "xoáy chết" khi máy khựng): phần dư bị bỏ.
var max_steps := 12
var _acc := 0.0


func _init(step_sec := 1.0 / 120.0, max_steps_ := 12) -> void:
	step = step_sec
	max_steps = max_steps_


## Cộng thời gian frame, trả về số bước logic cần chạy.
func advance(delta: float) -> int:
	_acc += maxf(delta, 0.0)
	var n := floori(_acc / step)
	if n > max_steps:
		n = max_steps
		_acc = 0.0
	else:
		_acc -= n * step
	return n


## Tỉ lệ 0..1 giữa bước logic trước và sau (để nội suy hình).
func alpha() -> float:
	return clampf(_acc / step, 0.0, 1.0)


func reset() -> void:
	_acc = 0.0
