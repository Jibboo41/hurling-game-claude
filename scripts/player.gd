extends CharacterBody3D

@export var speed: float = 7.0
@export var acceleration: float = 12.0
@export var rotation_speed: float = 10.0
@export var strike_range: float = 2.0
@export var strike_force: float = 20.0

const HURLEY_SWING_ANGLE: float = 1.4  # radians (~80 degrees forward tilt)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _strike_tween: Tween = null

@onready var camera_rig: Node3D = $CameraRig
@onready var hurley_pivot: Node3D = $HurleyPivot


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("strike"):
		_play_strike_animation()


func _play_strike_animation() -> void:
	# Don't restart if mid-swing
	if _strike_tween != null and _strike_tween.is_running():
		return
	_strike_tween = create_tween()
	# Snap hurley forward — CUBIC EASE_OUT feels like a sharp whip
	_strike_tween.tween_property(hurley_pivot, "rotation:x", HURLEY_SWING_ANGLE, 0.12) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# At peak of swing, attempt to hit the ball
	_strike_tween.tween_callback(_try_strike)
	# Smooth return to rest
	_strike_tween.tween_property(hurley_pivot, "rotation:x", 0.0, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _try_strike() -> void:
	for ball in get_tree().get_nodes_in_group("sliotar"):
		if global_position.distance_to(ball.global_position) <= strike_range:
			var dir := (-global_transform.basis.z + Vector3(0, 0.35, 0)).normalized()
			ball.apply_central_impulse(dir * strike_force)
			break


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)

	if input_dir == Vector2.ZERO:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
	else:
		# Project the camera rig's world-space axes onto the XZ plane
		var basis := camera_rig.global_transform.basis
		var cam_forward := -Vector3(basis.z.x, 0.0, basis.z.z).normalized()
		var cam_right   :=  Vector3(basis.x.x, 0.0, basis.x.z).normalized()
		var direction   := (cam_forward * -input_dir.y + cam_right * input_dir.x).normalized()

		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)

		var target_angle: float = atan2(direction.x, direction.z)
		rotation.y = rotate_toward(rotation.y, target_angle, rotation_speed * delta)

	move_and_slide()
