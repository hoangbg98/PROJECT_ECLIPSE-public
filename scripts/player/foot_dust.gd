class_name FootDust
extends CPUParticles2D
## Bụi dưới chân khi nhân vật chạy trên mặt đất: vài hạt mờ bay ngược chiều chạy rồi tan, để nhìn như đang chạy trên nền.
## Thuần hình ảnh (không ảnh hưởng va chạm hay luật chơi). Con của PlayerController; node gốc đặt ở chân.

## Tốc độ ngang tối thiểu (px/s) để bắt đầu có bụi.
const MIN_SPEED := 70.0

var _body: CharacterBody2D


func _init() -> void:
	name = "FootDust"
	amount = 14
	lifetime = 0.5
	local_coords = false          # hạt ở lại trong thế giới → thành vệt phía sau
	emitting = false
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(9.0, 2.0)
	direction = Vector2(-1.0, -0.35)
	spread = 22.0
	initial_velocity_min = 18.0
	initial_velocity_max = 48.0
	gravity = Vector2(0.0, -26.0)
	scale_amount_min = 0.7
	scale_amount_max = 1.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.78, 0.70, 0.64, 0.5))
	ramp.set_color(1, Color(0.78, 0.70, 0.64, 0.0))
	color_ramp = ramp
	var tex := GradientTexture2D.new()
	tex.width = 12
	tex.height = 12
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = g
	texture = tex
	z_index = -1                   # sau thân nhân vật, trước nền


## Gắn vào thân nhân vật; mỗi tick vật lý tự bật / tắt theo chuyển động.
func attach(body: CharacterBody2D) -> void:
	_body = body


static func should_emit(on_floor: bool, velocity_x: float) -> bool:
	return on_floor and absf(velocity_x) >= MIN_SPEED


func _physics_process(_delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		return
	var emit := should_emit(_body.is_on_floor(), _body.velocity.x)
	emitting = emit
	if emit:
		direction = Vector2(-signf(_body.velocity.x), -0.35)
