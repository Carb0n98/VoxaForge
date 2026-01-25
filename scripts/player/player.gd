extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.002
@export var gravity := 20.0
@export var jump_force := 8.0

var rotation_x := 0.0

@onready var camera = $Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotation_x -= event.relative.y * mouse_sensitivity
		rotation_x = clamp(rotation_x, -1.5, 1.5)
		camera.rotation.x = rotation_x
		rotation.y -= event.relative.x * mouse_sensitivity

func _physics_process(delta):
	var move_dir := Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		move_dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		move_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		move_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		move_dir += transform.basis.x
	
	move_dir = move_dir.normalized()
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
		
	move_and_slide()
