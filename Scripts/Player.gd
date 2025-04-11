extends CharacterBody3D

#This will be used to calculate the speed of the player based on whether or not they are walking or sprinting
var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0

const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.001

#BOB Variables
#Affects the how often the footsteps occur
const BOB_FREQ = 2.0
#Affects how far up and down the camera will go
const BOB_AMP = 0.008
#Pass wo sin function to determine how far along we are in the function at the current moment
var t_bob = 0.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Default gravity value anyway in GODOT
var gravity = 9.8

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready():
	#Shuts off the players mouse pointer and turns it into FPS mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	#Grabs the mouse moved event
	if event is InputEventMouseMotion:
		#Adjusts the view based on the heads y rotation with sensitivity
		head.rotate_y(-event.relative.x * SENSITIVITY)
		#Adjusts the view based on the cameras x rotation with sensitivity
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		#Will not allow you to look to low or high 
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	#Handles whether or not we are sprinting and sets the speed according to that
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	#Sets the direction of the player based on the direction of the head node
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#Player will only have movement control when they are on the floor
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 10.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 10.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	#Handles the head bob calculations
	t_bob += delta * velocity.length() *float(is_on_floor())
	#Assigns the position of the camera to the result of t_bob
	camera.transform.origin = _headbob(t_bob)
	
	#FOV Calculation
	#maximum that we can go FOV wise
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	#local target fov calculation
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	#sets the camera fov, origional, target, decimal percentage we want to cover
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ * 2) * BOB_AMP
	return pos
