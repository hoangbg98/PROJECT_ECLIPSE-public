class_name JetRules
extends Resource
## Thông số Bay Nguyên Tố (M11-5, docs/design/JET_MODE.md mục 4, 5, 7). Dữ liệu: data/jet/jet_rules.tres.
## Đơn vị: px, giây; trục y hướng xuống (y nhỏ = cao). Vận tốc dọc âm = đi lên.

@export_group("Sân")
@export var player_x := 420.0
@export var floor_y := 900.0
@export var ceiling_y := 110.0
@export var spawn_x := 2070.0
@export var px_per_meter := 60.0

@export_group("Cuộn")
@export var scroll_cap := 1000.0

@export_group("Bay (người thường)")
@export var gravity := 2200.0
@export var thrust := 3600.0
@export var vy_up_max := 900.0
@export var vy_down_max := 1100.0

@export_group("Năng lượng")
@export var energy_max := 100.0
@export var energy_drain := 24.0
@export var energy_regen_ground := 10.0
@export var core_gain := 30.0

@export_group("Va chạm")
@export var hurt_radius := 32.0
## Bán kính va chạm hiệu dụng = hệ số × hurtbox.
@export var hit_scale := 0.8
## Bán kính nhặt = hurtbox + chừng này.
@export var pickup_pad := 22.0
@export var obstacle_thickness := 13.0
@export var missile_radius := 28.0
@export var missile_speed := 650.0
@export var missile_warn := 1.0
@export var gate_gap := 300.0
@export var gate_width := 70.0
@export var sweep_half := 130.0
@export var orb_spacing := 70.0
@export var orb_wave := 80.0

@export_group("Tim")
@export var lives := 3
@export var invuln_hit := 1.5
@export var invuln_form_break := 1.2

@export_group("Rồng")
@export var dragon_up := 2600.0
@export var dragon_down := 1500.0
@export var dragon_vy_up := 650.0
@export var dragon_vy_down := 800.0
@export var dragon_radius := 60.0
@export var dragon_time := 14.0

@export_group("Robo")
@export var robo_gravity := 3400.0
@export var robo_jump := 1300.0
@export var robo_radius := 58.0
@export var robo_time := 10.0
## Hạt thưởng khi Robo nghiền một vật cản.
@export var robo_crush_orbs := 5
## Hạt thưởng khi chạm Hộp Ký Ức.
@export var box_orbs := 10

@export_group("Vùng")
@export var zone_length_m := 600.0
@export var zone_banner_sec := 3.2
## Gió: chu kỳ (giây ở tốc độ cuộn gốc của level, quy ra quãng đường): im → thổi → im.
@export var wind_cycle := 5.0
@export var wind_on := 1.5
@export var wind_off := 3.5
@export var wind_accel := 1300.0

@export_group("Điểm, hạng")
@export var score_per_orb := 5
## Vô tận: qua khi đi được chừng này mét; hạng theo bội số.
@export var endless_clear_m := 1500.0
@export var endless_rank_s := 2.0
@export var endless_rank_a := 1.5
@export var endless_rank_b := 1.2
@export var endless_rank_c := 1.0
@export var rank_s := 0.95
@export var rank_a := 0.9
@export var rank_b := 0.8
@export var rank_c := 0.7

@export_group("Hiển thị")
@export var countdown_sec := 3.0


func hit_radius(form: String) -> float:
	match form:
		"dragon":
			return dragon_radius * hit_scale
		"robo":
			return robo_radius * hit_scale
	return hurt_radius * hit_scale


func body_radius(form: String) -> float:
	match form:
		"dragon":
			return dragon_radius
		"robo":
			return robo_radius
	return hurt_radius


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


func endless_rank(distance_m: float) -> String:
	var k := distance_m / endless_clear_m
	if k >= endless_rank_s:
		return "S"
	if k >= endless_rank_a:
		return "A"
	if k >= endless_rank_b:
		return "B"
	if k >= endless_rank_c:
		return "C"
	return "D"
