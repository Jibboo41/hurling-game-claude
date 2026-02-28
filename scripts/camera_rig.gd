extends Node3D

@export var mouse_sensitivity: float = 0.003
@export var pitch_min: float = -0.6
@export var pitch_max: float = 0.4

@onready var spring_arm: SpringArm3D = $SpringArm


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotation.y -= event.relative.x * mouse_sensitivity
			spring_arm.rotation.x -= event.relative.y * mouse_sensitivity
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, pitch_min, pitch_max)
