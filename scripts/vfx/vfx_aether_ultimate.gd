extends Node2D

signal cut_in_requested(duration_ms: int)
signal sequence_finished

@export_group("Timing (ms)")
@export var cut_in_ms: int = 600
@export var startup_ms: int = 300
@export var active_ms: int = 1400
@export var recovery_ms: int = 500
@export var phoenix_duration_ms: int = 550
@export var slash_interval_ms: int = 110
@export var explosion_duration_ms: int = 300
@export var shockwave_duration_ms: int = 260

@export_group("Scale")
@export var gather_scale: Vector2 = Vector2(0.48, 0.48)
@export var phoenix_scale: Vector2 = Vector2(1.85, 1.85)
@export var slash_scale: Vector2 = Vector2(1.08, 1.08)
@export var explosion_scale: Vector2 = Vector2(1.45, 1.45)
@export var shockwave_start_scale: float = 0.08
@export var shockwave_end_scale: float = 2.5

@export_group("Offsets")
@export var gather_offset: Vector2 = Vector2(175.0, -225.0)
@export var phoenix_start_offset: Vector2 = Vector2(120.0, -520.0)
@export var phoenix_end_offset: Vector2 = Vector2(680.0, -55.0)
@export var slash_offset: Vector2 = Vector2(690.0, -40.0)
@export var explosion_offset: Vector2 = Vector2(690.0, -40.0)
@export var aura_offset: Vector2 = Vector2(360.0, -100.0)
@export var tail_offset: Vector2 = Vector2(130.0, -200.0)

@export_group("Fire colors")
@export var fire_core_color: Color = Color(1.0, 0.94, 0.67, 1.0)
@export var fire_edge_color: Color = Color(1.0, 0.416, 0.239, 1.0)
@export var ember_color: Color = Color(1.0, 0.61, 0.25, 1.0)

@export_group("Shockwave")
@export var shockwave_radius: float = 96.0
@export var shockwave_width: float = 9.0
@export var shockwave_segments: int = 48

@export_group("Particles")
@export var aura_particle_count: int = 42
@export var aura_lifetime_s: float = 0.62
@export var aura_radius: float = 92.0
@export var aura_velocity_min: float = 36.0
@export var aura_velocity_max: float = 138.0
@export var tail_particle_count: int = 52
@export var tail_lifetime_s: float = 0.48
@export var tail_emission_extent: Vector2 = Vector2(88.0, 48.0)
@export var tail_velocity_min: float = 55.0
@export var tail_velocity_max: float = 210.0
@export var ember_particle_count: int = 96
@export var ember_lifetime_s: float = 0.52
@export var ember_velocity_min: float = 85.0
@export var ember_velocity_max: float = 310.0
@export var particle_scale_min: float = 0.22
@export var particle_scale_max: float = 0.76

@export_group("Frame paths")
@export var gather_frame_paths: PackedStringArray = PackedStringArray()
@export var phoenix_frame_paths: PackedStringArray = PackedStringArray()
@export var slash_frame_paths: PackedStringArray = PackedStringArray()
@export var explosion_frame_paths: PackedStringArray = PackedStringArray()

@onready var _gather: AnimatedSprite2D = $FlameGather
@onready var _phoenix: AnimatedSprite2D = $Phoenix
@onready var _explosion: AnimatedSprite2D = $Explosion
@onready var _slash_sprites: Array[Sprite2D] = [
	$Slash000, $Slash001, $Slash002, $Slash003, $Slash004
]
@onready var _shockwaves: Array[Line2D] = [
	$Shockwave000, $Shockwave001, $Shockwave002, $Shockwave003, $Shockwave004
]
@onready var _aura: CPUParticles2D = $Aura
@onready var _tail: CPUParticles2D = $FlameTail
@onready var _embers: CPUParticles2D = $Embers

var _playing: bool = false
var _slash_textures: Array[Texture2D] = []
var _shockwave_tweens: Array[Tween] = []
var _additive_material: CanvasItemMaterial


func _ready() -> void:
	_additive_material = CanvasItemMaterial.new()
	_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for item in [_gather, _phoenix, _explosion, _aura, _tail, _embers]:
		item.material = _additive_material
	for item in _slash_sprites:
		item.material = _additive_material
		item.visible = false
	for item in _shockwaves:
		item.material = _additive_material
		item.visible = false

	_build_animated_frames(_gather, gather_frame_paths)
	_build_animated_frames(_phoenix, phoenix_frame_paths)
	_build_animated_frames(_explosion, explosion_frame_paths)
	_slash_textures = _load_textures(slash_frame_paths)
	_gather.scale = gather_scale
	_phoenix.scale = phoenix_scale
	_explosion.scale = explosion_scale
	_gather.visible = false
	_phoenix.visible = false
	_explosion.visible = false
	_configure_particles()
	_configure_shockwaves()


func play_ultimate() -> void:
	if _playing:
		return
	_playing = true
	cut_in_requested.emit(cut_in_ms)
	await _wait_ms(cut_in_ms)

	_aura.position = aura_offset
	_aura.emitting = true
	_gather.position = gather_offset
	await _play_animation(_gather, startup_ms)

	_tail.position = tail_offset
	_tail.emitting = true
	var slash_count: int = mini(_slash_sprites.size(), _slash_textures.size())
	var requested_active_ms: int = phoenix_duration_ms + slash_interval_ms * slash_count + explosion_duration_ms
	var phase_ratio: float = float(active_ms) / float(maxi(1, requested_active_ms))
	var phoenix_ms: int = roundi(float(phoenix_duration_ms) * phase_ratio)
	var slash_ms: int = roundi(float(slash_interval_ms) * phase_ratio)
	var explosion_ms: int = maxi(0, active_ms - phoenix_ms - slash_ms * slash_count)

	_phoenix.position = phoenix_start_offset
	_phoenix.visible = true
	_play_sprite(_phoenix, phoenix_ms)
	var dive_tween: Tween = create_tween()
	dive_tween.tween_property(_phoenix, "position", phoenix_end_offset, float(phoenix_ms) / 1000.0)
	await _wait_ms(phoenix_ms)
	_phoenix.stop()
	_phoenix.visible = false

	for index in range(slash_count):
		var slash: Sprite2D = _slash_sprites[index]
		slash.texture = _slash_textures[index]
		slash.position = slash_offset
		slash.scale = slash_scale
		slash.modulate = fire_core_color
		slash.visible = true
		_start_shockwave(index)
		await _wait_ms(slash_ms)
		slash.visible = false

	_aura.emitting = false
	_tail.emitting = false
	_explosion.position = explosion_offset
	_explosion.visible = true
	_embers.position = explosion_offset
	_embers.modulate = Color.WHITE
	_embers.restart()
	_embers.emitting = true
	await _play_animation(_explosion, explosion_ms)

	var recovery_seconds: float = float(recovery_ms) / 1000.0
	var ember_fade: Tween = create_tween()
	ember_fade.tween_property(_embers, "modulate:a", 0.0, recovery_seconds)
	await ember_fade.finished
	_embers.emitting = false
	_embers.visible = false
	_explosion.visible = false
	_playing = false
	sequence_finished.emit()


func _build_animated_frames(sprite: AnimatedSprite2D, paths: PackedStringArray) -> void:
	var frames := SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	else:
		frames.clear("default")
	frames.set_animation_loop("default", false)
	for texture in _load_textures(paths):
		frames.add_frame("default", texture)
	sprite.sprite_frames = frames


func _load_textures(paths: PackedStringArray) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in paths:
		var texture: Texture2D = load(path) as Texture2D
		if texture != null:
			textures.append(texture)
	return textures


func _play_sprite(sprite: AnimatedSprite2D, duration_ms: int) -> void:
	if sprite.sprite_frames == null or sprite.sprite_frames.get_frame_count("default") == 0:
		return
	var frame_count: int = sprite.sprite_frames.get_frame_count("default")
	sprite.sprite_frames.set_animation_speed("default", float(frame_count) * 1000.0 / float(maxi(1, duration_ms)))
	sprite.speed_scale = 1.0
	sprite.play("default")


func _play_animation(sprite: AnimatedSprite2D, duration_ms: int) -> void:
	_play_sprite(sprite, duration_ms)
	sprite.visible = true
	await _wait_ms(duration_ms)
	sprite.stop()
	sprite.visible = false


func _configure_particles() -> void:
	var particle_gradient := Gradient.new()
	particle_gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	var particle_texture := GradientTexture2D.new()
	particle_texture.gradient = particle_gradient
	particle_texture.width = 20
	particle_texture.height = 20
	particle_texture.fill = GradientTexture2D.FILL_RADIAL
	particle_texture.fill_from = Vector2(0.5, 0.5)
	particle_texture.fill_to = Vector2(0.5, 0.0)

	_aura.texture = particle_texture
	_aura.amount = aura_particle_count
	_aura.lifetime = aura_lifetime_s
	_aura.one_shot = false
	_aura.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_aura.emission_sphere_radius = aura_radius
	_aura.direction = Vector2.UP
	_aura.spread = 180.0
	_aura.initial_velocity_min = aura_velocity_min
	_aura.initial_velocity_max = aura_velocity_max
	_aura.gravity = Vector2(0.0, -32.0)
	_aura.scale_amount_min = particle_scale_min
	_aura.scale_amount_max = particle_scale_max
	_aura.color = fire_edge_color
	_aura.emitting = false

	_tail.texture = particle_texture
	_tail.amount = tail_particle_count
	_tail.lifetime = tail_lifetime_s
	_tail.one_shot = false
	_tail.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_tail.emission_rect_extents = tail_emission_extent
	_tail.direction = Vector2.LEFT
	_tail.spread = 34.0
	_tail.initial_velocity_min = tail_velocity_min
	_tail.initial_velocity_max = tail_velocity_max
	_tail.gravity = Vector2(-14.0, 0.0)
	_tail.scale_amount_min = particle_scale_min
	_tail.scale_amount_max = particle_scale_max
	_tail.color = ember_color
	_tail.emitting = false

	_embers.texture = particle_texture
	_embers.amount = ember_particle_count
	_embers.lifetime = ember_lifetime_s
	_embers.one_shot = true
	_embers.explosiveness = 1.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_embers.emission_sphere_radius = shockwave_radius * 0.55
	_embers.direction = Vector2.UP
	_embers.spread = 180.0
	_embers.initial_velocity_min = ember_velocity_min
	_embers.initial_velocity_max = ember_velocity_max
	_embers.gravity = Vector2(0.0, 170.0)
	_embers.scale_amount_min = particle_scale_min
	_embers.scale_amount_max = particle_scale_max
	_embers.color = ember_color
	_embers.emitting = false
	_embers.visible = false


func _configure_shockwaves() -> void:
	for line in _shockwaves:
		line.clear_points()
		line.closed = true
		line.width = shockwave_width
		line.default_color = fire_edge_color
		for index in range(maxi(8, shockwave_segments)):
			var angle: float = TAU * float(index) / float(maxi(8, shockwave_segments))
			line.add_point(Vector2(cos(angle), sin(angle)) * shockwave_radius)


func _start_shockwave(index: int) -> void:
	var line: Line2D = _shockwaves[index]
	line.position = slash_offset
	line.scale = Vector2.ONE * shockwave_start_scale
	line.modulate = Color.WHITE
	line.visible = true
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(line, "scale", Vector2.ONE * shockwave_end_scale, float(shockwave_duration_ms) / 1000.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "modulate:a", 0.0, float(shockwave_duration_ms) / 1000.0)
	_shockwave_tweens.append(tween)
	tween.finished.connect(func() -> void: line.visible = false)


func _wait_ms(duration_ms: int) -> void:
	if duration_ms <= 0:
		await get_tree().process_frame
		return
	await get_tree().create_timer(float(duration_ms) / 1000.0, true, false, true).timeout
