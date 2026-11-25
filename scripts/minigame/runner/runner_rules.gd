class_name RunnerRules
extends Resource
## Thông số Chạy Nguyên Tố (M11-4, docs/design/RUNNER_MODE.md mục 4, 6). Dữ liệu: data/runner/runner_rules.tres.
## Đơn vị: px, giây; độ cao tính từ mặt đường lên (dương = trên không).

@export_group("Vị trí")
@export var player_x := 480.0
## Mặt đường trên màn (y, khung 1920x1080).
@export var ground_y := 840.0
## Nơi vật xuất hiện (ngoài mép phải).
@export var spawn_x := 2000.0

@export_group("Nhảy")
@export var jump_velocity := 1300.0
@export var gravity := 4000.0
## Còn được nhảy bấy nhiêu giây sau khi rời mặt đất (rời mép hố).
@export var coyote_time := 0.08
## Bấm nhảy sớm bấy nhiêu giây trước khi chạm đất vẫn nhảy.
@export var jump_buffer := 0.12

@export_group("Đổi người")
@export var swap_cooldown := 0.12
## Đổi xong trong khoảng này trước lúc qua cổng = Perfect.
@export var perfect_swap_window := 0.30
## Cổng xét người đang chạy tại thời điểm chạm + chừng này.
@export var gate_grace := 0.05

@export_group("Hurtbox (chữ nhật, đáy ở bàn chân)")
@export var hurt_width := 110.0
@export var hurt_height := 230.0
## Bán kính nhặt Hạt Tinh quanh tâm người chạy.
@export var pickup_radius := 60.0

@export_group("HP")
@export var hp_max := 100
@export var hit_damage := 20
@export var gate_damage := 25
@export var invuln_time := 1.2
@export var pit_invuln_time := 1.5

@export_group("Điểm")
@export var score_pass := 50
@export var score_gate_perfect := 200
@export var score_gate := 100
@export var score_orb := 10
@export var score_orb_match := 20
@export var combo_bonus_step := 0.002
@export var combo_bonus_cap := 100

@export_group("Fever")
@export var fever_max := 100.0
@export var fever_gate_perfect := 4.0
@export var fever_pass := 1.0
@export var fever_orb := 0.25
@export var fever_hit := -20.0
@export var fever_duration := 8.0
@export var fever_multiplier := 1.5
## Khi Fever: hút Hạt Tinh trong bán kính này.
@export var fever_magnet_radius := 300.0

@export_group("Hạng (độ chính xác)")
## Cổng đúng nhưng không cần đổi tính bấy nhiêu phần một Perfect.
@export var gate_normal_weight := 0.8
@export var rank_s := 0.95
@export var rank_a := 0.9
@export var rank_b := 0.8
@export var rank_c := 0.7

@export_group("Hiển thị")
@export var countdown_sec := 3.0


## Thời gian trên không của một cú nhảy từ mặt đất.
func airtime() -> float:
	return 2.0 * jump_velocity / gravity


## Độ cao đỉnh.
func peak_height() -> float:
	return jump_velocity * jump_velocity / (2.0 * gravity)


func rank_of(acc: float) -> String:
	if acc >= rank_s:
		return "S"
	if acc >= rank_a:
		return "A"
	if acc >= rank_b:
		return "B"
	if acc >= rank_c:
		return "C"
	return "D"
