extends Node2D


func _ready() -> void:
	var effect: Node2D = $VfxAetherUltimate
	effect.position = Vector2(500.0, 640.0)
	await effect.play_ultimate()
	await get_tree().process_frame
	get_tree().quit()
